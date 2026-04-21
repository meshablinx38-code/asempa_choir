import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../providers/providers.dart';
import '../../shared/theme/app_theme.dart';

class AttendanceHistoryScreen extends ConsumerWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final attendanceAsync = ref.watch(userAttendanceProvider(user.uid));

    return Scaffold(
      appBar: AppBar(title: const Text('My Attendance History')),
      body: Column(children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider.withOpacity(0.5)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Hello, ${user.name}', style: Theme.of(context).textTheme.titleLarge),
            Text('Your attendance for the last 60 days',
                style: Theme.of(context).textTheme.bodyMedium),
          ]),
        ),
        Expanded(child: attendanceAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (records) {
            final presentDates = records.map((r) => r.dateStr).toSet();
            final days = List.generate(60, (i) {
              final d = DateTime.now().subtract(Duration(days: i));
              return d;
            });
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: days.length,
              itemBuilder: (_, i) {
                final day = days[i];
                final key = '${day.year}-${day.month.toString().padLeft(2,'0')}-${day.day.toString().padLeft(2,'0')}';
                final present = presentDates.contains(key);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider.withOpacity(0.5)),
                  ),
                  child: Row(children: [
                    Icon(present ? Icons.check_circle : Icons.cancel,
                        color: present ? AppColors.success : AppColors.error, size: 24),
                    const SizedBox(width: 12),
                    Expanded(child: Text(DateFormat('EEEE, MMMM d, y').format(day),
                        style: Theme.of(context).textTheme.bodyLarge)),
                    Text(present ? 'Present' : 'Absent',
                        style: TextStyle(
                            color: present ? AppColors.success : AppColors.error,
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ]),
                );
              },
            );
          },
        )),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _downloadPdf(ref, user),
            icon: const Icon(Icons.download),
            label: const Text('Download Attendance PDF'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          ),
        ),
      ]),
    );
  }

  Future<void> _downloadPdf(WidgetRef ref, user) async {
    final records = ref.read(userAttendanceProvider(user.uid)).valueOrNull ?? [];
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('Asempa Choir â€” Attendance Report',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text('Member: ${user.name}  |  Part: ${user.voicePart}'),
        pw.Text('Generated: ${DateFormat('dd MMM yyyy').format(DateTime.now())}'),
        pw.SizedBox(height: 20),
        pw.Table.fromTextArray(
          headers: ['Date', 'Status'],
          data: records.map((r) => [
            DateFormat('EEE, dd MMM yyyy').format(r.checkInTime),
            'Present',
          ]).toList(),
        ),
      ]),
    ));
    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }
}