import 'action_apply_result.dart';
import 'action_resolution_result.dart';

class ActionExecutionResult {
  final ActionResolutionResult resolution;

  final ActionApplyResult application;

  const ActionExecutionResult({
    required this.resolution,
    required this.application,
  });
}
