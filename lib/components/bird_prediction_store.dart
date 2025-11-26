// lib/bird_prediction_store.dart

class BirdPredictionStore {
  BirdPredictionStore._();

  static final BirdPredictionStore instance = BirdPredictionStore._();

  /// Raw label from backend, e.g. "Pavo_cristatus"
  String? lastBirdId;

  /// Pretty name, e.g. "Pavo cristatus"
  String? get prettyName =>
      lastBirdId == null ? null : lastBirdId!.replaceAll('_', ' ');
}
