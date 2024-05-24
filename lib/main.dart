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
        title: const Text(
          'mobility bay alloc',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
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

  Map<int, Person>? getBayAssignments(DateTime date) {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    final allocation = allocations.firstWhere(
      (allocation) => allocation['date'] == dateString,
      orElse: () => {},
    );
    if (allocation.isNotEmpty) {
      return (allocation['bays'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(int.parse(key), Person.fromJson(value)));
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
            padding: const EdgeInsets.all(10),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: assignments.entries.map((entry) {
              final person = entry.value;
              return Card(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Bay ${entry.key}'),
                    Text('Assigned: ${person.name}'),
                    Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              CircleAvatar(
                                // backgroundColor: Colors.blue,
                                // child: Text('Cam'),
                                backgroundImage: NetworkImage(person.picture),
                                minRadius: 30,
                                maxRadius: 45,
                              ),
                              // Image.asset(person.picture, height: 100, width: 100),
                            ]))
                  ],
                ),
              );
            }).toList(),
          ),
        const Padding(
            padding: EdgeInsets.all(10.0),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Text(
                      'Remember to mentioned in team if you are not coming in, so others can use your bay',
                      style: TextStyle(
                        fontSize: 16,
                      )),
                  Icon(
                    Icons.favorite,
                    color: Colors.pink,
                    size: 24.0,
                    semanticLabel: 'Text to announce in accessibility modes',
                  ),
                ])),
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

  bool hasAssignments(DateTime date) {
    return _scheduleData?.isDateAvailable(date) ?? false;
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

    List<Person> firstWeekMonday = [
      Person(name: 'Kieran', picture: 'assets/kieran.png'),
      Person(name: 'Leah', picture: 'assets/leah.png'),
      Person(name: 'Stratton', picture: 'assets/stratton.png'),
      Person(name: 'Frans', picture: 'assets/frans.png')
    ];
    List<Person> firstWeekTuesday = [
      Person(name: 'Jeffry', picture: 'assets/jeffry.png'),
      Person(name: 'Leah', picture: 'assets/leah.png'),
      Person(name: 'Cam', picture: 'assets/cam.png'),
      Person(name: 'Michelle', picture: 'assets/michelle.png')
    ];
    List<Person> firstWeekFriday = [
      Person(name: 'Adam M', picture: 'assets/adam_m.png'),
      Person(name: 'Leah', picture: 'assets/leah.png'),
      Person(name: 'Stratton', picture: 'assets/stratton.png'),
      Person(name: 'Frans', picture: 'assets/frans.png')
    ];
    List<Person> secondWeekMonday = [
      Person(name: 'Kieran', picture: 'assets/kieran.png'),
      Person(name: 'Leah', picture: 'assets/leah.png'),
      Person(name: 'Stratton', picture: 'assets/stratton.png'),
      Person(name: 'Frans', picture: 'assets/frans.png')
    ];
    List<Person> secondWeekTuesday = [
      Person(name: 'Jeffry', picture: 'assets/jeffry.png'),
      Person(name: 'Leah', picture: 'assets/leah.png'),
      Person(name: 'Cam', picture: 'assets/cam.png'),
      Person(name: 'Michelle', picture: 'assets/michelle.png')
    ];
    List<Person> secondWeekFriday = [
      Person(name: 'Adam M', picture: 'assets/adam_m.png'),
      Person(name: 'Leah', picture: 'assets/leah.png'),
      Person(name: 'Cam', picture: 'assets/cam.png'),
      Person(name: 'Jeffry', picture: 'assets/jeffry.png'),
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
              '11': firstWeekMonday[0].toJson(),
              '12': firstWeekMonday[1].toJson(),
              '13': firstWeekMonday[2].toJson(),
              '14': firstWeekMonday[3].toJson()
            }
          },
          {
            'date': DateFormat('yyyy-MM-dd').format(tuesday),
            'bays': {
              '11': firstWeekTuesday[0].toJson(),
              '12': firstWeekTuesday[1].toJson(),
              '13': firstWeekTuesday[2].toJson(),
              '14': firstWeekTuesday[3].toJson()
            }
          },
          {
            'date': DateFormat('yyyy-MM-dd').format(friday),
            'bays': {
              '11': firstWeekFriday[0].toJson(),
              '12': firstWeekFriday[1].toJson(),
              '13': firstWeekFriday[2].toJson(),
              '14': firstWeekFriday[3].toJson(),
            }
          },
        ]);
      } else {
        allocations.addAll([
          {
            'date': DateFormat('yyyy-MM-dd').format(monday),
            'bays': {
              '11': secondWeekMonday[0].toJson(),
              '12': secondWeekMonday[1].toJson(),
              '13': secondWeekMonday[2].toJson(),
              '14': secondWeekMonday[3].toJson()
            }
          },
          {
            'date': DateFormat('yyyy-MM-dd').format(tuesday),
            'bays': {
              '11': secondWeekTuesday[0].toJson(),
              '12': secondWeekTuesday[1].toJson(),
              '13': secondWeekTuesday[2].toJson(),
              '14': secondWeekTuesday[3].toJson(),
            }
          },
          {
            'date': DateFormat('yyyy-MM-dd').format(friday),
            'bays': {
              '11': secondWeekFriday[0].toJson(),
              '12': secondWeekFriday[1].toJson(),
              '13': secondWeekFriday[2].toJson(),
              '14': secondWeekFriday[3].toJson(),
            }
          },
        ]);
      }
    }

    _scheduleData = ScheduleData(allocations: allocations);
    notifyListeners();
  }
}

class Person {
  final String name;
  final String picture;

  Person({required this.name, required this.picture});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'picture': picture,
    };
  }

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      name: json['name'],
      picture: json['picture'],
    );
  }
}
