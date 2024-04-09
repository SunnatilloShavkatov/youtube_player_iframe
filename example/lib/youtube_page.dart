import "dart:developer";

import "package:flutter/material.dart";
import "package:youtube_player_iframe/youtube_player_iframe.dart";
import "package:youtube_player_iframe_example/main.dart";

class YoutubePage extends StatefulWidget {
  const YoutubePage({super.key, required this.message, required this.top});

  final String message;
  final double top;

  @override
  State<YoutubePage> createState() => _YoutubePageState();
}

class _YoutubePageState extends State<YoutubePage>
    with TickerProviderStateMixin {
  bool _isFullScreen = false;
  String title = "";
  late Animation<double> animation;
  late AnimationController animationController;

  final YoutubePlayerController _controller = YoutubePlayerController(
    params: const YoutubePlayerParams(
      loop: true,
      showControls: false,
      enableJavaScript: false,
      showFullscreenButton: true,
      showVideoAnnotations: false,
    ),
  );

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // Set your desired duration
    );
    animation = Tween<double>(begin: 0, end: kToolbarHeight + widget.top)
        .animate(animationController);
    _controller
      ..setFullScreenListener(
        (bool isFullScreen) async {
          setState(() {
            _isFullScreen = isFullScreen;
          });

          log('${isFullScreen ? 'Entered' : 'Exited'} Fullscreen.');
        },
      )
      ..listen((YoutubePlayerValue event) async {
        if (event.playerState == PlayerState.playing) {
          await Future<void>.delayed(const Duration(seconds: 3), () {
            animationController.forward();
          });
        } else {
          await animationController.reverse();
        }
      })
      // ignore: discarded_futures
      ..loadVideo(widget.message);
  }

  @override
  void dispose() {
    _controller
      ..exitFullScreen()
      // ignore: discarded_futures
      ..close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => YoutubePlayerScaffold(
        backgroundColor: Colors.black,
        controller: _controller,
        builder: (_, Widget player) => YoutubeValueBuilder(
          builder: (_, YoutubePlayerValue value) => Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: GestureDetector(
                child: Stack(
                  fit: StackFit.passthrough,
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () async {
                        if (animationController.value == 1) {
                          await animationController.reverse();
                          if (_controller.value.playerState ==
                              PlayerState.playing) {
                            await Future<void>.delayed(
                              const Duration(seconds: 3),
                              () {
                                animationController.forward();
                              },
                            );
                          }
                        }
                      },
                      child: Align(child: player),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: kToolbarHeight,
                      child: AnimatedBuilder(
                        animation: animation,
                        builder: (_, __) => Transform.translate(
                          offset: Offset(0, -animation.value),
                          child: AppBar(
                            backgroundColor: Colors.transparent,
                            surfaceTintColor: Colors.transparent,
                            iconTheme: const IconThemeData(color: Colors.white),
                            titleTextStyle:
                                const TextStyle(color: Colors.white),
                            title: _isFullScreen
                                ? null
                                : Text(value.metaData.title),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: AnimatedBuilder(
                        animation: animation,
                        builder: (_, __) => Transform.translate(
                          offset: Offset(0, animation.value),
                          child: Row(
                            children: <Widget>[
                              const Expanded(child: VideoPositionSeeker()),
                              IconButton(
                                onPressed: () async {
                                  if (_isFullScreen) {
                                    _controller.exitFullScreen();
                                  } else {
                                    _controller.enterFullScreen();
                                  }
                                },
                                icon: const Icon(
                                  Icons.crop_landscape_rounded,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
      builder: (_, AsyncSnapshot<YoutubeVideoState> snapshot) {
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

class VideoPositionSeeker extends StatelessWidget {
  const VideoPositionSeeker({super.key});

  @override
  Widget build(BuildContext context) {
    double value = 0;
    const TextStyle textStyle = TextStyle(
      fontSize: 11,
      color: Colors.white,
      fontWeight: FontWeight.w500,
    );
    return StreamBuilder<YoutubeVideoState>(
      stream: context.ytController.videoStateStream,
      initialData: const YoutubeVideoState(),
      builder: (_, AsyncSnapshot<YoutubeVideoState> snapshot) {
        final int position = snapshot.data?.position.inSeconds ?? 0;
        final int duration = context.ytController.metadata.duration.inSeconds;
        value = position == 0 || duration == 0 ? 0 : position / duration;
        return Row(
          children: <Widget>[
            const SizedBox(width: 8),
            Text(position.formattedTime, style: textStyle),
            const Text(" / ", style: textStyle),
            Text(duration.formattedTime, style: textStyle),
            Expanded(
              child: Slider(
                value: value,
                onChanged: (double positionFraction) async {
                  value = positionFraction;
                  await context.ytController.seekTo(
                    seconds: value * duration,
                    allowSeekAhead: true,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
