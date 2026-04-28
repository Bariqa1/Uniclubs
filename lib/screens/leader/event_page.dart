import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/ai_service.dart'; // Added AI Service Import
import 'event_attendees_screen.dart';
import 'event_feedback_screen.dart';

class EventPage extends StatefulWidget {
  final String clubId;
  const EventPage({super.key, required this.clubId});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddEventSheet(bool isClubActive) {
    if (!isClubActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("This club is currently suspended by admin. You cannot add new events."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final capacityCtrl = TextEditingController();
    final tagsCtrl = TextEditingController();

    String category = 'tech';
    DateTime? selectedEventDate;
    TimeOfDay? selectedEventTime;

    DateTime? selectedDeadlineDate;
    TimeOfDay? selectedDeadlineTime;

    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
          builder: (context, setSheetState) {
            double bottomInset = MediaQuery.of(context).viewInsets.bottom;

            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                    const SizedBox(height: 16),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Create New Event', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A))),
                    ),
                    const SizedBox(height: 16),

                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: titleCtrl,
                              decoration: _inputStyle('Event Title (e.g. Cybersecurity Workshop)'),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              initialValue: category,
                              decoration: _inputStyle('Category'),
                              items: const [
                                DropdownMenuItem(value: 'tech', child: Text('Technology')),
                                DropdownMenuItem(value: 'sports', child: Text('Sports')),
                                DropdownMenuItem(value: 'arts', child: Text('Arts & Culture')),
                                DropdownMenuItem(value: 'academic', child: Text('Academic')),
                                DropdownMenuItem(value: 'social', child: Text('Social')),
                              ],
                              onChanged: (val) => setSheetState(() => category = val!),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: descCtrl,
                              maxLines: 3,
                              decoration: _inputStyle('Description'),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: locCtrl,
                                    decoration: _inputStyle('Location (e.g. Lab 102)'),
                                    validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 1,
                                  child: TextFormField(
                                    controller: capacityCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: _inputStyle('Capacity'),
                                    validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: tagsCtrl,
                              decoration: _inputStyle('Tags (comma separated: tech, AI, workshop)'),
                            ),
                            const SizedBox(height: 24),
                            const Text('Event Date & Time', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                            const SizedBox(height: 8),
                            _buildDateTimePickerRow(
                              context: context,
                              selectedDate: selectedEventDate,
                              selectedTime: selectedEventTime,
                              onDateSelected: (d) => setSheetState(() => selectedEventDate = d),
                              onTimeSelected: (t) => setSheetState(() => selectedEventTime = t),
                            ),
                            const SizedBox(height: 24),
                            const Text('Registration Deadline', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                            const SizedBox(height: 8),
                            _buildDateTimePickerRow(
                              context: context,
                              selectedDate: selectedDeadlineDate,
                              selectedTime: selectedDeadlineTime,
                              onDateSelected: (d) => setSheetState(() => selectedDeadlineDate = d),
                              onTimeSelected: (t) => setSheetState(() => selectedDeadlineTime = t),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity, height: 55,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () async {
                          if (formKey.currentState!.validate()) {
                            if (selectedEventDate == null || selectedEventTime == null || selectedDeadlineDate == null || selectedDeadlineTime == null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select all Dates and Times!'), backgroundColor: Colors.red));
                              return;
                            }
                            setSheetState(() => isLoading = true);
                            try {
                              DateTime eventDT = DateTime(selectedEventDate!.year, selectedEventDate!.month, selectedEventDate!.day, selectedEventTime!.hour, selectedEventTime!.minute);
                              DateTime deadlineDT = DateTime(selectedDeadlineDate!.year, selectedDeadlineDate!.month, selectedDeadlineDate!.day, selectedDeadlineTime!.hour, selectedDeadlineTime!.minute);
                              List<String> tagsList = tagsCtrl.text.split(',').map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty).toList();

                              int capacity = int.tryParse(capacityCtrl.text.trim()) ?? 50;

                              // 1. Fetch current active members count for this club
                              int memberCount = 0;
                              try {
                                final membersSnap = await FirebaseFirestore.instance
                                    .collection('memberships')
                                    .where('clubId', isEqualTo: widget.clubId)
                                    .where('status', isEqualTo: 'approved')
                                    .get();
                                memberCount = membersSnap.docs.length;
                              } catch (e) {
                                debugPrint("Failed to fetch members: $e");
                              }

                              // 2. Prepare features for AI Prediction
                              final categoryMap = {
                                'arts':     {'category_Arts': 1},
                                'academic': {'category_Education': 1},
                                'sports':   {'category_Sports': 1},
                                'tech':     {'category_Technology': 1},
                                'social':   {'category_Community': 1},
                              };

                              final features = <String, dynamic>{
                                "capacity": capacity,
                                "tags_count": tagsList.length,
                                "interested_users_count": memberCount,
                                "past_avg_attendance": (capacity * 0.6).roundToDouble(),
                                "interest_ratio": memberCount > 0 ? (capacity / memberCount).clamp(0.0, 1.0) : 0.5,
                                "category_Arts": 0, "category_Business": 0, "category_Community": 0, "category_Education": 0,
                                "category_Health": 0, "category_Medical": 0, "category_Science": 0, "category_Sports": 0,
                                "category_Technology": 0, ...?categoryMap[category],
                              };

                              // 3. Call AI Service
                              double predictionResult = 0.0;
                              try {
                                predictionResult = await AiService.predictAttendance(features);
                              } catch (e) {
                                debugPrint("AI Prediction Failed: $e");
                              }

                              // 4. Save Event to Firestore with predicted value
                              await FirebaseFirestore.instance.collection('events').add({
                                'clubId': widget.clubId,
                                'title': titleCtrl.text.trim(),
                                'description': descCtrl.text.trim(),
                                'category': category,
                                'location': locCtrl.text.trim(),
                                'capacity': capacity,
                                'tags': tagsList,
                                'date': Timestamp.fromDate(eventDT),
                                'registrationDeadline': Timestamp.fromDate(deadlineDT),
                                'createdAt': FieldValue.serverTimestamp(),
                                'status': 'upcoming',
                                'currentRegistrations': 0,
                                'actualAttendance': 0,
                                'predictedAttendance': predictionResult.toInt(), // Dynamic AI Value
                                'poster': '',
                              });

                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event Created Successfully!'), backgroundColor: Colors.green));
                              }
                            } catch (e) {
                              setSheetState(() => isLoading = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3674B5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Publish Event', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            );
          }
      ),
    );
  }

  InputDecoration _inputStyle(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
    );
  }

  Widget _buildDateTimePickerRow({
    required BuildContext context,
    required DateTime? selectedDate,
    required TimeOfDay? selectedTime,
    required Function(DateTime) onDateSelected,
    required Function(TimeOfDay) onTimeSelected,
  }) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) onDateSelected(date);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.withValues(alpha: 0.5)), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF3674B5)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedDate == null ? 'Select Date' : '${selectedDate.year}-${selectedDate.month}-${selectedDate.day}',
                      style: TextStyle(color: selectedDate == null ? Colors.grey[700] : Colors.black, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () async {
              final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
              if (time != null) onTimeSelected(time);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.withValues(alpha: 0.5)), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF3674B5)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedTime == null ? 'Select Time' : selectedTime.format(context),
                      style: TextStyle(color: selectedTime == null ? Colors.grey[700] : Colors.black, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('clubs').doc(widget.clubId).snapshots(),
        builder: (context, clubSnapshot) {
          bool isClubActive = true;
          if (clubSnapshot.hasData && clubSnapshot.data!.exists) {
            final clubData = clubSnapshot.data!.data() as Map<String, dynamic>?;
            isClubActive = (clubData?['isActive'] ?? true) &&
                (clubData?['status']?.toString().toLowerCase() == 'active');
          }

          return Scaffold(
            backgroundColor: const Color(0xFFF3F7FB),
            appBar: AppBar(
              title: const Text("Club Events", style: TextStyle(color: Color(0xFF3674B5), fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Color(0xFF3674B5)),
              bottom: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF3674B5),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF3674B5),
                tabs: const [Tab(text: "Upcoming"), Tab(text: "Past")],
              ),
            ),
            body: Column(
              children: [
                if (!isClubActive)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFB74D).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB74D).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.lock_outline_rounded, color: Color(0xFFE65100), size: 18),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Club Suspended",
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFFE65100))),
                              SizedBox(height: 2),
                              Text("Adding events is disabled until the admin restores this club.",
                                  style: TextStyle(fontSize: 11, color: Color(0xFF795548))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildEventStream(isUpcoming: true),
                      _buildEventStream(isUpcoming: false),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showAddEventSheet(isClubActive),
              backgroundColor: isClubActive ? const Color(0xFF3674B5) : Colors.grey,
              elevation: 4,
              icon: Icon(isClubActive ? Icons.add_rounded : Icons.lock_outline, color: Colors.white),
              label: Text(isClubActive ? "New Event" : "Club Suspended", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          );
        }
    );
  }

  Widget _buildEventStream({required bool isUpcoming}) {
    final now = Timestamp.now();
    Query query = FirebaseFirestore.instance.collection('events').where('clubId', isEqualTo: widget.clubId);
    if (isUpcoming) {
      query = query.where('date', isGreaterThanOrEqualTo: now).orderBy('date', descending: false);
    } else {
      query = query.where('date', isLessThan: now).orderBy('date', descending: true);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF3674B5)));
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isUpcoming ? Icons.event_busy_rounded : Icons.history_rounded, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(isUpcoming ? "No upcoming events" : "No past events", style: const TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildEventCard(data, docs[index]);
          },
        );
      },
    );
  }

  Widget _buildEventCard(Map<String, dynamic> data, DocumentSnapshot doc) {
    final eventDate = (data['date'] as Timestamp?)?.toDate();
    final isPast = eventDate != null && eventDate.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(data['title'] ?? 'Event Title',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF3674B5))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 5),
              Text(data['date'] != null
                  ? (data['date'] as Timestamp).toDate().toString().split(' ')[0]
                  : 'TBD', style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 15),
              const Icon(Icons.location_on, size: 14, color: Colors.grey),
              const SizedBox(width: 5),
              Expanded(
                child: Text(data['location'] ?? 'TBD', style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isPast)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventFeedbackScreen(
                          eventId: doc.id,
                          eventTitle: data['title'] ?? 'Event',
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.analytics_outlined, size: 16),
                    label: const Text("AI Feedback", style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3674B5),
                      side: const BorderSide(color: Color(0xFF3674B5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventAttendeesScreen(
                          eventId: doc.id,
                          eventTitle: data['title'] ?? 'Event',
                          eventDate: eventDate,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.how_to_reg, size: 16, color: Colors.white),
                    label: const Text("Attendance", style: TextStyle(fontSize: 12, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3674B5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            )
          else if (data['tags'] != null && (data['tags'] as List).isNotEmpty)
            Wrap(
              spacing: 6,
              children: (data['tags'] as List).take(3).map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                child: Text('#$tag', style: const TextStyle(fontSize: 10, color: Colors.black54)),
              )).toList(),
            )
        ],
      ),
    );
  }
}