import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

http.Client createBaseClient() {
  final client = BrowserClient()..withCredentials = true;
  return client;
}
