import '../data/mock_data.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../ui.dart';


class CreateSessionQrScreen extends StatefulWidget {
  final AppState state;
  final VoidCallback onBack;
  const CreateSessionQrScreen({super.key, required this.state, required this.onBack});

  @override
  State<CreateSessionQrScreen> createState() => _CreateSessionQrScreenState();
}

class _CreateSessionQrScreenState extends State<CreateSessionQrScreen> {
  String activeTab = 'qr'; // qr | summoned | manual | archive | create
  String summonedFilter = 'all'; // all | present | absent
  String exceptionReason = 'Điện thoại hết pin tại buổi họp';
  String archivePeriod = 'month'; // month | quarter | year
  Timer? _timer;

  late final titleCtrl = TextEditingController(text: widget.state.activeSession.title);
  late final dateCtrl = TextEditingController(text: widget.state.activeSession.date);
  late final locationCtrl = TextEditingController(text: widget.state.activeSession.location);
  String format = 'hybrid';
  late int refreshSeconds = widget.state.activeSession.refreshSeconds;
  late bool geofenceRequired = widget.state.activeSession.geofenceRequired;

  int countdown = 60;

  @override
  void initState() {
    super.initState();
    countdown = widget.state.activeSession.refreshSeconds;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    titleCtrl.dispose();
    dateCtrl.dispose();
    locationCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    countdown = refreshSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (countdown <= 1) {
          widget.state.rotateQRToken();
          countdown = widget.state.activeSession.refreshSeconds;
        } else {
          countdown--;
        }
      });
    });
  }

  void _manualRefresh() {
    widget.state.rotateQRToken();
    _startTimer();
    widget.state.showToast('Đã sinh mã QR động mới chống chụp ảnh điểm danh hộ!');
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final session = state.activeSession;
    final summoned = state.members.where((m) => m.type != 'transferred').toList();
    final exempt = state.members.where((m) => m.type == 'transferred').toList();
    final localAttended = summoned.where((m) => m.type == 'local' && state.scannedMemberIds.contains(m.id)).length;
    final farAttended = summoned.where((m) => m.type == 'working_far' && state.scannedMemberIds.contains(m.id)).length;
    final filtered = summoned.where((m) {
      final present = state.scannedMemberIds.contains(m.id);
      if (summonedFilter == 'present') return present;
      if (summonedFilter == 'absent') return !present;
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Tab chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _tabChip('qr', 'Mã QR', Icons.qr_code_2),
                _tabChip('summoned', 'Triệu tập', Icons.groups_rounded),
                _tabChip('manual', 'Ngoại lệ', Icons.how_to_reg_rounded),
                _tabChip('archive', 'Lưu trữ', Icons.inventory_2_rounded),
                _tabChip('create', 'Tạo mới', Icons.add_circle_outline_rounded),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (activeTab == 'create') ...[
            AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: D.light, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.add_circle_outline_rounded, size: 19, color: D.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tạo Buổi Sinh hoạt mới', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                            Text('Triệu tập ${summoned.length} ĐV (Miễn ${exempt.length} chuyển SH)', style: const TextStyle(fontSize: 12, color: D.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DTextField(controller: titleCtrl, label: 'Chủ đề sinh hoạt'),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: DTextField(controller: dateCtrl, label: 'Thời gian')),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Hình thức', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: D.border)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: format,
                                  isExpanded: true,
                                  items: const [
                                    DropdownMenuItem(value: 'direct', child: Text('Trực tiếp tại NVH', style: TextStyle(fontSize: 13))),
                                    DropdownMenuItem(value: 'hybrid', child: Text('Kết hợp Trực tuyến', style: TextStyle(fontSize: 13))),
                                    DropdownMenuItem(value: 'online', child: Text('Trực tuyến 100%', style: TextStyle(fontSize: 13))),
                                  ],
                                  onChanged: (v) => setState(() => format = v ?? format),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DTextField(controller: locationCtrl, label: 'Địa điểm tổ chức'),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: D.border)),
                    child: Column(
                      children: [
                        const Row(children: [
                          Icon(Icons.shield_rounded, size: 15, color: D.primary),
                          SizedBox(width: 6),
                          Text('Bảo mật QR Động & Định vị GPS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                        ]),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Chu kỳ đổi mã QR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                                  Text('Chống điểm danh hộ', style: TextStyle(fontSize: 11, color: D.textMuted)),
                                ],
                              ),
                            ),
                            for (final sec in [30, 60, 90])
                              GestureDetector(
                                onTap: () => setState(() => refreshSeconds = sec),
                                child: Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: refreshSeconds == sec ? D.primary : Colors.white,
                                    borderRadius: BorderRadius.circular(9),
                                    border: Border.all(color: refreshSeconds == sec ? D.primary : D.border),
                                  ),
                                  child: Text('${sec}s', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: refreshSeconds == sec ? Colors.white : const Color(0xFF475569))),
                                ),
                              ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Geofencing GPS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                                  Text('Bán kính hợp lệ 100m', style: TextStyle(fontSize: 11, color: D.textMuted)),
                                ],
                              ),
                            ),
                            Switch(value: geofenceRequired, activeColor: D.primary, onChanged: (v) => setState(() => geofenceRequired = v)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton('Khởi tạo buổi họp & Sinh mã QR', icon: Icons.qr_code_2, onPressed: () {
                    widget.state.updateActiveSession({
                      'title': titleCtrl.text,
                      'date': dateCtrl.text,
                      'location': locationCtrl.text,
                      'format': format,
                      'refreshSeconds': refreshSeconds,
                      'geofenceRequired': geofenceRequired,
                      'allowShiftCatchup': session.allowShiftCatchup,
                    }, isNewSession: true);
                    setState(() => activeTab = 'qr');
                    _startTimer();
                    widget.state.showToast('Đã khởi tạo buổi sinh hoạt mới & triệu tập đoàn viên Chi đoàn KP5!');
                  }),
                ],
              ),
            ),
          ],

          if (activeTab == 'summoned') ...[
            AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('Danh sách Triệu tập', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                      const Spacer(),
                      Pill('${state.scannedCount}/${summoned.length} có mặt', fontSize: 11),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _filterBtn('all', 'Tất cả (${summoned.length})', D.primary, Colors.white, Colors.white),
                      _filterBtn('present', 'Có mặt (${state.scannedCount})', const Color(0xFF059669), Colors.white, D.greenDark),
                      _filterBtn('absent', 'Vắng (${math.max(0, summoned.length - state.scannedCount)})', const Color(0xFFE11D48), Colors.white, const Color(0xFFBE123C)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Miễn triệu tập ${exempt.length} đoàn viên đang chuyển sinh hoạt / nghĩa vụ quân sự.', style: const TextStyle(fontSize: 12, color: D.textMuted)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...filtered.map((m) {
              final present = state.scannedMemberIds.contains(m.id);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: D.border)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                          Text('${m.memberCode} • ${m.workplace} (${m.shift})', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: D.textMuted)),
                        ],
                      ),
                    ),
                    Pill(present ? 'Có mặt' : 'Chưa dự', bg: present ? D.greenLight : const Color(0xFFF1F5F9), fg: present ? D.greenDark : const Color(0xFF475569), fontSize: 11),
                  ],
                ),
              );
            }),
          ],

          if (activeTab == 'manual') ...[
            AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: D.light, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.gpp_maybe_rounded, size: 19, color: D.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Điểm danh Ngoại lệ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                            Text(state.isOffline ? 'Ngoại tuyến: Lưu cục bộ' : 'Xác nhận ĐV không quét được QR', style: const TextStyle(fontSize: 12, color: D.textMuted)),
                          ],
                        ),
                      ),
                      Pill('${state.scannedCount}/${summoned.length}', fontSize: 11),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Lý do xác nhận ngoại lệ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: D.border)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: exceptionReason,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'Điện thoại hết pin tại buổi họp', child: Text('Điện thoại hết pin tại buổi họp', style: TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'Khu vực sóng yếu không tải được camera', child: Text('Khu vực sóng yếu không tải được camera', style: TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'Đoàn viên quên mang điện thoại thông minh', child: Text('Đoàn viên quên mang điện thoại thông minh', style: TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'Tham gia trực dân quân / công tác đột xuất', child: Text('Tham gia trực dân quân / công tác đột xuất', style: TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (v) => setState(() => exceptionReason = v ?? exceptionReason),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...summoned.map((m) {
                    final present = state.scannedMemberIds.contains(m.id);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: D.border.withValues(alpha: 0.6))),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                Text('${m.workplace} • ${m.shift}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: D.textMuted)),
                              ],
                            ),
                          ),
                          if (present)
                            Pill('Có mặt', bg: D.greenLight, fg: D.greenDark, fontSize: 11)
                          else
                            GestureDetector(
                              onTap: () {
                                final res = state.markManualAttendance(m.id, exceptionReason);
                                if (res['ok'] == true) {
                                  state.showToast(res['offline'] == true ? 'Đã lưu xác nhận ngoại lệ cho ${m.name} (Offline)!' : 'Đã xác nhận điểm danh ngoại lệ cho ${m.name} (+10đ)!');
                                }
                              },
                              child: Container(
                                height: 36,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(color: D.primary, borderRadius: BorderRadius.circular(12)),
                                child: const Text('Xác nhận', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          if (activeTab == 'archive') ...[
            AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('Lưu trữ Lịch sử 2026', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                      const Spacer(),
                      Text('${sessionArchive.length} kỳ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: D.primary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        _seg('month', 'Tháng'),
                        _seg('quarter', 'Quý'),
                        _seg('year', 'Năm 2026'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (archivePeriod == 'quarter')
              ...['Quý IV/2026', 'Quý III/2026', 'Quý II/2026', 'Quý I/2026'].map((q) {
                final items = sessionArchive.where((s) => s['quarter'] == q).toList();
                final avg = items.isEmpty ? '0' : (items.fold<double>(0, (acc, it) => acc + double.parse((it['rate'] as String).replaceAll('%', ''))) / items.length).toStringAsFixed(1);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: D.border)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(q, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: D.primary)),
                            Text('${items.length} kỳ sinh hoạt định kỳ', style: const TextStyle(fontSize: 12, color: D.textMuted)),
                          ],
                        ),
                      ),
                      Text('$avg%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    ],
                  ),
                );
              })
            else if (archivePeriod == 'year')
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tổng kết Năm 2026 — Chi đoàn KP5', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: D.primary)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(12)),
                            child: Column(children: [
                              Text('${sessionArchive.length} kỳ', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: D.primary)),
                              const Text('Đã lưu trữ', style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
                            ]),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: D.light, borderRadius: BorderRadius.circular(12)),
                            child: const Column(children: [
                              Text('70.9%', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: D.primary)),
                              Text('Chuyên cần năm', style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              ...sessionArchive.map((arc) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: D.border)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Pill(arc['period'] as String, fontSize: 10),
                              const SizedBox(height: 6),
                              Text(arc['title'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                              Text(arc['location'] as String, style: const TextStyle(fontSize: 12, color: D.textMuted)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(arc['rate'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: D.primary)),
                            Text('${arc['attended']}/${arc['total']} ĐV', style: const TextStyle(fontSize: 12, color: D.textMuted)),
                          ],
                        ),
                      ],
                    ),
                  )),
          ],

          if (activeTab == 'qr') ...[
            // Thông tin buổi
            AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Pill('Chi đoàn Khu phố 5', fontSize: 11),
                      const Spacer(),
                      const Row(children: [
                        Icon(Icons.circle, size: 8, color: Color(0xFF10B981)),
                        SizedBox(width: 6),
                        Text('Đang mở điểm danh', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: D.greenDark)),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(session.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), height: 1.3)),
                  ),
                  const SizedBox(height: 8),
                  _iconRow(Icons.calendar_today_rounded, session.date),
                  _iconRow(Icons.place_rounded, session.location),
                ],
              ),
            ),
            // QR card
            const SizedBox(height: 14),
            AppCard(
              radius: 24,
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_rounded, size: 15, color: D.primary),
                      SizedBox(width: 6),
                      Text('Mã QR Động', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: D.primary)),
                    ],
                  ),
                  Text('Token ${session.qrToken}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: D.primary)),
                  const SizedBox(height: 14),
                  Container(
                    width: 208,
                    height: 208,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: D.primary.withValues(alpha: 0.2), width: 2)),
                    child: CustomPaint(painter: _DynamicQrPainter(token: session.qrToken, seed: session.qrSeed)),
                  ),
                  const SizedBox(height: 14),
                  Text.rich(TextSpan(style: const TextStyle(fontSize: 13, color: Color(0xFF475569)), children: [
                    const TextSpan(text: 'Làm mới tự động sau '),
                    TextSpan(text: '$countdown', style: const TextStyle(fontWeight: FontWeight.w800, fontFamily: 'monospace', color: D.primary)),
                    const TextSpan(text: 's'),
                  ])),
                  const SizedBox(height: 6),
                  Container(
                    width: 176,
                    height: 6,
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: (countdown / refreshSeconds).clamp(0.0, 1.0),
                          child: Container(color: D.primary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _qrAction('Đổi mã', Icons.refresh_rounded, bg: D.grayBg, fg: const Color(0xFF1E293B), onTap: _manualRefresh)),
                      Expanded(child: _qrAction('Chép link', Icons.copy_rounded, bg: D.light, fg: D.primary, onTap: () => widget.state.showToast('Đã sao chép link điểm danh (${session.qrToken})!'))),
                      Expanded(child: _qrAction('Gửi Zalo', Icons.share_rounded, bg: D.primary, fg: Colors.white, onTap: () => widget.state.showToast('Đã gửi link & mã ${session.qrToken} vào nhóm Zalo Chi đoàn KP5!'))),
                    ],
                  ),
                ],
              ),
            ),
            // Tiến độ
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('Tiến độ điểm danh', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                      const Spacer(),
                      Text('${state.scannedCount} / ${summoned.length} ĐV (${((state.scannedCount / summoned.length) * 100).round()}%)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: D.primary)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DProgress(value: state.scannedCount / summoned.length, height: 10),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tại chỗ: $localAttended/31', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                      Text('Làm ca KCN: $farAttended/12', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: D.primary)),
                    ],
                  ),
                ],
              ),
            ),
            // Toggle ca bù
            const SizedBox(height: 14),
            AppCard(
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, size: 16, color: D.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Cho phép đăng ký ca bù', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                        Text('Đoàn viên ca đêm đăng ký ghép hoặc E-Learning', style: const TextStyle(fontSize: 12, color: D.textMuted)),
                      ],
                    ),
                  ),
                  Switch(
                    value: session.allowShiftCatchup,
                    activeColor: D.primary,
                    onChanged: (v) {
                      widget.state.updateActiveSession({'allowShiftCatchup': v});
                    },
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _qrAction(String label, IconData icon, {required Color bg, required Color fg, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
          ],
        ),
      ),
    );
  }

  Widget _seg(String id, String label) {
    final active = archivePeriod == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => archivePeriod = id),
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: active ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(9)),
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? D.primary : const Color(0xFF475569))),
        ),
      ),
    );
  }

  Widget _filterBtn(String id, String label, Color activeBg, Color activeFg, Color inactiveFg) {
    final active = summonedFilter == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => summonedFilter = id),
        child: Container(
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? activeBg : D.grayBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? activeBg : D.border),
          ),
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: active ? activeFg : inactiveFg)),
        ),
      ),
    );
  }

  Widget _tabChip(String id, String label, IconData icon) {
    final active = activeTab == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => activeTab = id),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: active ? D.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? D.primary : D.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 15, color: active ? Colors.white : const Color(0xFF475569)),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? Colors.white : const Color(0xFF475569))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Icon(icon, size: 15, color: D.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Color(0xFF475569)))),
      ]),
    );
  }
}

/// QR động giả lập theo thiết kế (hash token + seed, vẽ ma ô)
class _DynamicQrPainter extends CustomPainter {
  final String token;
  final int seed;
  _DynamicQrPainter({required this.token, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100;
    Paint primary = Paint()..color = D.primary;
    Paint white = Paint()..color = Colors.white;

    void rect(double x, double y, double w, double h, double r, Paint p) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x * scale, y * scale, w * scale, h * scale), Radius.circular(r * scale)), p);
    }

    // 3 finder pattern
    for (final (fx, fy) in [(5.0, 5.0), (69.0, 5.0), (5.0, 69.0)]) {
      rect(fx, fy, 26, 26, 4, primary);
      rect(fx + 4, fy + 4, 18, 18, 2, white);
      rect(fx + 8, fy + 8, 10, 10, 1, primary);
    }

    // Data cells
    int hashSeed = seed * 31;
    for (int i = 0; i < token.length; i++) {
      hashSeed += token.codeUnitAt(i) * (i + 3);
    }
    for (int row = 0; row < 11; row++) {
      for (int col = 0; col < 11; col++) {
        final inTopLeft = row < 4 && col < 4;
        final inTopRight = row < 4 && col >= 7;
        final inBottomLeft = row >= 7 && col < 4;
        final inCenter = row >= 4 && row <= 6 && col >= 4 && col <= 6;
        if (inTopLeft || inTopRight || inBottomLeft || inCenter) continue;
        final val = (hashSeed + row * 17 + col * 29 + row * col * 7) % 5;
        if (val == 0 || val == 2 || val == 4) {
          rect(6 + col * 8.0, 6 + row * 8.0, 6, 6, 1, primary);
        }
      }
    }

    // Center logo
    canvas.drawCircle(Offset(50 * scale, 50 * scale), 11 * scale, white);
    canvas.drawCircle(Offset(50 * scale, 50 * scale), 8 * scale, primary);
  }

  @override
  bool shouldRepaint(_DynamicQrPainter oldDelegate) => oldDelegate.token != token || oldDelegate.seed != seed;
}
