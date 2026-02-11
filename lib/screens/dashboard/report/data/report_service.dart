import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../models/report_model.dart';

class ReportService {
  final Dio _dio;
  final String _baseUrl;

  ReportService({Dio? dio})
    : _dio = dio ?? Dio(),
      _baseUrl = dotenv.env['BASE_URL'] ?? '' {
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Future<DashboardData> fetchMainDashboard() async {
    try {
      final response = await _dio.get('$_baseUrl/report/dashboard');
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return DashboardData.fromJson(response.data['data']);
      }
      throw Exception("Gagal memuat dashboard");
    } catch (e) {
      throw Exception("Error Dashboard: $e");
    }
  }

  Future<AnalyticsData> fetchAnalytics() async {
    try {
      final response = await _dio.get('$_baseUrl/report/analytics');
      if (response.statusCode == 200) {
        return AnalyticsData.fromJson(response.data);
      }
      throw Exception("Gagal memuat analytics");
    } catch (e) {
      throw Exception("Error Analytics: $e");
    }
  }

  Future<String> exportToSheets() async {
    try {
      final response = await _dio.post('$_baseUrl/report/export/sheets');
      if (response.statusCode == 200) {
        return response.data['message'] ?? "Export Berhasil";
      }
      throw Exception("Gagal export data");
    } catch (e) {
      throw Exception("Error Export: $e");
    }
  }

  Future<InstagramProfile> fetchInstagramProfile() async {
    final response = await _dio.get('$_baseUrl/instagram/profile');
    if (response.statusCode == 200) {
      return InstagramProfile.fromJson(response.data);
    }
    throw Exception("Gagal");
  }
}
