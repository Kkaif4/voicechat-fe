// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:voicechat/main.dart';
import 'package:voicechat/core/network/api_client.dart';
import 'package:voicechat/features/auth/data/auth_repository.dart';
import 'package:voicechat/core/network/socket_service.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Create dummy/mock dependencies for testing
    final storage = const FlutterSecureStorage();
    final apiClient = ApiClient(storage);
    final authRepo = AuthRepository(apiClient, storage);
    final socketService = SocketService();

    await tester.pumpWidget(
      MyApp(authRepository: authRepo, socketService: socketService),
    );

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
