import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:numberpicker/numberpicker.dart'; // Importa numberpicker

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  Timer? _timer;
  int _currentRepetition = 0;
  int _remainingTime = 0;
  String _status = "Imposta i valori e premi Start";

  // Valori per i NumberPicker
  int _intervalValue = 30; // Valore predefinito per l'intervallo in secondi
  int _repetitionsValue = 5; // Valore predefinito per le ripetizioni
  int _pauseValue = 10; // Valore predefinito per la pausa in secondi

  void _startTimer() {
    // Leggi i valori dai NumberPicker (già interi)
    final int interval = _intervalValue;
    final int repetitions = _repetitionsValue;
    final int pause = _pauseValue;

    if (interval <= 0 || repetitions <= 0) {
      setState(() {
        _status = "L'intervallo e le ripetizioni devono essere maggiori di 0.";
      });
      return;
    }

    _currentRepetition = 0;
    _startRepetition(interval, repetitions, pause);
  }

  void _startRepetition(int interval, int repetitions, int pause) {
    if (_currentRepetition < repetitions) {
      _currentRepetition++;
      _remainingTime = interval;
      setState(() {
        _status =
            "Ripetizione $_currentRepetition di $repetitions\n$_remainingTime s";
      });
      _timer?.cancel(); // Cancella timer precedenti se presenti
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_remainingTime > 0) {
            _remainingTime--;
            _status =
                "Ripetizione $_currentRepetition di $repetitions\n$_remainingTime s";
          } else {
            timer.cancel();
            _playSound();
            if (_currentRepetition < repetitions) {
              _startPause(interval, repetitions, pause);
            } else {
              _status = "Completato!";
            }
          }
        });
      });
    }
  }

  void _playSound() async {
    try {
      await _audioPlayer.play(AssetSource('hotel-bell-334109.mp3'));
      print("Suono riprodotto");
    } catch (e) {
      print("Errore durante la riproduzione del suono: $e");
      setState(() {
        _status = "Errore audio: $e";
      });
    }
  }

  void _startPause(int interval, int repetitions, int pause) {
    if (pause > 0) {
      _remainingTime = pause;
      setState(() {
        _status = "Pausa: $_remainingTime s";
      });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_remainingTime > 0) {
            _remainingTime--;
            _status = "Pausa: $_remainingTime s";
          } else {
            timer.cancel();
            _startRepetition(interval, repetitions, pause);
          }
        });
      });
    } else {
      _startRepetition(interval, repetitions, pause);
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _status = "Timer fermato.\nImposta i valori e premi Start";
      _remainingTime = 0;
      _currentRepetition = 0;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Widget _buildNumberPickerColumn(String label, int currentValue, int minValue,
      int maxValue, ValueChanged<int> onChanged) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Padding(
          padding:
              const EdgeInsets.all(6.0), // Piccolo padding attorno al border
          child: NumberPicker(
            value: currentValue,
            minValue: minValue,
            maxValue: maxValue,
            onChanged: onChanged,
            itemHeight: 50,
            itemWidth: 60,
            axis: Axis.vertical, // o Axis.horizontal
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildNumberPickerColumn(
                  'Intervallo\n(sec)',
                  _intervalValue,
                  1, // Minimo 1 secondo
                  180, // Massimo 3 minuti
                  (value) => setState(() => _intervalValue = value),
                ),
                _buildNumberPickerColumn(
                  'Ripetizioni\n',
                  _repetitionsValue,
                  1, // Minimo 1 ripetizione
                  50, // Massimo 50 ripetizioni
                  (value) => setState(() => _repetitionsValue = value),
                ),
                _buildNumberPickerColumn(
                  'Pausa\n(sec)',
                  _pauseValue,
                  0, // La pausa può essere 0
                  120, // Massimo 2 minuti
                  (value) => setState(() => _pauseValue = value),
                ),
              ],
            ),
            Text(
              _status,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _startTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Start'),
                ),
                ElevatedButton(
                  onPressed: _stopTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Stop'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
