import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

class SchedulePage extends StatefulWidget {
  final String username;

  const SchedulePage({super.key, required this.username});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  List<Map<String, dynamic>> schedules = [];
  bool isLoading = true;
  String errorMessage = "";
  String? studentClass;

  @override
  void initState() {
    super.initState();
    fetchSchedules();
  }

  Future<void> fetchSchedules() async {
    mongo.Db? db;
    try {
      print("Connecting to MongoDB...");
      db = await mongo.Db.create(
          "mongodb+srv://purkaitshubham5:sam@students.x3rdy.mongodb.net/mdbuser_test_db?retryWrites=true&w=majority");
      await db.open();
      print("Connected to MongoDB!");

      // Get student class
      final studentCollection = db.collection('students');
      final studentData = await studentCollection.findOne(
        mongo.where.eq('username', widget.username),
      );

      if (studentData == null) {
        setState(() {
          errorMessage = 'Student not found';
          isLoading = false;
        });
        await db.close();
        return;
      }

      studentClass = studentData['class_name'];

      if (studentClass == null) {
        setState(() {
          errorMessage = 'Class not found for the student';
          isLoading = false;
        });
        await db.close();
        return;
      }

      // Fetch schedules sorted by latest date first
      final scheduleCollection = db.collection('schedules');
      final result = await scheduleCollection
          .find(
        mongo.where.eq('classes', studentClass).sortBy('dateTime', descending: true),
      )
          .toList();

      // Format date fields
      final formattedResult = result.map((schedule) {
        final rawDate = schedule['dateTime'];
        if (rawDate is mongo.Timestamp) {
          schedule['dateTime'] =
              DateTime.fromMillisecondsSinceEpoch(rawDate.seconds * 1000);
        } else if (rawDate is String) {
          schedule['dateTime'] = DateTime.tryParse(rawDate);
        }
        return schedule;
      }).toList();

      setState(() {
        schedules = formattedResult.cast<Map<String, dynamic>>();
        isLoading = false;
      });
    } catch (e) {
      print("Error occurred: $e");
      setState(() {
        errorMessage = 'An error occurred while fetching schedules: $e';
        isLoading = false;
      });
    } finally {
      if (db != null && db.isConnected) {
        await db.close();
        print("Database connection closed.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Schedule Page",
          style: TextStyle(color: Color(0xFF0C0569), fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : schedules.isEmpty
          ? const Center(child: Text("No schedules available"))
          : ListView.builder(
        itemCount: schedules.length,
        itemBuilder: (context, index) {
          final schedule = schedules[index];

          final title = schedule['title'] ?? 'No Title';
          final professor = schedule['professor'] ?? 'Unknown Professor';
          final rawDate = schedule['dateTime'];
          DateTime? date;

          if (rawDate is DateTime) {
            date = rawDate.toLocal();
          } else if (rawDate is String) {
            date = DateTime.tryParse(rawDate)?.toLocal();
          }

          final time = date != null ? date.toString().substring(11, 16) : 'No Time';
          final formattedDate = date != null
              ? '${date.day}-${date.month}-${date.year}'
              : 'No Date';

          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Professor: $professor"),
                  Text("Time: $time"),
                  Text(
                    "Date: $formattedDate",
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
