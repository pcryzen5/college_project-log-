import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:intl/intl.dart'; // Import for formatting date and time

class AnnouncementsPage extends StatefulWidget {
  final String username;

  const AnnouncementsPage({super.key, required this.username});

  @override
  _AnnouncementsPageState createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  final String dbUrl =
      "mongodb://purkaitshubham5:sam@students-shard-00-00.x3rdy.mongodb.net:27017,students-shard-00-01.x3rdy.mongodb.net:27017,students-shard-00-02.x3rdy.mongodb.net:27017/mdbuser_test_db?ssl=true&replicaSet=atlas-123-shard-0&authSource=admin";

  mongo.Db? db;
  mongo.DbCollection? announcementCollection;
  mongo.DbCollection? studentsCollection;

  List<Map<String, dynamic>> announcements = [];
  String? studentClass;
  bool isLoading = false;

  Future<void> fetchAnnouncements() async {
    setState(() {
      isLoading = true;
    });

    try {
      db = await mongo.Db.create(dbUrl);
      await db!.open();
      announcementCollection = db!.collection('announcements');
      studentsCollection = db!.collection('students');

      final studentDoc =
      await studentsCollection!.findOne({'username': widget.username});

      if (studentDoc == null || studentDoc['class_name'] == null) {
        throw Exception("Class not found for username: ${widget.username}");
      }

      studentClass = studentDoc['class_name'];

      final announcementDocs = await announcementCollection!
          .modernFind(
        filter: {'class': studentClass},
        sort: {'createdAt': -1}, // Sorting by latest date first
      )
          .toList();

      setState(() {
        announcements = List<Map<String, dynamic>>.from(announcementDocs);
      });
    } catch (e) {
      debugPrint("Error fetching announcements: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
      db?.close();
    }
  }

  String formatDateTime(String createdAt) {
    try {
      DateTime dateTime = DateTime.parse(createdAt).toLocal();
      String time = DateFormat('HH:mm').format(dateTime); // 24-hour time format
      String date = DateFormat('d-M-yyyy').format(dateTime); // Date format d-M-yyyy
      return "Time: $time\nDate: $date";
    } catch (e) {
      return "Invalid Date";
    }
  }

  @override
  void initState() {
    super.initState();
    fetchAnnouncements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Announcements",
        style: TextStyle(color: Color(0xFF0C0569), fontWeight: FontWeight.bold),
      ),
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : announcements.isEmpty
          ? const Center(child: Text("No announcements available."))
          : ListView.builder(
        itemCount: announcements.length,
        itemBuilder: (context, index) {
          final announcement = announcements[index];

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              title: Text(announcement['title']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(announcement['description']),
                  const SizedBox(height: 4),
                  Text(
                    formatDateTime(announcement['createdAt']),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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
