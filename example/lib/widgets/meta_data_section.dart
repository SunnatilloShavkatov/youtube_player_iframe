// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: discarded_futures

import "package:flutter/material.dart";
import "package:youtube_player_iframe/youtube_player_iframe.dart";

///
class MetaDataSection extends StatelessWidget {
  const MetaDataSection({super.key});

  @override
  Widget build(BuildContext context) => YoutubeValueBuilder(
        buildWhen: (YoutubePlayerValue o, YoutubePlayerValue n) =>
            o.metaData != n.metaData || o.playbackQuality != n.playbackQuality,
        builder: (BuildContext context, YoutubePlayerValue value) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _Text("Title", value.metaData.title),
            const SizedBox(height: 10),
            _Text("Channel", value.metaData.author),
            const SizedBox(height: 10),
            _Text(
              "Playback Quality",
              value.playbackQuality ?? "",
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                _Text("Video Id", value.metaData.videoId),
                const Spacer(),
                const _Text(
                  "Speed",
                  "",
                ),
                YoutubeValueBuilder(
                  builder: (BuildContext context, YoutubePlayerValue value) =>
                      DropdownButton<double>(
                    value: value.playbackRate,
                    isDense: true,
                    underline: const SizedBox(),
                    items: PlaybackRate.all
                        .map(
                          (double rate) => DropdownMenuItem<double>(
                            value: rate,
                            child: Text(
                              "${rate}x",
                              style: const TextStyle(
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (double? newValue) {
                      if (newValue != null) {
                        context.ytController.setPlaybackRate(newValue);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _Text extends StatelessWidget {
  const _Text(this.title, this.value);

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(
          text: "$title : ",
          style: Theme.of(context).textTheme.labelLarge,
          children: <InlineSpan>[
            TextSpan(
              text: value,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium!
                  .copyWith(fontWeight: FontWeight.w300),
            ),
          ],
        ),
      );
}
