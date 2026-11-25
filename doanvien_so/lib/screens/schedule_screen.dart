import '../data/mock_data.dart';
import 'package:flutter/material.dart';
import '../state/app_state.dart';

import '../ui.dart';

class MakeupSessionScreen extends StatefulWidget {
  final AppState state;
  final AppRole currentRole;
  final void Function(String) onNavigate;
  const MakeupSessionScreen({super.key, required this.state, required this.currentRole, required this.onNavigate});

  @override
  State<MakeupSessionScreen> createState() => _MakeupSessionScreenState();
}

class _MakeupSessionScreenState extends State<MakeupSessionScreen> {
  String selectedDay = 'all';
  String activeTab = 'timetable'; // timetable | catalog | requests | manage | wardcal | launch | approvals

  final absenceReasonCtrl = TextEditingController(text: 'Lịch công tác đột xuất / Trùng giờ làm việc');
  final absenceProofCtrl = TextEditingController(text: 'Xác nhận của đơn vị công tác');
  final createTitleCtrl = TextEditingController();
  final createTimeCtrl = TextEditingController(text: '08:00 - 10:30');
  final createRoomCtrl = TextEditingController(text: 'Nhà văn hóa Khu phố 5');
  String createDateStr = '29/11/2026';

  // Phát động hoạt động cấp phường (wardOfficer)
  final launchTitleCtrl = TextEditingController();
  final launchDateCtrl = TextEditingController(text: '01/12/2026');
  final launchTimeCtrl = TextEditingController(text: '08:00 - 11:00');
  final launchPointsCtrl = TextEditingController(text: '+25');
  String launchType = 'Sự kiện Đoàn';

  // Quiz
  bool quizOpen = false;
  Map<int, int> userAnswers = {};
  bool quizSubmitted = false;
  int quizScore = 0;

  @override
  void dispose() {
    absenceReasonCtrl.dispose();
    absenceProofCtrl.dispose();
    createTitleCtrl.dispose();
    createTimeCtrl.dispose();
    createRoomCtrl.dispose();
    launchTitleCtrl.dispose();
    launchDateCtrl.dispose();
    launchTimeCtrl.dispose();
    launchPointsCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDeco(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
      labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
    );
  }

  /// Cán bộ phường: phát động hoạt động → vào danh mục toàn chi đoàn
  void _launchWardActivity() {
    final title = launchTitleCtrl.text.trim();
    if (title.isEmpty) {
      widget.state.showToast('Vui lòng nhập tên hoạt động!');
      return;
    }
    final points = launchPointsCtrl.text.trim().startsWith('+') ? launchPointsCtrl.text.trim() : '+${launchPointsCtrl.text.trim()}';
    widget.state.createScheduleCatalogItem({
      'title': title,
      'category': launchType,
      'dateStr': launchDateCtrl.text.trim(),
      'dayOfWeek': 'CN',
      'timeSlot': launchTimeCtrl.text.trim(),
      'room': 'Theo phân công của Đoàn Phường',
      'organizer': 'Đoàn Phường Trấn Biên',
      'pointsValue': 25,
      'format': 'Trực tiếp • Điểm danh QR',
    });
    widget.state.showToast('Đã phát động "$title" đến 12 chi đoàn!');
    launchTitleCtrl.clear();
    setState(() {});
  }

  bool get isOfficer => widget.currentRole != AppRole.member;

  @override
  void initState() {
    super.initState();
    // Mỗi vai trò mở đúng không gian của mình
    activeTab = switch (widget.currentRole) {
      AppRole.wardOfficer => 'wardcal',
      AppRole.secretary => 'timetable',
      _ => 'timetable',
    };
  }

  /// Cấu hình tab theo vai trò — mỗi vai trò có bộ tab riêng hoàn toàn
  List<(String, String)> get _roleTabs {
    final state = widget.state;
    final pending = state.makeupRequests.where((r) => r.status == 'pending').length;
    final pendingBranches = (state.wardDataByMonth['11']?.branchesRank ?? []).where((b) => b.status == 'pending').length;
    return switch (widget.currentRole) {
      AppRole.secretary => [
          ('timetable', 'Lịch chi đoàn'),
          ('requests', 'Duyệt đơn ($pending)'),
          ('manage', 'Quản lý lịch'),
        ],
      AppRole.wardOfficer => [
          ('wardcal', 'Lịch cấp phường'),
          ('approvals', 'Duyệt chi đoàn ($pendingBranches)'),
          ('launch', 'Phát động'),
        ],
      _ => [
          ('timetable', 'Lịch của tôi (${widget.state.mySchedule.length})'),
          ('catalog', 'Đăng ký (${widget.state.scheduleCatalog.length})'),
          ('requests', 'Đơn của tôi'),
        ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final member = state.currentMember;
    final pendingRequests = state.makeupRequests.where((r) => r.status == 'pending').length;

    final filteredSchedule = state.mySchedule.where((item) => selectedDay == 'all' ? true : item.dateStr == selectedDay).toList()
      ..sort((a, b) => a.dateStr.compareTo(b.dateStr));
    final filteredCatalog = state.scheduleCatalog.where((item) => selectedDay == 'all' ? true : item.dateStr == selectedDay).toList();

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header tuần
              AppCard(
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Pill('Tuần 25/11 — 30/11/2026', fontSize: 10),
                              const SizedBox(height: 8),
                              const Text('Lịch hoạt động cá nhân', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                              Text('${state.mySchedule.length} sự kiện đã đăng ký • Đồng bộ từ Bảng tin & Chi đoàn', style: const TextStyle(fontSize: 12, color: D.textMuted)),
                            ],
                          ),
                        ),
                        isOfficer
                            ? GestureDetector(
                                onTap: () => _showCreateScheduleSheet(),
                                child: Container(
                                  height: 36,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(color: D.primary, borderRadius: BorderRadius.circular(12)),
                                  child: const Row(children: [
                                    Icon(Icons.add_circle_outline_rounded, size: 15, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text('Tạo lịch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                                  ]),
                                ),
                              )
                            : GestureDetector(
                                onTap: _showAbsenceSheet,
                                child: Container(
                                  height: 36,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(color: D.light, borderRadius: BorderRadius.circular(12)),
                                  child: const Row(children: [
                                    Icon(Icons.post_add_rounded, size: 15, color: D.primary),
                                    SizedBox(width: 4),
                                    Text('Báo vắng', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: D.primary)),
                                  ]),
                                ),
                              ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 7 ngày
                    Row(
                      children: [
                        for (final day in scheduleWeekDays)
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => selectedDay = day['key']!),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 7),
                                decoration: BoxDecoration(
                                  color: selectedDay == day['key'] ? D.primary : D.grayBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Text(day['label']!, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: selectedDay == day['key'] ? Colors.white70 : const Color(0xFF64748B))),
                                    Text(day['dayNum']!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: selectedDay == day['key'] ? Colors.white : const Color(0xFF1E293B))),
                                    Container(
                                      width: 6,
                                      height: 6,
                                      margin: const EdgeInsets.only(top: 3),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: day['key'] == 'all'
                                            ? (state.mySchedule.isNotEmpty ? (selectedDay == day['key'] ? Colors.white : D.primary) : Colors.transparent)
                                            : (state.mySchedule.any((s) => s.dateStr == day['key']) ? (selectedDay == day['key'] ? Colors.white : D.primary) : Colors.transparent),
                                      ),
                                    ),
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
              // Băng định vị không gian theo vai trò
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: switch (widget.currentRole) {
                    AppRole.secretary => const LinearGradient(colors: [Color(0xFF161891), Color(0xFF0E1068)]),
                    AppRole.wardOfficer => const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF134E4A)]),
                    _ => const LinearGradient(colors: [Color(0xFF0369A1), Color(0xFF075985)]),
                  },
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.currentRole.spaceTitle, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.2)),
                  const SizedBox(height: 3),
                  Text(widget.currentRole.spaceDesc, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.85))),
                ]),
              ),
              const SizedBox(height: 14),
              // Segmented tab — riêng cho từng vai trò
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: const Color(0xFFCBD5E1).withValues(alpha: 0.7), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [for (final (id, label) in _roleTabs) Expanded(child: _seg(id, label))],
                ),
              ),
              const SizedBox(height: 14),

              if (activeTab == 'timetable') ...[
                if (filteredSchedule.isEmpty)
                  AppCard(
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.calendar_month_rounded, size: 32, color: Color(0xFFA5B4FC)),
                          const SizedBox(height: 8),
                          const Text('Không có lịch hoạt động trong ngày này', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                          const Text('Chọn "Tất cả" hoặc chuyển sang mục "Đăng ký" để thêm sự kiện vào lịch cá nhân.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: D.textMuted)),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () => setState(() => activeTab = 'catalog'),
                            child: Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: D.light, borderRadius: BorderRadius.circular(12)),
                              child: const Text('Khám phá hoạt động', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: D.primary)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...filteredSchedule.map((item) => _scheduleCard(context, state, item)),
              ],

              if (activeTab == 'catalog' && widget.currentRole == AppRole.member) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      const Expanded(child: Text('Lịch sinh hoạt, Chuyên đề & Sự kiện mở đăng ký', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)))),
                      Text('${filteredCatalog.length} mục', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: D.primary)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ...filteredCatalog.map((item) {
                  final isEnrolled = state.mySchedule.any((s) => s.id == item.id || s.title == item.title);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: D.cardBorder),
                      boxShadow: [BoxShadow(color: const Color(0x090F172A), blurRadius: 10, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Pill(item.category, fontSize: 10),
                                      const SizedBox(width: 6),
                                      Text(item.points, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: D.greenDark)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(item.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), height: 1.3)),
                                ],
                              ),
                            ),
                            Pill(item.seatsLeft == 999 ? 'Không giới hạn' : 'Còn ${item.seatsLeft} suất', bg: D.grayBg, fg: const Color(0xFF475569), fontSize: 10),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _iconRow(Icons.schedule_rounded, '${item.dayOfWeek}, ${item.dateStr} • ${item.timeSlot}'),
                        _iconRow(Icons.place_rounded, '${item.room} (${item.organizer})'),
                        const Divider(height: 20),
                        Row(
                          children: [
                            Expanded(child: Text(item.format, style: const TextStyle(fontSize: 12, color: D.textMuted))),
                            GestureDetector(
                              onTap: isEnrolled
                                  ? null
                                  : () {
                                      final res = state.enrollScheduleItem(item);
                                      if (res['ok'] == true) {
                                        state.showToast('Đã thêm "${item.title}" vào Lịch cá nhân (${item.dateStr})!');
                                      } else {
                                        state.showToast('Hoạt động này đã có trong Lịch cá nhân của bạn.');
                                      }
                                    },
                              child: Container(
                                height: 40,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: isEnrolled ? D.greenLight : D.primary,
                                  borderRadius: BorderRadius.circular(12),
                                  border: isEnrolled ? Border.all(color: const Color(0xFFA7F3D0)) : Border.all(color: D.primary),
                                ),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(isEnrolled ? Icons.check_rounded : Icons.add_circle_outline_rounded, size: 15, color: isEnrolled ? D.greenDark : Colors.white),
                                  const SizedBox(width: 5),
                                  Text(isEnrolled ? 'Đã có trong Lịch' : 'Đăng ký vào Lịch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isEnrolled ? D.greenDark : Colors.white)),
                                ]),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],

              if (activeTab == 'requests') ...[
                if (!isOfficer)
                  PrimaryButton('Gửi đơn xin phép / Đổi lịch trực tuyến', icon: Icons.post_add_rounded, height: 44, onPressed: _showAbsenceSheet),
                if (isOfficer)
                  AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        RichText(text: TextSpan(style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)), children: [
                          const TextSpan(text: 'Đang chờ phê duyệt: '),
                          TextSpan(text: '$pendingRequests đơn', style: const TextStyle(fontWeight: FontWeight.w800, color: D.primary)),
                        ])),
                        const Spacer(),
                        GestureDetector(
                          onTap: _showCreateScheduleSheet,
                          child: const Text('+ Thêm lịch mới', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: D.primary)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                ...state.makeupRequests
                    .where((req) => widget.currentRole == AppRole.member ? req.memberId == state.currentMember.id : true)
                    .map((req) => _requestCard(state, req)),
                if (widget.currentRole == AppRole.member && state.makeupRequests.every((r) => r.memberId != state.currentMember.id))
                  AppCard(
                    child: Center(child: Text('Bạn chưa có đơn xin phép / sinh hoạt bù nào.\nBấm nút phía trên để gửi đơn.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: D.textMuted))),
                  ),
              ],

              // ====== BÍ THƯ: Quản lý lịch chi đoàn (tạo / đóng ĐK / xóa) ======
              if (activeTab == 'manage') ...[
                PrimaryButton('+ Tạo buổi sinh hoạt / hoạt động mới', icon: Icons.add_rounded, height: 46, onPressed: _showCreateScheduleSheet),
                const SizedBox(height: 14),
                Row(children: [
                  const Expanded(child: Text('Buổi do Chi đoàn KP5 tổ chức', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)))),
                  Text('Quyền: Tạo • Đóng ĐK • Xóa', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: D.primary)),
                ]),
                const SizedBox(height: 10),
                ...state.scheduleCatalog.where((item) => item.organizer.contains('KP5')).map((item) => _manageCard(state, item)),
                if (!state.scheduleCatalog.any((item) => item.organizer.contains('KP5')))
                  AppCard(
                    child: Center(child: Column(children: [
                      const Icon(Icons.event_note_rounded, size: 30, color: Color(0xFFA5B4FC)),
                      const SizedBox(height: 8),
                      const Text('Chưa có buổi sinh hoạt nào do chi đoàn tổ chức', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                      const Text('Bấm "Tạo buổi sinh hoạt" phía trên để lên lịch — đoàn viên sẽ thấy ngay trong mục Đăng ký.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: D.textMuted)),
                    ])),
                  ),
              ],

              // ====== CÁN BỘ PHƯỜNG: Lịch cấp phường (chỉ xem tổng hợp) ======
              if (activeTab == 'wardcal') ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF0F766E), borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    const Icon(Icons.map_rounded, size: 18, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(child: Text('12 chi đoàn trực thuộc • ${state.scheduleCatalog.length} hoạt động trong danh mục', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white))),
                  ]),
                ),
                const SizedBox(height: 12),
                ...state.scheduleCatalog.map((item) => _scheduleCard(context, state, item, readOnly: true)),
              ],

              // ====== CÁN BỘ PHƯỜNG: Duyệt báo cáo / kế hoạch chi đoàn ======
              if (activeTab == 'approvals') ...[
                Row(children: [
                  const Expanded(child: Text('Tiến độ nộp báo cáo kỳ 11/2026', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)))),
                  Pill('${(state.wardDataByMonth['11']?.branchesRank ?? []).where((b) => b.status == 'submitted').length}/12 đã nộp', bg: D.light, fontSize: 10.5),
                ]),
                const SizedBox(height: 10),
                ...(state.wardDataByMonth['11']?.branchesRank ?? []).where((b) => b.status == 'pending').map((b) => _branchApprovalCard(state, b, pending: true)),
                ...(state.wardDataByMonth['11']?.branchesRank ?? []).where((b) => b.status == 'submitted' && b.id == 'kp5').map((b) => _branchApprovalCard(state, b, pending: false)),
                if ((state.wardDataByMonth['11']?.branchesRank ?? []).every((b) => b.status == 'submitted'))
                  AppCard(
                    child: Center(child: Column(children: [
                      const Icon(Icons.verified_rounded, size: 30, color: D.greenDark),
                      const SizedBox(height: 8),
                      const Text('Tất cả 12/12 chi đoàn đã nộp báo cáo', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: D.greenDark)),
                      const Text('Có thể xuất báo cáo định kỳ toàn phường tại mục Báo cáo.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: D.textMuted)),
                    ])),
                  ),
              ],

              // ====== CÁN BỘ PHƯỜNG: Phát động hoạt động toàn phường ======
              if (activeTab == 'launch') ...[
                AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.campaign_rounded, size: 18, color: Color(0xFF0F766E)),
                      const SizedBox(width: 8),
                      const Text('Phát động hoạt động toàn Phường', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    ]),
                    const SizedBox(height: 4),
                    Text('Hoạt động sẽ xuất hiện trong danh mục Đăng ký của toàn bộ 12 chi đoàn, 485 đoàn viên.', style: const TextStyle(fontSize: 11, color: D.textMuted)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: launchTitleCtrl,
                      decoration: _inputDeco('Tên hoạt động', 'VD: Ngày hội việc làm KCN Đồng Nai'),
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: TextField(controller: launchDateCtrl, decoration: _inputDeco('Ngày', '01/12/2026'))),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: launchTimeCtrl, decoration: _inputDeco('Giờ', '08:00 - 11:00'))),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: TextField(controller: launchPointsCtrl, decoration: _inputDeco('Điểm rèn luyện', '+25'))),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: launchType,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(value: 'Sự kiện Đoàn', child: Text('Sự kiện Đoàn', style: TextStyle(fontSize: 12.5))),
                                DropdownMenuItem(value: 'Chuyên đề', child: Text('Chuyên đề', style: TextStyle(fontSize: 12.5))),
                                DropdownMenuItem(value: 'Tình nguyện', child: Text('Tình nguyện', style: TextStyle(fontSize: 12.5))),
                              ],
                              onChanged: (v) => setState(() => launchType = v!),
                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF0F172A)),
                            ),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    PrimaryButton('Phát động đến 12 chi đoàn', icon: Icons.campaign_rounded, height: 46, onPressed: _launchWardActivity),
                  ]),
                ),
                const SizedBox(height: 14),
                const Text('Đã phát động gần đây', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                const SizedBox(height: 10),
                ...state.scheduleCatalog.where((item) => item.organizer.contains('Phường')).map((item) => _scheduleCard(context, state, item, readOnly: true)),
                if (!state.scheduleCatalog.any((item) => item.organizer.contains('Phường')))
                  AppCard(child: Center(child: Text('Chưa phát động hoạt động nào ở cấp phường.', style: TextStyle(fontSize: 12.5, color: D.textMuted)))),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
        // Quiz modal
        if (quizOpen) _quizSheet(state, member),
      ],
    );
  }

  Widget _scheduleCard(BuildContext context, AppState state, ScheduleItem item, {bool readOnly = false}) {
    final startTime = item.timeSlot.split('-').first.trim();
    final endTime = item.timeSlot.split('-').length > 1 ? item.timeSlot.split('-')[1].trim() : '10:00';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: D.cardBorder),
        boxShadow: [BoxShadow(color: const Color(0x090F172A), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(startTime, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: D.primary)),
                Text(endTime, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(4)),
                  child: Text('${item.dayOfWeek} ${item.dateStr.substring(0, 5)}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                ),
              ],
            ),
          ),
          Container(
            width: 4,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: D.primary, borderRadius: BorderRadius.circular(4)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Pill(item.category, bg: D.light, fg: D.primary, fontSize: 10, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
                    const Spacer(),
                    Text(item.points, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: D.greenDark)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(item.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), height: 1.3)),
                const SizedBox(height: 6),
                _iconRow(Icons.place_rounded, item.room),
                _iconRow(Icons.corporate_fare_rounded, '${item.organizer} • ${item.format}'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: readOnly
                          ? null
                          : () {
                              if (item.isELearning) {
                                setState(() {
                                  quizOpen = true;
                                  quizSubmitted = false;
                                  userAnswers = {};
                                  quizScore = 0;
                                });
                              } else {
                                widget.onNavigate(widget.currentRole.canIssueQR ? 'create_qr' : 'scan_qr');
                              }
                            },
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(color: readOnly ? D.light : D.primary, borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          Icon(item.isELearning ? Icons.menu_book_rounded : Icons.qr_code_2, size: 14, color: readOnly ? D.primary : Colors.white),
                          const SizedBox(width: 5),
                          Text(item.isELearning
                              ? 'Tham gia trực tuyến'
                              : readOnly
                                  ? 'Xem chi tiết'
                                  : widget.currentRole.canIssueQR
                                      ? 'Mở QR điểm danh'
                                      : 'Điểm danh QR', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: readOnly ? D.primary : Colors.white)),
                        ]),
                      ),
                    ),
                    if (!item.mandatory && widget.currentRole == AppRole.member) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          state.unenrollScheduleItem(item.id);
                          state.showToast('Đã hủy đăng ký "${item.title}" khỏi Lịch cá nhân.');
                        },
                        child: Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(12)),
                          child: const Row(children: [
                            Icon(Icons.delete_outline_rounded, size: 14, color: Color(0xFF64748B)),
                            SizedBox(width: 4),
                            Text('Hủy lịch', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                          ]),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _requestCard(AppState state, MakeupRequest req) {
    final (bg, fg, label) = switch (req.status) {
      'approved' => (D.greenLight, D.greenDark, 'Đã duyệt'),
      'clarify_requested' => (D.roseLight, const Color(0xFFBE123C), 'Cần bổ sung'),
      _ => (D.light, D.primary, 'Chờ duyệt'),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: D.cardBorder),
        boxShadow: [BoxShadow(color: const Color(0x090F172A), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(req.memberName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                    Row(children: [
                      const Icon(Icons.work_outline_rounded, size: 13, color: D.textMuted),
                      const SizedBox(width: 5),
                      Expanded(child: Text(req.workplace, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: D.textMuted))),
                    ]),
                  ],
                ),
              ),
              Pill(label, bg: bg, fg: fg, fontSize: 10),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(TextSpan(style: const TextStyle(fontSize: 12, color: Color(0xFF334155)), children: [
                  const TextSpan(text: 'Nội dung đăng ký: ', style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: req.registeredMakeup),
                ])),
                Text.rich(TextSpan(style: const TextStyle(fontSize: 12, color: Color(0xFF334155)), children: [
                  const TextSpan(text: 'Lý do: ', style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: req.reason),
                ])),
                Row(children: [
                  const Icon(Icons.verified_user_rounded, size: 13, color: D.greenDark),
                  const SizedBox(width: 5),
                  Expanded(child: Text(req.proof, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: D.greenDark))),
                ]),
              ],
            ),
          ),
          if (isOfficer && req.status == 'pending') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton('Phê duyệt', icon: Icons.check_rounded, height: 40, fontSize: 12, onPressed: () {
                    state.handleMakeupRequestAction(req.id, 'approve');
                    state.showToast('Đã phê duyệt đơn của Đ/c ${req.memberName}!');
                  }),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    state.handleMakeupRequestAction(req.id, 'clarify');
                    state.showToast('Đã gửi yêu cầu bổ sung tới Đ/c ${req.memberName}.');
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: const Color(0xFF334155),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Bổ sung', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showAbsenceSheet() {
    final state = widget.state;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14), decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(4)))),
              Row(
                children: [
                  const Expanded(child: Text('Đơn Xin phép & Đổi lịch', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)))),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(12)),
                child: Text.rich(TextSpan(style: const TextStyle(fontSize: 12, color: Color(0xFF334155)), children: [
                  const TextSpan(text: 'Buổi xin phép: ', style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: state.activeSession.title),
                ])),
              ),
              const SizedBox(height: 12),
              DTextField(controller: absenceReasonCtrl, label: 'Lý do *', maxLines: 2),
              const SizedBox(height: 12),
              DTextField(controller: absenceProofCtrl, label: 'Minh chứng đính kèm'),
              const SizedBox(height: 16),
              PrimaryButton('Gửi đơn xét duyệt', onPressed: () {
                state.submitAbsenceRequest(sessionTitle: state.activeSession.title, reason: absenceReasonCtrl.text, proof: absenceProofCtrl.text, preferredMakeup: 'Chuyển sang tham gia chuyên đề trực tuyến');
                Navigator.pop(ctx);
                state.showToast('Đã gửi đơn xin phép thành công!');
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateScheduleSheet() {
    final state = widget.state;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          child: StatefulBuilder(
            builder: (ctx, setSheet) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14), decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(4)))),
                Row(
                  children: [
                    const Expanded(child: Text('Tạo Lịch Sinh hoạt / Hoạt động', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)))),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                DTextField(controller: createTitleCtrl, label: 'Tên sự kiện / hoạt động *', hint: 'VD: Tập huấn Kỹ năng Truyền thông Số'),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ngày diễn ra', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: D.border)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: createDateStr,
                                isExpanded: true,
                                items: scheduleWeekDays.where((d) => d['key'] != 'all').map((d) => DropdownMenuItem(value: d['key'], child: Text('${d['label']} — ${d['key']}', style: const TextStyle(fontSize: 12.5)))).toList(),
                                onChanged: (v) => setSheet(() => createDateStr = v ?? createDateStr),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: DTextField(controller: createTimeCtrl, label: 'Khung giờ')),
                  ],
                ),
                const SizedBox(height: 12),
                DTextField(controller: createRoomCtrl, label: 'Địa điểm tổ chức'),
                const SizedBox(height: 16),
                PrimaryButton('Thêm vào danh sách đăng ký Lịch', onPressed: () {
                  if (createTitleCtrl.text.trim().isEmpty) return;
                  final dayEntry = scheduleWeekDays.firstWhere((d) => d['key'] == createDateStr, orElse: () => {'key': '', 'label': 'CN', 'dayNum': ''});
                  state.createScheduleCatalogItem({
                    'title': createTitleCtrl.text,
                    'category': 'Sinh hoạt',
                    'dateStr': createDateStr,
                    'dayOfWeek': dayEntry['label'],
                    'timeSlot': createTimeCtrl.text,
                    'room': createRoomCtrl.text,
                    'pointsValue': 20,
                    'autoEnroll': true,
                    'organizer': widget.currentRole == AppRole.wardOfficer ? 'Đoàn Phường Trấn Biên' : 'BCH Chi đoàn Khu phố 5',
                  });
                  Navigator.pop(ctx);
                  state.showToast('Đã thêm hoạt động mới vào danh sách đăng ký Lịch!');
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quizSheet(AppState state, Member member) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {},
        child: Container(
          color: const Color(0xFF020617).withValues(alpha: 0.6),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                child: StatefulBuilder(
                  builder: (ctx, setSheet) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14), decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(4)))),
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(color: D.light, borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.menu_book_rounded, size: 18, color: D.primary),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Chuyên đề trực tuyến: Chuyển đổi số', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                const Text('Đúng tối thiểu 2/3 câu để hoàn thành', style: TextStyle(fontSize: 12, color: D.textMuted)),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => quizOpen = false),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                              child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (!quizSubmitted) ...[
                        ...quizQuestions.asMap().entries.expand((e) {
                          final q = e.value;
                          final qIdx = e.key;
                          return [
                            Text.rich(TextSpan(style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), height: 1.35), children: [
                              TextSpan(text: 'Câu ${qIdx + 1}: ', style: const TextStyle(fontWeight: FontWeight.w800, color: D.primary)),
                              TextSpan(text: q.question, style: const TextStyle(fontWeight: FontWeight.w700)),
                            ])),
                            const SizedBox(height: 8),
                            ...q.options.asMap().entries.map((o) {
                              final isSelected = userAnswers[q.id] == o.key;
                              return GestureDetector(
                                onTap: () => setSheet(() => userAnswers[q.id] = o.key),
                                child: Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? D.light : D.grayBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: isSelected ? D.primary : D.border),
                                  ),
                                  child: Text(o.value, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? D.primary : const Color(0xFF334155))),
                                ),
                              );
                            }),
                            const SizedBox(height: 12),
                          ];
                        }),
                        PrimaryButton(
                          'Nộp bài & Chấm điểm',
                          icon: Icons.workspace_premium_rounded,
                          onPressed: userAnswers.length < quizQuestions.length
                              ? null
                              : () {
                                  int score = 0;
                                  for (final q in quizQuestions) {
                                    if (userAnswers[q.id] == q.correctAnswer) score++;
                                  }
                                  setSheet(() {
                                    quizScore = score;
                                    quizSubmitted = true;
                                  });
                                  if (score >= 2) {
                                    final res = state.completeELearningQuiz(score, quizQuestions.length);
                                    state.showToast(res['pointsAwarded'] == true ? 'Đạt $score/3 câu! Đã cấp chứng nhận chuyên đề & cộng +10 điểm.' : 'Đạt $score/3 câu!');
                                  }
                                },
                        ),
                      ] else if (quizScore >= 2) ...[
                        Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(color: D.greenLight, borderRadius: BorderRadius.circular(16)),
                              child: const Icon(Icons.check_circle_rounded, size: 30, color: D.greenDark),
                            ),
                            const SizedBox(height: 10),
                            Pill('Đạt $quizScore/3 câu', bg: D.greenLight, fg: D.greenDark, fontSize: 11, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
                            const SizedBox(height: 8),
                            const Text('Hoàn thành chuyên đề!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: D.primary.withValues(alpha: 0.2))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Center(child: Text('THÀNH ĐOÀN ĐỒNG NAI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: D.primary))),
                              const Center(child: Text('CHỨNG NHẬN HOÀN THÀNH CHUYÊN ĐỀ', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)))),
                              const Divider(height: 18),
                              Text.rich(TextSpan(style: const TextStyle(fontSize: 12, color: Color(0xFF334155)), children: [
                                const TextSpan(text: 'Đoàn viên: '),
                                TextSpan(text: member.name, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                              ])),
                              Text.rich(TextSpan(style: const TextStyle(fontSize: 12, color: Color(0xFF334155)), children: [
                                const TextSpan(text: 'Điểm cộng: '),
                                const TextSpan(text: '+10 điểm', style: TextStyle(fontWeight: FontWeight.w700, color: D.primary)),
                              ])),
                              Text.rich(TextSpan(style: const TextStyle(fontSize: 12, color: Color(0xFF334155)), children: [
                                const TextSpan(text: 'Mã xác thực: '),
                                const TextSpan(text: 'DN-EL-2026-8831', style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'monospace', color: D.primary)),
                              ])),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        PrimaryButton('Hoàn tất', onPressed: () => setState(() => quizOpen = false)),
                      ] else ...[
                        Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(color: D.roseLight, borderRadius: BorderRadius.circular(16)),
                              child: const Icon(Icons.warning_amber_rounded, size: 30, color: const Color(0xFFDC2626)),
                            ),
                            const SizedBox(height: 10),
                            Text('Chưa đạt ($quizScore/3 câu)', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                            const Text('Cần đúng tối thiểu 2/3 câu hỏi để hoàn thành chuyên đề.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: PrimaryButton('Làm lại', icon: Icons.refresh_rounded, height: 44, fontSize: 13, onPressed: () => setSheet(() {
                                quizSubmitted = false;
                                userAnswers = {};
                                quizScore = 0;
                              })),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => setState(() => quizOpen = false),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  foregroundColor: const Color(0xFF334155),
                                  side: BorderSide.none,
                                  minimumSize: const Size.fromHeight(44),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Đóng', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  /// Bí thư: thẻ quản lý buổi sinh hoạt — Đóng đăng ký / Xóa / Phát QR
  Widget _manageCard(AppState state, ScheduleItem item) {
    final closed = item.seatsLeft == 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: D.cardBorder), boxShadow: [BoxShadow(color: const Color(0x090F172A), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(item.title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)))),
          Pill(closed ? 'ĐÃ ĐÓNG ĐK' : 'Còn ${item.seatsLeft} suất', bg: closed ? const Color(0xFFFEE2E2) : D.greenLight, fg: closed ? const Color(0xFFDC2626) : D.greenDark, fontSize: 9.5),
        ]),
        const SizedBox(height: 6),
        _iconRow(Icons.schedule_rounded, '${item.dayOfWeek}, ${item.dateStr} • ${item.timeSlot}'),
        _iconRow(Icons.place_rounded, '${item.room} • ${item.points}'),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: () => widget.onNavigate('create_qr'),
              child: Container(height: 38, alignment: Alignment.center, decoration: BoxDecoration(color: D.primary, borderRadius: BorderRadius.circular(11)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.qr_code_2, size: 15, color: Colors.white), SizedBox(width: 5), Text('Phát QR', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white))])),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: closed
                ? null
                : () {
                    state.closeScheduleRegistration(item.id);
                    state.showToast('Đã đóng đăng ký "${item.title}". Đoàn viên không thể đăng ký thêm.');
                  },
            child: Container(height: 38, padding: const EdgeInsets.symmetric(horizontal: 12), alignment: Alignment.center, decoration: BoxDecoration(color: closed ? const Color(0xFFF1F5F9) : const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(11)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.lock_clock_rounded, size: 15, color: closed ? const Color(0xFF94A3B8) : const Color(0xFFB45309)), const SizedBox(width: 5), Text('Đóng ĐK', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: closed ? const Color(0xFF94A3B8) : const Color(0xFFB45309)))])),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              state.removeScheduleItem(item.id);
              state.showToast('Đã xóa "${item.title}" khỏi lịch chi đoàn.');
            },
            child: Container(height: 38, width: 44, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(11)), child: Icon(Icons.delete_outline_rounded, size: 16, color: const Color(0xFFDC2626))),
          ),
        ]),
      ]),
    );
  }

  /// Cán bộ phường: thẻ duyệt báo cáo chi đoàn
  Widget _branchApprovalCard(AppState state, dynamic b, {required bool pending}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: pending ? const Color(0xFFFDE68A) : D.cardBorder, width: pending ? 1.5 : 1), boxShadow: [BoxShadow(color: const Color(0x090F172A), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(b.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)))),
          Pill(pending ? 'CHỜ DUYỆT' : 'ĐÃ DUYỆT', bg: pending ? const Color(0xFFFEF3C7) : D.greenLight, fg: pending ? const Color(0xFFB45309) : D.greenDark, fontSize: 9.5),
        ]),
        const SizedBox(height: 5),
        Text('${b.secretary} • ${b.attended}/${b.total} ĐV tham dự • Tỷ lệ ${b.rate.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
        if (pending) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  state.approveBranchReport(b.id);
                  state.showToast('Đã phê duyệt báo cáo của ${b.name}.');
                },
                child: Container(height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: D.primary, borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.task_alt_rounded, size: 16, color: Colors.white), SizedBox(width: 6), Text('Phê duyệt báo cáo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white))])),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                state.remindBranchReport('11', b.id);
                state.showToast('Đã gửi nhắc nộp báo cáo qua Zalo đến ${b.name}.');
              },
              child: Container(height: 40, padding: const EdgeInsets.symmetric(horizontal: 14), alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(12)), child: Row(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.notifications_active_rounded, size: 15, color: Color(0xFFB45309)), SizedBox(width: 5), Text('Nhắc', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFB45309)))])),
            ),
          ]),
        ],
      ]),
    );
  }

  Widget _seg(String id, String label) {
    final active = activeTab == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => activeTab = id),
        child: Container(
          height: 40,
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
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(children: [
        Icon(icon, size: 14, color: D.primary),
        const SizedBox(width: 6),
        Expanded(child: Text(text, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF475569)))),
      ]),
    );
  }
}
