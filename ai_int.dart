import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'dart:io';


// Function to be called when user issues the appropriate command - mother function for all others in file
Future<String> getAiRecs(String tags) async {

    // Make sure API call returns something before executing rest of method
    try {
      final movies = await fetchMoviesFromTMDB(tags);
      print("Raw response body: $movies");
      // Good API call, no movies returned
      if(movies.isEmpty){
        print('No Movies Found Matching These Tags.');
        return 'No Movies Found Matching These Tags.';
      }
      // Pass the returned movies as an argument to the prompt generator
      final prompt = genPrompt(tags, movies);
      // Use the prompt as an argument to the callAIAPI method to get personalized recs
      final response = await callAIAPI(prompt);
      print(response);
      return response;
    } catch (e) {
      print('Error: , $e');
      return 'Error Occurred While Attempting to Generate Movie Reccomendations';
    }
}

// Generates the prompt given to the AI
String genPrompt(String tags, List<Map<String, dynamic>> movies) {

    // Create a map of each movie associated with the desciption provided by the TMDb API
    final movieList = movies.map((movie) {
      return '- Film: ${movie['title']}\n Synopsis: ${movie['overview']}\n';
    }).join('\n');

    // Create and return the prompt
    final prompt =  ''' 

      Acting as a movie-buff, create a personalized reccomendation for each movie listed below, using the
      supplied tags, also below. Acting friendly and knowledgable, rank the movies based on which you think
      is most similar to the provided tags, and the reasons why.

      Movies: $movieList

      Tags: $tags

    ''';

    return prompt;
}

// Sends the prompt to the AI, and returns the AI output
Future<String> callAIAPI(String prompt) async {

    // Load env variable for ai API key, set up request headers and URL for AI API
    final config = await File('config.txt').readAsLines();
    final apiKey = config.firstWhere((line) => line.startsWith('AI_API_KEY=')).split('=')[1];
    
    final baseUrl = 'https://api.openai.com/v1/chat/completions';

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    // Request body
    final body = jsonEncode({
    'model': 'gpt-4o-mini',  // Use the correct model name, e.g., 'gpt-4' or 'gpt-3.5-turbo'
    'messages': [
      {
        'role': 'system',
        'content': 'You are a movie expert. Provide personalized movie recommendations based on the given tags and movies.'
      },
      {
        'role': 'user',
        'content': prompt
      }
    ],
    'max_tokens': 1000,
    'temperature': 0.7,
    'n': 1,
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
      //final text = data['choices'][0]['text'].trim();
      return data;

    } else {
      
      // API call failure
      print('Error Calling AI API: ${response.statusCode} ${response.body}');
      return 'API call failed.';
    }
}

// Get a list of randomly chosen movies based on user-supplied tags
Future<List<Map<String, dynamic>>> fetchMoviesFromTMDB(String tags) async {
    
    // Load .env variables, use to create get http get request
    final config = await File('config.txt').readAsLines();
    final apiKey = config
        .firstWhere((line) => line.startsWith('TMDB_API_KEY='))
        .split('=')[1];
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
        print("No movie db response");
        return [];
      }

      // Ignore any movies without rating
      films = films.where((movie) => movie['vote_average'] != null).toList();

      // Sort movies in descending order by user rating
      films.sort((a, b) => (b['vote_average'] as num).compareTo(a['vote_average'] as num));

      // Get top 50% of movies
      int halfMovies = (films.length/2).ceil();
      List<Map<String, dynamic>> topFilms = films.take(halfMovies).toList();

      // Return 10 of them randomly
      topFilms.shuffle(Random());
      List<Map<String, dynamic>> result = topFilms.take(10).toList();

      return result;

    } else {
      
      print("Unable to fetch movies from TMDb");
      throw Exception('Unable to Fetch Movies from TMDb');
    
    }

}
