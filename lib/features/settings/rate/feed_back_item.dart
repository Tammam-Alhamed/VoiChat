class FeedbackItem {
  final double rating;
  final String comment;

  FeedbackItem({required this.rating, required this.comment});

  factory FeedbackItem.fromJson(Map<String, dynamic> json) {
    return FeedbackItem(
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      comment: json['comment']?.toString() ?? '',
    );
  }
}

class CallRatingModel {
  final double averageRating;
  final List<FeedbackItem> recentFeedback;

  CallRatingModel({required this.averageRating, required this.recentFeedback});

  factory CallRatingModel.fromJson(Map<String, dynamic> json) {
    var list = json['recentFeedback'] as List? ?? [];
    List<FeedbackItem> feedbackList = list
        .map((i) => FeedbackItem.fromJson(i))
        .toList();

    return CallRatingModel(
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      recentFeedback: feedbackList,
    );
  }

  factory CallRatingModel.empty() {
    return CallRatingModel(averageRating: 0.0, recentFeedback: []);
  }

  factory CallRatingModel.mock() {
    return CallRatingModel(
      averageRating: 4.5,
      recentFeedback: [
        FeedbackItem(rating: 5.0, comment: "Great call"),
        FeedbackItem(rating: 4.0, comment: "Good connection"),
        FeedbackItem(rating: 3.0, comment: "Slight delay"),
      ],
    );
  }
}
