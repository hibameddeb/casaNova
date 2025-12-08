import 'package:mongo_dart/mongo_dart.dart';

class MongoService {
  static Db? _db;

  static Future<Db> connect() async {
    if (_db == null) {
      var db = Db(
        'mongodb+srv://aleeaouini_db_user:TBnMK1kKSFTLOWTi@immobilier.m36u7fm.mongodb.net/immobilier',
      );
      await db.open();
      _db = db;
      print(' Connected to MongoDB!');
    }
    return _db!;
  }

  static DbCollection getCollection(String name) {
    if (_db == null) {
      throw Exception('Database not connected!');
    }
    return _db!.collection(name);
  }
}
