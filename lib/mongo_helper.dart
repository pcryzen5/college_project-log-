// mongo_helper.dart
import 'package:mongo_dart/mongo_dart.dart';

class MongoHelper {
  static const String _mongoUri =
      "mongodb://purkaitshubham5:sam@students-shard-00-00.x3rdy.mongodb.net:27017,students-shard-00-01.x3rdy.mongodb.net:27017,students-shard-00-02.x3rdy.mongodb.net:27017/mdbuser_test_db?ssl=true&replicaSet=atlas-123-shard-0&authSource=admin";
  static const String _collectionName = 'students';

  static Future<Map<String, dynamic>?> authenticate(String username, String password) async {
    final db = Db(_mongoUri);
    try {
      await db.open();
      final collection = db.collection(_collectionName);
      final user = await collection.findOne({
        'username': username,
        'password': password,
      });
      await db.close();
      return user;
    } catch (e) {
      await db.close();
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> fetchProfile(String username) async {
    final db = Db(_mongoUri);
    try {
      await db.open();
      final collection = db.collection(_collectionName);
      final profile = await collection.findOne({'username': username});
      await db.close();
      return profile;
    } catch (e) {
      await db.close();
      rethrow;
    }
  }
}
