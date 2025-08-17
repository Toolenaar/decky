import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class DecksView extends StatelessWidget {
  const DecksView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('decks.title'.tr()), automaticallyImplyLeading: false),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.style, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('decks.empty_state.title'.tr(), style: const TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Create new deck
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
