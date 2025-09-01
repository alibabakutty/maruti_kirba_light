import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://192.168.1.7:8080';
  static const Duration timeout = Duration(seconds: 30);

  // Helper method for handling HTTP requests - UPDATED to handle 201
  static Future<dynamic> _handleRequest(Future<http.Response> request) async {
    try {
      final response = await request.timeout(timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Handle both 200 (OK) and 201 (Created) as success
        try {
          return json.decode(response.body);
        } catch (e) {
          // If response body is empty but status is success
          return {'success': true, 'statusCode': response.statusCode};
        }
      } else if (response.statusCode == 404) {
        return null; // Resource not found
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}\nResponse: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Create new customer
  static Future<dynamic> createCustomer(Map<String, dynamic> data) async {
    print('Creating customer: ${data['customerName']}');

    return await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/customerMasterApi/addCustomer'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      ),
    );
  }

  // Check if customer already exists
  static Future<bool> checkCustomerExists(String customerName) async {
    try {
      final customer = await getCustomerByCustomerName(customerName);
      return customer != null;
    } catch (e) {
      return false;
    }
  }

  // Get customer by customer name
  static Future<dynamic> getCustomerByCustomerName(String customerName) async {
    return await _handleRequest(
      http.get(
        Uri.parse('$baseUrl/customerMasterApi/displayCustomer/$customerName'),
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }

  // Other methods remain the same...
  static Future<List<dynamic>> getAllCustomers() async {
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/customerMasterApi/allCustomers')),
    );
    return response != null ? List<dynamic>.from(response) : [];
  }

  static Future<dynamic> updateCustomerByCustomerName(
    String customerName,
    Map<String, dynamic> customerData,
  ) async {
    return await _handleRequest(
      http.put(
        Uri.parse(
          '$baseUrl/customerMasterApi/alterCustomerMaster/$customerName',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(customerData),
      ),
    );
  }

  static Future<dynamic> deleteCustomer(int id) async {
    return await _handleRequest(
      http.delete(Uri.parse('$baseUrl/customerMasterApi/deleteCustomer/$id')),
    );
  }
}
