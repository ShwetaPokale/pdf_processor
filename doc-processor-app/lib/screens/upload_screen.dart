import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:doc_processor_app/config/app_config.dart';
import 'package:doc_processor_app/services/api_service.dart';
import 'package:shared_preferences.dart';
import 'package:http/http.dart' as http;

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _selectedFile;
  bool _isUploading = false;
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _initializeApiService();
  }

  Future<void> _initializeApiService() async {
    final prefs = await SharedPreferences.getInstance();
    _apiService = ApiService(prefs, http.Client());
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: AppConfig.allowedFileTypes,
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Future<void> _uploadAndProcessFile() async {
    if (_selectedFile == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // Upload file
      final filepath = await _apiService.uploadFile(_selectedFile!);
      
      // Process document
      final result = await _apiService.processDocument(filepath);
      
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/results',
          arguments: result,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Document')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_selectedFile != null)
              Column(
                children: [
                  const Icon(Icons.file_present, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    _selectedFile!.path.split('/').last,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_selectedFile!.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              )
            else
              const Icon(Icons.cloud_upload, size: 64),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isUploading ? null : _pickFile,
              child: Text(_selectedFile == null ? 'Select File' : 'Change File'),
            ),
            const SizedBox(height: 16),
            if (_selectedFile != null)
              ElevatedButton(
                onPressed: _isUploading ? null : _uploadAndProcessFile,
                child: _isUploading
                    ? const CircularProgressIndicator()
                    : const Text('Upload and Process'),
              ),
          ],
        ),
      ),
    );
  }
} 