import '../data/mock_data.dart';
import 'package:flutter/material.dart';
import '../state/app_state.dart';

import '../ui.dart';

class SecretaryReportView extends StatefulWidget {
  final AppState state;
  final VoidCallback onBack;
  const SecretaryReportView({super.key, required this.state, required this.onBack});

  @override
  State<SecretaryReportView> createState() => _SecretaryReportViewState();
}

class _SecretaryReportViewState extends State<SecretaryReportView> {
  bool previewOpen = false;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final members = state.members;
    final localCount = members.where((m) => m.type == 'local').length;
    final workingFarCount = members.where((m) => m.type == 'working_far').length;
    final transferredCount = members.where((m) => m.type == 'transferred').length;
    final kp5 = state.wardDataByMonth['11']!.branchesRank.firstWhere((b) => b.id == 'kp5');
    final approvedMakeup = state.makeupRequests.where((r) => r.status == 'approved').length;
    final pendingMakeup = state.makeupRequests.where((r) => r.status == 'pending').length;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Hero
              HeroCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
                      child: Text('Báo cáo nội bộ Chi đoàn', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.95))),
                    ),
                    const SizedBox(height: 8),
                    const Text('Chi đoàn Khu phố 5 — P. Tam Hiệp', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                    Text('Tổng hợp số liệu tháng 11/2026 nộp BCH Đoàn Phường', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          _stat('${members.length}', 'Tổng ĐV'),
                          _div(),
                          _stat('${kp5.rate.toStringAsFixed(1)}%', 'Tỷ lệ T11'),
                          _div(),
                          _stat('${state.scannedCount}', 'Đã quét QR'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Phân loại
              AppCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.groups_rounded, size: 16, color: D.primary),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Phân loại chất lượng (${members.length} ĐV)', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _box('$localCount', 'Tại chỗ', D.light),
                        _box('$workingFarCount', 'Làm xa KCN', D.grayBg),
                        _box('$transferredCount', 'Chuyển SH', D.grayBg),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(12)),
                      child: Text.rich(TextSpan(style: const TextStyle(fontSize: 12, color: Color(0xFF475569)), children: [
                        const TextSpan(text: 'Đơn sinh hoạt bù công nhân KCN: '),
                        TextSpan(text: '$approvedMakeup đã duyệt', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        const TextSpan(text: ', '),
                        TextSpan(text: '$pendingMakeup chờ duyệt', style: const TextStyle(fontWeight: FontWeight.w800, color: D.primary)),
                        const TextSpan(text: '.'),
                      ])),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 3 kỳ
              AppCard(
                child: Column(
                  children: [
                    const Row(children: [
                      Icon(Icons.trending_up_rounded, size: 16, color: D.primary),
                      SizedBox(width: 8),
                      Text('Đối chiếu 03 kỳ sinh hoạt', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                    ]),
                    const SizedBox(height: 12),
                    ...recentSessions.map((ses) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(ses.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                    Text(ses.date, style: const TextStyle(fontSize: 12, color: D.textMuted)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('${ses.attendees}/${ses.total}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: D.primary)),
                                  Text(ses.rate, style: const TextStyle(fontSize: 11, color: D.textMuted)),
                                ],
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Actions
              AppCard(
                child: Column(
                  children: [
                    PrimaryButton(
                      state.kp5ReportSubmitted ? 'Đã nộp báo cáo lên Đoàn Phường' : 'Nộp báo cáo lên Đoàn Phường',
                      icon: state.kp5ReportSubmitted ? Icons.check_circle_rounded : Icons.send_rounded,
                      bg: state.kp5ReportSubmitted ? const Color(0xFF059669) : D.primary,
                      onPressed: state.kp5ReportSubmitted
                          ? null
                          : () {
                              state.submitBranchReportToWard();
                              state.showToast('Đã gửi báo cáo số hóa Chi đoàn KP5 lên Đoàn Phường Tam Hiệp!');
                            },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: SecondaryButton('Xem phiếu', icon: Icons.description_rounded, height: 44, onPressed: () => setState(() => previewOpen = true))),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => state.showToast('Đã tải về bảng thống kê Excel (.csv) của Chi đoàn KP5!'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: D.grayBg,
                              foregroundColor: const Color(0xFF1E293B),
                              side: const BorderSide(color: D.border),
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.download_rounded, size: 16),
                              SizedBox(width: 6),
                              Text('Xuất Excel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: widget.onBack,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_rounded, size: 15, color: Color(0xFF64748B)),
                    SizedBox(width: 6),
                    Text('Quay lại Trang chủ Bí thư', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        if (previewOpen) _previewSheet(state, localCount, workingFarCount, transferredCount, kp5),
      ],
    );
  }

  Widget _previewSheet(AppState state, int localCount, int workingFarCount, int transferredCount, BranchRank kp5) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {},
        child: Container(
          color: const Color(0xFF020617).withValues(alpha: 0.6),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14), decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(4)))),
                    Row(
                      children: [
                        const Expanded(child: Text('Phiếu Báo cáo Chi đoàn KP5', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)))),
                        GestureDetector(
                          onTap: () => setState(() => previewOpen = false),
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
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: D.border)),
                      child: Column(
                        children: [
                          const Center(child: Text('ĐOÀN TNCS HỒ CHÍ MINH PHƯỜNG TAM HIỆP', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF334155)))),
                          const Center(child: Text('BCH CHI ĐOÀN KHU PHỐ 5', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: D.primary))),
                          const Divider(height: 18),
                          const Center(child: Text('BÁO CÁO SINH HOẠT THÁNG 11/2026', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800))),
                          const SizedBox(height: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(TextSpan(style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4), children: [
                                const TextSpan(text: '1. Tổng số đoàn viên: '),
                                TextSpan(text: '${state.members.length} ĐV', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                TextSpan(text: ' (Tại chỗ: $localCount, Làm xa KCN: $workingFarCount, Chuyển SH: $transferredCount).'),
                              ])),
                              Text.rich(TextSpan(style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4), children: [
                                const TextSpan(text: '2. Tỷ lệ tham dự tháng 11: '),
                                TextSpan(text: '${kp5.attended}/${kp5.total} (${kp5.rate.toStringAsFixed(1)}%)', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                              ])),
                              Text.rich(TextSpan(style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4), children: [
                                const TextSpan(text: '3. Kỳ sinh hoạt đang mở: Đã điểm danh '),
                                TextSpan(text: '${state.scannedCount}/${state.members.length} ĐV', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                              ])),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Column(
                                children: [
                                  const Text('TM. BCH CHI ĐOÀN KP5', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
                                  const SizedBox(height: 10),
                                  Text(state.backendUserName ?? 'Nguyễn Văn An', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                  const Row(children: [
                                    Icon(Icons.verified_user_rounded, size: 13, color: D.greenDark),
                                    SizedBox(width: 4),
                                    Text('Đã xác thực điện tử', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: D.greenDark)),
                                  ]),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: PrimaryButton('In / PDF', icon: Icons.print_rounded, height: 44, fontSize: 13, onPressed: () => state.showToast('Đã xuất bản in phiếu báo cáo (mock)!'))),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => previewOpen = false),
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  Widget _div() {
    return Container(width: 1, height: 30, margin: const EdgeInsets.symmetric(horizontal: 6), color: Colors.white.withValues(alpha: 0.15));
  }

  Widget _box(String value, String label, Color bg) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: D.border.withValues(alpha: 0.7))),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: D.primary)),
            Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFF475569))),
          ],
        ),
      ),
    );
  }
}
