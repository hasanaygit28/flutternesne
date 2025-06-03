import 'dart:convert';
import 'dart:typed_data';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

const String apiKey = 'AIzaSyD7FPfUo9SOS9nW7Ph7RWFjfg9iGzaWSmQ';

class ImageLabelPage extends StatefulWidget {
  const ImageLabelPage({super.key});

  @override
  State<ImageLabelPage> createState() => _ImageLabelPageState();
}

class _ImageLabelPageState extends State<ImageLabelPage> {
  List<String> labels = [];
  bool loading = false;
  Uint8List? selectedImage;

  Future<void> pickAndLabelImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result == null || result.files.single.bytes == null) return;

      final bytes = result.files.single.bytes!;
      final base64Image = base64Encode(bytes);

      setState(() {
        selectedImage = bytes;
        loading = true;
        labels = [];
      });

      final response = await http.post(
        Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "requests": [
            {
              "image": {"content": base64Image},
              "features": [{"type": "LABEL_DETECTION", "maxResults": 10}]
            }
          ]
        }),
      );

      log("Vision API status: \${response.statusCode}");
      log("Vision API body: \${response.body}");

      if (response.statusCode != 200) {
        setState(() {
          loading = false;
          labels = ['Vision API hatası: \${response.statusCode}'];
        });
        return;
      }

      final json = jsonDecode(response.body);

      if (json['responses'] == null ||
          json['responses'].isEmpty ||
          json['responses'][0]['labelAnnotations'] == null) {
        setState(() {
          loading = false;
          labels = ['Etiket bulunamadı.'];
        });
        return;
      }

      final annotations = json['responses'][0]['labelAnnotations'];
      final resultLabels = <String>[];

      for (var e in annotations) {
        final label = e['description'];
        final translated = await translateText(label);
        resultLabels.add(translated);
      }

      setState(() {
        labels = resultLabels;
        loading = false;
      });
    } catch (e) {
      log("Genel hata: $e");
      setState(() {
        loading = false;
        labels = ['Bir hata oluştu: $e'];
      });
    }
  }

  Future<String> translateText(String text) async {
    final uri = Uri.parse('https://translation.googleapis.com/language/translate/v2?key=$apiKey');

    final requestBody = {
      'q': text,
      'source': 'en',
      'target': 'tr',
      'format': 'text',
    };

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      return 'Çeviri başarısız (\${response.statusCode})';
    }

    final data = jsonDecode(response.body);
    final translated = data['data']['translations'][0]['translatedText'];
    return toBeginningOfSentenceCase(translated) ?? translated;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nesne Tanıma'),
        backgroundColor: const Color(0xFF8D6E63),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: loading ? null : pickAndLabelImage,
                icon: const Icon(Icons.image),
                label: const Text("Resim Seç ve Etiketle"),
              ),
              const SizedBox(height: 24),
              if (selectedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(selectedImage!, height: 200),
                ),
              const SizedBox(height: 24),
              if (loading)
                const CircularProgressIndicator(),
              if (!loading && labels.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fotoğrafta Bulunan Etiketler:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: labels.map((label) => Chip(
                        avatar: const Icon(Icons.label_important, color: Colors.brown),
                        label: Text(
                          label,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFFBCAAA4)),
                        ),
                        backgroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      )).toList(),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
