import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart'
    hide NotificationVisibility;
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:overlay_window/task_handler.dart';

// overlay entry point
@pragma("vm:entry-point")
void overlayMain() {
  runApp(const MaterialApp(
    home: Material(child: OverlayWindow()),
  ));
}

@pragma('vm:entry-point')
void startCallback() {
  // The setTaskHandler function must be called to handle the task in the background.
  FlutterForegroundTask.setTaskHandler(FirstTaskHandler());
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: WillStartForegroundTask(
          onWillStart: () async {
            // Return whether to start the foreground service.
            return true;
          },
          androidNotificationOptions: AndroidNotificationOptions(
            channelId: 'notification_channel_id',
            channelName: 'Foreground Notification',
            channelDescription:
                'This notification appears when the foreground service is running.',
            channelImportance: NotificationChannelImportance.LOW,
            priority: NotificationPriority.LOW,
            iconData: const NotificationIconData(
              resType: ResourceType.mipmap,
              resPrefix: ResourcePrefix.ic,
              name: 'launcher',
            ),
          ),
          iosNotificationOptions: const IOSNotificationOptions(
            showNotification: true,
            playSound: false,
          ),
          foregroundTaskOptions: const ForegroundTaskOptions(
            interval: 5000,
            autoRunOnBoot: false,
            allowWifiLock: false,
          ),
          notificationTitle: 'Foreground Service is running',
          notificationText: 'Tap to return to the app',
          callback: startCallback,
          child: const MyHomePage(title: 'Flutter Demo Home Page')),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool permissionGrantedStatus = false;
  bool? requestPermissionStatus = false;
  bool isOverlayActive = false;

  @override
  void initState() {
    _handleInitState();
    Timer.periodic(const Duration(seconds: 1), (timer) {
      _shareData(timer.tick);
    });

    super.initState();
  }

  void _shareData(dynamic data) async {
    await FlutterOverlayWindow.shareData(data);
  }

  void _handleInitState() async {
    try {
      /// it will open the overlay settings page and return `true` once the permission granted.

      permissionGrantedStatus =
          await FlutterOverlayWindow.isPermissionGranted();

      if (!permissionGrantedStatus) {
        requestPermissionStatus =
            await FlutterOverlayWindow.requestPermission();
      }

      setState(() {});
    } catch (e) {
      log("/ERROR PERMISSION : $e");
    }
  }

  void _openOverlayWindow() async {
    await FlutterOverlayWindow.showOverlay(
      enableDrag: true,
      overlayTitle: "X-SLAYER",
      overlayContent: 'Overlay Enabled',
      flag: OverlayFlag.defaultFlag,
      visibility: NotificationVisibility.visibilityPublic,
      positionGravity: PositionGravity.auto,
      height: 200,
      width: 100,
    );
    FlutterForegroundTask.minimizeApp();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Permission Granted $permissionGrantedStatus',
            ),
            Text(
              'Request Permission $requestPermissionStatus',
            ),
            Text(
              'Overlay',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openOverlayWindow,
        child: Icon(requestPermissionStatus != null && requestPermissionStatus!
            ? Icons.add
            : Icons.disabled_by_default),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class OverlayWindow extends StatefulWidget {
  const OverlayWindow({super.key});

  @override
  State<OverlayWindow> createState() => _OverlayWindowState();
}

class _OverlayWindowState extends State<OverlayWindow> {
  dynamic data;

  bool isMaximize = false;

  @override
  void initState() {
    FlutterOverlayWindow.overlayListener.listen((event) {
      setState(() {
        data = event;
      });
    });

    super.initState();
  }

  void _closeOverlay() async {
    await FlutterOverlayWindow.closeOverlay();
    FlutterForegroundTask.launchApp();
  }

  void _resizeOverlay() async {
    if (!isMaximize) {
      await FlutterOverlayWindow.resizeOverlay(WindowSize.fullCover, 200);
    } else {
      await FlutterOverlayWindow.resizeOverlay(100, 200);
    }
    setState(() {
      isMaximize = !isMaximize;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.blue,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
                onPressed: _resizeOverlay, icon: const Icon(Icons.home_max)),
            Text("$data"),
            IconButton(onPressed: _closeOverlay, icon: const Icon(Icons.close)),
          ],
        ));
  }
}
