import 'package:posfrontend/features/settings/domain/entities/feedback.dart';

abstract class FeedbackRepository {
  Future<FeedbackEntity> submitFeedback({
    required FeedbackType type,
    required String message,
  });
}
