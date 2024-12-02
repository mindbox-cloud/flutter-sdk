import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mindbox/mindbox.dart';
import '../push_info_page/push_info_page.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const String url = "https://your-site.com/";

  // Timeout for waiting to fetch the deviceUUID.
  // The page will not start loading until this timeout expires.
  // During the first initialization, fetching may take a few seconds,
  // while subsequent attempts typically take less than 250 ms.
  static const fetchDeviceUuidTimeout = Duration(milliseconds: 4000);
  late final WebViewController _controller;
  String? deviceUUID;
  bool _isWebViewInitialized = false;

  @override
  void initState() {
    super.initState();

    _initializeDeviceUUIDAndWebView();
    // Please note: if the context is not initialized at the time of
    // receiving data from the push, then navigation will not work
    Mindbox.instance.onPushClickReceived((link, payload) {
      _handlePushNotification(link, payload);
    });

    // Adding this method ensures that even if fetching the deviceUUID times out
    // during the initial page load, synchronization will occur on subsequent
    // page loads or app launches.
    Mindbox.instance.getDeviceUUID((uuid) {
      deviceUUID = uuid;
    });
  }

  // Attempts to fetch the mobile device UUID within the specified timeout (fetchDeviceUuidTimeout).
  // The page will start loading either as soon as the UUID is fetched or after the timeout expires.
  // If the UUID cannot be fetched, synchronization will happen on the next page load or app launch.
  Future<void> _initializeDeviceUUIDAndWebView() async {
    try {
      final uuid = await _fetchDeviceUUIDWithTimeout();
      deviceUUID = uuid;
      print('DeviceUUID initialized: $deviceUUID');
    } catch (e) {
      print('Failed to initialize DeviceUUID: $e');
    } finally {
      _initializeWebViewController();
      setState(() {
        _isWebViewInitialized = true;
      });
    }
  }

  // Initializes the WebView. Synchronization is handled in the onPageStarted callback.
  Future<void> _initializeWebViewController() async {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) async {
            if (deviceUUID != null) {
              await _waitForJavaScriptReady(_controller);
              await _synchronizeDeviceUUID(_controller, deviceUUID!);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  // Fetches the deviceUUID within the specified timeout period.
  // Note: The fetchDeviceUuidTimeout should not be set to less than 250 ms,
  // as the deviceUUID might not be fetched in time.
  Future<String> _fetchDeviceUUIDWithTimeout() async {
    final completer = Completer<String>();
    if (fetchDeviceUuidTimeout.inMilliseconds < 250) {
      throw ArgumentError("Timeout must be at least 250 milliseconds.");
    }
    final timer = Timer(fetchDeviceUuidTimeout, () {
      if (!completer.isCompleted) {
        completer.completeError(
            TimeoutException("Timeout while fetching Device UUID."));
      }
    });
    Mindbox.instance.getDeviceUUID((deviceUUID) {
      if (!completer.isCompleted) {
        if (deviceUUID.isNotEmpty) {
          completer.complete(deviceUUID);
        } else {
          completer.completeError(Exception("DeviceUUID is empty"));
        }
      }
    });
    return completer.future.whenComplete(() => timer.cancel());
  }

  void _handlePushNotification(String link, dynamic payload) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PushInfoPage(link: link, payload: payload),
      ),
    );
  }

  // Debugging method for synchronization.
  // Displays the deviceUUID stored in cookies, localStorage, and the mobile device UUID.
  // These values  of deviceUUID should match.
  Future<void> _showData(WebViewController controller) async {
    try {
      final cookies =
          await controller.runJavaScriptReturningResult("document.cookie");
      print("Cookies: $cookies");
      print("Mobile device UUID us: $deviceUUID");
      final localStorageUUID = await controller.runJavaScriptReturningResult(
        "window.localStorage.getItem('mindboxDeviceUUID');",
      );
      print("JS tracker device UUID is $localStorageUUID");
    } catch (e) {
      print("Failed to fetch cookies: $e");
    }
  }

  // Synchronizes the deviceUUID with the JS SDK
  Future<void> _synchronizeDeviceUUID(
      WebViewController controller, String uuid) async {
    await controller.runJavaScript('''
      document.cookie = "mindboxDeviceUUID=$uuid";
      window.localStorage.setItem('mindboxDeviceUUID', '$uuid');
    ''');
    Mindbox.instance.writeNativeLog(
      message: "Device UUID synchronized with deviceUUID: $uuid",
      logLevel: LogLevel.debug,
    );
  }

  // Method to clear all cookies
  Future<void> _clearAllCookies() async {
    final cookieManager = WebViewCookieManager();
    await cookieManager.clearCookies();
  }

  // Method to wait for JavaScript context to be ready
  Future<void> _waitForJavaScriptReady(WebViewController controller) async {
    const int maxRetries = 10;
    int attempts = 0;
    const Duration retryInterval = Duration(milliseconds: 10);

    while (attempts < maxRetries) {
      // Introduce a small delay before the first check to allow the JavaScript context to initialize.
      // Typically, 15ms is enough, but we use retryInterval for consistency and reliability.
      await Future.delayed(retryInterval);
      try {
        final isReady = await controller.runJavaScriptReturningResult('''
        (function() {
          return typeof document.cookie !== "undefined" && typeof localStorage !== "undefined";
        })();
      ''');

        if (isReady == true) {
          print("JavaScript context is ready.");
          return;
        }
        print("JavaScript context not ready, retrying... [$attempts]");
      } catch (e) {
        print("Error during JavaScript readiness check: $e");
      }

      await Future.delayed(retryInterval);
      attempts++;
    }
    throw TimeoutException(
        "JavaScript context not ready after $maxRetries retries.");
  }

  @override
  Widget build(BuildContext context) {
    if (!_isWebViewInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('WebView Example'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebView Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cookie),
            onPressed: () => _showData(_controller),
          ),
        ],
      ),
      body: WebViewWidget(controller: _controller),
    );
  }

  @override
  void dispose() {
    _controller.clearCache();
    super.dispose();
  }
}
