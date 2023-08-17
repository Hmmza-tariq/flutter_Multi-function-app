import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:student/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class RecordedVideosPage extends StatelessWidget {
  final String appDocPath;

  const RecordedVideosPage({super.key, required this.appDocPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recorded Videos')),
      body: FutureBuilder<List<FileSystemEntity>>(
        future: Directory(appDocPath).list().toList(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          List<FileSystemEntity> files = snapshot.data!;
          Size screenSize = MediaQuery.of(context).size / 3;
          files = files.skip(2).toList();

          return Center(
            child: SingleChildScrollView(
              child: Wrap(
                children: files.map((file) {
                  return FutureBuilder<Uint8List?>(
                    future: VideoThumbnail.thumbnailData(
                      timeMs: 5000,
                      video: file.path,
                      imageFormat: ImageFormat.JPEG,
                      quality: 50,
                    ),
                    builder: (context, thumbSnapshot) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.grey,
                            boxShadow: [
                              BoxShadow(color: Colors.black, blurRadius: 4),
                            ],
                          ),
                          child: SizedBox(
                            width: screenSize.width,
                            height: screenSize.height,
                            child: (!thumbSnapshot.hasData)
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => VideoPlayerPage(
                                            videoPath: file.path,
                                          ),
                                        ),
                                      );
                                    },
                                    child: SizedBox(
                                      width: 100,
                                      height: 100,
                                      child: Image.memory(thumbSnapshot.data!),
                                    ),
                                  ),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
