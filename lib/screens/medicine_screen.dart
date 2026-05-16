import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pill_box/models/Medicine.dart';
import 'add_medicine_screen.dart';

class MedicineScreen extends StatefulWidget {
  const MedicineScreen({super.key});

  @override
  State<MedicineScreen> createState() => _MedicineScreenState();
}

class _MedicineScreenState extends State<MedicineScreen> {
  DateTime selectedDate = DateTime.now();
  final ScrollController _calendarController = ScrollController();
  final userId = FirebaseAuth.instance.currentUser?.uid;
  late Stream<QuerySnapshot> _medicineStream;

  @override
  void initState() {
    super.initState();
    // إعداد الـ Stream مرة واحدة في البداية
    _medicineStream = FirebaseFirestore.instance
        .collection('Medicine')
        .where('userId', isEqualTo: userId)
        .snapshots();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dayIndex = selectedDate.day - 1;
      if (_calendarController.hasClients) {
        _calendarController.jumpTo(dayIndex * 62.0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _medicineStream,
      builder: (context, snapshot) {
        // حساب عدد الأدوية المضافة للتحكم في الزر
        final int medicineCount = snapshot.data?.docs.length ?? 0;

        return Scaffold(
          backgroundColor: const Color(0xFFF6F7FB),
          appBar: AppBar(
            title: const Text('Medicine Schedule'),
            centerTitle: true,
            backgroundColor: const Color(0xffF6F7FB),
          ),
          // الزر يظهر فقط إذا لم يكن هناك دواء مضاف
          floatingActionButton: medicineCount == 0
              ? FloatingActionButton(
                  backgroundColor: const Color(0xFF2196F3),
                  child: const Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddMedicineScreen(),
                      ),
                    );
                  },
                )
              : null,
          body: Column(
            children: [
              _buildCalendar(),
              const SizedBox(height: 12),
              _buildHeader(),
              // نمرر الـ snapshot والدالة تقوم بالعرض
              Expanded(child: _buildMedicineList(snapshot)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalendar() {
    final daysInMonth = DateUtils.getDaysInMonth(
      selectedDate.year,
      selectedDate.month,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            DateFormat('MMMM yyyy', 'en').format(selectedDate),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView.builder(
            controller: _calendarController,
            scrollDirection: Axis.horizontal,
            itemCount: daysInMonth,
            itemBuilder: (context, index) {
              final day = DateTime(
                selectedDate.year,
                selectedDate.month,
                index + 1,
              );
              final isSelected = DateUtils.isSameDay(day, selectedDate);
              final isToday = DateUtils.isSameDay(day, DateTime.now());

              return GestureDetector(
                onTap: () => setState(() => selectedDate = day),
                child: Container(
                  width: 56,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue
                        : isToday
                        ? Colors.blue.shade100
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('EEE', 'en').format(day),
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected ? Colors.white : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        day.day.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Medicines',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // تم تصحيح هذه الدالة لاستقبال البيانات مباشرة من الـ Stream الرئيسي
  Widget _buildMedicineList(AsyncSnapshot<QuerySnapshot> snapshot) {
    if (userId == null) return const Center(child: Text('User not logged in'));

    if (snapshot.hasError) {
      return const Center(child: Text('Something went wrong'));
    }

    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    final docs = snapshot.data!.docs;
    final List<Medicine> filteredMedicines = docs
        .map((doc) {
          return Medicine.fromFirestore(doc);
        })
        .where((medicine) {
          // نقوم بإخفاء الوقت من التاريخ لنقارن الأيام فقط
          DateTime pureSelectedDate = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
          );
          DateTime pureStartDate = DateTime(
            medicine.startDate.year,
            medicine.startDate.month,
            medicine.startDate.day,
          );
          DateTime pureEndDate = DateTime(
            medicine.endDate.year,
            medicine.endDate.month,
            medicine.endDate.day,
          );

          // الشرط: يجب أن يكون التاريخ المختار بين البداية والنهاية (بما في ذلك يوم البداية والنهاية)
          return pureSelectedDate.isAtSameMomentAs(pureStartDate) ||
              pureSelectedDate.isAtSameMomentAs(pureEndDate) ||
              (pureSelectedDate.isAfter(pureStartDate) &&
                  pureSelectedDate.isBefore(pureEndDate));
        })
        .toList();

    if (filteredMedicines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'No medicines scheduled for this day.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredMedicines.length,
      itemBuilder: (context, index) {
        // final data = docs[index];
        final medicine = filteredMedicines[index];
        final docId = docs.firstWhere((d) => d.id == medicine.id).id;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const Icon(Icons.medication, color: Colors.blue),
            title: Text(
              medicine.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('${medicine.dose} • ${medicine.frequency}'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      medicine.withFood ? Icons.restaurant : Icons.no_meals,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      medicine.withFood
                          ? 'Take with Food'
                          : 'Take without Food',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddMedicineScreen(existing: medicine),
                ),
              );
            },
            onLongPress: () => _showDeleteDialog(medicine, docId),
          ),
        );
      },
    );
  }

  // دالة منفصلة للحذف لجعل الكود أنظف
  Future<void> _showDeleteDialog(Medicine medicine, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Medicine'),
        content: const Text(
          'Are you sure you want to delete this medicine and cancel all its reminders?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('Medicine')
            .doc(docId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medicine deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}
