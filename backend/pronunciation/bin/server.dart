import 'dart:io';

/// Retain the team's original command while running the actual Python models.
Future<void> main() async {
  final root = File(Platform.script.toFilePath()).parent.parent.parent.parent;
  final defaultPython = Platform.isWindows
      ? '${root.path}/.venv/Scripts/python.exe'
      : '${root.path}/.venv/bin/python';
  final python = Platform.environment['PRONUNCIATION_PYTHON'] ?? defaultPython;
  if (!File(python).existsSync()) {
    stderr.writeln(
      'Python environment missing. Run backend/pronunciation/setup_backend.ps1 first.',
    );
    exitCode = 2;
    return;
  }
  final process = await Process.start(
    python,
    [
      '-m',
      'uvicorn',
      'server:app',
      '--app-dir',
      '${root.path}/backend/pronunciation',
      '--host',
      Platform.environment['HOST'] ?? '127.0.0.1',
      '--port',
      Platform.environment['PORT'] ?? '8080',
    ],
    workingDirectory: root.path,
    mode: ProcessStartMode.inheritStdio,
  );
  exitCode = await process.exitCode;
}
