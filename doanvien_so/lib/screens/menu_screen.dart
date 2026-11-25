import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../ui.dart';
import 'assistant_screen.dart';

class UtilitiesMenuScreen extends StatefulWidget {
  final AppState state;
  final AppRole currentRole;
  final void Function(String) onNavigateScreen;
  final VoidCallback onOpenRoleModal;
  final VoidCallback onOpenNotification;
  final VoidCallback onOpenAdmin;
  final VoidCallback onLogout;
  const UtilitiesMenuScreen({
    super.key,
    required this.state,
    required this.currentRole,
    required this.onNavigateScreen,
    required this.onOpenRoleModal,
    required this.onOpenNotification,
    required this.onOpenAdmin,
    required this.onLogout,
  });

  @override
  State<UtilitiesMenuScreen> createState() => _UtilitiesMenuScreenState();
}

class _UtilitiesMenuScreenState extends State<UtilitiesMenuScreen> {
  String searchQuery = '';
  final searchCtrl = TextEditingController();

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final member = state.currentMember;
    final (name, subtitle, badge) = switch (widget.currentRole) {
      AppRole.secretary => ('Nguyễn Văn An', 'Bí thư Chi đoàn • Khu phố 5', '${state.members.length} ĐV'),
      AppRole.wardOfficer => (state.backendUserName ?? 'Phan Thị Bích Thảo', 'Cán bộ Đoàn • Phường Trấn Biên', '12 Chi đoàn'),
      AppRole.member => (member.name, 'Đoàn viên • ${member.branchName}', '${state.userPoints} đ'),
    };

    final shortcuts = <(String, String, String, IconData, Color, Color, VoidCallback)>[
      // ===== Chung (mọi vai trò) =====
      ('assistant', 'Trợ lý ảo AI', 'Hỏi chức năng ở đâu — dẫn thẳng tới màn hình', Icons.smart_toy_rounded, const Color(0xFFF5F3FF), const Color(0xFF6D28D9), () => openAssistantSheet(context, state, widget.currentRole, widget.onNavigateScreen)),
      ('home', 'Trang chủ', 'Tổng quan hoạt động', Icons.home_rounded, D.light, D.primary, () => widget.onNavigateScreen(widget.currentRole == AppRole.wardOfficer ? 'ward_dash' : 'home')),
      ('social', 'Bảng tin Đoàn viên', '${state.socialPosts.length} bài viết sự kiện', Icons.article_rounded, const Color(0xFFEFF6FF), const Color(0xFF1D4ED8), () => widget.onNavigateScreen('social')),

      // ===== Riêng Đoàn viên =====
      if (widget.currentRole == AppRole.member) ...[
        ('schedule', 'Lịch hoạt động cá nhân', '${state.mySchedule.length} sự kiện đã đăng ký', Icons.calendar_month_rounded, const Color(0xFFF0F9FF), const Color(0xFF0369A1), () => widget.onNavigateScreen('makeup')),
        ('qr', 'Quét QR Điểm danh', 'Xác thực 2 lớp GPS', Icons.qr_code_2, const Color(0xFFEEF2FF), D.primary, () => widget.onNavigateScreen('scan_qr')),
        ('rewards', 'Thi đua & Đổi quà', '${state.volunteerActivities.length} phong trào mới', Icons.workspace_premium_rounded, const Color(0xFFFFFBEB), const Color(0xFFB45309), () => widget.onNavigateScreen('rewards')),
        ('history', 'Lịch sử tham gia', 'Điểm rèn luyện cá nhân', Icons.history_rounded, const Color(0xFFF5F3FF), const Color(0xFF6D28D9), () => widget.onNavigateScreen('history')),
      ],

      // ===== Riêng Bí thư Chi đoàn =====
      if (widget.currentRole == AppRole.secretary) ...[
        ('schedule', 'Quản lý lịch chi đoàn', 'Tạo lịch • Duyệt đơn bù', Icons.calendar_month_rounded, const Color(0xFFF0F9FF), const Color(0xFF0369A1), () => widget.onNavigateScreen('makeup')),
        ('qr', 'Phát mã QR điểm danh', 'QR động + Geofence 100m', Icons.qr_code_2, const Color(0xFFEEF2FF), D.primary, () => widget.onNavigateScreen('create_qr')),
        ('members', 'Hồ sơ & Danh bạ', '${state.members.length} hồ sơ • Chuyển SH', Icons.groups_rounded, const Color(0xFFECFDF5), const Color(0xFF047857), () => widget.onNavigateScreen('members')),
        ('rewards', 'Thi đua chi đoàn', 'Cộng điểm • Khen thưởng ĐV', Icons.workspace_premium_rounded, const Color(0xFFFFFBEB), const Color(0xFFB45309), () => widget.onNavigateScreen('rewards')),
        ('reports', 'Báo cáo về Đoàn phường', 'Tổng hợp kỳ • Nộp phường', Icons.table_chart_rounded, const Color(0xFFECFEFF), const Color(0xFF0E7490), () => widget.onNavigateScreen('reports')),
      ],

      // ===== Riêng Cán bộ Đoàn Phường =====
      if (widget.currentRole == AppRole.wardOfficer) ...[
        ('schedule', 'Lịch cấp phường', 'Phát động • Duyệt chi đoàn', Icons.calendar_month_rounded, const Color(0xFFF0F9FF), const Color(0xFF0369A1), () => widget.onNavigateScreen('makeup')),
        ('rewards', 'Thi đua toàn phường', 'Xét khen thưởng chi đoàn', Icons.workspace_premium_rounded, const Color(0xFFFFFBEB), const Color(0xFFB45309), () => widget.onNavigateScreen('rewards')),
        ('branches', 'Quản lý 12 Chi đoàn', 'Theo dõi cấp Phường/Xã', Icons.location_city_rounded, const Color(0xFFF0FDFA), const Color(0xFF0F766E), () => widget.onNavigateScreen('ward_branches')),
        ('ward_rank', 'Xếp hạng Chi đoàn', 'Thi đua toàn Phường', Icons.emoji_events_rounded, const Color(0xFFFFF7ED), const Color(0xFFC2410C), () => widget.onNavigateScreen('ward_rewards')),
        ('reports', 'Báo cáo Đoàn vụ', 'Xuất văn bản tự động', Icons.table_chart_rounded, const Color(0xFFECFEFF), const Color(0xFF0E7490), () => widget.onNavigateScreen('ward_reports')),
      ],
    ];

    final q = searchQuery.trim().toLowerCase();
    final filtered = shortcuts.where((s) => q.isEmpty || s.$2.toLowerCase().contains(q) || s.$3.toLowerCase().contains(q)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Tài khoản
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: D.light, borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.all(4),
                      child: Image.asset('assets/doantn.png', fit: BoxFit.contain),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                          Text(subtitle, style: const TextStyle(fontSize: 12, color: D.textMuted)),
                        ],
                      ),
                    ),
                    Pill(badge, fontSize: 11),
                  ],
                ),
                const Divider(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: widget.onOpenRoleModal,
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(12)),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.layers_rounded, size: 14, color: D.primary),
                              SizedBox(width: 6),
                              Text('Đổi vai trò', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: widget.onOpenAdmin,
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(color: D.light, borderRadius: BorderRadius.circular(12)),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.verified_user_rounded, size: 14, color: D.primary),
                              SizedBox(width: 6),
                              Text('Tài khoản & Quyền', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: D.primary)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Search
          TextField(
            controller: searchCtrl,
            onChanged: (v) => setState(() => searchQuery = v),
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
              hintText: 'Tìm tiện ích, chức năng ứng dụng...',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: D.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: D.primary, width: 1.5)),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              children: [
                const Expanded(child: Text('Tất cả lối tắt tiện ích', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)))),
                Text('${filtered.length} mục', style: const TextStyle(fontSize: 12, color: D.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.55,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: filtered.map((s) => _shortcutTile(s)).toList(),
          ),
          const SizedBox(height: 16),
          // Nhóm tiện ích mở rộng
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _groupTile(
                  Icons.auto_awesome_rounded,
                  'Phong trào & Hoạt động',
                  'Lịch cá nhân, Chuyên đề, Ví quà',
                  expanded: openGroup == 'phongtrao',
                  onTap: () => setState(() => openGroup = openGroup == 'phongtrao' ? '' : 'phongtrao'),
                  children: [
                    ('Lịch hoạt động & Đăng ký chuyên đề', () => widget.onNavigateScreen('makeup')),
                    ('Hoạt động Tình nguyện & Ví Voucher', () => widget.onNavigateScreen('rewards')),
                  ],
                ),
                _groupTile(
                  Icons.notifications_none_rounded,
                  'Thông báo & Hệ thống',
                  'Hộp thư nhắc lịch, sao lưu dữ liệu',
                  expanded: openGroup == 'hethong',
                  onTap: () => setState(() => openGroup = openGroup == 'hethong' ? '' : 'hethong'),
                  children: [
                    ('Hộp thư Thông báo & Lịch sắp tới', widget.onOpenNotification),
                    ('Phân quyền, Nhật ký & Sao lưu JSON', widget.onOpenAdmin),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: widget.onLogout,
            child: Container(
              width: double.infinity,
              height: 44,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: D.border)),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, size: 16, color: Color(0xFF334155)),
                  SizedBox(width: 8),
                  Text('Đăng xuất khỏi tài khoản', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String openGroup = 'phongtrao';

  Widget _shortcutTile((String, String, String, IconData, Color, Color, VoidCallback) s) {
    return GestureDetector(
      onTap: s.$7,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: D.cardBorder),
          boxShadow: [BoxShadow(color: const Color(0x090F172A), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: s.$5, borderRadius: BorderRadius.circular(10)),
              child: Icon(s.$4, size: 17, color: s.$6),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                Text(s.$3, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: D.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupTile(IconData icon, String title, String sub, {required bool expanded, required VoidCallback onTap, required List<(String, VoidCallback)> children}) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: D.light, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, size: 16, color: D.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                      Text(sub, style: const TextStyle(fontSize: 12, color: D.textMuted)),
                    ],
                  ),
                ),
                Icon(expanded ? Icons.keyboard_arrow_down_rounded : Icons.chevron_right_rounded, size: 18, color: const Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: children
                  .map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: GestureDetector(
                          onTap: c.$2,
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                Expanded(child: Text(c.$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
                                const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                              ],
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}
