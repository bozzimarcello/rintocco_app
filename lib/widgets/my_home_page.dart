import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

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

  double _intervalValue = 30.0; // Valore predefinito per l'intervallo
  double _repetitionsValue = 5.0; // Valore predefinito per le ripetizioni
  double _pauseValue = 10.0; // Valore predefinito per la pausa

  void _startTimer() {
    // Leggi i valori dagli Slider
    final int interval = _intervalValue.round();
    final int repetitions = _repetitionsValue.round();
    final int pause = _pauseValue.round();

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
        _status = "Ripetizione $_currentRepetition di $repetitions: $_remainingTime s";
      });
      _timer?.cancel(); // Cancella timer precedenti se presenti
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_remainingTime > 0) {
            _remainingTime--;
            _status = "Ripetizione $_currentRepetition di $repetitions: $_remainingTime s";
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
      // Assicurati che il nome del file sia corretto e che sia nella cartella assets
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
      _status = "Timer fermato. Imposta i valori e premi Start";
      _remainingTime = 0;
      _currentRepetition = 0;
    });
  }

  @override
  void dispose() {
    // Rimuovi i dispose dei controller
    // _intervalController.dispose();
    // _repetitionsController.dispose();
    // _pauseController.dispose();
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Intervallo: ${_intervalValue.round()} secondi'),
            Slider(
              value: _intervalValue,
              min: 1,
              max: 180, // Massimo 3 minuti
              divisions: 179,
              label: _intervalValue.round().toString(),
              onChanged: (double value) {
                setState(() {
                  _intervalValue = value;
                });
              },
            ),
            const SizedBox(height: 20),
            Text('Numero di Ripetizioni: ${_repetitionsValue.round()}'),
            Slider(
              value: _repetitionsValue,
              min: 1,
              max: 50, // Massimo 50 ripetizioni
              divisions: 49,
              label: _repetitionsValue.round().toString(),
              onChanged: (double value) {
                setState(() {
                  _repetitionsValue = value;
                });
              },
            ),
            const SizedBox(height: 20),
            Text('Pausa tra Ripetizioni: ${_pauseValue.round()} secondi'),
            Slider(
              value: _pauseValue,
              min: 0, // La pausa può essere 0
              max: 120, // Massimo 2 minuti di pausa
              divisions: 120,
              label: _pauseValue.round().toString(),
              onChanged: (double value) {
                setState(() {
                  _pauseValue = value;
                });
              },
            ),
            const SizedBox(height: 30),
            Text(
              _status,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
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
