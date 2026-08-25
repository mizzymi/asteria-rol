import 'formulas/character_formula.dart';
import 'formulas/formula_modifier.dart';

enum PassiveResourceTarget { current, max }

extension PassiveResourceTargetData on PassiveResourceTarget {
  String get label {
    switch (this) {
      case PassiveResourceTarget.current:
        return 'Cantidad actual';

      case PassiveResourceTarget.max:
        return 'Cantidad máxima';
    }
  }
}

class PassiveResourceModifier {
  String id;
  String resourceId;

  PassiveResourceTarget target;
  FormulaModifierOperation operation;

  CharacterFormula formula;

  PassiveResourceModifier({
    required this.id,
    required this.resourceId,
    this.target = PassiveResourceTarget.current,
    this.operation = FormulaModifierOperation.add,
    CharacterFormula? formula,
  }) : formula = formula ?? CharacterFormula(expression: '0');

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'resourceId': resourceId,
      'target': target.name,
      'operation': operation.name,
      'formula': formula.toMap(),
    };
  }

  factory PassiveResourceModifier.fromMap(Map<dynamic, dynamic> map) {
    final rawFormula = map['formula'];

    return PassiveResourceModifier(
      id: map['id']?.toString() ?? '',
      resourceId: map['resourceId']?.toString() ?? '',
      target: PassiveResourceTarget.values.firstWhere(
        (value) => value.name == map['target']?.toString(),
        orElse: () => PassiveResourceTarget.current,
      ),
      operation: FormulaModifierOperation.values.firstWhere(
        (value) => value.name == map['operation']?.toString(),
        orElse: () => FormulaModifierOperation.add,
      ),
      formula: rawFormula is Map
          ? CharacterFormula.fromMap(Map<dynamic, dynamic>.from(rawFormula))
          : CharacterFormula(expression: '0'),
    );
  }
}
