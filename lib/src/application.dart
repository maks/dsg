part of dsg;

class Application {
  /// Commandline options
  final Options options;

  /// {timerForPageRefresh} waits 500ms before refreshing the page
  /// If there are more PageRefresh-Requests withing 500ms only the last refresh will be made
  late Timer timerForPageRefresh;

  /// {timerWatchCss} waits 500ms before it calls it's watch-functions.
  /// If there are more watch-events within 500ms only the last event counts
  late Timer timerWatchCss;

  /// {timerWatch} waits 500ms until all watched folders and files updated
  late Timer timerWatch;

  Application() : options = Options();

  Future<int> run(final List<String> args) async {
    try {
      final argResults = options.parse(args);
      final config = Config(argResults);

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
      Log.e('', error);
      options.showUsage();
      return 1;
    }

    return 0;
  }

  void serve(final Config config) {
    check(config.ip).isNotEmpty();
    check(config.docroot).isNotEmpty();
    check(config.port).isNotEmpty();

    final ip = config.ip;
    final port = config.port;
    final MY_HTTP_ROOT_PATH =
        config.docroot; //Platform.script.resolve(folder).toFilePath();

    late VirtualDirectory virtDir;
    void _directoryHandler(final Directory dir, final HttpRequest request) {
      log('$dir');
      final indexUri = Uri.file(dir.path).resolve('index.html');
      virtDir.serveFile(File(indexUri.toFilePath()), request);
    }

    virtDir = VirtualDirectory(MY_HTTP_ROOT_PATH)
      ..allowDirectoryListing = true
      ..followLinks = true
      ..jailRoot = false;
    virtDir.directoryHandler = _directoryHandler;

    Future<HttpServer> connect;
    if (config.usesecureconnection) {
      final context = SecurityContext();
      context.useCertificateChain(config.certfile);
      context.usePrivateKey(config.keyfile);
      connect = HttpServer.bindSecure(ip, int.parse(port), context);
      log('Using a secure connection on $ip - Scheme should be https!');
    } else {
      connect = HttpServer.bind(ip, int.parse(port));
    }

    runZoned(() {
      connect.then((final server) {
        log('Server running $ip on port: $port, $MY_HTTP_ROOT_PATH');
        server.listen((final request) {
          log('${request.connectionInfo?.remoteAddress.address}:${request.connectionInfo?.localPort} - ${request.method} ${request.uri}');
          
          virtDir.serveRequest(request); 
        });
      });
    },
        onError: (Object e, StackTrace stackTrace) =>
            Log.e('Error running http server: $e $stackTrace'));
  }

  void watch(final String folder, final Config config) {
    check(folder).isNotEmpty();

    log('Observing (watch) $folder...');

    final srcDir = Directory(folder);

    final watcher = DirectoryWatcher(srcDir.path);
    watcher.events
        .where((final event) => (!event.path.contains('packages')))
        .listen((final event) {
      log(event.toString());
    });
  }

  bool _isFolderAvailable(final String folder) {
    check(folder).isNotEmpty();
    final dir = Directory(folder);
    return dir.existsSync();
  }
}
