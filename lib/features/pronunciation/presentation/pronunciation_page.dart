// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:flutter/material.dart';
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
import 'widgets/exercise_card.dart';
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
class PronunciationPage extends StatefulWidget {
  const PronunciationPage({
    super.key,
    this.userRepository,
    this.learningRepository,
    this.pronunciationService,
    this.audioRecorder,
    this.exercises,
  });

  final UserRepository? userRepository;
  final LearningRepository? learningRepository;
  final PronunciationService? pronunciationService;
  final AudioRecorderController? audioRecorder;
  final List<ExerciseDetail>? exercises;

  @override
  State<PronunciationPage> createState() => _PronunciationPageState();
}

class _PronunciationPageState extends State<PronunciationPage> {
  late final UserRepository _userRepo;
  late final LearningRepository _learningRepo;
  late PronunciationService _pronunciationService;
  late AudioRecorderController _recorder;
  late final List<ExerciseDetail> _catalog;

  UserProfile? _currentProfile;
  late ExerciseDetail _selectedExercise;
  String _selectedCategory = 'Tất cả';

  bool _hasMicPermission = true;
  bool _isAnalyzing = false;
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
    _learningRepo = widget.learningRepository ?? FakeInternalLearningRepository();
    _pronunciationService =
        widget.pronunciationService ?? RemotePronunciationService();
    _catalog = widget.exercises ?? DefaultExercises.catalog;

    _realRecorder = widget.audioRecorder ?? getPlatformAudioRecorder();
    _simulatedRecorder = SimulatedAudioRecorder();
    _recorder = _useSimulation ? _simulatedRecorder : _realRecorder;

    _speechRecognizer = getPlatformSpeechRecognizer();
    _sttSub = _speechRecognizer.transcriptStream.listen((text) {
      if (mounted) {
        setState(() => _liveTranscript = text);
      }
    });

    _selectedExercise = _catalog.first;

    _initializeAsync();
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
    _recordingTimer?.cancel();
    _ampSub?.cancel();
    _sttSub?.cancel();
    _speechRecognizer.dispose();
    if (_recorder.isRecording) {
      _recorder.cancelRecording();
    }
    super.dispose();
  }

  Future<void> _requestPermission() async {
    PronunciationLogger.info('MIC', 'Yêu cầu người dùng cấp quyền truy cập micro...');
    final granted = await _recorder.requestPermission();
    PronunciationLogger.info('MIC', 'Kết quả cấp quyền micro: $granted');
    if (mounted) {
      setState(() => _hasMicPermission = granted);
    }
  }

  Future<void> _startRecording() async {
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

    try {
      await _recorder.startRecording();
      _recordingStartTime = DateTime.now().toUtc();

      if (!_useSimulation) {
        _speechRecognizer.start(lang: 'en-US');
      }

      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
        if (!mounted || !_recorder.isRecording) return;
        setState(() {
          _elapsedMilliseconds = _recorder.elapsedMilliseconds;
        });
      });

      setState(() {});
    } on AppFailure catch (e) {
      PronunciationLogger.error('MIC', 'Lỗi cấp quyền hoặc khởi tạo thu âm: ${e.message}', e);
      setState(() => _currentError = e);
    } catch (e, stack) {
      PronunciationLogger.error('MIC', 'Lỗi không xác định khi bắt đầu thu âm: $e', e, stack);
      setState(() {
        _currentError = AppFailure(AppFailureCode.unknown, e.toString());
      });
    }
  }

  Future<void> _stopAndAnalyze() async {
    _recordingTimer?.cancel();
    final endTime = DateTime.now().toUtc();
    final startTime = _recordingStartTime ?? endTime.subtract(const Duration(seconds: 2));

    var finalTranscript = _liveTranscript;
    if (!_useSimulation) {
      try {
        final sttResult = await _speechRecognizer.stop();
        if (sttResult.isNotEmpty) finalTranscript = sttResult;
      } catch (e) {
        PronunciationLogger.warn('STT', 'Không thể hoàn tất Speech Recognition: $e');
      }
    }

    AudioSample audio;
    try {
      audio = await _recorder.stopRecording();
      PronunciationLogger.audio(
        'Đã thu được âm thanh: ${audio.bytes.length} bytes, format: ${audio.mimeType}',
      );
    } on AppFailure catch (e) {
      PronunciationLogger.error('AUDIO', 'Lỗi khi dừng thu âm: ${e.message}', e);
      setState(() => _currentError = e);
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisStatusMessage = 'Đang phân tích âm vị từ giọng thật và phiên âm Speech-to-Text…';
      _currentError = null;
    });

    final activeDurationSec =
        (_elapsedMilliseconds / 1000.0).round().clamp(1, 300);
    final sessionId = 'sess-${DateTime.now().millisecondsSinceEpoch}';

    try {
      final service = _pronunciationService;
      if (service is RemotePronunciationService) {
        service.clientTranscript =
            finalTranscript.isNotEmpty ? finalTranscript : null;
      } else if (service is FakePronunciationService) {
        service.latestTranscript =
            finalTranscript.isNotEmpty ? finalTranscript : null;
      }

      PronunciationLogger.scoring(
        'Bắt đầu gửi phân tích: Session $sessionId, STT: "$finalTranscript"',
      );

      final result = await _pronunciationService.analyze(
        sessionId: sessionId,
        audio: audio,
        exercise: _selectedExercise.exercise,
      );

      PronunciationLogger.scoring(
        'Kết quả nhận được: Điểm overall = ${result.overallScore}, Nhận dạng = "${result.recognizedText}"',
      );

      final session = PracticeSession(
        id: sessionId,
        userId: _currentProfile?.id ?? 'user-default',
        exerciseId: _selectedExercise.id,
        startedAt: startTime,
        endedAt: endTime,
        durationSeconds: activeDurationSec,
        status: PracticeStatus.completed,
      );

      await _learningRepo.savePractice(session: session, result: result);
      PronunciationLogger.info('DB', 'Đã lưu phiên $sessionId vào LearningRepository thành công');

      if (mounted) {
        setState(() {
          _latestResult = result;
          _isAnalyzing = false;
          _isSaved = true;
        });
      }
    } on AppFailure catch (e) {
      PronunciationLogger.error('API', 'Lỗi phân tích phát âm (${e.code.name}): ${e.message}', e);
      if (mounted) {
        setState(() {
          _currentError = e;
          _isAnalyzing = false;
        });
      }
    } catch (e, stack) {
      PronunciationLogger.error('API', 'Ngoại lệ không xác định khi chấm điểm: $e', e, stack);
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
    PronunciationLogger.info('UI', 'Người dùng chọn bài mới: "${ex.referenceText}" (ID: ${ex.id})');
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = [
      'Tất cả',
      ...{for (final e in _catalog) e.category},
    ];

    final filteredExercises = _selectedCategory == 'Tất cả'
        ? _catalog
        : _catalog.where((e) => e.category == _selectedCategory).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: 20),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Exercise Browser (380px)
                        SizedBox(
                          width: 380,
                          child: _buildExerciseCatalog(
                            theme,
                            categories,
                            filteredExercises,
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Right Column: Practice Studio & Diagnostic View
                        Expanded(child: _buildPracticeStudio(theme)),
                      ],
                    )
                  else ...[
                    _buildPracticeStudio(theme),
                    const SizedBox(height: 28),
                    _buildExerciseCatalog(
                      theme,
                      categories,
                      filteredExercises,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.mic_rounded, size: 28, color: theme.colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Luyện phát âm với AI · Module Vũ Hải Đăng',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Phân tích âm vị, chấm điểm GOP và đề xuất bài tập cải thiện',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.mic_rounded, size: 16),
                    label: Text('Micro thật', style: TextStyle(fontSize: 12)),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.graphic_eq_rounded, size: 16),
                    label: Text('Mô phỏng', style: TextStyle(fontSize: 12)),
                  ),
                ],
                selected: {_useSimulation},
                onSelectionChanged: (set) => _toggleRecorder(set.first),
              ),
              if (_currentProfile != null) ...[
                const SizedBox(width: 12),
                Chip(
                  avatar: const Icon(Icons.person_outline, size: 16),
                  label: Text(_currentProfile!.displayName),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeStudio(ThemeData theme) {
    final recommendations = _latestResult != null
        ? DefaultExercises.getRecommendations(
            _latestResult!.phonemes,
            currentExerciseId: _selectedExercise.id,
          )
        : <ImprovementRecommendation>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Exercise Focus Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  const Spacer(),
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
                  fontFamily: 'monospace',
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '/$p/',
                        style: TextStyle(
                          fontFamily: 'monospace',
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
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

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
          finalRecognizedText: _latestResult?.recognizedText,
        ),
        const SizedBox(height: 12),

        // Recording Controller
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
        if (_isAnalyzing) ...[
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
                  'Đang tính toán độ lệch âm học và đối chiếu với mẫu IPA',
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
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626)),
                    const SizedBox(width: 10),
                    Text(
                      'Không thể chấm điểm bản ghi',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: const Color(0xFFDC2626),
                        fontWeight: FontWeight.bold,
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
              'AI gợi ý bài luyện chuyên sâu cho các âm vị đạt điểm thấp:',
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

  Widget _buildExerciseCatalog(
    ThemeData theme,
    List<String> categories,
    List<ExerciseDetail> exercises,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Danh sách bài luyện',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${exercises.length} bài',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.map((cat) {
              final isSel = cat == _selectedCategory;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text(cat),
                  selected: isSel,
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        // Exercise cards
        for (final ex in exercises)
          ExerciseCard(
            exerciseDetail: ex,
            isSelected: ex.id == _selectedExercise.id,
            onTap: () => _selectExercise(ex),
          ),
      ],
    );
  }
}
