import '../data/mock_data.dart';
import 'package:flutter/material.dart';
import '../state/app_state.dart';

import '../ui.dart';

class SocialFeedScreen extends StatefulWidget {
  final AppState state;
  final AppRole currentRole;
  final void Function(String) onNavigate;
  const SocialFeedScreen({super.key, required this.state, required this.currentRole, required this.onNavigate});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  bool composerOpen = false;
  final postCtrl = TextEditingController();
  String selectedEventTag = 'Chiến dịch Mùa Đông Ấm & Hỗ trợ Thanh niên';
  String? selectedImageKey = '1';
  bool showImagePicker = false;
  bool attachEventCard = true;
  String filterMode = 'all'; // all | events_only | mine
  String? openCommentPostId = 'post-event-1';
  Map<String, TextEditingController> commentCtrls = {};

  String eventTitle = 'Ngày hội Thanh niên Chuyển đổi số Trấn Biên';
  String eventDateStr = '29/11/2026';
  final eventTimeCtrl = TextEditingController(text: '08:00 - 11:00');
  final eventRoomCtrl = TextEditingController(text: 'Nhà văn hóa Khu phố 5');

  @override
  void initState() {
    super.initState();
    // Chỉ cán bộ Đoàn mới được phát động sự kiện (RBAC: member không thấy hàng toggle)
    attachEventCard = widget.currentRole == AppRole.wardOfficer;
    // Preselect từ màn khác (chia sẻ sau điểm danh/minh chứng)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pre = widget.state.preselectedSocialEvent;
      if (pre != null) {
        setState(() {
          selectedEventTag = pre['eventTag'] ?? widget.state.activeSession.title;
          if (pre['imageUrl'] != null) selectedImageKey = pre['imageUrl'];
          if (pre['defaultContent'] != null) postCtrl.text = pre['defaultContent']!;
          composerOpen = true;
        });
        widget.state.consumePreselectedSocialEvent();
      }
    });
  }

  @override
  void dispose() {
    postCtrl.dispose();
    eventTimeCtrl.dispose();
    eventRoomCtrl.dispose();
    for (final c in commentCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  ({String name, String role}) get authorProfile {
    final state = widget.state;
    return switch (widget.currentRole) {
      AppRole.secretary => (name: 'Nguyễn Văn An', role: 'Bí thư Chi đoàn Khu phố 5'),
      AppRole.wardOfficer => (name: state.backendUserName ?? 'Phan Thị Bích Thảo', role: 'Cán bộ Đoàn Phường Trấn Biên'),
      AppRole.member => (name: state.currentMember.name, role: 'Đoàn viên • ${state.currentMember.branchName}'),
    };
  }

  List<String> get eventOptions {
    final state = widget.state;
    final opts = <String>[state.activeSession.title, ...state.volunteerActivities.map((a) => a.title)];
    return opts.toSet().toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final author = authorProfile;
    final isOfficer = widget.currentRole != AppRole.member;

    final filteredPosts = state.socialPosts.where((p) {
      if (filterMode == 'events_only') return p.isEventPost;
      if (filterMode == 'mine') return p.authorName == author.name;
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Composer
          if (!composerOpen)
            GestureDetector(
              onTap: () => setState(() => composerOpen = true),
              child: AppCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    DAvatar(name: author.name, size: 40, bg: D.light, fg: D.primary, fontSize: 13),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isOfficer ? 'Đăng phát động sự kiện hoặc chia sẻ hoạt động...' : 'Chia sẻ khoảnh khắc sự kiện vừa tham gia...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: D.textMuted),
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: D.light, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.photo_camera_rounded, size: 20, color: D.primary),
                    ),
                  ],
                ),
              ),
            )
          else
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      DAvatar(name: author.name, size: 40, bg: D.light, fg: D.primary, fontSize: 13),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(author.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                            Text(author.role, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: D.primary)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => composerOpen = false),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: postCtrl,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: attachEventCard ? 'Nhập lời mời gọi, thông tin sự kiện để đoàn viên bấm đăng ký trực tiếp...' : 'Chia sẻ cảm nhận và hình ảnh về hoạt động đã tham gia...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      filled: true,
                      fillColor: D.grayBg,
                      contentPadding: const EdgeInsets.all(12),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: D.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: D.primary, width: 1.5)),
                    ),
                  ),
                  // Toggle kèm thẻ sự kiện (chỉ cán bộ Đoàn; member ẩn hoàn toàn)
                  if (isOfficer) const SizedBox(height: 10),
                  if (isOfficer) Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.event_available_rounded, size: 16, color: D.primary),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('Kèm nút "Đăng ký tham dự" (Đẩy về Lịch)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)))),
                        Switch(value: attachEventCard, activeColor: D.primary, onChanged: (v) => setState(() => attachEventCard = v)),
                      ],
                    ),
                  ),
                  if (attachEventCard)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: D.accentLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: D.primary.withValues(alpha: 0.2))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DTextField(controller: TextEditingController(text: eventTitle), label: 'Tên sự kiện mở đăng ký', isDense: false),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Ngày tổ chức', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                                    const SizedBox(height: 3),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9), border: Border.all(color: D.border)),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: eventDateStr,
                                          isExpanded: true,
                                          items: scheduleWeekDays.where((d) => d['key'] != 'all').map((d) => DropdownMenuItem(value: d['key'], child: Text('${d['label']} — ${d['key']}', style: const TextStyle(fontSize: 12)))).toList(),
                                          onChanged: (v) => setState(() => eventDateStr = v ?? eventDateStr),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: DTextField(controller: eventTimeCtrl, label: 'Khung giờ', isDense: false)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          DTextField(controller: eventRoomCtrl, label: 'Địa điểm', isDense: false),
                        ],
                      ),
                    )
                  else ...[
                    const SizedBox(height: 10),
                    const Text('Gắn thẻ hoạt động đã tham gia', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: D.border)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedEventTag,
                          isExpanded: true,
                          items: eventOptions.map((ev) => DropdownMenuItem(value: ev, child: Text(ev, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (v) => setState(() => selectedEventTag = v ?? selectedEventTag),
                        ),
                      ),
                    ),
                  ],
                  // Ảnh đính kèm (mock placeholder)
                  if (selectedImageKey != null) ...[
                    const SizedBox(height: 12),
                    Stack(
                      children: [
                        _postImage(selectedImageKey!, height: 150),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: GestureDetector(
                            onTap: () => setState(() => selectedImageKey = null),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle),
                              child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (showImagePicker)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Thư viện ảnh sự kiện mẫu:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                          const SizedBox(height: 8),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 2.6,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            children: socialEventPresets.map((preset) {
                              final key = preset['id']!.split('-').last;
                              return GestureDetector(
                                onTap: () => setState(() {
                                  selectedImageKey = key;
                                  selectedEventTag = preset['eventTag']!;
                                  showImagePicker = false;
                                }),
                                child: Container(
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: D.border)),
                                  child: Row(
                                    children: [
                                      _postImage(key, width: 48, height: double.infinity),
                                      Expanded(child: Padding(padding: const EdgeInsets.all(6), child: Text(preset['label']!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))))),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => showImagePicker = !showImagePicker),
                        child: Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(color: D.light, borderRadius: BorderRadius.circular(12)),
                          child: const Row(children: [
                            Icon(Icons.image_rounded, size: 15, color: D.primary),
                            SizedBox(width: 5),
                            Text('Thư viện', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: D.primary)),
                          ]),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          if (postCtrl.text.trim().isEmpty) {
                            widget.state.showToast('Vui lòng nhập nội dung bài viết!');
                            return;
                          }
                          final dayEntry = scheduleWeekDays.firstWhere((d) => d['key'] == eventDateStr, orElse: () => {'key': '', 'label': 'CN', 'dayNum': ''});
                          widget.state.createSocialPost(
                            content: postCtrl.text.trim(),
                            eventTag: attachEventCard ? eventTitle : selectedEventTag,
                            imageUrl: selectedImageKey, // String?
                            authorName: author.name,
                            authorRole: author.role,
                            isEventPost: attachEventCard,
                            eventSchedule: attachEventCard
                                ? ScheduleItem(
                                    id: 'ev-soc-${DateTime.now().millisecondsSinceEpoch}',
                                    title: eventTitle,
                                    category: 'Sự kiện Đoàn',
                                    dateStr: eventDateStr,
                                    dayOfWeek: dayEntry['label']!,
                                    timeSlot: eventTimeCtrl.text,
                                    room: eventRoomCtrl.text,
                                    organizer: author.name,
                                    format: 'Trực tiếp • Điểm danh QR',
                                    points: '+20 điểm',
                                    isELearning: false,
                                  )
                                : null,
                          );
                          setState(() {
                            postCtrl.clear();
                            composerOpen = false;
                          });
                          widget.state.showToast(attachEventCard ? 'Đã đăng bài phát động sự kiện kèm nút Đăng ký tham dự!' : 'Đã đăng bài viết lên Bảng tin (+5đ)!');
                        },
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(color: D.primary, borderRadius: BorderRadius.circular(12)),
                          child: const Row(children: [
                            Icon(Icons.send_rounded, size: 14, color: Colors.white),
                            SizedBox(width: 6),
                            Text('Đăng bài', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          // Filter chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _filterChip('all', 'Tất cả (${state.socialPosts.length})'),
                _filterChip('events_only', 'Sự kiện mở đăng ký'),
                _filterChip('mine', 'Bài của tôi'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (filteredPosts.isEmpty)
            AppCard(
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, size: 32, color: Color(0xFFA5B4FC)),
                    const SizedBox(height: 8),
                    const Text('Chưa có bài viết nào', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                    const Text('Chạm khung đăng bài phía trên để chia sẻ sự kiện mới!', style: TextStyle(fontSize: 12, color: D.textMuted)),
                  ],
                ),
              ),
            )
          else
            ...filteredPosts.map((post) => _postCard(state, post, author.name)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _filterChip(String id, String label) {
    final active = filterMode == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => filterMode = id),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: active ? D.primary : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: active ? D.primary : D.border),
          ),
          child: Center(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? Colors.white : const Color(0xFF475569)))),
        ),
      ),
    );
  }

  /// Placeholder ảnh mock (không dùng ảnh mạng)
  Widget _postImage(String key, {double? width, required double height}) {
    final presets = {
      '1': (Icons.forest_rounded, 'Chiến dịch Mùa Đông Ấm'),
      '2': (Icons.volunteer_activism_rounded, 'Hiến máu Giọt hồng'),
      '3': (Icons.groups_rounded, 'Sinh hoạt Chi đoàn'),
      '4': (Icons.devices_rounded, 'Hỗ trợ VNeID'),
    };
    final (icon, label) = presets[key] ?? presets['1']!;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [D.primary.withValues(alpha: 0.85), const Color(0xFF2024B8)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 34, color: Colors.white),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _postCard(AppState state, SocialPost post, String myName) {
    final isCommentsOpen = openCommentPostId == post.id;
    final ev = post.eventSchedule;
    final isInMySchedule = ev != null && state.mySchedule.any((s) => s.id == ev.id || s.title == ev.title);

    final canModerate = widget.currentRole.canModerateFeed;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: post.pinned ? const Color(0xFFFDE68A) : D.cardBorder),
        boxShadow: [BoxShadow(color: const Color(0x090F172A), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                DAvatar(name: post.authorName, size: 40, bg: D.light, fg: D.primary, fontSize: 13),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(child: Text(post.authorName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)))),
                          if (post.pinned) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.push_pin_rounded, size: 12, color: Color(0xFFB45309)),
                          ],
                          if (post.verifiedOfficer) ...[
                            const SizedBox(width: 6),
                            Pill('Cán bộ Đoàn', fontSize: 9, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
                          ],
                        ],
                      ),
                      Text('${post.authorRole} • ${post.createdAt}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: D.textMuted)),
                    ],
                  ),
                ),
                if (canModerate)
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF94A3B8)),
                    onSelected: (v) {
                      if (v == 'pin') {
                        state.togglePinSocialPost(post.id);
                        state.showToast(post.pinned ? 'Đã bỏ ghim bài viết.' : 'Đã ghim bài viết lên đầu Bảng tin.');
                      } else if (v == 'delete') {
                        state.deleteSocialPost(post.id);
                        state.showToast('Đã xóa bài viết vi phạm khỏi Bảng tin.');
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'pin', child: Row(children: [Icon(post.pinned ? Icons.push_pin_outlined : Icons.push_pin_rounded, size: 16, color: const Color(0xFFB45309)), const SizedBox(width: 8), Text(post.pinned ? 'Bỏ ghim' : 'Ghim bài chính thức', style: const TextStyle(fontSize: 12.5))])),
                      PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFDC2626)), const SizedBox(width: 8), Text('Xóa bài', style: const TextStyle(fontSize: 12.5, color: Color(0xFFDC2626)))])),
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(post.content, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), height: 1.5)),
          ),
          if (post.imageUrl != null) _postImage(post.imageUrl!, height: 200),
          if (post.isEventPost && ev != null)
            Container(
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: D.accentLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: D.primary.withValues(alpha: 0.2))),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: D.primary.withValues(alpha: 0.2))),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(ev.dayOfWeek, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: D.primary)),
                            Text(ev.dateStr.substring(0, 5), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(ev.points, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: D.greenDark)),
                                const SizedBox(width: 8),
                                Icon(Icons.people_outline_rounded, size: 12, color: D.textMuted),
                                const SizedBox(width: 3),
                                Text('${post.registeredCount} đã đăng ký', style: const TextStyle(fontSize: 11, color: D.textMuted)),
                              ],
                            ),
                            Text(ev.title, maxLines: 2, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), height: 1.25)),
                            Text('${ev.timeSlot} • ${ev.room}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      final res = state.registerEventFromSocialPost(post);
                      if (res['ok'] != true) {
                        widget.onNavigate('makeup');
                        return;
                      }
                      state.showToast('Đã đăng ký "${ev.title}" & tự động thêm vào Lịch cá nhân!');
                    },
                    child: Container(
                      width: double.infinity,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isInMySchedule ? D.greenLight : D.primary,
                        borderRadius: BorderRadius.circular(12),
                        border: isInMySchedule ? Border.all(color: const Color(0xFFA7F3D0)) : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(isInMySchedule ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded, size: 16, color: isInMySchedule ? D.greenDark : Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            isInMySchedule ? 'Đã có trong Lịch • Xem Lịch cá nhân' : 'Đăng ký tham dự (Thêm vào Lịch)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isInMySchedule ? D.greenDark : Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (!post.isEventPost && post.eventTag.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: D.light, borderRadius: BorderRadius.circular(9)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 13, color: D.primary),
                    const SizedBox(width: 5),
                    Flexible(child: Text(post.eventTag, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: D.primary))),
                  ],
                ),
              ),
            ),
          Divider(height: 1, color: Colors.grey.shade100),
          Row(
            children: [
              _actionBtn(
                post.likedByMe ? const Color(0xFFE11D48) : const Color(0xFF475569),
                Icons.favorite_rounded,
                '${post.likesCount}',
                fill: post.likedByMe,
                onTap: () => state.toggleLikeSocialPost(post.id),
              ),
              _actionBtn(D.primary, Icons.mode_comment_rounded, '${post.comments.length} bình luận', onTap: () => setState(() => openCommentPostId = isCommentsOpen ? null : post.id)),
              _actionBtn(const Color(0xFF475569), Icons.share_rounded, 'Chia sẻ', onTap: () => state.showToast('Đã sao chép liên kết bài viết của ${post.authorName}!')),
            ],
          ),
          if (isCommentsOpen)
            Container(
              color: D.grayBg,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.comments.isEmpty)
                    const Center(child: Text('Hãy là người đầu tiên gửi bình luận!', style: TextStyle(fontSize: 12, color: D.textMuted)))
                  else
                    ...post.comments.map((cmt) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: D.border.withValues(alpha: 0.7))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(cmt.authorName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: D.primary))),
                                  Text(cmt.time, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                ],
                              ),
                              Text(cmt.text, style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
                            ],
                          ),
                        )),
                  const SizedBox(height: 6),
                  // Quick comments
                  SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: ['Đăng ký ngay!', 'Hoạt động rất thiết thực!', 'Hẹn gặp tại sự kiện!'].map((quick) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => state.addSocialComment(post.id, myName, quick),
                            child: Container(
                              height: 32,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), border: Border.all(color: D.border)),
                              child: Center(child: Text('+ $quick', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF334155)))),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentCtrls.putIfAbsent(post.id, () => TextEditingController()),
                          onSubmitted: (_) => state.addSocialComment(post.id, myName, commentCtrls[post.id]!.text),
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Viết bình luận...',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: D.border)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: D.primary, width: 1.5)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          final c = commentCtrls[post.id]!;
                          state.addSocialComment(post.id, myName, c.text);
                          c.clear();
                          FocusManager.instance.primaryFocus?.unfocus();
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: D.primary, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
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

  Widget _actionBtn(Color color, IconData icon, String label, {VoidCallback? onTap, bool fill = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 38,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color, opticalSize: 24, weight: fill ? 700 : 400),
              const SizedBox(width: 6),
              Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color))),
            ],
          ),
        ),
      ),
    );
  }
}
