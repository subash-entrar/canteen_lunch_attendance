import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canteen_lunch_attendance/app.dart';

void main() {
  testWidgets('App boots to splash', (tester) async {
    await tester.pumpWidget(const CanteenLunchApp());
    expect(find.text('SSVM Meal'), findsOneWidget);
  });
}
