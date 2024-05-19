import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class FavoriteScreen extends StatefulWidget {
  @override
  _FavoriteScreenState createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  DBHelper _dbHelper = DBHelper();
  List<String> favoriteSongs = [];

  @override
  void initState() {
    super.initState();
    fetchFavoriteSongs();
  }

  void fetchFavoriteSongs() async {
    List<String> favorites = await _dbHelper.getAllFavorites();
    setState(() {
      favoriteSongs = favorites;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Favorites")),
      body: favoriteSongs.isEmpty
          ? Center(
        child: Text("No favorites added yet"),
      )
          : ListView.builder(
        itemCount: favoriteSongs.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(favoriteSongs[index]),
            // You can add onTap functionality to play the song or perform any action
          );
        },
      ),
    );
  }
}

class DBHelper {
  static Database? _database;
  static const String TABLE_NAME = 'favorites';
  static const String COLUMN_ID = 'id';
  static const String COLUMN_TITLE = 'title';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB();
    return _database!;
  }

  Future<Database> initDB() async {
    var databasesPath = await getDatabasesPath();
    String path = databasesPath + 'favorites.db';
    return await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
           CREATE TABLE $TABLE_NAME (
             $COLUMN_ID INTEGER PRIMARY KEY,
             $COLUMN_TITLE TEXT
           )
         ''');
    });
  }

  Future<void> addToFavorites(String title) async {
    final db = await database;
    await db.insert(TABLE_NAME, {COLUMN_TITLE: title});
  }

  Future<void> removeFromFavorites(String title) async {
    final db = await database;
    await db.delete(TABLE_NAME, where: '$COLUMN_TITLE = ?', whereArgs: [title]);
  }

  Future<bool> isFavorite(String title) async {
    final db = await database;
    var result = await db.query(TABLE_NAME, where: '$COLUMN_TITLE = ?', whereArgs: [title]);
    return result.isNotEmpty;
  }

  Future<List<String>> getAllFavorites() async {
    final db = await database;
    var result = await db.query(TABLE_NAME);
    return result.map((e) => e[COLUMN_TITLE] as String).toList();
  }
}
