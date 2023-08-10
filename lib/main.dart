import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gohatch/util.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const MaterialApp(home: HealthApp()));

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class HealthApp extends StatefulWidget {
  const HealthApp({super.key});

  @override
  State<HealthApp> createState() => _HealthAppState();
}

enum AppState {
  dataNotFetched,
  fetchingData,
  dataReady,
  noData,
  authorized,
  authNotGranted,
  dataAdded,
  dataDeleted,
  dataNotAdded,
  dataNotDeleted,
  stepsReady,
}

class _HealthAppState extends State<HealthApp> {
  List<HealthDataPoint> _healthDataList = [];
  AppState _state = AppState.dataNotFetched;
  int _nofSteps = 0;

  static const types = dataTypesAndroid;

  final permissions = types.map((e) => HealthDataAccess.READ_WRITE).toList();

  HealthFactory health = HealthFactory();

  Future authorize() async {
    await Permission.activityRecognition.request();
    await Permission.location.request();

    // Check if we have permission
    bool? hasPermissions =
        await health.hasPermissions(types, permissions: permissions);

    hasPermissions = false;

    bool authorized = false;
    if (!hasPermissions) {
      // requesting access to the data types before reading them
      try {
        authorized =
            await health.requestAuthorization(types, permissions: permissions);
      } catch (error) {
        print("Exception in authorize: $error");
      }
    }

    setState(() => _state =
        (authorized) ? AppState.authorized : AppState.authNotGranted);
  }

  /// Fetch data points from the health plugin and show them in the app.
  Future fetchData() async {
    setState(() => _state = AppState.fetchingData);

    // get data within the last 24 hours
    final now = DateTime.now();
    // final yesterday = now.subtract(const Duration(hours: 24));
    final lastHour = now.subtract(const Duration(hours: 2));

    // Clear old data points
    _healthDataList.clear();

    try {
      // fetch health data
      List<HealthDataPoint> healthData =
          await health.getHealthDataFromTypes(lastHour, now, types);
      // save all the new data points (only the first 100)
      _healthDataList.addAll(
          (healthData.length < 100) ? healthData : healthData.sublist(0, 100));
    } catch (error) {
      print("Exception in getHealthDataFromTypes: $error");
    }

    // filter out duplicates
    _healthDataList = HealthFactory.removeDuplicates(_healthDataList);

    // print the results
    for (var x in _healthDataList) {
      print(x);
    }

    // update the UI to display the results
    setState(() {
      _state = _healthDataList.isEmpty ? AppState.noData : AppState.dataReady;
    });
  }

  /// Add some random health data.
  Future addData({required double steps}) async {
    final now = DateTime.now();
    final earlier = now.subtract(const Duration(minutes: 20));

    bool success = true;
    success &=
        await health.writeHealthData(steps, HealthDataType.STEPS, earlier, now);
    success &= await health.writeHealthData(
        steps, HealthDataType.DISTANCE_DELTA, earlier, now);

    setState(() {
      _state = success ? AppState.dataAdded : AppState.dataNotAdded;
    });
  }

  /// Delete some random health data.
  Future deleteData() async {
    final now = DateTime.now();
    final earlier = now.subtract(const Duration(hours: 24));

    bool success = true;
    for (HealthDataType type in types) {
      success &= await health.delete(type, earlier, now);
    }

    setState(() {
      _state = success ? AppState.dataDeleted : AppState.dataNotDeleted;
    });
  }

  /// Fetch steps from the health plugin and show them in the app.
  Future fetchStepData() async {
    int? steps;

    // get steps for today (i.e., since midnight)
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    bool requested = await health.requestAuthorization([HealthDataType.STEPS]);

    if (requested) {
      try {
        steps = await health.getTotalStepsInInterval(midnight, now);
      } catch (error) {
        print("Caught exception in getTotalStepsInInterval: $error");
      }

      print('Total number of steps: $steps');

      setState(() {
        _nofSteps = (steps == null) ? 0 : steps;
        _state = (steps == null) ? AppState.noData : AppState.stepsReady;
      });
    } else {
      print("Authorization not granted - error in authorization");
      setState(() => _state = AppState.dataNotFetched);
    }
  }

  Future revokeAccess() async {
    try {
      await health.revokePermissions();
    } catch (error) {
      print("Caught exception in revokeAccess: $error");
    }
  }

  Widget _contentFetchingData() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
            padding: const EdgeInsets.all(20),
            child: const CircularProgressIndicator(
              strokeWidth: 10,
            )),
        const Text('Fetching data...')
      ],
    );
  }

  Widget _contentDataReady() {
    return ListView.builder(
        itemCount: _healthDataList.length,
        itemBuilder: (_, index) {
          HealthDataPoint p = _healthDataList[index];
          if (p.value is AudiogramHealthValue) {
            return ListTile(
              title: Text("${p.typeString}: ${p.value}"),
              trailing: Text(p.unitString),
              subtitle: Text('${p.dateFrom} - ${p.dateTo}'),
            );
          }
          if (p.value is WorkoutHealthValue) {
            return ListTile(
              title: Text(
                  "${p.typeString}: ${(p.value as WorkoutHealthValue).totalEnergyBurned} ${(p.value as WorkoutHealthValue).totalEnergyBurnedUnit?.name}"),
              trailing: Text(
                  (p.value as WorkoutHealthValue).workoutActivityType.name),
              subtitle: Text('${p.dateFrom} - ${p.dateTo}'),
            );
          }
          return ListTile(
            title: Text("${p.typeString}: ${p.value}"),
            trailing: Text(p.unitString),
            subtitle: Text('${p.dateFrom} - ${p.dateTo}'),
          );
        });
  }

  Widget _contentNoData() {
    return const Text('No Data to show');
  }

  Widget _contentNotFetched() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Press the download button to fetch data.'),
        Text('Press the plus button to insert some random data.'),
        Text('Press the walking button to get total step count.'),
      ],
    );
  }

  Widget _authorized() {
    return const Text('Authorization granted!');
  }

  Widget _authorizationNotGranted() {
    return const Text('Authorization not given. '
        'For Android please check your OAUTH2 client ID is correct in Google Developer Console. '
        'For iOS check your permissions in Apple Health.');
  }

  Widget _dataAdded() {
    return const Text('Data points inserted successfully!');
  }

  Widget _dataDeleted() {
    return const Text('Data points deleted successfully!');
  }

  Widget _stepsFetched() {
    return Text('Total number of steps: $_nofSteps');
  }

  Widget _dataNotAdded() {
    return const Text('Failed to add data');
  }

  Widget _dataNotDeleted() {
    return const Text('Failed to delete data');
  }

  Widget _content() {
    if (_state == AppState.dataReady) {
      return _contentDataReady();
    } else if (_state == AppState.noData) {
      return _contentNoData();
    } else if (_state == AppState.fetchingData) {
      return _contentFetchingData();
    } else if (_state == AppState.authorized) {
      return _authorized();
    } else if (_state == AppState.authNotGranted) {
      return _authorizationNotGranted();
    } else if (_state == AppState.dataAdded) {
      return _dataAdded();
    } else if (_state == AppState.dataDeleted) {
      return _dataDeleted();
    } else if (_state == AppState.stepsReady) {
      return _stepsFetched();
    } else if (_state == AppState.dataNotAdded) {
      return _dataNotAdded();
    } else if (_state == AppState.dataNotDeleted) {
      return _dataNotDeleted();
    } else {
      return _contentNotFetched();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Example'),
      ),
      body: Column(
        children: [
          Wrap(
            spacing: 10,
            children: [
              TextButton(
                  onPressed: authorize,
                  style: const ButtonStyle(
                      backgroundColor: MaterialStatePropertyAll(Colors.blue)),
                  child: const Text("Auth",
                      style: TextStyle(color: Colors.white))),
              TextButton(
                  onPressed: fetchData,
                  style: const ButtonStyle(
                      backgroundColor: MaterialStatePropertyAll(Colors.blue)),
                  child: const Text("Fetch Data",
                      style: TextStyle(color: Colors.white))),
              TextButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.egg),
                              title: const Text("2KM"),
                              onTap: () => addData(steps: 10),
                            ),
                            ListTile(
                              leading: const Icon(Icons.egg_outlined),
                              title: const Text("5KM"),
                              onTap: () => addData(steps: 5000),
                            ),
                            ListTile(
                              leading: const Icon(Icons.egg_alt),
                              title: const Text("7KM"),
                              onTap: () => addData(steps: 7000),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  style: const ButtonStyle(
                      backgroundColor: MaterialStatePropertyAll(Colors.blue)),
                  child: const Text("Add Data",
                      style: TextStyle(color: Colors.white))),
              TextButton(
                  onPressed: deleteData,
                  style: const ButtonStyle(
                      backgroundColor: MaterialStatePropertyAll(Colors.blue)),
                  child: const Text("Delete Data",
                      style: TextStyle(color: Colors.white))),
              TextButton(
                  onPressed: fetchStepData,
                  style: const ButtonStyle(
                      backgroundColor: MaterialStatePropertyAll(Colors.blue)),
                  child: const Text("Fetch Step Data",
                      style: TextStyle(color: Colors.white))),
              TextButton(
                  onPressed: revokeAccess,
                  style: const ButtonStyle(
                      backgroundColor: MaterialStatePropertyAll(Colors.blue)),
                  child: const Text("Revoke Access",
                      style: TextStyle(color: Colors.white))),
            ],
          ),
          const Divider(thickness: 3),
          Expanded(child: Center(child: _content()))
        ],
      ),
    );
  }
}
