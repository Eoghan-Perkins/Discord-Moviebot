import 'package:nyxx/nyxx.dart';
import 'dart:io';
import '../dbcode.dart';


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

  // Initialize the database
  initDatabase();
  
  // Access the Discord API
  final bot = NyxxFactory.createNyxxWebsocket(token, GatewayIntents.allUnprivileged)
    ..registerPlugin(Logging())
    ..registerPlugin(CliIntegration())
    ..registerPlugin(IgnoreExceptions());

  print("Bot Running");
  
  // Print Hello message to channel upon bot arrival
  bot.eventsWs.onGuildCreate.listen((event) {
    for (var channel in event.guild.channels) {
      if (channel is ITextGuildChannel) {
        channel.sendMessage(MessageBuilder.content('Hello! Your movie guru has arrived! Respond with "!moviebot" to learn more.'));
        break; // Send only to the first text channel found
      }
    }
  });

  // RESPOND TO BOT MESSAGES
  
  bot.eventsWs.onMessageReceived.listen((event) async {
    final channelId = event.message.channel.id.toString();
    
    if (event.message.content.startsWith('!moviebot') ) {
      try {
        final greeting = await File('greeting.txt').readAsLines();
        
        event.message.channel.sendMessage(MessageBuilder.content(greeting.join('\n')));
      } catch(e) {
        event.message.channel.sendMessage(MessageBuilder.content('Greeting file failed to load'));
        print(e);
      }
    }
    
    if (event.message.content.startsWith('!addmovie')) {
        final args = event.message.content.split(' ');
        final title = args.sublist(1, args.length-1).join(' ');
        final userId = event.message.author.id.toString();

        print('Adding film to queue');
        addMovie(userId, channelId, title, 1);
        event.message.channel.sendMessage(MessageBuilder.content('Movie added to queue!'));
    }
    
    if (event.message.content.startsWith('!cq')) {
      final films = getFilms(channelId);
      final result = films.map((film) => '${film['film_title']} (Rank: ${film['rank']})').join('\n');
      
      print('Printing film queue');
      event.message.channel.sendMessage(MessageBuilder.content(result.isEmpty ? 'No Movies Found.' : result));
    }

    if (event.message.content.startsWith('!upvote')) {
      final args = event.message.content.split(' ');
      final film = args.sublist(1).join(' ');
      
      print('Upvoting $film');
      upvote(channelId, film);
      event.message.channel.sendMessage(MessageBuilder.content('$film upvoted'));
    }

  });
  
  bot.connect();
}