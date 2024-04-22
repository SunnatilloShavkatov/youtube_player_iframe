// ignore_for_file: discarded_futures

import "package:flutter/material.dart";
import "package:youtube_player_iframe/youtube_player_iframe.dart";

const List<String> _videoIds = <String>[
  "dHuYBB05bYU",
  "RpoFTgWRfJ4",
  "82u-4xcsyJU",
];

///
class VideoListPage extends StatefulWidget {
  ///
  const VideoListPage({super.key});

  @override
  State<VideoListPage> createState() => _VideoListPageState();
}

class _VideoListPageState extends State<VideoListPage> {
  late final List<YoutubePlayerController> _controllers;

  @override
  void initState() {
    super.initState();

    _controllers = List<YoutubePlayerController>.generate(
      _videoIds.length,
      (int index) => YoutubePlayerController.fromVideoId(
        videoId: _videoIds[index],
        params: const YoutubePlayerParams(showFullscreenButton: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text("Video List Demo"),
        ),
        body: ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: _controllers.length,
          itemBuilder: (BuildContext context, int index) {
            final YoutubePlayerController controller = _controllers[index];

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: YoutubePlayer(
                  key: ObjectKey(controller),
                  enableFullScreenOnVerticalDrag: false,
                  controller: controller
                    ..setFullScreenListener(
                      (_) async {
                        final VideoData videoData = await controller.videoData;
                        final double startSeconds =
                            await controller.currentTime;

                        if (context.mounted) {
                          final double? currentTime =
                              await FullscreenYoutubePlayer.launch(
                            context,
                            videoId: videoData.videoId,
                            startSeconds: startSeconds,
                          );
                          if (currentTime != null) {
                            await controller.seekTo(seconds: currentTime);
                          }
                        }
                      },
                    ),
                ),
              ),
            );
          },
          separatorBuilder: (BuildContext context, _) =>
              const SizedBox(height: 16),
        ),
      );

  @override
  void dispose() {
    for (final YoutubePlayerController controller in _controllers) {
      controller.close();
    }
    super.dispose();
  }
}
