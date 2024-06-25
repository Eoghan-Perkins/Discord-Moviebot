import 'package:nyxx/nyxx.dart';
import 'dart:io';
import 'dart:async';

void main() async {
  
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

 

  bot.connect();
}

