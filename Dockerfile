FROM dart:stable

WORKDIR /app

COPY . .

RUN dart pub get

CMD ["dart", "bin/dart_discord_bot.dart"]