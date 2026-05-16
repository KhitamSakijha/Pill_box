import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/Medicine.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onTabChange;

  const HomeScreen({super.key, this.onTabChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime selectedDate = DateTime.now();
  int newNotifications = 3;
  String userName = 'User';
  final userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    loadUserName();
  }

  Future<void> loadUserName() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final name = doc.data()?['name'] ?? 'User';

      if (mounted) {
        setState(() => userName = name);
      }
    } catch (e) {
      debugPrint("Error loading username: $e");
    }
  }

  // -------------------- الحسابات --------------------

  List<Medicine> getTodayMedicines(List<Medicine> allMeds) {
    return allMeds.where((m) {
      final day = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
      final startDate = DateTime(
        m.startDate.year,
        m.startDate.month,
        m.startDate.day,
      );
      final endDate = DateTime(m.endDate.year, m.endDate.month, m.endDate.day);

      return !day.isBefore(startDate) && !day.isAfter(endDate) && m.isActive;
    }).toList();
  }

  String nextDoseText(List<Medicine> todayMeds) {
    if (todayMeds.isEmpty) return 'No meds today';

    DateTime? next;
    Medicine? nextMed;

    for (final m in todayMeds) {
      final dose = m.nextDose(selectedDate);
      if (dose != null && (next == null || dose.isBefore(next))) {
        next = dose;
        nextMed = m;
      }
    }

    if (next == null || nextMed == null) return 'All taken';

    return '${nextMed.name} at ${DateFormat.jm().format(next)}';
  }

  String calculateAdherence(List<Medicine> meds) {
    if (meds.isEmpty) return '0%';

    double total = 0;
    for (var m in meds) {
      total += m.dailyAdherence(selectedDate);
    }

    return '${(total / meds.length).toStringAsFixed(0)}%';
  }

  String calculateStreak(List<Medicine> meds) {
    if (meds.isEmpty) return '0 Days';

    int max = 0;
    for (var m in meds) {
      int s = m.streak();
      if (s > max) max = s;
    }

    return '$max Days';
  }

  int remainingDoses(List<Medicine> todayMeds) {
    int remaining = 0;
    for (final m in todayMeds) {
      remaining += m.remainingDoses(selectedDate).length;
    }
    return remaining;
  }

  // -------------------- UI --------------------

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Scaffold(body: Center(child: Text("Please Login")));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Medicine') // عدّلي الاسم إذا مختلف
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final List<Medicine> allMedicines =
            snapshot.data?.docs
                .map((doc) => Medicine.fromFirestore(doc))
                .toList() ??
            [];

        final todayMeds = getTodayMedicines(allMedicines);

        return Scaffold(
          backgroundColor: const Color(0xffF6F7FB),
          appBar: _buildAppBar(),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Next Dose Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Next Dose',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      nextDoseText(todayMeds),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _infoCard(
                      title: 'Daily Adherence',
                      value: calculateAdherence(todayMeds),
                      subtitle: '${todayMeds.length} meds today',
                      valueColor: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _infoCard(
                      title: 'Streak',
                      value: calculateStreak(allMedicines),
                      subtitle: 'Keep it up!',
                      valueColor: Colors.orange,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              _buildPillboxCard(todayMeds),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Welcome",
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPillboxCard(List<Medicine> todayMeds) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.purpleAccent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Smart Pillbox', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 6),
          Text(
            'Remaining doses today: ${remainingDoses(todayMeds)}',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required String value,
    required String subtitle,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
