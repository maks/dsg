part of dsg;

/// Takes a template string (such as a Mustache template) and renders it out to an HTML string
/// using the given input values/options.
///
typedef TemplateRenderer = String Function(
    String template, Map options, PartialsResolver resolver);

/// Resolved partial-names into mustache.Templates
typedef PartialsResolver = mustache.Template Function(String name);

/// Can be set to define a custom [rendering function](TemplateRenderer) to handle your template files
/// and use any templating language of your choice.
///
/// Uses [Mustache templates](https://pub.dartlang.org/packages/mustache) by default.
///
TemplateRenderer renderTemplate =
    (final String source, final Map options, final PartialsResolver resolver) {
  final template = mustache.Template(source,
      htmlEscapeValues: false, partialResolver: resolver, lenient: true);

  return template.renderString(options);
};

class Generator {
  final Logger _logger = Logger('dsg.Generator');

  /// Mustache-Renderer strips out newlines
  static const String _NEWLINE_PROTECTOR = '@@@#@@@';

  /// Render and output your static site (WARNING: overwrites existing HTML files in output directory).
  void generate(final Config config) async {
    final contentDir = Directory(path.absolute(config.contentfolder));
    final templateDir = Directory(path.absolute(config.templatefolder));
    final outputDir = Directory(path.absolute(config.outputfolder));
    final dataDir = Directory(path.absolute(config.datafolder));
    final listingsDir = Directory(path.absolute(config.listingsfolder));
    final partialsDir = Directory(path.absolute(config.partialsfolder));
    final assetsDir = Directory(path.absolute(config.assetsfolder));

    Validate.isTrue(
        contentDir.existsSync(), 'ContentDir ${contentDir.path} must exist!');
    Validate.isTrue(templateDir.existsSync(),
        'Templatefolder ${templateDir.path} must exist!');
    Validate.isTrue(
        outputDir.existsSync(), 'OutputDir ${outputDir.path} must exist!');

    final files = _listContentFilesIn(contentDir);
    final images = _listImagesFilesIn(contentDir);
    final assets = _listAssetsFilesIn(assetsDir);
    final templates = _listTemplatesIn(templateDir);
    final dataFiles =
        dataDir.existsSync() ? _listDataFilesIn(dataDir) : <File>[];
    final listingsMap = listingsDir.existsSync()
        ? await getListingsMap(listingsDir, config.yamldelimeter)
        : null;

    final dataMap = _getDataMap(dataFiles);

    _logger.info('Listings... ${listingsMap.keys}');

    _logger.info('Generating .html files...');

    for (final file in files) {
      final relativeFileName =
          file.path.replaceAll('${contentDir.path}', '').replaceFirst('/', '');
      final relativePath = path.dirname(relativeFileName).replaceFirst('.', '');
      final extension =
          path.extension(relativeFileName).replaceFirst('.', '').toLowerCase();

      _logger.fine('\nFile: ${relativeFileName}, Path: $relativePath');

      final fileContents = file.readAsStringSync();
      fm.FrontMatterDocument fmDocument;
      try {
        fmDocument = fm.parse(fileContents, delimiter: config.yamldelimeter);
      } catch (e) {
        _logger.severe('Invalid Content File: ${file.path}');
        return;
      }
      var pageOptions = <String, dynamic>{};

      if (fmDocument.data != null) {
        pageOptions.addAll(
            fmDocument.data.map<String, dynamic>((dynamic key, dynamic value) {
          if (value is yaml.YamlList) {
            return MapEntry<String, yaml.YamlList>(key.toString(), value);
          }
          if (value is yaml.YamlMap) {
            return MapEntry<String, yaml.YamlMap>(key.toString(), value);
          }
          return MapEntry<String, String>(key.toString(), value.toString());
        }));

        _resolvePartialsInYamlBlock(
            partialsDir, pageOptions, config.usemarkdown);
      }

      pageOptions = _fillInPageNestingLevel(relativeFileName, pageOptions);
      pageOptions = _fillInDefaultPageOptions(
          config.dateformat, file, pageOptions, config.siteoptions);
      pageOptions['_data'] = dataMap;
      pageOptions['_lists'] = listingsMap;
      pageOptions['_content'] = renderTemplate(
          fmDocument.data != null ? fmDocument.content : fileContents,
          pageOptions,
          _partialsResolver(partialsDir,
              isMarkdownSupported: config.usemarkdown));

      pageOptions['_template'] = 'none';

      var outputExtension = extension;
      if (isMarkdown(file) &&
          _isMarkdownSupported(config.usemarkdown, pageOptions)) {
        pageOptions['_content'] = md.markdownToHtml(
            pageOptions['_content'] as String,
            inlineSyntaxes: [md.InlineHtmlSyntax()],
            extensionSet: md.ExtensionSet.gitHubWeb);
        outputExtension = 'html';
      }

      var templateContent = '{{_content}}';
      if ((fmDocument.data != null) &&
          (pageOptions.containsKey('template') == false ||
              pageOptions['template'] != 'none')) {
        final template = _getTemplateFor(
            file, pageOptions, templates, config.defaulttemplate);
        pageOptions['_template'] = template.path;
        _logger.fine('Template: ${path.basename(template.path)}');

        templateContent = template.readAsStringSync();
      }

      if (config.loglevel == 'debug') {
        _showPageOptions(relativeFileName, relativePath, pageOptions, config);
      }

      final content = _fixPathRefs(
          renderTemplate(
              templateContent,
              pageOptions,
              _partialsResolver(partialsDir,
                  isMarkdownSupported: config.usemarkdown)),
          config);

      final outputFilename =
          '${path.basenameWithoutExtension(relativeFileName)}.${outputExtension}';
      final outputPath = _createOutputPath(outputDir, relativePath);
      final outputFile = File('${outputPath.path}/$outputFilename');

      outputFile.writeAsStringSync(content);
      final outputPathReplaced =
          outputFile.path.replaceFirst(outputDir.path, '');
      _logger.info('   $outputPathReplaced - done!');
    }

    for (final image in images) {
      final relativeFileName =
          image.path.replaceAll('${contentDir.path}', '').replaceFirst('/', '');
      final relativePath = path.dirname(relativeFileName).replaceFirst('.', '');

      final outputPath = _createOutputPath(outputDir, relativePath);
      final outputFile =
          File('${outputPath.path}/${path.basename(relativeFileName)}');
      image.copySync(outputFile.path);

      final outputPathReplaced =
          outputFile.path.replaceFirst(outputDir.path, '');
      _logger.info('   $outputPathReplaced - copied!');
    }

    for (final asset in assets) {
      final relativeFileName =
          asset.path.replaceAll('${assetsDir.path}', '').replaceFirst('/', '');
      final relativePath = path.dirname(relativeFileName).replaceFirst('.', '');

      final outputPath = _createOutputPath(outputDir, relativePath);
      final outputFile =
          File('${outputPath.path}/${path.basename(relativeFileName)}');
      asset.copySync(outputFile.path);

      final outputPathReplaced =
          outputFile.path.replaceFirst(outputDir.path, '');
      _logger.info('   $outputPathReplaced - copied!');
    }
  }

  /// If there is a reference to a partial in the yaml block the contents of the partial becomes the
  /// contents of the page-var.
  ///
  /// Example: yaml-block in file
  /// ...
  /// dart: ->usage.badge.dart
  /// ---
  ///
  /// dart is the page-var.
  /// usage.badge.dart is the partial.
  ///
  void _resolvePartialsInYamlBlock(final Directory partialsDir,
      final Map<String, dynamic> pageOptions, bool useMarkdown) {
    pageOptions.keys.forEach((final String key) {
      if (pageOptions[key] is String &&
          (pageOptions[key] as String).contains('->')) {
        final partial =
            (pageOptions[key] as String).replaceAll(RegExp(r'[^>]*>'), '');
        pageOptions[key] = renderTemplate('{{>${partial}}}', pageOptions,
            _partialsResolver(partialsDir, isMarkdownSupported: useMarkdown));
      }
    });
  }

  /// Returns a partials-Resolver. The partials-Resolver gets a dot separated name. This name is translated
  /// into a filename / directory in _partials.
  /// Example:
  /// Name: category.house -> category/house.[html | md]
  ///
  PartialsResolver _partialsResolver(final Directory partialsDir,
      {final bool isMarkdownSupported = true}) {
    Validate.notNull(partialsDir);

    mustache.Template resolver(final String name) {
      final partialPath = partialsDir.path;
      final replacedName = name.replaceAll('.', '/');
      final partialHtml = File('$partialPath/$replacedName.html');
      final partialMd = File('$partialPath/$replacedName.md');

      var content = 'Partial with name {{$name}} is not available';
      if (partialHtml.existsSync()) {
        content = partialHtml.readAsStringSync();
      } else if (partialMd.existsSync()) {
        content = partialMd.readAsStringSync();
        if (isMarkdownSupported) {
          content = md.markdownToHtml(
            content,
            inlineSyntaxes: [md.InlineHtmlSyntax()],
            extensionSet: md.ExtensionSet.gitHubWeb,
          );
        }
      }

      return mustache.Template(content, name: '{{$name}}');
    }

    return resolver;
  }

  Directory _createOutputPath(
      final Directory outputDir, final String relativePath) {
    Validate.notNull(outputDir);

    final relPath = relativePath.isNotEmpty ? '/' : '';
    final outputPath = Directory('${outputDir.path}${relPath}${relativePath}');
    if (!outputPath.existsSync()) {
      outputPath.createSync(recursive: true);
    }
    return outputPath;
  }

  bool isMarkdown(final File file) {
    final extension = path.extension(file.path).toLowerCase();
    return extension == '.md' || extension == '.markdown';
  }

  List<File> _listContentFilesIn(final Directory contentDir) {
    if (!contentDir.existsSync()) {
      return <File>[];
    }

    return contentDir
        .listSync(recursive: true)
        .where((final FileSystemEntity entity) =>
            entity is File &&
            (entity.path.endsWith('.md') ||
                entity.path.endsWith('.markdown') ||
                entity.path.endsWith('.dart') ||
                entity.path.endsWith('.js') ||
                entity.path.endsWith('.json') ||
                entity.path.endsWith('.html') ||
                entity.path.endsWith('.scss') ||
                entity.path.endsWith('.css') ||
                entity.path.endsWith('.svg')) &&
            !entity.path.contains('packages'))
        .map((final FileSystemEntity entity) => entity as File)
        .toList();
  }

  List<File> _listImagesFilesIn(final Directory contentDir) {
    return contentDir
        .listSync(recursive: true)
        .where((file) =>
            file is File &&
            (file.path.endsWith('.png') ||
                file.path.endsWith('.jpg') ||
                file.path.endsWith('.gif') ||
                file.path.endsWith('.woff') ||
                file.path.endsWith('.tff') ||
                file.path.endsWith('.ico') ||
                file.path.endsWith('.txt') ||
                file.path.endsWith('.pdf')) &&
            !file.path.contains('packages'))
        .map((final FileSystemEntity entity) => entity as File)
        .toList();
  }

  List<File> _listAssetsFilesIn(final Directory contentDir) {
    if (!contentDir.existsSync()) {
      return <File>[];
    }

    return contentDir
        .listSync(recursive: true)
        .where((file) =>
            file is File &&
            (file.path.endsWith('.png') ||
                file.path.endsWith('.jpg') ||
                file.path.endsWith('.scss') ||
                file.path.endsWith('.css') ||
                file.path.endsWith('.svg')) &&
            !file.path.contains('packages'))
        .map((final FileSystemEntity entity) => entity as File)
        .toList();
  }

  List<File> _listTemplatesIn(final Directory templateDir) {
    return templateDir
        .listSync()
        .where((file) => file is File && !file.path.contains('packages'))
        .map((final FileSystemEntity entity) => entity as File)
        .toList();
  }

  List<File> _listDataFilesIn(final Directory dataDir) {
    return dataDir
        .listSync(recursive: true)
        .where((file) =>
            file is File &&
            (file.path.endsWith('.yaml') || file.path.endsWith('.json')) &&
            !file.path.contains('packages'))
        .map((final FileSystemEntity entity) => entity as File)
        .toList();
  }

  bool _isMarkdownSupported(
      final bool markdownForSite, final Map page_options) {
    return markdownForSite ||
        (page_options.containsKey('markdown_templating') &&
            page_options['markdown_templating'] as bool);
  }

  Map<String, dynamic> _fillInDefaultPageOptions(
      final String defaultDateFormat,
      final File file,
      final Map<String, dynamic> pageOptions,
      final Map<String, String> siteOptions) {
    final filename = path.basenameWithoutExtension(file.path);
    pageOptions.putIfAbsent('title', () => filename);

    pageOptions['_site'] = siteOptions;

    /// See [DateFormat](https://api.dartlang.org/docs/channels/stable/latest/intl/DateFormat.html) for formatting options
    final date_format = DateFormat(defaultDateFormat);

    if (pageOptions.containsKey('date_format')) {
      final page_date_format = DateFormat(pageOptions['date_format'] as String);
      pageOptions['_date'] = page_date_format.format(file.lastModifiedSync());
    } else {
      pageOptions['_date'] = date_format.format(file.lastModifiedSync());
    }

    return pageOptions;
  }

  Map _getDataMap(final List<File> dataFiles) {
    final dataMap = <String, dynamic>{};

    dataFiles.forEach((final File file) {
      if (file.existsSync()) {
        dynamic data;
        if (path.extension(file.path) == '.yaml') {
          data = yaml.loadYaml(file.readAsStringSync());
        } else {
          data = json.decode(file.readAsStringSync());
        }

        final filename = path.basenameWithoutExtension(file.path).toLowerCase();
        dataMap[filename] = data;
      }
    });

    return dataMap;
  }

  /// Sample: <link rel="stylesheet" href="{{_page.relative_to_root}}/styles/main.css">
  ///  produces <link rel="stylesheet" href="../styles/main.css"> for about/index.html
  ///
  /// Sample:
  ///  <a href="index.html" class="mdl-layout__tab {{#_page.index}}{{_page.index}}{{/_page.index}}">Overview</a>
  ///  produces:
  ///     <a href="index.html" class="mdl-layout__tab is-active">Overview</a>
  ///  if the current page is index.html
  ///
  Map<String, dynamic> _fillInPageNestingLevel(
      final String relativeFileName, Map<String, dynamic> pageOptions) {
    Validate.notBlank(relativeFileName);

    var backPath = '';
    var nestingLevel = 0;
    if (relativeFileName.contains('/')) {
      nestingLevel = relativeFileName.split('/').length - 1;
      for (var counter = 0; counter < nestingLevel; counter++) {
        backPath = backPath + '../';
      }
    }

    final pathWithoutExtension = path.withoutExtension(relativeFileName);
    // final String portablePath = pathWithoutExtension.replaceAll( RegExp('(/|\\\\\)'),':');
    final pageIndicator =
        pathWithoutExtension.replaceAll(RegExp('(/|\\\\\)'), '_');
    pageOptions['_page'] = {
      'filename': pathWithoutExtension,
      'pageindicator': pageIndicator,
      'relative_to_root': backPath,
      'nesting_level': nestingLevel,

      /// you can use this like
      ///     {{#_page.index}}{{_page.index}}{{/_page.index}
      pageIndicator: 'is-active',
    };

    return pageOptions;
  }

  File _getTemplateFor(final File file, final Map page_options,
      final List<File> templates, final String defaultTemplate) {
    final filenameWithoutExtension = path.basenameWithoutExtension(file.path);
    final filepath = path.normalize(file.path);

    File template;
    //_logger.info('Templates: ${templates}, Default: ${defaultTemplate}');

    try {
      if (page_options.containsKey('template')) {
        template = templates.firstWhere((final File file) =>
            path.basenameWithoutExtension(file.path) ==
            page_options['template']);
      } else if (defaultTemplate.isNotEmpty) {
        template = templates.firstWhere((final File file) {
          return path.basenameWithoutExtension(file.path) ==
              path.basenameWithoutExtension(defaultTemplate);
        });
      } else {
        template = templates.firstWhere((final File file) =>
            path.basenameWithoutExtension(file.path) ==
            filenameWithoutExtension);
      }
    } catch (e) {
      throw 'No template given for $filepath!';
    }

    return template;
  }

  /// Redirect resource links using relative paths to the output directory.
  /// Currently only supports replacing Unix-style relative paths.
  ///
  String _fixPathRefs(String html, final Config config) {
    var relative_output =
        path.relative(config.outputfolder, from: config.templatefolder);

    relative_output = '$relative_output/'.replaceAll('\\', '/');
    //_logger.info(relative_output);

    html = html
        .replaceAll('src="$relative_output', 'src="')
        .replaceAll('href="$relative_output', 'href="');

    return html;
  }

  /// Shows all the available vars for the current page
  ///
  void _showPageOptions(
      final String relativeFileName,
      final String relativePath,
      final Map<String, dynamic> pageOptions,
      final Config config) {
    Validate.notBlank(relativeFileName);
    Validate.notNull(relativePath);
    Validate.notNull(pageOptions);
    Validate.notNull(config);

    _logger.fine('   --- ${(relativeFileName + " ").padRight(76, "-")}');

    void _showMap(final Map<String, dynamic> values, final int nestingLevel) {
      values.forEach((final String key, final dynamic value) {
        _logger.fine('    ${"".padRight(nestingLevel * 2)} $key.');

        if (value is Map) {
          _showMap(value as Map<String, dynamic>, nestingLevel + 1);
        } else {
          var valueAsString = value.toString().replaceAll(
              RegExp('(\n|\r|\\s{2,}|${_NEWLINE_PROTECTOR})', multiLine: true),
              '');

          valueAsString =
              valueAsString.substring(0, min(50, max(valueAsString.length, 0)));
          _logger.fine(
              '    ${"".padRight(nestingLevel * 2)} $key -> [${valueAsString}]');
        }
      });
    }

    _showMap(pageOptions, 0);
    _logger.fine('   ${"".padRight(80, "-")}');
  }
}
