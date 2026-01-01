import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../screens/add_shift_screen.dart';
import '../services/api_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;

  Future<void> _captureImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);

      if (image == null) return;

      setState(() => _isAnalyzing = true);

      // Read image bytes
      final Uint8List imageBytes = await image.readAsBytes();

      // Save to phone gallery immediately if taken from camera
      if (source == ImageSource.camera) {
        await Gal.putImageBytes(imageBytes);
      }

      // Call the Supabase Edge Function to analyze the image
      final analysisData = await ApiService.analyzeImage(imageBytes);
      final analysisResult = jsonEncode(analysisData);

      setState(() => _isAnalyzing = false);

      if (!mounted) return;

      // Navigate to AddShiftScreen with pre-filled data
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddShiftScreen(
            aiAnalysis: analysisResult,
            imageBytes: imageBytes,
          ),
        ),
      );
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error analyzing image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Document')),
      body: _isAnalyzing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Analyzing image with AI...'),
                ],
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt, size: 100, color: Colors.grey),
                  const SizedBox(height: 40),
                  const Text(
                    'Scan a Document',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'BEO, Paycheck, or Receipt',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 60),
                  ElevatedButton.icon(
                    onPressed: () => _captureImage(ImageSource.camera),
                    icon: const Icon(Icons.camera),
                    label: const Text('Take Photo'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () => _captureImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Choose from Gallery'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
