part of dsg;

class Application {
  final Logger _logger = Logger("dsg.Application");

  /// Commandline options
  final Options options;

  /// {timerForPageRefresh} waits 500ms before refreshing the page
  /// If there are more PageRefresh-Requests withing 500ms only the last refresh will be made
  Timer timerForPageRefresh;

  /// {timerWatchCss} waits 500ms before it calls it's watch-functions.
  /// If there are more watch-events within 500ms only the last event counts
  Timer timerWatchCss;

  /// {timerWatch} waits 500ms until all watched folders and files updated
  Timer timerWatch;

  Application() : options = Options();

  Future<int> run(final List<String> args) async {
    try {
      final cm = await CommandManager.getInstance();
      final argResults = options.parse(args);
      final config = Config(argResults, cm);

      _configLogging(config.loglevel);

      try {
        _testPreconditions(cm, config);
      } catch (error) {
        stderr.writeln(error.toString());
        return 1;
      }

      if (argResults.wasParsed(Options._ARG_HELP) ||
          (config.dirstoscan.isEmpty && args.isEmpty)) {
        options.showUsage();
        return 0;
      }

      if (argResults.wasParsed(Options._ARG_SETTINGS)) {
        config.printSettings();
        return 0;
      }

      if (argResults.wasParsed(Options._ARG_SITE_KEYS)) {
        config.printSiteKeys();
        return 0;
      }

      var foundOptionToWorkWith = false;

      if (argResults.wasParsed(Options._ARG_INIT)) {
        foundOptionToWorkWith = true;
        final init = Init();
        await init.createDirs(config);
        await init.createFiles(config);
        return 0;
      }

      if (argResults.wasParsed(Options._ARG_GENERATE)) {
        foundOptionToWorkWith = true;
        Generator().generate(config);
      }

      if (argResults.wasParsed(Options._ARG_GENERATE_CSS)) {
        foundOptionToWorkWith = true;
        _compileSCSSFile(config.outputfolder, config);
      }

      if (argResults.wasParsed(Options._ARG_WATCH) ||
          argResults.wasParsed(Options._ARG_WATCH_AND_SERVE)) {
        foundOptionToWorkWith = true;
        if (_isFolderAvailable(config.contentfolder) &&
            _isFolderAvailable(config.templatefolder)) {
          watch(config.contentfolder, config);
          watch(config.templatefolder, config);

          if (_isFolderAvailable(config.datafolder)) {
            watch(config.datafolder, config);
          }

          if (_isFolderAvailable(config.partialsfolder)) {
            watch(config.partialsfolder, config);
          }

          if (_isFolderAvailable(config.assetsfolder)) {
            watch(config.assetsfolder, config);
          }

          Generator().generate(config);
        }
        watchScss(config.outputfolder, config);
        // watchToRefresh(config.outputfolder, config);

        watchAdditionalFolderScss(
            config.watchfolder1, config.outputfolder, config);
        watchAdditionalFolderScss(
            config.watchfolder2, config.outputfolder, config);
        watchAdditionalFolderScss(
            config.watchfolder3, config.outputfolder, config);
      }

      if (argResults.wasParsed(Options._ARG_SERVE) ||
          argResults.wasParsed(Options._ARG_WATCH_AND_SERVE)) {
        foundOptionToWorkWith = true;

        serve(config);
      }

      if (!foundOptionToWorkWith) {
        options.showUsage();
      }
    } on FormatException catch (error) {
      _logger.shout(error);
      options.showUsage();
      return 1;
    }

    return 0;
  }

  void serve(final Config config) {
    Validate.notBlank(config.ip);
    Validate.notBlank(config.docroot);
    Validate.notBlank(config.port);

    final ip = config.ip;
    final port = config.port;
    final MY_HTTP_ROOT_PATH =
        config.docroot; //Platform.script.resolve(folder).toFilePath();

    VirtualDirectory virtDir;
    void _directoryHandler(final Directory dir, final HttpRequest request) {
      _logger.info(dir);
      final indexUri = Uri.file(dir.path).resolve('index.html');
      virtDir.serveFile(File(indexUri.toFilePath()), request);
    }

    virtDir = VirtualDirectory(MY_HTTP_ROOT_PATH)
      ..allowDirectoryListing = true
      ..followLinks = true
      ..jailRoot = false;
    virtDir.directoryHandler = _directoryHandler;

    final packages = Packages();

    // if hasPackages is false then we are not in a Dart-Project
    final hasPackages = packages.hasPackages;

    Future<HttpServer> connect;
    if (config.usesecureconnection) {
      final context = SecurityContext();
      context.useCertificateChain(config.certfile);
      context.usePrivateKey(config.keyfile);
      connect = HttpServer.bindSecure(ip, int.parse(port), context);
      _logger
          .info('Using a secure connection on $ip - Scheme should be https!');
    } else {
      connect = HttpServer.bind(ip, int.parse(port));
    }

    runZoned(() {
      connect.then((final server) {
        _logger.info('Server running $ip on port: $port, $MY_HTTP_ROOT_PATH');
        server.listen((final request) {
          if (request.uri.path.startsWith("/packages") && hasPackages) {
            final parts = request.uri.path.split(RegExp(r"(?:/|\\)"));
            final path = parts.sublist(3).join("/");
            final packageName = parts[2];

            final package =
                packages.resolvePackageUri(Uri.parse("package:${packageName}"));
            final rewritten = "${package.lib.path}/$path"
                .replaceFirst(RegExp(r"^.*pub\.dartlang\.org/"), "package:");

            _logger.info(
                "${request.connectionInfo.remoteAddress.address}:${request.connectionInfo.localPort} - ${request.method} [Rewritten] ${rewritten}");
            virtDir.serveFile(File("${package.lib.path}/$path"), request);
          } else {
            _logger.info(
                "${request.connectionInfo.remoteAddress.address}:${request.connectionInfo.localPort} - ${request.method} ${request.uri}");
            virtDir.serveRequest(request);
          }
        });
      });
    },
        onError: (Object e, StackTrace stackTrace) =>
            _logger.severe('Error running http server: $e $stackTrace'));
  }

  void watch(final String folder, final Config config) {
    Validate.notBlank(folder);
    Validate.notNull(config);

    _logger.info('Observing (watch) $folder...');

    final srcDir = Directory(folder);

    final watcher = DirectoryWatcher(srcDir.path);
    watcher.events
        .where((final event) => (!event.path.contains("packages")))
        .listen((final event) {
      _logger.info(event.toString());
      timerWatch ??= Timer(Duration(milliseconds: 1000), () {
        Generator().generate(config);
        timerWatch = null;
      });
    });
  }

  void watchScss(final String folder, final Config config) {
    Validate.notBlank(folder);
    Validate.notNull(config);

    _logger.fine('Observing $folder (SCSS)... ');
    final dir = Directory(folder);
    final scssFiles = _listSCSSFilesIn(dir);

    if (scssFiles.isEmpty) {
      _logger.info("No SCSS files found");
      return;
    }

    _compileSCSSFile(folder, config);

    try {
      scssFiles.forEach((final File file) {
        _logger.info("Observing: (watchScss) ${file.path}");

        file
            .watch(events: FileSystemEvent.modify)
            .listen((final FileSystemEvent event) {
          _logger.fine(event.toString());
          //_logger.info("Scss: ${scssFile}, CSS: ${cssFile}");

          timerWatchCss ??= Timer(Duration(milliseconds: 500), () {
            _compileSCSSFile(folder, config);
            timerWatchCss = null;
          });
        });
      });
    } on StateError {
      _logger.info("Found no SCSS without a _ at the beginning...");
    }
  }

  void watchAdditionalFolderScss(final String additionalWatchFolder,
      final String cssFolder, final Config config) {
    Validate.notBlank(cssFolder);
    Validate.notNull(config);

    if (additionalWatchFolder.isEmpty) {
      return;
    }

    _logger.fine('Observing $cssFolder (SCSS)... ');

    final dirToCheck = Directory(additionalWatchFolder);
    final dir = Directory(cssFolder);
    final scssFiles = _listSCSSFilesIn(dir);

    if (scssFiles.isEmpty) {
      _logger.info("No SCSS files found");
      return;
    }

    _compileSCSSFile(cssFolder, config);

    try {
      _logger.info("Observing: (watchAdditionalFolderScss) ${dirToCheck.path}");

      dirToCheck
          .watch(events: FileSystemEvent.modify)
          .listen((final FileSystemEvent event) {
        _logger.fine(event.toString());
        // _logger.info("Scss: ${scssFile}, CSS: ${cssFile}");

        timerWatchCss ??= Timer(Duration(milliseconds: 500), () {
          _compileSCSSFile(cssFolder, config);
          timerWatchCss = null;
        });
      });
    } on StateError {
      _logger.info("Found no SCSS without a _ at the beginning...");
    }
  }

  // void _watchDir({
  //   Directory dir,
  //   int events,
  //   Function(FileSystemEvent event) whereFilter,
  //   Function(FileSystemEvent event) listener,
  //   bool recursive,
  // }) async {
  //   if (Platform.isLinux) {
  //     final dirList = dir
  //         .listSync(recursive: true)
  //         .where((entity) => FileSystemEntity.isDirectorySync(entity.path));

  //     for (final dir in dirList) {
  //       print("WATCH: ${dir.path}");
  //       dir.watch(events: events, recursive: false).listen(
  //           (e) => print("file change: $e"),
  //           onError: (e, stack) => print("$e $stack"));
  //     }
  //     // dirList.forEach((dir) {
  //     //   print("WATCH: ${dir.path}");
  //     //   dir.watch(events: events, recursive: false).listen(
  //     //       (e) => print("file change: $e"),
  //     //       onError: (e, stack) => print("$e $stack"));
  //     // });
  //   } else {
  //     dir
  //         .watch(events: events, recursive: recursive)
  //         .where(whereFilter)
  //         .listen(listener);
  //   }
  // }

  void _testPreconditions(final CommandManager cm, final Config config) {
    // if not using sass or prefixer, dont check for them being available
    if (!config.usesass && !config.useautoprefixer) {
      return;
    }

    if ((cm.containsKey(CommandManager.SASS) ||
            cm.containsKey(CommandManager.SASSC)) &&
        cm.containsKey(CommandManager.AUTOPREFIXER)) {
      return;
    }
    throw "Please install SASS (${CommandManager.SASS} | ${CommandManager.SASSC}) "
        "and AutoPrefixer (${CommandManager.AUTOPREFIXER})";
  }

  void _compileSCSSFile(final String folder, final Config config) {
    Validate.notBlank(folder);
    Validate.notNull(config);

    _logger.fine('Observing: (_compileSCSSFile) $folder (SCSS)... ');
    final dir = Directory(folder);
    final scssFiles = _listSCSSFilesIn(dir);

    if (scssFiles.isEmpty) {
      _logger.info("No SCSS files found");
      return;
    }

    // mainScssFile is the one not starting with a _ (underscore)
    File _mainScssFile(final List<File> scssFiles) {
      final mainScss = scssFiles.firstWhere((final File file) {
        final pureFilename = path.basename(file.path);
        return pureFilename.startsWith(RegExp(r"[a-z]", caseSensitive: false));
      });
      return mainScss;
    }

    final mainScss = _mainScssFile(scssFiles);

    final scssFile = mainScss.path;
    final cssFile = "${path.withoutExtension(scssFile)}.css";

    _logger.info("Main SCSS: $scssFile");
    _compileScss(scssFile, cssFile, config);
    _autoPrefixer(cssFile, config);
  }

  bool _isFolderAvailable(final String folder) {
    Validate.notBlank(folder);
    final dir = Directory(folder);
    return dir.existsSync();
  }

  void _compileScss(
      final String source, final String target, final Config config) {
    Validate.notBlank(source);
    Validate.notBlank(target);
    Validate.notNull(config);

    if (!config.usesass) {
      _logger
          .info("Sass was disabled - so your SCSS won't be compiled to CSS!");
      return;
    }

    final compiler = config.sasscompiler;
    final environment = <String, String>{};

    if (config.sasspath.isNotEmpty) {
      // only sass supports SASS_PATH (not sassc)
      if (!compiler.endsWith("c")) {
        environment["SASS_PATH"] = config.sasspath;
        _logger.info("Using SASS_PATH: ${config.sasspath}");
      } else {
        _logger.warning("SASS_PATH ist not supported by your compiler!");
      }
    }

    _logger.info("Compiling $source -> $target");
    final result =
        Process.runSync(compiler, [source, target], environment: environment);
    if (result.exitCode != 0) {
      _logger.info("sassc failed with: ${(result.stderr as String).trim()}!");
      _vickiSay("got a sassc error", config);
      return;
    }
    _logger.info("Done!");
  }

  void _autoPrefixer(final String cssFile, final Config config) {
    Validate.notBlank(cssFile);
    Validate.notNull(config);

    if (!config.useautoprefixer) {
      _logger
          .info("Autoprefixing was disabled - so your CSS won't be prefixed!");
      return;
    }

    _logger.info("Autoprefixing $cssFile");
    final result = Process.runSync("autoprefixer-cli", [cssFile]);
    if (result.exitCode != 0) {
      _logger.info("prefixer faild with: ${(result.stderr as String).trim()}!");
      _vickiSay("got a prefixer error", config);
      return;
    }
    _logger.info("Done!");
  }

  List<File> _listSCSSFilesIn(final Directory dir) {
    Validate.notNull(dir);
    return dir
        .listSync(recursive: true)
        .where((final file) {
          return file is File &&
              file.path.endsWith(".scss") &&
              !file.path.contains("packages");
        })
        .map((final FileSystemEntity entity) => entity as File)
        .toList();
  }

  void _vickiSay(final String sentence, final Config config) {
    Validate.notBlank(sentence);

    if (config.talktome == false) {
      _logger.severe("Vicki wants to say: '${sentence}'");
      return;
    }

    final result = Process.runSync(
        "say", ['-r', '200', sentence.replaceFirst("wsk_", "")]);
    if (result.exitCode != 0) {
      _logger.severe("run faild with: ${(result.stderr as String).trim()}!");
    }
  }

  void _configLogging(final String loglevel) {
    Validate.notBlank(loglevel);

    hierarchicalLoggingEnabled =
        false; // set this to true - its part of Logging SDK

    // now control the logging.
    // Turn off all logging first
    switch (loglevel) {
      case "fine":
      case "debug":
        Logger.root.level = Level.FINE;
        break;

      case "warning":
        Logger.root.level = Level.SEVERE;
        break;

      default:
        Logger.root.level = Level.INFO;
    }

    Logger.root.onRecord
        .listen(LogPrintHandler(transformer: transformerMessageOnly));
  }
}
