import 'package:grinder/grinder.dart';

void main(final List<String> args) => grind(args);

@Task()
@Depends(test, buildSamples)
void build() {}

@Task()
void clean() => defaultClean();

@Task()
@Depends(analyze)
void buildSamples() async {
  // Sitegen Sample
  await runAsync("buildSamples", arguments: ["--sitegen"]);

  // Update Sample
  await runAsync("buildSamples", arguments: ["-u"]);

  // Analyze
  analyze();

  // Build!
  await runAsync("buildSamples", arguments: ["-bc"]);
}

@Task()
@Depends(analyze)
void test() {
  // TestRunner().testAsync(files: "test/unit");
  // TestRunner().testAsync(files: "test/integration");

  // Alle test mit @TestOn("content-shell") im header
  // TestRunner().test(files: "test/unit",platformSelector: "content-shell");
  // TestRunner().test(files: "test/integration",platformSelector: "content-shell");
}

@Task()
void analyze() {
  final libs = ["lib/sitegen.dart", "bin/sitegen.dart"];

  libs.forEach((final String lib) => Analyzer.analyze(lib));
  // Analyzer.analyze("test");
}

@Task('Deploy built app.')
void deploy() {
  run(sdkBin('pub'),
      arguments: ["global", "activate", "--source", "path", "."]);
}
