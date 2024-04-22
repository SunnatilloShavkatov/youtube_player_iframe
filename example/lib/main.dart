// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: discarded_futures

import "dart:developer";

import "package:flutter/material.dart";
import "package:youtube_player_iframe/youtube_player_iframe.dart";

import "package:youtube_player_iframe_example/youtube_page.dart";

Future<void> main() async {
  runApp(const YoutubeApp());
}

///
class YoutubeApp extends StatelessWidget {
  const YoutubeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: "Youtube Player IFrame Demo",
        theme: ThemeData.from(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        home: YoutubePage(
          message: "https://youtu.be/2GnkIsGVDfI?si=UwLJVb2QfbQfBJyw",
          top: MediaQuery.viewPaddingOf(context).top,
        ),
      );
}

///
class YoutubeAppDemo extends StatefulWidget {
  const YoutubeAppDemo({super.key});

  @override
  State<YoutubeAppDemo> createState() => _YoutubeAppDemoState();
}

class _YoutubeAppDemoState extends State<YoutubeAppDemo> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: false,
        showFullscreenButton: true,
        showVideoAnnotations: false,
        loop: true,
      ),
    );

    _controller
      ..setFullScreenListener(
        (bool isFullScreen) {
          log('${isFullScreen ? 'Entered' : 'Exited'} Fullscreen.');
        },
      )
      ..loadVideo(
        "https://youtube.com/shorts/2GnkIsGVDfI?si=WlAnwymyr-L6_nDa",
      );
  }

  @override
  Widget build(BuildContext context) => YoutubePlayerScaffold(
        controller: _controller,
        builder: (BuildContext context, Widget player) => YoutubeValueBuilder(
          builder: (_, YoutubePlayerValue value) => Scaffold(
            body: SafeArea(
              child: Stack(
                children: <Widget>[
                  Align(child: player),
                  AnimatedPositioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    duration: const Duration(milliseconds: 300),
                    child: AppBar(
                      backgroundColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      title: const Text("Youtube Player IFrame"),
                    ),
                  ),
                  // Positioned(
                  //   bottom: 1,
                  //   left: 0,
                  //   right: 0,
                  //   child: const VideoPositionIndicator(),
                  // ),
                  const Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Controls(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}

///
class Controls extends StatelessWidget {
  ///
  const Controls({super.key});

  @override
  Widget build(BuildContext context) => const VideoPositionSeeker();
}

///
class VideoPlaylistIconButton extends StatefulWidget {
  ///
  const VideoPlaylistIconButton({super.key});

  @override
  State<VideoPlaylistIconButton> createState() =>
      _VideoPlaylistIconButtonState();
}

class _VideoPlaylistIconButtonState extends State<VideoPlaylistIconButton> {
  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: () async {},
        icon: const Icon(Icons.playlist_play_sharp),
      );
}

///
class VideoPositionIndicator extends StatelessWidget {
  const VideoPositionIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final YoutubePlayerController controller = context.ytController;

    return StreamBuilder<YoutubeVideoState>(
      stream: controller.videoStateStream,
      initialData: const YoutubeVideoState(),
      builder:
          (BuildContext context, AsyncSnapshot<YoutubeVideoState> snapshot) {
        final int position = snapshot.data?.position.inMilliseconds ?? 0;
        final int duration = controller.metadata.duration.inMilliseconds;

        return LinearProgressIndicator(
          value: duration == 0 ? 0 : position / duration,
          minHeight: 1,
        );
      },
    );
  }
}

///
class VideoPositionSeeker extends StatelessWidget {
  ///
  const VideoPositionSeeker({super.key});

  @override
  Widget build(BuildContext context) {
    double value = 0;

    return StreamBuilder<YoutubeVideoState>(
      stream: context.ytController.videoStateStream,
      initialData: const YoutubeVideoState(),
      builder:
          (BuildContext context, AsyncSnapshot<YoutubeVideoState> snapshot) {
        final int position = snapshot.data?.position.inSeconds ?? 0;
        final int duration = context.ytController.metadata.duration.inSeconds;

        value = position == 0 || duration == 0 ? 0 : position / duration;

        return StatefulBuilder(
          builder: (BuildContext context, setState) => Row(
            children: <Widget>[
              Expanded(
                child: Slider(
                  value: value,
                  onChanged: (double positionFraction) {
                    value = positionFraction;
                    setState(() {});

                    context.ytController.seekTo(
                      seconds: value * duration,
                      allowSeekAhead: true,
                    );
                  },
                ),
              ),
              Text(position.formattedTime),
              const Text(" / "),
              Text(duration.formattedTime),
            ],
          ),
        );
      },
    );
  }
}

extension StringExtension on String {
  String? get appendZeroPrefix => length <= 1 ? "0$this" : this;
}

extension IntExtension on num {
  String get formattedTime {
    final String sec = (this % 60).toString();
    final String min = (this / 60).floor().toString();
    return "${min.appendZeroPrefix}:${sec.appendZeroPrefix}";
  }
}
