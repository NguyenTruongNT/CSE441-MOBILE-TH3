/// Pronunciation AI module for English speech analysis and assessment.
///
/// Owned by Vũ Hải Đăng. Implements [PronunciationService] and provides
/// real-time audio recording, GOP scoring, IPA alignment, and diagnostic UI.
library;

export 'data/audio_sample_fixtures.dart';
export 'data/default_exercises.dart';
export 'data/fake_pronunciation_repository.dart';
export 'domain/audio_recorder.dart';
export 'domain/audio_validator.dart';
export 'domain/exercise_models.dart';
export 'domain/phoneme_scoring_engine.dart';
export 'presentation/pronunciation_page.dart';
export 'presentation/widgets/audio_sample_player.dart';
export 'presentation/widgets/exercise_card.dart';
export 'presentation/widgets/improvement_exercise_card.dart';
export 'presentation/widgets/overall_score_badge.dart';
export 'presentation/widgets/phoneme_feedback_table.dart';
export 'presentation/widgets/recording_control_bar.dart';
export 'presentation/widgets/waveform_visualizer.dart';
export 'services/audio_recorder_service.dart';
export 'services/fake_pronunciation_service.dart';
export 'services/remote_pronunciation_service.dart';
