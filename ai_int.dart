import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:dotenv/dotenv.dart' as dotenv;

Future<String> getAiRecs(String tags) async {

    // Make sure API call returns something before executing rest of method
    try {
      final movies = await fetchMoviesFromTMDB(tags);
      if(movies.isEmpty){
        return 'No Movies Found Matching These Tags.'
      }
      
      final prompt = genPrompt(tags, movies);
      final response = await callAIAPI(prompt);
      return response;
    } catch (e) {
      print('Error: , $e');
      return 'Error Occurred While Attempting to Generate Movie Reccomendations';
    }
}

String genPrompt(String tags, List<Map<String, dynamic>> movies) {

    final result = '';
    return result;
}

Future<String> callAIAPI(String prompt) async {

    // Load env variable for ai API key, set up request headers and URL for AI API
    var env = dotenv.DotEnv(includePlatformEnvironment: true)..load();
    final apiKey = env['AI_API_KEY'];
    final baseUrl = 'https://api.openai.com/v1/completions';

    final headers = {
      'Content-Type': 'application/json',
      'Authroization': 'Bearer $apiKey',
    };

    // Request body
    final body = jsonEncode( {
      'model': 'text-davinci-003',
      'prompt': prompt,
      'max_tokens': 250,
      'temperature': 0.7,
      'n': 1,
      'stop': null,
    });

    // POST request
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: headers,
      body: body,
    );

    // If good response
    if (response.statusCode == 200) {
      // Pull answer from JSON response data
      final data = jsonDecode(response.body);
      // Get the text generated via the response and return it
      final text = data['choices'][0]['text'].trim();
      return text;

    } else {
      
      // API call failure
      print('Error Calling AI API: ${response.statusCode} ${response.body}');
      return 'API call failed.';
    }
}


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
