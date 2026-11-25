import '../data/mock_data.dart';
import 'package:flutter/material.dart';
import '../state/app_state.dart';

import '../ui.dart';

class MemberListScreen extends StatefulWidget {
  final AppState state;
  final AppRole currentRole;
  final void Function(String) onNavigate;
  const MemberListScreen({super.key, required this.state, required this.currentRole, required this.onNavigate});

  @override
  State<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen> {
  String sectionTab = 'list'; // list | transfer
  String filterType = 'all';
  String searchQuery = '';
  Member? selectedMember;
  bool isEditingMember = false;

  final searchCtrl = TextEditingController();
  final editPhone = TextEditingController();
  final editOccupation = TextEditingController();
  final editWorkplace = TextEditingController();
  final editShift = TextEditingController();
  String editType = 'local';

  // Tạo mới ĐV
  final newNameCtrl = TextEditingController();
  final newCodeCtrl = TextEditingController(text: 'ĐV-DN-047');
  final newPhoneCtrl = TextEditingController();
  final newJoinDateCtrl = TextEditingController(text: '26/03/2024');
  final newWorkplaceCtrl = TextEditingController(text: 'KCN Amata Biên Hòa');
  String newType = 'working_far';

  // Chuyển SH
  final trMemberCtrl = TextEditingController(text: 'Nguyễn Tấn Đạt');
  final trCodeCtrl = TextEditingController(text: 'ĐV-DN-013');
  String trDirection = 'outgoing';
  final trToBranchCtrl = TextEditingController(text: 'Chi đoàn Công ty Pouchen - KCN Biên Hòa 1');
  final trReasonCtrl = TextEditingController(text: 'Chuyển nơi làm việc và chỗ ở sang gần KCN Biên Hòa 1');

  @override
  void dispose() {
    searchCtrl.dispose();
    editPhone.dispose();
    editOccupation.dispose();
    editWorkplace.dispose();
    editShift.dispose();
    newNameCtrl.dispose();
    newCodeCtrl.dispose();
    newPhoneCtrl.dispose();
    newJoinDateCtrl.dispose();
    newWorkplaceCtrl.dispose();
    trMemberCtrl.dispose();
    trCodeCtrl.dispose();
    trToBranchCtrl.dispose();
    trReasonCtrl.dispose();
    super.dispose();
  }

  void openMemberModal(Member member) {
    setState(() {
      selectedMember = member;
      isEditingMember = false;
      editPhone.text = member.phone;
      editOccupation.text = member.occupation;
      editWorkplace.text = member.workplace;
      editShift.text = member.shift;
      editType = member.type;
    });
  }

  @override
  Widget build(BuildContext context) {
    // RBAC: chỉ Bí thư (toàn quyền) và Cán bộ phường (chỉ xem) được vào Danh bạ
    if (widget.currentRole == AppRole.member) {
      return Scaffold(
        backgroundColor: D.pageBg,
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.lock_person_rounded, size: 44, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            const Text('Không có quyền truy cập', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            const SizedBox(height: 4),
            const Text('Chức năng Danh bạ & Hồ sơ chỉ dành cho\nBí thư Chi đoàn và Cán bộ Đoàn Phường.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: D.textMuted)),
          ]),
        ),
      );
    }
    final state = widget.state;
    final members = state.members;
    final maskPhone = state.securitySettings['maskPhone'] == true;

    final filtered = members.where((m) {
      final matchType = switch (filterType) {
        'all' => true,
        'local' => m.type == 'local',
        'working_far' => m.type == 'working_far',
        'transferred' => m.type == 'transferred',
        _ => true,
      };
      final q = searchQuery.toLowerCase();
      final matchSearch = m.name.toLowerCase().contains(q) || m.phone.contains(searchQuery) || m.memberCode.toLowerCase().contains(q) || m.workplace.toLowerCase().contains(q);
      return matchType && matchSearch;
    }).toList();

    final counts = {
      'all': members.length,
      'local': members.where((m) => m.type == 'local').length,
      'working_far': members.where((m) => m.type == 'working_far').length,
      'transferred': members.where((m) => m.type == 'transferred').length,
    };

    String masked(String phone) => maskPhone ? '${phone.substring(0, 4)}.xxx.${phone.substring(phone.length - 3)}' : phone;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: const Color(0xFFCBD5E1).withValues(alpha: 0.7), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    _seg('list', 'Hồ sơ (${counts['all']})', Icons.groups_rounded),
                    _seg('transfer', 'Chuyển SH (${state.transferRequests.length})', Icons.swap_horiz_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (sectionTab == 'list') ...[
                AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      TextField(
                        controller: searchCtrl,
                        onChanged: (v) => setState(() => searchQuery = v),
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          isDense: true,
                          prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                          suffixIcon: searchQuery.isEmpty ? null : IconButton(icon: const Icon(Icons.close_rounded, size: 16), onPressed: () => setState(() { searchCtrl.clear(); searchQuery = ''; })),
                          hintText: 'Tìm tên, mã ĐV, SĐT, KCN...',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          filled: true,
                          fillColor: D.grayBg,
                          contentPadding: const EdgeInsets.symmetric(vertical: 11),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: D.border)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: D.primary, width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _actionBtn('Tạo ĐV', Icons.person_add_rounded, bg: D.primary, fg: Colors.white, onTap: () { newCodeCtrl.text = 'ĐV-DN-${(members.length + 1).toString().padLeft(3, '0')}'; _showCreateSheet(state); })),
                          Expanded(child: _actionBtn('Nhập Excel', Icons.upload_file_rounded, bg: D.light, fg: D.primary, onTap: () => _showImportSheet(state))),
                          Expanded(child: _actionBtn('Xuất DS', Icons.download_rounded, bg: D.grayBg, fg: const Color(0xFF1E293B), onTap: () => widget.state.showToast('Đã xuất danh sách ${members.length} hồ sơ đoàn viên (.csv)!'))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _chip('all', 'Tất cả', counts['all']!),
                    _chip('local', 'Tại chỗ', counts['local']!),
                    _chip('working_far', 'Làm xa', counts['working_far']!),
                    _chip('transferred', 'Chuyển SH', counts['transferred']!),
                  ],
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(text: const TextSpan(style: TextStyle(fontSize: 12, color: D.textMuted), children: [
                        TextSpan(text: 'Hiển thị '),
                        TextSpan(text: 'đoàn viên', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                      ])),
                      const Text('Chạm để xem chi tiết', style: TextStyle(fontSize: 12, color: D.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (filtered.isEmpty)
                  AppCard(
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.groups_rounded, size: 32, color: Color(0xFFCBD5E1)),
                          const SizedBox(height: 8),
                          const Text('Không tìm thấy đoàn viên', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                          const Text('Thử thay đổi từ khóa hoặc bộ lọc phân loại', style: TextStyle(fontSize: 12, color: D.textMuted)),
                        ],
                      ),
                    ),
                  )
                else
                  ...filtered.map((member) => GestureDetector(
                        onTap: () => openMemberModal(member),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: D.border)),
                          child: Row(
                            children: [
                              DAvatar(name: member.name, size: 44, bg: D.light, fg: D.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(child: Text(member.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)))),
                                        const SizedBox(width: 6),
                                        if (member.type == 'working_far') Pill('KCN', bg: D.light, fg: D.primary, fontSize: 9, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
                                        if (member.type == 'transferred') Pill('Chuyển SH', bg: const Color(0xFFF1F5F9), fg: const Color(0xFF475569), fontSize: 9, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
                                      ],
                                    ),
                                    Text('${member.memberCode} • ${member.workplace}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: D.textMuted)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('${member.points} đ', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: D.primary)),
                                  Text(member.shift, style: const TextStyle(fontSize: 10, color: const Color(0xFF94A3B8))),
                                ],
                              ),
                              const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                            ],
                          ),
                        ),
                      )),
              ] else ...[
                // Tab chuyển sinh hoạt
                HeroCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
                        child: Text('Chuyển sinh hoạt trực tuyến', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.95))),
                      ),
                      const SizedBox(height: 8),
                      const Text('Tiếp nhận & Đồng bộ Hồ sơ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                      Text('Kết nối Chi đoàn cũ — mới và lưu trữ lịch sử xử lý 4 bước.', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.swap_horiz_rounded, size: 16, color: D.primary),
                        SizedBox(width: 8),
                        Text('Gửi Yêu cầu mới', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                      ]),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: DTextField(controller: trMemberCtrl, label: 'Đoàn viên')),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Loại hồ sơ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: D.border)),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: trDirection,
                                      isExpanded: true,
                                      items: const [
                                        DropdownMenuItem(value: 'outgoing', child: Text('Chuyển đi', style: TextStyle(fontSize: 13))),
                                        DropdownMenuItem(value: 'incoming', child: Text('Chuyển đến', style: TextStyle(fontSize: 13))),
                                      ],
                                      onChanged: (v) => setState(() => trDirection = v ?? trDirection),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DTextField(controller: trCodeCtrl, label: 'Mã đoàn viên'),
                      const SizedBox(height: 12),
                      DTextField(controller: trToBranchCtrl, label: 'Chi đoàn tiếp nhận mới'),
                      const SizedBox(height: 12),
                      DTextField(controller: trReasonCtrl, label: 'Lý do chuyển'),
                      const SizedBox(height: 14),
                      PrimaryButton('Gửi hồ sơ chuyển sinh hoạt', height: 44, fontSize: 13, onPressed: () {
                        if (trToBranchCtrl.text.trim().isEmpty || trReasonCtrl.text.trim().isEmpty) return;
                        state.submitTransferRequest(memberName: trMemberCtrl.text, memberCode: trCodeCtrl.text, direction: trDirection, toBranch: trToBranchCtrl.text, reason: trReasonCtrl.text);
                        state.showToast('Đã gửi yêu cầu chuyển sinh hoạt cho Đ/c ${trMemberCtrl.text}!');
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Hồ sơ đang xử lý (${state.transferRequests.length})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                ),
                const SizedBox(height: 10),
                ...state.transferRequests.map((tr) => _transferCard(state, tr)),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
        // Member detail sheet
        if (selectedMember != null) _memberSheet(state, masked),
      ],
    );
  }

  Widget _transferCard(AppState state, TransferRequest tr) {
    final statusLabel = switch (tr.status) {
      'completed' => 'Đã đồng bộ',
      'rejected' => 'Trả lại',
      'approved_source' => 'Chờ nơi đến',
      _ => 'Chờ duyệt',
    };
    final statusColor = switch (tr.status) {
      'completed' => (bg: D.greenLight, fg: D.greenDark),
      'rejected' => (bg: D.roseLight, fg: const Color(0xFFBE123C)),
      _ => (bg: D.light, fg: D.primary),
    };
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
                    Row(children: [
                      Flexible(child: Text(tr.memberName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)))),
                      const SizedBox(width: 8),
                      Text(tr.memberCode, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: const Color(0xFF475569), backgroundColor: Color(0xFFF1F5F9))),
                    ]),
                    const SizedBox(height: 4),
                    Pill(tr.direction == 'incoming' ? 'Chuyển đến KP5' : 'Chuyển đi đơn vị khác', bg: tr.direction == 'incoming' ? D.greenLight : D.light, fg: tr.direction == 'incoming' ? D.greenDark : D.primary, fontSize: 10),
                  ],
                ),
              ),
              Pill(statusLabel, bg: statusColor.bg, fg: statusColor.fg, fontSize: 10),
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
                  const TextSpan(text: 'Từ: ', style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: tr.fromBranch),
                ])),
                Text.rich(TextSpan(style: const TextStyle(fontSize: 12, color: Color(0xFF334155)), children: [
                  const TextSpan(text: 'Đến: ', style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: tr.toBranch),
                ])),
                Text.rich(TextSpan(style: const TextStyle(fontSize: 12, color: Color(0xFF334155)), children: [
                  const TextSpan(text: 'Lý do: ', style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: '${tr.reason} (${tr.submittedAt})'),
                ])),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (int i = 0; i < 4; i++)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: tr.step >= i + 1 ? D.primary : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      ['Gửi đơn', 'Chi đoàn cũ', 'Phường', 'Hoàn tất'][i],
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: tr.step >= i + 1 ? Colors.white : const Color(0xFF94A3B8)),
                    ),
                  ),
                ),
            ],
          ),
          if (tr.status == 'pending' || tr.status == 'approved_source') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton('Duyệt & Đồng bộ', icon: Icons.check_rounded, height: 40, fontSize: 12, onPressed: () {
                    state.processTransferRequest(tr.id, 'approve');
                    state.showToast('Đã phê duyệt & đồng bộ dữ liệu chuyển SH cho ${tr.memberName}!');
                  }),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      state.processTransferRequest(tr.id, 'reject');
                      state.showToast('Đã trả lại hồ sơ chuyển SH của ${tr.memberName}.');
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      foregroundColor: const Color(0xFF334155),
                      side: BorderSide.none,
                      minimumSize: const Size.fromHeight(40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Yêu cầu bổ sung', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _memberSheet(AppState state, String Function(String) masked) {
    final member = selectedMember!;
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
                        Pill(member.memberCode, fontSize: 11),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => isEditingMember = !isEditingMember),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(color: D.light, shape: BoxShape.circle),
                            child: const Icon(Icons.edit_rounded, size: 16, color: D.primary),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => setState(() => selectedMember = null),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                            child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF475569)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          DAvatar(name: member.name, size: 56, bg: Colors.white, fg: D.primary, fontSize: 18),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(member.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                Text(masked(member.phone), style: const TextStyle(fontSize: 13, fontFamily: 'monospace', color: D.textMuted)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Pill(switch (member.type) {
                                      'working_far' => 'Công nhân KCN',
                                      'transferred' => 'Chuyển SH',
                                      _ => 'Tại địa phương',
                                    }, fontSize: 10),
                                    const SizedBox(width: 6),
                                    Pill('${member.points} điểm', bg: const Color(0xFFD1FAE5), fg: const Color(0xFF065F46), fontSize: 10),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (isEditingMember)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Cập nhật hồ sơ điện tử', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: D.primary)),
                            const SizedBox(height: 10),
                            DTextField(controller: editPhone, label: 'Số điện thoại'),
                            const SizedBox(height: 10),
                            DTextField(controller: editWorkplace, label: 'Đơn vị / KCN'),
                            const SizedBox(height: 10),
                            DTextField(controller: editShift, label: 'Ca làm'),
                            const SizedBox(height: 12),
                            PrimaryButton('Lưu thay đổi hồ sơ', height: 44, fontSize: 13, onPressed: () {
                              state.updateMemberProfile(member.id, {'phone': editPhone.text});
                              setState(() {
                                selectedMember = null;
                                isEditingMember = false;
                              });
                              widget.state.showToast('Đã cập nhật hồ sơ điện tử của Đ/c ${member.name}!');
                            }),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          children: [
                            _kv('Ngày vào Đoàn', member.joinDate),
                            _kv('Nghề nghiệp', member.occupation),
                            _kv('Chi đoàn', member.branchName, vColor: D.primary),
                            _kv('Nơi làm việc', member.workplace),
                            _kv('Lịch ca kíp', member.shift, vColor: D.primary),
                          ],
                        ),
                      ),
                    const SizedBox(height: 14),
                    const Row(children: [
                      Icon(Icons.calendar_month_rounded, size: 16, color: D.primary),
                      SizedBox(width: 8),
                      Text('Lịch sử 03 kỳ gần nhất', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                    ]),
                    const SizedBox(height: 8),
                    ...member.attendanceHistory.map((rec) {
                      final (bg, fg) = switch (rec.status) {
                        'present' => (const Color(0xFFD1FAE5), const Color(0xFF065F46)),
                        'makeup' => (D.light, D.primary),
                        'military' || 'transferred' => (const Color(0xFFE2E8F0), const Color(0xFF334155)),
                        _ => (const Color(0xFFFFE4E6), const Color(0xFF9F1239)),
                      };
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Text(rec.month, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                            const Spacer(),
                            Pill(rec.label, bg: bg, fg: fg, fontSize: 10),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: SecondaryButton('Gọi điện', icon: Icons.phone_rounded, height: 44, onPressed: () => widget.state.showToast('Đang kết nối cuộc gọi đến ${member.name}...'))),
                        const SizedBox(width: 10),
                        Expanded(child: PrimaryButton('Nhắn Zalo', icon: Icons.chat_rounded, height: 44, fontSize: 13, onPressed: () => widget.state.showToast('Đã mở Zalo gửi tin nhắn tới ${member.name}!'))),
                      ],
                    ),
                    if (member.type == 'working_far') ...[
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () {
                          state.sendMemberMakeupReminder(member);
                          state.showToast('Đã gửi nhắc hẹn Sinh hoạt bù tới Đ/c ${member.name}!');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: D.primary,
                          backgroundColor: Colors.white,
                          side: BorderSide(color: D.primary.withValues(alpha: 0.3)),
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.auto_awesome_rounded, size: 15),
                          SizedBox(width: 6),
                          Text('Nhắc hẹn Đăng ký Sinh hoạt Bù', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateSheet(AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
                    const Expanded(child: Text('Tạo Hồ sơ Đoàn viên', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)))),
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
                DTextField(controller: newNameCtrl, label: 'Họ và tên *', hint: 'Nhập họ tên đoàn viên'),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: DTextField(controller: newCodeCtrl, label: 'Mã đoàn viên')),
                    const SizedBox(width: 10),
                    Expanded(child: DTextField(controller: newPhoneCtrl, label: 'Số điện thoại *', hint: '09xx.xxx.xxx')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: DTextField(controller: newJoinDateCtrl, label: 'Ngày vào Đoàn')),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Phân loại', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: D.border)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: newType,
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(value: 'working_far', child: Text('Đi làm xa / KCN', style: TextStyle(fontSize: 13))),
                                  DropdownMenuItem(value: 'local', child: Text('Tại địa phương', style: TextStyle(fontSize: 13))),
                                ],
                                onChanged: (v) => setSheet(() => newType = v ?? newType),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DTextField(controller: newWorkplaceCtrl, label: 'Đơn vị / KCN'),
                const SizedBox(height: 16),
                PrimaryButton('Lưu hồ sơ đoàn viên', onPressed: () {
                  if (newNameCtrl.text.trim().isEmpty) return;
                  state.createMemberProfile({'name': newNameCtrl.text, 'phone': newPhoneCtrl.text, 'memberCode': newCodeCtrl.text, 'joinDate': newJoinDateCtrl.text, 'type': newType, 'workplace': newWorkplaceCtrl.text});
                  Navigator.pop(ctx);
                  widget.state.showToast('Đã thêm hồ sơ đoàn viên ${newNameCtrl.text} vào Chi đoàn KP5!');
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showImportSheet(AppState state) {
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
              children: [
                const Icon(Icons.table_chart_rounded, size: 20, color: D.primary),
                const SizedBox(width: 8),
                const Expanded(child: Text('Nhập từ Excel / CSV', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)))),
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
            const SizedBox(height: 10),
            const Text('Vòng 1 (mock): nhấn nút dưới để nhập nhanh lô công nhân KCN mẫu sẵn sàng.', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: D.grayBg, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dữ liệu mẫu sẵn sàng (${excelImportBatch.length} ĐV)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: D.primary)),
                  ...excelImportBatch.map((row) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Expanded(child: Text(row['name'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)))),
                            Text(row['workplace'] as String, style: const TextStyle(fontSize: 12, color: D.textMuted)),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 14),
            PrimaryButton('Nhập danh sách này ngay', onPressed: () {
              state.importMembersBatch(excelImportBatch);
              Navigator.pop(ctx);
              widget.state.showToast('Đã nhập hàng loạt ${excelImportBatch.length} đoàn viên từ tệp Excel thành công!');
            }),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v, {Color? vColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Text(k, style: const TextStyle(fontSize: 13, color: D.textMuted)),
          const Spacer(),
          Flexible(child: Text(v, textAlign: TextAlign.right, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: vColor ?? const Color(0xFF0F172A)))),
        ],
      ),
    );
  }

  Widget _seg(String id, String label, IconData icon) {
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: active ? D.primary : const Color(0xFF475569)),
              const SizedBox(width: 5),
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: active ? D.primary : const Color(0xFF475569)))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, {required Color bg, required Color fg, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: fg))),
          ],
        ),
      ),
    );
  }

  Widget _chip(String id, String label, int count) {
    final active = filterType == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => filterType = id),
        child: Container(
          height: 44,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active ? D.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? D.primary : D.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: active ? Colors.white : const Color(0xFF475569))),
              Text('$count', style: TextStyle(fontSize: 10.5, color: active ? Colors.white70 : D.primary)),
            ],
          ),
        ),
      ),
    );
  }
}
