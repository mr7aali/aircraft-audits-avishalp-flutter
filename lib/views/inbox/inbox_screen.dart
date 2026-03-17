import 'package:avislap/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// =====================
// COLORS
// =====================

// =====================
// MODELS
// =====================
class ChatListItem {
  final String id;
  final String userName;
  final String phone;
  final String userImage;
  final String lastMessage;
  final String time;
  final bool isOnline;
  final int unreadCount;

  ChatListItem({
    required this.id,
    required this.userName,
    required this.phone,
    required this.userImage,
    required this.lastMessage,
    required this.time,
    required this.isOnline,
    required this.unreadCount,
  });
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
  final RxList<ChatListItem> chatList = <ChatListItem>[].obs;
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final RxString selectedTab = 'All'.obs;

  final List<String> tabs = ['All', 'Unread (3)', 'Groups', 'Favorite'];

  @override
  void onInit() {
    super.onInit();
    chatList.assignAll([
      ChatListItem(
        id: '1',
        userName: 'Dianne Russell',
        phone: '(209) 555-0104',
        userImage: 'assets/images/mursalin.jpg',
        lastMessage: '(209) 555-0104',
        time: '9:30 am',
        isOnline: true,
        unreadCount: 1,
      ),
      ChatListItem(
        id: '2',
        userName: 'Marvin McKinney',
        phone: '(302) 555-0107',
        userImage: 'assets/images/nirob.jpg',
        lastMessage: '(302) 555-0107',
        time: '9:30 am',
        isOnline: true,
        unreadCount: 3,
      ),
      ChatListItem(
        id: '3',
        userName: 'Bessie Cooper',
        phone: '(808) 555-0111',
        userImage: 'assets/images/Bessie.png',
        lastMessage: '(808) 555-0111',
        time: '9:30 am',
        isOnline: true,
        unreadCount: 1,
      ),
      ChatListItem(
        id: '4',
        userName: 'Esther Howard',
        phone: '(505) 555-0125',
        userImage: 'assets/images/Esther.png',
        lastMessage: '(505) 555-0125',
        time: '9:30 am',
        isOnline: false,
        unreadCount: 1,
      ),
      ChatListItem(
        id: '5',
        userName: 'Eleanor Pena',
        phone: '(229) 555-0109',
        userImage: 'assets/images/Eleanor.png',
        lastMessage: '(229) 555-0109',
        time: '9:30 am',
        isOnline: false,
        unreadCount: 0,
      ),
      ChatListItem(
        id: '6',
        userName: 'Kristin Watson',
        phone: '(201) 555-0124',
        userImage: 'assets/images/Kristin.png',
        lastMessage: '(201) 555-0124',
        time: '9:30 am',
        isOnline: false,
        unreadCount: 0,
      ),
    ]);
  }

  void updateSearch(String query) => searchQuery.value = query;

  List<ChatListItem> getFilteredChats() {
    return chatList.where((chat) {
      final matchesSearch = searchQuery.value.isEmpty ||
          chat.userName.toLowerCase().contains(searchQuery.value.toLowerCase());
      return matchesSearch;
    }).toList();
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
            child: Icon(Icons.arrow_back, color: AppColors.textDark, size: 22.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Search Category',
              style: GoogleFonts.poppins(
                fontSize: 15.sp,
                color: AppColors.textGrey,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: AppColors.mainAppColor,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(Icons.search, color: Colors.white, size: 20.sp),
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
            'Chat',
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
    return Obx(() => Padding(
      padding: EdgeInsets.only(left: 16.w, bottom: 8.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: controller.tabs.map((tab) {
            final isSelected = controller.selectedTab.value == tab;
            return GestureDetector(
              onTap: () => controller.selectedTab.value = tab,
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
                  tab,
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
    ));
  }

  // ── Chat List ───────────────────────────────────────────
  Widget _buildChatList() {
    return Obx(() {
      final chats = controller.getFilteredChats();
      if (chats.isEmpty) {
        return Center(
          child: Text(
            'No chats found',
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
      onTap: () {
        Get.to(() => ChatScreen(
          contactName: chat.userName,
          contactPhone: chat.phone,
          contactImage: chat.userImage,
        ));
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            // Avatar with online dot
            Stack(
              children: [
                CircleAvatar(
                  radius: 26.r,
                  backgroundImage: AssetImage(chat.userImage),
                  backgroundColor: Colors.grey.shade200,
                  child: chat.userImage.isEmpty
                      ? Icon(Icons.person, color: Colors.grey, size: 26.sp)
                      : null,
                ),
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
                    chat.phone,
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
}

// =====================
// CHAT CONTROLLER
// =====================
class ChatController extends GetxController {
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final TextEditingController messageController = TextEditingController();
  final RxBool showAttachments = false.obs;

  @override
  void onInit() {
    super.onInit();
    messages.assignAll([
      ChatMessage(
        id: '1',
        senderName: 'John Smith',
        senderImage: 'assets/images/mursalin.jpg',
        message: "I'm planning to go to the gym later. Want to grab coffee after?",
        time: '10:30 AM',
        isUserMessage: false,
      ),
      ChatMessage(
        id: '2',
        senderName: 'You',
        message: 'Sure! Let me check my schedule',
        time: '10:30 AM',
        isUserMessage: true,
      ),
      ChatMessage(
        id: '3',
        senderName: 'John Smith',
        senderImage: 'assets/images/mursalin.jpg',
        message: 'Perfect! I know a great place downtown.',
        time: '10:30 AM',
        isUserMessage: false,
      ),
      ChatMessage(
        id: '4',
        senderName: 'You',
        message: 'How about 4 PM? I should be done by then.',
        time: '10:30 AM',
        isUserMessage: true,
      ),
      ChatMessage(
        id: '5',
        senderName: 'You',
        message: 'Hey! How was the new design project coming along?',
        time: '10:30 AM',
        isUserMessage: true,
      ),
    ]);
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';

    messages.add(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderName: 'You',
      message: text.trim(),
      time: '$hour:$minute $period',
      isUserMessage: true,
    ));
    messageController.clear();
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
  final String contactName;
  final String contactPhone;
  final String contactImage;

  const ChatScreen({
    super.key,
    required this.contactName,
    required this.contactPhone,
    required this.contactImage,
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
    controller = Get.put(ChatController(), tag: widget.contactName);
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
      body: Column(
        children: [
          Expanded(
            child: Obx(() => ListView.builder(
              reverse: true,
              controller: _scrollController,
              padding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              itemCount: controller.messages.length,
              itemBuilder: (context, index) {
                final msg = controller.messages[
                controller.messages.length - 1 - index];
                return _buildBubble(msg);
              },
            )),
          ),
          _buildInputArea(),
          Obx(() => controller.showAttachments.value
              ? _buildAttachmentPanel()
              : const SizedBox.shrink()),
        ],
      ),
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
          CircleAvatar(
            radius: 18.r,
            backgroundImage: AssetImage(widget.contactImage),
            backgroundColor: Colors.grey.shade200,
          ),
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
                widget.contactPhone,
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
          icon: Icon(Icons.call_outlined,
              color: AppColors.mainAppColor, size: 22.sp),
          onPressed: () {},
        ),
      ],
    );
  }

  // ── Message Bubble ──────────────────────────────────────
  Widget _buildBubble(ChatMessage msg) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment:
        msg.isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                      horizontal: 14.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: msg.isUserMessage
                        ? AppColors.myBubble
                        : AppColors.otherBubble,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.r),
                      topRight: Radius.circular(16.r),
                      bottomLeft: Radius.circular(
                          msg.isUserMessage ? 16.r : 4.r),
                      bottomRight: Radius.circular(
                          msg.isUserMessage ? 4.r : 16.r),
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
              child: Icon(Icons.add,
                  color: AppColors.textGrey, size: 22.sp),
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
                    fontSize: 13.sp, color: AppColors.textDark),
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
                onSubmitted: (v) {
                  controller.sendMessage(v);
                  _scrollToBottom();
                },
              ),
            ),
          ),
          SizedBox(width: 10.w),
          // Send button
          GestureDetector(
            onTap: () {
              controller.sendMessage(controller.messageController.text);
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

  @override
  void dispose() {
    _scrollController.dispose();
    Get.delete<ChatController>(tag: widget.contactName);
    super.dispose();
  }
}