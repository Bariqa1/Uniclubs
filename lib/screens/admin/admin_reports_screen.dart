import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:fl_chart/fl_chart.dart';

// ==========================================
// Admin Reports Screen
// ==========================================
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
            ],
          ),
        ),
      ),
    );
  }

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
            onSelected: (value) => setState(() => _selectedClub = value!),
            dropdownMenuEntries: clubs.map((club) => DropdownMenuEntry(value: club, label: club)).toList(),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
            ),
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
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF5B9FD8) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey[600])),
        ),
      ),
    );
  }

  Widget _buildGenerateCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF5B9FD8).withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_outlined, color: Color(0xFF5B9FD8), size: 20),
              SizedBox(width: 8),
              Text('Comprehensive Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
            ],
          ),
          const SizedBox(height: 12),
          Text('Generate a detailed PDF including attendance, engagement, and AI sentiment analysis.', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateAndSharePDF,
              icon: _isGenerating ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
              label: Text(_isGenerating ? 'Processing...' : 'Export Full Report', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3674B5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            ),
          ),
        ],
      ),
    );
  }

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
        _categoryCard('Attendance', Icons.people_alt_rounded),
        _categoryCard('Compliance', Icons.shield_outlined),
      ],
    );
  }

  Widget _categoryCard(String title, IconData icon) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnalyticsDetailScreen(
              categoryTitle: title,
              selectedClub: _selectedClub,
              selectedPeriod: _selectedPeriod,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF5B9FD8), size: 32),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // Comprehensive PDF Generation
  // ==========================================
  Future<void> _generateAndSharePDF() async {
    setState(() => _isGenerating = true);
    try {
      final db = FirebaseFirestore.instance;
      Set<String> validEventIds = {};
      bool filterByClub = _selectedClub != 'All Clubs';
      DateTime now = DateTime.now();
      DateTime filterDate = _selectedPeriod == 'month'
          ? now.subtract(const Duration(days: 30))
          : now.subtract(const Duration(days: 120));

      // 1. Fetch Events & Calculate Attendance
      double totalActual = 0;
      double totalPredicted = 0;
      int eventsCount = 0;

      Query eventsQuery = db.collection('events');
      if (filterByClub) {
        final clubSnap = await db.collection('clubs').where('name', isEqualTo: _selectedClub).limit(1).get();
        if (clubSnap.docs.isNotEmpty) {
          eventsQuery = eventsQuery.where('clubId', isEqualTo: clubSnap.docs.first.id);
        }
      }

      final eventsSnap = await eventsQuery.get();

      for (var doc in eventsSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final Timestamp? eventDate = data['date'] as Timestamp?;

        if (eventDate != null && eventDate.toDate().isAfter(filterDate)) {
          validEventIds.add(doc.id);
          eventsCount++;
          totalActual += (data['actualAttendance'] as num? ?? 0).toDouble();
          totalPredicted += (data['predictedAttendance'] as num? ?? 0).toDouble();
        }
      }

      // 2. Fetch Feedback & Calculate Sentiment
      int pos = 0, neg = 0, neu = 0;
      if (validEventIds.isNotEmpty) {
        final feedbackSnap = await db.collection('feedback').get();
        for (var doc in feedbackSnap.docs) {
          final data = doc.data();
          final String fEventId = data['eventId'] ?? '';

          if (validEventIds.contains(fEventId)) {
            String label = (data['sentimentLabel'] ?? 'neutral').toString().toLowerCase();
            if (label.contains('positive')) {
              pos++;
            } else if (label.contains('negative')) {
              neg++;
            } else {
              neu++;
            }
          }
        }
      }

      int totalFeedback = pos + neg + neu;
      double attendanceRate = totalPredicted > 0 ? (totalActual / totalPredicted) * 100 : 0.0;
      double satisfactionRate = totalFeedback > 0 ? (pos / totalFeedback) * 100 : 0.0;

      // 3. Build PDF
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Text('UniClubs Analytics Report', style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: const PdfColor(0.12, 0.23, 0.54))),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 10),
              pw.Text('Target Scope: $_selectedClub', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text('Report Period: ${_selectedPeriod == 'month' ? 'Last 30 Days' : 'Current Semester'}', style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 30),

              // Section 1: Engagement
              pw.Text('1. Engagement & Activity', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Total Events Held: $eventsCount'),
              pw.Text('Total Student Footfall: ${totalActual.toInt()} attendees'),
              pw.SizedBox(height: 20),

              // Section 2: Attendance Performance
              pw.Text('2. Attendance Performance', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Expected Attendance: ${totalPredicted.toInt()}'),
              pw.Text('Actual Attendance: ${totalActual.toInt()}'),
              pw.Text('Attendance Achievement Rate: ${attendanceRate.toStringAsFixed(1)}%', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),

              // Section 3: Sentiment
              pw.Text('3. AI Sentiment Analysis', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Total Feedback Received: $totalFeedback'),
              pw.Bullet(text: 'Positive Reactions: $pos'),
              pw.Bullet(text: 'Neutral Reactions: $neu'),
              pw.Bullet(text: 'Negative Reactions: $neg'),
              pw.SizedBox(height: 10),
              pw.Text('Overall Satisfaction Rate: ${satisfactionRate.toStringAsFixed(1)}%', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: const PdfColor(0.18, 0.8, 0.44))),
            ],
          ),
        ),
      );

      final fileName = 'UniClubs_Report_${DateFormat('MMM_dd').format(DateTime.now())}.pdf';
      await Printing.sharePdf(bytes: await pdf.save(), filename: fileName);

    } catch (e) {
      debugPrint("PDF Generation Error: $e");
    }
    setState(() => _isGenerating = false);
  }
}

// ==========================================
// Dynamic Analytics Detail Screen (Charts)
// ==========================================
class AnalyticsDetailScreen extends StatefulWidget {
  final String categoryTitle;
  final String selectedClub;
  final String selectedPeriod;

  const AnalyticsDetailScreen({
    super.key,
    required this.categoryTitle,
    required this.selectedClub,
    required this.selectedPeriod,
  });

  @override
  State<AnalyticsDetailScreen> createState() => _AnalyticsDetailScreenState();
}

class _AnalyticsDetailScreenState extends State<AnalyticsDetailScreen> {
  bool _isLoading = true;

  // Chart Data
  int _pos = 0, _neg = 0, _neu = 0;
  List<Map<String, dynamic>> _eventStats = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final db = FirebaseFirestore.instance;
      Set<String> validEventIds = {};
      bool filterByClub = widget.selectedClub != 'All Clubs';
      DateTime filterDate = widget.selectedPeriod == 'month'
          ? DateTime.now().subtract(const Duration(days: 30))
          : DateTime.now().subtract(const Duration(days: 120));

      // Fetch Events
      Query eventsQuery = db.collection('events');
      if (filterByClub) {
        final clubSnap = await db.collection('clubs').where('name', isEqualTo: widget.selectedClub).limit(1).get();
        if (clubSnap.docs.isNotEmpty) {
          eventsQuery = eventsQuery.where('clubId', isEqualTo: clubSnap.docs.first.id);
        }
      }

      final eventsSnap = await eventsQuery.get();
      List<Map<String, dynamic>> tempEvents = [];

      for (var doc in eventsSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final Timestamp? eventDate = data['date'] as Timestamp?;

        if (eventDate != null && eventDate.toDate().isAfter(filterDate)) {
          validEventIds.add(doc.id);
          tempEvents.add({
            'title': data['title'] ?? 'Event',
            'actual': (data['actualAttendance'] as num? ?? 0).toDouble(),
            'predicted': (data['predictedAttendance'] as num? ?? 0).toDouble(),
          });
        }
      }

      // Fetch Feedback for Sentiment
      if (widget.categoryTitle == 'AI Sentiment' && validEventIds.isNotEmpty) {
        final feedbackSnap = await db.collection('feedback').get();
        for (var doc in feedbackSnap.docs) {
          final data = doc.data();
          if (validEventIds.contains(data['eventId'] ?? '')) {
            String label = (data['sentimentLabel'] ?? 'neutral').toString().toLowerCase();
            if (label.contains('positive')) {
              _pos++;
            } else if (label.contains('negative')) {
              _neg++;
            } else {
              _neu++;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _eventStats = tempEvents.take(5).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        title: Text('${widget.categoryTitle} Details', style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3674B5)))
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Showing data for ${widget.selectedClub}', style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 24),
            Expanded(child: _buildChart()),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    if (widget.categoryTitle == 'AI Sentiment') {
      if (_pos == 0 && _neg == 0 && _neu == 0) return const Center(child: Text("No sentiment data available."));
      return Column(
        children: [
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: [
                  PieChartSectionData(color: Colors.green, value: _pos.toDouble(), title: 'Pos', radius: 60, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  PieChartSectionData(color: Colors.orange, value: _neu.toDouble(), title: 'Neu', radius: 55, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  PieChartSectionData(color: Colors.red, value: _neg.toDouble(), title: 'Neg', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          _buildLegendItem(Colors.green, 'Positive Feedback ($_pos)'),
          const SizedBox(height: 8),
          _buildLegendItem(Colors.orange, 'Neutral Feedback ($_neu)'),
          const SizedBox(height: 8),
          _buildLegendItem(Colors.red, 'Negative Feedback ($_neg)'),
        ],
      );
    }

    else if (widget.categoryTitle == 'Attendance' || widget.categoryTitle == 'Engagement') {
      if (_eventStats.isEmpty) return const Center(child: Text("No event data available."));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Actual vs Expected Attendance (Recent Events)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _eventStats.map((e) => e['predicted'] as double).reduce((a, b) => a > b ? a : b) + 20,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index < 0 || index >= _eventStats.length) return const SizedBox.shrink();
                        String title = _eventStats[index]['title'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(title.length > 5 ? '${title.substring(0,4)}..' : title, style: const TextStyle(fontSize: 10)),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: List.generate(_eventStats.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(toY: _eventStats[i]['actual'], color: const Color(0xFF3674B5), width: 12, borderRadius: BorderRadius.circular(4)), // Actual
                      BarChartRodData(toY: _eventStats[i]['predicted'], color: Colors.grey[300], width: 12, borderRadius: BorderRadius.circular(4)), // Expected
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(const Color(0xFF3674B5), 'Actual'),
              const SizedBox(width: 20),
              _buildLegendItem(Colors.grey[300]!, 'Expected'),
            ],
          )
        ],
      );
    }

    return const Center(child: Text("Detailed report coming soon for this category."));
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}