import 'dart:io';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DocumentProvider with ChangeNotifier {
  final ApiService _apiService;
  File? _selectedFile;
  String? _processingResult;
  bool _isProcessing = false;
  String? _error;

  DocumentProvider() : _apiService = ApiService();

  File? get selectedFile => _selectedFile;
  String? get processingResult => _processingResult;
  bool get isProcessing => _isProcessing;
  String? get error => _error;

  void setSelectedFile(File file) {
    _selectedFile = file;
    _error = null;
    notifyListeners();
  }

  Future<void> processDocument(String command) async {
    if (_selectedFile == null) {
      _error = 'No file selected';
      notifyListeners();
      return;
    }

    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.processDocument(_selectedFile!, command);
      _processingResult = result['response'];
      _error = null;
    } catch (e) {
      _error = e.toString();
      _processingResult = null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void clearResults() {
    _processingResult = null;
    _error = null;
    notifyListeners();
  }
} 