// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import "package:flutter/widgets.dart";

import "package:youtube_player_iframe/src/controller/youtube_player_controller.dart";

/// An inherited widget to provide [YoutubePlayerController] to it's descendants.
class YoutubePlayerControllerProvider extends InheritedWidget {

  /// An inherited widget that provide [YoutubePlayerController] to it's descendants.
  const YoutubePlayerControllerProvider({
    super.key,
    required this.controller,
    required super.child,
  });
  /// The [YoutubePlayerController].
  final YoutubePlayerController controller;

  /// Finds the most recent [YoutubePlayerController] in its ancestors.
  static YoutubePlayerController of(BuildContext context) {
    final YoutubePlayerControllerProvider? controllerProvider = context
        .dependOnInheritedWidgetOfExactType<YoutubePlayerControllerProvider>();
    assert(
      controllerProvider != null,
      "Cannot find YoutubePlayerControllerProvider above. Please wrap parent widget with YoutubePlayerControllerProvider.",
    );
    return controllerProvider!.controller;
  }

  /// Finds the most recent [YoutubePlayerController] in its ancestors.
  static YoutubePlayerController? maybeOf(BuildContext context) {
    final YoutubePlayerControllerProvider? controllerProvider = context
        .dependOnInheritedWidgetOfExactType<YoutubePlayerControllerProvider>();

    return controllerProvider?.controller;
  }

  @override
  bool updateShouldNotify(YoutubePlayerControllerProvider oldWidget) => oldWidget.controller.hashCode != controller.hashCode;
}

/// YoutubePlayerControllerExtension
extension YoutubePlayerControllerExtension on BuildContext {
  /// Finds the most recent [YoutubePlayerController] in its ancestors.
  YoutubePlayerController get ytController => YoutubePlayerControllerProvider.of(this);
}
