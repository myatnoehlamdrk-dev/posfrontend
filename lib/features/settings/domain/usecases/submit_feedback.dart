import 'package:posfrontend/core/base/use_case.dart';
import 'package:posfrontend/features/settings/domain/entities/feedback.dart';
import 'package:posfrontend/features/settings/domain/repositories/feedback_repository.dart';

class SubmitFeedbackUseCase
    extends UseCase<FeedbackEntity, SubmitFeedbackParams> {
  final FeedbackRepository repository;

  SubmitFeedbackUseCase(this.repository);

  @override
  Future<FeedbackEntity> call(SubmitFeedbackParams params) {
    return repository.submitFeedback(
      type: params.type,
      message: params.message,
    );
  }
}

class SubmitFeedbackParams {
  final FeedbackType type;
  final String message;

  SubmitFeedbackParams({required this.type, required this.message});
}
