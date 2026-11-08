import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shoeebapk/core/assets_manager.dart';
import 'package:shoeebapk/core/helpers/avatar_helper.dart';
import 'package:shoeebapk/core/enums/page_state.dart';

import 'blocked_users_provider.dart';
import '../../../core/themes/app_dark_colors.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BlockedUsersProvider>().fetchBlockedUsers();
    });

    // الاستماع للـ Scroll للبدء بالـ Load More تلقائياً قبل الوصول للنهاية
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<BlockedUsersProvider>().loadMoreBlockedUsers();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.shellBackground,

      appBar: AppBar(
        backgroundColor: context.shellBackground,
        elevation: 0,
        foregroundColor: context.shellTextPrimary,
        title: Text(
          "blocked_users".tr,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
        ),
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              AssetsManager.search,
              colorFilter: context.isAppDarkMode
                  ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                  : null,
            ),
            onPressed: () {},
          ),
        ],
      ),

      body: Consumer<BlockedUsersProvider>(
        builder: (context, provider, child) {
          // 1. حالة التحميل الأساسية
          if (provider.pageState == PageState.loading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF7247EF)),
            );
          }

          // 2. حالة الخطأ
          if (provider.pageState == PageState.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    provider.error ?? "failed_load_blocked_users".tr,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => provider.fetchBlockedUsers(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7247EF),
                    ),
                    child: Text(
                      "retry".tr,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }

          // 3. حالة القائمة فارغة
          if (provider.pageState == PageState.empty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F3F6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_off_rounded,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "no_blocked_users".tr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          // 4. حالة عرض البيانات (Loaded)
          return ListView.builder(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount:
                provider.blockedUsers.length +
                (provider.isLoadMoreLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == provider.blockedUsers.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF7247EF),
                      strokeWidth: 2,
                    ),
                  ),
                );
              }

              final user = provider.blockedUsers[index];
              final isUnblocking = provider.unblockLoaders[user.id] ?? false;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                      image: DecorationImage(
                        image: AvatarHelper.resolve(user.profileImage),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  title: Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  trailing: SizedBox(
                    height: 34,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFFFFEBE8,
                        ), // لون فاتح عصري للزر
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onPressed: isUnblocking
                          ? null
                          : () => provider.unblockUser(
                              userId: user.id,
                              userName: user.name,
                            ),
                      child: isUnblocking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Color(0xFFFF3C1F),
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              "unblock".tr,
                              style: const TextStyle(
                                color: Color(0xFFFF3C1F),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
