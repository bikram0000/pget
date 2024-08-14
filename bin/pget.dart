library pget;
import 'package:logger/logger.dart';
import 'package:pget/package_get.dart' as package_get;



/// Command line entry point to configure package details.
///
/// Execute following command to set package details:
/// ```bash
/// flutter pub run package_rename:set
/// ```
void main(List<String> arguments) {
  Logger(
    filter: ProductionFilter(),
    printer: PrettyPrinter(
      lineLength: 80,
      methodCount: 0,
      noBoxingByDefault: true,
      printEmojis: false,
    ),
  ).w(
    'This command is deprecated and replaced with "dart run pget"',
  );
  package_get.set(arguments);
}
