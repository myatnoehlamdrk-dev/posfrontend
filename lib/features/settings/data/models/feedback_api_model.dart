import 'package:posfrontend/features/settings/domain/entities/feedback.dart';

class FeedbackApiModel {
  static FeedbackEntity fromJson(Map<String, dynamic> json) {
    return FeedbackEntity(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      shopId: json['shopId']?.toString() ?? '',
      type: FeedbackType.fromValue(json['type'] as String?),
      message: json['message'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      userEmail: json['userEmail'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}
