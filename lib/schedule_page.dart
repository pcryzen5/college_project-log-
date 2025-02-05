import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

class SchedulePage extends StatefulWidget {
  final String username; // Add a parameter for the student's username

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

      // Access the 'students' collection to get the student's class
      final studentCollection = db.collection('students');
      final studentData = await studentCollection.findOne(
        mongo.where.eq('username', widget.username), // Use the dynamic username
      );

      if (studentData == null) {
        setState(() {
          errorMessage = 'Student not found';
          isLoading = false;
        });
        await db.close();
        return;
      }

      // Get the class_name of the student
      studentClass = studentData['class_name'];
      //print("Student's class name: $studentClass");

      if (studentClass == null) {
        setState(() {
          errorMessage = 'Class not found for the student';
          isLoading = false;
        });
        await db.close();
        return;
      }

      // Access the 'schedules' collection to find matching schedules for the class
      final scheduleCollection = db.collection('schedules');
      //print("Querying schedules for class: $studentClass");

      // Query schedules for the matching class name
      final result = await scheduleCollection
          .find(
        mongo.where.eq('classes', studentClass), // Match the class name
      )
          .toList();

      //print("Query result: $result");

      // Parse and format the result
      final formattedResult = result.map((schedule) {
        // Parse the dateTime field
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
      // Ensure the database connection is closed
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
        title: const Text("Schedule Page"),
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

          // Safely extract and format fields
          final title = schedule['title'] ?? 'No Title';
          final professor =
              schedule['professor'] ?? 'Unknown Professor'; // Added professor
          final rawDate = schedule['dateTime'];
          DateTime? date;

          // Parse dateTime if it exists
          if (rawDate is DateTime) {
            date = rawDate.toLocal();
          } else if (rawDate is String) {
            date = DateTime.tryParse(rawDate)?.toLocal();
          }

          // Format date and time
          final time = date != null
              ? date.toString().substring(11, 16)
              : 'No Time';
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
                  Text("Professor: $professor"), // Display professor's name
                  Text("Time: $time"),
                  Text(
                    "Date: $formattedDate",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold),
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
