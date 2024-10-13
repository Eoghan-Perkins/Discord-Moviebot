import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:dotenv/dotenv.dart' as dotenv;

Future<List<Map<String, dynamic>>> fetchMoviesFromTMDB(String tags) async {
    
    // Load .env variables, use to create get http get request
    var env = dotenv.DotEnv(includePlatformEnvironment: true)..load();
    final apiKey = env['TMDB_API_KEY'];
    final baseURL = 'https://api.themoviedb.org/3';
    final query = Uri.encodeQueryComponent(tags);
    final url = '$baseURL/search/movie?api_key=$apiKey&query=$query&language=en-US&page=1&include_adult=false';

    final response = await http.get(Uri.parse(url));

    // If good response
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<Map<String, dynamic>> films = List<Map<String, dynamic>>.from(data['results']);

      // Check for empty response
      if (films.isEmpty) {
        return [];
      }

      // Ignore any movies without rating
      films = films.where((movie) => movie['vote average'] != null).toList();

      // Sort movies in descending order by user rating
      films.sort((a, b) => (b['vote average'] as num).compareTo(a['vote average'] as num));

      // Get top 50% of movies
      int halfMovies = (films.length/2).ceil();
      List<Map<String, dynamic>> topFilms = films.take(halfMovies).toList();

      // Return 10 of them randomly
      topFilms.shuffle(Random());
      List<Map<String, dynamic>> result = topFilms.take(10).toList();

      return result;

    } else {

      throw Exception('Unable to Fetch Movies from TMDb');
    
    }

}
