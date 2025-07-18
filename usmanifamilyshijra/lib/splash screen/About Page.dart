import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'About This App',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'ysbicchbdbhbcds'
                    'You can add people, link them with parents or children, and view their notes. '
                    'It is built with Flutter and Neo4j as the backend graph database. '
                    'This app aims to preserve family heritage across generations with simplicity and accessibility.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Text(
                'Developed by UsmaiFamily',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}