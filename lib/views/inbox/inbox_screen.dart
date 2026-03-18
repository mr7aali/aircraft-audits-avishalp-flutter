import 'package:avislap/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../services/api_exception.dart';
import '../../services/app_api_service.dart';
import '../../services/session_service.dart';

// =====================
// COLORS
// =====================

// =====================
// MODELS
// =====================
class ChatListItem {
  final String userId;
  final String conversationId;
  final String userName;
  final String phone;
  final String userImage;
  final String lastMessage;
  final String time;
  final bool isOnline;
  final int unreadCount;

  ChatListItem({
    required this.userId,
    required this.conversationId,
    required this.userName,
    required this.phone,
    required this.userImage,
    required this.lastMessage,
    required this.time,
    required this.isOnline,
    required this.unreadCount,
  });
}

class InboxTabItem {
  final String key;
  final String label;

  const InboxTabItem({required this.key, required this.label});
}

class ChatMessage {
  final String id;
  final String senderName;
  final String? senderImage;
  final String message;
  final String time;
  final bool isUserMessage;

  ChatMessage({
    required this.id,
    required this.senderName,
    this.senderImage,
    required this.message,
    required this.time,
    required this.isUserMessage,
  });
}

// =====================
// INBOX CONTROLLER
// =====================
class InboxController extends GetxController {
  final AppApiService _api = Get.find<AppApiService>();
  final RxList<ChatListItem> chatList = <ChatListItem>[].obs;
  final RxBool isLoading = true.obs;
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final RxString selectedTab = 'all'.obs;
  final RxInt unreadCount = 0.obs;

  List<InboxTabItem> get tabs => [
    const InboxTabItem(key: 'all', label: 'All'),
    InboxTabItem(key: 'unread', label: 'Unread (${unreadCount.value})'),
    const InboxTabItem(key: 'online', label: 'Online'),
  ];

  @override
  void onInit() {
    super.onInit();
    ever<String>(selectedTab, (_) => loadConversations());
    loadConversations();
  }

  void updateSearch(String query) => searchQuery.value = query;

  Future<void> loadConversations() async {
    isLoading.value = true;

    try {
      final trimmedQuery = searchQuery.value.trim();
      final conversations = await _api.listConversations();
      final users = await _api.listChatUsers(
        query: trimmedQuery.isEmpty ? null : trimmedQuery,
      );

      final directConversationsByUserId = <String, Map<String, dynamic>>{};
      for (final item in conversations) {
        final otherParticipant =
            item['otherParticipant'] is Map<String, dynamic>
            ? item['otherParticipant'] as Map<String, dynamic>
            : <String, dynamic>{};
        final otherUserId = otherParticipant['id']?.toString() ?? '';
        if (otherUserId.isEmpty) {
          continue;
        }
        directConversationsByUserId[otherUserId] = item;
      }

      final mapped = users
          .map(
            (user) => _mapChatUser(
              user,
              directConversationsByUserId[user['id']?.toString() ?? ''],
            ),
          )
          .where((item) => item.userId.isNotEmpty)
          .toList();

      unreadCount.value = mapped.fold<int>(
        0,
        (total, item) => total + item.unreadCount,
      );
      chatList.assignAll(mapped);
    } on ApiException catch (error) {
      chatList.clear();
      unreadCount.value = 0;
      Get.snackbar(
        'Chat Unavailable',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (_) {
      chatList.clear();
      unreadCount.value = 0;
      Get.snackbar(
        'Chat Unavailable',
        'Unable to load conversations right now.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  ChatListItem _mapChatUser(
    Map<String, dynamic> user,
    Map<String, dynamic>? conversation,
  ) {
    final timestamp = conversation?['timestamp']?.toString() ?? '';
    final preview =
        (conversation?['lastMessagePreview'] as String?)?.trim() ?? '';
    final profileImageFileId =
        (user['profileImageFileId'] as String?)?.trim() ?? '';
    return ChatListItem(
      userId: user['id']?.toString() ?? '',
      conversationId: conversation?['id']?.toString() ?? '',
      userName: (user['name'] as String?)?.trim().isNotEmpty == true
          ? (user['name'] as String).trim()
          : 'Unknown User',
      phone: (user['uid'] as String?)?.trim().isNotEmpty == true
          ? (user['uid'] as String).trim()
          : ((user['email'] as String?)?.trim() ?? ''),
      userImage: profileImageFileId.isEmpty
          ? ''
          : _api.buildFileContentUrl(profileImageFileId),
      lastMessage: preview.isNotEmpty ? preview : 'Tap to start chatting',
      time: _formatConversationTime(timestamp),
      isOnline: conversation?['isOnline'] == true,
      unreadCount: (conversation?['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }

  String _formatConversationTime(String rawTimestamp) {
    final timestamp = DateTime.tryParse(rawTimestamp)?.toLocal();
    if (timestamp == null) {
      return '';
    }

    final now = DateTime.now();
    final isSameDay =
        timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day;

    return isSameDay
        ? DateFormat('h:mm a').format(timestamp).toLowerCase()
        : DateFormat('MMM d').format(timestamp);
  }

  List<ChatListItem> getFilteredChats() {
    return chatList.where((chat) {
      final query = searchQuery.value.trim().toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          chat.userName.toLowerCase().contains(query) ||
          chat.phone.toLowerCase().contains(query);
      if (!matchesSearch) {
        return false;
      }
      if (selectedTab.value == 'unread') {
        return chat.unreadCount > 0;
      }
      if (selectedTab.value == 'online') {
        return chat.isOnline;
      }
      return true;
    }).toList();
  }

  Future<ChatListItem> openConversation(ChatListItem chat) async {
    if (chat.conversationId.isNotEmpty) {
      return chat;
    }

    final created = await _api.createDirectConversation(chat.userId);
    final conversationId = created['id']?.toString() ?? '';
    if (conversationId.isEmpty) {
      throw const ApiException('Unable to open this conversation.');
    }

    final updated = ChatListItem(
      userId: chat.userId,
      conversationId: conversationId,
      userName: chat.userName,
      phone: chat.phone,
      userImage: chat.userImage,
      lastMessage: chat.lastMessage,
      time: chat.time,
      isOnline: chat.isOnline,
      unreadCount: chat.unreadCount,
    );

    final index = chatList.indexWhere((item) => item.userId == chat.userId);
    if (index >= 0) {
      chatList[index] = updated;
      chatList.refresh();
    }

    return updated;
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}

// =====================
// INBOX SCREEN
// =====================
class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  late final InboxController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(InboxController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            _buildChatHeader(),
            _buildTabBar(),
            Expanded(child: _buildChatList()),
          ],
        ),
      ),
    );
  }

  // ── Search Bar ──────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Icon(
              Icons.arrow_back,
              color: AppColors.textDark,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Container(
              height: 44.h,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FB),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: const Color(0xFFE7ECF3)),
              ),
              child: TextField(
                controller: controller.searchController,
                onChanged: controller.updateSearch,
                onSubmitted: (_) => controller.loadConversations(),
                decoration: InputDecoration(
                  hintText: 'Search people',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: AppColors.textGrey,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.textGrey,
                    size: 20.sp,
                  ),
                  suffixIcon: Obx(
                    () => controller.searchQuery.value.trim().isEmpty
                        ? const SizedBox.shrink()
                        : IconButton(
                            onPressed: () {
                              controller.searchController.clear();
                              controller.updateSearch('');
                              controller.loadConversations();
                            },
                            icon: Icon(
                              Icons.close_rounded,
                              color: AppColors.textGrey,
                              size: 18.sp,
                            ),
                          ),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          GestureDetector(
            onTap: controller.loadConversations,
            child: Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: AppColors.mainAppColor,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.tune_rounded, color: Colors.white, size: 20.sp),
            ),
          ),
        ],
      ),
    );
  }

  // ── Chat Header ─────────────────────────────────────────
  Widget _buildChatHeader() {
    return Padding(
      padding: EdgeInsets.only(left: 16.w, top: 8.h, bottom: 16.h),
      child: Row(
        children: [
          Container(
            width: 4.w,
            height: 24.h,
            decoration: BoxDecoration(
              color: AppColors.mainAppColor,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(width: 10.w),
          Text(
            'People',
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab Bar ─────────────────────────────────────────────
  Widget _buildTabBar() {
    return Obx(
      () => Padding(
        padding: EdgeInsets.only(left: 16.w, bottom: 8.h),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: controller.tabs.map((tab) {
              final isSelected = controller.selectedTab.value == tab.key;
              return GestureDetector(
                onTap: () => controller.selectedTab.value = tab.key,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: 8.w),
                  padding: EdgeInsets.symmetric(
                    horizontal: 18.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.chipSelected
                        : AppColors.chipUnselected,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    tab.label,
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? AppColors.chipTextSelected
                          : AppColors.chipTextUnselected,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ── Chat List ───────────────────────────────────────────
  Widget _buildChatList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final chats = controller.getFilteredChats();
      if (chats.isEmpty) {
        return Center(
          child: Text(
            'No users found',
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              color: AppColors.textGrey,
            ),
          ),
        );
      }
      return ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: chats.length,
        itemBuilder: (context, index) {
          return _buildChatTile(chats[index]);
        },
      );
    });
  }

  Widget _buildChatTile(ChatListItem chat) {
    return InkWell(
      onTap: () async {
        try {
          final conversation = await controller.openConversation(chat);
          if (!mounted) {
            return;
          }
          await Get.to(
            () => ChatScreen(
              conversationId: conversation.conversationId,
              contactName: conversation.userName,
              contactPhone: conversation.phone,
              contactImage: conversation.userImage,
              isOnline: conversation.isOnline,
            ),
          );
          await controller.loadConversations();
        } on ApiException catch (error) {
          Get.snackbar(
            'Chat Unavailable',
            error.message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        } catch (_) {
          Get.snackbar(
            'Chat Unavailable',
            'Unable to open this conversation right now.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            // Avatar with online dot
            Stack(
              children: [
                _buildConversationAvatar(chat),
                if (chat.isOnline)
                  Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      width: 12.w,
                      height: 12.h,
                      decoration: BoxDecoration(
                        color: AppColors.onlineDot,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 14.w),
            // Name & phone
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.userName,
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    chat.lastMessage,
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            // Time & badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  chat.time,
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    color: AppColors.textGrey,
                  ),
                ),
                SizedBox(height: 4.h),
                if (chat.unreadCount > 0)
                  Container(
                    width: 20.w,
                    height: 20.h,
                    decoration: BoxDecoration(
                      color: AppColors.unreadBadge,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${chat.unreadCount}',
                      style: GoogleFonts.poppins(
                        fontSize: 10.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  SizedBox(height: 20.h),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationAvatar(ChatListItem chat) {
    final image = chat.userImage.trim();
    final imageHeaders = Get.find<AppApiService>().buildImageHeaders();
    final initials = chat.userName.isNotEmpty
        ? chat.userName
              .split(' ')
              .where((part) => part.isNotEmpty)
              .take(2)
              .map((part) => part[0].toUpperCase())
              .join()
        : '?';

    ImageProvider<Object>? imageProvider;
    if (image.startsWith('http')) {
      imageProvider = NetworkImage(image, headers: imageHeaders);
    } else if (image.isNotEmpty) {
      imageProvider = AssetImage(image);
    }

    return CircleAvatar(
      radius: 26.r,
      backgroundImage: imageProvider,
      backgroundColor: Colors.grey.shade200,
      child: imageProvider == null
          ? Text(
              initials,
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            )
          : null,
    );
  }
}

// =====================
// CHAT CONTROLLER
// =====================
class ChatController extends GetxController {
  ChatController({required this.conversationId});

  final String conversationId;
  final AppApiService _api = Get.find<AppApiService>();
  final SessionService _session = Get.find<SessionService>();
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final TextEditingController messageController = TextEditingController();
  final RxBool showAttachments = false.obs;
  final RxBool isLoading = true.obs;
  final RxBool isSending = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadMessages();
  }

  Future<void> loadMessages() async {
    isLoading.value = true;

    try {
      final response = await _api.getConversationMessages(
        conversationId,
        limit: 50,
      );
      final items = List<Map<String, dynamic>>.from(
        (response['items'] as List?) ?? const <dynamic>[],
      );

      messages.assignAll(items.reversed.map(_mapMessage));
      await _markMessagesAsRead(items);
    } on ApiException catch (error) {
      Get.snackbar(
        'Messages Unavailable',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (_) {
      Get.snackbar(
        'Messages Unavailable',
        'Unable to load this conversation right now.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  ChatMessage _mapMessage(Map<String, dynamic> item) {
    final sender = item['sender'] is Map<String, dynamic>
        ? item['sender'] as Map<String, dynamic>
        : <String, dynamic>{};
    final currentUserId = _session.user?['id']?.toString() ?? '';
    final senderId = sender['id']?.toString() ?? '';
    final messageType = item['messageType']?.toString() ?? '';
    final encryptedPayload =
        (item['encryptedPayload'] as String?)?.trim() ?? '';
    final preview = (item['previewText'] as String?)?.trim() ?? '';

    String content = encryptedPayload.isNotEmpty ? encryptedPayload : preview;
    if (content.isEmpty && messageType.isNotEmpty && messageType != 'TEXT') {
      content = messageType.replaceAll('_', ' ').toLowerCase();
    }
    if (content.isEmpty) {
      content = 'Message';
    }

    return ChatMessage(
      id: item['id']?.toString() ?? '',
      senderName: (sender['name'] as String?)?.trim().isNotEmpty == true
          ? (sender['name'] as String).trim()
          : 'Unknown',
      senderImage: null,
      message: content,
      time: _formatMessageTime(item['createdAt']?.toString() ?? ''),
      isUserMessage: senderId == currentUserId,
    );
  }

  String _formatMessageTime(String rawTimestamp) {
    final timestamp = DateTime.tryParse(rawTimestamp)?.toLocal();
    if (timestamp == null) {
      return '';
    }
    return DateFormat('h:mm a').format(timestamp);
  }

  Future<void> _markMessagesAsRead(List<Map<String, dynamic>> items) async {
    final currentUserId = _session.user?['id']?.toString() ?? '';
    for (final item in items) {
      final sender = item['sender'] is Map<String, dynamic>
          ? item['sender'] as Map<String, dynamic>
          : <String, dynamic>{};
      final senderId = sender['id']?.toString() ?? '';
      final messageId = item['id']?.toString() ?? '';

      if (messageId.isEmpty || senderId.isEmpty || senderId == currentUserId) {
        continue;
      }

      try {
        await _api.markMessageDelivered(messageId);
        await _api.markMessageRead(messageId);
      } catch (_) {
        // Best-effort receipts should not block the thread UI.
      }
    }
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || isSending.value) return;

    isSending.value = true;
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';

    try {
      await _api.sendTextMessage(conversationId, trimmed);
      messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderName: 'You',
          message: trimmed,
          time: '$hour:$minute $period',
          isUserMessage: true,
        ),
      );
      messageController.clear();
      if (Get.isRegistered<InboxController>()) {
        await Get.find<InboxController>().loadConversations();
      }
    } on ApiException catch (error) {
      Get.snackbar(
        'Message Failed',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (_) {
      Get.snackbar(
        'Message Failed',
        'Unable to send this message right now.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSending.value = false;
    }
  }

  void toggleAttachments() => showAttachments.toggle();

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }
}

// =====================
// CHAT SCREEN
// =====================
class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String contactName;
  final String contactPhone;
  final String contactImage;
  final bool isOnline;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.contactName,
    required this.contactPhone,
    required this.contactImage,
    required this.isOnline,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatController controller;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    controller = Get.put(
      ChatController(conversationId: widget.conversationId),
      tag: widget.conversationId,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    if (Get.isRegistered<ChatController>(tag: widget.conversationId)) {
      Get.delete<ChatController>(tag: widget.conversationId, force: true);
    }
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: _buildAppBar(),
      body: Obx(() {
        if (controller.isLoading.value && controller.messages.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true,
                controller: _scrollController,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final msg = controller
                      .messages[controller.messages.length - 1 - index];
                  return _buildBubble(msg);
                },
              ),
            ),
            _buildInputArea(),
            controller.showAttachments.value
                ? _buildAttachmentPanel()
                : const SizedBox.shrink(),
          ],
        );
      }),
    );
  }

  // ── App Bar ─────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      shadowColor: Colors.grey.shade200,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: AppColors.textDark, size: 22.sp),
        onPressed: () => Get.back(),
      ),
      title: Row(
        children: [
          _buildHeaderAvatar(),
          SizedBox(width: 10.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.contactName,
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                widget.isOnline
                    ? 'Online'
                    : (widget.contactPhone.isEmpty
                          ? 'Direct conversation'
                          : widget.contactPhone),
                style: GoogleFonts.poppins(
                  fontSize: 11.sp,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.call_outlined,
            color: AppColors.mainAppColor,
            size: 22.sp,
          ),
          onPressed: () {},
        ),
      ],
    );
  }

  // ── Message Bubble ──────────────────────────────────────
  Widget _buildHeaderAvatar() {
    final image = widget.contactImage.trim();
    final imageHeaders = Get.find<AppApiService>().buildImageHeaders();
    ImageProvider<Object>? imageProvider;
    if (image.startsWith('http')) {
      imageProvider = NetworkImage(image, headers: imageHeaders);
    } else if (image.isNotEmpty) {
      imageProvider = AssetImage(image);
    }

    final initials = widget.contactName.isNotEmpty
        ? widget.contactName
              .split(' ')
              .where((part) => part.isNotEmpty)
              .take(2)
              .map((part) => part[0].toUpperCase())
              .join()
        : '?';

    return CircleAvatar(
      radius: 18.r,
      backgroundImage: imageProvider,
      backgroundColor: Colors.grey.shade200,
      child: imageProvider == null
          ? Text(
              initials,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            )
          : null,
    );
  }

  Widget _buildBubble(ChatMessage msg) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: msg.isUserMessage
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isUserMessage) ...[
            CircleAvatar(
              radius: 16.r,
              backgroundImage: msg.senderImage != null
                  ? AssetImage(msg.senderImage!)
                  : null,
              backgroundColor: Colors.grey.shade300,
              child: msg.senderImage == null
                  ? Icon(Icons.person, size: 16.sp, color: Colors.grey)
                  : null,
            ),
            SizedBox(width: 8.w),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: msg.isUserMessage
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: msg.isUserMessage
                        ? AppColors.myBubble
                        : AppColors.otherBubble,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.r),
                      topRight: Radius.circular(16.r),
                      bottomLeft: Radius.circular(
                        msg.isUserMessage ? 16.r : 4.r,
                      ),
                      bottomRight: Radius.circular(
                        msg.isUserMessage ? 4.r : 16.r,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.message,
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      color: msg.isUserMessage
                          ? Colors.white
                          : AppColors.textDark,
                    ),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  msg.time,
                  style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Input Area ──────────────────────────────────────────
  Widget _buildInputArea() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Row(
        children: [
          // + button
          GestureDetector(
            onTap: controller.toggleAttachments,
            child: Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Icon(Icons.add, color: AppColors.textGrey, size: 22.sp),
            ),
          ),
          SizedBox(width: 10.w),
          // Text field
          Expanded(
            child: Container(
              height: 44.h,
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(22.r),
              ),
              child: TextField(
                controller: controller.messageController,
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  color: AppColors.textDark,
                ),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    color: AppColors.textGrey,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                ),
                onSubmitted: (v) async {
                  await controller.sendMessage(v);
                  _scrollToBottom();
                },
              ),
            ),
          ),
          SizedBox(width: 10.w),
          // Send button
          GestureDetector(
            onTap: () async {
              await controller.sendMessage(controller.messageController.text);
              _scrollToBottom();
            },
            child: Container(
              width: 40.w,
              height: 40.h,
              decoration: const BoxDecoration(
                color: AppColors.mainAppColor,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.send, color: Colors.white, size: 18.sp),
            ),
          ),
        ],
      ),
    );
  }

  // ── Attachment Panel ────────────────────────────────────
  Widget _buildAttachmentPanel() {
    final items = [
      {'icon': Icons.camera_alt_outlined, 'label': 'Camera'},
      {'icon': Icons.photo_outlined, 'label': 'Photos'},
      {'icon': Icons.insert_drive_file_outlined, 'label': 'Document'},
      {'icon': Icons.location_on_outlined, 'label': 'Location'},
      {'icon': Icons.contacts_outlined, 'label': 'Contact'},
      {'icon': Icons.bar_chart_outlined, 'label': 'Poll'},
      {'icon': Icons.event_outlined, 'label': 'Event'},
      {'icon': Icons.more_horiz, 'label': 'More'},
    ];

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Column(
        children: [
          // drag handle
          Container(
            width: 36.w,
            height: 4.h,
            margin: EdgeInsets.only(bottom: 16.h),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.85,
              crossAxisSpacing: 10.w,
              mainAxisSpacing: 10.h,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52.w,
                    height: 52.h,
                    decoration: BoxDecoration(
                      color: AppColors.mainAppColor,
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    item['label'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 11.sp,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
