import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TimerSetup {
  String id; // Identificatore univoco per ogni setup
  String name;
  int interval;
  int repetitions;
  int pause;

  TimerSetup({
    required this.id,
    required this.name,
    required this.interval,
    required this.repetitions,
    required this.pause,
  });

  // Metodo per convertire un TimerSetup in una mappa (per JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'interval': interval,
      'repetitions': repetitions,
      'pause': pause,
    };
  }

  // Metodo factory per creare un TimerSetup da una mappa (da JSON)
  factory TimerSetup.fromJson(Map<String, dynamic> json) {
    return TimerSetup(
      id: json['id'] as String,
      name: json['name'] as String,
      interval: json['interval'] as int,
      repetitions: json['repetitions'] as int,
      pause: json['pause'] as int,
    );
  }
}

// Funzione helper per salvare la lista di TimerSetup
Future<void> saveTimerSetups(List<TimerSetup> setups) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> setupsJson = setups.map((s) => jsonEncode(s.toJson())).toList();
  await prefs.setStringList('timer_setups', setupsJson);
}

// Funzione helper per caricare la lista di TimerSetup
Future<List<TimerSetup>> loadTimerSetups() async {
  final prefs = await SharedPreferences.getInstance();
  List<String>? setupsJson = prefs.getStringList('timer_setups');
  if (setupsJson == null) {
    return [];
  }
  return setupsJson.map((s) => TimerSetup.fromJson(jsonDecode(s) as Map<String, dynamic>)).toList();
}
