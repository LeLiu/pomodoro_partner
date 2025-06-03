export 'package:logger/logger.dart' show Logger, Level;

import 'package:logger/logger.dart';

class AppLogger {
  static late Level level;

  static final Logger _globalLogger = Logger(
    printer: PrettyPrinter(methodCount: 0, colors: true, printEmojis: true),
    level: level,
  );

  static Logger get logger => _globalLogger;

  static Logger forClass(Type classType) {
    final className = _getSimpleClassName(classType);

    return Logger(
      printer: _ClassNamePrinter(
        className: className,
        innerPrinter: PrettyPrinter(
          methodCount: 0,
          colors: true,
          printEmojis: true,
        ),
      ),
      level: level,
    );
  }

  static void initialize({Level level = Level.info}) {
    AppLogger.level = level;
  }

  static String _getSimpleClassName(Type type) {
    final fullName = type.toString();
    return fullName.substring(fullName.lastIndexOf('.') + 1);
  }
}

class _ClassNamePrinter extends LogPrinter {
  final String className;
  final LogPrinter innerPrinter;

  _ClassNamePrinter({required this.className, required this.innerPrinter});

  @override
  List<String> log(LogEvent event) {
    final originalOutput = innerPrinter.log(event);
    return originalOutput.map((line) => '[$className] $line').toList();
  }
}
