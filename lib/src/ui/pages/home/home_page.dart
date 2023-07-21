import 'package:flutter/material.dart';
import 'package:gohatch/src/ui/pages/home/home_controller.dart';
import 'package:health/health.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // HomeController controller = HomeController();

  // @override
  // void initState() {
  //   super.initState();
  //   getStepData();
  // }

  int _getSteps = 0;

  HealthFactory health = HealthFactory();

  Future getStepData() async {
    int? steps;

    var types = [
      HealthDataType.STEPS,
      HealthDataType.WEIGHT,
    ];

    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    var permissions = [HealthDataAccess.READ_WRITE];

    bool requested =
        await health.requestAuthorization(types, permissions: permissions);

    if (requested) {
      try {
        steps = await health.getTotalStepsInInterval(midnight, now);
      } catch (e) {
        print(e.toString());
      }

      print('Total number of steps: $steps');

      setState(() {
        _getSteps = (steps == null) ? 0 : steps;
      });
    } else {
      print('Auth not granted');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('GoHatch'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => getStepData(),
          child: const Icon(Icons.refresh),
        ),
        body: Center(
          child: Column(
            children: [
              Text('Total Steps: {$_getSteps}'),
            ],
          ),
        ));
  }
}
