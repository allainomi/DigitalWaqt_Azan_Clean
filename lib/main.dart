import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'prayer_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  runApp(const DigitalWaqtAzanApp());
}

class DigitalWaqtAzanApp extends StatelessWidget {
  const DigitalWaqtAzanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Waqt Azan',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _timer;
  DateTime _now = DateTime.now();
  final player = AudioPlayer();
  final prayerService = PrayerService();
  Map<String, String> times = {};
  bool notificationsScheduled = false;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _now = DateTime.now();
      });
    });

    times = prayerService.getTodayTimes();
  }

  @override
  void dispose() {
    _timer.cancel();
    player.dispose();
    super.dispose();
  }

  Future<void> playAzan() async {
    // Play bundled azan file from assets
    await player.play(AssetSource('assets/sounds/azan_manual.mp3'));
  }

  Future<void> scheduleSampleNotification() async {
    final scheduled = DateTime.now().add(const Duration(seconds: 10));
    final tzDate = tz.TZDateTime.from(scheduled, tz.local);
    const androidDetails = AndroidNotificationDetails(
      'azan_channel',
      'Azan Notifications',
      channelDescription: 'Channel for Azan reminders',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const details = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Azan Reminder',
      'This is a scheduled sample Azan reminder',
      tzDate,
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    setState(() {
      notificationsScheduled = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final timeString = DateFormat.Hms().format(_now);
    final dateString = DateFormat.yMMMMEEEEd().format(_now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Waqt Azan'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                child: Column(
                  children: [
                    Text(dateString, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(timeString,
                        style: const TextStyle(
                            fontSize: 48, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Local timezone: ' + tz.local.name),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Prayer Times (Today)',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                      const Divider(),
                      ...times.entries.map((e) => ListTile(
                            leading: const Icon(Icons.access_time),
                            title: Text(e.key),
                            trailing: Text(e.value),
                          )),
                      const Spacer(),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: playAzan,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Play Azan'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await scheduleSampleNotification();
                            },
                            icon: const Icon(Icons.notifications_active),
                            label: Text(notificationsScheduled
                                ? 'Scheduled'
                                : 'Schedule Sample Notification'),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Tip: Edit lib/prayer_service.dart to supply real prayer times',
                style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}