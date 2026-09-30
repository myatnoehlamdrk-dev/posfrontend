import 'package:equatable/equatable.dart';

/// The three kinds the Settings > Feedback dialog can submit. The wire values
/// are the API's snake_case, so they are kept separate from the labels the UI
/// shows.
enum FeedbackType {
  comment('comment', 'Comment'),
  suggestion('suggestion', 'Suggestion'),
  bugReport('bug_report', 'Bug Report');

  const FeedbackType(this.value, this.label);

  final String value;
  final String label;

  static FeedbackType fromValue(String? value) {
    return FeedbackType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => FeedbackType.comment,
    );
  }
}

class FeedbackEntity extends Equatable {
  final String id;
  final String userId;
  final String shopId;
  final FeedbackType type;
  final String message;
  final String userName;
  final String userEmail;
  final DateTime? createdAt;

  const FeedbackEntity({
    required this.id,
    required this.userId,
    required this.shopId,
    required this.type,
    required this.message,
    this.userName = '',
    this.userEmail = '',
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, userId, shopId, type, message, createdAt];
}
