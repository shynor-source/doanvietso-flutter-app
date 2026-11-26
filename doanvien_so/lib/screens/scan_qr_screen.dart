import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../state/app_state.dart';
import '../ui.dart';

class MemberScanQrScreen extends StatefulWidget {
  final AppState state;
  final String activeTab; // 'scan' | 'history'
  final void Function(String) onTabChange;
  final void Function(String) onNavigate;
  const MemberScanQrScreen({super.key, required this.state, required this.activeTab, required this.onTabChange, required this.onNavigate});

  @override
  State<MemberScanQrScreen> createState() => _MemberScanQrScreenState();
}

class _MemberScanQrScreenState extends State<MemberScanQrScreen> {
  bool scanning = false;
  String? geoError;
  bool simulateOutOfRange = false;
  Map<String, dynamic>? modalResult;
  Timer? _scanTimer;
  MobileScannerController? _camera;
  bool _handling = false;

  @override
  void initState() {
    super.initState();
    _camera = MobileScannerController(
      autoStart: true,
      formats: const [BarcodeFormat.qrCode],
      detectionTimeoutMs: 1200,
    );
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _camera?.dispose();
    _camera = null;
    super.dispose();
  }

  void _resumeCamera() {
    try {
      _camera?.start();
    } catch (_) {}
  }

  /// Xử lý 1 lượt quét (từ camera thật hoặc nhập mã thủ công).
  Future<void> _processScan(String scannedToken) async {
    if (_handling || scanning || modalResult != null) return;
    final state = widget.state;
    final member = state.currentMember;
    final hasCheckedIn = state.scannedMemberIds.contains(member.id);
    final hasQueuedOffline = state.offlineQueue.any((q) => q.memberId == member.id && q.sessionId == state.activeSession.id);
    final distanceMeters = simulateOutOfRange ? 320 : 35;

    setState(() => geoError = null);

    if (scannedToken.trim() != state.activeSession.qrToken.trim()) {
      setState(() => geoError = 'Mã QR không khớp buổi sinh hoạt hiện tại (${state.activeSession.qrToken}). Vui lòng quét đúng mã của Bí thư.');
      return;
    }
    if (hasCheckedIn || hasQueuedOffline) {
      setState(() => geoError = 'Bạn đã điểm danh buổi sinh hoạt này rồi. Hệ thống chặn điểm danh trùng lặp.');
      return;
    }

    setState(() => scanning = true);
    try {
      _camera?.stop();
    } catch (_) {}
    _scanTimer?.cancel();
    _scanTimer = Timer(const Duration(milliseconds: 700), () async {
      if (!mounted) return;
      setState(() => scanning = false);

      if (state.activeSession.geofenceRequired && simulateOutOfRange) {
        _resumeCamera();
        setState(() {
          geoError = 'Từ chối điểm danh: Vị trí hiện tại cách Nhà văn hóa KP5 ${distanceMeters}m (vượt bán kính 100m). Vui lòng di chuyển lại gần hoặc đăng ký sinh hoạt bù.';
        });
        return;
      }

      final res = await state.recordMemberQRCheckIn(distanceMeters: distanceMeters);
      if (!mounted) return;
      if (res['ok'] != true) {
        _resumeCamera();
        setState(() => geoError = (res['message'] as String?) ?? 'Bạn đã điểm danh buổi sinh hoạt này trước đó.');
        return;
      }
      setState(() => modalResult = res);
    });
  }

  void _onDetect(BarcodeCapture capture) {
    for (final b in capture.barcodes) {
      final raw = b.rawValue;
      if (raw == null || raw.trim().isEmpty) continue;
      _processScan(raw);
      return;
    }
  }

  /// Nhập mã thủ công — dự phòng khi camera lỗi/môi trường không có camera.
  Future<void> _manualEntry() async {
    final ctrl = TextEditingController();
    final token = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nhập mã điểm danh', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: 'VD: KP5-202612-A7F9',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Xác nhận')),
        ],
      ),
    );
    if (token == null || token.trim().isEmpty || !mounted) return;
    await _processScan(token);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final member = state.currentMember;
    final hasCheckedIn = state.scannedMemberIds.contains(member.id);
    final hasQueuedOffline = state.offlineQueue.any((q) => q.memberId == member.id && q.sessionId == state.activeSession.id);
    final distanceMeters = simulateOutOfRange ? 320 : 35;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Segmented
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: const Color(0xFFCBD5E1).withValues(alpha: 0.7), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    _seg('scan', 'Quét mã QR', Icons.photo_camera_rounded),
                    _seg('history', 'Lịch sử (${state.attendanceHistory.length + state.offlineQueue.length})', Icons.history_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Member card
              AppCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    DAvatar(name: member.name, size: 44, fg: D.primary, bg: D.light),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(member.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                          Text('${member.workplace} • ${member.shift}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: D.textMuted)),
                        ],
                      ),
                    ),
                    Pill('${state.userPoints} đ', fontSize: 12),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (widget.activeTab == 'scan') ..._scanTab(state, hasCheckedIn, hasQueuedOffline, distanceMeters) else ..._historyTab(state),
            ],
          ),
        ),
        // Bottom sheet kết quả
        if (modalResult != null) _resultSheet(state),
      ],
    );
  }

  List<Widget> _scanTab(AppState state, bool hasCheckedIn, bool hasQueuedOffline, int distanceMeters) {
    return [
      if (state.isOffline)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: D.amberLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFCD34D))),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.wifi_off_rounded, size: 16, color: Color(0xFFB45309)),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chế độ Ngoại tuyến (Sóng yếu KCN)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF78350F))),
                    Text('Lượt quét QR sẽ được lưu cục bộ trên máy và tự động đồng bộ khi có mạng.', style: TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
      if (geoError != null) ...[
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: D.roseLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFDA4AF))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFDC2626)),
              const SizedBox(width: 10),
              Expanded(child: Text(geoError!, style: const TextStyle(fontSize: 12, color: Color(0xFF7F1D1D), height: 1.45))),
            ],
          ),
        ),
      ],
      if (hasCheckedIn || hasQueuedOffline) ...[
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: D.greenLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFA7F3D0))),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, size: 16, color: D.green),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasCheckedIn ? 'Đã điểm danh buổi sinh hoạt này.' : 'Đã lưu điểm danh cục bộ - Chờ đồng bộ.',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF064E3B)),
                ),
              ),
              GestureDetector(
                onTap: () => widget.onTabChange('history'),
                child: const Text('Lịch sử', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: D.primary)),
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 12),
      // Camera thật
      Container(
        height: 320,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF020617),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 14)],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: _camera,
              fit: BoxFit.cover,
              onDetect: _onDetect,
              errorBuilder: (context, error) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.videocam_off_rounded, size: 42, color: Colors.white38),
                        const SizedBox(height: 12),
                        Text(
                          'Không mở được camera\n(Hãy cấp quyền CAMERA trong Cài đặt)',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12.5, color: Colors.white54, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Overlay tối mờ trên/dưới
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.55), Colors.transparent, Colors.transparent, Colors.black.withValues(alpha: 0.55)],
                  stops: const [0, 0.25, 0.75, 1],
                ),
              ),
            ),
            // Chip điều khiển trên cùng
            Positioned(
              top: 10, left: 12, right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => setState(() {
                      simulateOutOfRange = !simulateOutOfRange;
                      geoError = null;
                    }),
                    child: Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: simulateOutOfRange ? const Color(0xFFDC2626) : Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(children: [
                        Icon(Icons.navigation_rounded, size: 12, color: simulateOutOfRange ? Colors.white : Colors.white70),
                        const SizedBox(width: 5),
                        Text(simulateOutOfRange ? 'Ngoài vùng (${distanceMeters}m)' : 'GPS OK (${distanceMeters}m)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                      ]),
                    ),
                  ),
                  Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
                    child: const Row(children: [
                      Icon(Icons.lock_rounded, size: 12, color: Color(0xFF34D399)),
                      SizedBox(width: 5),
                      Text('QR Động', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white70)),
                    ]),
                  ),
                ],
              ),
            ),
            // Khung ngắm 4 góc
            Center(
              child: SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  children: [
                    Positioned(top: 0, left: 0, child: _corner(size: 26, top: true, left: true)),
                    Positioned(top: 0, right: 0, child: _corner(size: 26, top: true, left: false)),
                    Positioned(bottom: 0, left: 0, child: _corner(size: 26, top: false, left: true)),
                    Positioned(bottom: 0, right: 0, child: _corner(size: 26, top: false, left: false)),
                  ],
                ),
              ),
            ),
            // Overlay đang xử lý
            if (scanning)
              Container(
                color: D.primary.withValues(alpha: 0.45),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 30, height: 30, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                    SizedBox(height: 10),
                    Text('Đã nhận mã — Đang xác thực GPS...', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                  ],
                ),
              ),
            // Chú thích dưới
            Positioned(
              bottom: 10, left: 12, right: 12,
              child: Text(
                'Đưa mã QR của Bí thư vào khung — Token: ${state.activeSession.qrToken}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      SecondaryButton(
        'Nhập mã thủ công (dự phòng)',
        icon: Icons.keyboard_rounded,
        height: 44,
        onPressed: (scanning || hasCheckedIn || hasQueuedOffline) ? null : _manualEntry,
      ),
      const SizedBox(height: 14),
      AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: D.light, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.schedule_rounded, size: 17, color: D.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bận lịch công tác giờ sinh hoạt?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                  const SizedBox(height: 2),
                  const Text('Mở Lịch cá nhân để đăng ký khung giờ khác hoặc hoàn thành chuyên đề trực tuyến.', style: TextStyle(fontSize: 12, color: D.textMuted, height: 1.4)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => widget.onNavigate('makeup'),
                    child: const Row(children: [
                      Text('Mở Lịch cá nhân', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: D.primary)),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: D.primary),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _historyTab(AppState state) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Đã ghi nhận ${state.attendanceHistory.length} kỳ sinh hoạt', style: const TextStyle(fontSize: 12, color: D.textMuted)),
            const Text('Chuyên cần tốt', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: D.greenDark)),
          ],
        ),
      ),
      const SizedBox(height: 10),
      ...state.offlineQueue.map((item) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: D.amberLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFCD34D))),
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
                          Text(item.sessionTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), height: 1.25)),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.calendar_month_rounded, size: 13, color: Color(0xFFB45309)),
                            const SizedBox(width: 5),
                            Text(item.timestamp, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                          ]),
                        ],
                      ),
                    ),
                    Pill('Chờ đồng bộ', bg: const Color(0xFFFDE68A), fg: const Color(0xFF78350F), fontSize: 10),
                  ],
                ),
                const Divider(color: Color(0xFFFCD34D)),
                Row(
                  children: [
                    Expanded(child: Text(item.typeLabel, style: const TextStyle(fontSize: 12, color: Color(0xFF78350F)))),
                    if (!state.isOffline)
                      GestureDetector(
                        onTap: () => state.syncOfflineQueue(),
                        child: Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: D.primary, borderRadius: BorderRadius.circular(9)),
                          child: const Text('Đồng bộ ngay', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          )),
      ...state.attendanceHistory.map((item) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: D.border)),
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
                          Text(item.sessionName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), height: 1.25)),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.calendar_month_rounded, size: 13, color: D.primary),
                            const SizedBox(width: 5),
                            Text(item.date, style: const TextStyle(fontSize: 12, color: D.textMuted)),
                          ]),
                        ],
                      ),
                    ),
                    Pill(item.badge, bg: item.status == 'attended' ? D.greenLight : D.light, fg: item.status == 'attended' ? D.greenDark : D.primary, fontSize: 10),
                  ],
                ),
                const Divider(),
                Row(
                  children: [
                    Expanded(child: Text(item.type, style: const TextStyle(fontSize: 12, color: D.textMuted))),
                    Text(item.pointsEarned, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: D.primary)),
                  ],
                ),
              ],
            ),
          )),
    ];
  }

  Widget _seg(String id, String label, IconData icon) {
    final active = widget.activeTab == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onTabChange(id),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 3)] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: active ? D.primary : const Color(0xFF475569)),
              const SizedBox(width: 5),
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: active ? D.primary : const Color(0xFF475569)))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _corner({required double size, required bool top, required bool left}) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: top ? BorderSide(color: Colors.white, width: 3) : BorderSide.none,
            bottom: !top ? BorderSide(color: Colors.white, width: 3) : BorderSide.none,
            left: left ? BorderSide(color: Colors.white, width: 3) : BorderSide.none,
            right: !left ? BorderSide(color: Colors.white, width: 3) : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(top && left ? 16 : 0),
            topRight: Radius.circular(top && !left ? 16 : 0),
            bottomLeft: Radius.circular(!top && left ? 16 : 0),
            bottomRight: Radius.circular(!top && !left ? 16 : 0),
          ),
        ),
      ),
    );
  }

  Widget _resultSheet(AppState state) {
    final offline = modalResult!['offline'] == true;
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {},
        child: Container(
          color: const Color(0xFF020617).withValues(alpha: 0.6),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(4))),
                  ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: offline ? const Color(0xFFFEF3C7) : D.light,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(offline ? Icons.wifi_off_rounded : Icons.check_circle_rounded, size: offline ? 26 : 30, color: offline ? const Color(0xFFB45309) : D.primary),
                  ),
                  const SizedBox(height: 12),
                  Text(offline ? 'Đã lưu điểm danh cục bộ' : 'Điểm danh thành công', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                  const SizedBox(height: 6),
                  Text(
                    offline ? 'Hệ thống sẽ tự động đồng bộ và cộng +10 điểm khi có kết nối mạng trở lại.' : 'Đã ghi nhận có mặt của ${state.currentMember.name} tại Nhà văn hóa KP5.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        _row('Thời gian', modalResult!['timestamp']?.toString() ?? '28/11/2026', mono: true),
                        const Row(
                          children: [
                            Text('Định vị GPS', style: TextStyle(fontSize: 13, color: D.textMuted)),
                            Spacer(),
                            Text('NVH KP5 (35m)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: D.greenDark)),
                          ],
                        ),
                        if (!offline)
                          Row(
                            children: [
                              const Text('Điểm tích lũy', style: TextStyle(fontSize: 13, color: D.textMuted)),
                              const Spacer(),
                              Text('+10đ (${state.userPoints} đ)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: D.primary)),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton('Hoàn tất & Xem lịch sử', onPressed: () {
                    setState(() => modalResult = null);
                    widget.onTabChange('history');
                  }),
                  const SizedBox(height: 8),
                  SecondaryButton('Chia sẻ ảnh lên Bảng tin Social', icon: Icons.article_rounded, height: 44, onPressed: () {
                    state.setPreselectedSocialEvent({
                      'eventTag': state.activeSession.title,
                      'imageUrl': '3',
                      'defaultContent': 'Vừa hoàn thành điểm danh QR 2 lớp tại buổi "${state.activeSession.title}" cùng anh chị em Chi đoàn Khu phố 5!',
                    });
                    setState(() => modalResult = null);
                    widget.onNavigate('social');
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String k, String v, {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(k, style: const TextStyle(fontSize: 13, color: D.textMuted)),
          const Spacer(),
          Text(v, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFamily: mono ? 'monospace' : null, color: const Color(0xFF0F172A))),
        ],
      ),
    );
  }
}

