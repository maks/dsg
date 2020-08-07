library dsg;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:console_log_handler/print_log_handler.dart';
import 'package:dsg/src/listings.dart';
import 'package:front_matter/front_matter.dart' as fm;
import 'package:http_server/http_server.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:packages/packages.dart';
import 'package:path/path.dart' as path;
import 'package:reflected_mustache/mustache.dart' as mustache;
import 'package:system_info/system_info.dart';
import 'package:validate/validate.dart';
import 'package:watcher/watcher.dart';
import 'package:where/where.dart';
import 'package:yaml/yaml.dart' as yaml;

part 'src/application.dart';
part 'src/command_manager.dart';
part 'src/config.dart';
part 'src/generator.dart';
part 'src/init.dart';
part 'src/options.dart';
part 'src/dates.dart';

bool _runsOnOSX() => (SysInfo.operatingSystemName == 'Mac OS X');

Future main(List<String> arguments) async {
  final application = Application();

  await application.run(arguments);
}
