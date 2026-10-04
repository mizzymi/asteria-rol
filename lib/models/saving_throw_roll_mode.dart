enum SavingThrowRollMode { normal, advantage, disadvantage }

extension SavingThrowRollModeData on SavingThrowRollMode {
  String get label {
    switch (this) {
      case SavingThrowRollMode.normal:
        return 'Normal';
      case SavingThrowRollMode.advantage:
        return 'Ventaja';
      case SavingThrowRollMode.disadvantage:
        return 'Desventaja';
    }
  }

  String get shortLabel {
    switch (this) {
      case SavingThrowRollMode.normal:
        return 'Normal';
      case SavingThrowRollMode.advantage:
        return 'Ventaja';
      case SavingThrowRollMode.disadvantage:
        return 'Desventaja';
    }
  }
}
