import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'constants.dart';
import 'package:lottie/lottie.dart';

class ElevationScreen extends StatelessWidget {
  const ElevationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Color shadowColor = Theme.of(context).colorScheme.shadow;
    Color surfaceTint = Theme.of(context).colorScheme.primary;
    return Expanded(
      child: CustomScrollView(
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate(<Widget>[
              const SizedBox(height: 10),
              Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Select Date: ',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Consumer<ScheduleProvider>(
                          builder: (context, provider, child) {
                            return DaySelectionWidget(provider: provider);
                          },
                        ),
                      ])),
            ]),
          ),
          SliverList(
            delegate: SliverChildListDelegate(<Widget>[
              const SizedBox(height: 10),
              Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Consumer<ScheduleProvider>(
                          builder: (context, provider, child) {
                            return SelectedDateWidget(provider: provider);
                          },
                        ),
                      ])),
            ]),
          ),
          Consumer<ScheduleProvider>(
            builder: (context, provider, child) {
              return ElevationGrid(
                  shadowColor: shadowColor,
                  surfaceTintColor: surfaceTint,
                  provider: provider);
            },
          ),
        ],
      ),
    );
  }
}

const double narrowScreenWidthThreshold = 450;

class ElevationGrid extends StatelessWidget {
  const ElevationGrid(
      {super.key, this.shadowColor, this.surfaceTintColor, this.provider});

  final Color? shadowColor;
  final Color? surfaceTintColor;
  final ScheduleProvider? provider;

  List<ElevationCard> elevationCards(
      Color? shadowColor, Color? surfaceTintColor, ScheduleProvider? provider) {
    final assignments = provider != null &&
            provider.selectedDate != null &&
            provider.scheduleData != null
        ? provider.scheduleData?.getBayAssignments(provider.selectedDate!)
        : {};

    if (assignments == null || assignments.isEmpty) {
      return elevations
          .map(
            (elevationInfo) => ElevationCard(
              info: elevationInfo,
              shadowColor: shadowColor,
              surfaceTint: surfaceTintColor,
            ),
          )
          .toList();
    } else {
      return assignments.entries
          .map((entry) {
            final person = entry.value;
            return ElevationInfo(
                1, 2, 3, entry.key, person.name, person.picture);
          })
          .toList()
          .map(
            (elevationInfo) => ElevationCard(
              info: elevationInfo,
              shadowColor: shadowColor,
              surfaceTint: surfaceTintColor,
            ),
          )
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(8),
      sliver: SliverLayoutBuilder(builder: (context, constraints) {
        if (constraints.crossAxisExtent < narrowScreenWidthThreshold) {
          return SliverGrid.count(
            crossAxisCount: 2,
            children: elevationCards(shadowColor, surfaceTintColor, provider),
          );
        } else {
          return SliverGrid.count(
            crossAxisCount: 4,
            children: elevationCards(shadowColor, surfaceTintColor, provider),
          );
        }
      }),
    );
  }
}

class ElevationCard extends StatefulWidget {
  const ElevationCard(
      {super.key, required this.info, this.shadowColor, this.surfaceTint});

  final ElevationInfo info;
  final Color? shadowColor;
  final Color? surfaceTint;

  @override
  State<ElevationCard> createState() => _ElevationCardState();
}

class _ElevationCardState extends State<ElevationCard> {
  late double _elevation;

  @override
  void initState() {
    super.initState();
    _elevation = widget.info.elevation;
  }

  @override
  Widget build(BuildContext context) {
    const BorderRadius borderRadius = BorderRadius.all(Radius.circular(4.0));
    final Color color = Theme.of(context).colorScheme.surface;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Material(
        borderRadius: borderRadius,
        elevation: _elevation,
        color: color,
        shadowColor: widget.shadowColor,
        surfaceTintColor: widget.surfaceTint,
        type: MaterialType.card,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Bay: ${widget.info.bay}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              Text(
                widget.info.allocatedTo.isEmpty != true
                    ? 'Allocated to: ${widget.info.allocatedTo}'
                    : "Unallocated",
                style: Theme.of(context).textTheme.labelMedium,
              ),
              if (widget.info.allocatedTo.isEmpty != true)
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: CircleAvatar(
                      // backgroundImage: NetworkImage(widget.info.pictureUrl),
                      minRadius: 30,
                      maxRadius: 45,
                      child: Text(widget.info.allocatedTo
                          .substring(0, 2)
                          .toUpperCase()),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: FilledButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Notice'),
                              content: Text(
                                  'Please login to reserve Bay ${widget.info.bay}'),
                              actions: <Widget>[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Text(
                                                      'Sign up/in has not been implemented yet. Buy Stratton a coffee and he\'ll get it up.'),
                                                  const SizedBox(height: 20),
                                                  Lottie.asset(
                                                    'assets/underconstruction.json',
                                                    width: 300,
                                                    height: 300,
                                                    fit: BoxFit.scaleDown,
                                                  ),
                                                ],
                                              ),
                                              actions: <Widget>[
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Text('Ok'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      child: const Text('Sign In'),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: const Text('Claim it now!'),
                    ),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}

class ElevationInfo {
  const ElevationInfo(this.level, this.elevation, this.overlayPercent, this.bay,
      this.allocatedTo, this.pictureUrl);
  final int level;
  final double elevation;
  final int overlayPercent;
  final int bay;
  final String allocatedTo;
  final String pictureUrl;
}

const List<ElevationInfo> elevations = <ElevationInfo>[
  ElevationInfo(1, 1.0, 0, 11, "", "NA"),
  ElevationInfo(1, 1.0, 5, 12, "", "NA"),
  ElevationInfo(1, 1.0, 8, 13, "", "NA"),
  ElevationInfo(1, 1.0, 11, 14, "", "NA")
];

// OTHERS

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
        DateTime initialDate = provider
            ._selectedDate!; // hold on to the last selected date rather than getting the next available allocation

        // // Find the nearest date with assignments
        // if (!provider.hasAssignments(initialDate)) {
        //   final closestDateWithAssignment =
        //       _findClosestDateWithAssignments(provider, initialDate);
        //   if (closestDateWithAssignment != null) {
        //     initialDate = closestDateWithAssignment;
        //   }
        // }

        final selectedDate = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(2024, 1, 1),
          lastDate: DateTime(2025, 12, 31),
          selectableDayPredicate: (date) {
            // return provider.hasAssignments(date); // will hide other dates that has no allocation
            return true;
          },
        );

        if (selectedDate != null) {
          provider.setSelectedDate(selectedDate);
        }
      },
      child: Text(provider.selectedDate != null
          ? DateFormat(dateFormat).format(provider.selectedDate!)
          : 'Pick a date'),
    );
  }

  DateTime? _findClosestDateWithAssignments(
      ScheduleProvider provider, DateTime startDate) {
    final schedule = provider.scheduleData;
    if (schedule == null) return null;

    final dates = schedule.allocations.map((allocation) {
      return DateFormat(dateFormat).parse(allocation['date']);
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

class SelectedDateWidget extends StatelessWidget {
  final ScheduleProvider provider;
  const SelectedDateWidget({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Text(
      provider.selectedDate != null
          ? 'Allocation for ${DateFormat('EEEE, dd-MM-yyyy').format(provider.selectedDate!)}'
          : "No date selected",
      style: Theme.of(context).textTheme.bodyMedium,
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
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
