import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class ApiService {
  final String baseUrl;
  ApiService(this.baseUrl);

  Future<List<RequestModel>> fetchEndUserRequests(String userId) async {
    final res = await http.get(Uri.parse('$baseUrl/requests?role=enduser&userId=$userId'));
    if (res.statusCode != 200) throw Exception('Fetch failed');
    final data = json.decode(res.body) as List;
    return data.map((e) => RequestModel.fromJson(e)).toList();
  }

  Future<List<RequestModel>> fetchReceiverRequests(String receiverId) async {
    final res = await http.get(Uri.parse('$baseUrl/requests?role=receiver&receiverId=$receiverId'));
    if (res.statusCode != 200) throw Exception('Fetch failed');
    final data = json.decode(res.body) as List;
    return data.map((e) => RequestModel.fromJson(e)).toList();
  }

  Future<RequestModel> createRequest({required String userId, required List<String> items, String? receiverId}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/requests'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'userId': userId, 'items': items, 'receiverId': receiverId}),
    );
    if (res.statusCode != 200) throw Exception('Create failed');
    return RequestModel.fromJson(json.decode(res.body));
  }

  Future<RequestModel> submitConfirmation({required String requestId, required String receiverId, required List<Map<String, dynamic>> results}) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/requests/$requestId/confirm'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'receiverId': receiverId, 'results': results}),
    );
    if (res.statusCode != 200) throw Exception('Confirm failed');
    return RequestModel.fromJson(json.decode(res.body));
  }
}
