// lib/core/services/sheets_service.dart

import 'package:flutter/services.dart' show rootBundle;
import 'package:gsheets/gsheets.dart';

class SheetsService {
  final GSheets _gsheets;

  SheetsService(String credentialsJson) : _gsheets = GSheets(credentialsJson);

  static Future<SheetsService> initialize() async {
    final credentialsJson = await rootBundle.loadString('assets/credentials/ss-sna-credentials.json');
    return SheetsService(credentialsJson);
  }

  Future<Worksheet?> getWorksheet(String spreadsheetId, String worksheetTitle) async {
    try {
      final ss = await _gsheets.spreadsheet(spreadsheetId);
      return ss.worksheetByTitle(worksheetTitle);
    } catch (e) {
      // Jika worksheet tidak ditemukan, coba buat yang baru
      if (e.toString().contains('`worksheet` not found')) {
        try {
          print("Worksheet '$worksheetTitle' tidak ditemukan, mencoba membuat...");
          final ss = await _gsheets.spreadsheet(spreadsheetId);
          return await ss.addWorksheet(worksheetTitle);
        } catch (addErr) {
          print("Gagal membuat worksheet baru: $addErr");
          return null;
        }
      }
      print('Error mendapatkan worksheet berdasarkan judul: $e');
      return null;
    }
  }

  Future<bool> clearWorksheet(Worksheet worksheet) async {
    try {
      await worksheet.clear();
      return true;
    } catch (e) {
      print("Gagal membersihkan worksheet: $e");
      return false;
    }
  }

  Future<bool> insertRow(Worksheet worksheet, int rowNumber, List<dynamic> data) async {
      try {
          return await worksheet.values.insertRow(rowNumber, data);
      } catch (e) {
          print("Gagal menyisipkan baris: $e");
          return false;
      }
  }

  Future<bool> appendRows(Worksheet worksheet, List<List<dynamic>> rows) async {
    try {
      return await worksheet.values.appendRows(rows);
    } catch (e) {
      print("Gagal menambahkan baris-baris data: $e");
      return false;
    }
  }

  Future<List<Map<String, String>>?> getRowsAsMaps(Worksheet worksheet) async {
     try {
      final rows = await worksheet.values.map.allRows();
      return rows;
    } catch (e) {
      print('Error mendapatkan baris: $e');
      return null;
    }
  }
}