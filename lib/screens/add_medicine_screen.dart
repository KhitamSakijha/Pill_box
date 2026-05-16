import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:pill_box/models/Medicine.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';

class AddMedicineScreen extends StatefulWidget {
  final Medicine? existing;

  const AddMedicineScreen({super.key, this.existing});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final nameController = TextEditingController();
  final doseController = TextEditingController();
  final notesController = TextEditingController();

  String frequency = 'Daily';
  bool withFood = false;
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now().add(const Duration(days: 7));
  List<TimeOfDay> times = [];

  CollectionReference medicineCollection = FirebaseFirestore.instance
      .collection('Medicine');
  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final m = widget.existing!;
      nameController.text = m.name;
      doseController.text = m.dose;
      notesController.text = m.notes;
      frequency = m.frequency;
      withFood = m.withFood;
      startDate = m.startDate;
      endDate = m.endDate;
      times = List.from(m.times);
    }
  }

  Future<void> saveMedicine() async {
    // 1. التحقق من الحقول الأساسية
    if (nameController.text.isEmpty ||
        doseController.text.isEmpty ||
        times.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and add at least one time'),
        ),
      );
      return;
    }

    // 2. التحقق من تسجيل دخول المستخدم
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("No user logged in!");
      return;
    }

    // 3. إنشاء كائن الدواء (Medicine Object)
    final medicine = Medicine(
      id:
          widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      userId: user.uid,
      name: nameController.text,
      dose: doseController.text,
      frequency: frequency,
      withFood: withFood,
      notes: notesController.text,
      startDate: startDate,
      endDate: endDate,
      times: times,
    );
    try {
      print("1. Attempting to save to Firestore...");

      if (widget.existing == null) {
        // حفظ في داتابيز أولاً
        await medicineCollection.add(medicine.toFirestore());

        print("2. Scheduling Finished.");
      } else {
        // تحديث دواء موجود
        await medicineCollection
            .doc(widget.existing!.id)
            .update(medicine.toFirestore());
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Add Medicine' : 'Edit Medicine'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _field('Medicine Name', nameController),
            _field('Dose', doseController),
            DropdownButtonFormField<String>(
              initialValue: frequency,
              decoration: const InputDecoration(labelText: 'Frequency'),
              items: const [
                DropdownMenuItem(value: 'Daily', child: Text('Daily')),
                DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                DropdownMenuItem(value: 'As Needed', child: Text('As Needed')),
              ],
              onChanged: (v) => setState(() => frequency = v!),
            ),
            const SizedBox(height: 12),

            GestureDetector(
              onTap: () {
                DatePicker.showTimePicker(
                  context,
                  showTitleActions: true,
                  onConfirm: (DateTime dt) {
                    setState(() {
                      times.add(TimeOfDay(hour: dt.hour, minute: dt.minute));
                    });
                  },
                  currentTime: DateTime.now(),
                  locale: LocaleType.en,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      times.isEmpty
                          ? 'Tap to add time'
                          : times.map((t) => t.format(context)).join(', '),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Icon(Icons.access_time),
                  ],
                ),
              ),
            ),

            ListTile(
              title: const Text('Start Date'),
              subtitle: Text(DateFormat.yMd().format(startDate)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  initialDate: startDate,
                );
                if (picked != null) setState(() => startDate = picked);
              },
            ),
            ListTile(
              title: const Text('End Date'),
              subtitle: Text(DateFormat.yMd().format(endDate)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  initialDate: endDate,
                );
                if (picked != null) setState(() => endDate = picked);
              },
            ),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes / Instructions',
              ),
            ),
            CheckboxListTile(
              title: const Text('Take with Food'),
              value: withFood,
              onChanged: (v) => setState(() => withFood = v!),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveMedicine,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text(
                widget.existing == null ? 'Save Medicine' : 'Update Medicine',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
