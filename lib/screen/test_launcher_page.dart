import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class TestLauncherPage extends StatelessWidget{
  const TestLauncherPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Test Url launcher")),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          onPressed: () async{
            final uri = Uri.parse("https://www.google.com");
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              debugPrint("Gagal membuka link");
            }
          }, 
          child: const Text("Test buka link"),
          ),
      ),
    );
  }
}