import 'package:flutter/material.dart';
import '../models/timer_setup.dart';

typedef OnApplySetupCallback = void Function(TimerSetup setup);
typedef OnDeleteSetupCallback = void Function(String id);

class SavedSetupsPage extends StatefulWidget {
  final List<TimerSetup> setups;
  final OnApplySetupCallback onApplySetup;
  final OnDeleteSetupCallback onDeleteSetup;

  const SavedSetupsPage({
    super.key,
    required this.setups,
    required this.onApplySetup,
    required this.onDeleteSetup,
  });

  @override
  State<SavedSetupsPage> createState() => _SavedSetupsPageState();
}

class _SavedSetupsPageState extends State<SavedSetupsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rintocchi Salvati'),
      ),
      body: widget.setups.isEmpty
          ? const Center(
              child: Text('Nessun rintocco salvato.'),
            )
          : ListView.builder(
              itemCount: widget.setups.length,
              itemBuilder: (context, index) {
                final setup = widget.setups[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(setup.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        'Intervallo: ${setup.interval}s, Rip: ${setup.repetitions}, Pausa: ${setup.pause}s'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.play_arrow, color: Colors.green),
                          tooltip: 'Applica Rintocco',
                          onPressed: () {
                            widget.onApplySetup(setup);
                            Navigator.pop(context, true); // Torna e indica che qualcosa è cambiato
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Elimina Rintocco',
                          onPressed: () {
                            // Mostra un dialogo di conferma prima di eliminare
                            showDialog(
                              context: context,
                              builder: (BuildContext dialogContext) {
                                return AlertDialog(
                                  title: const Text('Conferma Eliminazione'),
                                  content: Text(
                                      'Sei sicuro di voler eliminare il rintocco "${setup.name}"?'),
                                  actions: <Widget>[
                                    TextButton(
                                      child: const Text('Annulla'),
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop(); // Chiudi il dialogo
                                      },
                                    ),
                                    TextButton(
                                      child: const Text('Elimina', style: TextStyle(color: Colors.red)),
                                      onPressed: () {
                                        widget.onDeleteSetup(setup.id);
                                        Navigator.of(dialogContext).pop(); // Chiudi il dialogo
                                        // Non è necessario Navigator.pop(context, true) qui
                                        // perché la modifica viene già gestita in onDeleteSetup
                                        // e la lista si aggiornerà automaticamente se la pagina precedente
                                        // ricarica i dati basandosi sul risultato della navigazione.
                                        // Tuttavia, per forzare un rebuild immediato della lista in questa pagina:
                                        setState(() {}); // Ricarica la lista in questa pagina
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                       widget.onApplySetup(setup);
                       Navigator.pop(context, true);
                    },
                  ),
                );
              },
            ),
    );
  }
}
