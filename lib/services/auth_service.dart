import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class AuthService {
  static const String baseUrl = 'http://localhost:8000/api';

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(Duration(seconds: 10));

      if (response.body.isEmpty) {
        if (response.statusCode == 200) {
          return {'success': true, 'message': 'Login successful!'};
        } else {
          throw Exception('Server returned empty response!');
        }
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Login failed!');
      }
    } on http.ClientException {
      throw Exception(
        'Cannot connect to server! Please check if the server is running.',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> signup(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/Auth/signup'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
            }),
          )
          .timeout(Duration(seconds: 10));

      if (response.body.isEmpty) {
        if (response.statusCode == 201) {
          return {'success': true, 'message': 'Account created successfully!'};
        } else {
          throw Exception(
            'Server returned empty response! Status: ${response.statusCode}',
          );
        }
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return data;
      } else {
        throw Exception(
          data['message'] ?? 'Signup failed! Status: ${response.statusCode}',
        );
      }
    } on http.ClientException {
      throw Exception(
        'Cannot connect to server! Please check if the server is running.',
      );
    } catch (e) {
      rethrow;
    }
  }
}
