import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:fl_chart/fl_chart.dart';
import 'admin_attendance_screen.dart';

// ==========================================
// Data Models
// ==========================================
class ReportData {
  final int eventsCount;
  final double totalActual;
  final double totalPredicted;
  final int positiveFeedback;
  final int negativeFeedback;
  final int neutralFeedback;
  final double attendanceRate;
  final double satisfactionRate;

  ReportData({
    required this.eventsCount,
    required this.totalActual,
    required this.totalPredicted,
    required this.positiveFeedback,
    required this.negativeFeedback,
    required this.neutralFeedback,
    required this.attendanceRate,
    required this.satisfactionRate,
  });
}

class EventData {
  final String title;
  final double actualAttendance;
  final double predictedAttendance;
  final DateTime date;

  EventData({
    required this.title,
    required this.actualAttendance,
    required this.predictedAttendance,
    required this.date,
  });

  double get attendanceRate => predictedAttendance > 0
      ? (actualAttendance / predictedAttendance) * 100
      : 0.0;
}

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

  List<String> _clubsList = ['All Clubs'];
  bool _isLoadingClubs = true;

  @override
  void initState() {
    super.initState();
    _fetchClubs();
  }

  Future<void> _fetchClubs() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('clubs').get();
      final fetchedClubs = snap.docs
          .map((doc) {
        final data = doc.data();
        return data['name']?.toString() ?? '';
      })
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();

      if (mounted) {
        setState(() {
          _clubsList = ['All Clubs', ...fetchedClubs];
          _isLoadingClubs = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching clubs: $e");
      if (mounted) {
        setState(() => _isLoadingClubs = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FD),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'System Reports',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 20),
              _buildFilters(),
              const SizedBox(height: 24),
              _buildGenerateCard(),
              const SizedBox(height: 24),
              const Text(
                'Analytics Categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: _isLoadingClubs
              ? const Padding(
            padding: EdgeInsets.all(12.0),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF3674B5)),
              ),
            ),
          )
              : DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _clubsList.contains(_selectedClub)
                  ? _selectedClub
                  : 'All Clubs',
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey),
              style: const TextStyle(color: Colors.black87, fontSize: 16),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => _selectedClub = newValue);
                }
              },
              items: _clubsList
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
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

  Widget _buildGenerateCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF5B9FD8).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_outlined, color: Color(0xFF5B9FD8), size: 20),
              SizedBox(width: 8),
              Text(
                'Comprehensive Report',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Generate a detailed PDF including attendance, engagement, and AI sentiment analysis.',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateAndSharePDF,
              icon: _isGenerating
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
              label: Text(
                _isGenerating ? 'Processing...' : 'Export Full Report',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3674B5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
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
        _categoryCard('AI Sentiment', Icons.psychology_rounded),
        _categoryCard('Attendance', Icons.people_alt_rounded),
      ],
    );
  }

  Widget _categoryCard(String title, IconData icon) {
    return GestureDetector(
      onTap: () {
        if (title == 'Attendance') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminAttendanceScreen(),
            ),
          );
        } else {
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
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF5B9FD8), size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
                fontSize: 13,
              ),
            ),
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
      final reportData = await _fetchReportData();
      await _generatePDF(reportData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report generated successfully!')),
        );
      }
    } catch (e) {
      debugPrint("PDF Generation Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e')),
        );
      }
    }
    if (mounted) {
      setState(() => _isGenerating = false);
    }
  }

  Future<ReportData> _fetchReportData() async {
    final db = FirebaseFirestore.instance;
    Set<String> validEventIds = {};
    bool filterByClub = _selectedClub != 'All Clubs';
    DateTime now = DateTime.now();
    DateTime filterDate = _selectedPeriod == 'month'
        ? now.subtract(const Duration(days: 30))
        : now.subtract(const Duration(days: 120));

    double totalActual = 0;
    double totalPredicted = 0;
    int eventsCount = 0;

    Query eventsQuery = db.collection('events');
    if (filterByClub) {
      final clubSnap = await db
          .collection('clubs')
          .where('name', isEqualTo: _selectedClub)
          .limit(1)
          .get();
      if (clubSnap.docs.isNotEmpty) {
        eventsQuery =
            eventsQuery.where('clubId', isEqualTo: clubSnap.docs.first.id);
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

    int pos = 0, neg = 0, neu = 0;
    if (validEventIds.isNotEmpty) {
      final feedbackSnap = await db.collection('feedback').get();
      for (var doc in feedbackSnap.docs) {
        final data = doc.data();
        final String fEventId = data['eventId'] ?? '';

        if (validEventIds.contains(fEventId)) {
          String label =
          (data['sentimentLabel'] ?? 'neutral').toString().toLowerCase();
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
    double attendanceRate =
    totalPredicted > 0 ? (totalActual / totalPredicted) * 100 : 0.0;
    double satisfactionRate =
    totalFeedback > 0 ? (pos / totalFeedback) * 100 : 0.0;

    return ReportData(
      eventsCount: eventsCount,
      totalActual: totalActual,
      totalPredicted: totalPredicted,
      positiveFeedback: pos,
      negativeFeedback: neg,
      neutralFeedback: neu,
      attendanceRate: attendanceRate,
      satisfactionRate: satisfactionRate,
    );
  }

  Future<void> _generatePDF(ReportData data) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'UniClubs Analytics Report',
              style: pw.TextStyle(
                fontSize: 26,
                fontWeight: pw.FontWeight.bold,
                color: const PdfColor(0.12, 0.23, 0.54),
              ),
            ),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 10),
            pw.Text(
              'Target Scope: $_selectedClub',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              'Report Period: ${_selectedPeriod == 'month' ? 'Last 30 Days' : 'Current Semester'}',
              style: const pw.TextStyle(fontSize: 14),
            ),
            pw.Text(
              'Generated: ${DateFormat('dd/MM/yyyy - HH:mm').format(now)}',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
            ),
            pw.SizedBox(height: 30),
            pw.Text(
              '1. Activity Overview',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Total Events Held: ${data.eventsCount}'),
            pw.Text(
              'Total Student Footfall: ${data.totalActual.toInt()} attendees',
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              '2. Attendance Performance',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Expected Attendance: ${data.totalPredicted.toInt()}'),
            pw.Text('Actual Attendance: ${data.totalActual.toInt()}'),
            pw.Text(
              'Attendance Achievement Rate: ${data.attendanceRate.toStringAsFixed(1)}%',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              '3. AI Sentiment Analysis',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Total Feedback Received: ${data.positiveFeedback + data.negativeFeedback + data.neutralFeedback}',
            ),
            pw.Bullet(text: 'Positive Reactions: ${data.positiveFeedback}'),
            pw.Bullet(text: 'Neutral Reactions: ${data.neutralFeedback}'),
            pw.Bullet(text: 'Negative Reactions: ${data.negativeFeedback}'),
            pw.SizedBox(height: 10),
            pw.Text(
              'Overall Satisfaction Rate: ${data.satisfactionRate.toStringAsFixed(1)}%',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: const PdfColor(0.18, 0.8, 0.44),
              ),
            ),
            pw.SizedBox(height: 30),
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Text(
                'This report provides insights into club engagement metrics and student satisfaction levels. Use these metrics to improve future events and activities.',
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
              ),
            ),
          ],
        ),
      ),
    );

    final fileName = 'UniClubs_Report_${DateFormat('MMM_dd_yyyy').format(now)}.pdf';
    await Printing.sharePdf(bytes: await pdf.save(), filename: fileName);
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
  String _errorMessage = '';

  int _pos = 0, _neg = 0, _neu = 0;
  List<EventData> _eventStats = [];

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

      Query eventsQuery = db.collection('events');
      if (filterByClub) {
        final clubSnap = await db
            .collection('clubs')
            .where('name', isEqualTo: widget.selectedClub)
            .limit(1)
            .get();
        if (clubSnap.docs.isNotEmpty) {
          eventsQuery =
              eventsQuery.where('clubId', isEqualTo: clubSnap.docs.first.id);
        }
      }

      final eventsSnap = await eventsQuery.get();
      List<EventData> tempEvents = [];

      for (var doc in eventsSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final Timestamp? eventDate = data['date'] as Timestamp?;

        if (eventDate != null && eventDate.toDate().isAfter(filterDate)) {
          validEventIds.add(doc.id);
          tempEvents.add(
            EventData(
              title: data['title'] ?? 'Event',
              actualAttendance:
              (data['actualAttendance'] as num? ?? 0).toDouble(),
              predictedAttendance:
              (data['predictedAttendance'] as num? ?? 0).toDouble(),
              date: eventDate.toDate(),
            ),
          );
        }
      }

      tempEvents.sort((a, b) => b.date.compareTo(a.date));

      if (widget.categoryTitle == 'AI Sentiment') {
        // Use all of the club's event IDs (no date restriction) so old feedback
        // is included. eventsSnap already holds every event for the selected club.
        final sentimentEventIds = eventsSnap.docs.map((d) => d.id).toSet();

        final feedbackSnap = await db.collection('feedback').get();
        for (var doc in feedbackSnap.docs) {
          final data = doc.data();
          final eventId = data['eventId'] ?? '';
          if (filterByClub && !sentimentEventIds.contains(eventId)) continue;
          final label =
              (data['sentimentLabel'] ?? 'neutral').toString().toLowerCase();
          if (label.contains('positive')) {
            _pos++;
          } else if (label.contains('negative')) {
            _neg++;
          } else {
            _neu++;
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
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading data: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FD),
      appBar: AppBar(
        title: Text(
          '${widget.categoryTitle} Details',
          style: const TextStyle(
            color: Color(0xFF1E3A8A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFF3674B5)),
      )
          : _errorMessage.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = '';
                });
                _fetchData();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Showing data for ${widget.selectedClub}',
              style:
              const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Expanded(child: _buildChart()),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    if (widget.categoryTitle == 'AI Sentiment') {
      int totalFeedback = _pos + _neg + _neu;
      if (totalFeedback == 0) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mood, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text("No sentiment data available.",
                  style: TextStyle(color: Colors.grey, fontSize: 16)),
            ],
          ),
        );
      }
      return Column(
        children: [
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 60,
                sections: [
                  if (_pos > 0)
                    PieChartSectionData(
                      color: const Color(0xFF4CAF50),
                      value: _pos.toDouble(),
                      title: '$_pos',
                      radius: 50,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  if (_neu > 0)
                    PieChartSectionData(
                      color: const Color(0xFFFFC107),
                      value: _neu.toDouble(),
                      title: '$_neu',
                      radius: 50,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  if (_neg > 0)
                    PieChartSectionData(
                      color: const Color(0xFFF44336),
                      value: _neg.toDouble(),
                      title: '$_neg',
                      radius: 50,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          if (_pos > 0) ...[
            _buildLegendItem(const Color(0xFF4CAF50), 'Positive Feedback ($_pos)'),
            const SizedBox(height: 8),
          ],
          if (_neu > 0) ...[
            _buildLegendItem(const Color(0xFFFFC107), 'Neutral Feedback ($_neu)'),
            const SizedBox(height: 8),
          ],
          if (_neg > 0)
            _buildLegendItem(const Color(0xFFF44336), 'Negative Feedback ($_neg)'),
        ],
      );
    } else if (widget.categoryTitle == 'Attendance') {
      if (_eventStats.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_note, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text("No event data available.",
                  style: TextStyle(color: Colors.grey, fontSize: 16)),
            ],
          ),
        );
      }

      double maxPredicted = _eventStats.map((e) => e.predictedAttendance).fold(0.0, (a, b) => a > b ? a : b);
      double maxActual = _eventStats.map((e) => e.actualAttendance).fold(0.0, (a, b) => a > b ? a : b);
      double maxY = maxPredicted > maxActual ? maxPredicted : maxActual;

      if (maxY == 0) maxY = 10.0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Actual vs Expected Attendance (Recent Events)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY + (maxY * 0.2),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toInt()}',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index < 0 || index >= _eventStats.length) {
                          return const SizedBox.shrink();
                        }
                        String title = _eventStats[index].title;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            title.length > 8
                                ? '${title.substring(0, 7)}..'
                                : title,
                            style: const TextStyle(fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          if (value % (maxY / 4).ceil() != 0 && value != maxY && value != 0) return const SizedBox.shrink();
                          return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey));
                        }
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? (maxY / 4) : 1,
                ),
                barGroups: List.generate(_eventStats.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: _eventStats[i].actualAttendance,
                        color: const Color(0xFF3674B5),
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: _eventStats[i].predictedAttendance,
                        color: Colors.grey[300]!,
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
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

    return const Center(
      child: Text("Detailed report coming soon for this category."),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}