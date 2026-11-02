// ฟังก์ชันช่วยแปลงข้อมูลสำหรับแสดงผล
/// แปลงตัวเลขเป็นราคาบาท เช่น 35000 -> "฿35,000"
String baht(dynamic v) {
  if (v == null) return '-';
  final s = (v as num).round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return '฿$b';
}

/// แปลงค่า null หรือ empty string เป็น "-"
String txt(dynamic v) => (v == null || v.toString().isEmpty) ? '-' : v.toString();

/// แปลงจำนวน megapixels เช่น 33.0 -> "33", 24.2 -> "24.2"
String mp(dynamic v) {
  if (v == null) return '-';
  final n = v as num;
  return n == n.roundToDouble() ? n.round().toString() : n.toStringAsFixed(1);
}

/// แปลง List<dynamic> เป็น List<Map<String, dynamic>>
List<Map<String, dynamic>> asList(dynamic v) =>
    (v as List).map((e) => e as Map<String, dynamic>).toList();

/// แสดงเวลาแบบ "2 วันที่แล้ว" (API ส่ง UTC timestamp โดยไม่มี timezone)
String ago(dynamic iso) {
  if (iso == null) return '';
  var s = iso.toString();
  if (!s.endsWith('Z') && !s.contains('+')) s = '${s}Z';
  final t = DateTime.tryParse(s);
  if (t == null) return '';
  final d = DateTime.now().toUtc().difference(t);
  if (d.inMinutes < 1) return 'เมื่อสักครู่';
  if (d.inMinutes < 60) return '${d.inMinutes} นาทีที่แล้ว';
  if (d.inHours < 24) return '${d.inHours} ชั่วโมงที่แล้ว';
  if (d.inDays < 30) return '${d.inDays} วันที่แล้ว';
  if (d.inDays < 365) return '${(d.inDays / 30).floor()} เดือนที่แล้ว';
  return '${(d.inDays / 365).floor()} ปีที่แล้ว';
}

