import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shoeebapk/core/assets_manager.dart';
import 'package:shoeebapk/core/helpers/avatar_helper.dart';
import 'package:shoeebapk/core/helpers/wallet_helper.dart';

import '../app/di/injection_container.dart';
import '../core/network/service_helper.dart';
import '../core/helpers/store_helper.dart';
import '../core/utils/api_status.dart';

/// Opens the shared Ranking bottom sheet. [liveId] scopes the "Daily
/// Ranking" (supporters of the current host) tab; "Top Creators" is
/// global and doesn't depend on the live room at all. [isHost] is kept
/// for future use (e.g. highlighting), but both tabs are visible to
/// hosts and viewers alike per spec.
void showRankingSheet(
  BuildContext context, {
  required String liveId,
  required String hostId,
  bool isHost = false,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => RankingSheet(liveId: liveId, hostId: hostId),
  );
}

/// One row of ranking data, shared by both tabs so the UI (podium + list
/// row widgets) is identical no matter which endpoint filled it — only
/// the content/permissions differ per the product spec.
class RankingEntry {
  final int rank;
  final String userId;
  final String name;
  final String? profileImage;
  final bool isVerified;
  final bool vipMember;
  final num coins;

  RankingEntry({
    required this.rank,
    required this.userId,
    required this.name,
    required this.profileImage,
    required this.isVerified,
    required this.vipMember,
    required this.coins,
  });

  factory RankingEntry.fromJson(Map<String, dynamic> json) {
    String? resolveImage(dynamic raw) {
      final s = raw?.toString() ?? '';
      if (s.isEmpty) return null;
      return s.startsWith('http') ? s : AssetsManager.getNetworkImagePath(s);
    }

    return RankingEntry(
      rank: int.tryParse(json['rank']?.toString() ?? '') ?? 0,
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'User',
      profileImage: resolveImage(json['profileImage']),
      isVerified: json['isVerified'] == true,
      vipMember: json['vipMember'] == true,
      coins: num.tryParse(json['coins']?.toString() ?? '') ?? 0,
    );
  }
}

class RankingSheet extends StatefulWidget {
  final String liveId;
  final String hostId;

  const RankingSheet({super.key, required this.liveId, required this.hostId});

  @override
  State<RankingSheet> createState() => _RankingSheetState();
}

class _RankingSheetState extends State<RankingSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.black,
                  unselectedLabelColor: const Color(0xFF7A7A7A),
                  dividerColor: Colors.transparent,
                  labelStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  indicatorColor: Colors.black,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: const [
                    Tab(text: "Daily Ranking"),
                    Tab(text: "Top Creators"),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.black54),
                onPressed: () => Navigator.maybePop(context),
              ),
            ],
          ),
          Container(height: 1, color: const Color(0xFFEDEDED)),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _DailyRankingTab(liveId: widget.liveId),
                const _TopCreatorsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// Tab 1: Daily Ranking (supporters of the current host)
// ==========================================
class _DailyRankingTab extends StatefulWidget {
  final String liveId;

  const _DailyRankingTab({required this.liveId});

  @override
  State<_DailyRankingTab> createState() => _DailyRankingTabState();
}

class _DailyRankingTabState extends State<_DailyRankingTab> {
  final ServiceHelper _serviceHelper = sl<ServiceHelper>();
  final StoreHelper _storeHelper = sl<StoreHelper>();

  bool _isLoading = true;
  String? _error;
  List<RankingEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = _storeHelper.getAccessToken();
      final response = await _serviceHelper.getHelper(
        target: '/v1/live/${widget.liveId}/ranking/daily',
        token: token,
      );

      if (response is Success) {
        final Map<String, dynamic> body = response.data is String
            ? jsonDecode(response.data as String)
            : response.data as Map<String, dynamic>;
        final List<dynamic> rows = body['data']?['data'] ?? [];
        _entries = rows
            .map((e) => RankingEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        setState(() => _isLoading = false);
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load ranking';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load ranking';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RankingListView(
      isLoading: _isLoading,
      error: _error,
      entries: _entries,
      emptyText: 'No supporters yet in the last 24 hours',
      onRetry: _load,
      bottomBar: null,
    );
  }
}

// ==========================================
// Tab 2: Top Creators (hosts, Daily/Weekly, Top 50 + personal pinned rank)
// ==========================================
class _TopCreatorsTab extends StatefulWidget {
  const _TopCreatorsTab();

  @override
  State<_TopCreatorsTab> createState() => _TopCreatorsTabState();
}

class _TopCreatorsTabState extends State<_TopCreatorsTab> {
  final ServiceHelper _serviceHelper = sl<ServiceHelper>();
  final StoreHelper _storeHelper = sl<StoreHelper>();

  String _period = 'daily';
  bool _isLoading = true;
  String? _error;
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
      _error = null;
    });

    try {
      final token = _storeHelper.getAccessToken();
      final response = await _serviceHelper.getHelper(
        target: '/v1/live/ranking/top-creators?period=$_period',
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
          _error = 'Failed to load ranking';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load ranking';
      });
    }
  }

  void _switchPeriod(String period) {
    if (period == _period) return;
    setState(() => _period = period);
    _load();
  }

  Widget _periodPill(String label, String value) {
    final active = _period == value;
    return GestureDetector(
      onTap: () => _switchPeriod(value),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: [Color(0xFF7247EF), Color(0xFFB862E1)],
                )
              : null,
          color: active ? null : const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF7A7A7A),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              _periodPill('Daily', 'daily'),
              _periodPill('Weekly', 'weekly'),
            ],
          ),
        ),
        Expanded(
          child: RankingListView(
            isLoading: _isLoading,
            error: _error,
            entries: _entries,
            emptyText: 'No creators ranked yet',
            onRetry: _load,
            bottomBar: _myRank == null ? null : _buildMyRankBar(_myRank!),
          ),
        ),
      ],
    );
  }

  // Only rendered for the requesting host herself when she's outside the
  // public Top 50 — the backend only ever includes `myRank` in the
  // response to her own authenticated request.
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
              Image.asset('assets/icons/sm-coin.png', width: 16),
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

// ==========================================
// Shared: podium (top 3) + list (rest) — same visual language for both
// tabs, per the product requirement that only content/permissions differ.
// ==========================================
class RankingListView extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final List<RankingEntry> entries;
  final String emptyText;
  final VoidCallback onRetry;
  final Widget? bottomBar;

  const RankingListView({
    super.key,
    required this.isLoading,
    required this.error,
    required this.entries,
    required this.emptyText,
    required this.onRetry,
    required this.bottomBar,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!, style: const TextStyle(color: Color(0xFF7A7A7A))),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (entries.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: const TextStyle(color: Color(0xFF7A7A7A)),
        ),
      );
    }

    final podium = entries.take(3).toList();
    final rest = entries.length > 3 ? entries.sublist(3) : <RankingEntry>[];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: 5,
          ),
          child: SizedBox(
            height: 210,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                if (podium.length > 1)
                  Positioned(
                    left: 10,
                    bottom: 0,
                    child: _PodiumSpot(
                      entry: podium[1],
                      size: 68,
                      rankLabel: '2',
                      rankColor: const Color(0xFFC0C0C0),
                    ),
                  ),
                if (podium.length > 2)
                  Positioned(
                    right: 10,
                    bottom: 0,
                    child: _PodiumSpot(
                      entry: podium[2],
                      size: 68,
                      rankLabel: '3',
                      rankColor: const Color(0xFFCD7F32),
                    ),
                  ),
                if (podium.isNotEmpty)
                  Positioned(
                    bottom: 24,
                    child: _PodiumSpot(
                      entry: podium[0],
                      size: 86,
                      rankLabel: '1',
                      rankColor: const Color(0xFFFFCA28),
                      isFirst: true,
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: rest.length,
            separatorBuilder: (context, index) => const SizedBox(height: 20),
            itemBuilder: (context, index) => _RankingRow(entry: rest[index]),
          ),
        ),
        if (bottomBar != null) bottomBar!,
      ],
    );
  }
}

class _PodiumSpot extends StatelessWidget {
  final RankingEntry entry;
  final double size;
  final String rankLabel;
  final Color rankColor;
  final bool isFirst;

  const _PodiumSpot({
    required this.entry,
    required this.size,
    required this.rankLabel,
    required this.rankColor,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.translate(
          offset: const Offset(0, 16),
          child: Text(
            rankLabel,
            style: TextStyle(
              fontSize: isFirst ? 56 : 46,
              fontWeight: FontWeight.w900,
              color: rankColor.withOpacity(0.8),
              height: 1,
            ),
          ),
        ),
        RankingAvatar(
          url: entry.profileImage,
          radius: size / 2,
          borderWidth: 3,
        ),
        const SizedBox(height: 8),
        Text(
          entry.name,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.black,
            fontSize: isFirst ? 16 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icons/sm-coin.png', width: 14),
            const SizedBox(width: 3),
            Text(
              WalletHelper.format(entry.coins),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RankingRow extends StatelessWidget {
  final RankingEntry entry;

  const _RankingRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(
            '${entry.rank}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        RankingAvatar(url: entry.profileImage, radius: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      entry.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (entry.isVerified) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified,
                      color: Color(0xFF8B3EE8),
                      size: 14,
                    ),
                  ],
                ],
              ),
              if (entry.vipMember) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7247EF), Color(0xFFB862E1)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'VIP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Row(
          children: [
            Image.asset('assets/icons/sm-coin.png', width: 16),
            const SizedBox(width: 6),
            Text(
              WalletHelper.format(entry.coins),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class RankingAvatar extends StatelessWidget {
  final String? url;
  final double radius;
  final double borderWidth;

  const RankingAvatar({
    super.key,
    required this.url,
    required this.radius,
    this.borderWidth = 0,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
      backgroundImage: AvatarHelper.resolve(url),
    );

    if (borderWidth <= 0) return avatar;

    return Container(
      padding: EdgeInsets.all(borderWidth),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: avatar,
    );
  }
}
