import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Medicine {
  final String id;
  final String userId;
  String name;
  String dose;
  String frequency;
  DateTime startDate;
  DateTime endDate;
  String notes;
  bool withFood;
  bool isActive;
  bool isTakenToday;
  List<TimeOfDay> times;
  List<DateTime> takenHistory;

  Medicine({
    required this.id,
    required this.userId,
    required this.name,
    required this.dose,
    required this.frequency,
    required this.startDate,
    required this.endDate,
    this.notes = '',
    this.withFood = false,
    this.isActive = true,
    this.isTakenToday = false,
    required this.times,
    List<DateTime>? takenHistory,
  }) : takenHistory = takenHistory ?? [];

  // 🔹 من Firestore إلى Medicine
  factory Medicine.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    List<DateTime> history = (data['takenHistory'] as List<dynamic>? ?? []).map(
      (e) {
        if (e is Timestamp) return e.toDate();
        return DateTime.now();
      },
    ).toList();

    bool takenToday = history.any(
      (date) =>
          date.year == DateTime.now().year &&
          date.month == DateTime.now().month &&
          date.day == DateTime.now().day,
    );

    return Medicine(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['Medicinename'] ?? '',
      dose: data['dose'] ?? '',
      frequency: data['frequency'] ?? 'Daily',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate:
          (data['endDate'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 30)),
      notes: data['notes'] ?? '',
      withFood: data['withFood'] ?? false,
      isActive: data['isActive'] ?? true,
      isTakenToday: data['isTakenToday'] ?? takenToday,
      times: (data['times'] as List<dynamic>? ?? []).map((t) {
        final split = t.toString().split(':');
        return TimeOfDay(
          hour: int.parse(split[0]),
          minute: int.parse(split[1]),
        );
      }).toList(),
      takenHistory: history,
    );
  }

  // 🔹 تصحيح دالة fromMap (للتعامل مع SharedPreferences)
  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      dose: map['dose'] ?? '',
      frequency: map['frequency'] ?? 'Daily',
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      notes: map['notes'] ?? '',
      withFood: map['withFood'] ?? false,
      isActive: map['isActive'] ?? true,
      isTakenToday: map['isTakenToday'] ?? false,
      times: (map['times'] as List<dynamic>).map((t) {
        final split = t.toString().split(':');
        return TimeOfDay(
          hour: int.parse(split[0]),
          minute: int.parse(split[1]),
        );
      }).toList(),
      takenHistory: (map['takenHistory'] as List<dynamic>)
          .map((e) => DateTime.parse(e))
          .toList(),
    );
  }

  // 🔹 تصحيح دالة toMap (للتحويل إلى JSON)
  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'name': name,
    'dose': dose,
    'frequency': frequency,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'notes': notes,
    'withFood': withFood,
    'isActive': isActive,
    'isTakenToday': isTakenToday,
    'times': times.map((t) => '${t.hour}:${t.minute}').toList(),
    'takenHistory': takenHistory.map((d) => d.toIso8601String()).toList(),
  };

  // 🔹 التحويل لـ Firestore
  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'Medicinename': name,
    'dose': dose,
    'frequency': frequency,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    'notes': notes,
    'withFood': withFood,
    'isActive': isActive,
    'isTakenToday': isTakenToday,
    'times': times.map((t) => '${t.hour}:${t.minute}').toList(),
    'takenHistory': takenHistory.map((d) => Timestamp.fromDate(d)).toList(),
  };

  void resetDailyStatus() {
    isTakenToday = false;
  }
}

// الـ Extensions تظل كما هي
extension MedicineExtensions on Medicine {
  DateTime? nextDose(DateTime day) {
    if (!isActive) return null;
    final d = DateTime(day.year, day.month, day.day);
    for (final t in times) {
      final time = DateTime(d.year, d.month, d.day, t.hour, t.minute);
      if (!takenHistory.any((e) => e.isAtSameMomentAs(time)) &&
          time.isAfter(DateTime.now())) {
        return time;
      }
    }
    return null;
  }

  double dailyAdherence(DateTime day) {
    if (times.isEmpty) return 0;
    final d = DateTime(day.year, day.month, day.day);
    final taken = times.where((t) {
      final time = DateTime(d.year, d.month, d.day, t.hour, t.minute);
      return takenHistory.any((e) => e.isAtSameMomentAs(time));
    }).length;
    return (taken / times.length) * 100;
  }

  int streak() {
    if (takenHistory.isEmpty) return 0;
    // ترتيب التاريخ من الأحدث للأقدم
    var sortedHistory = List<DateTime>.from(takenHistory)
      ..sort((a, b) => b.compareTo(a));
    int count = 0;
    DateTime currentDay = DateTime.now();

    for (var date in sortedHistory) {
      final difference = DateTime(
        currentDay.year,
        currentDay.month,
        currentDay.day,
      ).difference(DateTime(date.year, date.month, date.day)).inDays;

      if (difference <= 1) {
        count++;
        currentDay = date;
      } else {
        break;
      }
    }
    return count;
  }

  List<TimeOfDay> remainingDoses(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return times.where((t) {
      final time = DateTime(d.year, d.month, d.day, t.hour, t.minute);
      return !takenHistory.any((e) => e.isAtSameMomentAs(time)) &&
          time.isAfter(DateTime.now());
    }).toList();
  }
}
