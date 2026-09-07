import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../database/game_cache.dart';

void showSettingsModal(
  BuildContext context, {
  required ThemeMode themeMode,
  required VoidCallback onThemeToggle,
  required VoidCallback onDataCleared,
}) {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              leading: Icon(
                themeMode == ThemeMode.light
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
              title: const Text('Promijeni temu'),
              onTap: onThemeToggle,
            ),
            ListTile(
              leading: Icon(
                Icons.delete_sweep,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Obriši sve podatke',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Obriši sve podatke?'),
                    content: const Text(
                      'Jeste li sigurni? Sve odigrane partije i svi igrači bit će nepovratno obrisani!',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Odustani'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                        child: const Text('Obriši sve'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await DatabaseHelper.instance.clearAllPlayers();
                  await GameCache.clearAllActiveGames();
                  onDataCleared();
                }
              },
            ),
          ],
        ),
      );
    },
  );
}
