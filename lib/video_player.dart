import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student/theme_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VideoPlayerPage extends StatelessWidget {
  final String videoPath;

  const VideoPlayerPage({super.key, required this.videoPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: VideoPlayerWidget(videoPath: videoPath),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoPath;

  const VideoPlayerWidget({super.key, required this.videoPath});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

enum TtsState { playing, stopped, paused, continued }

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isVideoPlaying = false;
  bool _isAudioPlaying = false;
  final textRecognizer = TextRecognizer();
  String text = 'Nothing here yet!';
  FlutterTts flutterTts = FlutterTts();
  String _textToRead = 'Your text goes here';
  double _startOffset = 0.0;
  double _endOffset = 0.0;
  @override
  void initState() {
    initTts();
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath));
    _controller.initialize().then((_) {
      setState(() {});
    });
    _controller.addListener(() {
      if (!_controller.value.isPlaying &&
          _controller.value.position >= _controller.value.duration) {
        setState(() {
          _isVideoPlaying = false;
        });
      }
      if (_isVideoPlaying) {
        _scanVideo();
      }
    });
  }

  @override
  void dispose() {
    flutterTts.stop();
    textRecognizer.close();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size / 1.5;
    double screenWidth = screenSize.width;
    double screenHeight = screenSize.height;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  boxShadow: [
                    BoxShadow(color: Colors.black, blurRadius: 4),
                  ],
                ),
                height: screenHeight,
                width: screenWidth,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: VideoPlayer(_controller),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isVideoPlaying ? Icons.pause : Icons.play_arrow,
                      ),
                      onPressed: () {
                        if (_isVideoPlaying) {
                          _controller.pause();
                        } else {
                          _controller.play();
                        }
                        setState(() {
                          _isVideoPlaying = !_isVideoPlaying;
                        });
                      },
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20.0),
                        child: VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: FloatingActionButton(
                      backgroundColor: Colors.green,
                      onPressed: _speak,
                      child: const Center(
                        child: Icon(
                          Icons.volume_up,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  //   child: FloatingActionButton(
                  //     backgroundColor: Colors.amber,
                  //     onPressed: _isAudioPlaying ? _pause : resumeTextToSpeech,
                  //     child: Center(
                  //       child: Icon(
                  //         _isAudioPlaying
                  //             ? Icons.pause
                  //             : Icons.play_arrow_sharp,
                  //         color: Colors.white,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: FloatingActionButton(
                      backgroundColor: Colors.red,
                      onPressed: _stop,
                      child: const Center(
                        child: Icon(
                          Icons.stop,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _inputSection(themeProvider),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _scanVideo() async {
    try {
      Size screenSize = MediaQuery.of(context).size / 1.5;
      final currentPosition = _controller.value.position;
      final thumbnailBytes = await VideoThumbnail.thumbnailData(
        video: _controller.dataSource,
        imageFormat: ImageFormat.JPEG,
        maxWidth: screenSize.width.toInt(),
        maxHeight: screenSize.height.toInt(),
        quality: 25,
        timeMs: currentPosition.inMilliseconds,
      );

      final pictureFile = File('${widget.videoPath}.jpg');
      await pictureFile.writeAsBytes(thumbnailBytes!);

      final file = File(pictureFile.path);

      final inputImage = InputImage.fromFile(file);
      final recognizedText = await textRecognizer.processImage(inputImage);
      setState(() {
        _newVoiceText = recognizedText.text;
        _textEditingController.text = recognizedText.text;
      });
      print('recognizedText: $recognizedText');
    } catch (e) {
      print('Error:  $e');
      text = 'An error occurred when scanning text';
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred when scanning text'),
        ),
      );
    }
  }

  void startTextToSpeech(
      String text, double startOffset, double endOffset) async {
    setState(() {
      _isAudioPlaying = true;
      _textToRead = text;
      _startOffset = startOffset;
      _endOffset = endOffset;
    });

    await flutterTts.setLanguage("en-US");
    await flutterTts.setVolume(0.5);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1);

    flutterTts
        .setProgressHandler((String text, int start, int end, String word) {
      if (start >= _startOffset.toInt() && end <= _endOffset.toInt()) {
        _scanVideo();
      }
    });

    await flutterTts
        .speak(_textToRead.substring(_startOffset.toInt(), _endOffset.toInt()));
  }

  void stopTextToSpeech() {
    setState(() {
      _isAudioPlaying = false;
    });
    flutterTts.stop();
    flutterTts.pause();
  }

  void pauseTextToSpeech() async {
    setState(() {
      _isAudioPlaying = false;
      _textToRead = text.substring(_startOffset.toInt(), _endOffset.toInt());
    });
    await flutterTts.stop();
  }

  void resumeTextToSpeech() async {
    setState(() {
      _isAudioPlaying = true;
    });
    await flutterTts.speak(_newVoiceText!);
  }

//-------------------------------------------------
  String? language;
  String? engine;
  double volume = 0.5;
  double pitch = 1.0;
  double rate = 0.5;
  bool isCurrentLanguageInstalled = false;
  final TextEditingController _textEditingController = TextEditingController();
  String? _newVoiceText;
  // int? _inputLength;

  TtsState ttsState = TtsState.stopped;

  get isPlaying => ttsState == TtsState.playing;
  get isStopped => ttsState == TtsState.stopped;
  get isPaused => ttsState == TtsState.paused;
  get isContinued => ttsState == TtsState.continued;

  bool isAndroid = true;

  initTts() {
    flutterTts = FlutterTts();

    _setAwaitOptions();

    if (isAndroid) {
      _getDefaultEngine();
      _getDefaultVoice();
    }

    flutterTts.setStartHandler(() {
      setState(() {
        print("Playing");
        ttsState = TtsState.playing;
      });
    });

    if (isAndroid) {
      flutterTts.setInitHandler(() {
        setState(() {
          print("TTS Initialized");
        });
      });
    }

    flutterTts.setCompletionHandler(() {
      setState(() {
        print("Complete");
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setCancelHandler(() {
      setState(() {
        print("Cancel");
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setPauseHandler(() {
      setState(() {
        print("Paused");
        ttsState = TtsState.paused;
      });
    });

    flutterTts.setContinueHandler(() {
      setState(() {
        print("Continued");
        ttsState = TtsState.continued;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        print("error: $msg");
        ttsState = TtsState.stopped;
      });
    });
  }

  Future _getDefaultEngine() async {
    var engine = await flutterTts.getDefaultEngine;
    if (engine != null) {
      print(engine);
    }
  }

  Future _getDefaultVoice() async {
    var voice = await flutterTts.getDefaultVoice;
    if (voice != null) {
      print(voice);
    }
  }

  Future _setAwaitOptions() async {
    await flutterTts.awaitSpeakCompletion(true);
  }

  Future _speak() async {
    print(_newVoiceText);
    setState(() {
      _isAudioPlaying = true;
    });
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);

    if (_newVoiceText != null) {
      if (_newVoiceText!.isNotEmpty) {
        await flutterTts.speak(_newVoiceText!);
      }
    }
  }

  Future _stop() async {
    setState(() {
      _isAudioPlaying = false;
    });
    var result = await flutterTts.stop();
    if (result == 1) setState(() => ttsState = TtsState.stopped);
  }

  Future _pause() async {
    setState(() {
      _isAudioPlaying = false;
    });
    var result = await flutterTts.pause();
    if (result == 1) setState(() => ttsState = TtsState.paused);
  }

  List<DropdownMenuItem<String>> getEnginesDropDownMenuItems(dynamic engines) {
    var items = <DropdownMenuItem<String>>[];
    for (dynamic type in engines) {
      items.add(DropdownMenuItem(
          value: type as String?, child: Text(type as String)));
    }
    return items;
  }

  void changedEnginesDropDownItem(String? selectedEngine) async {
    await flutterTts.setEngine(selectedEngine!);
    language = null;
    setState(() {
      engine = selectedEngine;
    });
  }

  List<DropdownMenuItem<String>> getLanguageDropDownMenuItems(
      dynamic languages) {
    var items = <DropdownMenuItem<String>>[];
    for (dynamic type in languages) {
      items.add(DropdownMenuItem(
          value: type as String?, child: Text(type as String)));
    }
    return items;
  }

  void changedLanguageDropDownItem(String? selectedType) {
    setState(() {
      language = selectedType;
      flutterTts.setLanguage(language!);
      if (isAndroid) {
        flutterTts
            .isLanguageInstalled(language!)
            .then((value) => isCurrentLanguageInstalled = (value as bool));
      }
    });
  }

  void _onChange(String text) {
    setState(() {
      _newVoiceText = text;
    });
  }

  Widget _inputSection(ThemeProvider themeProvider) => Container(
      color: _isVideoPlaying
          ? Colors.yellow
          : _isAudioPlaying
              ? Colors.greenAccent
              : Colors.white,
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.only(top: 25.0, left: 25.0, right: 25.0),
      child: TextField(
        style: themeProvider.title.copyWith(color: Colors.black),
        controller: _textEditingController,
        maxLines: 11,
        minLines: 6,
        onChanged: (value) {
          _onChange(_textEditingController.text);
        },
      ));
}
