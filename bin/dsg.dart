import 'dart:async';
import 'dart:io';

import 'package:bonsai/bonsai.dart';
import 'package:dsg/dsg.dart';

Future main(List<String> arguments) async {
  const debug = true;
  if (debug) {
    Log.init(true);
  }
  final application = Application();
  exitCode = await application.run(arguments);
}
