import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pill_box/screens/forgot_password_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _image;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // متغيرات لتخزين البيانات المجلوبة من Firebase
  String userName = 'جارِ التحميل...';
  String dob = "غير محدد";
  String bloodType = "---";
  String weight = "--- kg";
  String height = "--- cm";
  String selectedAlarm = "Default";

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  // 1. جلب البيانات من Firestore عند تشغيل الصفحة
  Future<void> loadUserData() async {
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .get();

        if (userDoc.exists && mounted) {
          setState(() {
            // التعديل هنا: استخدمنا 'name' بدلاً من 'userName'
            userName = userDoc['name'] ?? 'مستخدم جديد';

            // هذه الحقول قد لا تكون موجودة في البداية، لذا نضع قيم افتراضية
            dob = userDoc['dob'] ?? "لم يحدد";
            bloodType = userDoc['bloodType'] ?? "---";
            weight = userDoc['weight'] ?? "--- kg";
            height = userDoc['height'] ?? "--- cm";
          });
        }
      } catch (e) {
        debugPrint("Error loading data: $e");
      }
    }
  }

  //اختيار تاريخ ميلاد
  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      String formattedDate = "${picked.day}/${picked.month}/${picked.year}";
      await updateFirestoreField("dob", formattedDate); // تحديث في فايربيس
      setState(() => dob = formattedDate); // تحديث الواجهة
    }
  }

  //دالة اختيار فصيلة الدم
  void _selectBloodType() {
    final types = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"];
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: types
              .map(
                (type) => ListTile(
                  title: Text(type, textAlign: TextAlign.center),
                  onTap: () async {
                    await updateFirestoreField("bloodType", type);
                    setState(() => bloodType = type);
                    Navigator.pop(context);
                  },
                ),
              )
              .toList(),
        );
      },
    );
  }

  // 2. دالة تحديث الحقول في Firestore
  Future<void> updateFirestoreField(String field, String value) async {
    if (currentUser != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .update({field: value});
      } catch (e) {
        debugPrint("Error updating $field: $e");
      }
    }
  }

  // 3. دالة اختيار الصورة الشخصية
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedImage != null) {
      setState(() => _image = File(pickedImage.path));
    }
  }

  // 4. نافذة التعديل المنبثقة (تستخدم لجميع الحقول)
  Future<void> _editInfo(
    String title,
    String currentValue,
    String firestoreField,
    Function(String) onSave,
  ) async {
    final controller = TextEditingController(text: currentValue);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Edit $title"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Enter $title",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newValue = controller.text.trim();
              if (newValue.isNotEmpty) {
                await updateFirestoreField(firestoreField, newValue);
                onSave(newValue);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _profileCard(),
              const SizedBox(height: 20),
              _infoCard(),
              const SizedBox(height: 20),
              _settingsCard(),
            ],
          ),
        ),
      ),
    );
  }

  // الكرت العلوي: الصورة والاسم والتاريخ والفصيلة
  Widget _profileCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: _image != null ? FileImage(_image!) : null,
                  child: _image == null
                      ? const Icon(Icons.person, size: 60, color: Colors.grey)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blue,
                      child: const Icon(
                        Icons.edit,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            userName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // اختيار التاريخ من التقويم
              InkWell(onTap: _selectDate, child: _smallInfo(Icons.cake, dob)),
              const SizedBox(width: 20),
              // اختيار فصيلة الدم من قائمة
              InkWell(
                onTap: _selectBloodType,
                child: _smallInfo(Icons.bloodtype, bloodType),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallInfo(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 6),
        Text(value, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  // كرت الطول والوزن
  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          _InfoTile(
            Icons.monitor_weight,
            'Weight',
            weight,
            onTap: () => _editInfo(
              "Weight",
              weight,
              "weight",
              (v) => setState(() => weight = v),
            ),
          ),
          const Divider(),
          _InfoTile(
            Icons.height,
            'Height',
            height,
            onTap: () => _editInfo(
              "Height",
              height,
              "height",
              (v) => setState(() => height = v),
            ),
          ),
        ],
      ),
    );
  }

  // كرت الإعدادات والخروج
  Widget _settingsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: _iconBox(Icons.lock, iconColor: Colors.blue),
            title: const Text('Change Password'),
            trailing: const Text(
              'Change',
              style: TextStyle(color: Colors.blue),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ForgotPasswordScreen()),
              );
            },
          ),
          const Divider(),
          const SizedBox(height: 20),

          ListTile(
            leading: _iconBox(Icons.info),
            title: const Text('About'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: "Pill Box",
                applicationVersion: "1.0.0",
                applicationIcon: const Icon(
                  Icons.health_and_safety_outlined,
                  size: 40,
                  color: Color(0xFF4DB6D6),
                ),
                children: const [
                  Text(
                    "This app helps you organize your medicines and track adherence.",
                  ),
                ],
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Log Out', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ويدجت الصفوف الصغيرة (الطول/الوزن)
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;
  const _InfoTile(this.icon, this.title, this.value, {this.onTap});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      horizontalTitleGap: 0,
    );
  }
}

Widget _iconBox(IconData icon, {Color iconColor = Colors.blue}) {
  return Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: const Color(0xFFEFF3F8),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, color: iconColor),
  );
}
