import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class Contact extends StatelessWidget {
  const Contact({super.key});

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Information'),
        centerTitle: true,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: ContactText(),
        ),
      ),
    );
  }
}

class ContactText extends StatelessWidget {
  const ContactText({super.key});

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      TextSpan(
        style: const TextStyle(fontSize: 18, height: 1.6, color: Colors.black),
        children: [
          const TextSpan(text: 'For any queries related to this application or services:\n\n'),
          const TextSpan(text: 'Umar Farooq:\n\n'),
          const TextSpan(text: 'Faaez Usmani\n'),
          const TextSpan(text: 'Whatsapp: '),
          TextSpan(
            text: '+923478502011\n',
            style: const TextStyle(color: Colors.blue),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                launchUrl(Uri.parse('https://wa.me/923478502011'), mode: LaunchMode.externalApplication);
              },
          ),
          const TextSpan(text: 'Email: '),
          TextSpan(
            text: 'faeezusmani2002@gmail.com\n',
            style: const TextStyle(color: Colors.blue),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                launchUrl(Uri.parse('mailto:faeezusmani2002@gmail.com'), mode: LaunchMode.externalApplication);
              },
          ),
          const TextSpan(text: 'LinkedIn: '),
          TextSpan(
            text: 'linkedin.com/in/faaez-usmani',
            style: const TextStyle(color: Colors.blue),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                launchUrl(Uri.parse('https://linkedin.com/in/faaez-usmani'), mode: LaunchMode.externalApplication);
              },
          ),
        ],
      ),
    );
  }
}
