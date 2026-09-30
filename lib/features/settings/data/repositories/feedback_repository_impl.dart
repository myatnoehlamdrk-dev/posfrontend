import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/settings/data/models/feedback_api_model.dart';
import 'package:posfrontend/features/settings/domain/entities/feedback.dart';
import 'package:posfrontend/features/settings/domain/repositories/feedback_repository.dart';

class FeedbackRepositoryImpl implements FeedbackRepository {
  final dio = ApiClient.create();

  @override
  Future<FeedbackEntity> submitFeedback({
    required FeedbackType type,
    required String message,
  }) async {
    final response = await dio.post(
      '/api/feedback',
      data: {'type': type.value, 'message': message},
    );

    return FeedbackApiModel.fromJson(response.data as Map<String, dynamic>);
  }
}
