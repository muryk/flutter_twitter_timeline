import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:tt_plugin/tt_plugin.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await TTPlugin.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    OrientationNotifier().addListener(_onOrientationChange);

    try {
        final response = await TwitterApiClient.startTask();
        if (response is TwitterApiStringResponse) {
            String taskIdentifier = response.string;
            /*
            trying to cancel long-running task
            Future.delayed(const Duration(milliseconds: 500), () async {
                debugPrint("Start task cancelling");
                await TwitterApiClient.cancelTask(taskIdentifier);
                debugPrint("End task cancelling");
            });
            */
            await TwitterApiClient.getTimeline(taskIdentifier: taskIdentifier, userName: "elonmusk");
        }
    } catch (e) {
        debugPrint("Error: $e");
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  void dispose() {
    OrientationNotifier().removeListener(_onOrientationChange);
    super.dispose();
  }

  void _onOrientationChange(Orientation orientation) {
      debugPrint("onOrientationChange: $orientation");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Running on: $_platformVersion\n'),
        ),
      ),
    );
  }
}
