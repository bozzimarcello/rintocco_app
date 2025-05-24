import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:uuid/uuid.dart';
import '../models/timer_setup.dart';
import './saved_setups_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _dialogSetupNameController = TextEditingController(); // Controller per il dialogo
  final Uuid _uuid = Uuid();

  Timer? _timer;
  int _currentRepetition = 0;
  int _remainingTime = 0;
  String _status = "Imposta i valori e premi Start";
  String? _currentLoadedSetupName; // Nome del setup caricato

  int _intervalValue = 30;
  int _repetitionsValue = 5;
  int _pauseValue = 10;

  List<TimerSetup> _savedSetups = [];

  @override
  void initState() {
    super.initState();
    _loadSetups();
  }

  Future<void> _loadSetups() async {
    _savedSetups = await loadTimerSetups();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _performSaveSetup(String name) async {
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Il nome del setup non può essere vuoto.')),
      );
      return;
    }
    final newSetup = TimerSetup(
      id: _uuid.v4(),
      name: name,
      interval: _intervalValue,
      repetitions: _repetitionsValue,
      pause: _pauseValue,
    );
    setState(() {
      _savedSetups.add(newSetup);
    });
    await saveTimerSetups(_savedSetups);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Setup "$name" salvato!')),
    );
  }

  Future<void> _showSaveSetupDialog() async {
    _dialogSetupNameController.clear(); // Pulisci il controller prima di usarlo
    final String? setupName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Salva Rintocco'),
          content: TextField(
            controller: _dialogSetupNameController,
            autofocus: true,
            decoration: const InputDecoration(hintText: "Nome del Rintocco"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annulla'),
              onPressed: () {
                Navigator.of(context).pop(); // Chiude il dialogo senza restituire nulla
              },
            ),
            TextButton(
              child: const Text('Salva'),
              onPressed: () {
                Navigator.of(context).pop(_dialogSetupNameController.text); // Restituisce il nome inserito
              },
            ),
          ],
        );
      },
    );

    if (setupName != null && setupName.isNotEmpty) {
      await _performSaveSetup(setupName);
    } else if (setupName != null && setupName.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Il nome del rintocco non può essere vuoto. Salvataggio annullato.')),
      );
    }
  }

  void _applySetup(TimerSetup setup) {
    setState(() {
      _intervalValue = setup.interval;
      _repetitionsValue = setup.repetitions;
      _pauseValue = setup.pause;
      _currentLoadedSetupName = setup.name; // Imposta il nome del setup caricato
      _status = "Rintocco '${setup.name}' caricato.\nPremi Start.";
    });
  }

  void _deleteSetup(String id) async {
    final setupToDelete = _savedSetups.firstWhere((s) => s.id == id, orElse: () => TimerSetup(id: '', name: '', interval: 0, repetitions: 0, pause: 0));
    if (_currentLoadedSetupName == setupToDelete.name) {
        setState(() {
            _currentLoadedSetupName = null;
        });
    }
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

    // Se un setup era caricato e i valori sono ancora quelli, usa il nome del setup.
    // Altrimenti, se i valori sono stati cambiati o nessun setup è caricato, non mostrare un nome specifico.
    String timerDisplayName = _currentLoadedSetupName ?? "Timer";
    if (_currentLoadedSetupName != null) {
        final loadedSetup = _savedSetups.firstWhere((s) => s.name == _currentLoadedSetupName, orElse: () => TimerSetup(id: '', name: '', interval: -1, repetitions: -1, pause: -1));
        if (loadedSetup.interval != _intervalValue || loadedSetup.repetitions != _repetitionsValue || loadedSetup.pause != _pauseValue) {
            timerDisplayName = "Timer personalizzato"; // O semplicemente "Timer"
        }
    }

    if (interval <= 0 || repetitions <= 0) {
      setState(() {
        _status = "L'intervallo e le ripetizioni devono essere maggiori di 0.";
      });
      return;
    }

    _currentRepetition = 0;
    _startRepetition(interval, repetitions, pause, timerDisplayName);
  }

  void _startRepetition(int interval, int repetitions, int pause, String timerDisplayName) {
    if (_currentRepetition < repetitions) {
      _currentRepetition++;
      _remainingTime = interval;
      setState(() {
        _status =
            "$timerDisplayName: Ripetizione $_currentRepetition di $repetitions\n$_remainingTime s";
      });
      _timer?.cancel(); // Cancella timer precedenti se presenti
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_remainingTime > 0) {
            _remainingTime--;
            _status =
                "$timerDisplayName: Ripetizione $_currentRepetition di $repetitions\n$_remainingTime s";
          } else {
            timer.cancel();
            _playSound();
            if (_currentRepetition < repetitions) {
              _startPause(interval, repetitions, pause, timerDisplayName);
            } else {
              _status = "$timerDisplayName: Completato!";
              _currentLoadedSetupName = null; // Resetta il nome del setup dopo il completamento
            }
          }
        });
      });
    }
  }

  void _playSound() async {
    try {
      await _audioPlayer.play(AssetSource('hotel-bell-334109.mp3'));
      // print("Suono riprodotto"); // Rimosso per pulizia console
    } catch (e) {
      print("Errore durante la riproduzione del suono: $e");
      setState(() {
        _status = "Errore audio: $e";
      });
    }
  }

  void _startPause(int interval, int repetitions, int pause, String timerDisplayName) {
    if (pause > 0) {
      _remainingTime = pause;
      setState(() {
        _status = "$timerDisplayName: Pausa: $_remainingTime s";
      });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_remainingTime > 0) {
            _remainingTime--;
            _status = "$timerDisplayName: Pausa: $_remainingTime s";
          } else {
            timer.cancel();
            _startRepetition(interval, repetitions, pause, timerDisplayName);
          }
        });
      });
    } else {
      _startRepetition(interval, repetitions, pause, timerDisplayName);
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _status = "Timer fermato.\nImposta i valori e premi Start";
      _remainingTime = 0;
      _currentRepetition = 0;
      // Non resettare _currentLoadedSetupName qui, l'utente potrebbe voler riavviare lo stesso setup.
      // _currentLoadedSetupName = null; 
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    _dialogSetupNameController.dispose(); // Dispose del nuovo controller
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
            onChanged: (value) {
              onChanged(value);
              // Se un setup è caricato e l'utente cambia un valore, resetta il nome del setup caricato
              // e aggiorna lo status per indicare che è una nuova configurazione.
              if (_currentLoadedSetupName != null) {
                final loadedSetup = _savedSetups.firstWhere((s) => s.name == _currentLoadedSetupName, orElse: () => TimerSetup(id: '', name: '', interval: -1, repetitions: -1, pause: -1) );
                bool changed = false;
                if (label.startsWith('Intervallo') && value != loadedSetup.interval) changed = true;
                if (label.startsWith('Ripetizioni') && value != loadedSetup.repetitions) changed = true;
                if (label.startsWith('Pausa') && value != loadedSetup.pause) changed = true;

                if (changed) {
                    setState(() {
                        _currentLoadedSetupName = null;
                        _status = "Valori modificati. Premi Start o Salva Rintocco.";
                    });
                }
              }
            },
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
    double buttonSize = 120.0;
    double borderRadius = 20.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Rintocchi Salvati',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SavedSetupsPage(
                    setups: _savedSetups,
                    onApplySetup: (setup) { 
                        _applySetup(setup);
                        // Navigator.pop(context); // RIMOSSO: SavedSetupsPage gestisce il pop
                    },
                    onDeleteSetup: _deleteSetup,
                  ),
                ),
              );
              // Se result è true (da SavedSetupsPage dopo apply o delete che modifica la lista),
              // ricarichiamo i setup per riflettere i cambiamenti (specialmente le eliminazioni).
              if (result == true) { 
                _loadSetups(); 
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Text(
                _currentLoadedSetupName ?? "Nuovo Rintocco",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildNumberPickerColumn(
                    'Intervallo\n(sec)',
                    _intervalValue,
                    1,
                    180,
                    (value) => setState(() => _intervalValue = value),
                  ),
                  _buildNumberPickerColumn(
                    'Ripetizioni\n',
                    _repetitionsValue,
                    1,
                    50,
                    (value) => setState(() => _repetitionsValue = value),
                  ),
                  _buildNumberPickerColumn(
                    'Pausa\n(sec)',
                    _pauseValue,
                    0,
                    120,
                    (value) => setState(() => _pauseValue = value),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _showSaveSetupDialog, // Modificato per chiamare il dialogo
                child: const Text('Salva Rintocco Corrente'),
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
            ],
          ),
        ),
      ),
    );
  }
}
