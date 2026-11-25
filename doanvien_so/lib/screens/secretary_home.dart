import 'package:flutter/material.dart';
import '../main.dart' show AppStateScope;
import '../data/mock_data.dart' show MakeupRequest;
import '../state/app_state.dart';
import '../ui.dart';

/// Bảng điều khiển Bí thư — "team lens":
/// Hero (3 KPI) → Buổi đang mở (1 primary action) → Hàng đợi đơn chờ duyệt.
/// Không chứa lối tắt trùng bottom nav; chi tiết nằm ở màn riêng (Danh bạ, Báo cáo…).
class SecretaryHomeView extends StatelessWidget {
  final void Function(String) onNavigate;
  const SecretaryHomeView({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final members = state.members;
    final workingFarCount = members.where((m) => m.type == 'working_far').length;
    final pendingRequests = state.makeupRequests.where((r) => r.status == 'pending').toList();
    final scannedCount = state.scannedCount;
    final attendanceRate = (scannedCount / (members.isEmpty ? 1 : members.length) * 100).toStringAsFixed(1);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== Hero: 3 KPI glanceable =====
          HeroCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
                            child: Text('Chi đoàn Khu phố 5', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.95))),
                          ),
                          const SizedBox(height: 6),
                          const Text('Nguyễn Văn An', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                          const Text('Bí thư Chi đoàn • P. Trấn Biên, TP. Đồng Nai', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.white)),
                        ],
                      ),
                    ),
                    const DAvatar(name: 'Nguyễn Văn An', size: 48, bg: Colors.white, fg: D.primary, fontSize: 15),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      _heroStat('${members.length}', 'Tổng ĐV'),
                      _divider(),
                      _heroStat('$workingFarCount', 'Làm xa'),
                      _divider(),
                      _heroStat('$attendanceRate%', 'Điểm danh kỳ này'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Hàng đợi ngoại tuyến (chỉ hiện khi có)
          if (state.offlineQueue.isNotEmpty) ...[
            const SizedBox(height: 16),
            _offlineQueueCard(state),
          ],

          // ===== Buổi đang mở — 1 primary action =====
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Pill('Đang mở điểm danh', fontSize: 11),
                    const Spacer(),
                    Text('$scannedCount/${members.length} ĐV có mặt', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: D.primary)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(state.activeSession.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), height: 1.3)),
                const SizedBox(height: 8),
                _iconRow(Icons.calendar_today_rounded, state.activeSession.date),
                _iconRow(Icons.place_rounded, state.activeSession.location),
                const SizedBox(height: 12),
                DProgress(value: scannedCount / (members.isEmpty ? 1 : members.length), height: 8),
                const SizedBox(height: 12),
                PrimaryButton('Mã QR & Triệu tập', icon: Icons.qr_code_2, height: 44, fontSize: 13, onPressed: () => onNavigate('create_qr')),
              ],
            ),
          ),

          // ===== Hàng đợi việc cần xử lý: đơn chờ duyệt (tối đa 2) =====
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 16, color: D.primary),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Đơn chờ duyệt', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)))),
                    Text('${pendingRequests.length} chờ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: pendingRequests.isEmpty ? D.greenDark : const Color(0xFFB45309))),
                  ],
                ),
                const SizedBox(height: 12),
                if (pendingRequests.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: D.greenLight, borderRadius: BorderRadius.circular(12)),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.task_alt_rounded, size: 16, color: D.greenDark),
                        SizedBox(width: 8),
                        Text('Đã xử lý toàn bộ đơn đăng ký.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: D.greenDark)),
                      ],
                    ),
                  )
                else ...[
                  ...pendingRequests.take(2).map((req) => _requestCard(context, req)),
                  if (pendingRequests.length > 2)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(12)),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.inbox_rounded, size: 14, color: D.textMuted),
                        const SizedBox(width: 6),
                        Text('Còn ${pendingRequests.length - 2} đơn — xem tại Lịch › Duyệt đơn', style: const TextStyle(fontSize: 12, color: D.textMuted)),
                      ]),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _requestCard(BuildContext context, MakeupRequest req) {
    final state = AppStateScope.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: D.border.withValues(alpha: 0.6))),
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
                      const SizedBox(width: 4),
                      Expanded(child: Text(req.workplace, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: D.textMuted))),
                    ]),
                  ],
                ),
              ),
              Pill('Chờ duyệt', bg: const Color(0xFFFEF3C7), fg: const Color(0xFF92400E), fontSize: 11),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(TextSpan(style: const TextStyle(fontSize: 12, color: Color(0xFF334155)), children: [
                  const TextSpan(text: 'Đăng ký: ', style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: req.registeredMakeup),
                ])),
                const SizedBox(height: 2),
                Text.rich(TextSpan(style: const TextStyle(fontSize: 12, color: Color(0xFF334155)), children: [
                  const TextSpan(text: 'Lý do: ', style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: req.reason),
                ])),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.verified_user_rounded, size: 13, color: D.greenDark),
                  const SizedBox(width: 4),
                  Expanded(child: Text(req.proof, style: const TextStyle(fontSize: 12, color: D.greenDark, fontWeight: FontWeight.w500))),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: PrimaryButton('Phê duyệt', icon: Icons.check_rounded, height: 40, fontSize: 12, onPressed: () {
                  state.handleMakeupRequestAction(req.id, 'approve');
                  state.showToast('Đã duyệt đơn cho Đ/c ${req.memberName} & đồng bộ số liệu Chi đoàn.');
                }),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  state.handleMakeupRequestAction(req.id, 'clarify');
                  state.showToast('Đã gửi yêu cầu bổ sung minh chứng tới Đ/c ${req.memberName}.');
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF334155),
                  side: const BorderSide(color: D.border),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Bổ sung', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _offlineQueueCard(AppState data) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: D.amberLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFCD34D))),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 16, color: Color(0xFF92400E)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${data.offlineQueue.length} lượt điểm danh lưu ngoại tuyến', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF78350F))),
                Text(data.isOffline ? 'Tự động đồng bộ khi có kết nối mạng.' : 'Đã có mạng, chạm để đồng bộ.', style: const TextStyle(fontSize: 11, color: Color(0xFF92400E))),
              ],
            ),
          ),
          if (!data.isOffline)
            PrimaryButton('Đồng bộ', icon: Icons.refresh_rounded, height: 36, fontSize: 12, onPressed: () => data.syncOfflineQueue()),
        ],
      ),
    );
  }

  Widget _heroStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 30, margin: const EdgeInsets.symmetric(horizontal: 6), color: Colors.white.withValues(alpha: 0.15));
  }

  Widget _iconRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(children: [
        Icon(icon, size: 15, color: D.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Color(0xFF475569)))),
      ]),
    );
  }
}
