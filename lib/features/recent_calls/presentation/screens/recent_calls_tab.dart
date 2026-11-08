import 'package:flutter/material.dart';
import 'package:shoeebapk/core/themes/app_dark_colors.dart';
import 'package:shoeebapk/core/themes/colors.dart';
import 'package:shoeebapk/core/enums/page_state.dart';
import '../widgets/recent_calls_skeleton.dart';
import '../widgets/recent_calls_empty.dart';
import '../widgets/recent_calls_error.dart';
import '../widgets/recent_calls_header.dart';
import '../widgets/recent_calls_list_item.dart';

import 'package:get/get.dart';
import '../../../session/domain/entities/session_data.dart';
import '../../../session/presentation/controllers/session_controller.dart';
import '../../domain/entities/call_history.dart';
import '../controllers/recent_calls_controller.dart';

class RecentCallsTab extends StatefulWidget {
  const RecentCallsTab({super.key});

  @override
  RecentCallsTabState createState() => RecentCallsTabState();
}

class RecentCallsTabState extends State<RecentCallsTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late SessionData splashModel;

  // ─── Selection state ──────────────────────────────────────────────────────
  final Set<String> _selectedIds = {};
  bool get isSelectionMode => _selectedIds.isNotEmpty;

  void _toggleSelected(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  bool _isAllSelected(List<CallHistory> calls) =>
      calls.isNotEmpty && _selectedIds.length == calls.length;

  void _toggleSelectAll(List<CallHistory> calls) {
    setState(() {
      if (_isAllSelected(calls)) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(calls.map((c) => c.id));
      }
    });
  }

  void _deleteSelected() {
    Get.find<RecentCallsController>().deleteCalls(_selectedIds);
    setState(() => _selectedIds.clear());
  }

  @override
  void initState() {
    super.initState();
    splashModel = Get.find<SessionController>().session!;
    // Fetch live data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<SessionController>().setUnSeenZero();
      Get.find<RecentCallsController>().reset();
      Get.find<RecentCallsController>().getRecentCall();
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _headerSlideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ─── Selection Toolbar ────────────────────────────────────────────────────
  // Replaces the decorative 3-dot icon that used to sit in RecentCallsHeader
  // — same pattern as MessagesTab's normal-header/selection-toolbar swap.

  Widget _buildSelectionToolbar(List<CallHistory> calls) {
    return Container(
      key: const ValueKey('selection_header'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      color: context.shellBackground,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close, color: context.shellTextPrimary),
            onPressed: () => setState(() => _selectedIds.clear()),
          ),
          const SizedBox(width: 8),
          Text(
            "${_selectedIds.length} Selected",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.shellTextPrimary,
            ),
          ),
          const Spacer(),
          Tooltip(
            message: "Select All",
            child: Checkbox(
              value: _isAllSelected(calls),
              activeColor: MainColors.primary,
              onChanged: (_) => _toggleSelectAll(calls),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: "Delete",
            onPressed: _deleteSelected,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RecentCallsController>(
      builder: (_) => _buildRecentCallsScope(context),
    );
  }

  Widget _buildRecentCallsScope(BuildContext context) {
    return Scaffold(
      backgroundColor: context.shellBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeTransition(
              opacity: _headerFadeAnimation,
              child: SlideTransition(
                position: _headerSlideAnimation,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0, -0.5),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutQuart,
                            ),
                          ),
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: isSelectionMode
                      ? _buildSelectionToolbar(
                          Get.find<RecentCallsController>().calls,
                        )
                      : const RecentCallsHeader(),
                ),
              ),
            ),
            Expanded(
              child: GetBuilder<RecentCallsController>(
                builder: (provider) {
                  // Handle different UI states from provider
                  switch (provider.pageState) {
                    case PageState.loading:
                      return const RecentCallsSkeleton();
                    case PageState.empty:
                      return RefreshIndicator(
                        color: MainColors.primary,
                        onRefresh: () => provider.getRecentCall(),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * .7,
                              child: const RecentCallsEmpty(),
                            ),
                          ],
                        ),
                      );
                    case PageState.error:
                      return RecentCallsError(
                        errorMessage: provider.error ?? "An error occurred",
                        onRetry: () => provider.retry(),
                      );
                    case PageState.loaded:
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeTransition(
                            opacity: _headerFadeAnimation,
                            child: SlideTransition(
                              position: _headerSlideAnimation,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  top: 28,
                                  bottom: 18,
                                  left: 21,
                                ),
                                child: Text(
                                  "Today",
                                  style: TextStyle(
                                    color: context.shellTextPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: RefreshIndicator(
                              color: MainColors.primary,
                              onRefresh: () => provider.getRecentCall(),
                              child: ListView.builder(
                                itemCount: provider.calls.length,
                                padding: EdgeInsets.zero,
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: ClampingScrollPhysics(),
                                ),
                                itemBuilder: (context, index) {
                                  final call = provider.calls[index];
                                  final animation =
                                      Tween<double>(
                                        begin: 0.0,
                                        end: 1.0,
                                      ).animate(
                                        CurvedAnimation(
                                          parent: _animationController,
                                          curve: Interval(
                                            0.2 +
                                                (index * 0.05).clamp(0.0, 0.6),
                                            1.0,
                                            curve: Curves.easeOutCubic,
                                          ),
                                        ),
                                      );
                                  return _AnimatedCallListItem(
                                    animation: animation,
                                    call: call,
                                    index: index,
                                    splashResponse: splashModel,
                                    isSelected: _selectedIds.contains(call.id),
                                    isSelectionMode: isSelectionMode,
                                    onLongPress: () => _toggleSelected(call.id),
                                    onTapToggle: () => _toggleSelected(call.id),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Animated call list item ──────────────────────────────────────────────────

class _AnimatedCallListItem extends StatelessWidget {
  final Animation<double> animation;
  final CallHistory call;
  final int index;
  final SessionData splashResponse;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onLongPress;
  final VoidCallback onTapToggle;

  const _AnimatedCallListItem({
    required this.animation,
    required this.call,
    required this.index,
    required this.splashResponse,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onLongPress,
    required this.onTapToggle,
  });

  @override
  Widget build(BuildContext context) {
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

    final scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack));

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: slideAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          // No outer spacing here anymore — RecentCallsListItem now carries
          // its own top/bottom padding *inside* the highlight container, so
          // two selected rows in a row paint as one unbroken purple block
          // instead of leaving a white sliver where this padding used to be.
          child: RecentCallsListItem(
            call: call,
            index: index,
            splashResponse: splashResponse,
            isSelected: isSelected,
            isSelectionMode: isSelectionMode,
            onLongPress: onLongPress,
            onTapToggle: onTapToggle,
          ),
        ),
      ),
    );
  }
}
