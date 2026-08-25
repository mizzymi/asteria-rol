class CharacterFormula {
  String expression;

  CharacterFormula({this.expression = '0'});

  bool get isEmpty {
    return expression.trim().isEmpty;
  }

  CharacterFormula copy() {
    return CharacterFormula(expression: expression);
  }

  Map<String, dynamic> toMap() {
    return {'expression': expression};
  }

  factory CharacterFormula.fromMap(Map<dynamic, dynamic> map) {
    return CharacterFormula(expression: map['expression']?.toString() ?? '0');
  }
}
