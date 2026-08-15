import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const ProfessionMatcherApp());
}

class ProfessionMatcherApp extends StatelessWidget {
  const ProfessionMatcherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Profession Matcher',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const ProfessionMatcherHomePage(),
    );
  }
}

class ProfessionMatcherHomePage extends StatefulWidget {
  const ProfessionMatcherHomePage({super.key});

  @override
  State<ProfessionMatcherHomePage> createState() =>
      _ProfessionMatcherHomePageState();
}

class _ProfessionMatcherHomePageState extends State<ProfessionMatcherHomePage> {
  final TextEditingController _searchController = TextEditingController();
  final List<ProfessionDto> _results = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _serverStatus = 'Checking server...';

  // Public ngrok tunnel pointing at the local Kotlin server
  final String _baseUrl = 'https://abide-banana-suing.ngrok-free.dev';

  @override
  void initState() {
    super.initState();
    _checkServer();
  }

  Future<void> _checkServer() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          _serverStatus = '✅ Server is running';
        });
      } else {
        setState(() {
          _serverStatus = '⚠️ Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _serverStatus = '❌ Cannot connect to server. Make sure Kotlin server is running on port 8080';
      });
    }
  }

  Future<void> _searchProfession() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a profession';
        _results.clear();
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _results.clear();
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/profession/search'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({'keyword': query}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _results.addAll(data.map((json) => ProfessionDto.fromJson(json)));
          _isLoading = false;
          if (_results.isEmpty) {
            _errorMessage = 'No matching profession found';
          }
        });
      } else {
        setState(() {
          _errorMessage = 'Error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profession Matcher'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _serverStatus.contains('✅') ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _serverStatus.contains('❌') ? 'Offline' : 'Online',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Server Status
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _serverStatus.contains('✅')
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _serverStatus.contains('✅')
                      ? Colors.green.shade300
                      : Colors.red.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _serverStatus.contains('✅') ? Icons.check_circle : Icons.error,
                    color: _serverStatus.contains('✅') ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _serverStatus,
                      style: TextStyle(
                        fontSize: 12,
                        color: _serverStatus.contains('✅') ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 16),
                    onPressed: _checkServer,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Search Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Enter profession in Arabic...',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.search),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onSubmitted: (_) => _searchProfession(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isLoading || !_serverStatus.contains('✅')
                              ? null
                              : _searchProfession,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text('Search'),
                        ),
                      ],
                    ),
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Results Section
            Expanded(
              child: _results.isEmpty && !_isLoading
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.work_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage.isNotEmpty && _errorMessage.contains('No matching')
                          ? _errorMessage
                          : 'Search for a profession to match',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final profession = _results[index];
                  return ProfessionCard(profession: profession);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfessionCard extends StatelessWidget {
  final ProfessionDto profession;

  const ProfessionCard({super.key, required this.profession});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(
            profession.enumName.substring(0, 1),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profession.nameAr,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              profession.nameEn,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        subtitle: Text(
          profession.enumName,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Arabic Name', profession.nameAr),
                _buildDetailRow('English Name', profession.nameEn),
                _buildDetailRow('Status', profession.professionStatus ?? 'N/A'),
                _buildDetailRow('Code', profession.professionCode ?? 'N/A'),
                if (profession.keyWords != null) ...[
                  const Divider(),
                  const Text(
                    'Keywords:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: profession.keyWords!
                        .split(',')
                        .where((kw) => kw.trim().isNotEmpty)
                        .map((kw) => Chip(
                      label: Text(kw.trim()),
                      backgroundColor: Colors.blue.shade50,
                      labelStyle: const TextStyle(fontSize: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                      ),
                    ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DATA MODELS
// ============================================================

class ProfessionDto {
  final int? id;
  final String enumName;
  final String nameAr;
  final String nameEn;
  final String? professionStatus;
  final String? professionCode;
  final String? jobTitleCode;
  final String? activity;
  final String? riskType;
  final String? educationLevel;
  final String? educationStatus;
  final String? employment;
  final String? currentEmployer;
  final String? keyWords;
  final String? ineligibleProfession;
  final String? ineligibleJobTitle;
  final String? ineligibleEducation;

  ProfessionDto({
    this.id,
    required this.enumName,
    required this.nameAr,
    required this.nameEn,
    this.professionStatus,
    this.professionCode,
    this.jobTitleCode,
    this.activity,
    this.riskType,
    this.educationLevel,
    this.educationStatus,
    this.employment,
    this.currentEmployer,
    this.keyWords,
    this.ineligibleProfession,
    this.ineligibleJobTitle,
    this.ineligibleEducation,
  });

  factory ProfessionDto.fromJson(Map<String, dynamic> json) {
    return ProfessionDto(
      id: json['id'] as int?,
      enumName: json['enumName'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      professionStatus: json['professionStatus'] as String?,
      professionCode: json['professionCode'] as String?,
      jobTitleCode: json['jobTitleCode'] as String?,
      activity: json['activity'] as String?,
      riskType: json['riskType'] as String?,
      educationLevel: json['educationLevel'] as String?,
      educationStatus: json['educationStatus'] as String?,
      employment: json['employment'] as String?,
      currentEmployer: json['currentEmployer'] as String?,
      keyWords: json['keyWords'] as String?,
      ineligibleProfession: json['ineligibleProfession'] as String?,
      ineligibleJobTitle: json['ineligibleJobTitle'] as String?,
      ineligibleEducation: json['ineligibleEducation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'enumName': enumName,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'professionStatus': professionStatus,
      'professionCode': professionCode,
      'jobTitleCode': jobTitleCode,
      'activity': activity,
      'riskType': riskType,
      'educationLevel': educationLevel,
      'educationStatus': educationStatus,
      'employment': employment,
      'currentEmployer': currentEmployer,
      'keyWords': keyWords,
      'ineligibleProfession': ineligibleProfession,
      'ineligibleJobTitle': ineligibleJobTitle,
      'ineligibleEducation': ineligibleEducation,
    };
  }
}