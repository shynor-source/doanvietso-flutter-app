import 'package:flutter/material.dart';
import '../main.dart' show AppStateScope;
import '../ui.dart';

class MemberHomeView extends StatelessWidget {
  final void Function(String) onNavigate;
  const MemberHomeView({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final member = state.currentMember;
    final hasCheckedIn = state.scannedMemberIds.contains(member.id);
    final hasQueuedOffline = state.offlineQueue.any((q) => q.memberId == member.id && q.sessionId == state.activeSession.id);
    final upcomingVolunteerCount = state.volunteerActivities.where((a) => a.status == 'upcoming').length;
    final upcomingSchedulePreview = state.mySchedule.take(2).toList();
    final rankLabel = state.userPoints >= 90 ? 'Xuất sắc' : state.userPoints >= 75 ? 'Khá' : 'Tiên tiến';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Hero Đoàn viên
          HeroCard(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.all(4),
                  child: Image.asset('assets/doantn.png', fit: BoxFit.contain),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
                        child: Text(member.branchName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.95))),
                      ),
                      const SizedBox(height: 5),
                      Text(member.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                      Text('${member.memberCode} • Đoàn viên chính thức', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      Text('${state.userPoints} đ', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: D.primary)),
                      const SizedBox(height: 2),
                      Text(rankLabel, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: D.primary)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Offline queue
          if (state.offlineQueue.any((q) => q.memberId == member.id)) ...[
            const SizedBox(height: 16),
            Container(
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
                        Text('${state.offlineQueue.length} lượt điểm danh lưu cục bộ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF78350F))),
                        Text(state.isOffline ? 'Tự động đồng bộ khi có mạng lại.' : 'Đã có mạng, chạm để đồng bộ.', style: const TextStyle(fontSize: 11, color: Color(0xFF92400E))),
                      ],
                    ),
                  ),
                  if (!state.isOffline)
                    PrimaryButton('Đồng bộ', icon: Icons.refresh_rounded, height: 36, fontSize: 12, onPressed: () => state.syncOfflineQueue()),
                ],
              ),
            ),
          ],

          // Buổi sinh hoạt hiện tại
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Pill('Sinh hoạt kỳ này', fontSize: 11),
                    const Spacer(),
                    if (hasCheckedIn)
                      Pill('Đã điểm danh', bg: D.greenLight, fg: D.greenDark, fontSize: 11)
                    else if (hasQueuedOffline)
                      Pill('Chờ đồng bộ', bg: const Color(0xFFFEF3C7), fg: const Color(0xFF92400E), fontSize: 11)
                    else
                      const Row(children: [
                        Icon(Icons.schedule_rounded, size: 13, color: D.primary),
                        SizedBox(width: 4),
                        Text('Đang mở điểm danh', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: D.primary)),
                      ]),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(state.activeSession.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), height: 1.3)),
                ),
                const SizedBox(height: 8),
                _iconRow(Icons.calendar_today_rounded, state.activeSession.date),
                _iconRow(Icons.place_rounded, state.activeSession.location),
                const SizedBox(height: 10),
                PrimaryButton(
                  hasCheckedIn ? 'Xem trạng thái & Lịch sử điểm danh' : 'Quét mã QR Điểm danh ngay',
                  icon: Icons.qr_code_2,
                  bg: hasCheckedIn ? const Color(0xFF059669) : D.primary,
                  onPressed: () => onNavigate('scan_qr'),
                ),
              ],
            ),
          ),

          // Lịch cá nhân sắp tới
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 16, color: D.primary),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Lịch cá nhân sắp tới', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)))),
                    Text('${state.mySchedule.length} lịch đăng ký', style: const TextStyle(fontSize: 11, color: D.textMuted)),
                  ],
                ),
                const SizedBox(height: 6),
                if (upcomingSchedulePreview.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(12)),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.event_available_rounded, size: 15, color: D.green),
                      SizedBox(width: 8),
                      Text('Chưa có lịch — đăng ký tại mục Lịch', style: TextStyle(fontSize: 12.5, color: Color(0xFF475569))),
                    ]),
                  )
                else
                  ...upcomingSchedulePreview.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: GestureDetector(
                        onTap: () => onNavigate('makeup'),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(color: D.light, borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(item.dayOfWeek, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: D.primary)),
                                  Text(item.dateStr.substring(0, 5), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: D.primary)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                  Text('${item.timeSlot} • ${item.room}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: D.textMuted)),
                                ],
                              ),
                            ),
                            Pill(item.category, bg: D.grayBg, fg: D.primary, fontSize: 10),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
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
