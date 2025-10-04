import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Configure Google Fonts for testing environment
void configureGoogleFontsForTest() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Load local test fonts
  FontLoader('NotoSerif')
    ..addFont(_loadFont('assets/fonts/NotoSerif-Regular.ttf'))
    ..load();
  FontLoader('Inter')
    ..addFont(_loadFont('assets/fonts/Inter-Regular.ttf'))
    ..load();
  FontLoader('GentiumPlus')
    ..addFont(_loadFont('assets/fonts/GentiumPlus-Regular.ttf'))
    ..load();

  // Allow Google Fonts to use local assets
  GoogleFonts.config.allowRuntimeFetching = false;
}

Future<ByteData> _loadFont(String path) async {
  return rootBundle.load(path);
}
