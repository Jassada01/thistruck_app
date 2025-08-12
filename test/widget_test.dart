// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:thistruck_app/provider/font_size_provider.dart';

void main() {
  testWidgets('FontSizeProvider basic test', (WidgetTester tester) async {
    // Test FontSizeProvider functionality
    final provider = FontSizeProvider();
    await provider.initialize();
    
    // Test initial values
    expect(provider.fontSizeLevel, isA<FontSizeLevel>());
    expect(provider.fontSizeName, isA<String>());
    
    // Test setting font size
    provider.setFontSizeLevel(FontSizeLevel.large);
    expect(provider.fontSizeLevel, FontSizeLevel.large);
  });
}
