import 'dart:async';
import 'dart:io';
import 'package:ed_screen_recorder/ed_screen_recorder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student/recorded_video.dart';
import 'package:student/settings_screen.dart';
import 'package:student/theme_provider.dart';
import 'package:alan_voice/alan_voice.dart';
import 'package:student/video_player.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sp = await SharedPreferences.getInstance();
  final int? colorValue = sp.getInt('theme_color');
  final double? size = sp.getDouble('font_size');
  Color initialColor = colorValue != null
      ? Color(colorValue)
      : const Color.fromARGB(255, 2, 99, 181);
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider<ThemeProvider>(
      create: (_) => ThemeProvider(initialColor, size ?? 16),
    ),
  ], child: const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeData = ThemeData(
      fontFamily: AppTheme.fontName,
      scaffoldBackgroundColor: themeProvider.primaryColor,
      appBarTheme: AppBarTheme(
          actionsIconTheme: IconThemeData(
              color: themeProvider.primaryColor.computeLuminance() > .3
                  ? Colors.black
                  : Colors.white),
          iconTheme: IconThemeData(
              color: themeProvider.primaryColor.computeLuminance() > .3
                  ? Colors.black
                  : Colors.white),
          titleTextStyle: TextStyle(
              fontSize: 20,
              fontFamily: AppTheme.fontName,
              fontWeight: FontWeight.bold,
              color: themeProvider.primaryColor.computeLuminance() > .3
                  ? Colors.black
                  : Colors.white),
          backgroundColor: themeProvider.primaryColor.withOpacity(.5),
          shadowColor: Colors.black,
          elevation: 5),
      useMaterial3: true,
      primarySwatch: MaterialColor(
        themeProvider.primaryColor.value,
        <int, Color>{
          50: themeProvider.primaryColor.withOpacity(0.1),
          100: themeProvider.primaryColor.withOpacity(0.2),
          200: themeProvider.primaryColor.withOpacity(0.3),
          300: themeProvider.primaryColor.withOpacity(0.4),
          400: themeProvider.primaryColor.withOpacity(0.5),
          500: themeProvider.primaryColor.withOpacity(0.6),
          600: themeProvider.primaryColor.withOpacity(0.7),
          700: themeProvider.primaryColor.withOpacity(0.8),
          800: themeProvider.primaryColor.withOpacity(0.9),
          900: themeProvider.primaryColor,
        },
      ),
      textTheme: AppTheme.textTheme,
    );
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness:
          !kIsWeb && Platform.isAndroid ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
    return MaterialApp(
      theme: themeData,
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  EdScreenRecorder? screenRecorder;
  Map<String, dynamic>? _response;
  bool inProgress = false;
  String appDocPath = '';
  late List<FileSystemEntity> files;
  @override
  void initState() {
    getData();
    _MyHomePageState();
    super.initState();
    screenRecorder = EdScreenRecorder();
  }

  Future<void> getData() async {
    Directory? appDocDirectory = await getApplicationDocumentsDirectory();
    appDocPath = appDocDirectory.path;
  }

  Future<void> startRecord({required String fileName}) async {
    Directory? tempDir = await getApplicationDocumentsDirectory();
    String? tempPath = tempDir.path;
    try {
      var startResponse = await screenRecorder?.startRecordScreen(
        fileName: fileName,
        dirPathToSave: tempPath,
        audioEnable: false,
      );
      setState(() {
        _response = startResponse;
        inProgress = true;
      });
    } on PlatformException {
      setState(() {
        inProgress = false;
      });
      if (kDebugMode) {
        debugPrint("Error: An error occurred while starting the recording!");
        print("Error: $_response");
      }
    }
  }

  Future<void> stopRecord() async {
    try {
      var stopResponse = await screenRecorder?.stopRecord();
      setState(() {
        _response = stopResponse;
        inProgress = false;
      });

      // ignore: use_build_context_synchronously
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text('Recording Stopped'),
                subtitle: Text('Recording has been successfully stopped.'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } on PlatformException {
      setState(() {
        inProgress = true;
      });
      if (kDebugMode) {
        debugPrint("Error: An error occurred while stopping recording.");
        print("Error: $_response");
      }
    }
  }

  Future<void> pauseRecord() async {
    try {
      await screenRecorder?.pauseRecord();
      // ignore: use_build_context_synchronously
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text('Recording Paused'),
                subtitle: Text('Recording has been successfully paused.'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } on PlatformException {
      kDebugMode
          ? debugPrint("Error: An error occurred while pause recording.")
          : null;
    }
  }

  Future<void> resumeRecord() async {
    try {
      await screenRecorder?.resumeRecord();
      // ignore: use_build_context_synchronously
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text('Recording Resumed'),
                subtitle: Text('Recording has been successfully resumed.'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } on PlatformException {
      kDebugMode
          ? debugPrint("Error: An error occurred while resume recording.")
          : null;
    }
  }

  _MyHomePageState() {
    AlanVoice.addButton(
        "deleted",
        buttonAlign: AlanVoice.BUTTON_ALIGN_RIGHT);

    AlanVoice.onCommand.add((command) => handleCommand(command.data));
  }

  void handleCommand(Map<String, dynamic> command) {
    switch (command["command"]) {
      case "start":
        startRecord(fileName: '');
        break;
      case "stop":
        stopRecord();
        break;
      case "pause":
        pauseRecord();
        break;
      case "resume":
        resumeRecord();
        break;
      case "settings":
        {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SettingsScreen(),
            ),
          );
        }
        break;
      case "recorded":
        {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecordedVideosPage(appDocPath: appDocPath),
            ),
          );
        }
        break;
      case "back":
        {
          Navigator.pop(context);
        }
        break;
      case "video":
        {
          String indexAsString = command["text"];
          int index = 1;
          try {
            index = int.parse(indexAsString);
          } catch (e) {
            index = convertTextToNumber(indexAsString);
          }
          openVideoAtIndex(index);
        }
        break;
      default:
    }
  }

  int convertTextToNumber(String text) {
    Map<String, int> wordToNumber = {
      'zero': 0,
      'one': 1,
      'two': 2,
      'three': 3,
      'four': 4,
      'five': 5,
      'six': 6,
      'seven': 7,
      'eight': 8,
      'nine': 9,
      'ten': 10,
      'eleven': 11,
      'twelve': 12,
      'thirteen': 13,
      'fourteen': 14,
      'fifteen': 15,
      'sixteen': 16,
      'seventeen': 17,
      'eighteen': 18,
      'nineteen': 19,
      'twenty': 20,
    };

    String cleanedText = text.trim();

    int numericValue = wordToNumber[cleanedText] ?? 0;

    return numericValue;
  }

  void openVideoAtIndex(int index) async {
    files = await Directory(appDocPath).list().toList();
    index += 1;
    if (index >= 0 && index < files.length) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerPage(
            videoPath: files[index].path,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Center(child: Text("Student app")),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Settings',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () => startRecord(fileName: "Recording"),
                  child: Text(
                    'START RECORD',
                    style: themeProvider.title,
                  )),
              inProgress
                  ? Column(
                      children: [
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orangeAccent,
                            ),
                            onPressed: () => resumeRecord(),
                            child: Text(
                              'RESUME RECORD',
                              style: themeProvider.title,
                            )),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orangeAccent,
                            ),
                            onPressed: () => pauseRecord(),
                            child: Text(
                              'PAUSE RECORD',
                              style: themeProvider.title,
                            )),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () => stopRecord(),
                            child: Text(
                              'STOP RECORD',
                              style: themeProvider.title,
                            )),
                      ],
                    )
                  : Container(),
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            RecordedVideosPage(appDocPath: appDocPath),
                      ),
                    );
                  },
                  child: Text(
                    'OPEN RECORDED VIDEOS',
                    textAlign: TextAlign.center,
                    style: themeProvider.title,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
