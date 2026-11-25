import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api.dart';
import '../state/app_state.dart';
import '../ui.dart';

/// Trợ lý ảo AI — mở như sheet chat từ tab Tiện ích, mọi vai trò.
/// Backend /assistant/ask lọc chức năng theo quyền vai trò, trả JSON
/// {nav, answer, steps} → app vẽ câu trả lời + nút "Đi tới màn hình".
void openAssistantSheet(BuildContext context, AppState state, AppRole role, void Function(String) onNavigateScreen) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AssistantSheet(state: state, role: role, onNavigateScreen: onNavigateScreen),
  );
}

class _AssistantSheet extends StatefulWidget {
  final AppState state;
  final AppRole role;
  final void Function(String) onNavigateScreen;
  const _AssistantSheet({required this.state, required this.role, required this.onNavigateScreen});

  @override
  State<_AssistantSheet> createState() => _AssistantSheetState();
}

class _Msg {
  final bool isUser;
  final String text;
  final List<String> steps;
  final String? nav;
  final String? navLabel;
  final String source; // 'gemini' | 'fallback' | 'error'
  _Msg(this.text, {this.isUser = false, this.steps = const [], this.nav, this.navLabel, this.source = 'gemini'});
}

class _AssistantSheetState extends State<_AssistantSheet> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _messages = [];
  bool _busy = false;

  static const _suggestions = <AppRole, List<String>>{
    AppRole.member: ['Cách quét QR điểm danh', 'Xin sinh hoạt bù khi làm ca', 'Đổi voucher ở đâu?', 'Đăng bài kèm ảnh'],
    AppRole.secretary: ['Tạo buổi & phát mã QR', 'Duyệt đơn sinh hoạt bù', 'Nộp báo cáo kỳ', 'Điểm danh thủ công'],
    AppRole.wardOfficer: ['Phát động hoạt động', 'Nhắc chi đoàn nộp báo cáo', 'Xuất văn bản báo cáo', 'Xét khen thưởng'],
  };

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<dynamic> _askOnce(String q) async {
    // Lần 1 có thể vội Render từ trạng thái ngủ (cold-start); tự thử lại 1 lần
    try {
      return await widget.state.api
          .post('/assistant/ask', {'question': q}, null, const Duration(seconds: 30));
    } on TimeoutException {
      return await widget.state.api
          .post('/assistant/ask', {'question': q}, null, const Duration(seconds: 30));
    }
  }

  Future<void> _send(String q) async {
    if (_busy || q.trim().isEmpty) return;
    setState(() {
      _messages.add(_Msg(q.trim(), isUser: true));
      _busy = true;
    });
    _ctrl.clear();
    _scrollDown();
    try {
      final r = await _askOnce(q.trim());
      final steps = (r['steps'] as List<dynamic>? ?? []).whereType<String>().toList();
      setState(() => _messages.add(_Msg(
            (r['answer'] as String?) ?? 'Chưa có câu trả lời.',
            steps: steps,
            nav: r['nav'] as String?,
            navLabel: r['nav_label'] as String?,
            source: (r['source'] as String?) ?? 'fallback',
          )));
    } on ApiException catch (e) {
      setState(() => _messages.add(_Msg(
            e.statusCode == 401
                ? 'Phiên đăng nhập đã hết hạn — thoát app rồi đăng nhập lại nhé.'
                : 'Trợ lý AI chưa trả lời được (${e.message}). Thử lại sau ít phút.',
            source: 'error',
          )));
    } catch (_) {
      setState(() => _messages.add(_Msg(
            'Không kết nối được trợ lý AI. Kiểm tra mạng rồi thử lại nhé.',
            source: 'error',
          )));
    }
    _busy = false;
    if (mounted) setState(() {});
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // ===== Header =====
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: Column(
                children: [
                  Center(
                    child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(4))),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: D.light, borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.smart_toy_rounded, color: D.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Trợ lý ảo AI', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: D.textDark)),
                            SizedBox(height: 2),
                            Text('Hỏi chức năng ở đâu & cách dùng — chỉ dẫn đúng quyền của bạn',
                                style: TextStyle(fontSize: 11.5, color: D.textMuted)),
                          ],
                        ),
                      ),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, size: 22, color: D.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: D.cardBorder),

            // ===== Chat =====
            Expanded(
              child: _messages.isEmpty ? _buildIntro() : ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                itemCount: _messages.length,
                itemBuilder: (_, i) => _buildMessage(_messages[i]),
              ),
            ),

            // ===== Gợi ý nhanh =====
            if (_messages.isEmpty)
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final s in _suggestions[widget.role] ?? const <String>[])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: D.primary)),
                          backgroundColor: D.light,
                          side: BorderSide.none,
                          onPressed: () => _send(s),
                        ),
                      ),
                  ],
                ),
              ),

            // ===== Input =====
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: D.cardBorder))),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _send,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Bạn cần trợ giúp gì?',
                        hintStyle: const TextStyle(fontSize: 13.5, color: D.textMuted),
                        filled: true,
                        fillColor: D.grayBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(color: _busy ? D.border : D.primary, borderRadius: BorderRadius.circular(14)),
                    child: IconButton(
                      onPressed: _busy ? null : () => _send(_ctrl.text),
                      icon: _busy
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: D.light, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.smart_toy_rounded, color: D.primary, size: 34),
            ),
            const SizedBox(height: 14),
            const Text('Xin chào! Mình là Trợ lý Đoàn Viên Số',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: D.textDark)),
            const SizedBox(height: 6),
            const Text(
              'Hỏi mình "chức năng X ở đâu, dùng thế nào" — mình sẽ trả lời kèm nút đưa bạn thẳng tới màn hình đó.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: D.textMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(_Msg m) {
    if (m.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: D.primary, borderRadius: BorderRadius.circular(16).copyWith(bottomRight: const Radius.circular(4))),
          child: Text(m.text, style: const TextStyle(fontSize: 13.5, color: Colors.white, height: 1.35)),
        ),
      );
    }
    final isError = m.source == 'error';
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 36),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isError ? D.roseLight : D.grayBg,
          borderRadius: BorderRadius.circular(16).copyWith(bottomLeft: const Radius.circular(4)),
          border: Border.all(color: isError ? const Color(0xFFFECDD3) : D.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isError ? Icons.wifi_off_rounded : (m.source == 'gemini' ? Icons.auto_awesome_rounded : Icons.menu_book_rounded),
                    size: 13, color: isError ? D.rose : D.primary),
                const SizedBox(width: 5),
                Text(isError ? 'Lỗi kết nối' : (m.source == 'gemini' ? 'Trợ lý AI' : 'Tra cứu nhanh'),
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: isError ? D.rose : D.primary)),
              ],
            ),
            const SizedBox(height: 6),
            Text(m.text, style: const TextStyle(fontSize: 13.5, color: D.textDark, height: 1.4)),
            if (m.steps.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (var i = 0; i < m.steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 18, height: 18, margin: const EdgeInsets.only(top: 1),
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: D.primary, shape: BoxShape.circle),
                        child: Text('${i + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(m.steps[i], style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155), height: 1.35))),
                    ],
                  ),
                ),
            ],
            if (m.nav != null && m.navLabel != null) ...[
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onNavigateScreen(m.nav!);
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: Text('Đi tới: ${m.navLabel}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: D.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
