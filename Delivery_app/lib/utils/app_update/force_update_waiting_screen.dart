import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/app_update_bloc.dart';
import 'bloc/app_update_event.dart';

class ForceUpdateWaitingScreen extends StatefulWidget {
  final String message;

  const ForceUpdateWaitingScreen({super.key, required this.message});

  @override
  State<ForceUpdateWaitingScreen> createState() =>
      _ForceUpdateWaitingScreenState();
}

class _ForceUpdateWaitingScreenState extends State<ForceUpdateWaitingScreen> {
  @override
  void initState() {
    super.initState();

    // 🔁 Retry every 10 sec
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 10));

      if (!mounted) return false;

      context.read<AppUpdateBloc>().add(CheckAppUpdate());

      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PopScope(
        canPop: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.system_update, size: 80),
                const SizedBox(height: 20),
                const Text(
                  "Update Coming Soon",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(widget.message, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
