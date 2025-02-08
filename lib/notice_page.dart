import 'dart:convert'; // For Base64 decoding
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:mongo_dart/mongo_dart.dart' as mongo;

class NoticePage extends StatefulWidget {
  const NoticePage({super.key});

  @override
  State<NoticePage> createState() => _NoticePageState();
}

class _NoticePageState extends State<NoticePage> {
  List<Map<String, dynamic>> notices = [];
  bool isLoading = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    fetchNotices();
  }

  Future<void> fetchNotices() async {
    try {
      final db = await mongo.Db.create(
        "mongodb+srv://purkaitshubham5:sam@students.x3rdy.mongodb.net/mdbuser_test_db?retryWrites=true&w=majority",
      );
      await db.open();

      // Access the 'notices' collection
      final collection = db.collection('notices');

      // Fetch all notices sorted by date (descending)
      final result = await collection
          .find(
        mongo.where.sortBy('date', descending: true),
      )
          .toList();

      // Update state with the results
      setState(() {
        notices = result.cast<Map<String, dynamic>>();
        isLoading = false;
      });

      await db.close();
    } catch (e) {
      setState(() {
        errorMessage = "An error occurred while fetching notices: $e";
        isLoading = false;
      });
    }
  }

  String formatDate(DateTime? dateTime) {
    if (dateTime == null) return "Date unavailable";
    return DateFormat('dd-MM-yyyy hh:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notices",
          style: TextStyle(color: Color(0xFF0C0569), fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        //centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : notices.isEmpty
          ? const Center(child: Text("No notices available"))
          : ListView.builder(
        itemCount: notices.length,
        itemBuilder: (context, index) {
          final notice = notices[index];

          // Retrieve data from notice
          final imageBase64 = notice['image'] ?? '';
          final caption = notice['title'] ?? 'No Title';
          final description =
              notice['description'] ?? 'No Description';
          final dateRaw = notice['date'];
          final date = dateRaw != null
              ? DateTime.parse(dateRaw).toLocal()
              : null;

          return Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Display the image if Base64 data is available
                  if (imageBase64.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(2, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          base64Decode(imageBase64),
                          width: 300,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                  // Show placeholder if no image data is available
                    Image.asset(
                      'assets/placeholder.png',
                      width: 300,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  const SizedBox(height: 10),

                  // Display the caption
                  Text(
                    caption,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

                  // Display the description
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 10),

                  // Display the date
                  Text(
                    "Date & Time: ${formatDate(date)}",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
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
