// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import "package:flutter/foundation.dart";
import "package:youtube_player_iframe/youtube_player_iframe.dart";

/// Youtube Player value
class YoutubePlayerValue {
  /// The duration, current position, buffering state, error state and settings
  /// of a [YoutubePlayerController].
  YoutubePlayerValue({
    this.fullScreenOption = const FullScreenOption(enabled: false),
    this.playerState = PlayerState.unknown,
    this.playbackRate = PlaybackRate.normal,
    this.playbackQuality,
    this.error = YoutubeError.none,
    this.metaData = const YoutubeMetaData(),
  });

  /// The initial fullscreen option.
  final FullScreenOption fullScreenOption;

  /// The current state of the player defined as [PlayerState].
  final PlayerState playerState;

  /// The current video playback rate defined as [PlaybackRate].
  final double playbackRate;

  /// Reports the error code as described [here](https://developers.google.com/youtube/iframe_api_reference#Events).
  ///
  /// See the onError Section.
  final YoutubeError error;

  /// Returns true is player has errors.
  bool get hasError => error != YoutubeError.none;

  /// Reports the current playback quality.
  final String? playbackQuality;

  /// Returns meta data of the currently loaded/cued video.
  final YoutubeMetaData metaData;

  @override
  String toString() => "YoutubePlayerValue("
      "metaData: $metaData, "
      "playerState: $playerState, "
      "playbackRate: $playbackRate, "
      "playbackQuality: $playbackQuality, "
      "isFullScreen: ${fullScreenOption.enabled}, "
      "error: $error)";
}

/// The fullscreen option.
@immutable
class FullScreenOption {
  /// Creates [FullScreenOption].
  const FullScreenOption({
    required this.enabled,
    this.locked = false,
  });

  /// Denotes that the fullscreen mode is currently enabled.
  final bool enabled;

  /// Denotes that the fullscreen mode is currently locked for auto update.
  final bool locked;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FullScreenOption &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          locked == other.locked;

  @override
  int get hashCode => enabled.hashCode ^ locked.hashCode;
}
