import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:shoeebapk/core/enums/page_state.dart';

import '../../../core/themes/app_dark_colors.dart';
import '../../../core/helpers/avatar_helper.dart';
import '../../../core/helpers/wallet_helper.dart';
import '../../../core/widgets/app_search_field.dart';
import '../../../core/widgets/app_state_view.dart';
import 'creator_model.dart';
import 'manage_creators_provider.dart';

class ManageCreatorsScreen extends StatefulWidget {
  const ManageCreatorsScreen({super.key});

  @override
  State<ManageCreatorsScreen> createState() => _ManageCreatorsScreenState();
}

class _ManageCreatorsScreenState extends State<ManageCreatorsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManageCreatorsProvider>().fetchCreators();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.shellBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: context.shellTextPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Manage Creators',
          style: TextStyle(
            color: context.shellTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: context.shellTextPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: AppSearchField(
                controller: _searchController,
                hintText: "Search by name or ID...",
                onChanged: (value) {
                  context
                      .read<ManageCreatorsProvider>()
                      .searchCreatorsLocally(value);
                },
              ),
            ),

            const SizedBox(height: 8),

            // Core Response Matrix
            Expanded(
              child: Consumer<ManageCreatorsProvider>(
                builder: (context, provider, child) {
                  if (provider.pageState == PageState.error) {
                    return AppStateView.error(
                      message: provider.error,
                      onRetry: () => provider.fetchCreators(),
                    );
                  }

                  if (provider.pageState == PageState.empty) {
                    return RefreshIndicator(
                      onRefresh: () => provider.fetchCreators(),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * .7,
                            child: AppStateView.empty(
                              icon: Icons.groups_outlined,
                              title: "No creators found",
                              message: "Pull down to refresh",
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final bool isLoading =
                      provider.pageState == PageState.loading;

                  // Setup clean temporary skeleton array items
                  final displayList = isLoading
                      ? List.generate(6, (index) => CreatorModel.mock(index))
                      : provider.filteredCreators;

                  return Skeletonizer(
                    enabled: isLoading,
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.61,
                          ),
                      itemCount: displayList.length,
                      itemBuilder: (context, index) {
                        return _buildCreatorCard(displayList[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // Material 3 Creator Card
  // ==========================================
  Widget _buildCreatorCard(CreatorModel creator) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.grey.shade100,
                      backgroundImage: AvatarHelper.resolve(
                        creator.profileImage,
                      ),
                    ),
                    if (creator.isOnline)
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Name
                Text(
                  creator.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                // ID Action Box
                InkWell(
                  onTap: () {
                    // Logic to copy ID
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ID: ${creator.profileId.isNotEmpty ? creator.profileId : creator.id.substring(0, 6)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.copy_rounded,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Pill Badge status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: creator.isOnline
                        ? const Color(0xFFE8F5E9)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    creator.isOnline ? "Online" : creator.lastSeen,
                    style: TextStyle(
                      color: creator.isOnline
                          ? const Color(0xFF2E7D32)
                          : Colors.grey.shade600,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Earnings Summary Bottom panel
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              border: Border(
                top: BorderSide(color: Colors.grey.shade100, width: 1),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 6),
                _buildStatRow(
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: const Color(0xFF4CAF50),
                  label: "Net Amount",
                  value: "${WalletHelper.format(creator.netAmount)} \$",
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: Colors.black12),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Earnings",
                      style: TextStyle(
                        color: Color(0xFF7247EF),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      "${WalletHelper.format(creator.agentEarnings)} \$",
                      style: const TextStyle(
                        color: Color(0xFF7247EF),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
