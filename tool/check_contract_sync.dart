import 'dart:convert';
import 'dart:io';

// The desktop repository owns these fixtures. Run this when updating either
// repository; ordinary mobile tests use the pinned copies without a sibling repo.
void main(List<String> arguments) {
  final desktop = arguments.isEmpty
      ? Directory.fromUri(Platform.script.resolve('../../devventory/'))
      : Directory(arguments.single);
  for (final name in ['read-v1.json', 'quota-status-v1.json']) {
    final producer = File('${desktop.path}/cloud/contracts/fixtures/$name');
    final consumer = File.fromUri(
      Platform.script.resolve('../test/contracts/fixtures/$name'),
    );
    if (!producer.existsSync() || !consumer.existsSync()) {
      stderr.writeln(
        'Missing contract fixture: $name. Supply the desktop root.',
      );
      exitCode = 1;
      continue;
    }
    final expected = jsonEncode(jsonDecode(producer.readAsStringSync()));
    final actual = jsonEncode(jsonDecode(consumer.readAsStringSync()));
    if (expected != actual) {
      stderr.writeln('Contract drift: refresh the pinned $name from desktop.');
      exitCode = 1;
    } else {
      stdout.writeln('Producer/consumer fixture matches: $name');
    }
  }
}
