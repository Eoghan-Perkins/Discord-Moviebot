import 'package:sqlite3/sqlite3.dart';
import 'dart:io';

void initDatabase() {
    final db = sqlite3.open('movies.db');

    db.execute (''' 
      CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id TEXT NOT NULL);    
    ''');

    db.execute ('''
    CREATE TABLE IF NOT EXISTS movies (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id TEXT NOT NULL,
      channel_id TEXT NOT NULL,
      film_title TEXT NOT NULL,
      rank INTEGER NOT NULL);
    '''); 

  db.dispose();

  }

void addMovie(String userID, String channelId, String title, int rank){
  final db = sqlite3.open("movies.db");
  final name = title.toLowerCase();

  db.execute('''
    INSERT INTO movies (user_id, channel_id, film_title, rank)
    VALUES (?, ?, ?, ?)
    ''', [userID, channelId, name, rank]);

  
  db.dispose();
}

List<Map <String, dynamic>> getFilms(String channelId) {
  final db = sqlite3.open('movies.db');

  final result = db.select('''
    SELECT film_title, rank
    FROM movies
    WHERE channel_id = ?
    ORDER BY rank DESC
  ''', [channelId]);

  final films = result.map((row) => {
    'film_title': row['film_title'],
    'rank': row['rank']
  }).toList();

  db.dispose();
  return films;
}

int upvote(String channelId, String title) {
  
  // Open db
  final db = sqlite3.open('movies.db');
  
  // Check if movie exists in queue already
  final ResultSet rs = db.select(
    'SELECT COUNT(*) as count FROM movies WHERE film_title = ?', [title]
  );

  final int count = rs.first['count'];

  // If movie not in queue, return false
  if(count == 0) {
    db.dispose();
    return 0;
  }

  // Otherwise, proceed with upvote
  db.execute('''
    UPDATE movies
    SET rank = rank + 1
    WHERE channel_id = ? AND film_title = ?
  ''', [channelId, title]);

  // Close db, return true
  db.dispose();
  return 1;
}

void removeMovie(String channelId, String title){
  final db = sqlite3.open('movies.db');

  db.execute('''
    DELETE FROM movies
    WHERE channel_id = ? AND film_title = ?
  ''', [channelId, title]);

  db.dispose();

}

void report(String reportText, String userID){
  final file = File('reports.txt');
  final ts = DateTime.now().toIso8601String();
  final entry = '[$ts] User: $userID\n$reportText\n\n';

  file.writeAsStringSync(entry, mode: FileMode.append);

}