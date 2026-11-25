import '../data/mock_data.dart';
import 'package:flutter/material.dart';
import '../state/app_state.dart';

import '../ui.dart';

class WardDashboard extends StatefulWidget {
  final AppState state;
  final String viewMode; // overview | branches | reports | rewards
  const WardDashboard({super.key, required this.state, required this.viewMode});

  @override
  State<WardDashboard> createState() => _WardDashboardState();
}

class _WardDashboardState extends State<WardDashboard> {
  String internalView = 'overview';
  String selectedMonth = '11';
  String reportPeriod = 'month';
  String branchFilter = 'all';
  String branchSearch = '';
  final searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    internalView = widget.viewMode;
  }

  @override
  void didUpdateWidget(covariant WardDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewMode != widget.viewMode) internalView = widget.viewMode;
    // Mở modal xem trước báo cáo khi bị trigger từ BottomNav
    if (widget.state.exportTrigger > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.state.consumeExportPreview();
        _showExportPreview();
      });
    }
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  void _showExportPreview() {
    final state = widget.state;
    final data = state.wardDataByMonth[selectedMonth]!;
    final submitted = data.branchesRank.where((b) => b.status == 'submitted').length;
    final kp5 = data.branchesRank.firstWhere((b) => b.id == 'kp5');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.88),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14), decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(4)))),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Pill('Xem trước Văn bản Số hóa', fontSize: 10),
                        const SizedBox(height: 6),
                        const Text('Báo cáo Thể thức Đoàn TNCS HCM', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                      ],
                    ),
                  ),
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
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: D.border)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ĐOÀN TNCS HỒ CHÍ MINH', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)),
                            const Text('BCH ĐOÀN P. TRẤN BIÊN', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: D.primary)),
                            Text(data.reportNumber, style: const TextStyle(fontSize: 10.5, color: D.textMuted)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('CHXHCN VIỆT NAM', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)),
                            Text('Độc lập - Tự do - Hạnh phúc', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Text('BÁO CÁO CÔNG TÁC ĐOÀN ${data.monthLabel.toUpperCase()}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                    Text('Kính gửi: Ban Thường vụ Tỉnh Đoàn Đồng Nai', style: const TextStyle(fontSize: 11, color: D.textMuted)),
                    const SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(TextSpan(style: const TextStyle(fontSize: 12, color: Color(0xFF334155)), children: [
                          const TextSpan(text: '1. Quy mô: '),
                          TextSpan(text: '${data.totalBranches} chi đoàn (${data.totalMembers} ĐV)', style: const TextStyle(fontWeight: FontWeight.w700)),
                        ])),
                        const SizedBox(height: 4),
                        Text.rich(TextSpan(style: const TextStyle(fontSize: 12, color: Color(0xFF334155)), children: [
                          const TextSpan(text: '2. Tỷ lệ tham dự bình quân: '),
                          TextSpan(text: '${data.averageAttendanceRate} ($submitted/12 đã nộp)', style: const TextStyle(fontWeight: FontWeight.w700)),
                        ])),
                        const SizedBox(height: 4),
                        Text.rich(TextSpan(style: const TextStyle(fontSize: 12, color: Color(0xFF334155)), children: [
                          const TextSpan(text: '3. Chi đoàn Khu phố 5 đạt tỷ lệ tham dự '),
                          TextSpan(text: '${kp5.rate.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.w700)),
                        ])),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Nơi nhận:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: D.textMuted)),
                            const Text('- Trân trọng, BAN THƯỜNG VỤ TỈNH ĐOÀN;', style: TextStyle(fontSize: 11, color: D.textMuted)),
                            const Text('- Lưu: VP.', style: TextStyle(fontSize: 11, color: D.textMuted)),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('TM. BCH ĐOÀN PHƯỜNG', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 10),
                            const Text('Phan Thị Bích Thảo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                            Row(children: [
                              const Icon(Icons.verified_user_rounded, size: 13, color: D.greenDark),
                              const SizedBox(width: 4),
                              const Text('Ký số điện tử', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: D.greenDark)),
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
                  Expanded(child: PrimaryButton('In / Lưu PDF', icon: Icons.print_rounded, height: 44, fontSize: 13, onPressed: () => widget.state.showToast('Đã xuất bản in văn bản báo cáo (mock) theo thể thức Đoàn!'))),
                  const SizedBox(width: 10),
                  Expanded(child: SecondaryButton('Tải CSV', icon: Icons.download_rounded, height: 44, onPressed: () => widget.state.showToast('Đã xuất file BaoCao_DoanVu_TamHiep_${selectedMonth}_2026.csv!'))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final data = state.wardDataByMonth[selectedMonth]!;
    final submittedCount = data.branchesRank.where((b) => b.status == 'submitted').length;
    final pendingBranches = data.branchesRank.where((b) => b.status != 'submitted').toList();
    final volunteerCount = state.volunteerActivities.length;

    final filtered = data.branchesRank.where((b) {
      final matchFilter = branchFilter == 'all' ? true : branchFilter == 'submitted' ? b.status == 'submitted' : b.status != 'submitted';
      final q = branchSearch.toLowerCase();
      final matchSearch = b.name.toLowerCase().contains(q) || b.secretary.toLowerCase().contains(q);
      return matchFilter && matchSearch;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Hero
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
                            child: Text('Cấp Xã / Phường • ${data.totalBranches} Chi đoàn', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.95))),
                          ),
                          const SizedBox(height: 6),
                          Text(wardDataName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                          Text('$wardOfficerRole — $wardOfficerName', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      for (final m in [('09', 'Tháng 09'), ('10', 'Tháng 10'), ('11', 'Tháng 11')])
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => selectedMonth = m.$1),
                            child: Container(
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selectedMonth == m.$1 ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(m.$2, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selectedMonth == m.$1 ? D.primary : Colors.white.withValues(alpha: 0.8))),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _wStat('${data.totalBranches}', 'Chi đoàn'),
                    _wStat('${data.totalMembers}', 'Đoàn viên'),
                    _wStat(data.averageAttendanceRate, 'Tỷ lệ SH'),
                    _wStat('$volunteerCount', 'Sự kiện'),
                  ],
                ),
              ],
            ),
          ),

          // 4 phân hệ
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: const Color(0xFFCBD5E1).withValues(alpha: 0.7), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                _viewTab('overview', 'Tổng hợp'),
                _viewTab('branches', '12 CĐ'),
                _viewTab('reports', 'Báo cáo'),
                _viewTab('rewards', 'Thi đua'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (internalView == 'branches') ...[
            AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.groups_rounded, size: 16, color: D.primary),
                      const SizedBox(width: 8),
                      Text('${data.branchesRank.length} Chi đoàn trực thuộc', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                      Pill('$submittedCount/${data.branchesRank.length} nộp', fontSize: 11),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: searchCtrl,
                    onChanged: (v) => setState(() => branchSearch = v),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                      hintText: 'Tìm Chi đoàn hoặc Bí thư...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      filled: true,
                      fillColor: D.grayBg,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: D.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: D.primary, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _branchFilter('all', 'Tất cả (${data.branchesRank.length})'),
                      _branchFilter('submitted', 'Đã nộp ($submittedCount)'),
                      _branchFilter('pending', 'Chưa nộp (${data.branchesRank.length - submittedCount})'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...filtered.asMap().entries.map((e) => _branchCard(e.value, e.key)),
          ],

          if (internalView == 'rewards') ...[
            AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.emoji_events_rounded, size: 16, color: D.primary),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('Top 3 Thi đua Phường', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)))),
                      Pill(data.monthLabel, fontSize: 10),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (int idx = 0; idx < 3; idx++)
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: idx == 0 ? D.light : D.grayBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: idx == 0 ? D.primary.withValues(alpha: 0.3) : D.border.withValues(alpha: 0.7)),
                            ),
                            child: Column(
                              children: [
                                Text('#${idx + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: D.primary)),
                                const SizedBox(height: 4),
                                Text(data.branchesRank[idx].name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), height: 1.2)),
                                const SizedBox(height: 4),
                                Text('${data.branchesRank[idx].rate.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: D.primary)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                children: [
                  Row(children: [
                    const Icon(Icons.workspace_premium_rounded, size: 16, color: D.primary),
                    const SizedBox(width: 8),
                    Text('Điểm thi đua ${data.branchesRank.length} Chi đoàn', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                  ]),
                  const SizedBox(height: 12),
                  ...data.branchesRank.asMap().entries.map((e) {
                    final b = e.value;
                    final innovationBonus = b.highlight ? 15 : b.status == 'submitted' ? 5 : 0;
                    final totalScore = (b.rate + innovationBonus).round().clamp(0, 100);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: b.highlight ? D.accentLight : D.grayBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: b.highlight ? D.primary.withValues(alpha: 0.3) : D.border.withValues(alpha: 0.7)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('#${e.key + 1} ${b.name}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                Text('Chuyên cần ${b.rate.toStringAsFixed(1)}% • ${b.status == 'submitted' ? 'Nộp đúng hạn' : 'Chưa nộp'}', style: const TextStyle(fontSize: 12, color: D.textMuted)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('$totalScore đ', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: D.primary)),
                              GestureDetector(
                                onTap: () => widget.state.showToast('Đã ghi nhận đề xuất biểu dương ${b.name}!'),
                                child: const Text('Đề xuất khen', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: D.primary)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          if (internalView == 'overview' || internalView == 'reports') ...[
            if (internalView == 'reports') ...[
            AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: D.light, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.table_chart_rounded, size: 19, color: D.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Báo cáo (${switch (reportPeriod) {
                              'quarter' => 'Quý IV/2026',
                              'year' => 'Năm 2026',
                              _ => data.monthLabel,
                            }})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                            Text('$submittedCount/12 Chi đoàn • $volunteerCount hoạt động', style: const TextStyle(fontSize: 12, color: D.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        _periodSeg('month', 'Tháng'),
                        _periodSeg('quarter', 'Quý'),
                        _periodSeg('year', 'Cả Năm'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: PrimaryButton('Xem trước PDF', icon: Icons.description_rounded, height: 44, fontSize: 13, onPressed: _showExportPreview)),
                      const SizedBox(width: 10),
                      Expanded(child: SecondaryButton('Xuất Excel', icon: Icons.download_rounded, height: 44, onPressed: () => widget.state.showToast('Đã xuất file BaoCao_DoanVu_TamHiep_${selectedMonth}_2026.csv!'))),
                    ],
                  ),
                ],
              ),
            ),
            ],
            if (internalView == 'overview') ...[
              const SizedBox(height: 14),
              // Tổng hợp = "mọi thứ có ổn không?" → chỉ hiện việc cần xử lý
              AppCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.fact_check_rounded, size: 16, color: D.primary),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('Tình hình nộp báo cáo kỳ này', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)))),
                        Pill('$submittedCount/${data.branchesRank.length} đã nộp', bg: submittedCount == data.branchesRank.length ? D.greenLight : const Color(0xFFFEF3C7), fg: submittedCount == data.branchesRank.length ? D.greenDark : const Color(0xFF92400E), fontSize: 11),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DProgress(value: data.branchesRank.isEmpty ? 0 : submittedCount / data.branchesRank.length, height: 8),
                    const SizedBox(height: 14),
                    if (pendingBranches.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: D.greenLight, borderRadius: BorderRadius.circular(12)),
                        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.task_alt_rounded, size: 16, color: D.greenDark),
                          SizedBox(width: 8),
                          Text('Tất cả chi đoàn đã nộp báo cáo kỳ này.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: D.greenDark)),
                        ]),
                      )
                    else
                      ...pendingBranches.map((b) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: D.border.withValues(alpha: 0.6))),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(b.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                      Text('${b.secretary} • tỷ lệ ${b.rate.toStringAsFixed(1)}%', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: D.textMuted)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: () => setState(() => widget.state.approveBranchReport(b.id)),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: D.primary,
                                    foregroundColor: Colors.white,
                                    side: BorderSide.none,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text('Duyệt', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                ),
                                const SizedBox(width: 6),
                                OutlinedButton(
                                  onPressed: () {
                                    widget.state.remindBranchReport(selectedMonth, b.id);
                                    setState(() {});
                                  },
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF334155),
                                    side: const BorderSide(color: D.border),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text('Nhắc nộp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          )),
                    const SizedBox(height: 4),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.swipe_left_rounded, size: 13, color: D.textMuted),
                      const SizedBox(width: 4),
                      const Text('Chi tiết từng chi đoàn & toàn bộ danh sách: mục "12 CĐ"', style: TextStyle(fontSize: 11.5, color: D.textMuted)),
                    ]),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _branchCard(BranchRank branch, int index) {
    final state = widget.state;
    final needsReminder = branch.status != 'submitted' || branch.rate < 65;
    final barColor = branch.rate >= 75 ? D.primary : branch.rate >= 65 ? D.primary.withValues(alpha: 0.7) : const Color(0xFFF59E0B);

    return GestureDetector(
      onTap: () => _showBranchDetail(branch),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: branch.highlight ? D.accentLight : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: branch.highlight ? D.primary.withValues(alpha: 0.3) : D.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: index < 3 ? D.primary : const Color(0xFFF1F5F9), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text('${index + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: index < 3 ? Colors.white : const Color(0xFF334155))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(branch.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                      Text('${branch.secretary} • ${branch.type}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: D.textMuted)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${branch.rate.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: D.primary)),
                    Text('${branch.attended}/${branch.total}', style: const TextStyle(fontSize: 11, color: D.textMuted)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            DProgress(value: branch.rate / 100, height: 8, color: barColor),
            const SizedBox(height: 10),
            Row(
              children: [
                Pill(
                  branch.status == 'submitted' ? 'Đã nộp' : branch.reminded ? 'Đã nhắc nộp' : 'Chưa nộp',
                  bg: branch.status == 'submitted' ? D.greenLight : branch.reminded ? D.light : D.roseLight,
                  fg: branch.status == 'submitted' ? D.greenDark : branch.reminded ? D.primary : const Color(0xFFBE123C),
                  fontSize: 10,
                ),
                const Spacer(),
                if (needsReminder)
                  GestureDetector(
                    onTap: () {
                      state.remindBranchReport(selectedMonth, branch.id);
                      state.showToast('Đã gửi tin nhắn nhắc nộp báo cáo tới ${branch.name}!');
                    },
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: branch.reminded ? D.light : D.primary,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(children: [
                        Icon(Icons.notifications_active_rounded, size: 13, color: branch.reminded ? D.primary : Colors.white),
                        const SizedBox(width: 5),
                        Text(branch.reminded ? 'Nhắc lại' : 'Nhắc nộp', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: branch.reminded ? D.primary : Colors.white)),
                      ]),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBranchDetail(BranchRank branch) {
    final state = widget.state;
    final localCount = state.members.where((m) => m.type == 'local').length;
    final farCount = state.members.where((m) => m.type == 'working_far').length;
    final transferredCount = state.members.where((m) => m.type == 'transferred').length;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14), decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(4)))),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Pill(branch.type, fontSize: 10),
                      const SizedBox(height: 6),
                      Text(branch.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                      Text(branch.secretary, style: const TextStyle(fontSize: 13, color: D.textMuted)),
                    ],
                  ),
                ),
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
            Row(
              children: [
                _detailStat('${branch.total}', 'Tổng ĐV', D.grayBg, const Color(0xFF0F172A)),
                _detailStat('${branch.attended}', 'Đã dự', D.greenLight, D.greenDark),
                _detailStat('${branch.rate.toStringAsFixed(1)}%', 'Tỷ lệ', D.light, D.primary),
              ],
            ),
            if (branch.id == 'kp5') ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cơ cấu Chi đoàn KP5:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: D.primary)),
                    Text('• Tại địa phương: $localCount ĐV', style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
                    Text('• Đi làm xa: $farCount ĐV', style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
                    Text('• Chuyển sinh hoạt: $transferredCount ĐV', style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            if (branch.status == 'pending' && branch.id != 'kp5') ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    state.approveBranchReport(branch.id);
                    state.showToast('Đã phê duyệt báo cáo của ${branch.name}!');
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    side: BorderSide.none,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Duyệt báo cáo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      state.remindBranchReport(selectedMonth, branch.id);
                      state.showToast('Đã gửi tin nhắn nhắc nộp báo cáo tới ${branch.name}!');
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: D.primary,
                      foregroundColor: Colors.white,
                      side: BorderSide.none,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Nhắc nộp', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
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
    );
  }

  Widget _wStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  Widget _viewTab(String id, String label) {
    final active = internalView == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => internalView = id),
        child: Container(
          height: 40,
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

  Widget _periodSeg(String id, String label) {
    final active = reportPeriod == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => reportPeriod = id),
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: active ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(9)),
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? D.primary : const Color(0xFF475569))),
        ),
      ),
    );
  }

  Widget _branchFilter(String id, String label) {
    final active = branchFilter == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => branchFilter = id),
        child: Container(
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? D.primary : D.grayBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: active ? Colors.white : const Color(0xFF475569))),
        ),
      ),
    );
  }

  Widget _detailStat(String value, String label, Color bg, Color fg) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: fg)),
            Text(label, style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }
}
