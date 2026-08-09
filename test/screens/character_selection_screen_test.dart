import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:rol/models/character.dart';
import 'package:rol/screens/character_selection_screen.dart';
import 'package:rol/theme/app_theme.dart';

void main() {
  late Directory tempDirectory;

  setUpAll(() async {
    tempDirectory =
    await Directory.systemTemp.createTemp(
      'asteria_selection_test_',
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
      home: const CharacterSelectionScreen(),
    );
  }

  testWidgets(
    'muestra estado vacío cuando no hay personajes',
        (tester) async {
      await tester.pumpWidget(
        createApp(),
      );

      await tester.pump();

      expect(
        find.text('Mis personajes'),
        findsOneWidget,
      );

      expect(
        find.text(
          'Todavía no tienes personajes',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'muestra los personajes guardados',
        (tester) async {
      final box =
      Hive.box('characters');

      await box.put(
        '1',
        Character(
          id: '1',
          name: 'Nyra',
          race: 'Loba',
          characterClass:
          'Exploradora',
          level: 8,
        ).toMap(),
      );

      await box.put(
        '2',
        Character(
          id: '2',
          name: 'Milo',
          race: 'Gato',
          characterClass: 'Mago',
          level: 5,
        ).toMap(),
      );

      await tester.pumpWidget(
        createApp(),
      );

      await tester.pump();

      expect(
        find.text('Nyra'),
        findsOneWidget,
      );

      expect(
        find.text('Milo'),
        findsOneWidget,
      );

      expect(
        find.text(
          'Loba · Exploradora',
        ),
        findsOneWidget,
      );

      expect(
        find.text(
          'Gato · Mago',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'busca personajes por nombre',
        (tester) async {
      final box =
      Hive.box('characters');

      await box.put(
        '1',
        Character(
          id: '1',
          name: 'Nyra',
          race: 'Loba',
        ).toMap(),
      );

      await box.put(
        '2',
        Character(
          id: '2',
          name: 'Milo',
          race: 'Gato',
        ).toMap(),
      );

      await tester.pumpWidget(
        createApp(),
      );

      await tester.pump();

      final search =
      find.byType(TextField);

      expect(
        search,
        findsOneWidget,
      );

      await tester.enterText(
        search,
        'nyra',
      );

      await tester.pump();

      expect(
        find.text('Nyra'),
        findsOneWidget,
      );

      expect(
        find.text('Milo'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'muestra mensaje si no encuentra personaje',
        (tester) async {
      await Hive.box('characters').put(
        '1',
        Character(
          id: '1',
          name: 'Nyra',
        ).toMap(),
      );

      await tester.pumpWidget(
        createApp(),
      );

      await tester.pump();

      await tester.enterText(
        find.byType(TextField),
        'pepe',
      );

      await tester.pump();

      expect(
        find.text(
          'No encontramos ese personaje',
        ),
        findsOneWidget,
      );
    },
  );
}