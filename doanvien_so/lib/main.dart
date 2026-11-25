import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_shell.dart';
import 'state/app_state.dart';
import 'ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const DoanVienSoApp());
}

class DoanVienSoApp extends StatelessWidget {
  const DoanVienSoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Đoàn Viên Số - Đồng Nai',
      debugShowCheckedModeBanner: false,
      theme: D.theme(),
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final AppState state = AppState();

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      state: state,
      child: const AppShell(),
    );
  }
}

/// InheritedWidget đơn giản truy cập AppState từ mọi widget
class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context, {bool listen = true}) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    if (scope == null) throw StateError('AppStateScope not found');
    return scope.notifier!;
  }
}
