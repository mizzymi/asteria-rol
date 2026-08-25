enum ActionDiceMode { digital, physical }

extension ActionDiceModeLabel on ActionDiceMode {
  String get label {
    switch (this) {
      case ActionDiceMode.digital:
        return 'Dados digitales';

      case ActionDiceMode.physical:
        return 'Dados físicos';
    }
  }
}
