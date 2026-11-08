import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:shoeebapk/core/constants.dart';
import 'package:shoeebapk/core/enums/page_state.dart';
import 'package:shoeebapk/core/helpers/avatar_helper.dart';
import 'package:shoeebapk/core/helpers/wallet_helper.dart';
import '../../core/widgets/app_state_view.dart';
import '../../core/themes/app_dark_colors.dart';
import 'state/performance_state_provider.dart';

import 'package:get/get.dart';
import '../session/presentation/controllers/session_controller.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  String userName = 'User';
  String profileId = '';
  String? avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PerformanceStateProvider>().getPerformance();
    });
  }

  void _loadUserInfo() {
    try {
      setState(() {
        userName = Get.find<SessionController>().session!.user!.name;
        profileId = Get.find<SessionController>().session!.user!.profileId!;
        avatarUrl = Get.find<SessionController>().session!.user!.profileImage;
      });
    } catch (e) {
      debugPrint('Error loading user info in PerformanceScreen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PerformanceStateProvider>();
    final currentMonthName = DateFormat('MMMM').format(DateTime.now());

    return Scaffold(
      backgroundColor: context.shellBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.maybePop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: context.shellTextPrimary,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Performance',
                    style: TextStyle(
                      color: context.shellTextPrimary,
                      fontSize: 18,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.02,
                    ),
                  ),
                ],
              ),
            ),

            // 2. Content
            Expanded(child: _buildBody(provider, currentMonthName)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    PerformanceStateProvider provider,
    String currentMonthName,
  ) {
    if (provider.pageState == PageState.error) {
      return AppStateView.error(
        message: provider.error ?? "Failed to load performance data",
        onRetry: () => provider.retry(),
      );
    }

    final isSkeletonEnabled = provider.pageState == PageState.loading;
    final performance = provider.performanceData;

    return Skeletonizer(
      enabled: isSkeletonEnabled,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User profile card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFEDEDED), width: 1),
              ),
              child: Row(
                children: [
                  // User image
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDEDED),
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AvatarHelper.resolve(
                          avatarUrl != null && avatarUrl!.isNotEmpty
                              ? (avatarUrl!.startsWith('http')
                                    ? avatarUrl!
                                    : '${Constants.imageUrl}$avatarUrl')
                              : avatarUrl,
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Name & ID
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: TextStyle(
                            color: context.shellTextPrimary,
                            fontSize: 18,
                            fontFamily: 'SF Pro',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profileId.isNotEmpty
                              ? 'ID: $profileId'
                              : 'ID: --------',
                          style: const TextStyle(
                            color: Color(0xFF7A7A7A),
                            fontSize: 14,
                            fontFamily: 'Open Sans',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Month/Title
            Text(
              currentMonthName,
              style: TextStyle(
                color: context.shellTextPrimary,
                fontSize: 24,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Today / Week / Month Filter
            _buildTimeFilter(provider),

            const SizedBox(height: 32),

            // Stat Cards
            _buildStatCard(
              title: 'Earning',
              value: isSkeletonEnabled
                  ? '999'
                  : '\$${WalletHelper.format(performance.earning)}',
              icon: Icons.monetization_on_outlined,
              barData: [
                2,
                9,
                isSkeletonEnabled ? 50 : (performance.earning > 0 ? 30.0 : 0.0),
              ],
            ),
            _buildStatCard(
              title: 'Stream Time',
              value: isSkeletonEnabled
                  ? '2 hr 45 min'
                  : '${performance.hours} hr ${performance.minutes} min',
              icon: Icons.access_time,
              barData: [
                2,
                9,
                isSkeletonEnabled ? 40 : (performance.seconds > 0 ? 46.0 : 0.0),
              ],
            ),
            _buildStatCard(
              title: 'Total Viewers',
              value: isSkeletonEnabled ? '999' : '${performance.totalViewers}',
              icon: Icons.visibility_outlined,
              barData: [
                2,
                9,
                isSkeletonEnabled
                    ? 30
                    : (performance.totalViewers > 0 ? 14.0 : 0.0),
              ],
            ),
            _buildStatCard(
              title: 'New Followers',
              value: isSkeletonEnabled ? '99' : '${performance.newFollowers}',
              icon: Icons.person_add_alt_1_outlined,
              barData: [
                2,
                9,
                isSkeletonEnabled
                    ? 20
                    : (performance.newFollowers > 0 ? 58.0 : 0.0),
              ],
              showDivider: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFilter(PerformanceStateProvider provider) {
    List<String> options = ['Today', 'Week', 'Month'];

    return Container(
      width: 220,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDED),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: options.map((option) {
          bool isSelected = provider.selectedFilter == option;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                provider.setSelectedFilter(option);
              },
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF131A34)
                        : const Color(0xFF7A7A7A),
                    fontSize: 14,
                    fontFamily: 'Roboto',
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required List<double> barData,
    bool showDivider = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: context.shellTextPrimary,
            fontSize: 18,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(icon, size: 22, color: context.shellTextSecondary),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                color: context.shellTextPrimary,
                fontSize: 20,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: barData.map((height) {
                bool isLast = barData.indexOf(height) == barData.length - 1;
                return Container(
                  width: 12,
                  height: height == 0 ? 2 : height,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    color: isLast
                        ? const Color(0xFF6044FF)
                        : const Color(0xFFEDEDED),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        if (showDivider) ...[
          const SizedBox(height: 24),
          Container(
            height: 1,
            width: double.infinity,
            color: const Color(0xFFBBBBBB).withOpacity(0.5),
          ),
          const SizedBox(height: 24),
        ] else ...[
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}
