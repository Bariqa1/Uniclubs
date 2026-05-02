import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/ai_service.dart';
import 'event_attendees_screen.dart';
import 'event_feedback_screen.dart';

// ==========================================
// Event Management Page
// ==========================================
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

  void _showErrorDialog(BuildContext context, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Required Information", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK")),
        ],
      ),
    );
  }

  void _confirmDeleteEvent(BuildContext parentContext, String eventId, String title) {
    showDialog(
      context: parentContext,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Event", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to delete '$title'? This will remove all registrations."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('events').doc(eventId).delete();
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (!parentContext.mounted) return;
                ScaffoldMessenger.of(parentContext).showSnackBar(const SnackBar(content: Text("Event deleted successfully")));
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (parentContext.mounted) {
                  _showErrorDialog(parentContext, "Error deleting event: $e");
                }
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditEventSheet(BuildContext parentContext, DocumentSnapshot eventDoc, bool isClubActive) {
    if (!isClubActive) {
      ScaffoldMessenger.of(parentContext).showSnackBar(const SnackBar(content: Text("Action disabled while club is suspended."), backgroundColor: Colors.orange));
      return;
    }

    final data = eventDoc.data() as Map<String, dynamic>;
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: data['title']);
    final descCtrl = TextEditingController(text: data['description']);
    final locCtrl = TextEditingController(text: data['location']);
    final capacityCtrl = TextEditingController(text: (data['capacity'] ?? 50).toString());
    final tagsCtrl = TextEditingController(text: (data['tags'] as List? ?? []).join(', '));

    DateTime selectedEventDate = (data['date'] as Timestamp).toDate();
    TimeOfDay selectedEventTime = TimeOfDay.fromDateTime(selectedEventDate);
    DateTime selectedDeadlineDate = (data['registrationDeadline'] as Timestamp).toDate();
    TimeOfDay selectedDeadlineTime = TimeOfDay.fromDateTime(selectedDeadlineDate);

    String category = data['category'] ?? 'tech';
    bool isLoading = false;

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                    const SizedBox(height: 16),
                    const Text('Edit Event', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A))),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            TextFormField(controller: titleCtrl, decoration: _inputStyle('Event Title'), validator: (val) => val == null || val.isEmpty ? 'Required' : null),
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
                            TextFormField(controller: descCtrl, maxLines: 3, decoration: _inputStyle('Description'), validator: (val) => val == null || val.isEmpty ? 'Required' : null),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: TextFormField(controller: locCtrl, decoration: _inputStyle('Location'), validator: (val) => val == null || val.isEmpty ? 'Required' : null)),
                                const SizedBox(width: 12),
                                Expanded(child: TextFormField(controller: capacityCtrl, keyboardType: TextInputType.number, decoration: _inputStyle('Capacity'), validator: (val) => val == null || val.isEmpty ? 'Required' : null)),
                              ],
                            ),
                            const SizedBox(height: 24),

                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Event Date & Time', style: TextStyle(fontSize: 14, color: Colors.black87)),
                            ),
                            const SizedBox(height: 8),
                            _buildDateTimePickerRow(
                              context: context,
                              selectedDate: selectedEventDate,
                              selectedTime: selectedEventTime,
                              onDateSelected: (d) => setSheetState(() => selectedEventDate = d),
                              onTimeSelected: (t) => setSheetState(() => selectedEventTime = t),
                            ),
                            const SizedBox(height: 20),

                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Registration Deadline', style: TextStyle(fontSize: 14, color: Colors.black87)),
                            ),
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
                            DateTime eventDT = DateTime(selectedEventDate.year, selectedEventDate.month, selectedEventDate.day, selectedEventTime.hour, selectedEventTime.minute);
                            DateTime deadlineDT = DateTime(selectedDeadlineDate.year, selectedDeadlineDate.month, selectedDeadlineDate.day, selectedDeadlineTime.hour, selectedDeadlineTime.minute);

                            if (deadlineDT.isAfter(eventDT)) {
                              if(ctx.mounted) _showErrorDialog(ctx, "Registration deadline must be before the event starts!");
                              return;
                            }

                            setSheetState(() => isLoading = true);
                            try {
                              await FirebaseFirestore.instance.collection('events').doc(eventDoc.id).update({
                                'title': titleCtrl.text.trim(),
                                'description': descCtrl.text.trim(),
                                'category': category,
                                'location': locCtrl.text.trim(),
                                'capacity': int.tryParse(capacityCtrl.text.trim()) ?? 50,
                                'tags': tagsCtrl.text.split(',').map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty).toList(),
                                'date': Timestamp.fromDate(eventDT),
                                'registrationDeadline': Timestamp.fromDate(deadlineDT),
                              });
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                if(parentContext.mounted){
                                  ScaffoldMessenger.of(parentContext).showSnackBar(const SnackBar(content: Text('Event updated successfully'), backgroundColor: Colors.green));
                                }
                              }
                            } catch (e) {
                              setSheetState(() => isLoading = false);
                              if(ctx.mounted) _showErrorDialog(ctx, "Update failed: $e");
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3674B5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Update Event', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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

  // FIXED: Method now accepts currentStatus to handle pending vs suspended logic
  void _showAddEventSheet(BuildContext parentContext, bool isClubActive, String currentStatus) {
    if (!isClubActive) {
      String alertMsg = currentStatus == 'pending'
          ? "Action disabled: Your club is still under review."
          : "Action disabled while club is suspended.";

      ScaffoldMessenger.of(parentContext).showSnackBar(
          SnackBar(content: Text(alertMsg), backgroundColor: Colors.orange)
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final capacityCtrl = TextEditingController();
    final tagsCtrl = TextEditingController();

    DateTime? selectedEventDate;
    TimeOfDay? selectedEventTime;
    DateTime? selectedDeadlineDate;
    TimeOfDay? selectedDeadlineTime;

    String category = 'tech';
    bool isLoading = false;

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                    const SizedBox(height: 16),
                    const Align(alignment: Alignment.centerLeft, child: Text('Create New Event', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A)))),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            TextFormField(controller: titleCtrl, decoration: _inputStyle('Event Title'), validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null),
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
                            TextFormField(controller: descCtrl, maxLines: 3, decoration: _inputStyle('Description'), validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: TextFormField(controller: locCtrl, decoration: _inputStyle('Location'), validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null)),
                                const SizedBox(width: 12),
                                Expanded(child: TextFormField(controller: capacityCtrl, keyboardType: TextInputType.number, decoration: _inputStyle('Capacity'), validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null)),
                              ],
                            ),
                            const SizedBox(height: 24),

                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Event Date & Time', style: TextStyle(fontSize: 14, color: Colors.black87)),
                            ),
                            const SizedBox(height: 8),
                            _buildDateTimePickerRow(
                              context: context,
                              selectedDate: selectedEventDate,
                              selectedTime: selectedEventTime,
                              onDateSelected: (d) {
                                setSheetState(() {
                                  selectedEventDate = d;
                                  selectedDeadlineDate ??= d;
                                });
                              },
                              onTimeSelected: (t) {
                                setSheetState(() {
                                  selectedEventTime = t;
                                  selectedDeadlineTime ??= t;
                                });
                              },
                            ),
                            const SizedBox(height: 20),

                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Registration Deadline', style: TextStyle(fontSize: 14, color: Colors.black87)),
                            ),
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
                            if (selectedEventDate == null || selectedEventTime == null) {
                              if(ctx.mounted) _showErrorDialog(ctx, "Please select the event date and time.");
                              return;
                            }
                            if (selectedDeadlineDate == null || selectedDeadlineTime == null) {
                              if(ctx.mounted) _showErrorDialog(ctx, "Please select the registration deadline.");
                              return;
                            }
                            DateTime eventDT = DateTime(selectedEventDate!.year, selectedEventDate!.month, selectedEventDate!.day, selectedEventTime!.hour, selectedEventTime!.minute);
                            DateTime deadlineDT = DateTime(selectedDeadlineDate!.year, selectedDeadlineDate!.month, selectedDeadlineDate!.day, selectedDeadlineTime!.hour, selectedDeadlineTime!.minute);

                            if (eventDT.isBefore(DateTime.now())) {
                              if(ctx.mounted) _showErrorDialog(ctx, "The event time cannot be in the past.");
                              return;
                            }
                            if (deadlineDT.isAfter(eventDT)) {
                              if(ctx.mounted) _showErrorDialog(ctx, "The deadline must be before the event starts.");
                              return;
                            }

                            setSheetState(() => isLoading = true);
                            try {
                              List<String> tagsList = tagsCtrl.text.split(',').map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty).toList();
                              int capacity = int.tryParse(capacityCtrl.text.trim()) ?? 50;

                              int memberCount = 0;
                              try {
                                final membersSnap = await FirebaseFirestore.instance.collection('memberships').where('clubId', isEqualTo: widget.clubId).where('status', isEqualTo: 'approved').get();
                                memberCount = membersSnap.docs.length;
                              } catch (_) {}

                              final features = <String, dynamic>{
                                "capacity": capacity,
                                "tags_count": tagsList.length,
                                "interested_users_count": memberCount,
                                "past_avg_attendance": (capacity * 0.6).roundToDouble(),
                                "interest_ratio": memberCount > 0 ? (capacity / memberCount).clamp(0.0, 1.0) : 0.5,
                                "category_Arts": category == 'arts' ? 1 : 0,
                                "category_Community": category == 'social' ? 1 : 0,
                                "category_Education": category == 'academic' ? 1 : 0,
                                "category_Sports": category == 'sports' ? 1 : 0,
                                "category_Technology": category == 'tech' ? 1 : 0,
                              };

                              double predictionResult = 0.0;
                              try {
                                predictionResult = await AiService.predictAttendance(features);
                              } catch (_) {}

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
                                'predictedAttendance': predictionResult.toInt(),
                                'poster': '',
                              });
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                if(parentContext.mounted){
                                  ScaffoldMessenger.of(parentContext).showSnackBar(const SnackBar(content: Text('Event Created Successfully!'), backgroundColor: Colors.green));
                                }
                              }
                            } catch (e) {
                              setSheetState(() => isLoading = false);
                              if(ctx.mounted) _showErrorDialog(ctx, "Error: $e");
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3674B5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Publish Event', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
          String currentStatus = 'active';

          if (clubSnapshot.hasData && clubSnapshot.data!.exists) {
            final clubData = clubSnapshot.data!.data() as Map<String, dynamic>?;
            currentStatus = clubData?['status']?.toString().toLowerCase() ?? 'active';

            isClubActive = currentStatus == 'active';
          }

          return Scaffold(
            backgroundColor: const Color(0xFFE8F4FD),
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
                      color: currentStatus == 'pending' ? const Color(0xFFFFFDE7) : const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: currentStatus == 'pending' ? const Color(0xFFFFF176).withValues(alpha: 0.4) : const Color(0xFFFFB74D).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: currentStatus == 'pending' ? const Color(0xFFFFF176).withValues(alpha: 0.15) : const Color(0xFFFFB74D).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                              currentStatus == 'pending' ? Icons.hourglass_empty_rounded : Icons.lock_outline_rounded,
                              color: currentStatus == 'pending' ? const Color(0xFFF57F17) : const Color(0xFFE65100),
                              size: 18
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentStatus == 'pending'
                                    ? "Pending Approval"
                                    : "Club Suspended",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: currentStatus == 'pending' ? const Color(0xFFF57F17) : const Color(0xFFE65100),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentStatus == 'pending'
                                    ? "Your club is under review. You can add events once approved."
                                    : "Adding events is disabled until the admin restores this club.",
                                style: const TextStyle(fontSize: 11, color: Color(0xFF795548)),
                              ),
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
                      _buildEventStream(isUpcoming: true, isClubActive: isClubActive),
                      _buildEventStream(isUpcoming: false, isClubActive: isClubActive),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showAddEventSheet(context, isClubActive, currentStatus),
              backgroundColor: isClubActive ? const Color(0xFF3674B5) : Colors.grey,
              elevation: 4,
              icon: Icon(
                  isClubActive
                      ? Icons.add_rounded
                      : (currentStatus == 'pending' ? Icons.hourglass_empty_rounded : Icons.lock_outline),
                  color: Colors.white
              ),
              label: Text(
                  isClubActive
                      ? "New Event"
                      : (currentStatus == 'pending' ? "Under Review" : "Club Suspended"),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
              ),
            ),
          );
        }
    );
  }

  Widget _buildEventStream({required bool isUpcoming, required bool isClubActive}) {
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
            return _buildEventCard(context, data, docs[index], isClubActive);
          },
        );
      },
    );
  }

  Widget _buildEventCard(BuildContext parentContext, Map<String, dynamic> data, DocumentSnapshot doc, bool isClubActive) {
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
              if (!isPast)
                PopupMenuButton<String>(
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (val) {
                    if (val == 'edit') _showEditEventSheet(parentContext, doc, isClubActive);
                    if (val == 'delete') _confirmDeleteEvent(parentContext, doc.id, data['title'] ?? 'Event');
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit, size: 20), title: Text('Edit', style: TextStyle(fontSize: 14)))),
                    const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red, size: 20), title: Text('Delete', style: TextStyle(color: Colors.red, fontSize: 14)))),
                  ],
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
                      parentContext,
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
                      parentContext,
                      MaterialPageRoute(
                        builder: (_) => EventAttendeesScreen(
                          eventId: doc.id,
                          eventTitle: data['title'] ?? 'Event',
                          eventDate: eventDate!, // Null check is fine here due to context
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