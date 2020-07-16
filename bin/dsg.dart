import 'dart:async';
import 'dart:io';

import 'package:dsg/dsg.dart';

Future main(List<String> arguments) async {
  final application = Application();
  exitCode = await application.run(arguments);
}
