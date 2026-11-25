// Dữ liệu giả lập nền tảng Đoàn Viên Số - Tỉnh Đồng Nai (mock Round 1)

class Member {
  final String id;
  final String name;
  String phone;
  final String type; // 'local' | 'working_far' | 'transferred'
  final String workplace;
  final String shift;
  final String lastAttended;
  int points;
  int makeupCount;
  String status; // active | warning | pending_transfer | military
  String? note;
  String memberCode; // non-final: đồng bộ từ server khi đăng nhập
  final String joinDate;
  final String occupation;
  final String branchName;
  final List<AttendanceRec> attendanceHistory;
  Member({
    required this.id,
    required this.name,
    required this.phone,
    required this.type,
    required this.workplace,
    required this.shift,
    required this.lastAttended,
    required this.points,
    required this.makeupCount,
    required this.status,
    this.note,
    required this.memberCode,
    required this.joinDate,
    required this.occupation,
    required this.branchName,
    required this.attendanceHistory,
  });
}

class AttendanceRec {
  final String month;
  final String status; // present | makeup | absent | transferred | military
  final String label;
  const AttendanceRec(this.month, this.status, this.label);
}

class SessionRec {
  final String id;
  final String date;
  final String title;
  final int attendees;
  final int total;
  final String rate;
  final String location;
  final String? note;
  const SessionRec({required this.id, required this.date, required this.title, required this.attendees, required this.total, required this.rate, required this.location, this.note});
}

class ActiveSession {
  final String id;
  final String title;
  final String date;
  final String location;
  final String format; // direct | hybrid | online
  int refreshSeconds;
  bool geofenceRequired;
  bool allowShiftCatchup;
  int expectedCount;
  String qrToken;
  int qrSeed;
  ActiveSession({
    required this.id,
    required this.title,
    required this.date,
    required this.location,
    required this.format,
    required this.refreshSeconds,
    required this.geofenceRequired,
    required this.allowShiftCatchup,
    required this.expectedCount,
    required this.qrToken,
    required this.qrSeed,
  });
}

class BranchRank {
  final String id;
  final String name;
  final String secretary;
  final int total;
  int attended;
  double rate;
  String status; // submitted | pending
  final String type;
  final bool highlight;
  bool reminded;
  BranchRank({required this.id, required this.name, required this.secretary, required this.total, required this.attended, required this.rate, required this.status, required this.type, this.highlight = false, this.reminded = false});
}

class MonthWardData {
  final String key;
  final String monthLabel;
  final String reportDateText;
  final String reportNumber;
  int totalBranches;
  int totalMembers;
  String averageAttendanceRate;
  String completedReports;
  List<BranchRank> branchesRank;
  MonthWardData({
    required this.key,
    required this.monthLabel,
    required this.reportDateText,
    required this.reportNumber,
    required this.totalBranches,
    required this.totalMembers,
    required this.averageAttendanceRate,
    required this.completedReports,
    required this.branchesRank,
  });
}

class MakeupSession {
  final String id;
  final String branchName;
  final String title;
  final String time;
  final String format;
  final int seatsLeft;
  final String suitableFor;
  const MakeupSession({required this.id, required this.branchName, required this.title, required this.time, required this.format, required this.seatsLeft, required this.suitableFor});
}

class MakeupRequest {
  final String id;
  final String memberId;
  final String memberName;
  final String workplace;
  final String shift;
  final String sessionName;
  final String registeredMakeup;
  final String reason;
  final String proof;
  String status; // pending | approved | clarify_requested
  final bool autoPointsAwarded;
  MakeupRequest({required this.id, required this.memberId, required this.memberName, required this.workplace, required this.shift, required this.sessionName, required this.registeredMakeup, required this.reason, required this.proof, required this.status, this.autoPointsAwarded = false});
}

class QuizQuestion {
  final int id;
  final String question;
  final List<String> options;
  final int correctAnswer;
  const QuizQuestion({required this.id, required this.question, required this.options, required this.correctAnswer});
}

class RewardItem {
  final String id;
  final String title;
  final int points;
  final String category;
  final String sponsor;
  final String icon;
  final String? badge;
  int available;
  RewardItem({required this.id, required this.title, required this.points, required this.category, required this.sponsor, required this.icon, this.badge, required this.available});
}

class VolunteerActivity {
  final String id;
  final String title;
  final String date;
  final String location;
  final String points;
  final int pointsValue;
  int participantsCount;
  final String status; // completed | upcoming
  VolunteerActivity({required this.id, required this.title, required this.date, required this.location, required this.points, required this.pointsValue, required this.participantsCount, required this.status});
}

class AppNotification {
  final String id;
  final String title;
  final String content;
  final String time;
  final String type;
  bool unread;
  AppNotification({required this.id, required this.title, required this.content, required this.time, required this.type, required this.unread});
}

class AttendanceHistoryItem {
  final String id;
  final String sessionName;
  final String date;
  final String status; // attended | makeup
  final String badge;
  final String pointsEarned;
  final String type;
  AttendanceHistoryItem({required this.id, required this.sessionName, required this.date, required this.status, required this.badge, required this.pointsEarned, required this.type});
}

class OfflineItem {
  final String id;
  final String memberId;
  final String memberName;
  final String sessionId;
  final String sessionTitle;
  final String timestamp;
  final int points;
  final String typeLabel;
  OfflineItem({required this.id, required this.memberId, required this.memberName, required this.sessionId, required this.sessionTitle, required this.timestamp, required this.points, required this.typeLabel});
}

class ScheduleItem {
  final String id;
  final String title;
  final String category;
  final String dateStr;
  final String dayOfWeek;
  final String timeSlot;
  final String room;
  final String organizer;
  final String format;
  final String points;
  bool mandatory;
  final bool isELearning;
  int seatsLeft;
  ScheduleItem({required this.id, required this.title, required this.category, required this.dateStr, required this.dayOfWeek, required this.timeSlot, required this.room, required this.organizer, required this.format, required this.points, this.mandatory = false, required this.isELearning, this.seatsLeft = 999});
}

class SocialPost {
  final String id;
  final String authorId;
  final String authorName;
  final String authorRole;
  final String authorAvatar;
  final String branchName;
  final String category;
  final String eventTag;
  final bool isEventPost;
  bool pinned;
  final bool verifiedOfficer;
  final bool verifiedParticipant;
  int registeredCount;
  bool registeredByMe;
  ScheduleItem? eventSchedule;
  final String createdAt;
  final String content;
  final String? imageUrl;
  int likesCount;
  bool likedByMe;
  List<Comment> comments;
  SocialPost({required this.id, required this.authorId, required this.authorName, required this.authorRole, required this.authorAvatar, required this.branchName, required this.category, required this.eventTag, required this.isEventPost, this.pinned = false, required this.verifiedOfficer, required this.verifiedParticipant, required this.registeredCount, required this.registeredByMe, required this.eventSchedule, required this.createdAt, required this.content, this.imageUrl, required this.likesCount, required this.likedByMe, required this.comments});
}

class Comment {
  final String id;
  final String authorName;
  final String text;
  final String time;
  const Comment({required this.id, required this.authorName, required this.text, required this.time});
}

class TransferRequest {
  final String id;
  final String memberId;
  final String memberName;
  final String memberCode;
  final String direction; // outgoing | incoming
  final String fromBranch;
  final String toBranch;
  final String reason;
  final String submittedAt;
  String status; // approved_source | pending | completed | rejected
  int step;
  TransferRequest({required this.id, required this.memberId, required this.memberName, required this.memberCode, required this.direction, required this.fromBranch, required this.toBranch, required this.reason, required this.submittedAt, required this.status, required this.step});
}

class DigitalBadge {
  final String id;
  final String name;
  final String desc;
  final String icon;
  bool earned;
  String? earnedAt;
  DigitalBadge({required this.id, required this.name, required this.desc, required this.icon, required this.earned, this.earnedAt});
}

class AuditLog {
  final String id;
  final String actor;
  final String action;
  final String time;
  AuditLog({required this.id, required this.actor, required this.action, required this.time});
}

class RewardVoucher {
  final String title;
  final String sponsor;
  final String code;
  final String createdAt;
  final String expiresAt;
  final String pickupLocation;
  RewardVoucher({required this.title, required this.sponsor, required this.code, required this.createdAt, required this.expiresAt, required this.pickupLocation});
}

// ===== Dữ liệu chi đoàn KP5 =====
const branchDataName = 'Chi đoàn Khu phố 5';
const branchDataWard = 'Phường Trấn Biên, TP. Đồng Nai, Tỉnh Đồng Nai';
const branchSecretaryName = 'Nguyễn Văn An';
const branchSecretaryPhone = '0912.345.678';

const recentSessions = [
  SessionRec(id: 'ses-1', date: '15/09/2026', title: 'Sinh hoạt tháng 9: Kỹ năng số cho thanh niên', attendees: 28, total: 46, rate: '60.9%', location: 'Nhà văn hóa Khu phố 5'),
  SessionRec(id: 'ses-2', date: '15/10/2026', title: 'Sinh hoạt tháng 10: Tuyên truyền ATGT & PCCC KCN', attendees: 19, total: 46, rate: '41.3%', location: 'Nhà văn hóa Khu phố 5', note: 'Nhiều công nhân tăng ca đêm tại KCN Amata'),
  SessionRec(id: 'ses-3', date: '15/11/2026', title: 'Sinh hoạt tháng 11: Ngày hội Thanh niên Đồng Nai', attendees: 33, total: 46, rate: '71.7%', location: 'Nhà văn hóa Khu phố 5', note: 'Đã triển khai thử nghiệm đăng ký sinh hoạt bù'),
];

final defaultActiveSession = ActiveSession(
  id: 'ses-next',
  title: 'Sinh hoạt Chi đoàn tháng 12: Thanh niên công nhân tiên phong Số hóa',
  date: '20:00 - Thứ Bảy, 28/11/2026',
  location: 'Nhà văn hóa Khu phố 5 (kết hợp trực tuyến)',
  format: 'hybrid',
  refreshSeconds: 60,
  geofenceRequired: true,
  allowShiftCatchup: true,
  expectedCount: 38,
  qrToken: 'KP5-202612-A7F9',
  qrSeed: 1,
);

List<AttendanceRec> _hist(List<List<String>> rows) => rows.map((r) => AttendanceRec(r[0], r[1], r[2])).toList();

final mockMembers = <Member>[
  Member(id: 'dv-01', name: 'Trần Minh Quân', phone: '0981.112.233', type: 'working_far', workplace: 'Cty Changshin - KCN Thạnh Phú', shift: 'Ca đêm (22h - 06h)', lastAttended: '15/11/2026', points: 95, makeupCount: 2, status: 'active', memberCode: 'ĐV-DN-001', joinDate: '26/03/2018', occupation: 'Công nhân sản xuất KCN', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9/2026', 'present', 'Có mặt trực tiếp'], ['Tháng 10/2026', 'makeup', 'Sinh hoạt bù (Làm ca 2)'], ['Tháng 11/2026', 'present', 'Có mặt trực tiếp']])),
  Member(id: 'dv-02', name: 'Lê Thị Thu Thảo', phone: '0972.223.344', type: 'working_far', workplace: 'Cty Taekwang Vina - KCN BH2', shift: 'Ca 2 (14h - 22h)', lastAttended: '15/11/2026', points: 88, makeupCount: 1, status: 'active', memberCode: 'ĐV-DN-002', joinDate: '15/05/2019', occupation: 'Công nhân sản xuất KCN', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9/2026', 'present', 'Có mặt trực tiếp'], ['Tháng 10/2026', 'absent', 'Vắng (Tăng ca đột xuất)'], ['Tháng 11/2026', 'makeup', 'Sinh hoạt bù E-Learning']])),
  Member(id: 'dv-03', name: 'Nguyễn Quốc Bảo', phone: '0903.334.455', type: 'working_far', workplace: 'KCN Amata Biên Hòa', shift: 'Ca 3 luân phiên', lastAttended: '15/10/2026', points: 72, makeupCount: 0, status: 'warning', memberCode: 'ĐV-DN-003', joinDate: '26/03/2020', occupation: 'Công nhân sản xuất KCN', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9/2026', 'absent', 'Vắng không phép'], ['Tháng 10/2026', 'present', 'Có mặt trực tiếp'], ['Tháng 11/2026', 'absent', 'Vắng (Ca 3 KCN Amata)']])),
  Member(id: 'dv-04', name: 'Phạm Thị Mỹ Linh', phone: '0914.445.566', type: 'working_far', workplace: 'KCN Long Đức, Long Thành', shift: 'Ca 1 (06h - 14h)', lastAttended: '15/11/2026', points: 90, makeupCount: 2, status: 'active', memberCode: 'ĐV-DN-004', joinDate: '19/05/2021', occupation: 'Công nhân sản xuất KCN', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9/2026', 'present', 'Có mặt trực tiếp'], ['Tháng 10/2026', 'makeup', 'Sinh hoạt bù trực tuyến'], ['Tháng 11/2026', 'present', 'Có mặt trực tiếp']])),
  Member(id: 'dv-05', name: 'Hoàng Văn Dũng', phone: '0985.556.677', type: 'working_far', workplace: 'KCN Nhơn Trạch 1', shift: 'Tăng ca kíp', lastAttended: '15/09/2026', points: 65, makeupCount: 1, status: 'warning', memberCode: 'ĐV-DN-005', joinDate: '26/03/2022', occupation: 'Công nhân sản xuất KCN', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9/2026', 'present', 'Có mặt trực tiếp'], ['Tháng 10/2026', 'absent', 'Vắng (Làm ca KCN Nhơn Trạch)'], ['Tháng 11/2026', 'absent', 'Đang chờ duyệt SH bù']])),
  Member(id: 'dv-06', name: 'Vũ Thị Ánh Tuyết', phone: '0966.667.788', type: 'working_far', workplace: 'KCN Hố Nai, Trảng Bom', shift: 'Ca ngày', lastAttended: '15/11/2026', points: 85, makeupCount: 1, status: 'active', memberCode: 'ĐV-DN-006', joinDate: '15/10/2023', occupation: 'Công nhân sản xuất KCN', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9/2026', 'present', 'Có mặt trực tiếp'], ['Tháng 10/2026', 'makeup', 'Sinh hoạt bù KP2'], ['Tháng 11/2026', 'present', 'Có mặt trực tiếp']])),
  Member(id: 'dv-07', name: 'Đặng Tuấn Khang', phone: '0977.778.899', type: 'working_far', workplace: 'KCN Giang Điền', shift: 'Ca 2 (14h - 22h)', lastAttended: '15/11/2026', points: 82, makeupCount: 1, status: 'active', memberCode: 'ĐV-DN-007', joinDate: '26/03/2018', occupation: 'Công nhân sản xuất KCN', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9/2026', 'absent', 'Vắng (Ca 2)'], ['Tháng 10/2026', 'present', 'Có mặt trực tiếp'], ['Tháng 11/2026', 'makeup', 'Sinh hoạt bù E-Learning']])),
  Member(id: 'dv-08', name: 'Bùi Diễm Hương', phone: '0918.889.900', type: 'working_far', workplace: 'Cty Fujitsu - KCN BH2', shift: 'Ca kíp 12h', lastAttended: '15/11/2026', points: 91, makeupCount: 2, status: 'active', memberCode: 'ĐV-DN-008', joinDate: '15/05/2019', occupation: 'Công nhân sản xuất KCN', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9/2026', 'present', 'Có mặt trực tiếp'], ['Tháng 10/2026', 'makeup', 'Sinh hoạt bù trực tuyến'], ['Tháng 11/2026', 'present', 'Có mặt trực tiếp']])),
  Member(id: 'dv-09', name: 'Đỗ Hữu Tài', phone: '0929.990.011', type: 'working_far', workplace: 'KCN Sông Mây, Trảng Bom', shift: 'Ca đêm', lastAttended: '15/10/2026', points: 74, makeupCount: 1, status: 'warning', memberCode: 'ĐV-DN-009', joinDate: '26/03/2020', occupation: 'Công nhân sản xuất KCN', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9/2026', 'absent', 'Vắng (Ca đêm)'], ['Tháng 10/2026', 'present', 'Có mặt trực tiếp'], ['Tháng 11/2026', 'absent', 'Chờ duyệt SH bù']])),
  Member(id: 'dv-10', name: 'Ngô Thanh Tú', phone: '0930.001.122', type: 'working_far', workplace: 'KCN Loteco Long Bình', shift: 'Ca ngày hành chính', lastAttended: '15/11/2026', points: 86, makeupCount: 0, status: 'active', memberCode: 'ĐV-DN-010', joinDate: '19/05/2021', occupation: 'Công nhân sản xuất KCN', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9/2026', 'present', 'Có mặt trực tiếp'], ['Tháng 10/2026', 'present', 'Có mặt trực tiếp'], ['Tháng 11/2026', 'present', 'Có mặt trực tiếp']])),
  Member(id: 'dv-11', name: 'Lý Quốc Huy', phone: '0941.112.233', type: 'working_far', workplace: 'KCN An Phước, Long Thành', shift: 'Ca 3 luân phiên', lastAttended: '15/09/2026', points: 68, makeupCount: 0, status: 'warning', memberCode: 'ĐV-DN-011', joinDate: '26/03/2022', occupation: 'Công nhân sản xuất KCN', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9/2026', 'present', 'Có mặt trực tiếp'], ['Tháng 10/2026', 'absent', 'Vắng (Ca 3)'], ['Tháng 11/2026', 'absent', 'Vắng không phép']])),
  Member(id: 'dv-12', name: 'Dương Thúy Vi', phone: '0952.223.344', type: 'working_far', workplace: 'Cty Hyosung - Nhơn Trạch', shift: 'Ca 2 (14h - 22h)', lastAttended: '15/11/2026', points: 89, makeupCount: 1, status: 'active', memberCode: 'ĐV-DN-012', joinDate: '15/10/2023', occupation: 'Công nhân sản xuất KCN', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9/2026', 'present', 'Có mặt trực tiếp'], ['Tháng 10/2026', 'makeup', 'Sinh hoạt bù KCN'], ['Tháng 11/2026', 'present', 'Có mặt trực tiếp']])),
  Member(id: 'dv-13', name: 'Nguyễn Tấn Đạt', phone: '0963.334.455', type: 'transferred', workplace: 'Đại học Đồng Nai (Chuyển đi)', shift: 'Sinh viên', lastAttended: '15/08/2026', points: 60, makeupCount: 0, status: 'pending_transfer', note: 'Chờ tiếp nhận tại ĐH Đồng Nai', memberCode: 'ĐV-DN-013', joinDate: '26/03/2018', occupation: 'Sinh viên', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9/2026', 'transferred', 'Chờ tiếp nhận'], ['Tháng 10/2026', 'transferred', 'Chờ tiếp nhận'], ['Tháng 11/2026', 'transferred', 'Chờ tiếp nhận']])),
  Member(id: 'dv-14', name: 'Trương Ngọc Hân', phone: '0974.445.566', type: 'transferred', workplace: 'Chuyển về P. Quyết Thắng', shift: 'Kinh doanh tự do', lastAttended: '15/08/2026', points: 55, makeupCount: 0, status: 'pending_transfer', note: 'Chuyển hộ khẩu về P. Quyết Thắng', memberCode: 'ĐV-DN-014', joinDate: '15/05/2019', occupation: 'Kinh doanh tự do', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9/2026', 'transferred', 'Chuyển địa bàn'], ['Tháng 10/2026', 'transferred', 'Chuyển địa bàn'], ['Tháng 11/2026', 'transferred', 'Chuyển địa bàn']])),
  Member(id: 'dv-15', name: 'Võ Đình Trọng', phone: '0985.556.677', type: 'transferred', workplace: 'Nghĩa vụ Quân sự Đồng Nai', shift: 'Chiến sĩ', lastAttended: '15/02/2026', points: 100, makeupCount: 0, status: 'military', note: 'Nhập ngũ đợt 1/2026', memberCode: 'ĐV-DN-015', joinDate: '26/03/2020', occupation: 'Chiến sĩ', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9/2026', 'military', 'Nghĩa vụ quân sự'], ['Tháng 10/2026', 'military', 'Nghĩa vụ quân sự'], ['Tháng 11/2026', 'military', 'Nghĩa vụ quân sự']])),
  Member(id: 'dv-16', name: 'Nguyễn Văn An (Bí thư)', phone: '0912.345.678', type: 'local', workplace: 'Hộ kinh doanh KP5', shift: 'Tự do', lastAttended: '15/11/2026', points: 98, makeupCount: 0, status: 'active', memberCode: 'ĐV-DN-016', joinDate: '19/05/2021', occupation: 'Cán bộ / Viên chức', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9', 'present', 'Có mặt'], ['Tháng 10', 'present', 'Có mặt'], ['Tháng 11', 'present', 'Có mặt']])),
  Member(id: 'dv-17', name: 'Trần Thị Mai', phone: '0901.123.456', type: 'local', workplace: 'Giáo viên Mầm non KP5', shift: 'Hành chính', lastAttended: '15/11/2026', points: 96, makeupCount: 0, status: 'active', memberCode: 'ĐV-DN-017', joinDate: '26/03/2022', occupation: 'Cán bộ / Viên chức', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9', 'present', 'Có mặt'], ['Tháng 10', 'present', 'Có mặt'], ['Tháng 11', 'present', 'Có mặt']])),
  Member(id: 'dv-18', name: 'Lê Hoàng Nam', phone: '0902.234.567', type: 'local', workplace: 'UBND Phường Trấn Biên', shift: 'Hành chính', lastAttended: '15/11/2026', points: 94, makeupCount: 0, status: 'active', memberCode: 'ĐV-DN-018', joinDate: '15/10/2023', occupation: 'Cán bộ / Viên chức', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9', 'present', 'Có mặt'], ['Tháng 10', 'present', 'Có mặt'], ['Tháng 11', 'present', 'Có mặt']])),
  Member(id: 'dv-19', name: 'Phạm Hồng Nhung', phone: '0903.345.678', type: 'local', workplace: 'Tiệm thuốc Trấn Biên', shift: 'Tại chỗ', lastAttended: '15/11/2026', points: 92, makeupCount: 0, status: 'active', memberCode: 'ĐV-DN-019', joinDate: '26/03/2018', occupation: 'Lao động địa phương', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9', 'present', 'Có mặt'], ['Tháng 10', 'present', 'Có mặt'], ['Tháng 11', 'present', 'Có mặt']])),
  Member(id: 'dv-20', name: 'Đoàn Thanh Tùng', phone: '0904.456.789', type: 'local', workplace: 'Kỹ sư IT tự do', shift: 'Remote', lastAttended: '15/11/2026', points: 95, makeupCount: 0, status: 'active', memberCode: 'ĐV-DN-020', joinDate: '15/05/2019', occupation: 'Lao động địa phương', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9', 'present', 'Có mặt'], ['Tháng 10', 'present', 'Có mặt'], ['Tháng 11', 'present', 'Có mặt']])),
  Member(id: 'dv-21', name: 'Vũ Minh Hằng', phone: '0905.567.890', type: 'local', workplace: 'CĐ Y tế Đồng Nai', shift: 'Học tập', lastAttended: '15/11/2026', points: 88, makeupCount: 0, status: 'active', memberCode: 'ĐV-DN-021', joinDate: '26/03/2020', occupation: 'Lao động địa phương', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9', 'present', 'Có mặt'], ['Tháng 10', 'present', 'Có mặt'], ['Tháng 11', 'present', 'Có mặt']])),
  Member(id: 'dv-22', name: 'Nguyễn Đăng Khoa', phone: '0906.678.901', type: 'local', workplace: 'Cửa hàng xe máy KP5', shift: 'Tại chỗ', lastAttended: '15/11/2026', points: 87, makeupCount: 0, status: 'active', memberCode: 'ĐV-DN-022', joinDate: '19/05/2021', occupation: 'Lao động địa phương', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9', 'present', 'Có mặt'], ['Tháng 10', 'present', 'Có mặt'], ['Tháng 11', 'present', 'Có mặt']])),
  Member(id: 'dv-23', name: 'Bùi Kim Oanh', phone: '0907.789.012', type: 'local', workplace: 'Kế toán tư nhân', shift: 'Hành chính', lastAttended: '15/11/2026', points: 91, makeupCount: 0, status: 'active', memberCode: 'ĐV-DN-023', joinDate: '26/03/2022', occupation: 'Lao động địa phương', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9', 'present', 'Có mặt'], ['Tháng 10', 'present', 'Có mặt'], ['Tháng 11', 'present', 'Có mặt']])),
  Member(id: 'dv-24', name: 'Đặng Quốc Anh', phone: '0908.890.123', type: 'local', workplace: 'Điện lực Biên Hòa', shift: 'Kỹ thuật', lastAttended: '15/11/2026', points: 93, makeupCount: 0, status: 'active', memberCode: 'ĐV-DN-024', joinDate: '15/10/2023', occupation: 'Lao động địa phương', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9', 'present', 'Có mặt'], ['Tháng 10', 'present', 'Có mặt'], ['Tháng 11', 'present', 'Có mặt']])),
  Member(id: 'dv-25', name: 'Trịnh Thị Lan', phone: '0909.901.234', type: 'local', workplace: 'Trường Tiểu học Trấn Biên', shift: 'Giáo viên', lastAttended: '15/11/2026', points: 95, makeupCount: 0, status: 'active', memberCode: 'ĐV-DN-025', joinDate: '26/03/2018', occupation: 'Cán bộ / Viên chức', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9', 'present', 'Có mặt'], ['Tháng 10', 'present', 'Có mặt'], ['Tháng 11', 'present', 'Có mặt']])),
  Member(id: 'dv-26', name: 'Phan Minh Trí', phone: '0910.012.345', type: 'local', workplace: 'Bưu điện Trấn Biên', shift: 'Bưu tá', lastAttended: '15/11/2026', points: 86, makeupCount: 0, status: 'active', memberCode: 'ĐV-DN-026', joinDate: '15/05/2019', occupation: 'Lao động địa phương', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9', 'present', 'Có mặt'], ['Tháng 10', 'present', 'Có mặt'], ['Tháng 11', 'present', 'Có mặt']])),
  Member(id: 'dv-27', name: 'Lê Thùy Dung', phone: '0911.123.456', type: 'local', workplace: 'Ngân hàng Agribank P. Trấn Biên', shift: 'Giao dịch viên', lastAttended: '15/11/2026', points: 97, makeupCount: 0, status: 'active', memberCode: 'ĐV-DN-027', joinDate: '26/03/2020', occupation: 'Lao động địa phương', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9', 'present', 'Có mặt'], ['Tháng 10', 'present', 'Có mặt'], ['Tháng 11', 'present', 'Có mặt']])),
  Member(id: 'dv-28', name: 'Tạ Văn Bình', phone: '0912.234.567', type: 'local', workplace: 'Xưởng mộc gia đình KP5', shift: 'Tại chỗ', lastAttended: '15/11/2026', points: 84, makeupCount: 0, status: 'active', memberCode: 'ĐV-DN-028', joinDate: '19/05/2021', occupation: 'Lao động địa phương', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9', 'present', 'Có mặt'], ['Tháng 10', 'present', 'Có mặt'], ['Tháng 11', 'present', 'Có mặt']])),
  Member(id: 'dv-29', name: 'Cao Thị Yến', phone: '0913.345.678', type: 'local', workplace: 'Cửa hàng tạp hóa KP5', shift: 'Tại chỗ', lastAttended: '15/11/2026', points: 89, makeupCount: 0, status: 'active', memberCode: 'ĐV-DN-029', joinDate: '26/03/2022', occupation: 'Lao động địa phương', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9', 'present', 'Có mặt'], ['Tháng 10', 'present', 'Có mặt'], ['Tháng 11', 'present', 'Có mặt']])),
  Member(id: 'dv-30', name: 'Ngô Đức Thắng', phone: '0914.456.789', type: 'local', workplace: 'Công ty vận tải Biên Hòa', shift: 'Tài xế', lastAttended: '15/11/2026', points: 82, makeupCount: 0, status: 'active', memberCode: 'ĐV-DN-030', joinDate: '15/10/2023', occupation: 'Lao động địa phương', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9', 'present', 'Có mặt'], ['Tháng 10', 'present', 'Có mặt'], ['Tháng 11', 'present', 'Có mặt']])),
  Member(id: 'dv-31', name: 'Mai Phương Uyên', phone: '0915.567.890', type: 'local', workplace: 'Trung tâm Ngoại ngữ KP5', shift: 'Trợ giảng', lastAttended: '15/11/2026', points: 94, makeupCount: 0, status: 'active', memberCode: 'ĐV-DN-031', joinDate: '26/03/2018', occupation: 'Lao động địa phương', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9', 'present', 'Có mặt'], ['Tháng 10', 'present', 'Có mặt'], ['Tháng 11', 'present', 'Có mặt']])),
  Member(id: 'dv-32', name: 'Lâm Hoàng Phúc', phone: '0916.678.901', type: 'local', workplace: 'Siêu thị Co.opmart Trấn Biên', shift: 'Thu ngân', lastAttended: '15/11/2026', points: 88, makeupCount: 0, status: 'active', memberCode: 'ĐV-DN-032', joinDate: '15/05/2019', occupation: 'Lao động địa phương', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9', 'present', 'Có mặt'], ['Tháng 10', 'present', 'Có mặt'], ['Tháng 11', 'present', 'Có mặt']])),
  Member(id: 'dv-33', name: 'Đoàn Thúy Nga', phone: '0917.789.012', type: 'local', workplace: 'Văn phòng Công chứng Đồng Nai', shift: 'Nhân viên', lastAttended: '15/11/2026', points: 92, makeupCount: 0, status: 'active', memberCode: 'ĐV-DN-033', joinDate: '26/03/2020', occupation: 'Lao động địa phương', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9', 'present', 'Có mặt'], ['Tháng 10', 'present', 'Có mặt'], ['Tháng 11', 'present', 'Có mặt']])),
  Member(id: 'dv-34', name: 'Phùng Văn Khôi', phone: '0918.890.123', type: 'local', workplace: 'Cửa hàng Viettel Trấn Biên', shift: 'Tư vấn', lastAttended: '15/11/2026', points: 87, makeupCount: 0, status: 'active', memberCode: 'ĐV-DN-034', joinDate: '19/05/2021', occupation: 'Lao động địa phương', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9', 'present', 'Có mặt'], ['Tháng 10', 'present', 'Có mặt'], ['Tháng 11', 'present', 'Có mặt']])),
  Member(id: 'dv-35', name: 'Hồ Quỳnh Chi', phone: '0919.901.234', type: 'local', workplace: 'Nha khoa Nụ Cười Xinh KP5', shift: 'Y tá', lastAttended: '15/11/2026', points: 90, makeupCount: 0, status: 'active', memberCode: 'ĐV-DN-035', joinDate: '26/03/2022', occupation: 'Lao động địa phương', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9', 'present', 'Có mặt'], ['Tháng 10', 'present', 'Có mặt'], ['Tháng 11', 'present', 'Có mặt']])),
  Member(id: 'dv-36', name: 'Thái Bá Đạt', phone: '0920.012.345', type: 'local', workplace: 'Đại lý phân phối Bia KP5', shift: 'Kinh doanh', lastAttended: '15/11/2026', points: 83, makeupCount: 0, status: 'active', memberCode: 'ĐV-DN-036', joinDate: '15/10/2023', occupation: 'Lao động địa phương', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9', 'present', 'Có mặt'], ['Tháng 10', 'present', 'Có mặt'], ['Tháng 11', 'present', 'Có mặt']])),
  Member(id: 'dv-37', name: 'Vương Bảo Trâm', phone: '0921.123.456', type: 'local', workplace: 'Phòng Gym Fitness Trấn Biên', shift: 'Huấn luyện viên', lastAttended: '15/11/2026', points: 91, makeupCount: 0, status: 'active', memberCode: 'ĐV-DN-037', joinDate: '26/03/2018', occupation: 'Lao động địa phương', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9', 'present', 'Có mặt'], ['Tháng 10', 'present', 'Có mặt'], ['Tháng 11', 'present', 'Có mặt']])),
  Member(id: 'dv-38', name: 'Lương Thế Vinh', phone: '0922.234.567', type: 'local', workplace: 'Đồ họa freelance KP5', shift: 'Tự do', lastAttended: '15/11/2026', points: 86, makeupCount: 0, status: 'active', memberCode: 'ĐV-DN-038', joinDate: '15/05/2019', occupation: 'Lao động địa phương', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9', 'present', 'Có mặt'], ['Tháng 10', 'present', 'Có mặt'], ['Tháng 11', 'present', 'Có mặt']])),
  Member(id: 'dv-39', name: 'Đào Bích Ngọc', phone: '0923.345.678', type: 'local', workplace: 'Quán Cafe Thanh Niên KP5', shift: 'Quản lý', lastAttended: '15/11/2026', points: 95, makeupCount: 0, status: 'active', memberCode: 'ĐV-DN-039', joinDate: '26/03/2020', occupation: 'Lao động địa phương', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9', 'present', 'Có mặt'], ['Tháng 10', 'present', 'Có mặt'], ['Tháng 11', 'present', 'Có mặt']])),
  Member(id: 'dv-40', name: 'Bùi Gia Huy', phone: '0924.456.789', type: 'local', workplace: 'Garage sửa xe Trấn Biên', shift: 'Thợ máy', lastAttended: '15/11/2026', points: 81, makeupCount: 0, status: 'active', memberCode: 'ĐV-DN-040', joinDate: '19/05/2021', occupation: 'Lao động địa phương', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9', 'present', 'Có mặt'], ['Tháng 10', 'present', 'Có mặt'], ['Tháng 11', 'present', 'Có mặt']])),
  Member(id: 'dv-41', name: 'Quách Ánh Dương', phone: '0925.567.890', type: 'local', workplace: 'Cửa hàng hoa tươi KP5', shift: 'Cắm hoa', lastAttended: '15/11/2026', points: 89, makeupCount: 0, status: 'active', memberCode: 'ĐV-DN-041', joinDate: '26/03/2022', occupation: 'Lao động địa phương', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9', 'present', 'Có mặt'], ['Tháng 10', 'present', 'Có mặt'], ['Tháng 11', 'present', 'Có mặt']])),
  Member(id: 'dv-42', name: 'Nghiêm Đình Long', phone: '0926.678.901', type: 'local', workplace: 'Khu thể thao Trấn Biên', shift: 'Nhân viên', lastAttended: '15/11/2026', points: 85, makeupCount: 0, status: 'active', memberCode: 'ĐV-DN-042', joinDate: '15/10/2023', occupation: 'Lao động địa phương', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9', 'present', 'Có mặt'], ['Tháng 10', 'present', 'Có mặt'], ['Tháng 11', 'present', 'Có mặt']])),
  Member(id: 'dv-43', name: 'Hà Thị Kim Liên', phone: '0927.789.012', type: 'local', workplace: 'Xưởng may thời trang KP5', shift: 'Thiết kế', lastAttended: '15/11/2026', points: 92, makeupCount: 0, status: 'active', memberCode: 'ĐV-DN-043', joinDate: '26/03/2018', occupation: 'Lao động địa phương', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9', 'present', 'Có mặt'], ['Tháng 10', 'present', 'Có mặt'], ['Tháng 11', 'present', 'Có mặt']])),
  Member(id: 'dv-44', name: 'Trần Văn Hoàng', phone: '0928.890.123', type: 'local', workplace: 'Cửa hàng nhôm kính KP5', shift: 'Thợ chính', lastAttended: '15/11/2026', points: 84, makeupCount: 0, status: 'active', memberCode: 'ĐV-DN-044', joinDate: '15/05/2019', occupation: 'Lao động địa phương', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9', 'present', 'Có mặt'], ['Tháng 10', 'present', 'Có mặt'], ['Tháng 11', 'present', 'Có mặt']])),
  Member(id: 'dv-45', name: 'Chu Mỹ Duyên', phone: '0929.901.234', type: 'local', workplace: 'Shop mỹ phẩm Trấn Biên', shift: 'Bán hàng', lastAttended: '15/11/2026', points: 88, makeupCount: 0, status: 'active', memberCode: 'ĐV-DN-045', joinDate: '26/03/2020', occupation: 'Lao động địa phương', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9', 'present', 'Có mặt'], ['Tháng 10', 'present', 'Có mặt'], ['Tháng 11', 'present', 'Có mặt']])),
  Member(id: 'dv-46', name: 'Tạ Minh Khôi', phone: '0930.012.345', type: 'local', workplace: 'Công ty thiết bị điện KP5', shift: 'Giao nhận', lastAttended: '15/11/2026', points: 87, makeupCount: 0, status: 'active', memberCode: 'ĐV-DN-046', joinDate: '19/05/2021', occupation: 'Lao động địa phương', branchName: 'Chi đoàn Khu phố 5', attendanceHistory: _hist([['Tháng 9', 'present', 'Có mặt'], ['Tháng 10', 'present', 'Có mặt'], ['Tháng 11', 'present', 'Có mặt']])),
];

final initialScannedMemberIds = ['dv-16', 'dv-17', 'dv-18', 'dv-19', 'dv-20', 'dv-21', 'dv-22', 'dv-23', 'dv-24', 'dv-25', 'dv-26', 'dv-27', 'dv-28', 'dv-29', 'dv-30', 'dv-31', 'dv-02', 'dv-04'];

final initialMemberAttendanceHistory = [
  AttendanceHistoryItem(id: 'h-1', sessionName: 'Sinh hoạt tháng 11: Ngày hội Thanh niên Đồng Nai', date: '15/11/2026', status: 'attended', badge: 'Đã tham gia', pointsEarned: '+10 điểm', type: 'Trực tiếp tại Nhà văn hóa KP5'),
  AttendanceHistoryItem(id: 'h-2', sessionName: 'Sinh hoạt tháng 10: Tuyên truyền ATGT & PCCC KCN', date: '15/10/2026', status: 'makeup', badge: 'Sinh hoạt bù', pointsEarned: '+10 điểm', type: 'Làm ca 2 Changshin - Học chuyên đề online 18/10'),
  AttendanceHistoryItem(id: 'h-3', sessionName: 'Sinh hoạt tháng 9: Kỹ năng số cho thanh niên', date: '15/09/2026', status: 'attended', badge: 'Đã tham gia', pointsEarned: '+10 điểm', type: 'Trực tiếp tại Nhà văn hóa KP5'),
];

BranchRank _br(String id, String name, String secretary, int total, int attended, double rate, String status, String type, {bool highlight = false}) =>
    BranchRank(id: id, name: name, secretary: secretary, total: total, attended: attended, rate: rate, status: status, type: type, highlight: highlight);

final wardDataByMonth = <String, MonthWardData>{
  '11': MonthWardData(
    key: '11', monthLabel: 'Tháng 11/2026', reportDateText: 'Trấn Biên, ngày 28 tháng 11 năm 2026', reportNumber: 'Số: 18-BC/ĐTN',
    totalBranches: 12, totalMembers: 485, averageAttendanceRate: '73.4%', completedReports: '11/12 Chi đoàn',
    branchesRank: [
      _br('kp1', 'Chi đoàn Khu phố 1', 'Đ/c Lê Hoàng Minh', 42, 36, 85.7, 'submitted', 'Khu dân cư'),
      _br('thcs', 'Chi đoàn Trường THCS Trấn Biên', 'Đ/c Nguyễn Ngọc Ánh', 28, 24, 85.7, 'submitted', 'Trường học'),
      _br('kp7', 'Chi đoàn Khu phố 7', 'Đ/c Phạm Văn Hùng', 36, 30, 83.3, 'submitted', 'Khu dân cư'),
      _br('kp4', 'Chi đoàn Khu phố 4', 'Đ/c Trần Quốc Tuấn', 35, 29, 82.9, 'submitted', 'Khu dân cư'),
      _br('yte', 'Chi đoàn Trạm Y tế & Dân quân', 'Đ/c Võ Minh Đức', 24, 19, 79.2, 'submitted', 'Hành chính sự nghiệp'),
      _br('kp2', 'Chi đoàn Khu phố 2', 'Đ/c Đỗ Thị Thanh Hà', 38, 30, 78.9, 'submitted', 'Khu dân cư'),
      _br('kp8', 'Chi đoàn Khu phố 8', 'Đ/c Bùi Tiến Dũng', 34, 26, 76.5, 'submitted', 'Khu dân cư'),
      _br('kp5', 'Chi đoàn Khu phố 5 (Bí thư An)', 'Đ/c Nguyễn Văn An', 46, 33, 71.7, 'submitted', 'Khu dân cư & CN KCN', highlight: true),
      _br('tm', 'Chi đoàn Khu Nhà trọ Công nhân', 'Đ/c Hoàng Thị Thu', 52, 36, 69.2, 'submitted', 'Thanh niên công nhân'),
      _br('kp3', 'Chi đoàn Khu phố 3', 'Đ/c Vũ Đình Khoa', 50, 34, 68.0, 'submitted', 'Khu dân cư'),
      _br('kcn', 'Chi đoàn DN KCN Trấn Biên', 'Đ/c Lý Gia Bảo', 60, 37, 61.7, 'submitted', 'Doanh nghiệp KCN'),
      _br('kp6', 'Chi đoàn Khu phố 6', 'Đ/c Mai Văn Hải', 40, 22, 55.0, 'pending', 'Khu dân cư'),
    ],
  ),
  '10': MonthWardData(
    key: '10', monthLabel: 'Tháng 10/2026', reportDateText: 'Trấn Biên, ngày 31 tháng 10 năm 2026', reportNumber: 'Số: 15-BC/ĐTN',
    totalBranches: 12, totalMembers: 485, averageAttendanceRate: '58.1%', completedReports: '10/12 Chi đoàn',
    branchesRank: [
      _br('kp1', 'Chi đoàn Khu phố 1', 'Đ/c Lê Hoàng Minh', 42, 31, 73.8, 'submitted', 'Khu dân cư'),
      _br('kp4', 'Chi đoàn Khu phố 4', 'Đ/c Trần Quốc Tuấn', 35, 25, 71.4, 'submitted', 'Khu dân cư'),
      _br('thcs', 'Chi đoàn Trường THCS Trấn Biên', 'Đ/c Nguyễn Ngọc Ánh', 28, 20, 71.4, 'submitted', 'Trường học'),
      _br('yte', 'Chi đoàn Trạm Y tế & Dân quân', 'Đ/c Võ Minh Đức', 24, 16, 66.7, 'submitted', 'Hành chính sự nghiệp'),
      _br('kp7', 'Chi đoàn Khu phố 7', 'Đ/c Phạm Văn Hùng', 36, 23, 63.9, 'submitted', 'Khu dân cư'),
      _br('kp2', 'Chi đoàn Khu phố 2', 'Đ/c Đỗ Thị Thanh Hà', 38, 24, 63.2, 'submitted', 'Khu dân cư'),
      _br('kp8', 'Chi đoàn Khu phố 8', 'Đ/c Bùi Tiến Dũng', 34, 21, 61.8, 'submitted', 'Khu dân cư'),
      _br('kp3', 'Chi đoàn Khu phố 3', 'Đ/c Vũ Đình Khoa', 50, 28, 56.0, 'submitted', 'Khu dân cư'),
      _br('tm', 'Chi đoàn Khu Nhà trọ Công nhân', 'Đ/c Hoàng Thị Thu', 52, 29, 55.8, 'pending', 'Thanh niên công nhân'),
      _br('kcn', 'Chi đoàn DN KCN Trấn Biên', 'Đ/c Lý Gia Bảo', 60, 30, 50.0, 'submitted', 'Doanh nghiệp KCN'),
      _br('kp5', 'Chi đoàn Khu phố 5 (Bí thư An)', 'Đ/c Nguyễn Văn An', 46, 19, 41.3, 'submitted', 'Khu dân cư & CN KCN', highlight: true),
      _br('kp6', 'Chi đoàn Khu phố 6', 'Đ/c Mai Văn Hải', 40, 16, 40.0, 'pending', 'Khu dân cư'),
    ],
  ),
  '09': MonthWardData(
    key: '09', monthLabel: 'Tháng 09/2026', reportDateText: 'Trấn Biên, ngày 30 tháng 09 năm 2026', reportNumber: 'Số: 12-BC/ĐTN',
    totalBranches: 12, totalMembers: 485, averageAttendanceRate: '67.0%', completedReports: '12/12 Chi đoàn',
    branchesRank: [
      _br('kp1', 'Chi đoàn Khu phố 1', 'Đ/c Lê Hoàng Minh', 42, 35, 83.3, 'submitted', 'Khu dân cư'),
      _br('thcs', 'Chi đoàn Trường THCS Trấn Biên', 'Đ/c Nguyễn Ngọc Ánh', 28, 22, 78.6, 'submitted', 'Trường học'),
      _br('kp4', 'Chi đoàn Khu phố 4', 'Đ/c Trần Quốc Tuấn', 35, 27, 77.1, 'submitted', 'Khu dân cư'),
      _br('yte', 'Chi đoàn Trạm Y tế & Dân quân', 'Đ/c Võ Minh Đức', 24, 18, 75.0, 'submitted', 'Hành chính sự nghiệp'),
      _br('kp7', 'Chi đoàn Khu phố 7', 'Đ/c Phạm Văn Hùng', 36, 26, 72.2, 'submitted', 'Khu dân cư'),
      _br('kp2', 'Chi đoàn Khu phố 2', 'Đ/c Đỗ Thị Thanh Hà', 38, 27, 71.1, 'submitted', 'Khu dân cư'),
      _br('kp8', 'Chi đoàn Khu phố 8', 'Đ/c Bùi Tiến Dũng', 34, 24, 70.6, 'submitted', 'Khu dân cư'),
      _br('tm', 'Chi đoàn Khu Nhà trọ Công nhân', 'Đ/c Hoàng Thị Thu', 52, 35, 67.3, 'submitted', 'Thanh niên công nhân'),
      _br('kp5', 'Chi đoàn Khu phố 5 (Bí thư An)', 'Đ/c Nguyễn Văn An', 46, 28, 60.9, 'submitted', 'Khu dân cư & CN KCN', highlight: true),
      _br('kp3', 'Chi đoàn Khu phố 3', 'Đ/c Vũ Đình Khoa', 50, 30, 60.0, 'submitted', 'Khu dân cư'),
      _br('kcn', 'Chi đoàn DN KCN Trấn Biên', 'Đ/c Lý Gia Bảo', 60, 33, 55.0, 'submitted', 'Doanh nghiệp KCN'),
      _br('kp6', 'Chi đoàn Khu phố 6', 'Đ/c Mai Văn Hải', 40, 20, 50.0, 'submitted', 'Khu dân cư'),
    ],
  ),
};

const wardOfficerName = 'Phan Thị Bích Thảo';
const wardOfficerRole = 'Cán bộ Đoàn Phường Trấn Biên';
const wardOfficerPhone = '0908.123.999';
const wardDataName = 'Đoàn Thanh niên Phường Trấn Biên';

final makeupSessions = [
  MakeupSession(id: 'mk-01', branchName: 'Chi đoàn Khối Doanh nghiệp KCN Amata', title: 'Sinh hoạt bù Chuyên đề: Kỹ năng an toàn lao động & Quyền lợi công đoàn', time: '09:00 - Chủ Nhật, 29/11/2026', format: 'Trực tiếp tại Nhà sinh hoạt Công nhân KCN Amata', seatsLeft: 8, suitableFor: 'Công nhân làm ca 2, ca đêm'),
  MakeupSession(id: 'mk-02', branchName: 'Chi đoàn Khu phố 2 (Liên kết)', title: 'Sinh hoạt ghép: Chuyển đổi số trong sinh hoạt Đoàn thanh niên', time: '19:30 - Thứ Hai, 30/11/2026', format: 'Trực tiếp tại Nhà văn hóa KP2', seatsLeft: 12, suitableFor: 'Công nhân làm ca 1'),
  MakeupSession(id: 'mk-03', branchName: 'Tỉnh Đoàn Đồng Nai (Trực tuyến)', title: 'E-Learning: Học tập Chuyên đề Kỹ năng số & Chuyển đổi số Đồng Nai', time: 'Linh hoạt (Hoàn thành bài trắc nghiệm 3 câu)', format: 'Trực tuyến 100% trên App (Tự động cấp chứng nhận)', seatsLeft: 999, suitableFor: 'Tất cả đoàn viên làm ca kíp khó sắp xếp thời gian'),
];

final initialMakeupRequests = [
  MakeupRequest(id: 'req-00', memberId: 'dv-02', memberName: 'Lê Thị Thu Thảo', workplace: 'Cty Taekwang Vina - KCN BH2', shift: 'Ca 2 (14h - 22h)', sessionName: 'Sinh hoạt tháng 11: Ngày hội Thanh niên', registeredMakeup: 'E-Learning Kỹ năng số Đồng Nai (Đã đạt 3/3 câu)', reason: 'Làm ca 2 tại KCN Biên Hòa 2, hoàn thành học trực tuyến chuyên đề số hóa.', proof: 'Chứng chỉ E-Learning mã số DN-EL-8790', status: 'approved', autoPointsAwarded: true),
  MakeupRequest(id: 'req-01', memberId: 'dv-05', memberName: 'Hoàng Văn Dũng', workplace: 'KCN Nhơn Trạch 1', shift: 'Tăng ca đêm kíp 12h', sessionName: 'Sinh hoạt tháng 11: Ngày hội Thanh niên', registeredMakeup: 'Sinh hoạt bù KP2 (Thứ Hai 30/11)', reason: 'Do công ty chạy đơn hàng xuất khẩu cuối năm, phải tăng ca đêm từ 18h đến 06h sáng.', proof: 'Có xác nhận tăng ca của Quản đốc xưởng', status: 'pending'),
  MakeupRequest(id: 'req-02', memberId: 'dv-09', memberName: 'Đỗ Hữu Tài', workplace: 'KCN Sông Mây, Trảng Bom', shift: 'Ca đêm', sessionName: 'Sinh hoạt tháng 11: Ngày hội Thanh niên', registeredMakeup: 'E-Learning Kỹ năng số Đồng Nai (Đã đạt 3/3 câu)', reason: 'Làm ca đêm tại KCN Sông Mây, đã tự học và hoàn thành bài kiểm tra E-Learning.', proof: 'Chứng chỉ E-Learning mã số DN-EL-8831', status: 'pending', autoPointsAwarded: true),
];

final quizQuestions = [
  QuizQuestion(id: 1, question: 'Nghị quyết Chuyển đổi số tỉnh Đồng Nai xác định lực lượng nào giữ vai trò tiên phong nòng cốt trong các Tổ công nghệ số cộng đồng?', options: ['A. Lực lượng Đoàn viên, Thanh niên Đồng Nai', 'B. Các doanh nghiệp cung cấp viễn thông', 'C. Hội Phụ nữ và Hội Nông dân cơ sở', 'D. Bộ phận Tiếp nhận và Trả kết quả một cửa'], correctAnswer: 0),
  QuizQuestion(id: 2, question: 'Theo hướng dẫn đổi mới sinh hoạt Đoàn cho công nhân làm ca tại các KCN Đồng Nai, giải pháp nào được áp dụng khi đoàn viên trùng ca sản xuất?', options: ['A. Xóa tên khỏi danh sách Đoàn viên sau 2 kỳ', 'B. Đăng ký sinh hoạt bù liên chi đoàn hoặc học chuyên đề E-Learning', 'C. Buộc phải xin nghỉ việc không lương để đi họp', 'D. Nhờ người khác đi họp và điểm danh hộ'], correctAnswer: 1),
  QuizQuestion(id: 3, question: 'Ứng dụng "Đoàn Viên Số Đồng Nai" sử dụng cơ chế bảo mật nào để chống gian lận điểm danh?', options: ['A. Chụp ảnh thẻ đoàn viên giấy gửi vào nhóm chat', 'B. Ký tên thủ công trên sổ tay bí thư', 'C. Mã QR động thay đổi theo thời gian thực kết hợp định vị GPS Geofencing', 'D. Điểm danh qua danh sách gọi tên miệng'], correctAnswer: 2),
];

final rewardItems = [
  RewardItem(id: 'rw-1', title: 'Voucher Xăng Petrolimex 50.000đ', points: 30, category: 'Hỗ trợ đi lại công nhân KCN', sponsor: 'Công đoàn Các KCN Đồng Nai', icon: 'fuel', badge: 'Phổ biến', available: 45),
  RewardItem(id: 'rw-2', title: 'Vé xem phim Lotte Cinema Vincom Biên Hòa', points: 40, category: 'Văn hóa giải trí thanh niên', sponsor: 'Tỉnh Đoàn Đồng Nai', icon: 'film', available: 20),
  RewardItem(id: 'rw-3', title: 'Áo thun Thanh niên Đồng Nai 2026', points: 50, category: 'Đồng phục thanh niên số', sponsor: 'Tỉnh Đoàn Đồng Nai', icon: 'shirt', available: 15),
  RewardItem(id: 'rw-4', title: 'Vé Xe Tết Sum Vầy Về Quê Đón Tết', points: 80, category: 'Chương trình Tết công nhân KCN', sponsor: 'Liên đoàn Lao động Tỉnh Đồng Nai', icon: 'bus', badge: 'Ý nghĩa Tết', available: 10),
];

final volunteerActivities = [
  VolunteerActivity(id: 'act-1', title: 'Ngày Thứ Bảy Tình Nguyện - Dọn dẹp vệ sinh đường nội bộ KCN Biên Hòa 2', date: '21/11/2026', location: 'Đường 2A, KCN Biên Hòa 2', points: '+20 điểm', pointsValue: 20, participantsCount: 42, status: 'completed'),
  VolunteerActivity(id: 'act-2', title: 'Hiến máu tình nguyện "Giọt hồng Đất Bưởi - Đồng Nai"', date: '08/11/2026', location: 'Trung tâm Văn hóa Thanh thiếu nhi Đồng Nai', points: '+30 điểm', pointsValue: 30, participantsCount: 68, status: 'completed'),
  VolunteerActivity(id: 'act-3', title: 'Hỗ trợ người dân cài đặt chữ ký số và VNeID tại UBND Phường', date: '15/10/2026', location: 'UBND Phường Trấn Biên, Biên Hòa', points: '+15 điểm', pointsValue: 15, participantsCount: 25, status: 'completed'),
  VolunteerActivity(id: 'act-4', title: 'Chiến dịch Mùa Đông Ấm thanh niên công nhân xa quê', date: '05/12/2026 (08:00 - 11:30)', location: 'Khu nhà trọ công nhân KP5 & KCN Amata', points: '+25 điểm', pointsValue: 25, participantsCount: 19, status: 'upcoming'),
  VolunteerActivity(id: 'act-5', title: 'Đội hình Thanh niên Tình nguyện hỗ trợ dịch vụ công trực tuyến', date: '12/12/2026 (07:30 - 11:00)', location: 'Bộ phận Một cửa Phường Trấn Biên', points: '+20 điểm', pointsValue: 20, participantsCount: 14, status: 'upcoming'),
];

final initialNotifications = <String, List<AppNotification>>{
  'secretary': [
    AppNotification(id: 'noti-sec-1', title: 'Có 2 đơn xin sinh hoạt bù cần phê duyệt', content: 'Đ/c Hoàng Văn Dũng (KCN Nhơn Trạch 1) và Đ/c Đỗ Hữu Tài (KCN Sông Mây) đã gửi minh chứng làm ca đêm.', time: '10 phút trước', type: 'makeup', unread: true),
    AppNotification(id: 'noti-sec-2', title: 'Nhắc lịch mở mã QR sinh hoạt tháng 12', content: 'Buổi sinh hoạt chuyên đề "Thanh niên công nhân tiên phong Số hóa" diễn ra lúc 20:00 ngày 28/11 tại NVH KP5.', time: '1 giờ trước', type: 'event', unread: true),
    AppNotification(id: 'noti-sec-3', title: 'Đoàn Phường Trấn Biên ghi nhận báo cáo T11', content: 'Chi đoàn KP5 đạt tỷ lệ 71.7% (+30.4% so với tháng 10) nhờ triển khai cơ chế ca bù.', time: 'Hôm qua', type: 'report', unread: false),
  ],
  'member': [
    AppNotification(id: 'noti-mem-1', title: 'Nhắc lịch sinh hoạt Chi đoàn tháng 12/2026', content: 'Chủ đề: "Thanh niên công nhân tiên phong Số hóa". 20:00 Thứ Bảy 28/11 tại Nhà văn hóa KP5.', time: '15 phút trước', type: 'event', unread: true),
    AppNotification(id: 'noti-mem-2', title: 'Mở đăng ký ca sinh hoạt bù KCN', content: 'Đoàn viên làm ca đêm có thể đăng ký sinh hoạt ghép với Chi đoàn KCN Amata hoặc học E-Learning trực tuyến.', time: '2 giờ trước', type: 'makeup', unread: true),
    AppNotification(id: 'noti-mem-3', title: 'Cập nhật điểm rèn luyện thi đua', content: 'Bạn đã được cộng +20 điểm từ hoạt động "Ngày Thứ Bảy Tình Nguyện dọn dẹp KCN Biên Hòa 2".', time: 'Hôm qua', type: 'reward', unread: false),
  ],
  'ward_officer': [
    AppNotification(id: 'noti-ward-1', title: 'Còn 1 chi đoàn chưa nộp báo cáo tháng 11', content: 'Chi đoàn Khu phố 6 (tỷ lệ 55.0%) chưa hoàn tất xác nhận số liệu. Vui lòng gửi nhắc nhở qua Zalo.', time: '20 phút trước', type: 'report', unread: true),
    AppNotification(id: 'noti-ward-2', title: 'Điểm sáng mô hình ca bù tại KP5', content: 'Chi đoàn KP5 nâng tỷ lệ tham dự từ 41.3% (T10) lên 71.7% (T11) nhờ E-Learning & sinh hoạt ghép.', time: '3 giờ trước', type: 'event', unread: false),
  ],
};

final socialEventPresets = [
  {'id': 'ev-img-1', 'label': 'Chiến dịch Tình nguyện Xanh', 'eventTag': 'Chiến dịch Mùa Đông Ấm & Hỗ trợ Thanh niên'},
  {'id': 'ev-img-2', 'label': 'Hiến máu Giọt hồng Đồng Nai', 'eventTag': 'Hiến máu tình nguyện "Giọt hồng Đất Bưởi - Đồng Nai"'},
  {'id': 'ev-img-3', 'label': 'Sinh hoạt Chi đoàn định kỳ', 'eventTag': 'Sinh hoạt Chi đoàn Khu phố 5 - Tháng 12/2026'},
  {'id': 'ev-img-4', 'label': 'Hỗ trợ Dịch vụ công trực tuyến', 'eventTag': 'Đội hình Thanh niên Tình nguyện hỗ trợ VNeID'},
];

final scheduleWeekDays = [
  {'key': 'all', 'label': 'Tất cả', 'dayNum': 'Tuần'},
  {'key': '25/11/2026', 'label': 'T4', 'dayNum': '25'},
  {'key': '26/11/2026', 'label': 'T5', 'dayNum': '26'},
  {'key': '27/11/2026', 'label': 'T6', 'dayNum': '27'},
  {'key': '28/11/2026', 'label': 'T7', 'dayNum': '28'},
  {'key': '29/11/2026', 'label': 'CN', 'dayNum': '29'},
  {'key': '30/11/2026', 'label': 'T2', 'dayNum': '30'},
];

final initialMySchedule = [
  ScheduleItem(id: 'sch-01', title: 'Sinh hoạt Chi đoàn tháng 12: Thanh niên tiên phong Số hóa', category: 'Sinh hoạt', dateStr: '28/11/2026', dayOfWeek: 'T7', timeSlot: '19:30 - 21:00', room: 'Nhà văn hóa Khu phố 5', organizer: 'BCH Chi đoàn Khu phố 5', format: 'Trực tiếp • Điểm danh QR', points: '+10 điểm', mandatory: true, isELearning: false),
  ScheduleItem(id: 'sch-02', title: 'Chuyên đề: Kỹ năng số & An toàn không gian mạng', category: 'Chuyên đề', dateStr: '26/11/2026', dayOfWeek: 'T5', timeSlot: '20:00 - 21:00', room: 'Trực tuyến trên ứng dụng', organizer: 'Tỉnh Đoàn Đồng Nai', format: 'Trực tuyến E-Learning', points: '+10 điểm', isELearning: true),
];

final scheduleCatalog = [
  ScheduleItem(id: 'cat-01', title: 'Tọa đàm Thanh niên với Chuyển đổi số & Dịch vụ công', category: 'Chuyên đề', dateStr: '27/11/2026', dayOfWeek: 'T6', timeSlot: '19:00 - 20:30', room: 'Hội trường UBND Phường Trấn Biên', organizer: 'Đoàn Phường Trấn Biên', format: 'Trực tiếp • Kết hợp Livestream', points: '+15 điểm', seatsLeft: 18, isELearning: false),
  ScheduleItem(id: 'cat-02', title: 'Đội hình Xung kích Hỗ trợ cài đặt VNeID & Chữ ký số', category: 'Tình nguyện', dateStr: '25/11/2026', dayOfWeek: 'T4', timeSlot: '08:00 - 11:00', room: 'Bộ phận Một cửa P. Trấn Biên', organizer: 'Đoàn Phường Trấn Biên', format: 'Trực tiếp', points: '+20 điểm', seatsLeft: 12, isELearning: false),
  ScheduleItem(id: 'cat-03', title: 'Tập huấn: Nghiệp vụ Đoàn viên & Quản lý Hồ sơ số', category: 'Chuyên đề', dateStr: '30/11/2026', dayOfWeek: 'T2', timeSlot: '19:30 - 20:45', room: 'Trực tuyến trên ứng dụng', organizer: 'Ban Tuyên giáo Tỉnh Đoàn', format: 'Trực tuyến • Có trắc nghiệm', points: '+15 điểm', seatsLeft: 999, isELearning: true),
  ScheduleItem(id: 'cat-04', title: 'Sinh hoạt Liên Chi đoàn Quý IV & Giao lưu Thanh niên', category: 'Sinh hoạt', dateStr: '30/11/2026', dayOfWeek: 'T2', timeSlot: '18:00 - 19:30', room: 'Trung tâm Văn hóa Thanh thiếu nhi', organizer: 'Tỉnh Đoàn Đồng Nai', format: 'Trực tiếp', points: '+10 điểm', seatsLeft: 25, isELearning: false),
];

final initialSocialPosts = [
  SocialPost(
    id: 'post-event-1', authorId: 'ward-01', authorName: 'Phan Thị Bích Thảo', authorRole: 'Cán bộ Đoàn Phường Trấn Biên • Cán bộ phát động', authorAvatar: 'Phan Thị Bích Thảo', branchName: 'Đoàn Phường Trấn Biên', category: 'event', eventTag: 'Chiến dịch Mùa Đông Ấm & Hỗ trợ Thanh niên', isEventPost: true, verifiedOfficer: true, verifiedParticipant: true, registeredCount: 34, registeredByMe: false,
    eventSchedule: ScheduleItem(id: 'ev-soc-1', title: 'Chiến dịch Mùa Đông Ấm & Hỗ trợ Thanh niên', category: 'Sự kiện Đoàn', dateStr: '29/11/2026', dayOfWeek: 'CN', timeSlot: '07:30 - 11:00', room: 'Nhà văn hóa KP5 & Khu vực Trấn Biên', organizer: 'BCH Đoàn Phường Trấn Biên', format: 'Trực tiếp • Điểm danh QR', points: '+25 điểm', isELearning: false),
    createdAt: '30 phút trước',
    content: 'Phát động Chiến dịch Mùa Đông Ấm tháng 11/2026! Kính mời các đồng chí đoàn viên đăng ký tham dự trực tiếp ngay bên dưới để hệ thống tự động đồng bộ vào Lịch cá nhân.',
    imageUrl: '1', likesCount: 42, likedByMe: false,
    comments: [Comment(id: 'cmt-ev-1', authorName: 'Nguyễn Văn An (Bí thư KP5)', text: 'Chi đoàn Khu phố 5 đã sẵn sàng lực lượng nòng cốt tham gia!', time: '15 phút trước')],
  ),
  SocialPost(
    id: 'post-1', authorId: 'dv-02', authorName: 'Lê Thị Thu Thảo', authorRole: 'Đoàn viên Chi đoàn KP5', authorAvatar: 'Lê Thị Thu Thảo', branchName: 'Chi đoàn Khu phố 5', category: 'event', eventTag: 'Ngày Thứ Bảy Tình Nguyện — Dọn dẹp Tuyến đường KCN', isEventPost: true, verifiedOfficer: false, verifiedParticipant: true, registeredCount: 22, registeredByMe: false,
    eventSchedule: ScheduleItem(id: 'ev-soc-2', title: 'Ngày Thứ Bảy Tình Nguyện — Tuyến đường Xanh', category: 'Tình nguyện', dateStr: '28/11/2026', dayOfWeek: 'T7', timeSlot: '07:30 - 10:00', room: 'Tuyến đường nội bộ KCN Biên Hòa 2', organizer: 'Chi đoàn Khu phố 5', format: 'Trực tiếp • Điểm danh QR', points: '+20 điểm', isELearning: false),
    createdAt: '2 giờ trước',
    content: 'Cùng anh chị em Chi đoàn KP5 ra quân dọn vệ sinh tuyến đường xanh - sạch - đẹp sáng cuối tuần. Các bạn có thể bấm đăng ký đợt tiếp theo ngay dưới bài viết nhé!',
    imageUrl: '2', likesCount: 28, likedByMe: false,
    comments: [Comment(id: 'cmt-1', authorName: 'Trần Minh Quân', text: 'Hoạt động rất ý nghĩa, hẹn mọi người vào cuối tuần này nhé!', time: '45 phút trước')],
  ),
  SocialPost(
    id: 'post-3', authorId: 'dv-04', authorName: 'Phạm Thị Mỹ Linh', authorRole: 'Đoàn viên • Phường Trấn Biên', authorAvatar: 'Phạm Thị Mỹ Linh', branchName: 'Chi đoàn Khu phố 5', category: 'event', eventTag: 'Hiến máu tình nguyện "Giọt hồng Đất Bưởi - Đồng Nai"', isEventPost: false, verifiedOfficer: false, verifiedParticipant: true, registeredCount: 0, registeredByMe: false,
    eventSchedule: null, createdAt: '3 ngày trước',
    content: 'Lần thứ 4 tham gia hiến máu tình nguyện tại Trung tâm Văn hóa Thanh thiếu nhi Đồng Nai. Một giọt máu cho đi, một cuộc đời ở lại!',
    imageUrl: '3', likesCount: 53, likedByMe: false, comments: [],
  ),
];

final initialTransferRequests = [
  TransferRequest(id: 'tr-1', memberId: 'dv-13', memberName: 'Nguyễn Tấn Đạt', memberCode: 'ĐV-DN-013', direction: 'outgoing', fromBranch: 'Chi đoàn Khu phố 5 - P. Trấn Biên', toBranch: 'Đoàn trường Đại học Đồng Nai', reason: 'Nhập học hệ Đại học chính quy năm học 2026 - 2030', submittedAt: '18/11/2026', status: 'approved_source', step: 3),
  TransferRequest(id: 'tr-2', memberId: 'dv-14', memberName: 'Trương Ngọc Hân', memberCode: 'ĐV-DN-014', direction: 'outgoing', fromBranch: 'Chi đoàn Khu phố 5 - P. Trấn Biên', toBranch: 'Chi đoàn Khu phố 2 - P. Quyết Thắng', reason: 'Chuyển hộ khẩu thường trú sang Phường Quyết Thắng', submittedAt: '22/11/2026', status: 'pending', step: 2),
  TransferRequest(id: 'tr-3', memberId: 'dv-in-1', memberName: 'Ngô Minh Khải', memberCode: 'ĐV-LD-108', direction: 'incoming', fromBranch: 'Chi đoàn Ấp 3 - Xã An Phước, Long Thành', toBranch: 'Chi đoàn Khu phố 5 - P. Trấn Biên', reason: 'Chuyển trọ đến Khu phố 5 để làm việc tại KCN Amata', submittedAt: '23/11/2026', status: 'pending', step: 2),
];

final digitalBadges = [
  DigitalBadge(id: 'bdg-1', name: 'Thanh niên Tiên phong Số', desc: 'Điểm danh QR 3 kỳ liên tiếp & hoàn thành E-Learning số hóa', icon: 'zap', earned: true, earnedAt: '18/11/2026'),
  DigitalBadge(id: 'bdg-2', name: 'Công nhân Gương mẫu KCN', desc: 'Duy trì 100% chuyên cần dù làm việc theo ca kíp tại KCN', icon: 'award', earned: true, earnedAt: '15/11/2026'),
  DigitalBadge(id: 'bdg-3', name: 'Chiến sĩ Giọt hồng Đồng Nai', desc: 'Tham gia hiến máu tình nguyện & hoạt động Thứ Bảy Xanh', icon: 'heart', earned: true, earnedAt: '08/11/2026'),
  DigitalBadge(id: 'bdg-4', name: 'Đại sứ Truyền thông Social', desc: 'Đăng bài & hình ảnh lan tỏa sự kiện Đoàn trên Bảng tin', icon: 'share', earned: false, earnedAt: null),
];

final sessionArchive = [
  {'id': 'arc-11', 'period': 'Tháng 11/2026', 'quarter': 'Quý IV/2026', 'year': '2026', 'title': 'Ngày hội Thanh niên Đồng Nai', 'attended': 33, 'total': 46, 'rate': '71.7%', 'location': 'NVH Khu phố 5'},
  {'id': 'arc-10', 'period': 'Tháng 10/2026', 'quarter': 'Quý IV/2026', 'year': '2026', 'title': 'Tuyên truyền ATGT & PCCC KCN', 'attended': 19, 'total': 46, 'rate': '41.3%', 'location': 'NVH Khu phố 5'},
  {'id': 'arc-09', 'period': 'Tháng 09/2026', 'quarter': 'Quý III/2026', 'year': '2026', 'title': 'Kỹ năng số cho thanh niên', 'attended': 28, 'total': 46, 'rate': '60.9%', 'location': 'NVH Khu phố 5'},
  {'id': 'arc-08', 'period': 'Tháng 08/2026', 'quarter': 'Quý III/2026', 'year': '2026', 'title': 'Tiếp sức mùa thi & Hành trình Đỏ', 'attended': 35, 'total': 46, 'rate': '76.1%', 'location': 'NVH Khu phố 5'},
  {'id': 'arc-06', 'period': 'Tháng 06/2026', 'quarter': 'Quý II/2026', 'year': '2026', 'title': 'Chiến dịch Thanh niên Tình nguyện Hè', 'attended': 37, 'total': 45, 'rate': '82.2%', 'location': 'P. Trấn Biên'},
  {'id': 'arc-03', 'period': 'Tháng 03/2026', 'quarter': 'Quý I/2026', 'year': '2026', 'title': 'Tháng Thanh niên 26/03 - Kết nạp ĐV mới', 'attended': 41, 'total': 44, 'rate': '93.2%', 'location': 'NVH Khu phố 5'},
];

final initialAuditLogs = [
  AuditLog(id: 'log-1', actor: 'Nguyễn Văn An (Bí thư KP5)', action: 'Khởi tạo mã QR Động 2 lớp cho buổi sinh hoạt tháng 12', time: '09:15 - 24/11/2026'),
  AuditLog(id: 'log-2', actor: 'Phan Thị Bích Thảo (Đoàn Phường)', action: 'Tổng hợp báo cáo tháng 11 cho 12 Chi đoàn trực thuộc', time: '08:40 - 24/11/2026'),
  AuditLog(id: 'log-3', actor: 'Trần Minh Quân (ĐV KP5)', action: 'Cập nhật lịch làm việc Ca đêm - KCN Thạnh Phú', time: '22:10 - 23/11/2026'),
];

final rolePermissions = [
  {'feature': 'Quét QR Điểm danh & Gửi đơn ca bù', 'member': true, 'secretary': true, 'ward_officer': false},
  {'feature': 'Đăng bài, ảnh sự kiện lên Bảng tin Social', 'member': true, 'secretary': true, 'ward_officer': true},
  {'feature': 'Quản lý 46 hồ sơ ĐV, Nhập Excel & Duyệt ca bù', 'member': false, 'secretary': true, 'ward_officer': true},
  {'feature': 'Tạo buổi sinh hoạt, phát QR & Điểm danh ngoại lệ', 'member': false, 'secretary': true, 'ward_officer': false},
  {'feature': 'Xét duyệt Chuyển sinh hoạt Đoàn liên đơn vị', 'member': false, 'secretary': true, 'ward_officer': true},
  {'feature': 'Thống kê 12 Chi đoàn, Nhắc nộp & Xuất Báo cáo Xã', 'member': false, 'secretary': false, 'ward_officer': true},
  {'feature': 'Quản trị bảo mật, Sao lưu & Nhật ký hệ thống', 'member': false, 'secretary': true, 'ward_officer': true},
];

final excelImportBatch = [
  {'name': 'Nguyễn Hữu Phước', 'phone': '0938.445.112', 'type': 'working_far', 'workplace': 'Cty Pouchen - KCN Biên Hòa 1', 'shift': 'Ca 2 (14h - 22h)', 'occupation': 'Công nhân sản xuất KCN', 'joinDate': '26/03/2023', 'points': 80},
  {'name': 'Lê Ngọc Ánh', 'phone': '0977.882.910', 'type': 'local', 'workplace': 'Trường Mầm non Trấn Biên', 'shift': 'Hành chính', 'occupation': 'Cán bộ / Viên chức', 'joinDate': '19/05/2022', 'points': 85},
];
