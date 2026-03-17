import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String _selectedPeriod = 'month';
  String _selectedClub = 'All Clubs';
  bool _isGenerating = false;

  final List<String> clubs = [
    'All Clubs',
    'Tech Club',
    'Sports Club',
    'Arts Club',
    'Academic Club'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'System Reports',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
              ),
              const SizedBox(height: 20),

              _buildFilters(),
              const SizedBox(height: 24),

              _buildGenerateCard(),
              const SizedBox(height: 24),

              const Text(
                'Analytics Categories',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
              ),
              const SizedBox(height: 16),

              _buildCategoriesGrid(),
              const SizedBox(height: 24),

              const Text(
                'Recent Files',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
              ),
              const SizedBox(height: 16),

              _buildRecentFilesList(),
            ],
          ),
        ),
      ),
    );
  }

  // --- Filter Section ---

  Widget _buildFilters() {
    return Column(
      children: [
        Container(
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              _buildToggleButton('This Month', 'month'),
              _buildToggleButton('This Semester', 'semester'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))
            ],
          ),
          child: DropdownMenu<String>(
            width: MediaQuery.of(context).size.width - 40,
            initialSelection: _selectedClub,
            menuStyle: MenuStyle(
              backgroundColor: WidgetStateProperty.all(Colors.white),
              surfaceTintColor: WidgetStateProperty.all(Colors.white),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A), fontSize: 14),
            leadingIcon: const Icon(Icons.groups_rounded, color: Color(0xFF3674B5)),
            trailingIcon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF3674B5)),
            onSelected: (value) => setState(() => _selectedClub = value!),
            dropdownMenuEntries: clubs.map((club) => DropdownMenuEntry(value: club, label: club)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton(String label, String value) {
    bool isSelected = _selectedPeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF5B9FD8) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  // --- PDF Generation Card ---

  Widget _buildGenerateCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF5B9FD8).withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: const Color(0xFF5B9FD8).withValues(alpha: 0.08), blurRadius: 15, spreadRadius: 2)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFF5B9FD8), size: 20),
              SizedBox(width: 8),
              Text('AI Insights Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Generate a comprehensive PDF including engagement summaries, sentiment analysis, and attendance predictions.',
            style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateAndSharePDF,
              icon: _isGenerating
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.picture_as_pdf_rounded, size: 20, color: Colors.white),
              label: Text(
                _isGenerating ? 'Processing...' : 'Export Comprehensive Report',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3674B5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Analytics Categories ---

  Widget _buildCategoriesGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _categoryCard('Engagement', Icons.trending_up_rounded),
        _categoryCard('AI Sentiment', Icons.psychology_rounded),
        _categoryCard('Compliance', Icons.shield_outlined),
        _categoryCard('Attendance', Icons.calendar_today_rounded),
      ],
    );
  }

  Widget _categoryCard(String title, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF5B9FD8), size: 32),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 13)),
        ],
      ),
    );
  }

  // --- Recent Files (Firestore) ---

  Widget _buildRecentFilesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('reports').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF3674B5)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No reports generated yet.', style: TextStyle(color: Colors.grey))));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return _buildFileCard(snapshot.data!.docs[index].id, data);
          },
        );
      },
    );
  }

  Widget _buildFileCard(String docId, Map<String, dynamic> data) {
    String fileName = data['fileName'] ?? 'Report.pdf';
    String fileSize = data['fileSize'] ?? '1.2 MB';
    String dateStr = data['createdAt'] != null ? DateFormat('MMM dd, yyyy').format((data['createdAt'] as Timestamp).toDate()) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 5))],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFEF2F2), Color(0xFFFEE2E2)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fileName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.storage_outlined, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(fileSize, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                    const SizedBox(width: 12),
                    Icon(Icons.event_outlined, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(dateStr, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(icon: const Icon(Icons.download_for_offline_outlined, color: Color(0xFF5B9FD8), size: 24), onPressed: () {}, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              const SizedBox(height: 8),
              IconButton(icon: const Icon(Icons.delete_sweep_outlined, color: Color(0xFFEF4444), size: 24), onPressed: () => FirebaseFirestore.instance.collection('reports').doc(docId).delete(), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ],
          ),
        ],
      ),
    );
  }

  // --- PDF Core Logic ---

  Future<void> _generateAndSharePDF() async {
    setState(() => _isGenerating = true);
    try {
      final pdf = pw.Document();
      String dateStr = DateFormat('MMM dd, yyyy').format(DateTime.now());
      String fileName = '${DateFormat('MMM_dd').format(DateTime.now())}_UniClubs_Report.pdf';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(child: pw.Text('UniClubs AI Analytics Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900))),
                pw.SizedBox(height: 10),
                pw.Center(child: pw.Text('Generated on: $dateStr', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700))),
                pw.Divider(thickness: 2, color: PdfColors.blueGrey100),
                pw.SizedBox(height: 20),
                pw.Text('1. Executive Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text('This report covers analytical data for $_selectedClub during $_selectedPeriod.', style: const pw.TextStyle(fontSize: 12)),
                pw.Spacer(),
                pw.Center(child: pw.Text('Powered by Gemini AI - UniClubs Project', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500, fontStyle: pw.FontStyle.italic)))
              ],
            );
          },
        ),
      );

      await Printing.sharePdf(bytes: await pdf.save(), filename: fileName);
      await FirebaseFirestore.instance.collection('reports').add({
        'fileName': fileName,
        'fileSize': '1.2 MB',
        'type': 'comprehensive',
        'createdAt': Timestamp.now(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report generated successfully!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
    if (mounted) setState(() => _isGenerating = false);
  }
}