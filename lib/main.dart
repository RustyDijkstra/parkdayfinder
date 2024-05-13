import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScheduleProvider(),
      child: MaterialApp(
        title: 'Bay Assignment App',
        home: const HomeScreen(),
        routes: {
          '/bay-assignments': (context) => const BayAssignmentScreen(),
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    loadScheduleData();
  }

  Future<void> loadScheduleData() async {
    // Load the schedule data from a JSON file or API
    final scheduleData = await loadScheduleDataFromSource();
    print('Loaded schedule data: $scheduleData'); // Add this line

    // Update the provider with the loaded data
    context.read<ScheduleProvider>().loadScheduleData(scheduleData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bay Assignment App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Day:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Consumer<ScheduleProvider>(
              builder: (context, provider, child) {
                return DaySelectionWidget(provider: provider);
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/bay-assignments');
              },
              child: const Text('View Bay Assignments'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<ScheduleData> loadScheduleDataFromSource() async {
  // Load the JSON data from a file`
  final jsonData = await rootBundle.loadString('assets/schedule.json');

  // Convert the JSON data to a ScheduleData object
  final scheduleData = ScheduleData.fromJson(jsonDecode(jsonData));

  return scheduleData;
}

class ScheduleData {
  final Map<String, Map<int, String>> schedule;

  ScheduleData({required this.schedule});

  factory ScheduleData.fromJson(Map<String, dynamic> json) {
    final schedule = <String, Map<int, String>>{};

    json.forEach((day, assignments) {
      schedule[day] = Map<int, String>.from(
        (assignments as Map).map(
          (key, value) => MapEntry(int.parse(key), value.toString()),
        ),
      );
    });

    return ScheduleData(schedule: schedule);
  }
}

class DaySelectionWidget extends StatelessWidget {
  final ScheduleProvider provider;

  const DaySelectionWidget({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final List<String> availableDays =
        provider.scheduleData?.schedule.keys.toList() ?? [];

    return DropdownButton<String>(
      value: provider.selectedDay,
      onChanged: (day) {
        if (day != null) {
          provider.setSelectedDay(day);
        }
      },
      items: availableDays.map((day) {
        return DropdownMenuItem<String>(
          value: day,
          child: Text(day),
        );
      }).toList(),
    );
  }
}

class BayAssignmentWidget extends StatelessWidget {
  final ScheduleProvider provider;

  const BayAssignmentWidget({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final assignments =
        provider.scheduleData?.schedule[provider.selectedDay] ?? {};

    return GridView.count(
      crossAxisCount: 2,
      children: assignments.entries.map((entry) {
        return Card(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Bay ${entry.key}'),
              Text('Assigned: ${entry.value}'),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class BayAssignmentScreen extends StatelessWidget {
  const BayAssignmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ScheduleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bay Assignments'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Selector<ScheduleProvider, ScheduleData?>(
          selector: (_, provider) => provider.scheduleData,
          builder: (context, scheduleData, child) {
            return BayAssignmentWidget(
              provider: provider,
            );
          },
        ),
      ),
    );
  }
}

class ScheduleProvider extends ChangeNotifier {
  ScheduleData? _scheduleData;
  String _selectedDay = 'Monday';

  ScheduleData? get scheduleData => _scheduleData;
  String get selectedDay => _selectedDay;

  void loadScheduleData(ScheduleData scheduleData) {
    _scheduleData = scheduleData;
    notifyListeners();
  }

  void setSelectedDay(String day) {
    _selectedDay = day;
    notifyListeners();
  }
}
