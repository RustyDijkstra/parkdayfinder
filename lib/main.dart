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
    initializeSchedule();
  }

  Future<void> initializeSchedule() async {
    final provider = context.read<ScheduleProvider>();
    provider.generateSchedule();

    try {
      final scheduleData = await loadScheduleDataFromSource();
      provider.loadScheduleData(scheduleData);
    } catch (e) {
      print('Error loading schedule data: $e');
    }
  }

  Future<ScheduleData> loadScheduleDataFromSource() async {
    final jsonData = await rootBundle.loadString('assets/schedule.json');
    final scheduleData = ScheduleData.fromJson(jsonDecode(jsonData));
    return scheduleData;
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

  void overwriteAllocations(List<Map<String, dynamic>> newAllocations) {
    for (var newAllocation in newAllocations) {
      final date = newAllocation['date'];
      final index =
          allocations.indexWhere((allocation) => allocation['date'] == date);
      if (index != -1) {
        allocations[index] = newAllocation;
      } else {
        allocations.add(newAllocation);
      }
    }
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
          lastDate: DateTime(2025, 12, 31), // Adjusted to allow 2025 dates
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
      crossAxisCount: 4,
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
    _scheduleData?.overwriteAllocations(scheduleData.allocations);
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void generateSchedule() {
    final List<Map<String, dynamic>> allocations = [];

    DateTime startDate = DateTime(2024, 3, 18);
    const List<String> firstWeekMonday = [
      'Leah',
      'Frans',
      'Stratton',
      'Kieran'
    ];
    const List<String> firstWeekTuesday = ['Leah', 'Michelle', 'Cam', 'Jeffry'];
    const List<String> firstWeekFriday = [
      'Leah',
      'Frans',
      'Stratton',
      'Adam M'
    ];
    const List<String> secondWeekMonday = [
      'Leah',
      'Frans',
      'Stratton',
      'Kieran'
    ];
    const List<String> secondWeekTuesday = [
      'Leah',
      'Michelle',
      'Cam',
      'Jeffry'
    ];
    const List<String> secondWeekFriday = ['Leah', 'Jeffry', 'Cam', 'Adam M'];

    for (int week = 0; week < 104; week++) {
      // Adjusted to cover 2 years (52 weeks/year * 2)
      bool isFirstWeek = week % 2 == 0;
      DateTime monday = startDate.add(Duration(days: week * 7));
      DateTime tuesday = monday.add(const Duration(days: 1));
      DateTime friday = monday.add(const Duration(days: 4));

      if (isFirstWeek) {
        allocations.addAll([
          {
            'date': DateFormat('yyyy-MM-dd').format(monday),
            'bays': {
              '12': firstWeekMonday[0],
              '14': firstWeekMonday[1],
              '13': firstWeekMonday[2],
              '11': firstWeekMonday[3]
            }
          },
          {
            'date': DateFormat('yyyy-MM-dd').format(tuesday),
            'bays': {
              '12': firstWeekTuesday[0],
              '14': firstWeekTuesday[1],
              '13': firstWeekTuesday[2],
              '11': firstWeekTuesday[3]
            }
          },
          {
            'date': DateFormat('yyyy-MM-dd').format(friday),
            'bays': {
              '12': firstWeekFriday[0],
              '14': firstWeekFriday[1],
              '13': firstWeekFriday[2],
              '11': firstWeekFriday[3]
            }
          },
        ]);
      } else {
        allocations.addAll([
          {
            'date': DateFormat('yyyy-MM-dd').format(monday),
            'bays': {
              '12': secondWeekMonday[0],
              '14': secondWeekMonday[1],
              '13': secondWeekMonday[2],
              '11': secondWeekMonday[3]
            }
          },
          {
            'date': DateFormat('yyyy-MM-dd').format(tuesday),
            'bays': {
              '12': secondWeekTuesday[0],
              '14': secondWeekTuesday[1],
              '13': secondWeekTuesday[2],
              '11': secondWeekTuesday[3]
            }
          },
          {
            'date': DateFormat('yyyy-MM-dd').format(friday),
            'bays': {
              '12': secondWeekFriday[0],
              '14': secondWeekFriday[1],
              '13': secondWeekFriday[2],
              '11': secondWeekFriday[3]
            }
          },
        ]);
      }
    }

    _scheduleData = ScheduleData(allocations: allocations);
    notifyListeners();
  }
}
