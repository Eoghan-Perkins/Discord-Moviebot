import 'package:nyxx/nyxx.dart';
import 'dart:io';
import 'dart:async';
import 'package:sqlite3/sqlite3.dart';


void main() async {
  
  // INITIALIZE BOT AND CONNECT TO DISCORD API

  // Retrive bot's Discord API token
  String token;
  try {
    final config = await File('cfigtoken.txt').readAsLines();
    token = config
        .firstWhere((line) => line.startsWith('BOT_TOKEN='))
        .split('=')[1];
  } catch(e) {
    print('Error reading API token config file: $e');
    return;
  }
  
  // Access the Discord API
  final bot = NyxxFactory.createNyxxWebsocket(token, GatewayIntents.allUnprivileged)
    ..registerPlugin(Logging())
    ..registerPlugin(CliIntegration())
    ..registerPlugin(IgnoreExceptions());

  print("Bot Running");
  
  // 
  bot.eventsWs.onGuildCreate.listen((event) {
    for (var channel in event.guild.channels) {
      if (channel is ITextGuildChannel) {
        channel.sendMessage(MessageBuilder.content('Hello! Your movie guru has arrived!'));
        break; // Send only to the first text channel found
      }
    }
  });

  bot.eventsWs.onMessageReceived.listen((event) {
    if (event.message.content.contains('!moviebot') ) {
      event.message.channel.sendMessage(MessageBuilder.content('Hello! I am Discord bot written using Dart programming, how can I help you?'));
      print("Responding to hello");
    }
  });

  // INITIALIZE DATABASE FOR MOVIES AND CREATE COMMANDS

  void init_database() {
    final db = sqlite3.open('movie_list.db');

    db.execute (''' 
      CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id TEXT NOT NULL);    
    ''');

    db.execute ('''
    CREATE TABLE IF NOT EXISTS movies (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id TEXT NOT NULL,
      movie_name TEXT NOT NULL,
      priority INTEGER NOT NULL);
  ''');
  }

 

  bot.connect();
}

