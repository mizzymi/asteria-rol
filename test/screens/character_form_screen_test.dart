import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:rol/screens/character_form_screen.dart';
import 'package:rol/theme/app_theme.dart';

void main() {
  late Directory tempDirectory;

  setUpAll(() async {
    tempDirectory =
    await Directory.systemTemp.createTemp(
      'asteria_form_test_',
    );

    Hive.init(tempDirectory.path);

    await Hive.openBox('characters');
  });

  setUp(() async {
    await Hive.box('characters').clear();
  });

  tearDownAll(() async {
    await Hive.close();

    if (await tempDirectory.exists()) {
      await tempDirectory.delete(
        recursive: true,
      );
    }
  });

  Widget createApp() {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: const CharacterFormScreen(),
    );
  }

  testWidgets(
    'no permite crear personaje sin nombre',
        (tester) async {
      await tester.pumpWidget(
        createApp(),
      );

      await tester.pump();

      expect(
        find.byIcon(Icons.check_rounded),
        findsOneWidget,
      );

      await tester.tap(
        find.byIcon(Icons.check_rounded),
      );

      await tester.pump();

      expect(
        find.text('Introduce un nombre'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'permite escribir los datos del personaje',
        (tester) async {
      await tester.pumpWidget(
        createApp(),
      );

      await tester.pump();

      final fields =
      find.byType(TextFormField);

      expect(fields, findsWidgets);

      await tester.enterText(
        fields.at(0),
        'Nyra',
      );

      await tester.enterText(
        fields.at(1),
        'Loba',
      );

      await tester.enterText(
        fields.at(2),
        'Exploradora',
      );

      expect(
        find.text('Nyra'),
        findsOneWidget,
      );

      expect(
        find.text('Loba'),
        findsOneWidget,
      );

      expect(
        find.text('Exploradora'),
        findsOneWidget,
      );
    },
  );
}