import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppwriteConfig {
  static final String projectId = dotenv.env['APPWRITE_PROJECT_ID'] ?? 'YOUR_DEFAULT_PROJECT_ID';
  static final String endpoint = dotenv.env['APPWRITE_ENDPOINT'] ?? 'YOUR_DEFAULT_ENDPOINT';
}
