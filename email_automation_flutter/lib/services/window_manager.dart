import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/email_config.dart';
import '../providers/email_automation_provider.dart';
import '../screens/email_automation_screen.dart';

enum WindowState { running, minimized, closed }

class AutomationWindow {
  final int id;
  EmailConfig config;
  WindowState state;
  final EmailAutomationProvider provider;

  AutomationWindow({
    required this.id,
    required this.config,
    required this.provider,
    this.state = WindowState.running,
  });
}

class WindowManager {
  static final Map<int, AutomationWindow> _windows = {};
  static int _nextWindowId = 1;
  static final ValueNotifier<int> windowsChangeNotifier = ValueNotifier(0);

  static Future<void> openAutomationWindow(
    BuildContext context, {
    EmailConfig? config,
  }) async {
    final windowId = _nextWindowId++;
    final automationProvider = EmailAutomationProvider();

    // If config is provided, update the provider with it
    if (config != null) {
      automationProvider.updateConfig(config);
    }

    // Create and store window
    _windows[windowId] = AutomationWindow(
      id: windowId,
      config: config ?? automationProvider.config,
      provider: automationProvider,
    );

    // Listen to automation status changes and configuration updates
    automationProvider.addListener(() {
      // Update the stored configuration when the provider's config changes
      final window = _windows[windowId];
      if (window != null) {
        window.config = automationProvider.config;
        // Force a rebuild by incrementing the notifier
        windowsChangeNotifier.value++;
      }
    });

    // Notify listeners that a new window was created
    windowsChangeNotifier.value++;

    // For macOS, we'll simulate multiple windows using showDialog
    // In a real desktop app, you would use actual window management
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => ChangeNotifierProvider.value(
            value: automationProvider,
            child: Dialog.fullscreen(
              child: Scaffold(
                appBar: AppBar(
                  title: Text('Email Automation #$windowId'),
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _closeWindow(context, windowId, automationProvider);
                    },
                  ),
                  actions: [
                    Chip(
                      label: Text('Window $windowId'),
                      backgroundColor: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
                body: const EmailAutomationScreen(),
              ),
            ),
          ),
    );
  }

  static void _closeWindow(
    BuildContext context,
    int windowId,
    EmailAutomationProvider provider,
  ) {
    closeWindow(windowId);
    // Close the dialog
    Navigator.of(context).pop();
  }

  static void minimizeWindow(int windowId) {
    final window = _windows[windowId];
    if (window != null) {
      window.state = WindowState.minimized;
      windowsChangeNotifier.value++;

      // In a real desktop app, you would minimize the actual window
      // For now, we'll just update the state
      debugPrint('Window $windowId minimized');
    }
  }

  static void restoreWindow(int windowId) {
    final window = _windows[windowId];
    if (window != null) {
      window.state = WindowState.running;
      windowsChangeNotifier.value++;

      // Since we're using dialogs to simulate windows, we need to show the dialog again
      // We'll need to get the context from somewhere to show the dialog
      debugPrint('Window $windowId restored - attempting to show dialog');

      // For now, we'll just update the state
      // In a real implementation, you would need to pass the context to show the dialog
    }
  }

  // New method to restore window with context
  static Future<void> restoreWindowWithContext(
    int windowId,
    BuildContext context,
  ) async {
    final window = _windows[windowId];
    if (window != null) {
      window.state = WindowState.running;
      // Update the stored config with the current provider config
      window.config = window.provider.config;
      windowsChangeNotifier.value++;

      // Show the window as a dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => ChangeNotifierProvider.value(
              value: window.provider,
              child: Dialog.fullscreen(
                child: Scaffold(
                  appBar: AppBar(
                    title: Text('Email Automation #${window.id}'),
                    leading: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _closeWindow(context, window.id, window.provider);
                      },
                    ),
                    actions: [
                      Chip(
                        label: Text('Window ${window.id}'),
                        backgroundColor: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.1),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                  body: const EmailAutomationScreen(),
                ),
              ),
            ),
      );
    }
  }

  static void closeWindow(int windowId) {
    final window = _windows[windowId];
    if (window != null) {
      // Stop automation if running
      if (window.provider.status == AutomationStatus.running ||
          window.provider.status == AutomationStatus.starting) {
        window.provider.stopAutomation();
      }

      window.state = WindowState.closed;
      windowsChangeNotifier.value++;

      // Remove window after a delay to allow animation to complete
      Future.delayed(const Duration(milliseconds: 300), () {
        _windows.remove(windowId);
        windowsChangeNotifier.value++;
      });

      debugPrint('Window $windowId closed');
    }
  }

  static List<int> get openWindows =>
      _windows.values
          .where(
            (w) =>
                w.state != WindowState.closed &&
                w.provider.status == AutomationStatus.running,
          )
          .map((w) => w.id)
          .toList();

  static int get openWindowsCount => openWindows.length;

  static List<int> get allOpenWindows =>
      _windows.values
          .where((w) => w.state != WindowState.closed)
          .map((w) => w.id)
          .toList();

  static int get allOpenWindowsCount => allOpenWindows.length;

  static WindowState getWindowState(int windowId) {
    final window = _windows[windowId];
    return window?.state ?? WindowState.closed;
  }

  static EmailConfig? getWindowConfig(int windowId) {
    final window = _windows[windowId];
    return window?.config;
  }

  static AutomationStatus getWindowStatus(int windowId) {
    final window = _windows[windowId];
    return window?.provider.status ?? AutomationStatus.stopped;
  }

  static bool isWindowOpen(int windowId) {
    return _windows.containsKey(windowId) &&
        _windows[windowId]?.state != WindowState.closed;
  }

  static void closeAllWindows(BuildContext context) {
    // Mark all windows as closed
    for (final window in _windows.values) {
      window.state = WindowState.closed;
      if (window.provider.status == AutomationStatus.running ||
          window.provider.status == AutomationStatus.starting) {
        window.provider.stopAutomation();
      }
    }
    // Clear windows after delay
    Future.delayed(const Duration(milliseconds: 300), () {
      _windows.clear();
      windowsChangeNotifier.value++;
    });
  }
}
