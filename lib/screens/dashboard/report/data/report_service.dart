import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ReportService {
  final Dio _dio;
  final String _baseUrl;

  ReportService({Dio? dio})
    : _dio = dio ?? Dio(),
      _baseUrl = dotenv.env['BASE_URL'] ?? '';

  Future<dynamic> fetchReports() async {
    if (_baseUrl.isEmpty) {
      throw Exception("BASE_URL not found in .env");
    }

    try {
      final response = await _dio.get('$_baseUrl/sna/dashboard');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception("Failed to load reports: ${response.statusCode}");
      }
    } on DioException catch (e) {
      throw Exception("Network Error: ${e.message}");
    } catch (e) {
      throw Exception("Unexpected Error: $e");
    }
  }
}
