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
        channel.sendMessage(MessageBuilder.content('Your movie guru has arrived! Respond with "!moviebot" to learn more.'));
        break; // Send only to the first text channel found
      }
    }
  });

  // RESPOND TO BOT MESSAGES
  
  bot.eventsWs.onMessageReceived.listen((event) async {
    final channelId = event.message.channel.id.toString();
    final guildId = event.message.guild?.id.toString();
    final authorId = event.message.author.id.toString();
    
    if (event.message.content.startsWith('!moviebot') ) {
      try {
        final greeting = await File('greeting.txt').readAsLines();
        
        event.message.channel.sendMessage(MessageBuilder.content(greeting.join('\n')));
      } catch(e) {
        event.message.channel.sendMessage(MessageBuilder.content('Error - Greeting file failed to load!'));
        print(e);
      }
    }
    
    if (event.message.content.startsWith('!addmovie')) {
        final args = event.message.content.split(' ');
        final title = args.sublist(1).join(' ');
        final userId = event.message.author.id.toString();
        
        // Only add movie to queue if title is provided
        if (args.length < 2){
          print('Film failed to add - no title');
          event.message.channel.sendMessage(MessageBuilder.content('Movie not added to watch queue - No title provided!'));
        } else {
          print('Adding film to queue');
          addMovie(userId, channelId, title, 1);
          event.message.channel.sendMessage(MessageBuilder.content('Movie added to queue!'));
        }
        
    }
    
    if (event.message.content.startsWith('!cq')) {
      final films = getFilms(channelId);
      final result = films.map((film) => '${film['film_title']} - ${film['rank']} Votes').join('\n');
      
      print('Printing film queue');
      event.message.channel.sendMessage(MessageBuilder.content(result.isEmpty ? 'No Movies Found.' : result));
    }

    // Upvote Movie
    if (event.message.content.startsWith('!upvote')) {
      final args = event.message.content.split(' ');
      final film = args.sublist(1).join(' ');
      
      print('Upvoting $film');
      upvote(channelId, film);
      event.message.channel.sendMessage(MessageBuilder.content('$film upvoted'));
    }

    // Remove movie from database
    if (event.message.content.startsWith('!removie')){
      final args = event.message.content.split(' ');
      if(args.length < 2){
        print('Cannot remove from database - No title provided');
        event.message.channel.sendMessage(MessageBuilder.content('Cannot Remove Movie - No Title Provided'));
      } else {
        final title = args.sublist(1).join(' ');

        // FIX: Movie removal privedlges restricted to server admin
        // Troubleshoot below commented out code
        if (guildId != null){
          final guild = bot.guilds[guildId];
          final member = await guild?.fetchMember(Snowflake(authorId));

          //if(member != null && member.roles.any((role) => guild!.roles[role]?.permissions.administrator ?? false)) {
              print('Removing movie from queue');
              removeMovie(channelId, title);
              event.message.channel.sendMessage(MessageBuilder.content('$title has been removed from the queue'));
          /*} else {
            print('Removing movie failed');
            event.message.channel.sendMessage(MessageBuilder.content('Admin status required to remove films from queue'));
          */}
        }
      }

      if(event.message.content.startsWith('!report')){
        final args = event.message.content.split(' ');
        
        if(args.length > 1 && args.length < 50){
          final text = args.sublist(1).join(' ');
          print('Report Recieved');
          report(text, authorId);
          event.message.channel.sendMessage(MessageBuilder.content('Thanks for your feedback!'));
        } else {
          print('Report submission failed. Please ensure your report is 50 words or less');
          event.message.channel.sendMessage(MessageBuilder.content('Please include text regarding the problem'));
        }
      }
    }

  );
  
  bot.connect();
}