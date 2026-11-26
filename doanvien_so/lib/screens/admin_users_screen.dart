import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../ui.dart';

/// Quản trị tài khoản (chỉ Cán bộ Đoàn phường — quyền user:manage phía server):
/// xem toàn bộ tài khoản thành viên và đổi vai trò (member / secretary / ward_officer).
/// Vai trò luôn do máy chủ gán — đây là con đường quản trị chính thức, mọi thay đổi ghi AuditLog.
const screenAdminUsers = 'admin_users';

class AdminUsersScreen extends StatefulWidget {
  final AppState state;
  const AdminUsersScreen({super.key, required this.state});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  bool _changing = false;
  String _query = '';
  final _searchCtrl = TextEditingController();

  static const _roleLabels = {
    'member': 'Đoàn viên',
    'secretary': 'Bí thư chi đoàn',
    'ward_officer': 'Cán bộ Đoàn phường',
  };
  static const _roleColors = {
    'member': Color(0xFF059669),
    'secretary': Color(0xFF161891),
    'ward_officer': Color(0xFFB45309),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final users = await widget.state.fetchBackendUsers();
      if (mounted) setState(() => _users = users);
    } catch (_) {
      // lỗi đã toast trong fetchBackendUsers
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openRoleSheet(Map<String, dynamic> u) async {
    String chosen = u['role'] as String;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(4)))),
                Text('Đổi vai trò', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: D.textDark)),
                const SizedBox(height: 2),
                Text('${u['full_name']} • ${u['phone']}',
                    style: const TextStyle(fontSize: 13, color: D.textMuted)),
                const SizedBox(height: 14),
                for (final e in _roleLabels.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => setSheet(() => chosen = e.key),
                      child: Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: chosen == e.key ? D.accentLight : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: chosen == e.key ? D.primary : D.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(color: _roleColors[e.key], borderRadius: BorderRadius.circular(11)),
                              child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(e.value,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: D.textDark))),
                            if (chosen == e.key)
                              const Icon(Icons.check_circle_rounded, color: D.primary, size: 22)
                            else
                              const Icon(Icons.radio_button_unchecked_rounded, color: Color(0xFFCBD5E1), size: 22),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(color: D.light, borderRadius: BorderRadius.circular(12)),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 15, color: D.primary),
                      SizedBox(width: 8),
                      Expanded(child: Text('Vai trò có hiệu lực ngay trên máy chủ. Người dùng đăng nhập lại để cập nhật giao diện.',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: D.primary))),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: const BorderSide(color: D.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                        ),
                        child: const Text('Hủy', style: TextStyle(color: D.textMuted, fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PrimaryButton(
                        _changing ? 'Đang cập nhật…' : 'Xác nhận đổi vai trò',
                        icon: null,
                        height: 46,
                        onPressed: _changing
                            ? null
                            : () async {
                                setState(() => _changing = true);
                                final ok = await widget.state.setUserRole(u['id'] as int, chosen);
                                setState(() => _changing = false);
                                if (mounted && ok != null) {
                                  Navigator.pop(ctx);
                                  await _load();
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final users = _users
        .where((u) => _query.isEmpty ||
            (u['full_name'] as String? ?? '').toLowerCase().contains(_query) ||
            (u['phone'] as String? ?? '').contains(_query) ||
            (u['role_label'] as String? ?? '').toLowerCase().contains(_query))
        .toList();
    return Column(
      children: [
        // ===== Header =====
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Quản trị tài khoản', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: D.textDark)),
              const SizedBox(height: 2),
              Text('${_users.length} tài khoản • đổi vai trò Đoàn viên ↔ Bí thư ↔ Cán bộ phường',
                  style: const TextStyle(fontSize: 12.5, color: D.textMuted)),
              const SizedBox(height: 10),
              TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Tìm tên, số điện thoại, vai trò…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: D.textMuted),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: D.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: D.border)),
                ),
              ),
            ],
          ),
        ),
        // ===== Danh sách =====
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: D.primary))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: users.length,
                  itemBuilder: (_, i) {
                    final u = users[i];
                    final role = u['role'] as String? ?? 'member';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: D.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(color: _roleColors[role], borderRadius: BorderRadius.circular(13)),
                            child: Center(
                              child: Text((u['full_name'] as String? ?? '?').characters.first.toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(u['full_name'] ?? '',
                                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: D.textDark)),
                                const SizedBox(height: 2),
                                Text(u['phone'] ?? '',
                                    style: const TextStyle(fontSize: 12, color: D.textMuted)),
                                if (u['branch'] != null && (u['branch'] as String).isNotEmpty)
                                  Text(u['branch'], style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8))),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(color: (_roleColors[role] ?? D.primary).withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8)),
                                child: Text(u['role_label'] ?? _roleLabels[role]!,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _roleColors[role])),
                              ),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () => _openRoleSheet(u),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(color: D.light, borderRadius: BorderRadius.circular(9)),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.swap_vert_rounded, size: 13, color: D.primary),
                                      SizedBox(width: 4),
                                      Text('Đổi vai trò', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: D.primary)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
