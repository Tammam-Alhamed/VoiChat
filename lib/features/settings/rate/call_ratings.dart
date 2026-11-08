import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:shoeebapk/core/enums/page_state.dart';

import '../../../core/widgets/app_state_view.dart';
import '../state/call_rating_state_provider.dart';
import 'feed_back_item.dart';

class CallRatingScreen extends StatefulWidget {
  const CallRatingScreen({super.key});

  @override
  State<CallRatingScreen> createState() => _CallRatingScreenState();
}

class _CallRatingScreenState extends State<CallRatingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CallRatingStateProvider>().getRatingSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Call Rating',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: Consumer<CallRatingStateProvider>(
          builder: (context, provider, child) {
            if (provider.pageState == PageState.error) {
              return AppStateView.error(
                message: provider.error,
                onRetry: () => provider.retry(),
              );
            }

            final isLoading = provider.pageState == PageState.loading;
            // Inject dynamic runtime api values or temporary mock values for structure construction
            final data = isLoading
                ? CallRatingModel.mock()
                : provider.ratingData;

            return Skeletonizer(
              enabled: isLoading,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Overall Rating Card
                    _buildOverallRatingCard(rating: data.averageRating),

                    const SizedBox(height: 32),

                    // 2. Recent Feedback Section
                    const Text(
                      "Recent Feedback",
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Based on recent calls",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Dynamic handling of list arrays injected directly without mutating elements
                    _buildRecentFeedbackCard(data.recentFeedback),

                    const SizedBox(height: 32),

                    // 3. Low Rating Warning Alert (Only show when rating is drops under 3.5)
                    if (data.averageRating < 3.5 || isLoading)
                      _buildWarningCard(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ==========================================
  // Overall Rating Card (Top Section)
  // ==========================================
  Widget _buildOverallRatingCard({required double rating}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                rating.toString(),
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 48,
                  height: 1.0,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  "/ 5.0",
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStarsRow(rating: rating, starSize: 32),
          const SizedBox(height: 24),

          // Dynamic Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              height: 12,
              color: const Color(0xFFF0F4F8),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: rating > 5.0 ? 1.0 : (rating / 5.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // Recent Feedback List Card
  // ==========================================
  Widget _buildRecentFeedbackCard(List<FeedbackItem> feedbackItems) {
    if (feedbackItems.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: Text("No feedback received yet")),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: feedbackItems.length,
        separatorBuilder: (context, index) =>
            Divider(height: 24, color: Colors.grey.shade100),
        itemBuilder: (context, index) {
          return _buildFeedbackRow(rating: feedbackItems[index].rating);
        },
      ),
    );
  }

  // ==========================================
  // Single Feedback Row
  // ==========================================
  Widget _buildFeedbackRow({required double rating}) {
    Color ratingColor;
    if (rating >= 4.0) {
      ratingColor = const Color(0xFF2E7D32);
    } else if (rating >= 3.0) {
      ratingColor = const Color(0xFFF57F17);
    } else {
      ratingColor = const Color(0xFFD32F2F);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStarsRow(rating: rating, starSize: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: ratingColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              rating == rating.toInt().toDouble()
                  ? rating.toInt().toString()
                  : rating.toString(),
              style: TextStyle(
                color: ratingColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // Low Rating Warning Card (Modern Alert)
  // ==========================================
  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFECB3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE082).withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFF57F17),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Attention Needed",
                  style: TextStyle(
                    color: Color(0xFFB71C1C),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Some recent calls were rated below 3 stars. Consider reviewing your connection or call quality.",
                  style: TextStyle(
                    color: Colors.orange.shade900.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // Dynamic Star Builder
  // ==========================================
  Widget _buildStarsRow({required double rating, required double starSize}) {
    List<Widget> stars = [];
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;

    for (int i = 1; i <= 5; i++) {
      if (i <= fullStars) {
        stars.add(
          Icon(
            Icons.star_rounded,
            color: const Color(0xFFFFC107),
            size: starSize,
          ),
        );
      } else if (i == fullStars + 1 && hasHalfStar) {
        stars.add(
          Icon(
            Icons.star_half_rounded,
            color: const Color(0xFFFFC107),
            size: starSize,
          ),
        );
      } else {
        stars.add(
          Icon(
            Icons.star_border_rounded,
            color: Colors.grey.shade300,
            size: starSize,
          ),
        );
      }
      if (i < 5) stars.add(const SizedBox(width: 2));
    }

    return Row(mainAxisSize: MainAxisSize.min, children: stars);
  }
}
