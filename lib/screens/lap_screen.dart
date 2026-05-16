import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart'; // المكتبة الجديدة
import 'package:cloud_firestore/cloud_firestore.dart'; // قاعدة البيانات
import 'package:firebase_storage/firebase_storage.dart'; // تخزين الملفات
import 'dart:io';

class LapResult {
  final String id; // أضفنا معرف السجل
  final String name;
  final String type;
  final DateTime date;
  final String fileUrl; // رابط الملف على الإنترنت بدلاً من File المحلي

  LapResult({
    required this.id,
    required this.name,
    required this.type,
    required this.date,
    required this.fileUrl,
  });
}

class LapScreen extends StatefulWidget {
  const LapScreen({super.key});

  @override
  State<LapScreen> createState() => _LabScreenState();
}

class _LabScreenState extends State<LapScreen> {
  // دالة لرفع الملف إلى Firebase Storage ثم حفظ بياناته في Firestore
  Future<void> uploadAndSaveFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false, // للتبسيط سنرفع ملفاً واحداً في كل مرة
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;

      try {
        // 1. رفع الملف إلى Storage
        TaskSnapshot uploadTask = await FirebaseStorage.instance
            .ref('lab_results/$fileName')
            .putFile(file);

        // 2. الحصول على رابط التحميل
        String downloadUrl = await uploadTask.ref.getDownloadURL();

        // 3. حفظ البيانات في Firestore
        await FirebaseFirestore.instance.collection('lab_results').add({
          'name': fileName,
          'type': result.files.single.extension ?? 'file',
          'date': DateTime.now(),
          'fileUrl': downloadUrl,
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Uploaded Successfully!')));
      } catch (e) {
        // هذا السطر سيظهر لكِ الخطأ في هاتفك مباشرة لتعرفي السبب
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        print("Detail Error: $e");
      }
    }
  }

  void openFile(LapResult lab) {
    if (lab.type == 'pdf') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PDFViewerScreen(url: lab.fileUrl)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ImagePreviewScreen(imageUrl: lab.fileUrl),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab Results (Firebase)'),
        backgroundColor: const Color(0xFF2196F3),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: uploadAndSaveFile),
        ],
      ),
      // استخدام StreamBuilder لجلب البيانات مباشرة من Firebase
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('lab_results')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No lab files found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (_, index) {
              var doc = snapshot.data!.docs[index];
              final lab = LapResult(
                id: doc.id,
                name: doc['name'],
                type: doc['type'],
                date: (doc['date'] as Timestamp).toDate(),
                fileUrl: doc['fileUrl'],
              );

              return Card(
                child: ListTile(
                  leading: Icon(
                    lab.type == 'pdf' ? Icons.picture_as_pdf : Icons.image,
                    color: Colors.purpleAccent,
                  ),
                  title: Text(lab.name),
                  subtitle: Text(
                    'Date: ${lab.date.day}/${lab.date.month}/${lab.date.year}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.remove_red_eye,
                          color: Colors.blue,
                        ),
                        onPressed: () => openFile(lab),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('lab_results')
                              .doc(lab.id)
                              .delete();
                          // ملاحظة: يفضل أيضاً حذف الملف من Storage هنا
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ImagePreviewScreen extends StatelessWidget {
  final String imageUrl;
  const ImagePreviewScreen({super.key, required this.imageUrl});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
        backgroundColor: Colors.purpleAccent,
      ),
      body: Center(
        child: Image.network(imageUrl),
      ), // استخدام Network بدلاً من File
    );
  }
}

class PDFViewerScreen extends StatelessWidget {
  final String url; // نمرر الرابط هنا
  const PDFViewerScreen({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Viewer'),
        backgroundColor: Colors.purpleAccent,
      ),
      // هذه الأداة تقوم بكل شيء: التحميل، إظهار مؤشر الانتظار، والعرض
      body: SfPdfViewer.network(url),
    );
  }
}

/*import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';

class LapResult {
  final String name;
  final String type;
  final DateTime date;
  final File file;

  LapResult({
    required this.name,
    required this.type,
    required this.date,
    required this.file,
  });
}

class LapScreen extends StatefulWidget {
  const LapScreen({super.key});

  @override
  State<LapScreen> createState() => _LabScreenState();
}

class _LabScreenState extends State<LapScreen> {
  List<LapResult> labFiles = [];

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        labFiles.addAll(
          result.files.map(
            (f) => LapResult(
              name: f.name,
              type: f.extension ?? 'file',
              date: DateTime.now(),
              file: File(f.path!),
            ),
          ),
        );
      });
    }
  }

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void openFile(LapResult lab) {
    if (lab.type == 'pdf') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PDFViewerScreen(file: lab.file)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ImagePreviewScreen(imageFile: lab.file),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab Results'),
        backgroundColor: Colors.purpleAccent,
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: pickFile)],
      ),
      body: labFiles.isEmpty
          ? const Center(
              child: Text(
                'No lab files uploaded yet.\nTap + to add files.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: labFiles.length,
              itemBuilder: (_, index) {
                final lab = labFiles[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: Icon(
                      lab.type == 'pdf' ? Icons.picture_as_pdf : Icons.image,
                      color: Colors.purpleAccent,
                      size: 32,
                    ),
                    title: Text(lab.name),
                    subtitle: Text(
                      'Type: ${lab.type} • Date: ${formatDate(lab.date)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.remove_red_eye,
                            color: Colors.blue,
                          ),
                          onPressed: () => openFile(lab),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              labFiles.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// عرض الصور
class ImagePreviewScreen extends StatelessWidget {
  final File imageFile;
  const ImagePreviewScreen({super.key, required this.imageFile});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Image'),
        backgroundColor: Colors.purpleAccent,
      ),
      body: Center(child: Image.file(imageFile)),
    );
  }
}

// عرض ملفات PDF
class PDFViewerScreen extends StatelessWidget {
  final File file;
  const PDFViewerScreen({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Viewer'),
        backgroundColor: Colors.purpleAccent,
      ),
      body: PDFView(filePath: file.path),
    );
  }
}
*/
