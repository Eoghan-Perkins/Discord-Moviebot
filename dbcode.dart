import 'package:sqlite3/sqlite3.dart';

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

  db.execute('''
    INSERT INTO movies (user_id, channel_id, film_title, rank)
    VALUES (?, ?, ?, ?)
    ''', [userID, channelId, title, rank]);

  
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

void upvote(String channelId, String title) {
  final db =sqlite3.open('movies.db');

  db.execute('''
    UPDATE movies
    SET rank = rank + 1
    WHERE channel_id = ? AND film_title = ?
  ''', [channelId, title]);

  db.dispose();
}

void removeMovie(String channelId, String title){
  final db = sqlite3.open('movies.db');

  db.execute('''
    DELETE FROM movies
    WHERE channel_id = ? AND film_title = ?
  ''', [channelId, title]);

  db.dispose();

}