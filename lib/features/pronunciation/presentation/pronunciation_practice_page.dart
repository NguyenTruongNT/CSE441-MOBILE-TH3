// ignore_for_file: deprecated_member_use
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/shared/page_activity.dart';

import 'package:th3_english_ai/core/contracts/models.dart';
import 'package:th3_english_ai/core/contracts/ports.dart';

import '../data/default_exercises.dart';
import '../data/fake_pronunciation_repository.dart';
import '../domain/audio_recorder.dart';
import '../domain/exercise_models.dart';
import '../domain/pronunciation_logger.dart';
import '../domain/speech_recognizer.dart';
import '../services/audio_recorder_service.dart';
import '../services/fake_pronunciation_service.dart';
import '../services/remote_pronunciation_service.dart';
import '../services/recorder/audio_recorder_factory.dart';
import '../services/recorder/speech_to_text_factory.dart';
import 'widgets/audio_sample_player.dart';
import 'widgets/improvement_exercise_card.dart';
import 'widgets/overall_score_badge.dart';
import 'widgets/phoneme_feedback_table.dart';
import 'widgets/recording_control_bar.dart';
import 'widgets/speech_transcript_view.dart';
import 'widgets/waveform_visualizer.dart';

/// Pronunciation practice studio and AI analysis page.
///
/// Designed to run fully standalone with internal defaults or with dependencies
/// injected via constructor from the app composition root.
class PronunciationPracticePage extends StatefulWidget {
  const PronunciationPracticePage({
    super.key,
    this.userRepository,
    this.learningRepository,
    this.pronunciationService,
    this.audioRecorder,
    required this.exercise,
  });

  final UserRepository? userRepository;
  final LearningRepository? learningRepository;
  final PronunciationService? pronunciationService;
  final AudioRecorderController? audioRecorder;
  final ExerciseDetail exercise;

  @override
  State<PronunciationPracticePage> createState() =>
      _PronunciationPracticePageState();
}

class _PronunciationPracticePageState extends State<PronunciationPracticePage> {
  late final UserRepository _userRepo;
  late final LearningRepository _learningRepo;
  late PronunciationService _pronunciationService;
  late AudioRecorderController _recorder;

  UserProfile? _currentProfile;
  late ExerciseDetail _selectedExercise;

  bool _hasMicPermission = true;
  bool _isAnalyzing = false;
  bool _starting = false;
  bool _active = true;
  bool _leaving = false;
  bool _stopping = false;
  final _scroll = ScrollController();
  String? _analysisStatusMessage;
  AppFailure? _currentError;

  DateTime? _recordingStartTime;
  PronunciationResult? _latestResult;
  bool _isSaved = false;

  Timer? _recordingTimer;
  int _elapsedMilliseconds = 0;
  StreamSubscription<double>? _ampSub;

  bool _useSimulation = false;
  late final AudioRecorderController _realRecorder;
  late final AudioRecorderController _simulatedRecorder;
  late final SpeechRecognizerController _speechRecognizer;
  String _liveTranscript = '';
  StreamSubscription<String>? _sttSub;

  @override
  void initState() {
    super.initState();
    _userRepo = widget.userRepository ?? FakeInternalUserRepository();
    _learningRepo =
        widget.learningRepository ?? FakeInternalLearningRepository();
    _pronunciationService =
        widget.pronunciationService ?? RemotePronunciationService();

    _realRecorder = widget.audioRecorder ?? getPlatformAudioRecorder();
    _simulatedRecorder = SimulatedAudioRecorder();
    _recorder = _useSimulation ? _simulatedRecorder : _realRecorder;

    _speechRecognizer = getPlatformSpeechRecognizer();
    _sttSub = _speechRecognizer.transcriptStream.listen((text) {
      if (mounted) {
        setState(() => _liveTranscript = text);
      }
    });

    _selectedExercise = widget.exercise;

    _initializeAsync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _active = PageActivity.isActive(context);
    if (!_active && !_stopping && (_recorder.isRecording || _starting)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_active) unawaited(_cancelRecording());
      });
    }
  }

  void _toggleRecorder(bool simulation) {
    if (_recorder.isRecording) {
      _recorder.cancelRecording();
      _speechRecognizer.cancel();
    }
    setState(() {
      _useSimulation = simulation;
      _recorder = simulation ? _simulatedRecorder : _realRecorder;
      _pronunciationService = simulation
          ? FakePronunciationService(mode: FakePronunciationMode.realistic)
          : (widget.pronunciationService ?? RemotePronunciationService());
      _currentError = null;
      _liveTranscript = '';
    });
    PronunciationLogger.info(
      'UI',
      'Đã đổi chế độ thu âm sang: ${simulation ? "Mô phỏng mẫu" : "Micro thật"}',
    );
  }

  Future<void> _initializeAsync() async {
    _hasMicPermission = await _recorder.hasPermission();
    _currentProfile = await _userRepo.getSelectedProfile();
    PronunciationLogger.info(
      'INIT',
      'Khởi tạo Phòng luyện phát âm (Hồ sơ: ${_currentProfile?.displayName ?? "Khách"}, Quyền micro: $_hasMicPermission)',
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _leaving = true;
    _scroll.dispose();
    _recordingTimer?.cancel();
    _ampSub?.cancel();
    _sttSub?.cancel();
    _speechRecognizer.dispose();
    if (_recorder.isRecording) {
      _recorder.cancelRecording();
    }
    if (widget.audioRecorder == null) _realRecorder.dispose();
    _simulatedRecorder.dispose();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    PronunciationLogger.info(
      'MIC',
      'Yêu cầu người dùng cấp quyền truy cập micro...',
    );
    final granted = await _recorder.requestPermission();
    PronunciationLogger.info('MIC', 'Kết quả cấp quyền micro: $granted');
    if (mounted) {
      setState(() => _hasMicPermission = granted);
    }
  }

  Future<void> _startRecording() async {
    if (_leaving ||
        !_active ||
        _starting ||
        _isAnalyzing ||
        _stopping ||
        _recorder.isRecording) {
      return;
    }
    _starting = true;
    try {
      _currentProfile = await _userRepo.getSelectedProfile();
      if (!mounted || _leaving || !_active) {
        _starting = false;
        return;
      }
      if (_currentProfile == null) {
        _starting = false;
        setState(
          () => _currentError = const AppFailure(
            AppFailureCode.storage,
            'Hãy chọn tài khoản trước khi luyện.',
          ),
        );
        return;
      }
      PronunciationLogger.info(
        'UI',
        'Bắt đầu thu âm bài: "${_selectedExercise.referenceText}" (Chế độ: ${_useSimulation ? "Mô phỏng" : "Micro thật"})',
      );
      setState(() {
        _currentError = null;
        _latestResult = null;
        _isSaved = false;
        _elapsedMilliseconds = 0;
        _liveTranscript = '';
      });

      await _recorder.startRecording();
      if (!mounted || _leaving || !_active) {
        await _recorder.cancelRecording();
        return;
      }
      _recordingStartTime = DateTime.now().toUtc();

      if (!_useSimulation) {
        try {
          await _speechRecognizer.start(lang: 'en-US');
        } catch (_) {
          // Backend recognition is available without browser live STT.
        }
      }

      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
        if (!mounted || !_recorder.isRecording) return;
        setState(() {
          _elapsedMilliseconds = _recorder.elapsedMilliseconds;
        });
        if (_elapsedMilliseconds >= 60000) unawaited(_stopAndAnalyze());
      });

      if (mounted) setState(() {});
    } on AppFailure catch (e) {
      PronunciationLogger.error(
        'MIC',
        'Lỗi cấp quyền hoặc khởi tạo thu âm: ${e.message}',
        e,
      );
      if (mounted) setState(() => _currentError = e);
    } catch (e, stack) {
      PronunciationLogger.error(
        'MIC',
        'Lỗi không xác định khi bắt đầu thu âm: $e',
        e,
        stack,
      );
      if (!mounted) return;
      setState(() {
        _currentError = AppFailure(AppFailureCode.unknown, e.toString());
      });
    } finally {
      _starting = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _stopAndAnalyze() async {
    if (_leaving || _stopping || _isAnalyzing || !_recorder.isRecording) return;
    final exercise = _selectedExercise;
    final profileId = _currentProfile?.id;
    setState(() => _stopping = true);
    _recordingTimer?.cancel();
    final endTime = DateTime.now().toUtc();
    final startTime =
        _recordingStartTime ?? endTime.subtract(const Duration(seconds: 2));

    var finalTranscript = _liveTranscript;
    if (!_useSimulation) {
      try {
        final sttResult = await _speechRecognizer.stop();
        if (sttResult.isNotEmpty) finalTranscript = sttResult;
      } catch (e) {
        PronunciationLogger.warn(
          'STT',
          'Không thể hoàn tất Speech Recognition: $e',
        );
      }
    }

    AudioSample audio;
    try {
      audio = await _recorder.stopRecording();
      PronunciationLogger.audio(
        'Đã thu được âm thanh: ${audio.bytes.length} bytes, format: ${audio.mimeType}',
      );
    } on AppFailure catch (e) {
      PronunciationLogger.error(
        'AUDIO',
        'Lỗi khi dừng thu âm: ${e.message}',
        e,
      );
      _stopping = false;
      if (mounted) setState(() => _currentError = e);
      return;
    } catch (_) {
      _stopping = false;
      if (mounted) {
        setState(
          () => _currentError = const AppFailure(
            AppFailureCode.invalidAudio,
            'Không hoàn tất được bản ghi. Hãy kiểm tra micro rồi thử lại.',
          ),
        );
      }
      return;
    }

    _stopping = false;
    if (!mounted || _leaving) return;

    setState(() {
      _isAnalyzing = true;
      _analysisStatusMessage = 'Đang nhận dạng và so sánh âm vị từ bản ghi âm…';
      _currentError = null;
    });

    final activeDurationSec = (_elapsedMilliseconds / 1000.0).round().clamp(
      1,
      300,
    );
    final sessionId = 'sess-${DateTime.now().millisecondsSinceEpoch}';

    try {
      final service = _pronunciationService;
      if (service is RemotePronunciationService) {
        service.clientTranscript = finalTranscript.isNotEmpty
            ? finalTranscript
            : null;
      } else if (service is FakePronunciationService) {
        service.latestTranscript = finalTranscript.isNotEmpty
            ? finalTranscript
            : null;
      }

      PronunciationLogger.scoring(
        'Bắt đầu gửi phân tích: Session $sessionId, STT: "$finalTranscript"',
      );

      final result = await _pronunciationService.analyze(
        sessionId: sessionId,
        audio: audio,
        exercise: exercise.exercise,
      );

      if (!mounted || _leaving) return;
      final selected = await _userRepo.getSelectedProfile();
      if (!mounted || _leaving) return;
      if (selected?.id != profileId) {
        throw const AppFailure(
          AppFailureCode.storage,
          'Tài khoản đã thay đổi. Hãy ghi âm lại.',
        );
      }

      final session = PracticeSession(
        id: sessionId,
        userId: profileId!,
        exerciseId: exercise.id,
        startedAt: startTime,
        endedAt: endTime,
        durationSeconds: activeDurationSec,
        status: PracticeStatus.completed,
      );

      await _learningRepo.savePractice(session: session, result: result);
      PronunciationLogger.info(
        'DB',
        'Đã lưu phiên $sessionId vào LearningRepository thành công',
      );

      if (mounted) {
        setState(() {
          _latestResult = result;
          _isAnalyzing = false;
          _isSaved = true;
        });
      }
    } on AppFailure catch (e) {
      PronunciationLogger.error(
        'API',
        'Lỗi phân tích phát âm (${e.code.name}): ${e.message}',
        e,
      );
      if (mounted) {
        setState(() {
          _currentError = e;
          _isAnalyzing = false;
        });
      }
    } catch (e, stack) {
      PronunciationLogger.error(
        'API',
        'Ngoại lệ không xác định khi chấm điểm: $e',
        e,
        stack,
      );
      if (mounted) {
        setState(() {
          _currentError = AppFailure(
            AppFailureCode.unknown,
            'Đã xảy ra lỗi không xác định: $e',
          );
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<void> _cancelRecording() async {
    _recordingTimer?.cancel();
    _speechRecognizer.cancel();
    await _recorder.cancelRecording();
    PronunciationLogger.info('UI', 'Đã hủy phiên ghi âm.');
    if (mounted) {
      setState(() {
        _elapsedMilliseconds = 0;
        _liveTranscript = '';
      });
    }
  }

  void _selectExercise(ExerciseDetail ex) {
    if (_starting || _stopping || _isAnalyzing) return;
    PronunciationLogger.info(
      'UI',
      'Người dùng chọn bài mới: "${ex.referenceText}" (ID: ${ex.id})',
    );
    if (_recorder.isRecording) {
      _recorder.cancelRecording();
      _speechRecognizer.cancel();
    }
    setState(() {
      _selectedExercise = ex;
      _latestResult = null;
      _currentError = null;
      _isSaved = false;
      _liveTranscript = '';
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _onLeave() {
    _leaving = true;
    _recordingTimer?.cancel();
    _speechRecognizer.cancel();
    if (_recorder.isRecording) unawaited(_recorder.cancelRecording());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope<void>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _onLeave();
      },
      child: Scaffold(
        key: const ValueKey('practice-detail'),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 4,
                children: [
                  TextButton.icon(
                    key: const ValueKey('back-to-exercises'),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    label: const Text('Danh sách bài luyện'),
                  ),
                  Text(
                    'Nghe mẫu · Luyện nói · Nhận phản hồi',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 900;
                  return SingleChildScrollView(
                    controller: _scroll,
                    padding: EdgeInsets.all(wide ? 28 : 16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (const bool.fromEnvironment(
                              'ENABLE_SIMULATION',
                            )) ...[
                              SegmentedButton<bool>(
                                segments: const [
                                  ButtonSegment(
                                    value: false,
                                    icon: Icon(Icons.mic_rounded),
                                    label: Text('Micro thật'),
                                  ),
                                  ButtonSegment(
                                    value: true,
                                    icon: Icon(Icons.science_outlined),
                                    label: Text('Mô phỏng'),
                                  ),
                                ],
                                selected: {_useSimulation},
                                onSelectionChanged:
                                    _recorder.isRecording || _isAnalyzing
                                    ? null
                                    : (values) => _toggleRecorder(values.first),
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (wide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: _buildExerciseFocus(theme),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    flex: 4,
                                    child: _recordingCard(theme),
                                  ),
                                ],
                              )
                            else ...[
                              _buildExerciseFocus(theme),
                              const SizedBox(height: 20),
                              _recordingCard(theme),
                            ],
                            if (_latestResult != null) ...[
                              const SizedBox(height: 28),
                              Text(
                                'Phản hồi sau luyện tập',
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              _buildResults(theme),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recordingCard(ThemeData theme) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.mic_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ghi âm của bạn',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Nghe mẫu, đọc trọn câu rồi dừng ghi âm để AI phân tích.'),
          _buildRecordingPanel(theme),
        ],
      ),
    ),
  );

  Widget _buildExerciseFocus(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _selectedExercise.category,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _selectedExercise.difficulty,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AudioSamplePlayer(
                referenceText: _selectedExercise.referenceText,
                sampleUri: _selectedExercise.sampleAudioUri,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Reference Text in large display font
          SelectableText(
            _selectedExercise.referenceText,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          // Reference IPA transcription
          SelectableText(
            _selectedExercise.referenceIpa,
            style: theme.textTheme.titleMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.primary,
              fontFamily: 'NotoSans',
            ),
          ),
          const SizedBox(height: 16),
          // Target phonemes tag list
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Âm mục tiêu:',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              for (final p in _selectedExercise.targetPhonemes)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '/$p/',
                    style: TextStyle(
                      fontFamily: 'NotoSans',
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSecondaryContainer,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // Vietnamese tip for articulatory positioning
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.tips_and_updates_outlined,
                  size: 20,
                  color: Colors.amber,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedExercise.vietnameseTip,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingPanel(ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 18),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          'Điểm thể hiện độ khớp âm vị được mô hình nhận dạng với mẫu IPA. Mô hình có thể nhận nhầm; hãy nghe lại và đối chiếu các âm được gợi ý.',
          style: TextStyle(fontSize: 12, color: Color(0xFF69718D)),
        ),
      ),
      const SizedBox(height: 12),

      // Live Waveform visualizer
      WaveformVisualizer(
        amplitudeStream: _recorder.amplitudeStream,
        isRecording: _recorder.isRecording,
      ),
      const SizedBox(height: 12),

      // Live Speech-to-Text banner during recording
      SpeechTranscriptView(
        referenceText: _selectedExercise.referenceText,
        liveTranscript: _liveTranscript,
        isRecording: _recorder.isRecording,
      ),
      const SizedBox(height: 12),

      // Recording Controller
      if (!_isAnalyzing && !_starting && !_stopping)
        RecordingControlBar(
          isRecording: _recorder.isRecording,
          elapsedMilliseconds: _elapsedMilliseconds,
          hasPermission: _hasMicPermission,
          onStartRecording: _startRecording,
          onStopRecording: _stopAndAnalyze,
          onCancelRecording: _cancelRecording,
          onRequestPermission: _requestPermission,
        ),
      const SizedBox(height: 20),

      // Analyzing State
      if (_isAnalyzing || _starting || _stopping) ...[
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 18),
              Text(
                _analysisStatusMessage ?? 'Đang phân tích phát âm…',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Đang xử lý bản ghi và đối chiếu chuỗi âm vị với mẫu IPA',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],

      // Error State
      if (_currentError != null) ...[
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Không thể chấm điểm bản ghi',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: const Color(0xFFDC2626),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _currentError!.message,
                style: const TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: _startRecording,
                  child: const Text('Thử ghi âm lại'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    ],
  );

  Widget _buildResults(ThemeData theme) {
    final recommendations = _latestResult != null
        ? DefaultExercises.getRecommendations(
            _latestResult!.phonemes,
            currentExerciseId: _selectedExercise.id,
          )
        : <ImprovementRecommendation>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Result Diagnostic View
        if (_latestResult != null) ...[
          // Overall Score Badge
          OverallScoreBadge(score: _latestResult!.overallScore),
          const SizedBox(height: 16),

          // Detailed speech transcript comparison
          SpeechTranscriptView(
            referenceText: _selectedExercise.referenceText,
            liveTranscript: '',
            isRecording: false,
            finalRecognizedText: _latestResult!.recognizedText,
          ),
          const SizedBox(height: 16),

          // Recognized Text feedback
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nội dung nhận dạng được:',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '"${_latestResult!.recognizedText}"',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Mô hình: ${_latestResult!.provider} (${_latestResult!.modelVersion})',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_isSaved)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_done_rounded,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Đã lưu kết quả',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Detailed Phoneme Breakdown
          PhonemeFeedbackTable(phonemes: _latestResult!.phonemes),
          const SizedBox(height: 20),

          // Follow-up Targeted Improvement Exercises
          if (recommendations.isNotEmpty) ...[
            Text(
              'Bài tập cải thiện theo lỗi âm vừa phát hiện',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Các bài dưới có chứa âm cần luyện trong phiên âm chuẩn:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            for (final rec in recommendations)
              ImprovementExerciseCard(
                recommendation: rec,
                onStartPractice: () => _selectExercise(rec.suggestedExercise),
              ),
          ],
        ],
      ],
    );
  }
}
