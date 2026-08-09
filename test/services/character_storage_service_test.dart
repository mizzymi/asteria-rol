import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rol/models/character.dart';


void main() {
  late Directory tempDirectory;
  late Box box;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp();

    Hive.init(tempDirectory.path);

    box = await Hive.openBox('characters_test');
  });

  tearDown(() async {
    await box.close();
    await Hive.deleteFromDisk();

    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('guarda y recupera un personaje', () async {
    final character = Character(
      id: '1',
      name: 'Nyra',
      race: 'Loba',
      characterClass: 'Exploradora',
      level: 8,
    );

    await box.put(character.id, character.toMap());

    final value = box.get('1');

    expect(value, isNotNull);

    final restored = Character.fromMap(Map<dynamic, dynamic>.from(value));

    expect(restored.id, '1');
    expect(restored.name, 'Nyra');
    expect(restored.race, 'Loba');

    expect(restored.characterClass, 'Exploradora');

    expect(restored.level, 8);
  });

  test('actualiza un personaje existente', () async {
    final character = Character(id: '1', name: 'Nyra', level: 1);

    await box.put(character.id, character.toMap());

    character.level = 10;

    await box.put(character.id, character.toMap());

    final value = box.get('1');

    final restored = Character.fromMap(Map<dynamic, dynamic>.from(value));

    expect(restored.level, 10);

    expect(
      box.length,
      1,
      reason: 'Editar un personaje no debe crear otro personaje',
    );
  });

  test('elimina un personaje', () async {
    final character = Character(id: '1', name: 'Nyra');

    await box.put(character.id, character.toMap());

    expect(box.containsKey('1'), true);

    await box.delete('1');

    expect(box.containsKey('1'), false);
  });

  test('puede guardar varios personajes', () async {
    final characters = [
      Character(id: '1', name: 'Nyra'),
      Character(id: '2', name: 'Milo'),
      Character(id: '3', name: 'Aria'),
    ];

    for (final character in characters) {
      await box.put(character.id, character.toMap());
    }

    expect(box.length, 3);

    final names = box.values
        .map(
          (value) => Character.fromMap(Map<dynamic, dynamic>.from(value)).name,
        )
        .toList();

    expect(names, containsAll(['Nyra', 'Milo', 'Aria']));
  });
}
