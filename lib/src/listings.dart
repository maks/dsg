import 'dart:io';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart' as yaml;
import 'package:front_matter/front_matter.dart' as fm;

final Logger _logger = Logger('dsg.Generator');

class ListingConfig {
  final Map<dynamic, dynamic> _config;
  String get path => _config['path'] as String;
  String get filter => _config['filter'] as String;
  String get sortby => _config['sort_by'] as String;

  ListingConfig(this._config);
}

/// Returns a Map, wher each key is the name of "listing",
/// the a listing is a List of Maps, where each Map represents the
/// metadata for a MD file, including any YAMl Frontmatter that file has
Future<Map<String, List<Map>>> getListingsMap(
    Directory dir, String yamlDelimiter) async {
  final listingConfigs = _listingsFilesIn(dir);

  final configsMap = _getListingConfigMap(listingConfigs);

  final listingsMap = configsMap
      .map((key, value) => MapEntry(key, _dirList(value, yamlDelimiter)));

  final listings = <String, List<Map>>{};

  await Future.wait(listingsMap.values);
  await listingsMap.forEach((key, value) async {
    listings[key] = await value;

    // TODO:
    _logger.info('SORT listing: $key BY: ${configsMap[key].sortby}');
  });
  return listings;
}

// given a listing config, return a List whose items are Maps, with each map
// representing a file in config.path and the contents of the maps containing
// both meta-data of the file (eg. filename, mod date, etc) as we as the
// front-matter data (if any) inside each of those files if they are markdown
// or html files
Future<List<Map<dynamic, dynamic>>> _dirList(
    ListingConfig config, String yamldelimiter) {
  final folderList = Directory(path.join('.dsg/html/_content', config.path))
      .listSync(recursive: false, followLinks: false)
      .where((f) => !FileSystemEntity.isDirectorySync(f.path))
      .map((e) => e as File)
      .where((f) => path.basenameWithoutExtension(f.path) != 'index')
      .toList();

  return Future.wait(folderList.map((e) => fileDataMap(e, yamldelimiter)));
}

Future<Map<dynamic, dynamic>> fileDataMap(File f, String yamldelimiter) async {
  final fileData = <dynamic, dynamic>{};
  fileData['filename'] = path.basenameWithoutExtension(f.path);
  fileData['last_modified'] = f.lastModifiedSync();

  fileData.addAll(await _getFrontMatter(f.path, yamldelimiter));

  return fileData;
}

Future<Map<String, dynamic>> _getFrontMatter(
    String filePath, String yamldelimiter) async {
  final extension = path.extension(filePath);
  if (extension != '.md' && extension != '.html') {
    return <String, dynamic>{};
  }
  try {
    return (await fm.parseFile(filePath, delimiter: yamldelimiter))
        .data
        .value
        .cast<String, dynamic>();
  } catch (e) {
    _logger.severe(e, 'failed parsing frontmatter in: $filePath');
    return <String, dynamic>{};
  }
}

//
Map<String, ListingConfig> _getListingConfigMap(final List<File> listingFiles) {
  final listingMap = <String, ListingConfig>{};

  listingFiles.forEach((final File file) {
    if (file.existsSync()) {
      dynamic data;
      if (path.extension(file.path) == '.yaml') {
        data = yaml.loadYaml(file.readAsStringSync());
      }
      final filename = path.basenameWithoutExtension(file.path).toLowerCase();
      listingMap[filename] = ListingConfig((data as yaml.YamlMap).value);
    }
  });
  return listingMap;
}

List<File> _listingsFilesIn(final Directory listingsDir) {
  return listingsDir
      .listSync(recursive: true)
      .where((file) => file is File && (file.path.endsWith('.yaml')))
      .map((final FileSystemEntity entity) => entity as File)
      .toList();
}
