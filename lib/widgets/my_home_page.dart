import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:uuid/uuid.dart'; // Aggiunto
import '../models/timer_setup.dart'; // Aggiunto
import './saved_setups_page.dart'; // Aggiungeremo questa pagina dopo

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _setupNameController =
      TextEditingController(); // Aggiunto
  final Uuid _uuid = Uuid(); // Aggiunto

  Timer? _timer;
  int _currentRepetition = 0;
  int _remainingTime = 0;
  String _status = "Imposta i valori e premi Start";

  int _intervalValue = 30;
  int _repetitionsValue = 5;
  int _pauseValue = 10;

  List<TimerSetup> _savedSetups = []; // Aggiunto

  @override
  void initState() {
    super.initState();
    _loadSetups(); // Aggiunto
  }

  Future<void> _loadSetups() async {
    _savedSetups = await loadTimerSetups();
    setState(() {});
  }

  Future<void> _saveCurrentSetup() async {
    if (_setupNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un nome per il rintocco.')),
      );
      return;
    }
    final newSetup = TimerSetup(
      id: _uuid.v4(), // Genera un ID univoco
      name: _setupNameController.text,
      interval: _intervalValue,
      repetitions: _repetitionsValue,
      pause: _pauseValue,
    );
    setState(() {
      _savedSetups.add(newSetup);
    });
    await saveTimerSetups(_savedSetups);
    _setupNameController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rintocco salvato!')),
    );
  }

  void _applySetup(TimerSetup setup) {
    setState(() {
      _intervalValue = setup.interval;
      _repetitionsValue = setup.repetitions;
      _pauseValue = setup.pause;
      _status = "Rintocco '${setup.name}' caricato.\nPremi Start.";
    });
  }

  void _deleteSetup(String id) async {
    setState(() {
      _savedSetups.removeWhere((setup) => setup.id == id);
    });
    await saveTimerSetups(_savedSetups);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rintocco eliminato!')),
    );
  }

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
    _setupNameController.dispose(); // Aggiunto
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
    double buttonSize = 120.0; // Dimensione per i lati del quadrato
    double borderRadius = 25.0; // Raggio per gli angoli arrotondati

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Rintocchi Salvati',
            onPressed: () async {
              // Passa le funzioni di callback alla pagina dei setup salvati
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SavedSetupsPage(
                    setups: _savedSetups,
                    onApplySetup:
                        _applySetup, // Passa la funzione per applicare
                    onDeleteSetup:
                        _deleteSetup, // Passa la funzione per eliminare
                  ),
                ),
              );
              // Se la pagina SavedSetupsPage modifica la lista (es. elimina un setup),
              // ricarichiamo i setup per riflettere i cambiamenti.
              if (result == true) {
                _loadSetups();
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 15.0),
        child: SingleChildScrollView(
          // Aggiunto per evitare overflow con la tastiera
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
              const SizedBox(height: 20),
                Text(
                _status,
                style: Theme.of(context)
                  .textTheme
                  .bodyLarge, // Usa bodyLarge invece di headlineSmall
                textAlign: TextAlign.center,
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _startTimer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      fixedSize: Size(buttonSize,
                          buttonSize), // Imposta la dimensione fissa per un quadrato
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            borderRadius), // Angoli molto arrotondati
                      ),
                      padding: EdgeInsets
                          .zero, // Rimuovi padding extra se necessario per il testo
                    ),
                    child: const Text(
                      'Start',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ), // Aumenta leggermente il testo se necessario
                  ),
                  ElevatedButton(
                    onPressed: _stopTimer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      fixedSize: Size(buttonSize,
                          buttonSize), // Imposta la dimensione fissa per un quadrato
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            borderRadius), // Angoli molto arrotondati
                      ),
                      padding: EdgeInsets
                          .zero, // Rimuovi padding extra se necessario per il testo
                    ),
                    child: const Text('Stop',
                        style: TextStyle(
                            fontSize:
                                18)), // Aumenta leggermente il testo se necessario
                  ),
                ],
              ),
              const SizedBox(height: 50),
              TextField(
                controller: _setupNameController,
                decoration: const InputDecoration(
                  labelText: 'Nome del Rintocco',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _saveCurrentSetup,
                child: const Text('Salva Rintocco Corrente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
