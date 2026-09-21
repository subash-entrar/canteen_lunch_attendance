import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/daily_report_model.dart';
import '../models/student_model.dart';

class DailyReportPdfService {
  DailyReportPdfService._();

  static const _photoSize = 26.0;
  static const _navy = PdfColor.fromInt(0xFF1A2B47);
  static const _teal = PdfColor.fromInt(0xFF309398);
  static const _orange = PdfColor.fromInt(0xFFD97706);
  static const _muted = PdfColor.fromInt(0xFF607D8B);
  static const _line = PdfColor.fromInt(0xFFE3E8EF);
  static const _rowAlt = PdfColor.fromInt(0xFFF8F9FA);

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      responseType: ResponseType.bytes,
    ),
  );

  /// Builds a PDF from the students currently shown on screen.
  static Future<Uint8List> build({
    required DailyLunchReport report,
    required List<StudentModel> students,
    String? filterNote,
  }) async {
    final attended =
        students.where((s) => s.isLunchAttended).toList(growable: false);
    final pending =
        students.where((s) => !s.isLunchAttended).toList(growable: false);

    final total = students.length;
    final done = attended.length;
    final pendingCount = pending.length;
    final percent = total == 0 ? 0 : ((done / total) * 100).round();

    final dailyPay = students.where((s) => s.isDailyPayment).length;
    final termPay = students.where((s) => s.isTermPayment).length;

    final photoCache = await _loadPhotoCache(students);

    final displayDate = _formatReportDate(report.date);
    final generatedAt =
        DateFormat('dd MMM yyyy, h:mm a').format(DateTime.now());

    final doc = pw.Document(
      title: 'Lunch Report $displayDate',
      author: 'RUH Canteen Lunch Attendance',
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 40, 36, 40),
        header: (context) => _header(displayDate, filterNote: filterNote),
        footer: (context) => _footer(context, generatedAt),
        build: (context) => [
          pw.SizedBox(height: 8),
          _summaryBlock(
            total: total,
            done: done,
            pending: pendingCount,
            percent: percent,
            dailyPay: dailyPay,
            termPay: termPay,
            filtered: filterNote != null,
          ),
          pw.SizedBox(height: 20),
          if (students.isEmpty) ...[
            _emptyNote('No students match the current filters.'),
          ] else ...[
            if (attended.isNotEmpty) ...[
              _sectionTitle('Done ($done)', _teal),
              pw.SizedBox(height: 8),
              _studentTable(
                attended,
                photoCache: photoCache,
                statusLabel: 'Done',
                statusColor: _teal,
              ),
              if (pending.isNotEmpty) pw.SizedBox(height: 18),
            ],
            if (pending.isNotEmpty) ...[
              _sectionTitle('Pending ($pendingCount)', _orange),
              pw.SizedBox(height: 8),
              _studentTable(
                pending,
                photoCache: photoCache,
                statusLabel: 'Pending',
                statusColor: _orange,
              ),
            ],
          ],
        ],
      ),
    );

    return doc.save();
  }

  static String filenameFor(String apiDate) => 'lunch_report_$apiDate.pdf';

  static Future<Map<int, pw.MemoryImage?>> _loadPhotoCache(
    List<StudentModel> students,
  ) async {
    final cache = <int, pw.MemoryImage?>{};
    const batchSize = 8;
    for (var i = 0; i < students.length; i += batchSize) {
      final end =
          (i + batchSize < students.length) ? i + batchSize : students.length;
      final batch = students.sublist(i, end);
      await Future.wait(
        batch.map((student) async {
          cache[student.studentId] = await _loadStudentPhoto(student);
        }),
      );
    }
    return cache;
  }

  static Future<pw.MemoryImage?> _loadStudentPhoto(StudentModel student) async {
    final url = student.profilePhoto.trim();
    if (url.isEmpty) return null;
    try {
      final response = await _dio.get<List<int>>(url);
      final data = response.data;
      if (response.statusCode == 200 && data != null && data.isNotEmpty) {
        final compressed = _compressPhoto(Uint8List.fromList(data));
        if (compressed == null) return null;
        return pw.MemoryImage(compressed);
      }
    } catch (_) {
      // Fall back to initials placeholder in the table cell.
    }
    return null;
  }

  /// Shrinks photos to a tiny JPEG so the PDF stays small (~KB, not MB).
  static Uint8List? _compressPhoto(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      final resized = img.copyResize(
        decoded,
        width: 64,
        height: 64,
        interpolation: img.Interpolation.average,
      );
      return Uint8List.fromList(img.encodeJpg(resized, quality: 50));
    } catch (_) {
      return null;
    }
  }

  static String _formatReportDate(String apiDate) {
    try {
      final parsed = DateFormat('yyyy-MM-dd').parseStrict(apiDate.trim());
      return DateFormat('EEE, dd MMM yyyy').format(parsed);
    } catch (_) {
      return apiDate;
    }
  }

  static pw.Widget _header(String displayDate, {String? filterNote}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'RUH Canteen',
          style: pw.TextStyle(
            color: _navy,
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          'Daily Lunch Attendance Report',
          style: pw.TextStyle(
            color: _navy,
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          displayDate,
          style: const pw.TextStyle(color: _muted, fontSize: 11),
        ),
        if (filterNote != null) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            'Filtered view: $filterNote',
            style: pw.TextStyle(
              color: _orange,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
        pw.SizedBox(height: 8),
        pw.Container(height: 1.2, color: _line),
      ],
    );
  }

  static pw.Widget _footer(pw.Context context, String generatedAt) {
    return pw.Column(
      children: [
        pw.Container(height: 1, color: _line),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated $generatedAt',
              style: const pw.TextStyle(color: _muted, fontSize: 8),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(color: _muted, fontSize: 8),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _summaryBlock({
    required int total,
    required int done,
    required int pending,
    required int percent,
    required int dailyPay,
    required int termPay,
    required bool filtered,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _line),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            filtered ? 'Summary (filtered list)' : 'Summary',
            style: pw.TextStyle(
              color: _navy,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              _statChip('Total', '$total', _navy),
              pw.SizedBox(width: 8),
              _statChip('Done', '$done', _teal),
              pw.SizedBox(width: 8),
              _statChip('Pending', '$pending', _orange),
              pw.SizedBox(width: 8),
              _statChip('Attended', '$percent%', _teal),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Payment mix: $dailyPay daily · $termPay term',
            style: const pw.TextStyle(color: _muted, fontSize: 9),
          ),
        ],
      ),
    );
  }

  static pw.Widget _statChip(String label, String value, PdfColor color) {
    final softFill = PdfColor(
      color.red * 0.12 + 0.88,
      color.green * 0.12 + 0.88,
      color.blue * 0.12 + 0.88,
    );
    final softBorder = PdfColor(
      color.red * 0.35 + 0.65,
      color.green * 0.35 + 0.65,
      color.blue * 0.35 + 0.65,
    );

    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: pw.BoxDecoration(
          color: softFill,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: softBorder),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(color: color, fontSize: 8),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              value,
              style: pw.TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _sectionTitle(String title, PdfColor color) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  static pw.Widget _emptyNote(String message) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _rowAlt,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _line),
      ),
      child: pw.Text(
        message,
        style: const pw.TextStyle(color: _muted, fontSize: 9),
      ),
    );
  }

  static pw.Widget _studentTable(
    List<StudentModel> students, {
    required Map<int, pw.MemoryImage?> photoCache,
    required String statusLabel,
    required PdfColor statusColor,
  }) {
    return pw.Table(
      border: pw.TableBorder(
        horizontalInside: const pw.BorderSide(color: _line, width: 0.5),
        top: const pw.BorderSide(color: _line),
        bottom: const pw.BorderSide(color: _line),
        left: const pw.BorderSide(color: _line),
        right: const pw.BorderSide(color: _line),
      ),
      columnWidths: const {
        0: pw.FixedColumnWidth(22),
        1: pw.FixedColumnWidth(34),
        2: pw.FlexColumnWidth(2.1),
        3: pw.FlexColumnWidth(1.2),
        4: pw.FlexColumnWidth(1.3),
        5: pw.FlexColumnWidth(0.8),
        6: pw.FlexColumnWidth(0.8),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _navy),
          children: [
            _headerCell('#'),
            _headerCell('Photo'),
            _headerCell('Name'),
            _headerCell('Admission'),
            _headerCell('Class'),
            _headerCell('Payment'),
            _headerCell('Status'),
          ],
        ),
        for (var i = 0; i < students.length; i++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: i.isOdd ? _rowAlt : PdfColors.white,
            ),
            children: [
              _bodyCell('${i + 1}'),
              _photoCell(students[i], photoCache[students[i].studentId]),
              _bodyCell(students[i].studentName),
              _bodyCell(
                students[i].admissionNo.isEmpty ? '—' : students[i].admissionNo,
              ),
              _bodyCell(
                students[i].classSection.isEmpty
                    ? '—'
                    : students[i].classSection,
              ),
              _bodyCell(students[i].paymentLabel),
              _bodyCell(statusLabel, color: statusColor, bold: true),
            ],
          ),
      ],
    );
  }

  static pw.Widget _photoCell(StudentModel student, pw.MemoryImage? image) {
    if (image != null) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.ClipRRect(
          horizontalRadius: 4,
          verticalRadius: 4,
          child: pw.Image(
            image,
            width: _photoSize,
            height: _photoSize,
            fit: pw.BoxFit.fill,
          ),
        ),
      );
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Container(
        width: _photoSize,
        height: _photoSize,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          color: _rowAlt,
          borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border.all(color: _line),
        ),
        child: pw.Text(
          student.initials,
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
            color: _navy,
          ),
        ),
      ),
    );
  }

  static pw.Widget _headerCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 7),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 7.5,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _bodyCell(
    String text, {
    PdfColor color = _navy,
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
