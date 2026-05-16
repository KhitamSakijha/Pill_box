import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/Medicine.dart';

class MedicineService {
  static const _key = 'medicines';

  // Get all medicines
  static Future<List<Medicine>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return [];

    final List decoded = jsonDecode(data);
    return decoded.map((e) => Medicine.fromMap(e)).toList();
  }

  // Add medicine
  static Future<void> add(Medicine medicine) async {
    final list = await getAll();
    list.add(medicine);
    await _save(list);
  }

  // Update medicine by index
  static Future<void> update(int index, Medicine medicine) async {
    final list = await getAll();
    if (index < 0 || index >= list.length) return;

    list[index] = medicine;
    await _save(list);
  }

  // Delete medicine by index
  static Future<void> delete(int index) async {
    final list = await getAll();
    if (index < 0 || index >= list.length) return;

    list.removeAt(index);
    await _save(list);
  }

  // Save list
  static Future<void> _save(List<Medicine> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(list.map((m) => m.toMap()).toList()),
    );
  }
}
