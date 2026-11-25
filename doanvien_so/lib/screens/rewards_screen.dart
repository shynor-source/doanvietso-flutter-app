import '../data/mock_data.dart';
import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../ui.dart';

class RewardsScreen extends StatefulWidget {
  final AppState state;
  final AppRole currentRole;
  final void Function(String) onNavigate;
  const RewardsScreen({super.key, required this.state, required this.currentRole, required this.onNavigate});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  String sectionTab = 'activities'; // activities | ranking | vouchers
  RewardItem? selectedReward;
  Map<String, dynamic>? generatedVoucher;
  final proofNoteCtrl = TextEditingController(text: 'Đã hoàn thành nhiệm vụ cùng tổ thanh niên xung kích.');

  // Tạo hoạt động mới
  final actTitleCtrl = TextEditingController();
  final actDateCtrl = TextEditingController(text: '19/12/2026 (07:30 - 11:00)');
  final actLocationCtrl = TextEditingController(text: 'Khu phố 5 - Phường Tam Hiệp');

  @override
  void dispose() {
    proofNoteCtrl.dispose();
    actTitleCtrl.dispose();
    actDateCtrl.dispose();
    actLocationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final member = state.currentMember;
    final rankLabel = state.userPoints >= 90 ? 'Hạng Xuất sắc' : state.userPoints >= 75 ? 'Hạng Khá' : 'Tiên tiến';
    final topMembers = [...state.members]..sort((a, b) => b.points.compareTo(a.points));
    final top5 = topMembers.take(5).toList();

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Hero điểm
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
                                child: Text('Phong trào Thanh niên 2026', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.95))),
                              ),
                              const SizedBox(height: 6),
                              const Text('Tình nguyện & Điểm Thi đua', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                            ],
                          ),
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.workspace_premium_rounded, size: 24, color: Colors.white),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Điểm của ${member.name}', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                              Text('${state.userPoints} điểm', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: Text(rankLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: D.primary)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Segmented
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: const Color(0xFFCBD5E1).withValues(alpha: 0.7), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    if (widget.currentRole == AppRole.wardOfficer) ...[
                      _seg('activities', 'Phong trào (${state.volunteerActivities.length})'),
                      _seg('ranking', 'Chi đoàn'),
                      _seg('vouchers', 'Khen thưởng'),
                    ] else ...[
                      _seg('activities', 'Hoạt động (${state.volunteerActivities.length})'),
                      _seg('ranking', 'Xếp hạng'),
                      _seg('vouchers', 'Quà (${state.vouchers.length})'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              if (sectionTab == 'activities') ...[
                Row(
                  children: [
                    const Expanded(child: Text('Hoạt động Phong trào', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)))),
                    GestureDetector(
                      onTap: _showCreateActivitySheet,
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(color: D.primary, borderRadius: BorderRadius.circular(12)),
                        child: const Row(children: [
                          Icon(Icons.add_circle_outline_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Tạo mới', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                        ]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...state.volunteerActivities.map((act) {
                  final isRegistered = state.registeredVolunteerIds.contains(act.id);
                  final isUpcoming = act.status == 'upcoming';
                  final isCheckedIn = state.volunteerCheckedInIds.contains(act.id);
                  final proof = state.volunteerProofs[act.id];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
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
                                  Pill(isUpcoming ? 'Sắp diễn ra' : 'Đã hoàn thành', bg: isUpcoming ? D.light : D.greenLight, fg: isUpcoming ? D.primary : D.greenDark, fontSize: 10),
                                  const SizedBox(height: 6),
                                  Text(act.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), height: 1.3)),
                                ],
                              ),
                            ),
                            Pill(act.points, bg: D.light, fg: D.primary, fontSize: 11),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _iconRow(Icons.calendar_month_rounded, act.date),
                        _iconRow(Icons.place_rounded, act.location),
                        if (proof != null)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(12)),
                            child: Row(children: [
                              const Icon(Icons.check_circle_rounded, size: 15, color: D.greenDark),
                              const SizedBox(width: 8),
                              Expanded(child: Text('Đã gửi minh chứng: ${proof['note']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: D.greenDark))),
                            ]),
                          ),
                        const Divider(height: 20),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (isUpcoming)
                              _actBtn(isRegistered ? 'Đã đăng ký' : 'Đăng ký', isRegistered ? Icons.check_rounded : Icons.add_rounded, bg: isRegistered ? const Color(0xFF059669) : D.primary, fg: Colors.white, onTap: () {
                                final res = state.toggleVolunteerRegistration(act.id);
                                if (res['ok'] == true) {
                                  state.showToast(res['registered'] == true ? 'Đã đăng ký tham gia "${act.title}" (${act.points})!' : 'Đã hủy đăng ký tham gia "${act.title}".');
                                }
                              }),
                            _actBtn(isCheckedIn ? 'Đã quét QR' : 'Quét QR', Icons.qr_code_2, bg: isCheckedIn ? D.greenLight : D.light, fg: isCheckedIn ? D.greenDark : D.primary, onTap: isCheckedIn
                                ? () => state.showToast('Bạn đã quét QR điểm danh hoạt động này rồi.')
                                : () {
                                    final res = state.checkInVolunteerQR(act.id);
                                    if (res['ok'] == true) {
                                      state.showToast('Điểm danh QR hoạt động "${act.title}" thành công (+${res['points']}đ)!');
                                    }
                                  }),
                            _actBtn(proof != null ? 'Cập nhật ảnh' : 'Minh chứng', Icons.photo_camera_rounded, bg: D.grayBg, fg: const Color(0xFF475569), onTap: () => _showProofSheet(state, act)),
                            _actBtn('Đăng Social', Icons.article_rounded, bg: D.light, fg: D.primary, onTap: () {
                              state.setPreselectedSocialEvent({
                                'eventTag': act.title,
                                'imageUrl': '1',
                                'defaultContent': 'Vừa tham gia hoạt động "${act.title}" tại ${act.location}. Rất vui được đồng hành cùng tuổi trẻ Chi đoàn Khu phố 5!',
                              });
                              widget.onNavigate('social');
                            }),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],

              if (sectionTab == 'ranking' && widget.currentRole == AppRole.wardOfficer) ...[
                AppCard(
                  child: Column(
                    children: [
                      Row(children: [
                        const Icon(Icons.emoji_events_rounded, size: 16, color: Color(0xFF0F766E)),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('Xếp hạng 12 Chi đoàn', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)))),
                        Text('Tháng 11/2026', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F766E))),
                      ]),
                      const SizedBox(height: 12),
                      ...(state.wardDataByMonth['11']?.branchesRank ?? []).take(6).map((b) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: b.id == 'kp5' ? D.light.withValues(alpha: 0.6) : D.grayBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: b.id == 'kp5' ? D.primary.withValues(alpha: 0.3) : D.border.withValues(alpha: 0.7))),
                            child: Row(children: [
                              Container(width: 26, height: 26, alignment: Alignment.center, decoration: BoxDecoration(color: (state.wardDataByMonth['11']?.branchesRank ?? []).indexOf(b) < 3 ? D.primary : const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(8)), child: Text('${(state.wardDataByMonth['11']?.branchesRank ?? []).indexOf(b) + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: (state.wardDataByMonth['11']?.branchesRank ?? []).indexOf(b) < 3 ? Colors.white : const Color(0xFF475569)))),
                              const SizedBox(width: 10),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(b.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                Text('${b.attended}/${b.total} ĐV • Tỷ lệ ${b.rate.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 10.5, color: D.textMuted)),
                              ])),
                              Text('${b.rate.toStringAsFixed(1)}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: b.rate >= 80 ? D.greenDark : const Color(0xFFB45309))),
                            ]),
                          )),
                      const SizedBox(height: 6),
                      const Text('Chi đoàn dưới 70% sẽ được gửi nhắc tiến độ tự động qua Zalo.', style: TextStyle(fontSize: 11, color: D.textMuted)),
                    ],
                  ),
                ),
              ],

              if (sectionTab == 'ranking' && widget.currentRole != AppRole.wardOfficer) ...[
                AppCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.emoji_events_rounded, size: 16, color: D.primary),
                          const SizedBox(width: 8),
                          const Expanded(child: Text('Top Đoàn viên tích cực', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)))),
                          Text('Chi đoàn KP5', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: D.primary)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...top5.asMap().entries.map((e) {
                        final m = e.value;
                        final isMe = m.id == member.id;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe ? D.light.withValues(alpha: 0.6) : D.grayBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isMe ? D.primary.withValues(alpha: 0.3) : D.border.withValues(alpha: 0.7)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: e.key == 0 ? D.primary : Colors.white,
                                  shape: BoxShape.circle,
                                  border: e.key == 0 ? null : Border.all(color: D.border),
                                ),
                                alignment: Alignment.center,
                                child: Text('${e.key + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: e.key == 0 ? Colors.white : const Color(0xFF334155))),
                              ),
                              const SizedBox(width: 10),
                              DAvatar(name: m.name, size: 36, bg: isMe ? Colors.white : D.light, fg: D.primary, fontSize: 12),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                    Text(m.workplace, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: D.textMuted)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('${m.points} đ', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: D.primary)),
                                  GestureDetector(
                                    onTap: () {
                                      state.awardBonusPoints(m.id, 5, null, 'Thưởng phong trào tích cực tháng 11');
                                      state.showToast('Đã thưởng +5 điểm cho Đ/c ${m.name}!');
                                    },
                                    child: const Text('+5đ thưởng', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: D.primary)),
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
                const SizedBox(height: 14),
                AppCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.workspace_premium_rounded, size: 16, color: D.primary),
                          const SizedBox(width: 8),
                          const Expanded(child: Text('Huy hiệu Điện tử', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)))),
                          Text('${state.digitalBadges.where((b) => b.earned).length}/${state.digitalBadges.length} đạt', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: D.greenDark)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 0.95,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        children: state.digitalBadges.map(_badgeCard).toList(),
                      ),
                    ],
                  ),
                ),
              ],

              if (sectionTab == 'vouchers' && widget.currentRole == AppRole.wardOfficer) ...[
                AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.workspace_premium_rounded, size: 18, color: Color(0xFFB45309)),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('Xét khen thưởng kỳ 11/2026', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)))),
                    ]),
                    const SizedBox(height: 4),
                    const Text('Cán bộ phường duyệt — bí thư chi đoàn không thể tự xét cho đơn vị mình.', style: TextStyle(fontSize: 11, color: D.textMuted)),
                    const SizedBox(height: 12),
                    ...topMembers.take(3).map((m) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(m.name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                              Text('${m.points} điểm • ${m.branchName}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: D.textMuted)),
                            ])),
                            GestureDetector(
                              onTap: () {
                                state.awardBonusPoints(m.id, 0, 'badge-danh-hieu', 'Danh hiệu "Đoàn viên tiên phong" kỳ 11/2026');
                                state.showToast('Đã trao danh hiệu "Đoàn viên tiên phong" cho ${m.name}.');
                              },
                              child: Container(height: 36, padding: const EdgeInsets.symmetric(horizontal: 12), alignment: Alignment.center, decoration: BoxDecoration(color: D.primary, borderRadius: BorderRadius.circular(10)), child: const Text('Tặng danh hiệu', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white))),
                            ),
                          ]),
                        )),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        state.showToast('Đã đăng công bố khen thưởng kỳ 11/2026 lên Bảng tin toàn phường.');
                      },
                      child: Container(height: 44, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFF0F766E), borderRadius: BorderRadius.circular(12)), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.campaign_rounded, size: 17, color: Colors.white), SizedBox(width: 6), Text('Công bố trên Bảng tin toàn phường', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white))])),
                    ),
                  ]),
                ),
              ],

              if (sectionTab == 'vouchers' && widget.currentRole != AppRole.wardOfficer) ...[
                if (state.vouchers.isNotEmpty)
                  AppCard(
                    child: Column(
                      children: [
                        Row(children: [
                          const Icon(Icons.account_balance_wallet_rounded, size: 16, color: D.primary),
                          const SizedBox(width: 8),
                          Text('Ví Voucher (${state.vouchers.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                        ]),
                        const SizedBox(height: 12),
                        ...state.vouchers.map((v) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(v.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                        Text(v.code, style: const TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: D.primary)),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => setState(() => generatedVoucher = {
                                          'title': v.title,
                                          'sponsor': v.sponsor,
                                          'code': v.code,
                                          'expiresAt': v.expiresAt,
                                          'pickupLocation': v.pickupLocation,
                                        }),
                                    child: Container(
                                      height: 36,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(color: D.primary, borderRadius: BorderRadius.circular(12)),
                                      child: const Text('Mở QR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                AppCard(
                  child: Column(
                    children: [
                      const Row(children: [
                        Icon(Icons.redeem_rounded, size: 16, color: D.primary),
                        SizedBox(width: 8),
                        Text('Đổi Quà Thanh niên', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                      ]),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 0.82,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        children: state.rewardItems.map<Widget>((item) {
                          final isOutOfStock = item.available <= 0;
                          final canRedeem = state.userPoints >= item.points && !isOutOfStock;
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(16)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: D.border)),
                                      child: Builder(builder: (_) => Icon(_rewardIcon(item.icon), size: 17, color: D.primary)),
                                    ),
                                    Text('Còn ${item.available}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: D.textMuted)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.title, maxLines: 2, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), height: 1.25)),
                                      Text(item.category, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: D.textMuted)),
                                    ],
                                  ),
                                ),
                                const Divider(height: 14),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${item.points} đ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: D.primary)),
                                    GestureDetector(
                                      onTap: () => _selectReward(state, item),
                                      child: Container(
                                        height: 30,
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: canRedeem ? D.primary : const Color(0xFFE2E8F0),
                                          borderRadius: BorderRadius.circular(9),
                                        ),
                                        child: Text('Đổi quà', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: canRedeem ? Colors.white : const Color(0xFF64748B))),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
        // Voucher QR sheet
        if (generatedVoucher != null) _voucherSheet(state),
        // Confirm redeem sheet
        if (selectedReward != null) _confirmRedeemSheet(state),
      ],
    );
  }

  void _selectReward(AppState state, RewardItem item) {
    if (item.available <= 0) {
      state.showToast('Quà tặng này hiện đã hết suất!');
      return;
    }
    if (state.userPoints < item.points) {
      state.showToast('Chưa đủ điểm rèn luyện! Cần thêm ${item.points - state.userPoints} điểm.');
      return;
    }
    setState(() => selectedReward = item);
  }

  Widget _confirmRedeemSheet(AppState state) {
    final item = selectedReward!;
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {},
        child: Container(
          color: const Color(0xFF020617).withValues(alpha: 0.6),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14), decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(4)))),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: D.light, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.redeem_rounded, size: 24, color: D.primary),
                  ),
                  const SizedBox(height: 10),
                  Text(item.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                  Text(item.category, style: const TextStyle(fontSize: 12, color: D.textMuted)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text('Điểm trừ', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
                            const Spacer(),
                            Text('-${item.points} điểm', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFFE11D48))),
                          ],
                        ),
                        Row(
                          children: [
                            const Text('Còn lại', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
                            const Spacer(),
                            Text('${state.userPoints - item.points} điểm', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: D.primary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton('Xác nhận đổi', height: 44, fontSize: 13, onPressed: () {
                          final res = state.redeemReward(item);
                          setState(() {
                            selectedReward = null;
                            if (res['ok'] == true) generatedVoucher = res['voucher'];
                          });
                        }),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => selectedReward = null),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F5F9),
                            foregroundColor: const Color(0xFF334155),
                            side: BorderSide.none,
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Hủy', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
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
    );
  }

  Widget _voucherSheet(AppState state) {
    final v = generatedVoucher!;
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {},
        child: Container(
          color: const Color(0xFF020617).withValues(alpha: 0.6),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Pill('Voucher điện tử', fontSize: 10),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => generatedVoucher = null),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(v['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                  Text(v['sponsor'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: D.primary)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: D.border)),
                          child: Text(v['code'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'monospace', color: D.primary)),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: 128,
                          height: 128,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: D.border)),
                          child: CustomPaint(painter: _VoucherQrPainter(code: v['code'])),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(TextSpan(style: const TextStyle(fontSize: 12, color: Color(0xFF475569)), children: [
                                const TextSpan(text: 'Người nhận: '),
                                TextSpan(text: state.currentMember.name, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                              ])),
                              Text.rich(TextSpan(style: const TextStyle(fontSize: 12, color: Color(0xFF475569)), children: [
                                const TextSpan(text: 'Hạn dùng: '),
                                TextSpan(text: v['expiresAt'], style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                              ])),
                              Text('Địa điểm: ${v['pickupLocation']}', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton('Lưu & Đóng', icon: Icons.download_rounded, onPressed: () {
                    state.showToast('Đã lưu Voucher ${v['code']} vào Ví Voucher!');
                    setState(() => generatedVoucher = null);
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showProofSheet(AppState state, VolunteerActivity act) {
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
                  const Expanded(child: Text('Gửi Ảnh / Video Minh chứng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)))),
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
              const SizedBox(height: 8),
              Text(act.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(color: D.light, borderRadius: BorderRadius.circular(16)),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_rounded, size: 34, color: D.primary),
                    SizedBox(height: 6),
                    Text('Ảnh minh chứng hoạt động (mock)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: D.primary)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              DTextField(controller: proofNoteCtrl, label: 'Ghi chú kết quả tham gia...', maxLines: 2),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton('Lưu minh chứng', height: 44, fontSize: 13, onPressed: () {
                      state.submitVolunteerProof(act.id, note: proofNoteCtrl.text, imageUrl: '1');
                      Navigator.pop(ctx);
                      state.showToast('Đã gửi hình ảnh minh chứng cho "${act.title}"!');
                    }),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SecondaryButton('Đăng lên Social', height: 44, onPressed: () {
                      state.setPreselectedSocialEvent({
                        'eventTag': act.title,
                        'imageUrl': '1',
                        'defaultContent': 'Vừa tham gia hoạt động "${act.title}" tại ${act.location}. Rất vui được đồng hành cùng tuổi trẻ Chi đoàn Khu phố 5!',
                      });
                      Navigator.pop(ctx);
                      widget.onNavigate('social');
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateActivitySheet() {
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
                  const Expanded(child: Text('Tạo Hoạt động Tình nguyện', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)))),
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
              DTextField(controller: actTitleCtrl, label: 'Tên hoạt động *', hint: 'VD: Ngày Chủ Nhật Xanh dọn dẹp Khu phố 5'),
              const SizedBox(height: 12),
              DTextField(controller: actDateCtrl, label: 'Thời gian'),
              const SizedBox(height: 12),
              DTextField(controller: actLocationCtrl, label: 'Địa điểm'),
              const SizedBox(height: 16),
              PrimaryButton('Đăng tải hoạt động', onPressed: () {
                if (actTitleCtrl.text.trim().isEmpty) return;
                state.createVolunteerActivity(title: actTitleCtrl.text, date: actDateCtrl.text, location: actLocationCtrl.text, pointsValue: 20);
                Navigator.pop(ctx);
                state.showToast('Đã tạo và phát động hoạt động phong trào mới tới toàn Chi đoàn!');
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badgeCard(DigitalBadge bdg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bdg.earned ? D.accentLight : D.grayBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bdg.earned ? D.primary.withValues(alpha: 0.25) : D.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: bdg.earned ? D.primary : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_badgeIcon(bdg.icon), size: 16, color: bdg.earned ? Colors.white : const Color(0xFF64748B)),
              ),
              Pill(bdg.earned ? 'Đã cấp' : 'Chưa đạt', bg: bdg.earned ? const Color(0xFFD1FAE5) : const Color(0xFFE2E8F0), fg: bdg.earned ? const Color(0xFF065F46) : const Color(0xFF475569), fontSize: 9),
            ],
          ),
          const SizedBox(height: 8),
          Text(bdg.name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), height: 1.2)),
          Text(bdg.desc, style: const TextStyle(fontSize: 10.5, color: D.textMuted, height: 1.25)),
          if (!bdg.earned) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                widget.state.awardBonusPoints(widget.state.currentMember.id, 5, bdg.id, 'Cấp huy hiệu ${bdg.name}');
                widget.state.showToast('Đã cấp huy hiệu "${bdg.name}" và +5 điểm thưởng!');
              },
              child: Container(
                width: double.infinity,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: D.primary, borderRadius: BorderRadius.circular(9)),
                child: const Text('Cấp huy hiệu', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _badgeIcon(String icon) {
    return switch (icon) {
      'zap' => Icons.bolt_rounded,
      'heart' => Icons.favorite_rounded,
      'share' => Icons.share_rounded,
      _ => Icons.workspace_premium_rounded,
    };
  }

  IconData _rewardIcon(String icon) {
    return switch (icon) {
      'fuel' => Icons.local_gas_station_rounded,
      'film' => Icons.movie_rounded,
      'shirt' => Icons.checkroom_rounded,
      _ => Icons.directions_bus_rounded,
    };
  }

  Widget _actBtn(String label, IconData icon, {required Color bg, required Color fg, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: fg)),
          ],
        ),
      ),
    );
  }

  Widget _seg(String id, String label) {
    final active = sectionTab == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => sectionTab = id),
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
        const SizedBox(width: 8),
        Expanded(child: Text(text, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Color(0xFF475569)))),
      ]),
    );
  }
}

/// QR giả lập voucher
class _VoucherQrPainter extends CustomPainter {
  final String code;
  _VoucherQrPainter({required this.code});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100;
    final paint = Paint()..color = D.primary;
    void rect(double x, double y, double w, double h) {
      canvas.drawRect(Rect.fromLTWH(x * scale, y * scale, w * scale, h * scale), paint);
    }
    for (final (fx, fy) in [(5.0, 5.0), (69.0, 5.0), (5.0, 69.0)]) {
      rect(fx, fy, 26, 26);
      canvas.drawRect(Rect.fromLTWH((fx + 4) * scale, (fy + 4) * scale, 18 * scale, 18 * scale), Paint()..color = Colors.white);
      rect(fx + 8, fy + 8, 10, 10);
    }
    int seed = code.length * 17;
    for (int i = 0; i < code.length; i++) {
      seed += code.codeUnitAt(i);
    }
    for (int row = 0; row < 11; row++) {
      for (int col = 0; col < 11; col++) {
        if ((row < 4 && col < 4) || (row < 4 && col >= 7) || (row >= 7 && col < 4)) continue;
        if (((seed + row * 13 + col * 7) % 5) == 0) rect(6 + col * 8.0, 6 + row * 8.0, 6, 6);
      }
    }
  }

  @override
  bool shouldRepaint(_VoucherQrPainter oldDelegate) => oldDelegate.code != code;
}
