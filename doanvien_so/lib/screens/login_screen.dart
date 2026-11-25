import 'package:flutter/material.dart';
import '../main.dart' show AppStateScope;
import '../state/app_state.dart';
import '../ui.dart';

class LoginScreen extends StatefulWidget {
  final void Function(AppRole) onSelectRole;
  const LoginScreen({super.key, required this.onSelectRole});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String authMode = 'login'; // login | register
  // OTP demo lấy qua --dart-define=DEMO_OTP=... khi build — source không chứa OTP.
  static const String otpCode = String.fromEnvironment('DEMO_OTP');
  bool loggingIn = false;
  bool obscureOtp = false;

  final phoneCtrl = TextEditingController();
  final otpCtrl = TextEditingController(text: const String.fromEnvironment('DEMO_OTP'));

  final regName = TextEditingController();
  final regPhone = TextEditingController();
  final regMemberCode = TextEditingController(text: 'ĐV-DN-047');
  final regJoinDate = TextEditingController(text: '26/03/2024');
  final regOccupation = TextEditingController(text: 'Công nhân sản xuất KCN');
  final regWorkplace = TextEditingController(text: 'KCN Biên Hòa 2');

  @override
  void dispose() {
    phoneCtrl.dispose();
    otpCtrl.dispose();
    regName.dispose();
    regPhone.dispose();
    regMemberCode.dispose();
    regJoinDate.dispose();
    regOccupation.dispose();
    regWorkplace.dispose();
    super.dispose();
  }

  void _submitRegister() {
    final state = AppStateScope.of(context);
    if (regName.text.trim().isEmpty || regPhone.text.trim().isEmpty) return;
    state.registerNewAccount({
      'name': regName.text.trim(),
      'phone': regPhone.text.trim(),
      'memberCode': regMemberCode.text,
      'joinDate': regJoinDate.text,
      'occupation': regOccupation.text,
      'workplace': regWorkplace.text,
      'type': regOccupation.text.toLowerCase().contains('kcn') ? 'working_far' : 'local',
      'shift': 'Ca ngày',
    });
    state.showToast('Đăng ký & xác thực tài khoản "${regName.text.trim()}" thành công!');
    widget.onSelectRole(AppRole.member);
  }

  /// Số điện thoại thô (bỏ dấu chấm/khoảng trắng) để gửi máy chủ.
  String get _rawPhone => phoneCtrl.text.replaceAll(RegExp(r'[.\s-]'), '').trim();

  /// Vai trò dự phòng cho chế độ demo (server không khả dụng) — suy luận từ SĐT.
  AppRole _demoRoleFor(String raw) {
    if (raw.startsWith('0912')) return AppRole.secretary;
    if (raw.startsWith('0908')) return AppRole.wardOfficer;
    return AppRole.member;
  }

  /// Gợi ý OTP: hiện mã demo nếu được truyền khi build, không thì gợi ý chung.
  String demoOtpHint() {
    if (otpCode.trim().isEmpty) {
      return 'Mã OTP được cấp cho tài khoản demo (production gửi OTP qua SMS/Zalo).';
    }
    return 'Bản demo: mã OTP cố định $otpCode. Production gửi OTP qua SMS/Zalo.';
  }

  /// Đăng nhập qua backend thật (OTP demo truyền qua --dart-define khi build).
  /// Thành công → vai trò do máy chủ quyết định (RBAC) và tự đồng bộ dữ liệu.
  /// Lỗi kết nối → fallback chế độ demo dữ liệu mẫu.
  Future<void> _handleBackendLogin(BuildContext context) async {
    final state = AppStateScope.of(context, listen: false);
    final phone = _rawPhone;
    final otp = otpCode.trim();
    if (phone.length < 9) {
      state.showToast('Vui lòng nhập số điện thoại hợp lệ (9–10 số).');
      return;
    }
    if (otp.length < 4) {
      state.showToast('Vui lòng nhập mã OTP gồm 6 số.');
      return;
    }
    setState(() => loggingIn = true);
    try {
      final serverRole = await state.loginWithBackend(phone, otp);
      final role = switch (serverRole) {
        'secretary' => AppRole.secretary,
        'ward_officer' => AppRole.wardOfficer,
        _ => AppRole.member,
      };
      if (!mounted) return;
      state.showToast('Xác thực OTP thành công (${_roleLabel(role)}) — đã đồng bộ dữ liệu từ máy chủ.');
      widget.onSelectRole(role);
    } catch (e) {
      if (!mounted) return;
      setState(() => loggingIn = false);
      state.showToast('Không đăng nhập được qua máy chủ (${e.toString().split(':').first}) — tiếp tục chế độ demo dữ liệu mẫu.');
      widget.onSelectRole(_demoRoleFor(phone));
    }
  }

  String _roleLabel(AppRole r) => switch (r) {
        AppRole.secretary => 'Bí thư Chi đoàn',
        AppRole.wardOfficer => 'Cán bộ Đoàn Phường',
        _ => 'Đoàn viên',
      };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          children: [
            // ===== Nhận diện app + logo =====
            Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 14)],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset('assets/doantn.png', fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 10),
                const Pill('Đoàn TNCS Hồ Chí Minh Tỉnh Đồng Nai', fontSize: 11),
                const SizedBox(height: 6),
                const Text('Đoàn Viên Số', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                const Text('Quản lý chi đoàn & kết nối thanh niên công nhân KCN', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: D.textMuted)),
              ],
            ),
            const SizedBox(height: 16),
            // ===== Chế độ =====
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12), border: Border.all(color: D.border)),
              child: Row(
                children: [
                  _segment('Đăng nhập', authMode == 'login', () => setState(() => authMode = 'login')),
                  _segment('Đăng ký mới', authMode == 'register', () => setState(() => authMode = 'register')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (authMode == 'login') ...[
              // ===== Khung đăng nhập chuyên nghiệp =====
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: D.border),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(color: D.primary, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.lock_person_rounded, size: 17, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text('Đăng nhập tài khoản', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text('Dùng số điện thoại đã đăng ký với Chi đoàn. Hệ thống tự nhận diện vai trò và phân quyền.', style: TextStyle(fontSize: 12, color: D.textMuted)),
                    const SizedBox(height: 14),
                    DTextField(
                      controller: phoneCtrl,
                      label: 'Số điện thoại',
                      hint: 'VD: 0912.345.678',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    // OTP
                    Text('Mã xác thực OTP', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: otpCtrl,
                            maxLength: 6,
                            obscureText: obscureOtp,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 6, color: D.primary),
                            decoration: InputDecoration(
                              counterText: '',
                              isDense: true,
                              hintText: '• • • • • •',
                              hintStyle: const TextStyle(fontSize: 14, letterSpacing: 4, color: Color(0xFFCBD5E1), fontWeight: FontWeight.w700),
                              filled: true,
                              fillColor: D.grayBg,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: D.border)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: D.primary, width: 1.5)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => setState(() => obscureOtp = !obscureOtp),
                          child: Container(
                            height: 42,
                            width: 42,
                            decoration: BoxDecoration(color: D.light, borderRadius: BorderRadius.circular(12)),
                            child: Icon(obscureOtp ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18, color: D.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 12, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(demoOtpHint(),
                              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    PrimaryButton(
                      loggingIn ? 'Đang xác thực qua máy chủ…' : 'Đăng nhập',
                      icon: loggingIn ? null : Icons.arrow_forward_rounded,
                      onPressed: loggingIn ? null : () => _handleBackendLogin(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // RBAC note
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: D.light, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, size: 16, color: D.primary),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('Phân quyền RBAC: vai trò được gán theo tài khoản trên máy chủ — không thể tự chọn.',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: D.primary)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(width: 128, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(4))),
              ),
            ] else ...[
              DTextField(controller: regName, label: 'Họ và tên *', hint: 'VD: Nguyễn Minh Tâm'),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: DTextField(controller: regPhone, label: 'Số điện thoại *', hint: '09xx.xxx.xxx', keyboardType: TextInputType.phone)),
                  const SizedBox(width: 10),
                  Expanded(child: DTextField(controller: regMemberCode, label: 'Mã đoàn viên')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: DTextField(controller: regJoinDate, label: 'Ngày vào Đoàn')),
                  const SizedBox(width: 10),
                  Expanded(child: DTextField(controller: regOccupation, label: 'Nghề nghiệp')),
                ],
              ),
              const SizedBox(height: 12),
              DTextField(controller: regWorkplace, label: 'Đơn vị làm việc / Nơi sinh hoạt'),
              const SizedBox(height: 14),
              PrimaryButton('Hoàn tất đăng ký & Đăng nhập', icon: Icons.check_circle_rounded, onPressed: _submitRegister),
            ],
          ],
        ),
      ),
    );
  }

  Widget _segment(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 3)] : null,
          ),
          child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: active ? D.primary : const Color(0xFF475569))),
        ),
      ),
    );
  }
}
