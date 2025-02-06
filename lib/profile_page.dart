import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert'; // For base64Decode
import 'mongo_helper.dart';

class ProfilePage extends StatefulWidget {
  final String username;

  const ProfilePage({super.key, required this.username});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  String? selectedSemester;
  String? selectedSubject;
  Map<String, Map<String, int>> semestersMarks = {};

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final profile = await MongoHelper.fetchProfile(widget.username);
      if (mounted) {
        setState(() {
          _profileData = profile;
          _isLoading = false;

          // Access and validate the 'semester' field
          final semestersData = profile?['semester'];
          if (semestersData is Map) {
            semestersMarks = semestersData.map((key, value) {
              if (value is Map<String, dynamic>) {
                return MapEntry(
                  key.toString(),
                  value.map((subKey, subValue) =>
                      MapEntry(subKey.toString(), int.tryParse(subValue.toString()) ?? 0)),
                );
              }
              return MapEntry(key.toString(), {});
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_profileData == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Profile not found!',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    List<String> semesters = semestersMarks.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Page',
            style: TextStyle(color: Color(0xFF0C0569), fontWeight: FontWeight.bold),
      ),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _profileData!['id_card_print'] != null
                        ? MemoryImage(base64Decode(_profileData!['id_card_print']))
                        : const AssetImage('assets/placeholder.png') as ImageProvider,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileItem('Name', _profileData!['full_name']),
                      _buildProfileItem('Username', _profileData!['username']),
                      _buildProfileItem('Email', _profileData!['email']),
                      _buildProfileItem('Class', _profileData!['class_name']),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Color(0xE60C0569),
                child: Text(
                  'Department: ${_profileData!['department'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Select Semester to View Marks:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                hint: const Text('Select Semester'),
                value: selectedSemester,
                isExpanded: true,
                items: semesters.isNotEmpty
                    ? semesters.map((semester) {
                  return DropdownMenuItem<String>(
                    value: semester,
                    child: Text(semester),
                  );
                }).toList()
                    : [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('No Semesters Available'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedSemester = value;
                    selectedSubject = null; // Reset subject when semester changes
                  });
                },
              ),
              const SizedBox(height: 16),
              if (selectedSemester != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Subject to View Marks:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      hint: const Text('Select Subject'),
                      value: selectedSubject,
                      isExpanded: true,
                      items: semestersMarks[selectedSemester]?.keys.isNotEmpty ?? false
                          ? semestersMarks[selectedSemester]!.keys.map((subject) {
                        return DropdownMenuItem<String>(
                          value: subject,
                          child: Text(subject),
                        );
                      }).toList()
                          : [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('No Subjects Available'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedSubject = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    if (selectedSubject != null)
                      Text(
                        'Marks: ${semestersMarks[selectedSemester]?[selectedSubject] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),

              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  final url = _profileData!['ebooksLink'];
                  if (url != null) {
                    _launchURL(url);
                  }
                },
                icon: const Icon(Icons.book),
                label: const Text('E-Books'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        '$label: ${value ?? 'N/A'}',
        style: const TextStyle(fontSize: 18),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the link')),
      );
    }
  }
}
