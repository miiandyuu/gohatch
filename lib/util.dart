import 'package:health/health.dart';

/// List of data types available on iOS
const List<HealthDataType> dataTypesIOS = [
  HealthDataType.STEPS,
  HealthDataType.DISTANCE_WALKING_RUNNING,
];

/// List of data types available on Android
const List<HealthDataType> dataTypesAndroid = [
  // HealthDataType.STEPS,
  HealthDataType.DISTANCE_DELTA,
  // HealthDataType.MOVE_MINUTES,
  // HealthDataType.WORKOUT,
];