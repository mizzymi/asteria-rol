class CharacterCounter {
  String id;
  String name;
  int value;

  CharacterCounter({required this.id, required this.name, this.value = 0});

  void increase([int amount = 1]) {
    if (amount <= 0) {
      return;
    }

    value += amount;
  }

  void decrease([int amount = 1]) {
    if (amount <= 0) {
      return;
    }

    value -= amount;

    if (value < 0) {
      value = 0;
    }
  }

  void setValue(int newValue) {
    value = newValue < 0 ? 0 : newValue;
  }

  void reset() {
    value = 0;
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'value': value};
  }

  factory CharacterCounter.fromMap(Map<dynamic, dynamic> map) {
    return CharacterCounter(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      value: (map['value'] as num?)?.toInt() ?? 0,
    );
  }
}
