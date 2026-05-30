import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class SubjectService {
  static const String baseUrl = 'http://localhost:8000/api';

  Future<List<Map<String, dynamic>>> getSubjects() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/subject'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      } else {
        throw Exception('Failed to load subjects!');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTopicsBySubject(int subjectId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/subject/$subjectId/topics'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      } else {
        throw Exception('Failed to load topics!');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getNotes(
    int subjectId,
    String topicName,
  ) async {
    try {
      final encodedTopic = Uri.encodeComponent(topicName);
      final response = await http
          .get(
            Uri.parse('$baseUrl/Notes/$subjectId/$encodedTopic'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        return [];
      } else {
        throw Exception('Failed to load notes!');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> generateQuiz(Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/Quiz/generate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(Duration(seconds: 180));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to generate quiz!');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> submitQuiz(Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/Quiz/submit'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to submit quiz!');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getExplanation(Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/Explain'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(Duration(seconds: 180));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to get explanation!');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getQuizHistory(int userId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/Quiz/history/$userId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      } else {
        throw Exception('Failed to load quiz history!');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Admin API methods
  Future<List<Map<String, dynamic>>> getAdminSubjects() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/admin/subjects'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      } else {
        throw Exception('Failed to load subjects!');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addSubject(String name) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/admin/subjects?name=$name'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to add subject!');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteSubject(int subjectId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/admin/subjects/$subjectId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Failed to delete subject!');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAdminTopics(int subjectId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/admin/subjects/$subjectId/topics'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      } else {
        throw Exception('Failed to load topics!');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addTopic(int subjectId, String topicName) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/admin/topics?subject_id=$subjectId&topic_name=$topicName'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to add topic!');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTopic(int topicId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/admin/topics/$topicId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Failed to delete topic!');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/admin/stats'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load stats!');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPoolQuestions(String topicName, {int? subjectId}) async {
    try {
      final encoded = Uri.encodeComponent(topicName);
      var uri = Uri.parse('$baseUrl/admin/questions/$encoded');
      if (subjectId != null) {
        uri = uri.replace(queryParameters: {'subject_id': subjectId.toString()});
      }
      final response = await http
          .get(
            uri,
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      } else {
        throw Exception('Failed to load questions!');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteQuestion(int questionId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/admin/questions/$questionId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Failed to delete question!');
      }
    } catch (e) {
      throw Exception('Delete error: $e');
    }
  }

  Future<Map<String, dynamic>> uploadPdf(int subjectId, String filePath, String fileName, {bool generateQuestions = true}) async {
    try {
      var uri = Uri.parse('$baseUrl/admin/upload-pdf');
      uri = uri.replace(queryParameters: {
        'subject_id': subjectId.toString(),
        'generate_questions': generateQuestions.toString(),
      });
      
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      final response = await request.send().timeout(Duration(seconds: generateQuestions ? 300 : 60));
      
      final body = await response.stream.bytesToString();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(body);
      } else {
        throw Exception('Upload failed: $body');
      }
    } catch (e) {
      throw Exception('Upload error: $e');
    }
  }

  Future<Map<String, dynamic>> generateQuestionsForSubject(int subjectId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/admin/generate-questions/$subjectId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 300));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to generate questions!');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getKnowledgeChunks(int subjectId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/admin/knowledge-chunks/$subjectId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      } else {
        throw Exception('Failed to load knowledge chunks!');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> generateQuestions(String topicName, int subjectId, {int count = 20}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/admin/generate-questions/$topicName?subject_id=$subjectId&count=$count'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 300));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to generate questions!');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<int> getQuestionCount(String topicName) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/admin/question-count/$topicName'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['questionCount'] ?? 0;
      } else {
        return 0;
      }
    } catch (e) {
      return 0;
    }
  }

  Future<void> deleteKnowledgeChunk(int chunkId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/admin/knowledge-chunks/$chunkId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Failed to delete chunk!');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> generateAllQuestions(int subjectId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/admin/generate-all-questions/$subjectId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 300));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to generate questions!');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTopicsFromPdf(int subjectId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/admin/topics-from-pdf/$subjectId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<String> getKnowledgeContent(String topicName) async {
    try {
      final encoded = Uri.encodeComponent(topicName);
      final response = await http
          .get(
            Uri.parse('$baseUrl/admin/knowledge-content/$encoded'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'] ?? '';
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  Future<List<Map<String, dynamic>>> generateQuestionsForTopic(int subjectId, String topicName) async {
    try {
      final encoded = Uri.encodeComponent(topicName);
      final response = await http
          .post(
            Uri.parse('$baseUrl/admin/generate-topic-questions/$subjectId?topic_name=$encoded'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 300));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      } else {
        throw Exception('Failed to generate questions for topic!');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getQuestionsForTopic(int subjectId, String topicName) async {
    try {
      final encoded = Uri.encodeComponent(topicName);
      final response = await http
          .get(
            Uri.parse('$baseUrl/admin/topic-questions/$subjectId?topic_name=$encoded'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      } else {
        throw Exception('Failed to load questions for topic!');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> regenerateQuestionsForTopic(int subjectId, String topicName) async {
    try {
      final encoded = Uri.encodeComponent(topicName);
      final response = await http
          .post(
            Uri.parse('$baseUrl/admin/regenerate-topic-questions/$subjectId?topic_name=$encoded'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 300));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      } else {
        throw Exception('Failed to regenerate questions for topic!');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> getTopicContent(String topicName) async {
    return getKnowledgeContent(topicName);
  }

  Future<Map<String, dynamic>> getGenerationStatus(int subjectId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/admin/generation-status/$subjectId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      return {};
    }
  }
}
