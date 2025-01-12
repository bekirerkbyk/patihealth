import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:table_calendar/table_calendar.dart';

class VaccineEvent {
  final String name;
  final String note;
  final DateTime date;

  VaccineEvent({
    required this.name,
    required this.note,
    required this.date,
  });
}

class VaccineCalendarScreen extends StatefulWidget {
  const VaccineCalendarScreen({super.key});

  @override
  _VaccineCalendarScreenState createState() => _VaccineCalendarScreenState();
}

class _VaccineCalendarScreenState extends State<VaccineCalendarScreen> {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final List<int> _timeOptions = [5, 60, 3600];
  final List<String> _unitOptions = ['5 Saniye', '1 Dakika', '1 Saat'];

  int _selectedTime = 5;
  String _selectedUnit = '5 Saniye';
  Timer? _timer;

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<DateTime, List<VaccineEvent>> _events = {};

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _requestNotificationPermission();
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      final result = await Permission.notification.request();
      if (!result.isGranted) {
        _showSnackBar('Lütfen bildirim izinlerini ayarlardan etkinleştirin.');
      }
    }
  }

  int _calculateDuration() {
    switch (_selectedUnit) {
      case '5 Saniye':
        return 5;
      case '1 Dakika':
        return 60;
      case '1 Saat':
        return 3600;
      default:
        return 5;
    }
  }

  void _scheduleNotification() {
    _cancelNotification();

    if (_selectedTime <= 0 || _selectedUnit.isEmpty) {
      _showSnackBar('Lütfen geçerli bir süre ve birim seçin.');
      return;
    }

    final durationInSeconds = _calculateDuration();
    _showSnackBar('Bildirim her $_selectedTime $_selectedUnit gönderilecek.');

    _timer = Timer.periodic(Duration(seconds: durationInSeconds), (timer) {
      _showNotification();
    });
  }

  Future<void> _showNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'vaccine_notification_channel',
      'Aşı Hatırlatıcı',
      channelDescription: 'Evcil hayvan aşı hatırlatıcıları.',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      0,
      'Aşı Hatırlatma!',
      'Evcil hayvanınızın aşı takvimini kontrol etme zamanı!',
      notificationDetails,
    );
  }

  void _cancelNotification() {
    if (_timer != null) {
      _timer!.cancel();
      _showSnackBar('Zamanlanmış bildirimler iptal edildi.');
    }
  }

  void _confirmCancelNotification() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Bildirimleri İptal Et'),
          content: const Text(
              'Tüm zamanlanmış bildirimleri iptal etmek istiyor musunuz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hayır'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _cancelNotification();
              },
              child: const Text('Evet'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAddVaccineDialog(DateTime selectedDate) {
    final nameController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Aşı Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Aşı İsmi',
                ),
              ),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Notlar',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  final event = VaccineEvent(
                    name: nameController.text,
                    note: noteController.text,
                    date: selectedDate,
                  );

                  if (_events[selectedDate] == null) {
                    _events[selectedDate] = [event];
                  } else {
                    _events[selectedDate]!.add(event);
                  }
                });
                Navigator.pop(context);
              },
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );
  }

  List<VaccineEvent> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aşı Takvimi'),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Container(
        color: Colors.green[50],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                elevation: 4,
                child: TableCalendar(
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay: DateTime.utc(2025, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    _showAddVaccineDialog(selectedDay);
                  },
                  eventLoader: _getEventsForDay,
                  calendarStyle: CalendarStyle(
                    markerDecoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
              if (_selectedDay != null &&
                  _getEventsForDay(_selectedDay!).isNotEmpty)
                Expanded(
                  child: Card(
                    child: ListView(
                      children: _getEventsForDay(_selectedDay!).map((event) {
                        return ListTile(
                          title: Text(event.name),
                          subtitle: Text(event.note),
                          leading: const Icon(Icons.medical_services,
                              color: Colors.green),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ElevatedButton(
                onPressed: _scheduleNotification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: const Text(
                  'Bildirimleri Ayarla',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _confirmCancelNotification,
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: const Text(
                  'Bildirimleri İptal Et',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DropdownButton<String>(
                    value: _selectedUnit,
                    items: _unitOptions.map((unit) {
                      return DropdownMenuItem<String>(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedUnit = value!;
                      });
                    },
                  ),
                  const SizedBox(width: 20),
                  DropdownButton<int>(
                    value: _selectedTime,
                    items: _timeOptions.map((time) {
                      return DropdownMenuItem<int>(
                        value: time,
                        child: Text('$time'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTime = value!;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:table_calendar/table_calendar.dart';

class VaccineEvent {
  final String name;
  final String note;
  final DateTime date;

  VaccineEvent({
    required this.name,
    required this.note,
    required this.date,
  });
}

class VaccineCalendarScreen extends StatefulWidget {
  const VaccineCalendarScreen({super.key});

  @override
  _VaccineCalendarScreenState createState() => _VaccineCalendarScreenState();
}

class _VaccineCalendarScreenState extends State<VaccineCalendarScreen> {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final List<int> _timeOptions = [5, 60, 3600];
  final List<String> _unitOptions = ['5 Seconds', '1 Minute', '1 Hour'];

  int _selectedTime = 5;
  String _selectedUnit = '5 Seconds';
  Timer? _timer;

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<DateTime, List<VaccineEvent>> _events = {};

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _requestNotificationPermission();
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      final result = await Permission.notification.request();
      if (!result.isGranted) {
        _showSnackBar('Please enable notification permissions in settings.');
      }
    }
  }

  int _calculateDuration() {
    switch (_selectedUnit) {
      case '5 Seconds':
        return 5;
      case '1 Minute':
        return 60;
      case '1 Hour':
        return 3600;
      default:
        return 5;
    }
  }

  void _scheduleNotification() {
    _cancelNotification();

    if (_selectedTime <= 0 || _selectedUnit.isEmpty) {
      _showSnackBar('Please select a valid time and unit.');
      return;
    }

    final durationInSeconds = _calculateDuration();
    _showSnackBar(
        'Notification scheduled every $_selectedTime $_selectedUnit.');

    _timer = Timer.periodic(Duration(seconds: durationInSeconds), (timer) {
      _showNotification();
    });
  }

  Future<void> _showNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'vaccine_notification_channel',
      'Vaccine Reminder',
      channelDescription: 'Reminders for pet vaccines.',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      0,
      'Vaccine Reminder!',
      'Time to check your pet\'s vaccine schedule!',
      notificationDetails,
    );
  }

  void _cancelNotification() {
    if (_timer != null) {
      _timer!.cancel();
      _showSnackBar('Scheduled notifications canceled.');
    }
  }

  void _confirmCancelNotification() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Notifications'),
          content:
              const Text('Do you want to cancel all scheduled notifications?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _cancelNotification();
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAddVaccineDialog(DateTime selectedDate) {
    final nameController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Vaccine'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Vaccine Name',
                ),
              ),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  final event = VaccineEvent(
                    name: nameController.text,
                    note: noteController.text,
                    date: selectedDate,
                  );

                  if (_events[selectedDate] == null) {
                    _events[selectedDate] = [event];
                  } else {
                    _events[selectedDate]!.add(event);
                  }
                });
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  List<VaccineEvent> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vaccine Calendar'),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Container(
        color: Colors.green[50],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                elevation: 4,
                child: TableCalendar(
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay: DateTime.utc(2025, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    _showAddVaccineDialog(selectedDay);
                  },
                  eventLoader: _getEventsForDay,
                  calendarStyle: CalendarStyle(
                    markerDecoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
              if (_selectedDay != null &&
                  _getEventsForDay(_selectedDay!).isNotEmpty)
                Expanded(
                  child: Card(
                    child: ListView(
                      children: _getEventsForDay(_selectedDay!).map((event) {
                        return ListTile(
                          title: Text(event.name),
                          subtitle: Text(event.note),
                          leading: const Icon(Icons.medical_services,
                              color: Colors.green),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ElevatedButton(
                onPressed: _scheduleNotification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: const Text(
                  'Schedule Notifications',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _confirmCancelNotification,
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: const Text(
                  'Cancel Notifications',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DropdownButton<String>(
                    value: _selectedUnit,
                    items: _unitOptions.map((unit) {
                      return DropdownMenuItem<String>(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedUnit = value!;
                      });
                    },
                  ),
                  const SizedBox(width: 20),
                  DropdownButton<int>(
                    value: _selectedTime,
                    items: _timeOptions.map((time) {
                      return DropdownMenuItem<int>(
                        value: time,
                        child: Text('$time'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTime = value!;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}*/
