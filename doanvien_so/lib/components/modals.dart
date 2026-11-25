import 'package:flutter/material.dart';
import '../main.dart' show AppStateScope;
import '../state/app_state.dart';
import '../data/mock_data.dart';
import '../ui.dart';

// ================== MODAL ĐỔI VAI TRÒ & NHẢY MÀN HÌNH ==================
Future<void> showRoleSwitcherSheet(
  BuildContext context, {
  required AppRole currentRole,
  required String activeScreen,
  required void Function(AppRole) onSelectRole,
  required void Function(String) onJump,
}) {
  final state = AppStateScope.of(context);
  final roles = [
    (id: AppRole.secretary, name: 'Bí thư Chi đoàn cơ sở', desc: 'Nguyễn Văn An • Chi đoàn KP5', icon: Icons.manage_accounts_rounded),
    (id: AppRole.member, name: 'Đoàn viên Thanh niên', desc: 'Trần Minh Quân • Chi đoàn KP5', icon: Icons.person_rounded),
    (id: AppRole.wardOfficer, name: 'Cán bộ Đoàn Xã / Phường', desc: 'Phan Thị Bích Thảo • P. Trấn Biên', icon: Icons.location_city_rounded),
  ];
  final isWardScreen = [screenWardDashS, screenWardBranchesS, screenWardReportsS, screenWardRewardsS].contains(activeScreen) ||
      (activeScreen == screenHomeS && currentRole == AppRole.wardOfficer);
  final screens = [
    (id: 'login', label: '1. Đăng nhập & Đăng ký', match: activeScreen == 'login'),
    (id: screenHomeS, label: '2. Trang chủ Chi đoàn (Bí thư)', match: activeScreen == screenHomeS && currentRole == AppRole.secretary),
    (id: screenCreateQrS, label: '3. Sinh hoạt, QR & Lưu trữ', match: activeScreen == screenCreateQrS),
    (id: screenScanQrS, label: '4. Quét QR & Lịch sử', match: activeScreen == screenScanQrS),
    (id: screenMembersS, label: '5. Danh bạ Hồ sơ & Chuyển SH', match: activeScreen == screenMembersS),
    (id: screenWardDashS, label: '6. Tổng hợp Xã & Báo cáo', match: isWardScreen),
    (id: screenMakeupS, label: '7. Lịch hoạt động cá nhân', match: activeScreen == screenMakeupS),
    (id: screenRewardsS, label: '8. Thi đua, Huy hiệu & Đổi quà', match: activeScreen == screenRewardsS),
    (id: screenSocialS, label: '9. Bảng tin Sự kiện Đoàn', match: activeScreen == screenSocialS),
    (id: screenMenuS, label: '10. Menu Tiện ích (Super-App)', match: activeScreen == screenMenuS),
  ];

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _SheetScaffold(
      child: Column(
        children: [
          sheetHeader(context, icon: Icons.auto_awesome_rounded, title: 'Đổi góc nhìn vai trò', subtitle: 'Chuyển đổi nhanh 3 nhóm người dùng'),
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(padding: EdgeInsets.only(left: 4, bottom: 6), child: Text('1. Vai trò tài khoản', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF475569)))),
          ),
          ...roles.map((r) {
            final selected = currentRole == r.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  onSelectRole(r.id);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected ? D.accentLight : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: selected ? D.primary : D.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: selected ? D.primary : D.light, borderRadius: BorderRadius.circular(12)),
                        child: Icon(r.icon, size: 20, color: selected ? Colors.white : D.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                            Text(r.desc, style: const TextStyle(fontSize: 12, color: D.textMuted)),
                          ],
                        ),
                      ),
                      if (selected) const Icon(Icons.check_rounded, color: D.primary, size: 18),
                    ],
                  ),
                ),
              ),
            );
          }),
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(padding: EdgeInsets.only(left: 4, bottom: 6, top: 4), child: Text('2. Lối tắt các màn hình Flutter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF475569)))),
          ),
          ...screens.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    onJump(s.id);
                  },
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: s.match ? D.primary : D.grayBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(s.label, style: TextStyle(fontSize: 13, color: s.match ? Colors.white : const Color(0xFF1E293B), fontWeight: s.match ? FontWeight.w700 : FontWeight.w500))),
                        if (s.match) const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),
              )),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              state.resetAppData();
              state.showToast('Đã khôi phục toàn bộ dữ liệu gốc!');
              Navigator.pop(ctx);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF475569),
              backgroundColor: const Color(0xFFF1F5F9),
              minimumSize: const Size.fromHeight(40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Khôi phục dữ liệu mặc định', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ),
  );
}

// Alias hằng số để dùng trong file này mà không import vòng app_shell
const screenHomeS = 'home';
const screenCreateQrS = 'create_qr';
const screenScanQrS = 'scan_qr';
const screenMembersS = 'members';
const screenWardDashS = 'ward_dash';
const screenWardBranchesS = 'ward_branches';
const screenWardReportsS = 'ward_reports';
const screenWardRewardsS = 'ward_rewards';
const screenMakeupS = 'makeup';
const screenRewardsS = 'rewards';
const screenSocialS = 'social';
const screenMenuS = 'menu';

// ================== MODAL THÔNG BÁO ==================
Future<void> showNotificationSheet(BuildContext context, AppRole role) {
  final state = AppStateScope.of(context);
  final roleKey = role.key;
  final notis = state.roleNotifications(roleKey);
  final unread = notis.where((n) => n.unread).length;
  final canCompose = role != AppRole.member;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _NotificationSheet(state: state, roleKey: roleKey, notis: notis, unread: unread, canCompose: canCompose),
  );
}

class _NotificationSheet extends StatefulWidget {
  final AppState state;
  final String roleKey;
  final List<AppNotification> notis;
  final int unread;
  final bool canCompose;
  const _NotificationSheet({required this.state, required this.roleKey, required this.notis, required this.unread, required this.canCompose});

  @override
  State<_NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends State<_NotificationSheet> {
  String activeTab = 'inbox';
  final composeTarget = ValueNotifier<String>('Nhóm công nhân làm xa KCN');
  final composeTitle = TextEditingController(text: 'Thông báo điều chỉnh lịch sinh hoạt tháng 12');
  final composeContent = TextEditingController(text: 'Kính đề nghị các đồng chí cập nhật lại thời gian họp lúc 20:00 tại Nhà văn hóa KP5 (hỗ trợ đăng ký ca bù nếu vướng tăng ca).');

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final notis = state.roleNotifications(widget.roleKey);
    final unread = notis.where((n) => n.unread).length;
    final upcoming = state.volunteerActivities.where((a) => a.status == 'upcoming').toList();
    final session = state.activeSession;

    return _SheetScaffold(
      child: StatefulBuilder(
        builder: (ctx, setSheet) => Column(
          children: [
            sheetHeader(context, icon: Icons.notifications_none_rounded, title: 'Lịch & Thông báo', subtitle: unread > 0 ? '$unread chưa đọc' : 'Đã đọc tất cả'),
            Row(
              children: [
                _sheetTab(ctx, 'inbox', 'Thông báo (${notis.length})', flex: true),
                _sheetTab(ctx, 'schedule', 'Lịch sắp tới', flex: true),
                if (widget.canCompose) _sheetTab(ctx, 'compose', 'Gửi tin', flex: true),
              ],
            ),
            const SizedBox(height: 12),
            if (activeTab == 'inbox') ...[
              if (unread > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SecondaryButton(
                    'Đánh dấu tất cả đã đọc',
                    icon: Icons.done_all_rounded,
                    height: 40,
                    fontSize: 12,
                    onPressed: () => setSheet(() {
                      state.markAllNotificationsRead(widget.roleKey);
                    }),
                  ),
                ),
              ...notis.map((n) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => setSheet(() => state.markNotificationRead(widget.roleKey, n.id)),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: n.unread ? D.accentLight : D.grayBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: n.unread ? D.primary.withValues(alpha: 0.25) : D.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: Text(n.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)))),
                                const SizedBox(width: 8),
                                Pill(n.unread ? 'Mới' : 'Đã đọc', bg: n.unread ? D.primary : const Color(0xFFE2E8F0), fg: n.unread ? Colors.white : const Color(0xFF475569), fontSize: 10),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(n.content, style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.45)),
                            Text(n.time, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                          ],
                        ),
                      ),
                    ),
                  )),
            ],
            if (activeTab == 'schedule') ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: D.accentLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: D.primary.withValues(alpha: 0.2))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Pill('Sinh hoạt định kỳ', bg: D.primary, fg: Colors.white, fontSize: 10),
                        const Spacer(),
                        const Row(children: [
                          Icon(Icons.check_circle_rounded, size: 13, color: D.greenDark),
                          SizedBox(width: 4),
                          Text('Nhắc 24h', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: D.greenDark)),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(session.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                    _iconRow(Icons.schedule_rounded, session.date),
                    _iconRow(Icons.place_rounded, session.location),
                  ],
                ),
              ),
              ...upcoming.map((a) => Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Pill('Tình nguyện', bg: D.light, fg: D.primary, fontSize: 10),
                              const Spacer(),
                              Text(a.points, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: D.primary)),
                            ],
                          ),
                          Text(a.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                          _iconRow(Icons.calendar_month_rounded, a.date),
                        ],
                      ),
                    ),
                  )),
            ],
            if (activeTab == 'compose' && widget.canCompose) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: D.border)),
                child: ValueListenableBuilder<String>(
                  valueListenable: composeTarget,
                  builder: (context, v, _) => DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: v,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'Nhóm công nhân làm xa KCN', child: Text('Nhóm công nhân làm xa / KCN (12 ĐV)', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 'Toàn Chi đoàn Khu phố 5', child: Text('Toàn thể Chi đoàn Khu phố 5 (46 ĐV)', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 'Nhóm đoàn viên tại địa phương', child: Text('Nhóm đoàn viên tại địa phương (31 ĐV)', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: '12 Bí thư Chi đoàn Phường Trấn Biên', child: Text('12 Bí thư Chi đoàn trực thuộc Phường', style: TextStyle(fontSize: 13))),
                      ],
                      onChanged: (v) => composeTarget.value = v!,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              DTextField(controller: composeTitle, label: 'Tiêu đề thông báo'),
              const SizedBox(height: 10),
              DTextField(controller: composeContent, label: 'Nội dung thông báo', maxLines: 3),
              const SizedBox(height: 12),
              PrimaryButton(
                'Phát thông báo ngay',
                icon: Icons.send_rounded,
                onPressed: () {
                  final target = composeTarget.value;
                  final role = target.contains('12 Bí thư') ? 'secretary' : 'member';
                  state.sendTargetedNotification(targetGroup: target, targetRole: role, title: composeTitle.text, content: composeContent.text);
                  state.showToast('Đã gửi thông báo tới "$target"!');
                  setSheet(() => activeTab = 'inbox');
                },
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF334155),
                backgroundColor: const Color(0xFFF1F5F9),
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Đóng', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetTab(BuildContext ctx, String id, String label, {bool flex = false}) {
    final active = activeTab == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => activeTab = id),
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 3)] : null,
          ),
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: active ? D.primary : const Color(0xFF475569))),
        ),
      ),
    );
  }

  Widget _iconRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(children: [
        Icon(icon, size: 13, color: D.primary),
        const SizedBox(width: 5),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF475569)))),
      ]),
    );
  }
}

// ================== MODAL QUẢN TRỊ & BẢO MẬT ==================
Future<void> showSystemAdminSheet(BuildContext context, AppRole role) {
  final state = AppStateScope.of(context);
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _SystemAdminSheet(state: state, role: role),
  );
}

class _SystemAdminSheet extends StatefulWidget {
  final AppState state;
  final AppRole role;
  const _SystemAdminSheet({required this.state, required this.role});

  @override
  State<_SystemAdminSheet> createState() => _SystemAdminSheetState();
}

class _SystemAdminSheetState extends State<_SystemAdminSheet> {
  String activeTab = 'account';
  String? restoreFeedback;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final member = state.currentMember;
    final Map<String, String> profile = switch (widget.role) {
      AppRole.secretary => {'name': state.backendUserName ?? 'Nguyễn Văn An', 'code': 'CB-KP5-2026', 'roleName': 'Bí thư Chi đoàn Khu phố 5', 'unit': 'Phường Trấn Biên, TP. Đồng Nai', 'phone': '0912.345.678', 'joinDate': '26/03/2017'},
      AppRole.wardOfficer => {'name': state.backendUserName ?? 'Phan Thị Bích Thảo', 'code': 'CB-PHUONG-01', 'roleName': 'Cán bộ Đoàn Phường Trấn Biên', 'unit': 'BCH Đoàn Phường Trấn Biên (12 Chi đoàn)', 'phone': '0908.123.999', 'joinDate': '26/03/2015'},
      AppRole.member => {'name': member.name, 'code': member.memberCode, 'roleName': 'Đoàn viên • Công nhân KCN', 'unit': '${member.branchName} • ${member.workplace}', 'phone': member.phone, 'joinDate': member.joinDate},
    };
    final branches = state.wardDataByMonth['11']!.branchesRank;

    return _SheetScaffold(
      child: StatefulBuilder(
        builder: (ctx, setSheet) => Column(
          children: [
            sheetHeader(context, icon: Icons.shield_rounded, title: 'Quản trị & Bảo mật', subtitle: 'Tài khoản, phân quyền & sao lưu'),
            Row(
              children: [
                _tab(ctx, 'account', 'Tài khoản'),
                _tab(ctx, 'security', 'Quyền'),
                _tab(ctx, 'logs', 'Nhật ký'),
                _tab(ctx, 'backup', 'Sao lưu'),
              ],
            ),
            const SizedBox(height: 12),
            if (activeTab == 'account') ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: D.accentLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: D.primary.withValues(alpha: 0.2))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.manage_accounts_rounded, size: 16, color: D.primary),
                      SizedBox(width: 8),
                      Text('Tài khoản đang đăng nhập', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: D.primary)),
                    ]),
                    const SizedBox(height: 8),
                    _kv('Họ tên', profile['name']!),
                    _kv('Mã định danh', profile['code']!, mono: true, valueColor: D.primary),
                    _kv('Vai trò', profile['roleName']!),
                    _kv('Số điện thoại', (state.securitySettings['maskPhone'] ?? false) ? '09xx.xxx.${profile['phone']!.substring(profile['phone']!.length - 3)}' : profile['phone']!, mono: true),
                    _kv('Ngày vào Đoàn', profile['joinDate']!),
                    const Divider(height: 16),
                    RichText(text: TextSpan(style: const TextStyle(fontSize: 12, color: Color(0xFF475569)), children: [
                      const TextSpan(text: 'Đơn vị: ', style: TextStyle(fontWeight: FontWeight.w700)),
                      TextSpan(text: profile['unit']!),
                    ])),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_city_rounded, size: 16, color: D.primary),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('12 Chi đoàn trực thuộc', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)))),
                        Pill('485 ĐV', fontSize: 10),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 160,
                      child: ListView.builder(
                        itemCount: branches.length,
                        itemBuilder: (c, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                            decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                Expanded(child: Text(branches[i].name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
                                Text('${branches[i].total} ĐV', style: const TextStyle(fontSize: 12, color: D.textMuted)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (activeTab == 'security') ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    const Row(children: [
                      Icon(Icons.lock_rounded, size: 16, color: D.primary),
                      SizedBox(width: 8),
                      Text('Thiết lập Bảo mật Hồ sơ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    ]),
                    for (final item in [
                      ('maskPhone', 'Ẩn một phần SĐT công khai', 'Bảo vệ thông tin cá nhân khi tra cứu'),
                      ('twoFactorAuth', 'Xác thực 2 lớp (OTP & GPS)', 'Ngăn điểm danh hộ và truy cập trái phép'),
                      ('encryptOffline', 'Mã hóa hàng đợi Ngoại tuyến', 'Bảo toàn dữ liệu lưu cục bộ khi mất mạng'),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.$2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                  Text(item.$3, style: const TextStyle(fontSize: 11, color: D.textMuted)),
                                ],
                              ),
                            ),
                            Switch(
                              value: state.securitySettings[item.$1] ?? false,
                              activeColor: D.primary,
                              onChanged: (v) => setSheet(() => state.updateSecuritySettings(item.$1, v)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.key_rounded, size: 16, color: D.primary),
                      SizedBox(width: 8),
                      Text('Ma trận Phân quyền (RBAC)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    ]),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Table(
                        defaultColumnWidth: const IntrinsicColumnWidth(),
                        border: TableBorder.all(color: D.border, width: 1),
                        children: [
                          const TableRow(decoration: BoxDecoration(color: D.grayBg), children: [
                            Padding(padding: EdgeInsets.all(6), child: Text('Chức năng', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700))),
                            Padding(padding: EdgeInsets.all(6), child: Text('ĐV', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700))),
                            Padding(padding: EdgeInsets.all(6), child: Text('BT', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700))),
                            Padding(padding: EdgeInsets.all(6), child: Text('Xã', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700))),
                          ]),
                          ...rolePermissions.map((p) => TableRow(children: [
                                Padding(padding: const EdgeInsets.all(6), child: Text(p['feature'] as String, style: const TextStyle(fontSize: 10, color: Color(0xFF334155)))),
                                _permCell(p['member'] == true, false),
                                _permCell(p['secretary'] == true, true),
                                _permCell(p['ward_officer'] == true, true),
                              ])),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (activeTab == 'logs') ...[
              Row(
                children: [
                  const Icon(Icons.history_rounded, size: 16, color: D.primary),
                  const SizedBox(width: 6),
                  const Expanded(child: Text('Lịch sử thao tác gần đây', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)))),
                  Text('${state.auditLogs.length} bản ghi', style: const TextStyle(fontSize: 12, color: D.textMuted)),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.auditLogs.length,
                  itemBuilder: (c, i) {
                    final log = state.auditLogs[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(log.actor, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: D.primary))),
                              Text(log.time, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                            ],
                          ),
                          Text(log.action, style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
            if (activeTab == 'backup') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Row(children: [
                      const Icon(Icons.backup_rounded, size: 16, color: D.primary),
                      const SizedBox(width: 8),
                      const Text('Sao lưu & Khôi phục Dữ liệu', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    ]),
                    const SizedBox(height: 8),
                    const Text('Vòng 1: dữ liệu mock chỉ lưu trong bộ nhớ phiên. Nhấn "Sao lưu" để xem chuỗi JSON trạng thái hiện tại.', style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      'Tải bản sao lưu (.json)',
                      icon: Icons.download_rounded,
                      height: 44,
                      fontSize: 13,
                      onPressed: () {
                        final json = _exportBackupJson(state);
                        debugPrint(json.substring(0, json.length.clamp(0, 400)));
                        state.showToast('Đã sao lưu dữ liệu phiên (mock JSON)!');
                      },
                    ),
                    if (restoreFeedback != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: D.greenLight, borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          const Icon(Icons.check_circle_rounded, size: 15, color: D.greenDark),
                          const SizedBox(width: 8),
                          Expanded(child: Text(restoreFeedback!, style: const TextStyle(fontSize: 12, color: Color(0xFF065F46)))),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () {
                        state.resetAppData();
                        state.showToast('Đã khôi phục dữ liệu gốc ban đầu!');
                        Navigator.pop(ctx);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFBE123C),
                        backgroundColor: D.roseLight,
                        minimumSize: const Size.fromHeight(40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Đặt lại dữ liệu gốc', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  String _exportBackupJson(AppState state) {
    final sb = StringBuffer();
    sb.writeln('{"app":"DoanVienSoDongNai","exportedAt":"2026-11-28T09:00:00","members":${state.members.length},"scanned":${state.scannedCount},"vouchers":${state.vouchers.length}}');
    return sb.toString();
  }

  Widget _permCell(bool ok, bool strong) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Text(ok ? '✓' : '—', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: strong ? FontWeight.w800 : FontWeight.w400, color: ok && strong ? D.primary : const Color(0xFF334155))),
    );
  }

  Widget _kv(String k, String v, {bool mono = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(k, style: const TextStyle(fontSize: 12, color: D.textMuted)),
          const Spacer(),
          Text(v, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: valueColor ?? const Color(0xFF0F172A), fontFamily: mono ? 'monospace' : null)),
        ],
      ),
    );
  }

  Widget _tab(BuildContext ctx, String id, String label) {
    final active = activeTab == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => activeTab = id),
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 3)] : null,
          ),
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? D.primary : const Color(0xFF475569))),
        ),
      ),
    );
  }
}

// ===== Khung chung của bottom sheet =====
class _SheetScaffold extends StatelessWidget {
  final Widget child;
  const _SheetScaffold({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: child,
      ),
    );
  }
}

Widget sheetHeader(BuildContext context, {required IconData icon, required String title, required String subtitle}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(4)),
          ),
        ),
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: D.primary, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: D.textMuted)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
