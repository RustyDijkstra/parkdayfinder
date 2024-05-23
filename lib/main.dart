import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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
          ],
        ),
      ),
    );
  }
}

Future<ScheduleData> loadScheduleDataFromSource() async {
  // Load the JSON data from a file
  final jsonData = await rootBundle.loadString('assets/schedule.json');

  // Convert the JSON data to a ScheduleData object
  final scheduleData = ScheduleData.fromJson(jsonDecode(jsonData));

  return scheduleData;
}

class ScheduleData {
  final List<Map<String, dynamic>> allocations;

  ScheduleData({required this.allocations});

  factory ScheduleData.fromJson(Map<String, dynamic> json) {
    return ScheduleData(
      allocations: List<Map<String, dynamic>>.from(json['allocations']),
    );
  }

  bool isDateAvailable(DateTime date) {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    return allocations.any((allocation) => allocation['date'] == dateString);
  }

  Map<int, String>? getBayAssignments(DateTime date) {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    final allocation = allocations.firstWhere(
      (allocation) => allocation['date'] == dateString,
      orElse: () => {},
    );
    if (allocation.isNotEmpty) {
      return (allocation['bays'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(int.parse(key), value.toString()));
    }
    return null;
  }

  DateTime getEarliestAvailableDate() {
    if (allocations.isEmpty) return DateTime.now();
    final dateStrings =
        allocations.map((allocation) => allocation['date']).toList();
    dateStrings.sort();
    return DateFormat('yyyy-MM-dd').parse(dateStrings.first);
  }
}

class DaySelectionWidget extends StatelessWidget {
  final ScheduleProvider provider;

  const DaySelectionWidget({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final initialDate =
            provider.scheduleData?.getEarliestAvailableDate() ?? DateTime.now();
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(2024, 1, 1),
          lastDate: DateTime(2024, 12, 31),
          selectableDayPredicate: (date) {
            return provider.scheduleData?.isDateAvailable(date) ?? false;
          },
        );
        if (selectedDate != null) {
          provider.setSelectedDate(selectedDate);
          Navigator.pushNamed(context, '/bay-assignments');
        }
      },
      child: Text(provider.selectedDate != null
          ? DateFormat('yyyy-MM-dd').format(provider.selectedDate!)
          : 'Pick a date'),
    );
  }
}

class BayAssignmentWidget extends StatelessWidget {
  final ScheduleProvider provider;

  const BayAssignmentWidget({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final assignments = provider.selectedDate != null
        ? provider.scheduleData?.getBayAssignments(provider.selectedDate!)
        : {};

    if (assignments == null || assignments.isEmpty) {
      return const Center(
        child: Text(
            'No assignments available for the selected date. Park where ever you like!'),
      );
    }

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
        child: Selector<ScheduleProvider, DateTime?>(
          selector: (_, provider) => provider.selectedDate,
          builder: (context, selectedDate, child) {
            if (selectedDate == null) {
              return const Center(
                child: Text('No date selected'),
              );
            }

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
  DateTime? _selectedDate;

  ScheduleData? get scheduleData => _scheduleData;
  DateTime? get selectedDate => _selectedDate;

  void loadScheduleData(ScheduleData scheduleData) {
    _scheduleData = scheduleData;
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }
}
