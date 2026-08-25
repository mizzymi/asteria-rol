import 'character_formula.dart';

enum FormulaModifierOperation { add, subtract, set }

extension FormulaModifierOperationData on FormulaModifierOperation {
  String get label {
    switch (this) {
      case FormulaModifierOperation.add:
        return 'Sumar';

      case FormulaModifierOperation.subtract:
        return 'Restar';

      case FormulaModifierOperation.set:
        return 'Establecer';
    }
  }
}

class FormulaModifier {
  String id;

  CharacterFormula formula;

  FormulaModifierOperation operation;

  FormulaModifier({
    required this.id,
    CharacterFormula? formula,
    this.operation = FormulaModifierOperation.add,
  }) : formula = formula ?? CharacterFormula(expression: '0');

  Map<String, dynamic> toMap() {
    return {'id': id, 'formula': formula.toMap(), 'operation': operation.name};
  }

  factory FormulaModifier.fromMap(Map<dynamic, dynamic> map) {
    final rawFormula = map['formula'];

    return FormulaModifier(
      id: map['id']?.toString() ?? '',
      formula: rawFormula is Map
          ? CharacterFormula.fromMap(Map<dynamic, dynamic>.from(rawFormula))
          : CharacterFormula(expression: '0'),
      operation: FormulaModifierOperation.values.firstWhere(
        (value) => value.name == map['operation']?.toString(),
        orElse: () => FormulaModifierOperation.add,
      ),
    );
  }
}
