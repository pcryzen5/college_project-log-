import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

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
      // Connect to the database
      db = await mongo.Db.create(dbUrl);
      await db!.open();
      announcementCollection = db!.collection('announcements');
      studentsCollection = db!.collection('students');

      db = await mongo.Db.create(dbUrl);
      await db!.open();

      final attendanceCollection = db!.collection('students');

      // Step 1: Retrive the class name for the given username
      //
      final studentDoc =
          await attendanceCollection.findOne({'username': widget.username});
      //debugPrint("Student document fetched: $studentDoc");

      if (studentDoc == null || studentDoc['class_name'] == null) {
        throw Exception(
            "Class not found for the provided username: ${widget.username}");
      }

      studentClass = studentDoc['class_name'];
      //debugPrint("Student class retrieved: $studentClass");

      // Step 2: Fetch announcements for the retrieved class
      final announcementDocs =
          await announcementCollection!.find({'class': studentClass}).toList();
      //debugPrint("Announcements fetched: $announcementDocs");

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

  @override
  void initState() {
    super.initState();
    fetchAnnouncements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Announcements")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : announcements.isEmpty
              ? const Center(child: Text("No announcements available."))
              : ListView.builder(
                  itemCount: announcements.length,
                  itemBuilder: (context, index) {
                    final announcement = announcements[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Text(announcement['title']),
                        subtitle: Text(announcement['description']),
                        trailing: Text(
                          "${DateTime.parse(announcement['createdAt']).toLocal()}",
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
