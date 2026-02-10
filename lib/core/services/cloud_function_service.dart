import 'dart:io'; // Untuk Platform check
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:suara_surabaya_admin/core/utils/constants.dart';

class CloudFunctionService {
  final Dio _dio = Dio();

  /// Fungsi Hybrid: 
  /// - Windows/Linux -> HTTP Request via Dio (Manual)
  /// - Mobile/Web    -> Firebase SDK (Native)
  Future<dynamic> call(String functionName, Map<String, dynamic> parameters) async {
    
    // Cek Platform: Jika Web atau Mobile (Android/iOS), pakai SDK Native
    // kIsWeb harus dicek duluan karena Platform.isWindows error di Web
    if (kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      try {
        final callable = FirebaseFunctions.instance.httpsCallable(functionName);
        final result = await callable.call(parameters);
        return result.data;
      } on FirebaseFunctionsException catch (e) {
        throw e.message ?? "Terjadi kesalahan pada fungsi server.";
      }
    } 
    
    // Jika Windows / Linux -> Pakai HTTP Manual (Dio)
    else {
      return _callViaHttp(functionName, parameters);
    }
  }

  Future<dynamic> _callViaHttp(String functionName, Map<String, dynamic> parameters) async {
    try {
      // 1. Dapatkan Token Auth User saat ini (PENTING untuk context.auth di backend)
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw "User tidak terautentikasi";
      
      final idToken = await user.getIdToken();

      // 2. Susun URL Endpoint
      // Format: https://<REGION>-<PROJECT_ID>.cloudfunctions.net/<FUNCTION_NAME>
      final String url = 
          "https://$FUNCTIONS_REGION-$FIREBASE_PROJECT_ID.cloudfunctions.net/$functionName";

      // 3. Request via Dio
      // Ingat: Callable Function butuh body dibungkus dengan key "data"
      final response = await _dio.post(
        url,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $idToken", // Ini kunci agar context.auth terbaca
          },
        ),
        data: {
          "data": parameters, 
        },
      );

      // 4. Handle Response
      // Callable function mengembalikan: {"result": ...} atau {"error": ...}
      final responseData = response.data;

      if (responseData is Map && responseData.containsKey('error')) {
        // Jika backend melempar error (throw HttpsError)
        final error = responseData['error'];
        throw error['message'] ?? "Unknown server error";
      }

      return responseData['result'];

    } on DioException catch (e) {
      // Handle error jaringan/server level HTTP
      if (e.response != null) {
        // Coba baca pesan error dari body response Firebase
        final data = e.response?.data;
        if (data is Map && data.containsKey('error')) {
           final errInfo = data['error'];
           if (errInfo is Map && errInfo.containsKey('message')) {
             throw errInfo['message'];
           }
        }
      }
      throw "Gagal terhubung ke server: ${e.message}";
    } catch (e) {
      throw e.toString();
    }
  }
}