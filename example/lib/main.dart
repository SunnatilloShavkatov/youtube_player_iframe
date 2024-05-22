// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: discarded_futures

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
          message:
              "https://www.youtube.com/watch?v=EMDhqk8VHlE&list=RDEMDhqk8VHlE&start_radio=1&ab_channel=Uzbekistan%27sclub",
          top: MediaQuery.viewPaddingOf(context).top,
        ),
      );
}

class Controls extends StatelessWidget {
  const Controls({super.key});

  @override
  Widget build(BuildContext context) => const VideoPositionSeeker();
}

class VideoPlaylistIconButton extends StatefulWidget {
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
