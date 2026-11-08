import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/helpers/store_helper.dart';
import '../../core/helpers/wallet_helper.dart';
import '../../core/network/service_helper.dart';
import '../../core/utils/api_status.dart';
import '../../core/widgets/app_state_view.dart';
import '../../core/themes/app_dark_colors.dart';
import '../../app/di/injection_container.dart';
import '../../testlivekit/ranking_sheet.dart';

/// Real, backend-fed global leaderboard (hosts ranked by total gift value
/// received while streaming). Reuses the exact same
/// `GET /v1/live/ranking/top-creators` endpoint, and the shared
/// `RankingEntry`/`RankingAvatar`/`RankingListView` widgets, that already
/// power the in-live-room "Top Creators" tab — so this screen and that
/// sheet can never visually drift apart, and there's a single source of
/// truth for the ranking query. "Trending" maps to the `all` (all-time)
/// period, giving it a real, distinct meaning instead of duplicating
/// Weekly's content.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.shellBackground,
      body: SafeArea(
        child: Column(
          children: [
            // 1. الشريط العلوي (App Bar مع TabBar)
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: context.shellTextPrimary),
                  onPressed: () => Navigator.maybePop(context),
                ),
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    labelColor: context.shellTextPrimary,
                    unselectedLabelColor: const Color(0xFF7A7A7A),
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    indicatorColor: context.shellTextPrimary,
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: const [
                      Tab(text: "Daily"),
                      Tab(text: "Weekly"),
                      Tab(text: "Trending"),
                    ],
                  ),
                ),
              ],
            ),
            Container(height: 1, color: const Color(0xFFEDEDED)), // خط فاصل
            // 2. المحتوى (الرانك) — كل تبويبة تجلب بياناتها الحقيقية الخاصة
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _LeaderboardTab(period: 'daily'),
                  _LeaderboardTab(period: 'weekly'),
                  _LeaderboardTab(period: 'all'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardTab extends StatefulWidget {
  final String period;

  const _LeaderboardTab({required this.period});

  @override
  State<_LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<_LeaderboardTab> {
  final ServiceHelper _serviceHelper = sl<ServiceHelper>();
  final StoreHelper _storeHelper = sl<StoreHelper>();

  bool _isLoading = true;
  bool _hasError = false;
  List<RankingEntry> _entries = [];
  RankingEntry? _myRank;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final token = _storeHelper.getAccessToken();
      final response = await _serviceHelper.getHelper(
        target: '/v1/live/ranking/top-creators?period=${widget.period}',
        token: token,
      );

      if (response is Success) {
        final Map<String, dynamic> body = response.data is String
            ? jsonDecode(response.data as String)
            : response.data as Map<String, dynamic>;
        final data = body['data'];
        final List<dynamic> rows = data?['data'] ?? [];
        final myRankJson = data?['myRank'];
        _entries = rows
            .map((e) => RankingEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        _myRank = myRankJson != null
            ? RankingEntry.fromJson(myRankJson as Map<String, dynamic>)
            : null;
        setState(() => _isLoading = false);
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (_) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return AppStateView.error(onRetry: _load);
    }

    return RankingListView(
      isLoading: _isLoading,
      error: null,
      entries: _entries,
      emptyText: 'No creators ranked yet',
      onRetry: _load,
      bottomBar: _myRank == null ? null : _buildMyRankBar(_myRank!),
    );
  }

  // Only rendered for the requesting host herself when she's outside the
  // public Top 50 — mirrors the in-live-room Top Creators tab exactly.
  Widget _buildMyRankBar(RankingEntry entry) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#${entry.rank}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          RankingAvatar(url: entry.profileImage, radius: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Your personal rank',
                  style: TextStyle(color: Color(0xFF7A7A7A), fontSize: 12),
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(
                Icons.diamond_outlined,
                color: Colors.blueAccent,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                WalletHelper.format(entry.coins),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
