// ignore_for_file: constant_identifier_names

part of dsg;

/// Defines default-configurations.
/// Most of these configs can be overwritten by commandline args.
///
class Config {
  static const String _CONFIG_FOLDER = '.dsg';

  static const _CONF_CONTENT_DIR = 'content_dir';
  static const _CONF_TEMPLATE_DIR = 'template_dir';
  static const _CONF_OUTPUT_DIR = 'output_dir';
  static const _CONF_DATA_DIR = 'data_dir';
  static const _CONF_LISTINGS_DIR = 'listings_dir';
  static const _CONF_PARTIALS_DIR = 'partials_dir';
  static const _CONF_ASSETS_DIR = 'assets_dir';
  static const _CONF_WORKSPACE_DIR = 'workspace';
  static const _CONF_DATE_FORMAT = 'date_format';
  static const _CONF_YAML_DELIMITER = 'yaml_delimeter';
  static const _CONF_USE_MARKDOWN = 'use_markdown';
  static const _CONF_DEFAULT_TEMPLATE = 'default_template';
  static const _CONF_SITE_OPTIONS = 'site_options';
  static const _CONF_BROWSER = 'browser';
  static const _CONF_PORT = 'port';

  static const _CONF_USE_SECURE_CONNECTION = 'usesec';
  static const _CONF_CERT_FILE = 'cert_file';
  static const _CONF_KEY_FILE = 'key_file';

  static const _CONF_ADDITIONAL_WATCH_FOLDER1 = 'watchfolder1';
  static const _CONF_ADDITIONAL_WATCH_FOLDER2 = 'watchfolder2';
  static const _CONF_ADDITIONAL_WATCH_FOLDER3 = 'watchfolder3';

  final ArgResults _argResults;
  final Map<String, dynamic> _settings = <String, dynamic>{};

  Config(this._argResults) {
    _settings[Options._ARG_LOGLEVEL] = 'info';

    _settings[Config._CONF_CONTENT_DIR] = '$_CONFIG_FOLDER/html/_content';
    _settings[Config._CONF_TEMPLATE_DIR] = '$_CONFIG_FOLDER/html/_templates';
    _settings[Config._CONF_DATA_DIR] = '$_CONFIG_FOLDER/html/_data';
    _settings[Config._CONF_LISTINGS_DIR] = '$_CONFIG_FOLDER/html/_listings';
    _settings[Config._CONF_PARTIALS_DIR] = '$_CONFIG_FOLDER/html/_partials';
    _settings[Config._CONF_ASSETS_DIR] = '$_CONFIG_FOLDER/html/_assets';

    _settings[Config._CONF_OUTPUT_DIR] = 'web';
    _settings[Config._CONF_WORKSPACE_DIR] = '.';
    _settings[Config._CONF_DATE_FORMAT] = 'dd.MM.yyyy';
    _settings[Config._CONF_YAML_DELIMITER] = '---';
    _settings[Config._CONF_USE_MARKDOWN] = true;
    _settings[Config._CONF_DEFAULT_TEMPLATE] = 'default.html';
  
    _settings[Config._CONF_BROWSER] = 'Chromium';

    _settings[Config._CONF_BROWSER] = 'Chromium';

    _settings[Config._CONF_SITE_OPTIONS] = <String, String>{};

    _settings[Options._ARG_IP] = '127.0.0.1';
    _settings[Config._CONF_PORT] = '8080';

    _settings[Options._ARG_DOCROOT] = _settings[Config._CONF_OUTPUT_DIR]; // web

    _settings[Config._CONF_USE_SECURE_CONNECTION] = false;
    _settings[Config._CONF_CERT_FILE] = 'dart.crt';
    _settings[Config._CONF_KEY_FILE] = 'dart.key';

    _settings[Config._CONF_ADDITIONAL_WATCH_FOLDER1] = '';
    _settings[Config._CONF_ADDITIONAL_WATCH_FOLDER2] = '';
    _settings[Config._CONF_ADDITIONAL_WATCH_FOLDER3] = '';

    _overwriteSettingsWithConfigFile();
    _overwriteSettingsWithArgResults();
  }

  List<String> get dirstoscan => _argResults.rest;

  String get configfolder => _CONFIG_FOLDER;

  String get configfile => 'site.yaml';

  String get loglevel => _settings[Options._ARG_LOGLEVEL] as String;

  String get contentfolder => _settings[Config._CONF_CONTENT_DIR] as String;

  String get templatefolder => _settings[Config._CONF_TEMPLATE_DIR] as String;

  String get outputfolder => _settings[Config._CONF_OUTPUT_DIR] as String;

  String get datafolder => _settings[Config._CONF_DATA_DIR] as String;

  String get listingsfolder => _settings[Config._CONF_LISTINGS_DIR] as String;

  String get partialsfolder => _settings[Config._CONF_PARTIALS_DIR] as String;

  String get assetsfolder => _settings[Config._CONF_ASSETS_DIR] as String;

  String get workspace => _settings[Config._CONF_WORKSPACE_DIR] as String;

  String get dateformat => _settings[Config._CONF_DATE_FORMAT] as String;

  String get yamldelimeter => _settings[Config._CONF_YAML_DELIMITER] as String;

  bool get usemarkdown => _settings[Config._CONF_USE_MARKDOWN] as bool;

  String get defaulttemplate =>
      _settings[Config._CONF_DEFAULT_TEMPLATE] as String;

  Map<String, String> get siteoptions =>
      _toMap(_settings[Config._CONF_SITE_OPTIONS]);

  String get ip => _settings[Options._ARG_IP] as String;

  String get port => _settings[Config._CONF_PORT].toString();

  String get docroot => _settings[Options._ARG_DOCROOT] as String;

  bool get usesecureconnection =>
      _settings[Config._CONF_USE_SECURE_CONNECTION] as bool;

  String get certfile => _settings[Config._CONF_CERT_FILE] as String;
  String get keyfile => _settings[Config._CONF_KEY_FILE] as String;

  String get browser => _settings[Config._CONF_BROWSER] as String;

  String get watchfolder1 =>
      _settings[Config._CONF_ADDITIONAL_WATCH_FOLDER1] as String;
  String get watchfolder2 =>
      _settings[Config._CONF_ADDITIONAL_WATCH_FOLDER2] as String;
  String get watchfolder3 =>
      _settings[Config._CONF_ADDITIONAL_WATCH_FOLDER3] as String;

  Map<String, String> get settings {
    final settings = <String, String>{};

    settings['loglevel'] = loglevel;

    settings['Content folder'] = contentfolder;
    settings['Template folder'] = templatefolder;
    settings['Data folder'] = datafolder;
    settings['Partials folder'] = partialsfolder;
    settings['Assets folder'] = assetsfolder;

    settings['Default template'] = defaulttemplate;
    settings['Output folder'] = outputfolder;
    settings['Workspace'] = workspace;

    settings['Dateformat'] = dateformat;
    settings['YAML-Delimeter'] = yamldelimeter;

    settings['Use markdown'] = usemarkdown ? 'yes' : 'no';

    settings['Use secure connection'] = usesecureconnection ? 'yes' : 'no';
    settings['Cert-file for secure connection'] = certfile;
    settings['Key-file for secure connection'] = keyfile;

    settings['Site options'] = siteoptions.toString();

    settings['Config folder'] = configfolder;
    settings['Config file'] = configfile;

    settings['Browser'] = browser;

    settings['IP-Address'] = ip;
    settings['Port'] = port;
    settings['Document root'] = docroot;

    settings['Additional watchfolder1'] =
        watchfolder1.isNotEmpty ? watchfolder1 : '<not set>';
    settings['Additional watchfolder2'] =
        watchfolder1.isNotEmpty ? watchfolder2 : '<not set>';
    settings['Additional watchfolder3'] =
        watchfolder1.isNotEmpty ? watchfolder3 : '<not set>';

    if (dirstoscan.isNotEmpty) {
      settings['Dirs to scan'] = dirstoscan.join(', ');
    }

    return settings;
  }

  void printSettings() {
    int getMaxKeyLength() {
      var length = 0;
      for (var key in settings.keys) {
        length = math.max(length, key.length);
      }
      return length;
    }

    final maxKeyLength = getMaxKeyLength();

    String? prepareKey(final String key) {
      if (key.isNotEmpty) {
        return '${key[0].toUpperCase()}${key.substring(1)}:'
            .padRight(maxKeyLength + 1);
      }
      return null;
    }

    print('Settings:');
    settings.forEach((final String key, final value) {
      print('    ${prepareKey(key)} $value');
    });
  }

  void printSiteKeys() {
    print('Keys for $configfile:');
    _settings.forEach((final String key, final dynamic value) {
      print('    ${('$key:').padRight(20)} $value');
    });
  }

  void _overwriteSettingsWithArgResults() {
    if (_argResults.wasParsed(Options._ARG_LOGLEVEL)) {
      _settings[Options._ARG_LOGLEVEL] = _argResults[Options._ARG_LOGLEVEL];
    }

    if (_argResults.wasParsed(Options._ARG_IP)) {
      _settings[Options._ARG_IP] = _argResults[Options._ARG_IP];
    }

    if (_argResults.wasParsed(Options._ARG_PORT)) {
      _settings[Config._CONF_PORT] = _argResults[Options._ARG_PORT];
    }

    if (_argResults.wasParsed(Options._ARG_DOCROOT)) {
      _settings[Options._ARG_DOCROOT] = _argResults[Options._ARG_DOCROOT];
    }

    if (_argResults.wasParsed(Options._ARG_USE_SECURE_CONNECTION)) {
      _settings[Config._CONF_USE_SECURE_CONNECTION] =
          _argResults[Options._ARG_USE_SECURE_CONNECTION];
    }
  }

  void _overwriteSettingsWithConfigFile() {
    final file = File('$configfolder/$configfile');
    if (!file.existsSync()) {
      return;
    }
    final map = yaml.loadYaml(file.readAsStringSync()) as yaml.YamlMap;
    for (var key in _settings.keys) {
      if (map.containsKey(key)) {
        _settings[key] = map[key];
        print('Found $key in $configfile: ${map[key]}');
      }
    }
  }

  Map<String, String> _toMap(final dynamic configOption) {
    if (configOption is Map<String, String>) {
      return configOption;
    }

    if (configOption is yaml.YamlMap) {
      return configOption.map((dynamic key, dynamic value) =>
          MapEntry<String, String>(key.toString(), value.toString()));
    } else {
      return configOption as Map<String, String>;
    }
  }
}
