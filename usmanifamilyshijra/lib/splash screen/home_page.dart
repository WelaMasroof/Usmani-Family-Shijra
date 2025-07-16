import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'add_person_page.dart';
import 'delete_person_page.dart';  // You'll need to create this new screen

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usmani Family Shijra'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Show Family Graph Button
              ElevatedButton.icon(
                icon: const Icon(Icons.family_restroom),
                label: const Text('Show Family Graph'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SplashScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: 20),

              // 2. Add Person Button
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text('Add Person'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddPersonPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: 20),

              // 3. Delete Person Button (New)
              ElevatedButton.icon(
                icon: const Icon(Icons.person_remove, color: Colors.white),
                label: const Text('Delete Person', style: TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DeletePersonPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}