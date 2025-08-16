import 'dart:io';

void main(List<String> arguments) {
  print('Reply Detection Test Script');
  print('==========================');
  print('');
  print('This script helps you test the reply detection functionality.');
  print('');
  print('To simulate a reply being received:');
  print('1. Run this script with: dart test_reply_detection.dart create');
  print('2. Start the email automation in the Flutter app');
  print('3. The automation should detect the "reply" and stop');
  print('');
  print('To remove the test reply:');
  print('1. Run this script with: dart test_reply_detection.dart remove');
  print('');

  if (arguments.isNotEmpty) {
    final command = arguments[0];

    if (command == 'create') {
      _createTestReply();
    } else if (command == 'remove') {
      _removeTestReply();
    } else {
      print('Unknown command: $command');
      print('Use "create" or "remove"');
    }
  }
}

void _createTestReply() {
  try {
    final file = File('test_reply_received.txt');
    file.writeAsStringSync('Reply received at ${DateTime.now()}');
    print('✓ Test reply file created successfully');
    print('The email automation should now detect this reply and stop.');
  } catch (e) {
    print('✗ Failed to create test reply file: $e');
  }
}

void _removeTestReply() {
  try {
    final file = File('test_reply_received.txt');
    if (file.existsSync()) {
      file.deleteSync();
      print('✓ Test reply file removed successfully');
    } else {
      print('ℹ Test reply file does not exist');
    }
  } catch (e) {
    print('✗ Failed to remove test reply file: $e');
  }
}
