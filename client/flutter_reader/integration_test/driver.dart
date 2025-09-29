import "dart:convert";
import "dart:io";

import "package:integration_test/integration_test_driver_extended.dart";

Future<void> main() async {
  await integrationDriver(
    onScreenshot:
        (String name, List<int> bytes, [Map<String, Object?>? args]) async {
          final file = File('../../artifacts/$name.png');
          await file.create(recursive: true);
          await file.writeAsBytes(bytes);
          // ignore: avoid_print
          print('saved screenshot $name bytes=${bytes.length}');
          return true;
        },
    responseDataCallback: (Map<String, dynamic>? data) async {
      final reportFile = File('../../artifacts/e2e_web_report.json');
      await reportFile.create(recursive: true);
      final payload = <String, Object?>{
        'result': 'success',
        'failureDetails': const <Object?>[],
      };
      if (data != null) {
        // ignore: avoid_print
        print('integration data keys: ${data.keys.join(',')}');
        final mutable = Map<String, dynamic>.from(data);
        final result = mutable.remove('result');
        if (result != null) {
          payload['result'] = result;
        }
        final details = mutable.remove('failureDetails');
        if (details != null) {
          payload['failureDetails'] = details;
        }
        if (mutable.isNotEmpty) {
          payload['data'] = mutable;
        }
      }
      await reportFile.writeAsString(jsonEncode(payload));
    },
  );
}
