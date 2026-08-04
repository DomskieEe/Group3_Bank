import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {

  static Future<Map<String, dynamic>>
  getAccountInformation() async {

    try {

      final response = await http.get(
        Uri.parse(
          'https://jsonplaceholder.typicode.com/users/1',
        ),
      );

      if (response.statusCode == 200) {

        final data =
        jsonDecode(response.body);

        return {
          "accountName": data["name"],
          "balance": 125000
        };
      }

      throw Exception("API Error");

    } catch (e) {

      return {
        "accountName": "Offline User",
        "balance": 0
      };
    }
  }
}