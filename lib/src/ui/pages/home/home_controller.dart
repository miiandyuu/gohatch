import 'package:health/health.dart';

class HomeController {
  Future testData() async {
    int _getSteps = 0;

    HealthFactory health = HealthFactory();

    

  }

  Future<void> getData() async {
    final health = HealthFactory();

    var types = [
      HealthDataType.STEPS,
      // HealthDataType.BLOOD_GLUCOSE,
      // HealthDataType.WEIGHT,
      // HealthDataType.HEIGHT,
      // HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
      // HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
      // HealthDataType.HEART_RATE,
      // HealthDataType.BODY_TEMPERATURE,
    ];

    // requesting access to the data types before reading them
    // bool requested = await health.requestAuthorization(types);

    var now = DateTime.now();

    // fetch health data from the last 24 hours
    List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
        now.subtract(const Duration(days: 1)), now, types);

    // request permissions to write steps and blood glucose
    types = [HealthDataType.STEPS, HealthDataType.BLOOD_GLUCOSE];
    var permissions = [
      HealthDataAccess.READ_WRITE,
      HealthDataAccess.READ_WRITE
    ];
    await health.requestAuthorization(types, permissions: permissions);

    // write steps and blood glucose
    bool success =
        await health.writeHealthData(10, HealthDataType.STEPS, now, now);
    // success = await health.writeHealthData(
    //     3.1, HealthDataType.BLOOD_GLUCOSE, now, now);

    // get the number of steps for today
    var midnight = DateTime(now.year, now.month, now.day);
    int? steps = await health.getTotalStepsInInterval(midnight, now);
    if (success) {
      print("Successfully wrote data to HealthKit.");
      print(healthData);
    } else {
      print("Failed to write data to HealthKit.");
      print(healthData);
    }
    // print(healthData);
  }
}
