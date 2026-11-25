import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/mock_data.dart';
import '../services/api.dart';
import '../data/mock_data.dart' as md;

enum AppRole { secretary, member, wardOfficer }

extension AppRoleX on AppRole {
  String get key {
    switch (this) {
      case AppRole.secretary:
        return 'secretary';
      case AppRole.member:
        return 'member';
      case AppRole.wardOfficer:
        return 'ward_officer';
    }
  }

  /// ====== MA TRẬN PHÂN QUYỀN (RBAC) — Vòng 2 ======
  /// Mỗi vai trò chỉ được thực thi đúng nhóm chức năng của mình.

  /// Đoàn viên: quét QR điểm danh bản thân
  bool get canScanQr => this == AppRole.member;
  /// Đoàn viên: tự đăng ký hoạt động vào lịch cá nhân
  bool get canRegisterSelf => this == AppRole.member;
  /// Đoàn viên: gửi đơn xin phép / sinh hoạt bù (chỉ tạo, không duyệt)
  bool get canSubmitAbsenceRequest => this == AppRole.member;

  /// Bí thư: tạo / sửa / xóa buổi sinh hoạt của chi đoàn mình
  bool get canManageBranchSessions => this == AppRole.secretary;
  /// Bí thư: phát / thu hồi mã QR điểm danh
  bool get canIssueQR => this == AppRole.secretary;
  /// Bí thư: thêm / sửa / xóa hồ sơ đoàn viên, nhập Excel, chuyển sinh hoạt
  bool get canEditMembers => this == AppRole.secretary;
  /// Bí thư: duyệt đơn xin phép & sinh hoạt bù của đoàn viên chi đoàn
  bool get canApproveBranchRequests => this == AppRole.secretary;
  /// Bí thư: tổng hợp & nộp báo cáo kỳ về Đoàn phường
  bool get canSubmitReport => this == AppRole.secretary;

  /// Cán bộ phường: phát động hoạt động toàn phường (xuất hiện trong danh mục)
  bool get canLaunchWardActivity => this == AppRole.wardOfficer;
  /// Cán bộ phường: phê duyệt báo cáo / kế hoạch của chi đoàn trực thuộc
  bool get canApproveWardPlans => this == AppRole.wardOfficer;
  /// Cán bộ phường: xem tổng hợp toàn phường (không sửa hồ sơ chi đoàn)
  bool get canViewWardOverview => this == AppRole.wardOfficer;

  /// Cán bộ (bí thư + phường): đăng bài chính thức, ghim, xóa bài vi phạm
  bool get canModerateFeed => this != AppRole.member;

  /// Tên "không gian làm việc" — hiển thị để vai trò vào là biết mình có gì
  String get spaceTitle => switch (this) {
    AppRole.secretary => 'KHÔNG GIAN QUẢN LÝ CHI ĐOÀN',
    AppRole.wardOfficer => 'KHÔNG GIAN ĐIỀU PHỐI PHƯỜNG',
    AppRole.member => 'KHÔNG GIAN CÁ NHÂN ĐOÀN VIÊN',
  };
  String get spaceDesc => switch (this) {
    AppRole.secretary => 'Tạo buổi sinh hoạt • Phát mã QR • Duyệt đơn • Danh bạ & Báo cáo',
    AppRole.wardOfficer => 'Phát động hoạt động • Duyệt chi đoàn • Xếp hạng • Xuất báo cáo phường',
    AppRole.member => 'Điểm danh QR • Lịch cá nhân • Đăng ký & đơn bù • Thi đua',
  };
}

/// State trung tâm giả lập AppContext.jsx (mock, in-memory)
class AppState extends ChangeNotifier {
  static const defaultCurrentMemberId = 'dv-01';

  List<Member> members;
  ActiveSession activeSession;
  List<String> scannedMemberIds;
  List<AttendanceHistoryItem> attendanceHistory;
  List<MakeupRequest> makeupRequests;
  Map<String, List<AppNotification>> notifications;
  List<RewardVoucher> vouchers;
  List<RewardItem> rewardItems;
  List<VolunteerActivity> volunteerActivities;
  List<String> registeredVolunteerIds;
  List<String> volunteerCheckedInIds;
  Map<String, Map<String, String>> volunteerProofs;
  final Map<String, MonthWardData> wardDataByMonth;
  bool kp5ReportSubmitted;
  List<OfflineItem> offlineQueue;
  List<SocialPost> socialPosts;
  List<TransferRequest> transferRequests;
  List<DigitalBadge> digitalBadges;
  List<Map<String, dynamic>> sessionArchive;
  List<AuditLog> auditLogs;
  List<ScheduleItem> mySchedule;
  List<ScheduleItem> scheduleCatalog;
  Map<String, bool> securitySettings;
  List<String> registeredMakeupIds;
  int volunteerRegistrationCounter = 0;

  bool isOffline = false;
  String? globalToast;
  Map<String, String>? preselectedSocialEvent;
  int exportTrigger = 0; // trigger mở modal xem trước báo cáo (Cán bộ Phường)

  void requestExportPreview() {
    exportTrigger++;
    notifyListeners();
  }

  void consumeExportPreview() {
    exportTrigger = 0;
    notifyListeners();
  }

  AppState()
      : members = List.of(mockMembers),
        activeSession = defaultActiveSession,
        scannedMemberIds = List.of(initialScannedMemberIds),
        attendanceHistory = List.of(initialMemberAttendanceHistory),
        makeupRequests = List.of(initialMakeupRequests),
        notifications = {
          for (final e in initialNotifications.entries) e.key: List.of(e.value),
        },
        vouchers = [],
        rewardItems = List.of(md.rewardItems),
        volunteerActivities = List.of(md.volunteerActivities),
        registeredVolunteerIds = [],
        volunteerCheckedInIds = [],
        volunteerProofs = {},
        wardDataByMonth = md.wardDataByMonth,
        kp5ReportSubmitted = false,
        offlineQueue = [],
        socialPosts = List.of(initialSocialPosts),
        transferRequests = List.of(initialTransferRequests),
        digitalBadges = List.of(md.digitalBadges),
        sessionArchive = List.of(md.sessionArchive),
        auditLogs = List.of(initialAuditLogs),
        mySchedule = List.of(initialMySchedule),
        scheduleCatalog = List.of(md.scheduleCatalog),
        securitySettings = {'maskPhone': false, 'twoFactorAuth': true, 'encryptOffline': true},
        registeredMakeupIds = [];

  Member? _member(String id) {
    for (final m in members) {
      if (m.id == id) return m;
    }
    return null;
  }

  Member get currentMember =>
      _member(backendMemberId?.toString() ?? defaultCurrentMemberId) ?? members.first;
  int get userPoints => currentMember.points;
  int get scannedCount => scannedMemberIds.length;

  List<AppNotification> roleNotifications(String roleKey) => notifications[roleKey] ?? [];

  // ===== Toast =====
  void showToast(String? msg) {
    globalToast = msg;
    notifyListeners();
  }

  void clearToast() {
    globalToast = null;
    notifyListeners();
  }

  void toggleOffline(bool v) {
    isOffline = v;
    if (!isOffline && offlineQueue.isNotEmpty) {
      final count = offlineQueue.length;
      _syncOfflineQueueInternal();
      showToast('Đã kết nối mạng 5G & tự động đồng bộ $count lượt điểm danh ngoại tuyến!');
    }
    notifyListeners();
  }

  // ===== QR động =====
  void rotateQRToken() {
    activeSession.qrSeed++;
    if (useApi && RegExp(r'^\d+$').hasMatch(activeSession.id)) {
      // Backend thật: server cấp mã + vô hiệu mã cũ (anti-replay)
      api.post('/sessions/${activeSession.id}/qr').then((r) {
        activeSession.qrToken = r['token'];
        activeSession.refreshSeconds = _intOf(r['expires_in_s']);
        notifyListeners();
      }).catchError((e) {
        showToast(e is ApiException ? e.message : 'Không phát được mã từ máy chủ — đang dùng mã cục bộ.');
      });
      notifyListeners();
      return;
    }
    final rnd = Random();
    activeSession.qrToken =
        'KP5-${rnd.nextInt(9000) + 1000}-${(rnd.nextInt(1296) + 46656).toRadixString(36).substring(1).toUpperCase()}';
    notifyListeners();
  }

  void updateActiveSession(Map<String, dynamic> updates, {bool isNewSession = false}) {
    final title = (updates['title'] as String?) ?? activeSession.title;
    final date = (updates['date'] as String?) ?? activeSession.date;
    final location = (updates['location'] as String?) ?? activeSession.location;
    activeSession = ActiveSession(
      id: isNewSession ? 'ses-${DateTime.now().millisecondsSinceEpoch}' : activeSession.id,
      title: title,
      date: date,
      location: location,
      format: (updates['format'] as String?) ?? activeSession.format,
      refreshSeconds: (updates['refreshSeconds'] as int?) ?? activeSession.refreshSeconds,
      geofenceRequired: (updates['geofenceRequired'] as bool?) ?? activeSession.geofenceRequired,
      allowShiftCatchup: (updates['allowShiftCatchup'] as bool?) ?? activeSession.allowShiftCatchup,
      expectedCount: activeSession.expectedCount,
      qrToken: 'KP5-2026-${Random().nextInt(9000) + 1000}',
      qrSeed: activeSession.qrSeed + 1,
    );
    if (isNewSession) {
      scannedMemberIds = [];
      notifications['member']!.insert(
        0,
        AppNotification(
          id: 'noti-ses-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Lịch sinh hoạt mới: ${activeSession.title}',
          content: '${activeSession.date} tại ${activeSession.location}. Đã mở mã QR điểm danh.',
          time: 'Vừa xong',
          type: 'event',
          unread: true,
        ),
      );
    }
    notifyListeners();
  }

  // ===== Điểm danh QR đoàn viên =====
  Future<Map<String, dynamic>> recordMemberQRCheckIn({int distanceMeters = 35}) async {
    final sessionId = activeSession.id;
    final myId = currentMember.id;
    final alreadyScanned = scannedMemberIds.contains(myId);
    final alreadyQueued = offlineQueue.any((q) => q.memberId == myId && q.sessionId == sessionId);
    if (alreadyScanned || alreadyQueued) return {'ok': false, 'reason': 'already_checked_in', 'message': 'Bạn đã điểm danh buổi này rồi.'};

    // --- Backend thật: kiểm tra token + geofence phía server ---
    if (useApi && RegExp(r'^\d+$').hasMatch(sessionId)) {
      try {
        // Làm mới token trước khi gửi: mã QR chỉ sống 55s, lấy mã hợp lệ mới nhất
        try {
          final sess = await api.get('/sessions') as List;
          final open = sess.whereType<Map>().where((s) => s['is_open'] == true).toList();
          if (open.isNotEmpty) {
            final tok = open.first['current_qr_token'] as String?;
            final id = open.first['id'];
            if (tok != null) {
              activeSession = ActiveSession(
                id: '$id', title: activeSession.title, date: activeSession.date,
                location: activeSession.location, format: 'hybrid',
                refreshSeconds: 55, geofenceRequired: true, allowShiftCatchup: true,
                expectedCount: activeSession.expectedCount, qrToken: tok, qrSeed: activeSession.qrSeed,
              );
            }
          }
        } on ApiException catch (_) {}
        final r = await api.post('/sessions/$sessionId/checkin', {
          'token': activeSession.qrToken,
          'lat': 10.95682, // vị trí mô phỏng: trong phạm vi ~35m của Nhà văn hóa KP5
          'lng': 106.8244,
        });
        final now = DateTime.now();
        final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
        _applyCheckIn(myId, timeStr, 'Xác thực 2 lớp server-side: QR động + Geofence (${distanceMeters}m)', 'Vừa hoàn thành');
        notifyListeners();
        return {'ok': true, 'timestamp': timeStr, 'message': r['message'] ?? 'Điểm danh thành công!'};
      } on ApiException catch (e) {
        notifyListeners();
        return {'ok': false, 'reason': e.statusCode == 403 ? 'geofence' : 'error', 'message': e.message};
      }
    }

    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')} - 28/11/2026';

    if (isOffline) {
      offlineQueue.insert(
        0,
        OfflineItem(
          id: 'off-${DateTime.now().millisecondsSinceEpoch}',
          memberId: myId,
          memberName: currentMember.name,
          sessionId: sessionId,
          sessionTitle: activeSession.title,
          timestamp: timeStr,
          points: 10,
          typeLabel: 'QR Động + GPS (${distanceMeters}m) - Lưu ngoại tuyến',
        ),
      );
      notifyListeners();
      return {'ok': true, 'offline': true, 'timestamp': timeStr};
    }

    _applyCheckIn(myId, timeStr, 'Xác thực 2 lớp: QR Động ${activeSession.refreshSeconds}s + GPS Geofencing (${distanceMeters}m)', 'Vừa hoàn thành');
    notifications['secretary']!.insert(
      0,
      AppNotification(
        id: 'noti-qr-${DateTime.now().millisecondsSinceEpoch}',
        title: '${currentMember.name} đã điểm danh QR',
        content: 'Vừa quét mã QR động hợp lệ (GPS cách ${distanceMeters}m) cho buổi "${activeSession.title}".',
        time: 'Vừa xong',
        type: 'event',
        unread: true,
      ),
    );
    notifyListeners();
    return {'ok': true, 'offline': false, 'timestamp': timeStr};
  }

  Map<String, dynamic> markManualAttendance(String memberId, String exceptionReason) {
    final member = _member(memberId);
    if (member == null) return {'ok': false};
    final sessionId = activeSession.id;
    if (scannedMemberIds.contains(memberId) || offlineQueue.any((q) => q.memberId == memberId && q.sessionId == sessionId)) {
      return {'ok': false, 'reason': 'already_checked_in'};
    }
    if (isOffline) {
      offlineQueue.insert(
        0,
        OfflineItem(
          id: 'off-man-${DateTime.now().millisecondsSinceEpoch}',
          memberId: memberId,
          memberName: member.name,
          sessionId: sessionId,
          sessionTitle: activeSession.title,
          timestamp: '28/11/2026',
          points: 10,
          typeLabel: 'Bí thư xác nhận ngoại lệ ($exceptionReason) - Ngoại tuyến',
        ),
      );
      notifyListeners();
      return {'ok': true, 'offline': true, 'memberName': member.name};
    }
    _applyCheckIn(memberId, '28/11/2026', 'Xác nhận ngoại lệ bởi Bí thư KP5: $exceptionReason', 'Bí thư xác nhận');
    auditLogs.insert(0, AuditLog(id: 'log-man-${DateTime.now().millisecondsSinceEpoch}', actor: 'Nguyễn Văn An (Bí thư KP5)', action: 'Xác nhận điểm danh ngoại lệ cho ${member.name} ($exceptionReason)', time: 'Vừa xong'));
    notifyListeners();
    return {'ok': true, 'offline': false, 'memberName': member.name};
  }

  void _applyCheckIn(String memberId, String date, String type, String badge) {
    scannedMemberIds.add(memberId);
    for (final m in members) {
      if (m.id == memberId) {
        m.points += 10;
      }
    }
    if (memberId == defaultCurrentMemberId) {
      attendanceHistory.insert(
        0,
        AttendanceHistoryItem(
          id: 'att-${activeSession.id}',
          sessionName: activeSession.title,
          date: date,
          status: 'attended',
          badge: badge,
          pointsEarned: '+10 điểm',
          type: type,
        ),
      );
    }
    _incrementKP5InWard(1);
  }

  void _incrementKP5InWard(int delta) {
    if (delta <= 0) return;
    final month11 = wardDataByMonth['11'];
    if (month11 == null) return;
    for (final b in month11.branchesRank) {
      if (b.id == 'kp5') {
        b.attended = min(b.attended + delta, b.total);
        b.rate = ((b.attended / b.total) * 1000).round() / 10;
      }
    }
    month11.branchesRank.sort((a, b) => b.rate.compareTo(a.rate));
    final totalAttended = month11.branchesRank.fold<int>(0, (s, b) => s + b.attended);
    final totalMembers = month11.branchesRank.fold<int>(0, (s, b) => s + b.total);
    month11.averageAttendanceRate = '${(totalAttended / totalMembers * 100).toStringAsFixed(1)}%';
  }

  void _syncOfflineQueueInternal() {
    if (offlineQueue.isEmpty) return;
    int syncedCount = 0;
    final queue = List.of(offlineQueue);
    for (final item in queue) {
      if (item.sessionId == activeSession.id && !scannedMemberIds.contains(item.memberId)) {
        _applyCheckIn(item.memberId, item.timestamp, 'QR Động + GPS (Đồng bộ từ ngoại tuyến)', 'Đã đồng bộ');
        syncedCount++;
      }
    }
    offlineQueue = [];
    if (syncedCount > 0) {
      notifications['secretary']!.insert(0, AppNotification(id: 'noti-sync-${DateTime.now().millisecondsSinceEpoch}', title: 'Đồng bộ $syncedCount lượt điểm danh ngoại tuyến', content: 'Dữ liệu lưu cục bộ khi mất sóng đã được đồng bộ lên danh sách Chi đoàn KP5.', time: 'Vừa xong', type: 'event', unread: true));
      notifications['member']!.insert(0, AppNotification(id: 'noti-mem-sync-${DateTime.now().millisecondsSinceEpoch}', title: 'Đã đồng bộ điểm danh ngoại tuyến', content: 'Lượt điểm danh lưu trên máy đã đồng bộ thành công và cộng +10 điểm rèn luyện.', time: 'Vừa xong', type: 'event', unread: true));
    }
    notifyListeners();
  }

  void syncOfflineQueue() {
    _syncOfflineQueueInternal();
    showToast('Đã đồng bộ toàn bộ hàng đợi ngoại tuyến!');
  }

  // ===== Đơn ca bù =====
  Map<String, dynamic> registerMakeupSession(MakeupSession session) {
    if (registeredMakeupIds.contains(session.id)) {
      return {'ok': false, 'reason': 'already_registered'};
    }
    registeredMakeupIds.add(session.id);
    notifications['secretary']!.insert(
      0,
      AppNotification(
        id: 'noti-mk-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Đơn đăng ký ca bù mới: ${currentMember.name}',
        content: 'Đã đăng ký "${session.title}" tại ${session.branchName}.',
        time: 'Vừa xong',
        type: 'makeup',
        unread: true,
      ),
    );
    makeupRequests.insert(
      0,
      MakeupRequest(
        id: 'req-${DateTime.now().millisecondsSinceEpoch}',
        memberId: defaultCurrentMemberId,
        memberName: currentMember.name,
        workplace: currentMember.workplace,
        shift: currentMember.shift,
        sessionName: activeSession.title,
        registeredMakeup: '${session.branchName} (${session.time})',
        reason: 'Đăng ký sinh hoạt bù ca kíp (${currentMember.shift}) trên ứng dụng Đoàn Viên Số.',
        proof: 'Xác nhận ca làm việc KCN Thạnh Phú',
        status: 'pending',
      ),
    );
    notifyListeners();
    return {'ok': true};
  }

  Map<String, dynamic> completeELearningQuiz(int score, int total) {
    if (score < 2) return {'passed': false};
    final alreadyCompleted = registeredMakeupIds.contains('mk-03');
    if (!alreadyCompleted) {
      currentMember.points += 10;
      currentMember.makeupCount++;
      currentMember.status = 'active';
      attendanceHistory.insert(0, AttendanceHistoryItem(id: 'el-${DateTime.now().millisecondsSinceEpoch}', sessionName: 'E-Learning: Kỹ năng số & Chuyển đổi số Đồng Nai', date: '28/11/2026', status: 'makeup', badge: 'E-Learning Đạt', pointsEarned: '+10 điểm', type: 'Hoàn thành trắc nghiệm ($score/$total câu đúng) • Mã DN-EL-2026-8831'));
      registeredMakeupIds.add('mk-03');
      notifications['secretary']!.insert(0, AppNotification(id: 'noti-el-${DateTime.now().millisecondsSinceEpoch}', title: '${currentMember.name} đạt chứng chỉ E-Learning', content: 'Hoàn thành $score/$total câu trắc nghiệm Chuyển đổi số Đồng Nai (Mã DN-EL-2026-8831).', time: 'Vừa xong', type: 'makeup', unread: true));
    }
    notifyListeners();
    return {'passed': true, 'pointsAwarded': !alreadyCompleted};
  }

  void handleMakeupRequestAction(String reqId, String action) {
    final req = makeupRequests.firstWhere((r) => r.id == reqId, orElse: () => makeupRequests.first);
    if (req.status == 'approved') return;
    final backendReqId = _backendIdOf(req.id);
    if (useApi && backendReqId != null) {
      _apiFire(api.post('/requests/$backendReqId/decide', {'action': action == 'approve' ? 'approve' : action == 'reject' ? 'reject' : 'clarify'}),
          okMsg: 'Đã ghi nhận quyết định vào hệ thống!');
    }
    if (action == 'approve') {
      req.status = 'approved';
      for (final m in members) {
        if (m.id == req.memberId) {
          if (!req.autoPointsAwarded) m.points += 10;
          m.makeupCount = req.autoPointsAwarded ? m.makeupCount : m.makeupCount + 1;
          m.status = 'active';
          for (int i = m.attendanceHistory.length - 1; i >= 0; i--) {
            if (m.attendanceHistory[i].status == 'absent') {
              m.attendanceHistory[i] = AttendanceRec(m.attendanceHistory[i].month, 'makeup', 'Đã duyệt SH bù');
              break;
            }
          }
          break;
        }
      }
      if (req.memberId == currentMember.id) {
        notifications['member']!.insert(0, AppNotification(id: 'noti-app-${DateTime.now().millisecondsSinceEpoch}', title: 'Bí thư KP5 đã duyệt đơn sinh hoạt bù!', content: 'Đơn "${req.registeredMakeup}" của đồng chí đã được phê duyệt và ghi nhận chuyên cần.', time: 'Vừa xong', type: 'makeup', unread: true));
      }
      _incrementKP5InWard(1);
    } else {
      req.status = 'clarify_requested';
      if (req.memberId == currentMember.id) {
        notifications['member']!.insert(0, AppNotification(id: 'noti-cl-${DateTime.now().millisecondsSinceEpoch}', title: 'Bí thư KP5 yêu cầu bổ sung minh chứng', content: 'Đề nghị đồng chí bổ sung xác nhận lịch ca làm việc cho "${req.registeredMakeup}".', time: 'Vừa xong', type: 'makeup', unread: true));
      }
    }
    notifyListeners();
  }

  void sendMemberMakeupReminder(Member member) {
    notifications['member']!.insert(0, AppNotification(id: 'noti-mrem-${DateTime.now().millisecondsSinceEpoch}', title: 'Nhắc hẹn Đăng ký Sinh hoạt Bù KCN', content: 'Bí thư Chi đoàn KP5 gửi lời mời Đ/c ${member.name} (${member.workplace}) đăng ký lớp Sinh hoạt bù hoặc học E-Learning trực tuyến.', time: 'Vừa xong', type: 'makeup', unread: true));
    notifyListeners();
  }

  void submitAbsenceRequest({required String sessionTitle, required String reason, required String proof, required String preferredMakeup}) {
    makeupRequests.insert(0, MakeupRequest(id: 'req-abs-${DateTime.now().millisecondsSinceEpoch}', memberId: currentMember.id, memberName: currentMember.name, workplace: currentMember.workplace, shift: currentMember.shift, sessionName: sessionTitle, registeredMakeup: preferredMakeup, reason: reason, proof: proof, status: 'pending'));
    if (useApi) {
      _apiFire(api.post('/requests', {'session_title': sessionTitle, 'reason': reason, 'proof': proof}),
          okMsg: 'Đã gửi đơn lên Bí thư Chi đoàn qua hệ thống!');
    }
    notifications['secretary']!.insert(0, AppNotification(id: 'noti-abs-${DateTime.now().millisecondsSinceEpoch}', title: 'Đơn xin vắng & ca bù: ${currentMember.name}', content: 'Lý do: $reason (${currentMember.shift}).', time: 'Vừa xong', type: 'makeup', unread: true));
    auditLogs.insert(0, AuditLog(id: 'log-abs-${DateTime.now().millisecondsSinceEpoch}', actor: currentMember.name, action: 'Gửi đơn xin vắng mặt trực tuyến ($sessionTitle)', time: 'Vừa xong'));
    notifyListeners();
  }

  // ===== Cán bộ Đoàn Phường =====
  void remindBranchReport(String monthKey, String branchId) {
    final monthData0 = wardDataByMonth[monthKey];
    String? localName;
    if (monthData0 != null) {
      for (final b in monthData0.branchesRank) {
        if (b.id == branchId) localName = b.name;
      }
    }
    final bid = backendBranchIdByName[localName ?? ''] ?? _backendIdOf(branchId);
    if (useApi && bid != null) {
      _apiFire(api.post('/ward/branches/$bid/remind'), okMsg: 'Đã gửi nhắc qua Zalo (server)!');
    }
    final monthData = wardDataByMonth[monthKey];
    if (monthData == null) return;
    BranchRank? branch;
    for (final b in monthData.branchesRank) {
      if (b.id == branchId) {
        b.reminded = true;
        branch = b;
      }
    }
    if (branch == null) return;
    notifications['secretary']!.insert(0, AppNotification(id: 'noti-rem-${DateTime.now().millisecondsSinceEpoch}', title: 'Đoàn Phường nhắc báo cáo ${monthData.monthLabel}', content: 'BCH Đoàn Phường Tam Hiệp đề nghị ${branch.name} hoàn tất gửi số liệu sinh hoạt tháng.', time: 'Vừa xong', type: 'report', unread: true));
    notifyListeners();
  }

  void submitBranchReportToWard() {
    kp5ReportSubmitted = true;
    if (useApi) {
      _apiFire(api.post('/ward/reports'), okMsg: 'Đã nộp báo cáo kỳ lên Đoàn Phường (server)!');
    }
    final month11 = wardDataByMonth['11']!;
    for (final b in month11.branchesRank) {
      if (b.id == 'kp5') b.status = 'submitted';
    }
    notifications['ward_officer']!.insert(0, AppNotification(id: 'noti-sub-${DateTime.now().millisecondsSinceEpoch}', title: 'Chi đoàn KP5 đã gửi báo cáo số hóa', content: 'Bí thư Nguyễn Văn An đã chốt số liệu sinh hoạt KP5 (46 ĐV) gửi Đoàn Phường Tam Hiệp.', time: 'Vừa xong', type: 'report', unread: true));
    notifyListeners();
  }

  // ===== Thi đua & Quà =====
  Map<String, dynamic> redeemReward(RewardItem reward) {
    if (reward.available <= 0) return {'ok': false, 'outOfStock': true};
    if (userPoints < reward.points) return {'ok': false, 'missing': reward.points - userPoints};
    final code = 'DN-KCN-2026-${Random().nextInt(9000) + 1000}';
    final voucher = RewardVoucher(title: reward.title, sponsor: reward.sponsor, code: code, createdAt: '28/11/2026', expiresAt: '31/12/2026', pickupLocation: 'Văn phòng Công đoàn Các KCN Đồng Nai (Đường 3A, KCN Biên Hòa 2)');
    currentMember.points -= reward.points;
    reward.available--;
    vouchers.insert(0, voucher);
    final vid = _backendIdOf(reward.id);
    if (useApi && vid != null) {
      _apiFire(api.post('/rewards/vouchers/$vid/redeem'), okMsg: 'Đã ghi nhận đổi voucher trên hệ thống!');
    }
    notifications['member']!.insert(0, AppNotification(id: 'noti-vch-${DateTime.now().millisecondsSinceEpoch}', title: 'Đổi Voucher thành công: ${reward.title}', content: 'Mã nhận quà: $code. Đã lưu vào Ví Voucher của bạn.', time: 'Vừa xong', type: 'reward', unread: true));
    notifyListeners();
    return {'ok': true, 'voucher': voucher};
  }

  Map<String, dynamic> toggleVolunteerRegistration(String activityId) {
    VolunteerActivity? act;
    for (final a in volunteerActivities) {
      if (a.id == activityId) act = a;
    }
    if (act == null || act.status != 'upcoming') return {'ok': false};
    final isRegistered = registeredVolunteerIds.contains(activityId);
    if (isRegistered) {
      registeredVolunteerIds.remove(activityId);
      act.participantsCount--;
    } else {
      registeredVolunteerIds.add(activityId);
      act.participantsCount++;
      notifications['member']!.insert(0, AppNotification(id: 'noti-vol-${DateTime.now().millisecondsSinceEpoch}', title: 'Đã đăng ký: ${act.title}', content: 'Thời gian: ${act.date} tại ${act.location}. Hệ thống sẽ nhắc lịch trước 24h (${act.points} dự kiến).', time: 'Vừa xong', type: 'event', unread: true));
    }
    notifyListeners();
    return {'ok': true, 'registered': !isRegistered, 'activity': act};
  }

  Map<String, dynamic> checkInVolunteerQR(String activityId) {
    if (volunteerCheckedInIds.contains(activityId)) return {'ok': false};
    VolunteerActivity? act;
    for (final a in volunteerActivities) {
      if (a.id == activityId) act = a;
    }
    final pts = act?.pointsValue ?? 20;
    volunteerCheckedInIds.add(activityId);
    currentMember.points += pts;
    auditLogs.insert(0, AuditLog(id: 'log-vqr-${DateTime.now().millisecondsSinceEpoch}', actor: currentMember.name, action: 'Quét QR điểm danh hoạt động "${act?.title ?? activityId}" (+${pts}đ)', time: 'Vừa xong'));
    notifyListeners();
    return {'ok': true, 'points': pts, 'activity': act};
  }

  void submitVolunteerProof(String activityId, {required String note, required String imageUrl}) {
    volunteerProofs[activityId] = {'note': note, 'imageUrl': imageUrl, 'submittedAt': 'Vừa xong'};
    auditLogs.insert(0, AuditLog(id: 'log-proof-${DateTime.now().millisecondsSinceEpoch}', actor: currentMember.name, action: 'Gửi ảnh/video minh chứng hoạt động', time: 'Vừa xong'));
    notifyListeners();
  }

  void awardBonusPoints(String memberId, int points, String? badgeId, String reason) {
    for (final m in members) {
      if (m.id == memberId) m.points += points;
    }
    if (badgeId != null) {
      for (final b in digitalBadges) {
        if (b.id == badgeId) {
          b.earned = true;
          b.earnedAt = '28/11/2026';
        }
      }
    }
    if (memberId == defaultCurrentMemberId) {
      notifications['member']!.insert(0, AppNotification(id: 'noti-aw-${DateTime.now().millisecondsSinceEpoch}', title: 'Được thưởng +$points điểm thành tích', content: reason, time: 'Vừa xong', type: 'reward', unread: true));
    }
    auditLogs.insert(0, AuditLog(id: 'log-aw-${DateTime.now().millisecondsSinceEpoch}', actor: 'Cán bộ Đoàn', action: 'Xác nhận cộng +${points}đ cho $memberId ($reason)', time: 'Vừa xong'));
    notifyListeners();
  }

  void createVolunteerActivity({required String title, required String date, required String location, required int pointsValue}) {
    volunteerActivities.insert(0, VolunteerActivity(id: 'act-${DateTime.now().millisecondsSinceEpoch}', title: title, date: date, location: location, points: '+$pointsValue điểm', pointsValue: pointsValue, participantsCount: 1, status: 'upcoming'));
    notifications['member']!.insert(0, AppNotification(id: 'noti-nact-${DateTime.now().millisecondsSinceEpoch}', title: 'Hoạt động phong trào mới: $title', content: '$date tại $location (+$pointsValue điểm). Đăng ký tham gia ngay!', time: 'Vừa xong', type: 'event', unread: true));
    auditLogs.insert(0, AuditLog(id: 'log-nact-${DateTime.now().millisecondsSinceEpoch}', actor: 'Nguyễn Văn An (Bí thư KP5)', action: 'Đăng tải hoạt động mới "$title"', time: 'Vừa xong'));
    notifyListeners();
  }

  // ===== Hồ sơ & chuyển SH =====
  void registerNewAccount(Map<String, String> accountData) {
    final nextNum = members.length + 1;
    members.insert(
      0,
      Member(
        id: 'dv-reg-${DateTime.now().millisecondsSinceEpoch}',
        name: accountData['name']!,
        phone: accountData['phone']!,
        type: accountData['type'] ?? 'local',
        workplace: accountData['workplace'] ?? 'Phường Tam Hiệp, TP. Biên Hòa',
        shift: accountData['shift'] ?? 'Hành chính',
        lastAttended: '24/11/2026',
        points: 80,
        makeupCount: 0,
        status: 'active',
        memberCode: accountData['memberCode'] ?? 'ĐV-DN-${nextNum.toString().padLeft(3, '0')}',
        joinDate: accountData['joinDate'] ?? '26/03/2024',
        occupation: accountData['occupation'] ?? 'Đoàn viên Thanh niên',
        branchName: accountData['branchName'] ?? 'Chi đoàn Khu phố 5',
        attendanceHistory: [const AttendanceRec('Tháng 11', 'present', 'Mới đăng ký')],
      ),
    );
    auditLogs.insert(0, AuditLog(id: 'log-reg-${DateTime.now().millisecondsSinceEpoch}', actor: accountData['name']!, action: 'Đăng ký tài khoản Đoàn viên mới', time: 'Vừa xong'));
    notifyListeners();
  }

  void createMemberProfile(Map<String, dynamic> input) {
    final nextNum = members.length + 1;
    members.insert(0, Member(
      id: 'dv-new-${DateTime.now().millisecondsSinceEpoch}',
      name: input['name'],
      phone: input['phone'] ?? '',
      type: input['type'] ?? 'local',
      workplace: input['workplace'] ?? 'Khu phố 5, Tam Hiệp',
      shift: input['shift'] ?? 'Hành chính',
      lastAttended: 'Chưa tham gia',
      points: 75,
      makeupCount: 0,
      status: 'active',
      memberCode: input['memberCode'] ?? 'ĐV-DN-${nextNum.toString().padLeft(3, '0')}',
      joinDate: input['joinDate'] ?? '26/03/2023',
      occupation: input['occupation'] ?? 'Lao động trẻ',
      branchName: 'Chi đoàn Khu phố 5',
      attendanceHistory: [const AttendanceRec('Tháng 11', 'present', 'Hồ sơ mới')],
    ));
    auditLogs.insert(0, AuditLog(id: 'log-new-${DateTime.now().millisecondsSinceEpoch}', actor: 'Nguyễn Văn An (Bí thư KP5)', action: 'Tạo mới hồ sơ ĐV ${input['name']}', time: 'Vừa xong'));
    if (useApi) {
      _apiFire(api.post('/members', {'name': input['name'], 'phone': input['phone'] ?? '', 'type': input['type'] ?? 'local', 'workplace': input['workplace'] ?? '', 'shift': input['shift'] ?? ''}),
          okMsg: 'Đã tạo hồ sơ trên hệ thống!');
    }
    notifyListeners();
  }

  void updateMemberProfile(String memberId, Map<String, String?> updates) {
    for (final m in members) {
      if (m.id == memberId) {
        if (updates['phone'] != null) m.phone = updates['phone']!;
        break;
      }
    }
    final bid = _backendIdOf(memberId);
    if (useApi && bid != null) {
      _apiFire(api.patch('/members/$bid', {'phone': updates['phone'] ?? ''}));
    }
    notifyListeners();
  }

  void importMembersBatch(List<Map<String, dynamic>> batchList) {
    final baseIndex = members.length + 1;
    for (int i = 0; i < batchList.length; i++) {
      final item = batchList[i];
      members.insert(0, Member(
        id: 'dv-imp-${DateTime.now().millisecondsSinceEpoch}-$i',
        name: item['name'],
        phone: item['phone'],
        type: item['type'] ?? 'working_far',
        workplace: item['workplace'] ?? 'KCN Biên Hòa',
        shift: item['shift'] ?? 'Ca 2 (14h - 22h)',
        lastAttended: '15/11/2026',
        points: (item['points'] as num?)?.toInt() ?? 80,
        makeupCount: 0,
        status: 'active',
        memberCode: 'ĐV-DN-${(baseIndex + i).toString().padLeft(3, '0')}',
        joinDate: item['joinDate'] ?? '26/03/2023',
        occupation: item['occupation'] ?? 'Công nhân sản xuất KCN',
        branchName: 'Chi đoàn Khu phố 5',
        attendanceHistory: [const AttendanceRec('Tháng 11', 'present', 'Nhập từ Excel')],
      ));
    }
    auditLogs.insert(0, AuditLog(id: 'log-imp-${DateTime.now().millisecondsSinceEpoch}', actor: 'Nguyễn Văn An (Bí thư KP5)', action: 'Nhập hàng loạt ${batchList.length} hồ sơ đoàn viên từ tệp Excel', time: 'Vừa xong'));
    if (useApi) {
      for (final item in batchList) {
        _apiFire(api.post('/members', {'name': item['name'], 'phone': item['phone'], 'type': item['type'] ?? 'working_far', 'workplace': item['workplace'] ?? '', 'shift': item['shift'] ?? ''}));
      }
    }
    notifyListeners();
  }

  void submitTransferRequest({required String memberName, required String memberCode, required String direction, required String toBranch, required String reason, String? memberId, String? fromBranch}) {
    transferRequests.insert(0, TransferRequest(id: 'tr-${DateTime.now().millisecondsSinceEpoch}', memberId: memberId ?? defaultCurrentMemberId, memberName: memberName, memberCode: memberCode, direction: direction, fromBranch: fromBranch ?? 'Chi đoàn Khu phố 5 - P. Tam Hiệp', toBranch: toBranch, reason: reason, submittedAt: '24/11/2026', status: 'pending', step: 1));
    notifications['secretary']!.insert(0, AppNotification(id: 'noti-tr-${DateTime.now().millisecondsSinceEpoch}', title: 'Hồ sơ chuyển sinh hoạt mới: $memberName', content: '→ $toBranch. Lý do: $reason', time: 'Vừa xong', type: 'report', unread: true));
    notifyListeners();
  }

  void processTransferRequest(String reqId, String action) {
    TransferRequest? target0;
    for (final t in transferRequests) {
      if (t.id == reqId) target0 = t;
    }
    if (target0 == null) return;
    final target = target0;
    if (action == 'approve') {
      target.status = 'completed';
      target.step = 4;
      if (target.direction == 'outgoing') {
        for (final m in members) {
          if (m.id == target.memberId) {
            m.note = 'Đã chuyển sang ${target.toBranch}';
          }
        }
      } else {
        final exists = members.any((m) => m.id == target.memberId);
        if (!exists) {
          members.insert(0, Member(id: target.memberId, memberCode: target.memberCode, name: target.memberName, phone: '0933.778.901', type: 'local', workplace: 'Khu phố 5, Tam Hiệp (Chuyển đến)', shift: 'Ca 1 (06h - 14h)', lastAttended: '24/11/2026', points: 85, makeupCount: 0, status: 'active', occupation: 'Công nhân KCN Amata', joinDate: '26/03/2022', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: [const AttendanceRec('Tháng 11', 'present', 'Tiếp nhận chuyển đến')]));
        }
      }
    } else {
      target.status = 'rejected';
    }
    auditLogs.insert(0, AuditLog(id: 'log-tr-${DateTime.now().millisecondsSinceEpoch}', actor: 'Cán bộ Đoàn', action: '${action == 'approve' ? 'Phê duyệt & đồng bộ' : 'Từ chối'} hồ sơ chuyển SH của ${target.memberName}', time: 'Vừa xong'));
    notifyListeners();
  }

  // ===== Lịch cá nhân =====
  String _toIso(Map<String, dynamic> form) {
    final dateStr = '${form['dateStr'] ?? '29/11/2026'}';
    final parts = dateStr.split('/');
    final timeStr = '${form['timeSlot'] ?? '20:00 - 21:30'}'.split('-').first.trim();
    final hhmm = timeStr.split(':');
    try {
      final d = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]),
          int.parse(hhmm[0]), hhmm.length > 1 ? int.parse(hhmm[1]) : 0);
      return d.toUtc().toIso8601String();
    } catch (_) {
      return DateTime.now().toUtc().toIso8601String();
    }
  }

  Map<String, dynamic> enrollScheduleItem(ScheduleItem item) {
    final exists = mySchedule.any((s) => s.id == item.id || s.title == item.title);
    if (exists) return {'ok': false, 'reason': 'already_enrolled'};
    mySchedule.insert(0, ScheduleItem(id: item.id, title: item.title, category: item.category, dateStr: item.dateStr, dayOfWeek: item.dayOfWeek, timeSlot: item.timeSlot, room: item.room, organizer: item.organizer, format: item.format, points: item.points, isELearning: item.isELearning, seatsLeft: item.seatsLeft));
    for (final c in scheduleCatalog) {
      if (c.id == item.id && c.seatsLeft < 999) c.seatsLeft = max(0, c.seatsLeft - 1);
    }
    if (!registeredMakeupIds.contains(item.id)) registeredMakeupIds.add(item.id);
    final aid = _backendIdOf(item.id);
    if (useApi && aid != null) {
      _apiFire(api.post('/rewards/activities/$aid/register'), okMsg: 'Đã đăng ký hoạt động trên hệ thống!');
    }
    auditLogs.insert(0, AuditLog(id: 'log-enr-${DateTime.now().millisecondsSinceEpoch}', actor: currentMember.name, action: 'Đăng ký "${item.title}" vào Lịch cá nhân (${item.dateStr})', time: 'Vừa xong'));
    notifyListeners();
    return {'ok': true};
  }

  void unenrollScheduleItem(String itemId) {
    mySchedule.removeWhere((s) => s.id == itemId);
    registeredMakeupIds.remove(itemId);
    for (final p in socialPosts) {
      if (p.eventSchedule?.id == itemId) {
        p.registeredByMe = false;
        p.registeredCount = max(0, p.registeredCount - 1);
      }
    }
    notifyListeners();
  }

  // ====== BACKEND (Vòng 2) — nối API thật ======
  final ApiClient api = ApiClient();
  bool backendLive = false;
  int? backendMemberId; // id hồ sơ đoàn viên gắn với tài khoản đang đăng nhập
  String? backendRole;  // role trả về từ máy chủ
  final Map<String, String> backendBranchIdByName = {}; // tên chi đoàn (local) → branch_id server

  /// Đang dùng API thật (có token, server reachable, không bật chế độ offline demo)
  bool get useApi => api.hasToken && backendLive && !isOffline;


  /// Đăng nhập qua backend (phone + OTP) → nhận vai trò + đồng bộ dữ liệu
  Future<String> loginWithBackend(String phone, String otp) async {
    final data = await api.login(phone, otp);
    final user = data['user'] as Map;
    backendRole = (user['role'] as String?) ?? 'member';
    backendMemberId = (user['member_id'] as num?)?.toInt();
    await _syncFromBackend();
    return backendRole!;
  }

  void logoutBackend() {
    api.setAuth(null);
    backendLive = false;
    backendMemberId = null;
    backendRole = null;
  }

  String _fmtDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return iso;
    }
  }

  String _fmtTime(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '20:00';
    }
  }

  int _intOf(dynamic v) => (v as num?)?.toInt() ?? 0;

  Member _mapMember(dynamic j) => Member(
        id: '${j['id']}',
        name: (j['name'] as String?) ?? 'Chưa rõ',
        phone: (j['phone'] as String?) ?? '',
        type: (j['type'] as String?) ?? 'local',
        workplace: (j['workplace'] as String?) ?? '',
        shift: (j['shift'] as String?) ?? '',
        lastAttended: '15/11/2026',
        points: _intOf(j['points']),
        makeupCount: _intOf(j['makeup_count']),
        status: j['status'] == 'warning' ? 'warning' : 'active',
        memberCode: (j['member_code'] as String?) ?? '',
        joinDate: '26/03/2023',
        occupation: 'Lao động trẻ',
        branchName: 'Chi đoàn Khu phố 5',
        attendanceHistory: const [],
      );

  Future<void> _syncFromBackend() async {
    if (!api.hasToken) return;
    backendLive = true;
    try {
      // 0. Hồ sơ cá nhân (mọi vai trò): đồng bộ điểm/thành viên thật từ server —
      //    quan trọng với Đoàn viên vì /members bị RBAC chặn (không được dùng mock)
      try {
        final me = await api.get('/auth/me') as Map;
        final mem = me['member'];
        if (mem is Map) {
          final points = _intOf(mem['points']);
          final id = '${mem['id']}';
          final idx = members.indexWhere((m) => m.id == id);
          if (idx >= 0) {
            members[idx].points = points;
          } else {
            // server trả hồ sơ chưa có trong danh sách (Đoàn viên đang dùng mock):
            // cập nhật điểm + mã vào bản mock của chính mình để hero hiển thị đúng
            final cur = currentMember;
            cur.points = points;
            if ((mem['member_code'] as String?)?.isNotEmpty == true) {
              cur.memberCode = mem['member_code'] as String;
            }
          }
        }
      } on ApiException catch (_) {/* bỏ qua — dùng dữ liệu hiện có */}

      // 1. Hồ sơ đoàn viên (bí thư/phường có quyền; đoàn viên giữ dữ liệu mock)
      try {
        final mems = await api.get('/members') as List;
        if (mems.isNotEmpty) {
          members = mems.map<Member>(_mapMember).toList();
        }
      } on ApiException catch (_) {/* đoàn viên bị chặn — dùng mock */}

      // 2. Buổi sinh hoạt
      try {
        final sess = await api.get('/sessions') as List;
        _mapSessions(sess.cast<Map>());
      } on ApiException catch (e) {
        showToast('Buổi sinh hoạt: ${e.message}');
      }

      // 3. Đơn xin phép / sinh hoạt bù
      try {
        final reqs = await api.get('/requests') as List;
        makeupRequests = reqs.map<MakeupRequest>(_mapRequest).toList();
      } on ApiException catch (_) {}

      // 4. Dashboard phường (chỉ cán bộ phường)
      try {
        final dash = await api.get('/ward/dashboard');
        _mapWard(dash as Map);
      } on ApiException catch (_) {}

      // 5. Hoạt động → danh mục đăng ký
      try {
        final acts = await api.get('/ward/activities') as List;
        _mapActivities(acts);
      } on ApiException catch (_) {}

      // 6. Voucher
      try {
        final vs = await api.get('/rewards/vouchers') as List;
        if (vs.isNotEmpty) {
          rewardItems = vs.map<RewardItem>(_mapVoucher).toList();
        }
      } on ApiException catch (_) {}

      // 7. Bảng tin
      try {
        final posts = await api.get('/social/posts') as List;
        if (posts.isNotEmpty) {
          socialPosts = posts.map<SocialPost>(_mapPost).toList();
        }
      } on ApiException catch (_) {}

      auditLogs.insert(0, AuditLog(id: 'log-sync-${DateTime.now().millisecondsSinceEpoch}', actor: 'Hệ thống', action: 'Đồng bộ dữ liệu từ máy chủ (backend Vòng 2)', time: 'Vừa xong'));
    } on ApiException catch (e) {
      showToast('Không đồng bộ được dữ liệu: ${e.message}');
    } catch (e) {
      backendLive = false;
      showToast('Máy chủ không phản hồi — chạy chế độ dữ liệu mẫu. ($e)');
    } finally {
      notifyListeners();
    }
  }

  void _mapSessions(List<Map> sess) {
    final open = sess.where((s) => s['is_open'] == true).toList();
    if (open.isNotEmpty) {
      final s = open.first;
      activeSession = ActiveSession(
        id: '${s['id']}',
        title: (s['title'] as String?) ?? activeSession.title,
        date: _fmtDate('${s['starts_at']}'),
        location: (s['location'] as String?) ?? activeSession.location,
        format: 'hybrid',
        refreshSeconds: 55,
        geofenceRequired: true,
        allowShiftCatchup: true,
        expectedCount: 46,
        qrToken: (s['current_qr_token'] as String?) ?? activeSession.qrToken,
        qrSeed: activeSession.qrSeed,
      );
      // Số người đã điểm danh trên server → hiển thị trong màn QR
      final checked = _intOf(s['checked_in']);
      scannedMemberIds = List.generate(checked, (i) => 'sv-$i');
    }
    sessionArchive = sess.where((s) => s['is_open'] != true).map<Map<String, dynamic>>((s) {
      final attendees = _intOf(s['checked_in']);
      const total = 46;
      return <String, dynamic>{
        'period': '11/2026',
        'title': (s['title'] as String?) ?? '',
        'location': (s['location'] as String?) ?? '',
        'rate': '${(attendees / total * 100).toStringAsFixed(1)}%',
        'attended': attendees,
        'total': total,
      };
    }).toList();
  }

  MakeupRequest _mapRequest(dynamic j) {
    final mid = '${j['member_id']}';
    final m = _member(mid);
    final rawStatus = (j['status'] as String?) ?? 'pending';
    return MakeupRequest(
      id: 'req-${j['id']}',
      memberId: mid,
      memberName: m?.name ?? 'Đoàn viên #${j['member_id']}',
      workplace: m?.workplace ?? '',
      shift: m?.shift ?? '',
      sessionName: (j['session_title'] as String?) ?? '',
      registeredMakeup: 'Trực tuyến (hybrid)',
      reason: (j['reason'] as String?) ?? '',
      proof: (j['proof'] as String?) ?? '',
      status: rawStatus == 'clarify' ? 'clarify_requested' : rawStatus,
    );
  }

  void _mapWard(Map dash) {
    final m11 = wardDataByMonth['11'];
    if (m11 == null) return;
    backendBranchIdByName.clear();
    final branches = (dash['branches'] as List?) ?? [];
    for (final b in branches) {
      final nm = (b['name'] as String?) ?? '';
      if (nm.isNotEmpty) backendBranchIdByName[nm] = '${b['branch_id']}';
    }
    m11.branchesRank = branches.map<BranchRank>((b) => BranchRank(
          id: '${b['branch_id']}',
          name: (b['name'] as String?) ?? '',
          secretary: 'Đ/c ${b['secretary'] ?? ''}',
          total: _intOf(b['total']),
          attended: _intOf(b['attended']),
          rate: ((b['rate'] as num?) ?? 0).toDouble(),
          status: b['status'] == 'pending' ? 'pending' : 'submitted',
          type: 'Khu dân cư',
          highlight: '${b['branch_id']}' == '1',
        )).toList();
    m11.totalBranches = m11.branchesRank.length;
    m11.totalMembers = m11.branchesRank.fold<int>(0, (s, b) => s + b.total);
    final totalAttended = m11.branchesRank.fold<int>(0, (s, b) => s + b.attended);
    final avg = m11.totalMembers == 0 ? 0.0 : totalAttended / m11.totalMembers * 100;
    m11.averageAttendanceRate = '${avg.toStringAsFixed(1)}%';
    m11.completedReports =
        '${m11.branchesRank.where((b) => b.status == 'submitted').length}/${m11.totalBranches} Chi đoàn';
  }

  void _mapActivities(List acts) {
    scheduleCatalog = acts.map<ScheduleItem>((j) => ScheduleItem(
          id: 'a${j['id']}',
          title: (j['title'] as String?) ?? '',
          category: (j['category'] as String?) ?? 'Sự kiện Đoàn',
          dateStr: _fmtDate('${j['starts_at']}'),
          dayOfWeek: 'CN',
          timeSlot: _fmtTime('${j['starts_at']}'),
          room: (j['location'] as String?) ?? '',
          organizer: (j['organizer'] as String?) ?? 'Đoàn Phường Tam Hiệp',
          format: 'Trực tiếp • Điểm danh QR',
          points: '+${_intOf(j['points'])} điểm',
          isELearning: false,
          seatsLeft: 999,
        )).toList();
    final mine = scheduleCatalog.where((item) {
      final match = acts.where((j) => 'a${j['id']}' == item.id);
      return match.isNotEmpty && match.first['registered'] == true;
    }).toList();
    mySchedule = mine.map((item) => ScheduleItem(
          id: item.id, title: item.title, category: item.category, dateStr: item.dateStr,
          dayOfWeek: item.dayOfWeek, timeSlot: item.timeSlot, room: item.room,
          organizer: item.organizer, format: item.format, points: item.points,
          isELearning: item.isELearning, seatsLeft: item.seatsLeft,
        )).toList();
  }

  RewardItem _mapVoucher(dynamic j) => RewardItem(
        id: 'v${j['id']}',
        title: (j['title'] as String?) ?? '',
        points: _intOf(j['cost_points']),
        category: 'Voucher',
        sponsor: 'Đối tác Đồng Nai',
        icon: 'gift',
        available: _intOf(j['stock']),
      );

  SocialPost _mapPost(dynamic j) {
    final role = (j['role'] as String?) ?? 'member';
    final roleLabel = switch (role) {
      'secretary' => 'Bí thư Chi đoàn',
      'ward_officer' => 'Cán bộ Đoàn Phường',
      _ => 'Đoàn viên',
    };
    return SocialPost(
      id: 'p${j['id']}',
      authorId: '${j['author_id'] ?? ''}',
      authorName: (j['author_name'] as String?) ?? 'Ẩn danh',
      authorRole: roleLabel,
      authorAvatar: (j['author_name'] as String?) ?? '',
      branchName: 'Chi đoàn Khu phố 5',
      category: 'event',
      eventTag: '',
      isEventPost: j['is_event'] == true,
      pinned: j['is_pinned'] == true,
      verifiedOfficer: role != 'member',
      verifiedParticipant: false,
      registeredCount: 0,
      registeredByMe: false,
      eventSchedule: null,
      createdAt: _fmtDate('${j['created_at']}'),
      content: (j['content'] as String?) ?? '',
      imageUrl: null,
      likesCount: 0,
      likedByMe: false,
      comments: const [],
    );
  }

  int? _backendIdOf(String localId) {
    final m = RegExp(r'(\d+)$').firstMatch(localId);
    return m == null ? null : int.tryParse(m.group(1)!);
  }

  void _apiFire(Future<dynamic> fut, {String? okMsg}) {
    fut.then((r) {
      if (okMsg != null) showToast(okMsg);
    }).catchError((e) {
      showToast(e is ApiException ? e.message : 'Chưa đồng bộ được với máy chủ — dữ liệu đang lưu cục bộ.');
    });
  }

  /// ====== PHÂN QUYỀN — chức năng theo vai trò (Vòng 2) ======

  /// Bí thư: xóa buổi sinh hoạt đã tạo
  void removeScheduleItem(String id) {
    final removed = mySchedule.where((s) => s.id == id).toList();
    mySchedule.removeWhere((s) => s.id == id);
    scheduleCatalog.removeWhere((s) => s.id == id);
    for (final p in socialPosts) {
      if (removed.any((r) => r.id == p.eventSchedule?.id)) p.eventSchedule = null;
    }
    auditLogs.insert(0, AuditLog(id: 'log-del-${DateTime.now().millisecondsSinceEpoch}', actor: 'Bí thư Chi đoàn', action: 'Xóa hoạt động khỏi lịch (${removed.map((r) => r.title).join(', ')})', time: 'Vừa xong'));
    notifyListeners();
  }

  /// Bí thư: đóng đăng ký buổi sinh hoạt (không còn nhận đăng ký mới)
  void closeScheduleRegistration(String id) {
    for (final c in scheduleCatalog) {
      if (c.id == id) c.seatsLeft = 0;
    }
    for (final s in mySchedule) {
      if (s.id == id) s.mandatory = true;
    }
    final item = mySchedule.where((s) => s.id == id).toList();
    auditLogs.insert(0, AuditLog(id: 'log-close-${DateTime.now().millisecondsSinceEpoch}', actor: 'Bí thư Chi đoàn', action: 'Đóng đăng ký "${item.isNotEmpty ? item.first.title : id}"', time: 'Vừa xong'));
    notifyListeners();
  }

  /// Cán bộ phường: phê duyệt báo cáo của chi đoàn trực thuộc
  void approveBranchReport(String branchId) {
    final month = wardDataByMonth['11'];
    String? localName;
    if (month != null) {
      for (final b in month.branchesRank) {
        if (b.id == branchId) localName = b.name;
      }
    }
    final bid = backendBranchIdByName[localName ?? ''] ?? _backendIdOf(branchId);
    if (useApi && bid != null) {
      _apiFire(api.post('/ward/branches/$bid/approve'), okMsg: 'Đã phê duyệt báo cáo trên hệ thống!');
    }
    if (month == null) return;
    for (final b in month.branchesRank) {
      if (b.id == branchId && b.status == 'pending') {
        b.status = 'submitted';
        auditLogs.insert(0, AuditLog(id: 'log-bapp-${DateTime.now().millisecondsSinceEpoch}', actor: 'Cán bộ Đoàn Phường', action: 'Phê duyệt báo cáo tháng 11 của ${b.name}', time: 'Vừa xong'));
        notifications['ward_officer']!.insert(0, AppNotification(id: 'noti-bapp-${DateTime.now().millisecondsSinceEpoch}', title: 'Đã duyệt báo cáo chi đoàn', content: '${b.name} — kỳ tháng 11/2026 (${b.attended}/${b.total} ĐV).', time: 'Vừa xong', type: 'report', unread: true));
      }
    }
    notifyListeners();
  }

  ScheduleItem createScheduleCatalogItem(Map<String, dynamic> form) {
    final newItem = ScheduleItem(
      id: 'cat-${DateTime.now().millisecondsSinceEpoch}',
      title: form['title'],
      category: form['category'] ?? 'Sinh hoạt',
      dateStr: form['dateStr'] ?? '29/11/2026',
      dayOfWeek: form['dayOfWeek'] ?? 'CN',
      timeSlot: form['timeSlot'] ?? '08:00 - 10:30',
      room: form['room'] ?? 'Nhà văn hóa Khu phố 5',
      organizer: form['organizer'] ?? 'BCH Chi đoàn KP5',
      format: 'Trực tiếp • Điểm danh QR',
      points: '+${form['pointsValue'] ?? 15} điểm',
      seatsLeft: 40,
      isELearning: false,
    );
    scheduleCatalog.insert(0, newItem);
    if (form['autoEnroll'] == true) mySchedule.insert(0, newItem);
    if (useApi) {
      if ((form['organizer'] as String? ?? '').contains('Phường')) {
        _apiFire(api.post('/ward/activities', {
          'title': newItem.title, 'category': newItem.category,
          'starts_at': '${_toIso(form)}', 'location': newItem.room,
          'points': int.tryParse('${form['pointsValue'] ?? 25}') ?? 25,
        }), okMsg: 'Đã phát động hoạt động toàn phường qua hệ thống!');
      } else {
        _apiFire(api.post('/sessions', {
          'title': newItem.title,
          'starts_at': '${_toIso(form)}',
          'location': newItem.room,
        }), okMsg: 'Đã tạo buổi sinh hoạt trên hệ thống!');
      }
    }
    auditLogs.insert(0, AuditLog(id: 'log-csch-${DateTime.now().millisecondsSinceEpoch}', actor: 'Cán bộ Đoàn', action: 'Thêm lịch hoạt động mới "${newItem.title}" (${newItem.dateStr})', time: 'Vừa xong'));
    notifyListeners();
    return newItem;
  }

  Map<String, dynamic> registerEventFromSocialPost(SocialPost post) {
    final ev = post.eventSchedule;
    if (ev == null) return {'ok': false};
    final exists = mySchedule.any((s) => s.id == ev.id || s.title == ev.title);
    if (exists) return {'ok': false, 'reason': 'already_registered'};
    mySchedule.insert(0, ev);
    post.registeredByMe = true;
    post.registeredCount++;
    notifications['member']!.insert(0, AppNotification(id: 'noti-evreg-${DateTime.now().millisecondsSinceEpoch}', title: 'Đã thêm vào Lịch: ${ev.title}', content: '${ev.dateStr} (${ev.timeSlot}) tại ${ev.room}. Hệ thống sẽ nhắc trước giờ diễn ra.', time: 'Vừa xong', type: 'event', unread: true));
    auditLogs.insert(0, AuditLog(id: 'log-evreg-${DateTime.now().millisecondsSinceEpoch}', actor: currentMember.name, action: 'Đăng ký tham dự sự kiện "${ev.title}" từ Bảng tin', time: 'Vừa xong'));
    notifyListeners();
    return {'ok': true};
  }

  // ===== Bảng tin Social =====
  /// Cán bộ: ghim / bỏ ghim bài chính thức (luôn hiển thị đầu bảng tin)
  void togglePinSocialPost(String postId) {
    for (final p in socialPosts) {
      if (p.id == postId) p.pinned = !p.pinned;
    }
    final pid = _backendIdOf(postId);
    if (useApi && pid != null) _apiFire(api.post('/social/posts/$pid/pin'));
    // Sắp xếp: bài ghim lên đầu
    socialPosts.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return 0;
    });
    notifyListeners();
  }

  /// Cán bộ: xóa bài vi phạm / không phù hợp
  void deleteSocialPost(String postId) {
    socialPosts.removeWhere((p) => p.id == postId);
    final pid = _backendIdOf(postId);
    if (useApi && pid != null) _apiFire(api.delete('/social/posts/$pid'));
    auditLogs.insert(0, AuditLog(id: 'log-postdel-${DateTime.now().millisecondsSinceEpoch}', actor: 'Cán bộ Đoàn', action: 'Xóa một bài viết vi phạm trên Bảng tin', time: 'Vừa xong'));
    notifyListeners();
  }

  SocialPost createSocialPost({required String content, required String eventTag, required String? imageUrl, required String authorName, required String authorRole, bool isEventPost = false, ScheduleItem? eventSchedule}) {
    if (useApi) {
      _apiFire(api.post('/social/posts', {'content': content, 'is_event': isEventPost}));
    }
    final post = SocialPost(
      id: 'post-${DateTime.now().millisecondsSinceEpoch}',
      authorId: defaultCurrentMemberId,
      authorName: authorName,
      authorRole: authorRole,
      authorAvatar: authorName,
      branchName: 'Chi đoàn Khu phố 5',
      category: 'event',
      eventTag: eventTag,
      isEventPost: isEventPost && eventSchedule != null,
      verifiedOfficer: isEventPost,
      verifiedParticipant: true,
      registeredCount: eventSchedule != null ? 1 : 0,
      registeredByMe: false,
      eventSchedule: eventSchedule,
      createdAt: 'Vừa xong',
      content: content,
      imageUrl: imageUrl,
      likesCount: 1,
      likedByMe: true,
      comments: [],
    );
    socialPosts.insert(0, post);
    if (eventSchedule != null) {
      scheduleCatalog.insert(0, ScheduleItem(id: eventSchedule.id, title: eventSchedule.title, category: 'Sự kiện Đoàn', dateStr: eventSchedule.dateStr, dayOfWeek: eventSchedule.dayOfWeek, timeSlot: eventSchedule.timeSlot, room: eventSchedule.room, organizer: eventSchedule.organizer, format: eventSchedule.format, points: eventSchedule.points, isELearning: false, seatsLeft: 50));
    }
    currentMember.points += 5;
    for (final b in digitalBadges) {
      if (b.id == 'bdg-4') {
        b.earned = true;
        b.earnedAt = '24/11/2026';
      }
    }
    auditLogs.insert(0, AuditLog(id: 'log-post-${DateTime.now().millisecondsSinceEpoch}', actor: authorName, action: 'Đăng bài "${post.eventTag}" lên Bảng tin (+5đ)', time: 'Vừa xong'));
    notifyListeners();
    return post;
  }

  void toggleLikeSocialPost(String postId) {
    for (final p in socialPosts) {
      if (p.id == postId) {
        p.likedByMe = !p.likedByMe;
        p.likesCount += p.likedByMe ? 1 : -1;
      }
    }
    notifyListeners();
  }

  void addSocialComment(String postId, String authorName, String text) {
    if (text.trim().isEmpty) return;
    for (final p in socialPosts) {
      if (p.id == postId) {
        p.comments.add(Comment(id: 'cmt-${DateTime.now().millisecondsSinceEpoch}', authorName: authorName, text: text.trim(), time: 'Vừa xong'));
        // Ghi bình luận xuống máy chủ (nếu bài đã đồng bộ từ server)
        final pid = _backendIdOf(postId);
        if (pid != null && backendLive) {
          _apiFire(api.post('/social/posts/$pid/comment', {'content': text.trim()}));
        }
      }
    }
    notifyListeners();
  }

  void setPreselectedSocialEvent(Map<String, String> value) {
    preselectedSocialEvent = value;
    notifyListeners();
  }

  void consumePreselectedSocialEvent() {
    preselectedSocialEvent = null;
    notifyListeners();
  }

  // ===== Thông báo & bảo mật =====
  void markNotificationRead(String roleKey, String notificationId) {
    for (final n in notifications[roleKey] ?? []) {
      if (n.id == notificationId) n.unread = false;
    }
    notifyListeners();
  }

  void markAllNotificationsRead(String roleKey) {
    for (final n in notifications[roleKey] ?? []) {
      n.unread = false;
    }
    notifyListeners();
  }

  void sendTargetedNotification({required String targetGroup, required String targetRole, required String title, required String content}) {
    notifications[targetRole]?.insert(0, AppNotification(id: 'noti-tgt-${DateTime.now().millisecondsSinceEpoch}', title: '[$targetGroup] $title', content: content, time: 'Vừa xong', type: 'event', unread: true));
    auditLogs.insert(0, AuditLog(id: 'log-tgt-${DateTime.now().millisecondsSinceEpoch}', actor: 'Cán bộ Đoàn', action: 'Gửi thông báo tới nhóm "$targetGroup": $title', time: 'Vừa xong'));
    notifyListeners();
  }

  void updateSecuritySettings(String key, bool value) {
    securitySettings[key] = value;
    auditLogs.insert(0, AuditLog(id: 'log-sec-${DateTime.now().millisecondsSinceEpoch}', actor: 'Quản trị viên Hệ thống', action: 'Cập nhật cấu hình bảo mật hệ thống', time: 'Vừa xong'));
    notifyListeners();
  }

  /// Khôi phục toàn bộ dữ liệu gốc (mock reset)
  void resetAppData() {
    final fresh = AppState();
    members
      ..clear()
      ..addAll(fresh.members);
    activeSession = fresh.activeSession;
    scannedMemberIds = fresh.scannedMemberIds;
    attendanceHistory = fresh.attendanceHistory;
    makeupRequests = fresh.makeupRequests;
    notifications = fresh.notifications;
    vouchers.clear();
    volunteerActivities = fresh.volunteerActivities;
    registeredVolunteerIds = [];
    volunteerCheckedInIds = [];
    volunteerProofs = {};
    offlineQueue = [];
    socialPosts = fresh.socialPosts;
    transferRequests = fresh.transferRequests;
    digitalBadges = fresh.digitalBadges;
    auditLogs = fresh.auditLogs;
    mySchedule = fresh.mySchedule;
    scheduleCatalog = fresh.scheduleCatalog;
    registeredMakeupIds = [];
    kp5ReportSubmitted = false;
    // reset rates
    for (final md in wardDataByMonth.values) {
      for (final b in md.branchesRank) {
        b.reminded = false;
      }
    }
    notifyListeners();
  }
}
