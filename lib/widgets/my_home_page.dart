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
  final TextEditingController _intervalController = TextEditingController();
  final TextEditingController _repetitionsController = TextEditingController();
  final TextEditingController _pauseController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  Timer? _timer;
  int _currentRepetition = 0;
  int _remainingTime = 0;
  String _status = "Inserisci i valori e premi Start";

  void _startTimer() {
    final int interval = int.tryParse(_intervalController.text) ?? 0;
    final int repetitions = int.tryParse(_repetitionsController.text) ?? 0;
    final int pause = int.tryParse(_pauseController.text) ?? 0;

    if (interval <= 0 || repetitions <= 0) {
      setState(() {
        _status = "Inserisci valori validi per intervallo e ripetizioni.";
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
      _status = "Timer fermato. Inserisci i valori e premi Start";
      _remainingTime = 0;
      _currentRepetition = 0;
    });
  }

  @override
  void dispose() {
    _intervalController.dispose();
    _repetitionsController.dispose();
    _pauseController.dispose();
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
            TextField(
              controller: _intervalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Intervallo (secondi)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _repetitionsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Numero di Ripetizioni',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pauseController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Pausa tra Ripetizioni (secondi)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _status,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                ElevatedButton(
                  onPressed: _startTimer,
                  style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white, // Colore del testo
                  ),
                  child: const Text('Start'),
                ),
                ElevatedButton(
                  onPressed: _stopTimer,
                  style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white, // Colore del testo
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
