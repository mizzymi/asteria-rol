import 'package:flutter_test/flutter_test.dart';
import 'package:rol/models/character.dart';

void main() {
  group('Character', () {
    test('crea un personaje con valores por defecto', () {
      final character = Character(id: '1', name: 'Nyra');

      expect(character.id, '1');
      expect(character.name, 'Nyra');
      expect(character.level, 1);

      expect(character.currentHealth, 10);
      expect(character.maxHealth, 10);

      expect(character.currentMana, 10);
      expect(character.maxMana, 10);

      expect(character.race, '');
      expect(character.characterClass, '');
      expect(character.backstory, '');
      expect(character.personality, '');

      expect(character.avatarPath, isNull);
    });

    test('convierte Character a Map correctamente', () {
      final character = Character(
        id: '123',
        name: 'Nyra',
        avatarPath: '/avatar/nyra.png',
        race: 'Loba',
        characterClass: 'Exploradora',
        level: 8,
        currentHealth: 72,
        maxHealth: 95,
        currentMana: 14,
        maxMana: 20,
        backstory: 'Nació en las montañas.',
        personality: 'Curiosa y protectora.',
      );

      final map = character.toMap();

      expect(map['id'], '123');
      expect(map['name'], 'Nyra');
      expect(map['avatarPath'], '/avatar/nyra.png');

      expect(map['race'], 'Loba');
      expect(map['characterClass'], 'Exploradora');

      expect(map['level'], 8);

      expect(map['currentHealth'], 72);
      expect(map['maxHealth'], 95);

      expect(map['currentMana'], 14);
      expect(map['maxMana'], 20);

      expect(map['backstory'], 'Nació en las montañas.');

      expect(map['personality'], 'Curiosa y protectora.');
    });

    test('crea Character desde Map correctamente', () {
      final map = {
        'id': '456',
        'name': 'Milo',
        'avatarPath': null,
        'race': 'Gato',
        'characterClass': 'Mago',
        'level': 5,
        'currentHealth': 40,
        'maxHealth': 50,
        'currentMana': 28,
        'maxMana': 35,
        'backstory': 'Un joven mago.',
        'personality': 'Tranquilo.',
      };

      final character = Character.fromMap(map);

      expect(character.id, '456');
      expect(character.name, 'Milo');

      expect(character.race, 'Gato');
      expect(character.characterClass, 'Mago');

      expect(character.level, 5);

      expect(character.currentHealth, 40);
      expect(character.maxHealth, 50);

      expect(character.currentMana, 28);
      expect(character.maxMana, 35);

      expect(character.backstory, 'Un joven mago.');
      expect(character.personality, 'Tranquilo.');
    });

    test('toMap y fromMap mantienen los datos', () {
      final original = Character(
        id: '999',
        name: 'Aria',
        race: 'Humana',
        characterClass: 'Guerrera',
        level: 12,
        currentHealth: 90,
        maxHealth: 120,
        currentMana: 5,
        maxMana: 10,
        backstory: 'Una antigua guerrera.',
        personality: 'Valiente.',
      );

      final restored = Character.fromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.race, original.race);

      expect(restored.characterClass, original.characterClass);

      expect(restored.level, original.level);

      expect(restored.currentHealth, original.currentHealth);

      expect(restored.maxHealth, original.maxHealth);

      expect(restored.currentMana, original.currentMana);

      expect(restored.maxMana, original.maxMana);

      expect(restored.backstory, original.backstory);

      expect(restored.personality, original.personality);
    });
  });
}
