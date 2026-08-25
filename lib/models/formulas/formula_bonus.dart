import 'character_formula.dart';

class FormulaBonus {
  int flatValue;

  CharacterFormula? formula;

  FormulaBonus({this.flatValue = 0, this.formula});

  bool get hasFormula {
    return formula != null &&
        formula!.expression.trim().isNotEmpty &&
        formula!.expression.trim() != '0';
  }

  bool get hasValue {
    return flatValue != 0 || hasFormula;
  }

  Map<String, dynamic> toMap() {
    return {'flatValue': flatValue, 'formula': formula?.toMap()};
  }

  factory FormulaBonus.fromMap(Map<dynamic, dynamic> map) {
    final rawFormula = map['formula'];

    return FormulaBonus(
      flatValue: (map['flatValue'] as num?)?.toInt() ?? 0,
      formula: rawFormula is Map
          ? CharacterFormula.fromMap(Map<dynamic, dynamic>.from(rawFormula))
          : null,
    );
  }
}
