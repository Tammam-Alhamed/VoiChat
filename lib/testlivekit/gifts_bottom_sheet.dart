import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shoeebapk/core/assets_manager.dart';
import 'package:shoeebapk/core/network/service_helper.dart';
import 'package:shoeebapk/core/helpers/store_helper.dart';
import 'package:shoeebapk/core/utils/api_status.dart';
import 'package:shoeebapk/app/di/injection_container.dart';

// A single sendable gift, loaded from the real catalog (GET
// /v1/gifts/with-gifts) rather than hardcoded — `id` is what actually gets
// sent to POST /wallet/gifts/send.
class GiftItem {
  final String id;
  final String name;
  final String imageUrl;
  final String svga;
  final String sound;
  final num price;
  final int durationSeconds; // how long the SVGA/audio plays for
  const GiftItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.svga,
    required this.sound,
    required this.durationSeconds,
  });

  factory GiftItem.fromJson(Map<String, dynamic> json) {
    String resolve(dynamic raw) {
      final s = raw?.toString() ?? '';
      if (s.isEmpty) return '';
      return s.startsWith('http') ? s : AssetsManager.getNetworkImagePath(s);
    }

    return GiftItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Gift',
      imageUrl: resolve(json['image']),
      svga: resolve(json['svga']),
      sound: resolve(json['music']),
      price: num.tryParse(json['price']?.toString() ?? '') ?? 0,
      durationSeconds: int.tryParse(json['duration']?.toString() ?? '') ?? 3,
    );
  }
}

// One category tab (e.g. "Gifts", "Interactive", "Exclusive") with its
// nested real gifts, as returned by GET /v1/gifts/with-gifts.
class GiftCategory {
  final String id;
  final String name;
  final List<GiftItem> gifts;
  const GiftCategory({
    required this.id,
    required this.name,
    required this.gifts,
  });

  factory GiftCategory.fromJson(Map<String, dynamic> json) {
    final rawGifts = json['gifts'] as List? ?? [];
    return GiftCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Gifts',
      gifts: rawGifts
          .whereType<Map<String, dynamic>>()
          .map(GiftItem.fromJson)
          .toList(),
    );
  }
}

Future<GiftItem?> showGiftBottomSheet(BuildContext context) {
  return showModalBottomSheet<GiftItem>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (_) => const _GiftBottomSheet(),
  );
}

// ─────────────────────────────────────────────────────────────
// Bottom sheet widget — fetches the real catalog on open (loading
// spinner while that's in flight), then behaves exactly like before.
// ─────────────────────────────────────────────────────────────
class _GiftBottomSheet extends StatefulWidget {
  const _GiftBottomSheet();

  @override
  State<_GiftBottomSheet> createState() => _GiftBottomSheetState();
}

class _GiftBottomSheetState extends State<_GiftBottomSheet>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  int _selectedGiftIndex = -1;
  int _currentTab = 0;

  List<GiftCategory> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      final serviceHelper = sl<ServiceHelper>();
      final token = sl<StoreHelper>().getAccessToken();
      final response = await serviceHelper.getHelper(
        target: '/v1/gifts/with-gifts',
        token: token,
      );

      if (response is Success) {
        final body = response.data is String
            ? jsonDecode(response.data as String) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;

        if (body['success'] == true && body['data'] is List) {
          final categories = (body['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map(GiftCategory.fromJson)
              .toList();

          if (mounted) {
            setState(() {
              _categories = categories;
              _tabController = TabController(
                length: categories.isEmpty ? 1 : categories.length,
                vsync: this,
              );
              _tabController!.addListener(() {
                if (_tabController!.indexIsChanging) return;
                setState(() {
                  _currentTab = _tabController!.index;
                  _selectedGiftIndex = -1;
                });
              });
              _isLoading = false;
            });
          }
          return;
        }
      }
      if (mounted) setState(() => _error = 'Failed to load gifts');
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load gifts');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  List<GiftItem> get _currentGifts =>
      _currentTab < _categories.length ? _categories[_currentTab].gifts : [];

  GiftItem? get _selectedGift =>
      _selectedGiftIndex >= 0 && _selectedGiftIndex < _currentGifts.length
      ? _currentGifts[_selectedGiftIndex]
      : null;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.58,
      decoration: const BoxDecoration(
        // Dark translucent background — matches screenshot exactly
        color: Color(0xCC1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white54),
            )
          : _error != null
          ? Center(
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.white54),
              ),
            )
          : _buildLoadedContent(),
    );
  }

  Widget _buildLoadedContent() {
    final tabController = _tabController!;
    final tabCount = _categories.isEmpty ? 1 : _categories.length;

    return Column(
      children: [
        // ── Title ────────────────────────────────────────────
        const Padding(
          padding: EdgeInsets.only(top: 16, bottom: 12),
          child: Text(
            'Select Entry Gift',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),

        // ── Gift grid ─────────────────────────────────────────
        Expanded(
          child: _categories.isEmpty
              ? const Center(
                  child: Text(
                    'No gifts available',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : TabBarView(
                  controller: tabController,
                  children: List.generate(tabCount, (tabIndex) {
                    final gifts = _categories[tabIndex].gifts;
                    if (gifts.isEmpty) {
                      return const Center(
                        child: Text(
                          'No gifts in this category yet',
                          style: TextStyle(color: Colors.white54),
                        ),
                      );
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 0.75,
                          ),
                      itemCount: gifts.length,
                      itemBuilder: (context, index) {
                        final gift = gifts[index];
                        final isSelected =
                            _currentTab == tabIndex &&
                            _selectedGiftIndex == index;

                        return GestureDetector(
                          onTap: () => setState(() {
                            _currentTab = tabIndex;
                            _selectedGiftIndex = index;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(
                                      color: Colors.pinkAccent,
                                      width: 2,
                                    )
                                  : null,
                              color: isSelected
                                  ? Colors.pinkAccent.withOpacity(0.12)
                                  : Colors.transparent,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Gift image
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: gift.imageUrl.isEmpty
                                        ? const Icon(
                                            Icons.card_giftcard,
                                            color: Colors.white54,
                                            size: 36,
                                          )
                                        : CachedNetworkImage(
                                            imageUrl:
                                                AssetsManager.getNetworkImagePath(
                                                  gift.imageUrl,
                                                ),
                                            fit: BoxFit.contain,
                                            errorWidget: (_, __, ___) =>
                                                const Icon(
                                                  Icons.card_giftcard,
                                                  color: Colors.white54,
                                                  size: 36,
                                                ),
                                          ),
                                  ),
                                ),

                                // Gift name
                                Text(
                                  gift.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const SizedBox(height: 3),

                                // Price row — gold coin + number
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    /* Container(
                                  width: 13,
                                  height: 13,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Color(0xFFFFD700),
                                        Color(0xFFFF8C00),
                                      ],
                                    ),
                                  ),
                                ),*/
                                    Image.asset(
                                      "assets/icons/sm-coin.png",
                                      width: 18,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${gift.price}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
        ),

        // ── Send button (visible when gift selected) ──────────
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: _selectedGift != null
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, _selectedGift),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF4D8D), Color(0xFFFF2D6B)],
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Send  ${_selectedGift!.price}  •  ${_selectedGift!.name}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // ── TabBar — at the very bottom ───────────────────────
        if (_categories.isNotEmpty)
          Container(
            color: const Color(0xFF111111),
            child: TabBar(
              controller: tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorSize: TabBarIndicatorSize.label,
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(width: 2, color: Colors.white),
                insets: EdgeInsets.zero,
              ),
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Colors.white54,
              ),
              splashFactory: NoSplash.splashFactory,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              tabs: _categories
                  .map((c) => Tab(text: c.name, height: 44))
                  .toList(),
            ),
          ),

        // Safe area bottom padding
        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ],
    );
  }
}
