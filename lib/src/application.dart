part of dsg;

class Application {
  final Logger _logger = Logger('dsg.Application');

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
      final argResults = options.parse(args);
      final config = Config(argResults);

      _configLogging(config.loglevel);

      try {
        _testPreconditions(config);
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
          if (request.uri.path.startsWith('/packages') && hasPackages) {
            final parts = request.uri.path.split(RegExp(r'(?:/|\\)'));
            final path = parts.sublist(3).join('/');
            final packageName = parts[2];

            final package =
                packages.resolvePackageUri(Uri.parse('package:${packageName}'));
            final rewritten = '${package.lib.path}/$path'
                .replaceFirst(RegExp(r'^.*pub\.dartlang\.org/'), 'package:');

            _logger.info(
                '${request.connectionInfo.remoteAddress.address}:${request.connectionInfo.localPort} - ${request.method} [Rewritten] ${rewritten}');
            virtDir.serveFile(File('${package.lib.path}/$path'), request);
          } else {
            _logger.info(
                '${request.connectionInfo.remoteAddress.address}:${request.connectionInfo.localPort} - ${request.method} ${request.uri}');
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
        .where((final event) => (!event.path.contains('packages')))
        .listen((final event) {
      _logger.info(event.toString());
      timerWatch ??= Timer(Duration(milliseconds: 1000), () {
        Generator().generate(config);
        timerWatch = null;
      });
    });
  }

  void _testPreconditions(final Config config) {
    // if not using sass or prefixer, dont check for them being available
    if (!config.usesass && !config.useautoprefixer) {
      return;
    }
  }

  bool _isFolderAvailable(final String folder) {
    Validate.notBlank(folder);
    final dir = Directory(folder);
    return dir.existsSync();
  }

  void _configLogging(final String loglevel) {
    Validate.notBlank(loglevel);

    hierarchicalLoggingEnabled =
        false; // set this to true - its part of Logging SDK

    // now control the logging.
    // Turn off all logging first
    switch (loglevel) {
      case 'fine':
      case 'debug':
        Logger.root.level = Level.FINE;
        break;

      case 'warning':
        Logger.root.level = Level.SEVERE;
        break;

      default:
        Logger.root.level = Level.INFO;
    }

    Logger.root.onRecord
        .listen(LogPrintHandler(transformer: transformerMessageOnly));
  }
}
