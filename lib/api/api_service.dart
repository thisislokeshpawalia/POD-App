import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_constants.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, {this.statusCode = 500});

  @override
  String toString() => message;
}

class UnauthenticatedException implements Exception {
  final String message;
  UnauthenticatedException([this.message = 'Session expired. Please log in again.']);

  @override
  String toString() => message;
}

class ApiService {
  final http.Client _client;
  String? _authToken;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> get _headers {
    final map = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      map['Authorization'] = 'Bearer $_authToken';
    }
    return map;
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    Uri uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    try {
      final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 60));
      return _processResponse(response);
    } catch (e) {
      if (e is ApiException || e is UnauthenticatedException) rethrow;
      throw _handleNetworkException(e);
    }
  }

  Future<dynamic> post(String endpoint, {dynamic body}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    try {
      final response = await _client.post(
        uri,
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 60));
      return _processResponse(response);
    } catch (e) {
      if (e is ApiException || e is UnauthenticatedException) rethrow;
      throw _handleNetworkException(e);
    }
  }

  Future<dynamic> patch(String endpoint, {dynamic body}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    try {
      final response = await _client.patch(
        uri,
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 60));
      return _processResponse(response);
    } catch (e) {
      if (e is ApiException || e is UnauthenticatedException) rethrow;
      throw _handleNetworkException(e);
    }
  }

  Future<dynamic> delete(String endpoint) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    try {
      final response = await _client.delete(uri, headers: _headers).timeout(const Duration(seconds: 60));
      return _processResponse(response);
    } catch (e) {
      if (e is ApiException || e is UnauthenticatedException) rethrow;
      throw _handleNetworkException(e);
    }
  }

  Future<dynamic> postMultipart(String endpoint, {required String filePath, required String fileField}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    try {
      var request = http.MultipartRequest('POST', uri);
      if (_authToken != null && _authToken!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }
      
      request.files.add(
        await http.MultipartFile.fromPath(fileField, filePath)
      );

      final streamedResponse = await _client.send(request).timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);
    } catch (e) {
      if (e is ApiException || e is UnauthenticatedException) rethrow;
      throw _handleNetworkException(e);
    }
  }

  ApiException _handleNetworkException(dynamic e) {
    final str = e.toString();
    if (str.contains('Connection refused') || str.contains('errno = 111')) {
      return ApiException(
        'Connection refused by Mac server.\n\nPlease start FastAPI using:\nuvicorn app.main:app --host 0.0.0.0 --port 8000\n\nEnsure Mac & Phone are on the same Wi-Fi.',
      );
    }
    return ApiException('Network error: Unable to connect to server ($e)');
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode == 401) {
      throw UnauthenticatedException();
    }

    dynamic body;
    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(response.body);
      } catch (_) {
        body = response.body;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    String errorMessage = 'Server error occurred (${response.statusCode})';
    if (body is Map<String, dynamic>) {
      if (body.containsKey('detail')) {
        final detail = body['detail'];
        if (detail is String) {
          errorMessage = detail;
        } else if (detail is List) {
          errorMessage = detail.map((e) => e['msg'] ?? e.toString()).join(', ');
        }
      } else if (body.containsKey('message')) {
        errorMessage = body['message'].toString();
      }
    }

    throw ApiException(errorMessage, statusCode: response.statusCode);
  }
}
