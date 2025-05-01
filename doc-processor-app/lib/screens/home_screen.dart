import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../providers/auth_provider.dart';
import '../providers/document_provider.dart';
import 'login_screen.dart';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PlatformFile? _selectedFile;
  String? _fileName;
  bool _isLoading = false;
  String? _error;
  String? _result;
  String? _token;
  final TextEditingController _commandController = TextEditingController();
  final List<String> _suggestedCommands = [
    'summarize',
    'extract main points',
    'analyze',
    'find key topics',
    'generate notes',
  ];

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  @override
  void dispose() {
    _commandController.dispose();
    super.dispose();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token');
    });
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
          _fileName = result.files.first.name;
          _error = null;
          _result = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error picking file: $e';
      });
    }
  }

  Future<void> _processFile() async {
    if (_selectedFile == null) {
      setState(() {
        _error = 'Please select a file first';
      });
      return;
    }

    if (_commandController.text.isEmpty) {
      setState(() {
        _error = 'Please enter a command';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      var uri = Uri.parse('http://localhost:8080/api/process');
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $_token';
      
      // Add the command to the request
      request.fields['command'] = _commandController.text;

      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            _selectedFile!.bytes!,
            filename: _selectedFile!.name,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            _selectedFile!.path!,
          ),
        );
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseBody);
        setState(() {
          _result = jsonResponse['response'] as String;
        });
      } else {
        setState(() {
          _error = 'Error: ${response.statusCode} - $responseBody';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error processing file: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, DocumentProvider>(
      builder: (context, authProvider, docProvider, _) {
        if (!authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Document Processor'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _logout,
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.upload_file,
                  size: 100,
                  color: Colors.blue,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.file_upload),
                  label: const Text('Select File'),
                ),
                const SizedBox(height: 16),
                if (_fileName != null) ...[
                  Text(
                    'Selected file: $_fileName',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _commandController,
                  decoration: const InputDecoration(
                    labelText: 'Enter Command',
                    hintText: 'e.g., summarize, extract main points',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _suggestedCommands.map((cmd) {
                    return ActionChip(
                      label: Text(cmd),
                      onPressed: () {
                        _commandController.text = cmd;
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _processFile,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_fix_high),
                  label: Text(_isLoading ? 'Processing...' : 'Process File'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                if (_result != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Result:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: Text(_result!),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
} 