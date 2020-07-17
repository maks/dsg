part of dsg;

/// Initializes your site directory.
/// This means - creates _templates folder, _content folder aso.
///
class Init {
  final Logger _logger = Logger('dsg.Init');

  static const String _STYLES_FOLDER = 'styles';
  static const String _STYLES_FILE = 'main.scss';

  Future<void> createDirs(final Config config) {
    Validate.notNull(config);
    return Future.wait([
      _createDir(config.templatefolder),
      _createDir(config.contentfolder),
      _createDir('${config.contentfolder}/$_STYLES_FOLDER'),
      _createDir(config.outputfolder),
      _createDir(config.configfolder)
    ]);
  }

  /// Creates files like site.yaml and adds a default Template and a default content file
  Future<void> createFiles(final Config config) {
    Validate.notNull(config);

    return Future.wait([
      _createSiteYaml(config),
      _createDefaultTemplate(config),
      _createIndexHTML(config),
      _createScssFile(config)
    ]);
  }

  Future<void> _createDir(final String dirname) async {
    Validate.notBlank(dirname);

    final dir = Directory(dirname);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      _logger.info('${dir.path} created...');
    }
  }

  Future<void> _createSiteYaml(final Config config) async {
    Validate.notNull(config);

    final file = File('${config.configfolder}/${config.configfile}');
    if (!await file.exists()) {
      final content = 'site_options:\n  generator: DSG\n  site_name: Sample';
      await file.writeAsString(content);
      _logger.info('${file.path} created...');
    }
  }

  Future<void> _createDefaultTemplate(final Config config) async {
    Validate.notNull(config);

    final file = File(('${config.templatefolder}/${config.defaulttemplate}'));
    if (!await file.exists()) {
      final content = '''
                <!DOCTYPE html>
                <html>
                <head>
                    <title>{{title}} | {{_site.site_name}}</title>
                    <meta charset="utf-8">
                    <link rel="stylesheet" href="{{_page.relative_to_root}}styles/main.css">
                </head>
                <body>
                <h1>{{title}}</h1>
                {{_content}}
                <!--
                    <script type="application/dart" src="{{_page.relative_to_root}}main.dart"></script>
                    <script src="packages/browser/dart.js"></script>
                -->
                </body>
                </html>
            '''
          .trim()
          .replaceAll(RegExp(r'^\s{16}', multiLine: true),
              ''); // 16 is the number of spaces for the first indention
      await file.writeAsString(content);
      _logger.info('${file.path} created...');
    }
  }

  Future<void> _createIndexHTML(final Config config) async {
    Validate.notNull(config);

    final file = File('${config.contentfolder}/index.html');
    if (!await file.exists()) {
      final content = '''
                ---
                title: My index page
                ---
                <section class="main">
                    My content
                </section>
                '''
          .trim()
          .replaceAll(RegExp(r'^\s{16}', multiLine: true), '');
      await file.writeAsString(content);
      _logger.info('${file.path} created...');
    }
  }

  Future<void> _createScssFile(final Config config) async {
    Validate.notNull(config);

    final file = File('${config.contentfolder}/$_STYLES_FOLDER/$_STYLES_FILE');
    if (!await file.exists()) {
      final content = '''
                body {
                    background-color: #eeeeee;

                    .main {
                        background-color: red;
                    }
                }
                '''
          .trim()
          .replaceAll(RegExp(r'^\s{16}', multiLine: true), '');
      await file.writeAsString(content);
      _logger.info('${file.path} created...');
    }
  }
}
