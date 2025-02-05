import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

// Global variable to store total lectures
int globalTotalLectures = 0;

class AttendancePage extends StatefulWidget {
  final String userName; // Receive user_name from the Welcome Page

  const AttendancePage({super.key, required this.userName});

  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final String studentDbUrl =
      "mongodb://purkaitshubham5:sam@students-shard-00-00.x3rdy.mongodb.net:27017,students-shard-00-01.x3rdy.mongodb.net:27017,students-shard-00-02.x3rdy.mongodb.net:27017/mdbuser_test_db?ssl=true&replicaSet=atlas-123-shard-0&authSource=admin"; // MongoDB URL for the student database
  final String attendanceDbUrl =
      "mongodb://purkaitshubham5:sam@students-shard-00-00.x3rdy.mongodb.net:27017,students-shard-00-01.x3rdy.mongodb.net:27017,students-shard-00-02.x3rdy.mongodb.net:27017/attendance?ssl=true&replicaSet=atlas-123-shard-0&authSource=admin"; // MongoDB URL for the attendance database

  mongo.Db? studentDb;
  mongo.Db? attendanceDb;
  Map<String, dynamic> attendanceData = {};
  String userId = ""; // Will be populated with user_id dynamically
  String? selectedMonth; // For month selection
  bool isLoading = false; // Flag for loading state
  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  @override
  void initState() {
    super.initState();
    selectedMonth = months[0]; // Default month set to January
    fetchUserIdAndAttendance(); // Function to fetch both user_id and attendance
  }

  Future<void> fetchUserIdAndAttendance() async {
    setState(() {
      isLoading = true; // Show loading spinner while fetching data
    });

    try {
      studentDb = await mongo.Db.create(studentDbUrl);
      await studentDb!.open();
      final studentCollection = studentDb!.collection('students');

      var n =
          await studentCollection.find({"username": widget.userName}).toList();

      if (n.isNotEmpty) {
        var student = n[0];
        if (student['user_id'] != null) {
          setState(() {
            userId = student['user_id'];
          });
          fetchAttendance();
        } else {
          setState(() {
            userId = '';
          });
        }
      } else {
        setState(() {
          userId = '';
        });
      }
    } catch (e) {
      debugPrint("Error fetching student data: $e");
    } finally {
      studentDb?.close();
    }
  }

  Future<void> fetchAttendance() async {
    if (userId.isEmpty || selectedMonth == null) return;

    try {
      attendanceDb = await mongo.Db.create(attendanceDbUrl);
      await attendanceDb!.open();

      final currentYear = DateTime.now().year;
      final monthIndex = months.indexOf(selectedMonth!);
      final collectionName = "attendance${monthIndex + 1}_$currentYear";
      final attendanceCollection = attendanceDb!.collection(collectionName);

      final attendanceRecord =
          await attendanceCollection.findOne({"user_id": userId});

      if (attendanceRecord != null && attendanceRecord["attendance"] != null) {
        setState(() {
          attendanceData =
              Map<String, dynamic>.from(attendanceRecord["attendance"]);
        });
        calculateTotalLectures(); // Calculate total lectures and print
      } else {
        setState(() {
          attendanceData = {};
        });
      }
    } catch (e) {
      debugPrint("Error fetching attendance: $e");
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Error"),
          content:
              Text("Failed to load attendance data. Please try again later."),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
      attendanceDb?.close();
    }
  }

  void calculateTotalLectures() {
    var globalTotalLectures = 0;
    var totalAttendedLectures = 0;

    // Iterate through all subjects in attendanceData
    attendanceData.forEach((subject, lectures) {
      if (lectures is Map<String, dynamic>) {
        globalTotalLectures += lectures.length;

        // Count the number of attended lectures
        totalAttendedLectures +=
            lectures.values.where((attended) => attended == true).length;
      }
    });

    // Print the results to the terminal
    //debugPrint("Total number of lectures conducted till date for all subjects: $globalTotalLectures");
    //debugPrint("Total number of lectures attended till date for all subjects: $totalAttendedLectures");
  }

  double calculatePercentage(Map<String, bool> subjectAttendance) {
    if (subjectAttendance.isEmpty) {
      return 0.0; // No lectures conducted
    }
    int attended =
        subjectAttendance.values.where((attended) => attended).length;
    int total = subjectAttendance.length;

    return (attended / total) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Attendance Overview"),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month selection
            Text(
              "Select Month for Attendance",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            DropdownButton<String>(
              value: selectedMonth,
              onChanged: (String? newValue) {
                setState(() {
                  selectedMonth = newValue;
                });
                fetchAttendance(); // Fetch attendance data for the selected month
              },
              items: months.map((String month) {
                return DropdownMenuItem<String>(
                  value: month,
                  child: Text(month),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            // Show loading spinner while data is being fetched
            if (isLoading) Center(child: CircularProgressIndicator()),
            // Display attendance or message if no data
            if (!isLoading && attendanceData.isEmpty)
              Text(
                  "No attendance data for $selectedMonth. Please try another month."),
            if (!isLoading && attendanceData.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: attendanceData.keys.length,
                  itemBuilder: (context, index) {
                    String subject = attendanceData.keys.elementAt(index);
                    Map<String, bool> subjectAttendance =
                        Map<String, bool>.from(attendanceData[subject]);

                    // Calculate percentage
                    double percentage = calculatePercentage(subjectAttendance);

                    return Card(
                      child: ListTile(
                        title: Text(subject),
                        subtitle: Text(
                            'Attendance: ${percentage.toStringAsFixed(2)}%'),
                        trailing: Text(
                          '${subjectAttendance.values.where((attended) => attended).length}/${subjectAttendance.length}',
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
