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
      child: const MaterialApp(
        title: 'mobility bay alloc',
        home: HomeScreen(),
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

      // Set the selected date to the closest available date
      provider.setSelectedDate(DateTime.now());
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
        title: const Text('mobility bay alloc'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Date:',
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
            Consumer<ScheduleProvider>(
              builder: (context, provider, child) {
                return provider.selectedDate != null
                    ? BayAssignmentWidget(provider: provider)
                    : const Center(child: Text('No date selected'));
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
        DateTime initialDate = DateTime.now();

        // Find the nearest date with assignments
        if (!provider.hasAssignments(initialDate)) {
          final closestDateWithAssignment =
              _findClosestDateWithAssignments(provider, initialDate);
          if (closestDateWithAssignment != null) {
            initialDate = closestDateWithAssignment;
          }
        }

        final selectedDate = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(2024, 1, 1),
          lastDate: DateTime(2025, 12, 31),
          selectableDayPredicate: (date) {
            return provider.hasAssignments(date);
          },
        );

        if (selectedDate != null) {
          provider.setSelectedDate(selectedDate);
        }
      },
      child: Text(provider.selectedDate != null
          ? DateFormat('yyyy-MM-dd').format(provider.selectedDate!)
          : 'Pick a date'),
    );
  }

  DateTime? _findClosestDateWithAssignments(
      ScheduleProvider provider, DateTime startDate) {
    final schedule = provider.scheduleData;
    if (schedule == null) return null;

    final dates = schedule.allocations.map((allocation) {
      return DateFormat('yyyy-MM-dd').parse(allocation['date']);
    }).toList();

    dates.sort((a, b) => a.compareTo(b));

    for (DateTime date in dates) {
      if (date.isAfter(startDate) || date.isAtSameMomentAs(startDate)) {
        return date;
      }
    }

    return dates.isNotEmpty ? dates.first : null;
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

    final dayOfWeek = DateFormat('EEEE').format(provider.selectedDate!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Allocation for ${DateFormat('EEEE, yyyy-MM-dd').format(provider.selectedDate!)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (assignments == null || assignments.isEmpty)
          const Center(
            child: Text(
                'No assignments available for the selected date. Park where ever you like!'),
          )
        else
          GridView.count(
            shrinkWrap: true,
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
          ),
      ],
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

    // Get the current year
    final currentYear = DateTime.now().year;

    // Set the start date to March 18th of the current year
    DateTime startDate = DateTime(currentYear, 3, 18);

    const List<String> firstWeekMonday = [
      'Kieran',
      'Leah',
      'Stratton',
      'Frans'
    ];
    const List<String> firstWeekTuesday = ['Jeffry', 'Leah', 'Cam', 'Michelle'];
    const List<String> firstWeekFriday = [
      'Adam M',
      'Leah',
      'Stratton',
      'Frans'
    ];
    const List<String> secondWeekMonday = [
      'Kieran',
      'Leah',
      'Stratton',
      'Frans'
    ];
    const List<String> secondWeekTuesday = [
      'Jeffry',
      'Leah',
      'Cam',
      'Michelle'
    ];
    const List<String> secondWeekFriday = [
      'Adam M',
      'Leah',
      'Cam',
      'Jeffry',
    ];

    for (int week = 0; week < 104; week++) {
      bool isFirstWeek = week % 2 == 0;
      DateTime monday = startDate.add(Duration(days: week * 7));
      DateTime tuesday = monday.add(const Duration(days: 1));
      DateTime friday = monday.add(const Duration(days: 4));

      if (isFirstWeek) {
        allocations.addAll([
          {
            'date': DateFormat('yyyy-MM-dd').format(monday),
            'bays': {
              '11': firstWeekMonday[0],
              '12': firstWeekMonday[1],
              '13': firstWeekMonday[2],
              '14': firstWeekMonday[3]
            }
          },
          {
            'date': DateFormat('yyyy-MM-dd').format(tuesday),
            'bays': {
              '11': firstWeekTuesday[0],
              '12': firstWeekTuesday[1],
              '13': firstWeekTuesday[2],
              '14': firstWeekTuesday[3]
            }
          },
          {
            'date': DateFormat('yyyy-MM-dd').format(friday),
            'bays': {
              '11': firstWeekFriday[0],
              '12': firstWeekFriday[1],
              '13': firstWeekFriday[2],
              '14': firstWeekFriday[3],
            }
          },
        ]);
      } else {
        allocations.addAll([
          {
            'date': DateFormat('yyyy-MM-dd').format(monday),
            'bays': {
              '11': secondWeekMonday[0],
              '12': secondWeekMonday[1],
              '13': secondWeekMonday[2],
              '14': secondWeekMonday[3]
            }
          },
          {
            'date': DateFormat('yyyy-MM-dd').format(tuesday),
            'bays': {
              '11': secondWeekTuesday[0],
              '12': secondWeekTuesday[1],
              '13': secondWeekTuesday[2],
              '14': secondWeekTuesday[3],
            }
          },
          {
            'date': DateFormat('yyyy-MM-dd').format(friday),
            'bays': {
              '11': secondWeekFriday[0],
              '12': secondWeekFriday[1],
              '13': secondWeekFriday[2],
              '14': secondWeekFriday[3],
            }
          },
        ]);
      }
    }

    _scheduleData = ScheduleData(allocations: allocations);
    notifyListeners();
  }

  bool hasAssignments(DateTime date) {
    return _scheduleData?.isDateAvailable(date) ?? false;
  }
}
