import 'dart:async';
import 'package:flutter/material.dart';
import 'main.dart' show AppStateScope;
import 'state/app_state.dart';
import 'ui.dart';
import 'components/modals.dart';
import 'screens/login_screen.dart';
import 'screens/secretary_home.dart';
import 'screens/member_home.dart';
import 'screens/create_qr_screen.dart';
import 'screens/scan_qr_screen.dart';
import 'screens/members_screen.dart';
import 'screens/ward_dashboard.dart';
import 'screens/schedule_screen.dart';
import 'screens/rewards_screen.dart';
import 'screens/social_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/report_screen.dart';

// ====== Khu vực màn hình ======
const screenHome = 'home';
const screenCreateQr = 'create_qr';
const screenScanQr = 'scan_qr';
const screenMembers = 'members';
const screenReports = 'reports';
const screenWardDash = 'ward_dash';
const screenWardBranches = 'ward_branches';
const screenWardReports = 'ward_reports';
const screenWardRewards = 'ward_rewards';
const screenMakeup = 'makeup';
const screenRewards = 'rewards';
const screenSocial = 'social';
const screenMenu = 'menu';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppRole currentRole = AppRole.secretary;
  String activeScreen = 'login';
  String memberSubTab = 'scan';
  int exportModalTrigger = 0;
  Timer? _clock;
  Timer? _toastTimer;
  String? _lastToast;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  // Toast tự tắt sau 4 giây (kể cả khi toast mới thay toast cũ — đếm lại từ đầu)
  void _autoDismissToast(String? toast) {
    if (toast == _lastToast) return;
    _lastToast = toast;
    _toastTimer?.cancel();
    if (toast == null) return;
    _toastTimer = Timer(const Duration(seconds: 4), () {
      final app = AppStateScope.of(context);
      if (mounted && app.globalToast != null && app.globalToast == toast) {
        app.clearToast();
      }
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _toastTimer?.cancel();
    super.dispose();
  }

  void selectRoleFromLogin(AppRole role) {
    setState(() {
      currentRole = role;
      if (role == AppRole.secretary) {
        activeScreen = screenHome;
      } else if (role == AppRole.member) {
        memberSubTab = 'scan';
        activeScreen = screenHome;
      } else {
        activeScreen = screenWardDash;
      }
    });
  }

  void navigate(String target) {
    setState(() {
      if (target == 'history') {
        memberSubTab = 'history';
        activeScreen = screenScanQr;
        return;
      }
      if (target == 'scan_qr') {
        memberSubTab = 'scan';
        activeScreen = screenScanQr;
        return;
      }
      activeScreen = target;
    });
  }

  void handleNav(String tabId) {
    final state = AppStateScope.of(context);
    if (tabId == 'social') return navigate(screenSocial);
    if (tabId == 'menu') return navigate(screenMenu);
    if (tabId == 'makeup') return navigate(screenMakeup);

    if (currentRole == AppRole.member) {
      if (tabId == 'home') return navigate(screenHome);
      if (tabId == 'qr_action') {
        memberSubTab = 'scan';
        activeScreen = screenScanQr;
      } else if (tabId == 'history') {
        memberSubTab = 'history';
        activeScreen = screenScanQr;
      } else if (tabId == 'rewards') {
        activeScreen = screenRewards;
      }
      setState(() {});
      return;
    }

    if (currentRole == AppRole.wardOfficer) {
      if (tabId == 'home') return navigate(screenWardDash);
      if (tabId == 'branches') return navigate(screenWardBranches);
      if (tabId == 'export_action') {
        const wardScreens = [screenWardDash, screenWardBranches, screenWardReports, screenWardRewards];
        if (!wardScreens.contains(activeScreen)) activeScreen = screenWardDash;
        exportModalTrigger++;
        state.requestExportPreview();
        setState(() {});
        return;
      }
      if (tabId == 'reports') return navigate(screenWardReports);
      if (tabId == 'rewards') return navigate(screenWardRewards);
      setState(() {});
      return;
    }

    if (tabId == 'home') return navigate(screenHome);
    if (tabId == 'members') return navigate(screenMembers);
    if (tabId == 'qr_action') return navigate(screenCreateQr);
    if (tabId == 'reports') return navigate(screenReports);
    setState(() {});
  }

  String get activeNavTab {
    if (activeScreen == screenSocial) return 'social';
    if (activeScreen == screenMenu) return 'menu';
    if (activeScreen == screenMakeup) return 'makeup';

    if (currentRole == AppRole.member) {
      if (activeScreen == screenHome) return 'home';
      if (activeScreen == screenScanQr) return memberSubTab == 'scan' ? 'qr_action' : 'menu';
      if (activeScreen == screenRewards) return 'rewards';
      return 'menu';
    }

    if (currentRole == AppRole.wardOfficer) {
      if (activeScreen == screenWardDash) return 'home';
      if (activeScreen == screenWardBranches) return 'branches';
      if (activeScreen == screenWardReports) return 'reports';
      if (activeScreen == screenWardRewards) return 'rewards';
      return 'menu';
    }

    if (activeScreen == screenHome) return 'home';
    if (activeScreen == screenCreateQr) return 'qr_action';
    if (activeScreen == screenMembers) return 'members';
    if (activeScreen == screenReports) return 'reports';
    return 'menu';
  }

  ({String title, String subtitle, bool showBack}) get headerInfo {
    switch (activeScreen) {
      case screenHome:
        if (currentRole == AppRole.member) {
          return (title: 'Trang chủ Đoàn viên', subtitle: 'Chi đoàn Khu phố 5 • Tỉnh Đồng Nai', showBack: false);
        }
        return (title: 'Chi đoàn Khu phố 5', subtitle: 'Quản lý Đoàn vụ • Phường Trấn Biên', showBack: false);
      case screenCreateQr:
        return (title: 'Sinh hoạt & Mã QR', subtitle: 'Xác thực 2 lớp • QR động', showBack: true);
      case screenScanQr:
        return (
          title: memberSubTab == 'history' ? 'Lịch sử tham gia' : 'Quét QR Điểm danh',
          subtitle: 'Xác thực 2 lớp & Định vị GPS',
          showBack: true
        );
      case screenMembers:
        return (title: 'Danh bạ & Hồ sơ ĐV', subtitle: 'Quản lý thành viên & Chuyển sinh hoạt', showBack: true);
      case screenReports:
        return (title: 'Báo cáo Chi đoàn KP5', subtitle: 'Tổng hợp số liệu định kỳ', showBack: true);
      case screenWardDash:
        final wd = AppStateScope.of(context, listen: false);
        return (title: 'Đoàn Phường Trấn Biên', subtitle: '${wd.wardDataByMonth['11']!.totalBranches} chi đoàn • ${wd.wardDataByMonth['11']!.totalMembers} đoàn viên', showBack: false);
      case screenWardBranches:
        return (title: 'Quản lý ${AppStateScope.of(context, listen: false).wardDataByMonth['11']!.totalBranches} Chi đoàn', subtitle: 'Đoàn Phường Trấn Biên', showBack: true);
      case screenWardReports:
        return (title: 'Báo cáo Đoàn vụ', subtitle: 'Thống kê & Xuất văn bản tự động', showBack: true);
      case screenWardRewards:
        return (title: 'Thi đua & Xếp hạng', subtitle: '12 Chi đoàn trực thuộc', showBack: true);
      case screenMakeup:
        return (title: 'Lịch hoạt động cá nhân', subtitle: 'Theo dõi lịch sinh hoạt & sự kiện đã đăng ký', showBack: true);
      case screenRewards:
        return (title: 'Thi đua & Đổi quà', subtitle: 'Phong trào thanh niên & Ví Voucher', showBack: true);
      case screenSocial:
        return (title: 'Bảng tin Đoàn viên', subtitle: 'Sự kiện phát động & Hoạt động cộng đồng', showBack: true);
      case screenMenu:
        return (title: 'Menu Tiện ích', subtitle: 'Toàn bộ tính năng & dịch vụ số', showBack: false);
      default:
        return (title: 'Đoàn Viên Số', subtitle: 'Tỉnh Đồng Nai', showBack: false);
    }
  }

  void onBack() {
    setState(() {
      if (currentRole == AppRole.wardOfficer) {
        activeScreen = screenWardDash;
      } else {
        activeScreen = screenHome;
      }
    });
  }

  void jumpToScreen(String screenId) {
    setState(() {
      if (screenId == 'ward_dash') {
        currentRole = AppRole.wardOfficer;
        activeScreen = screenWardDash;
      } else if (screenId == 'scan_qr') {
        currentRole = AppRole.member;
        memberSubTab = 'scan';
        activeScreen = screenScanQr;
      } else if (screenId == 'home') {
        currentRole = AppRole.secretary;
        activeScreen = screenHome;
      } else if (screenId == 'login') {
        activeScreen = 'login';
      } else {
        activeScreen = screenId;
      }
    });
  }

  Widget _buildScreen() {
    final state = AppStateScope.of(context);
    switch (activeScreen) {
      case 'login':
        return LoginScreen(onSelectRole: selectRoleFromLogin);
      case screenHome:
        if (currentRole == AppRole.member) {
          return MemberHomeView(onNavigate: navigate);
        }
        return SecretaryHomeView(onNavigate: navigate);
      case screenCreateQr:
        return CreateSessionQrScreen(state: state, onBack: onBack);
      case screenScanQr:
        return MemberScanQrScreen(state: state, activeTab: memberSubTab, onTabChange: (t) => setState(() => memberSubTab = t), onNavigate: navigate);
      case screenMembers:
        return MemberListScreen(state: state, currentRole: currentRole, onNavigate: navigate);
      case screenReports:
        return SecretaryReportView(state: state, onBack: onBack);
      case screenWardDash:
        return WardDashboard(state: state, viewMode: 'overview');
      case screenWardBranches:
        return WardDashboard(state: state, viewMode: 'branches');
      case screenWardReports:
        return WardDashboard(state: state, viewMode: 'reports');
      case screenWardRewards:
        return WardDashboard(state: state, viewMode: 'rewards');
      case screenMakeup:
        return MakeupSessionScreen(state: state, currentRole: currentRole, onNavigate: navigate);
      case screenRewards:
        return RewardsScreen(state: state, currentRole: currentRole, onNavigate: navigate);
      case screenSocial:
        return SocialFeedScreen(state: state, currentRole: currentRole, onNavigate: navigate);
      case screenMenu:
        return UtilitiesMenuScreen(
          state: state,
          currentRole: currentRole,
          onNavigateScreen: navigate,
          onOpenRoleModal: () => showRoleSwitcherSheet(
            context,
            currentRole: currentRole,
            activeScreen: activeScreen,
            onSelectRole: selectRoleFromLogin,
            onJump: jumpToScreen,
          ),
          onOpenNotification: () => showNotificationSheet(context, currentRole),
          onOpenAdmin: () => showSystemAdminSheet(context, currentRole),
          onLogout: () { state.logoutBackend(); setState(() => activeScreen = "login"); },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final info = headerInfo;
    _autoDismissToast(state.globalToast);

    return Scaffold(
      backgroundColor: activeScreen == 'login' ? Colors.white : D.pageBg,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Column(
            children: [
              if (activeScreen != 'login') ...[
                AppHeader(
                  time: _now,
                  info: info,
                  state: state,
                  role: currentRole,
                  onBack: onBack,
                  onOpenNotification: () => showNotificationSheet(context, currentRole),
                  onOpenAdmin: () => showSystemAdminSheet(context, currentRole),
                  onLogout: () { state.logoutBackend(); setState(() => activeScreen = "login"); },
                ),
                Expanded(
                  child: _buildScreen(),
                ),
                BottomNavBar(
                  activeTab: activeNavTab,
                  onTabChange: handleNav,
                  currentRole: currentRole,
                ),
              ] else
                Expanded(child: LoginScreen(onSelectRole: selectRoleFromLogin)),
            ],
          ),
          // Global toast
          Positioned(
            top: 8,
            left: 16,
            right: 16,
            child: IgnorePointer(
              ignoring: state.globalToast == null,
              child: AnimatedOpacity(
                opacity: state.globalToast == null ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: state.globalToast != null
                    ? Material(
                        color: Colors.transparent,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 16),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(state.globalToast!, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                              ),
                              GestureDetector(
                                onTap: state.clearToast,
                                child: const Icon(Icons.close_rounded, color: Colors.white70, size: 14),
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

// ===================== HEADER =====================
class AppHeader extends StatelessWidget {
  final DateTime time;
  final ({String title, String subtitle, bool showBack}) info;
  final AppState state;
  final AppRole role;
  final VoidCallback onBack;
  final VoidCallback onOpenNotification;
  final VoidCallback onOpenAdmin;
  final VoidCallback onLogout;

  const AppHeader({super.key, required this.time, required this.info, required this.state, required this.role, required this.onBack, required this.onOpenNotification, required this.onOpenAdmin, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final roleKey = role.key;
    final unread = state.roleNotifications(roleKey).where((n) => n.unread).length;
    final offlineQueue = state.offlineQueue.length;

    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status bar mô phỏng
          SizedBox(
            height: 34,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => state.toggleOffline(!state.isOffline),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: state.isOffline ? const Color(0xFFFEF3C7) : D.light,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            children: [
                              Icon(state.isOffline ? Icons.wifi_off_rounded : Icons.wifi, size: 11, color: state.isOffline ? const Color(0xFF92400E) : D.primary),
                              const SizedBox(width: 3),
                              Text(state.isOffline ? 'Offline${offlineQueue > 0 ? ' ($offlineQueue)' : ''}' : '5G',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: state.isOffline ? const Color(0xFF92400E) : D.primary)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.battery_full_rounded, size: 15, color: Color(0xFF334155)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // AppBar
          SizedBox(
            height: 56,
            child: Row(
              children: [
                const SizedBox(width: 8),
                if (info.showBack)
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded, size: 21, color: Color(0xFF1E293B)),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: LogoBadge(size: 34, radius: 10, fontSize: 12),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(info.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                      if (info.subtitle.isNotEmpty)
                        Text(info.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: D.textMuted)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onOpenAdmin,
                  icon: const Icon(Icons.verified_user_rounded, size: 19, color: Color(0xFF475569)),
                ),
                Stack(
                  children: [
                    IconButton(
                      onPressed: onOpenNotification,
                      icon: const Icon(Icons.notifications_none_rounded, size: 21, color: Color(0xFF475569)),
                    ),
                    if (unread > 0)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          constraints: const BoxConstraints(minWidth: 15),
                          height: 15,
                          decoration: BoxDecoration(color: D.primary, borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white, width: 1.4)),
                          child: Text('$unread', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                        ),
                      ),
                  ],
                ),
                IconButton(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_rounded, size: 19, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
        ],
      ),
    );
  }

}

// ===================== BOTTOM NAV =====================
class BottomNavBar extends StatelessWidget {
  final String activeTab;
  final void Function(String) onTabChange;
  final AppRole currentRole;

  const BottomNavBar({super.key, required this.activeTab, required this.onTabChange, required this.currentRole});

  List<({String id, String label, IconData icon, bool hasDot})> _items(int myScheduleCount, int pendingMakeupCount) {
    if (currentRole == AppRole.secretary) {
      return [
        (id: 'home', label: 'Trang chủ', icon: Icons.home_rounded, hasDot: pendingMakeupCount > 0),
        (id: 'makeup', label: 'Lịch', icon: Icons.calendar_month_rounded, hasDot: myScheduleCount > 0),
        (id: 'qr_action', label: 'Mã QR', icon: Icons.qr_code_2, hasDot: false),
        (id: 'social', label: 'Bảng tin', icon: Icons.article_rounded, hasDot: false),
        (id: 'menu', label: 'Tiện ích', icon: Icons.grid_view_rounded, hasDot: false),
      ];
    } else if (currentRole == AppRole.member) {
      return [
        (id: 'home', label: 'Trang chủ', icon: Icons.home_rounded, hasDot: false),
        (id: 'makeup', label: 'Lịch', icon: Icons.calendar_month_rounded, hasDot: myScheduleCount > 0),
        (id: 'qr_action', label: 'Quét QR', icon: Icons.qr_code_scanner, hasDot: false),
        (id: 'social', label: 'Bảng tin', icon: Icons.article_rounded, hasDot: false),
        (id: 'menu', label: 'Tiện ích', icon: Icons.grid_view_rounded, hasDot: false),
      ];
    } else {
      return [
        (id: 'home', label: 'Tổng hợp', icon: Icons.home_rounded, hasDot: false),
        (id: 'makeup', label: 'Lịch', icon: Icons.calendar_month_rounded, hasDot: false),
        (id: 'branches', label: 'Chi đoàn', icon: Icons.groups_rounded, hasDot: false),
        (id: 'social', label: 'Bảng tin', icon: Icons.article_rounded, hasDot: false),
        (id: 'menu', label: 'Tiện ích', icon: Icons.grid_view_rounded, hasDot: false),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final items = _items(state.mySchedule.length, state.makeupRequests.where((r) => r.status == 'pending').length);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [BoxShadow(color: const Color(0x0A0F172A), blurRadius: 12, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (final item in items)
                Expanded(
                  child: InkWell(
                    onTap: () => onTabChange(item.id),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 46,
                          height: 26,
                          decoration: BoxDecoration(
                            color: activeTab == item.id ? D.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(item.icon, size: 19, color: activeTab == item.id ? Colors.white : const Color(0xFF64748B)),
                              if (item.hasDot && activeTab != item.id)
                                Positioned(
                                  top: 4,
                                  right: 10,
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(color: D.primary, borderRadius: BorderRadius.circular(9), border: Border.all(color: Colors.white, width: 1.4)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: activeTab == item.id ? FontWeight.w800 : FontWeight.w500,
                            color: activeTab == item.id ? D.primary : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
