import 'package:flutter/material.dart';

/// Design tokens lấy từ design/tailwind.config.js + index.css
class D {
  static const Color primary = Color(0xFF161891);
  static const Color primaryDark = Color(0xFF0E1068);
  static const Color light = Color(0xFFEEF0FB);
  static const Color accentLight = Color(0xFFF4F5FC);
  static const Color grayBg = Color(0xFFF5F7FB);
  static const Color pageBg = Color(0xFFF5F7FB);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color cardBorder = Color(0xFFEEF1F6);
  static const Color green = Color(0xFF059669);
  static const Color greenDark = Color(0xFF047857);
  static const Color greenLight = Color(0xFFECFDF5);
  static const Color rose = Color(0xFFE11D48);
  static const Color roseLight = Color(0xFFFFF1F2);
  static const Color amber = Color(0xFFB45309);
  static const Color amberLight = Color(0xFFFFFBEB);
  static const Color orange = Color(0xFFFF6B00);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF161891), Color(0xFF2024B8), Color(0xFF0D0F66)],
    stops: [0.0, 0.55, 1.0],
  );

  static ThemeData theme() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: pageBg,
      fontFamily: 'BeVietnamPro',
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: 'BeVietnamPro', bodyColor: textDark, displayColor: textDark),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.white, surfaceTintColor: Colors.transparent),
      dividerTheme: DividerThemeData(color: Colors.grey.shade100, thickness: 1, space: 1),
    );
  }
}

/// Vòng tròn avatar chữ cái đầu (mock không dùng ảnh mạng)
class DAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color bg;
  final Color fg;
  final double fontSize;
  final Border? border;
  const DAvatar({super.key, required this.name, this.size = 40, this.bg = D.light, this.fg = D.primary, this.fontSize = 14, this.border});
  String _initials(String n) {
    final parts = n.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0];
    return parts.first[0] + parts.last[0];
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: border,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(name),
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }
}

/// Badge nhỏ dạng pill
class Pill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final double fontSize;
  final EdgeInsets padding;
  const Pill(this.text, {super.key, this.bg = D.light, this.fg = D.primary, this.fontSize = 11, this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 3)});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: fontSize, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// app-card: nền trắng, bo góc 16, viền + shadow nhẹ
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? bg;
  final Border? border;
  final double radius;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.bg, this.border, this.radius = 16});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg ?? Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: border ?? Border.all(color: D.cardBorder),
        boxShadow: [
          BoxShadow(color: const Color(0x090F172A), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

/// Nút chính màu #161891
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color bg;
  final Color fg;
  final double height;
  final IconData? icon;
  final double fontSize;
  final double radius;
  const PrimaryButton(this.label, {super.key, this.onPressed, this.bg = D.primary, this.fg = Colors.white, this.height = 48, this.icon, this.fontSize = 14, this.radius = 12});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(color: onPressed == null ? bg.withValues(alpha: 0.5) : bg, borderRadius: BorderRadius.circular(radius)),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: fg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 6)],
              Flexible(
                child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nút phụ nền #EEF0FB
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color fg;
  final double height;
  final double fontSize;
  const SecondaryButton(this.label, {super.key, this.onPressed, this.icon, this.fg = D.primary, this.height = 44, this.fontSize = 13});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: fg,
          backgroundColor: D.light,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: 17, color: fg), const SizedBox(width: 6)],
            Text(label, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

/// Thẻ hero gradient Super-App
class HeroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const HeroCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: D.heroGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: D.primary.withValues(alpha: 0.28), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Ô input chung
class DTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType keyboardType;
  final bool isDense;
  final int maxLines;
  const DTextField({super.key, required this.controller, required this.label, this.hint, this.keyboardType = TextInputType.text, this.isDense = true, this.maxLines = 1});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: isDense,
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            filled: true,
            fillColor: D.grayBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: D.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: D.primary, width: 1.5)),
          ),
        ),
      ],
    );
  }
}

/// Thanh progress tròn
class DProgress extends StatelessWidget {
  final double value; // 0..1
  final double height;
  final Color color;
  final Color bg;
  const DProgress({super.key, required this.value, this.height = 8, this.color = D.primary, this.bg = const Color(0xFFE2E8F0)});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Container(color: bg),
            FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: Container(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nhãn logo (dùng ảnh assets/doantn.png thay mặt nền)
class LogoBadge extends StatelessWidget {
  final double size;
  final double radius;
  final String text;
  final double fontSize;
  const LogoBadge({super.key, this.size = 36, this.radius = 12, this.text = 'ĐV', this.fontSize = 13});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: EdgeInsets.all(size * 0.1),
      child: Image.asset('assets/doantn.png', fit: BoxFit.contain),
    );
  }
}
