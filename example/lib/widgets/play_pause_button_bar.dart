// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: discarded_futures

import "package:flutter/material.dart";
import "package:youtube_player_iframe/youtube_player_iframe.dart";

///
class PlayPauseButtonBar extends StatelessWidget {
  PlayPauseButtonBar({super.key});

  final ValueNotifier<bool> _isMuted = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.skip_previous),
            onPressed: context.ytController.previousVideo,
          ),
          YoutubeValueBuilder(
            builder: (BuildContext context, YoutubePlayerValue value) =>
                IconButton(
              icon: Icon(
                value.playerState == PlayerState.playing
                    ? Icons.pause
                    : Icons.play_arrow,
              ),
              onPressed: () {
                value.playerState == PlayerState.playing
                    ? context.ytController.pauseVideo()
                    : context.ytController.playVideo();
              },
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _isMuted,
            builder: (BuildContext context, bool isMuted, _) => IconButton(
              icon: Icon(isMuted ? Icons.volume_off : Icons.volume_up),
              onPressed: () {
                _isMuted.value = !isMuted;
                isMuted
                    ? context.ytController.unMute()
                    : context.ytController.mute();
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.skip_next),
            onPressed: context.ytController.nextVideo,
          ),
        ],
      );
}
