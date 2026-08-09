import 'dart:math';

class DiceRollResult {
  final int die;
  final int modifier;

  DiceRollResult({required this.die, required this.modifier});

  int get total => die + modifier;
}

class DiceRoller {
  static final Random _random = Random();

  static DiceRollResult d20({int modifier = 0}) {
    final die = _random.nextInt(20) + 1;

    return DiceRollResult(die: die, modifier: modifier);
  }
}
