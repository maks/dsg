part of dsg;

class CommandManager {
  static String SASS = 'sass';
  static String SASSC = 'sassc';
  static String AUTOPREFIXER = 'autoprefixer-cli';
  static String SAY = 'say';

  static CommandManager _commandmanager;

  final Map<String, Command> _commands;

  static Future<CommandManager> getInstance() async {
    if (_commandmanager == null) {
      final commands = await _getAvailableCommands();
      _commandmanager = CommandManager._private(commands);
    }
    return _commandmanager;
  }

  Command operator [](final String key) => _commands[key];

  bool containsKey(final String key) => _commands.containsKey(key);

  CommandManager._private(this._commands);
}

class Command {
  final String name;
  final String exe;

  Command(this.name, this.exe);
}

/// Test if necessary commands are available
Future<Map<String, Command>> _getAvailableCommands() async {
  final commands = <String, Command>{};
  final names = <String>[
    CommandManager.SASS,
    CommandManager.SASSC,
    CommandManager.AUTOPREFIXER,
    CommandManager.SAY,
    //CommandManager.OSASCRIPT,
  ];

  await Future.forEach(names, (final String binName) async {
    try {
      final exe = (await where(binName)) as String;
      commands[binName] = Command(binName, exe);
    } catch (_) {}
  });

  return commands;
}
