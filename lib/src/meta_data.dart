// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Meta data for Youtube Video.
class YoutubeMetaData {
  /// Creates [YoutubeMetaData] for Youtube Video.
  const YoutubeMetaData({
    this.videoId = "",
    this.title = "",
    this.author = "",
    this.duration = Duration.zero,
  });

  /// Youtube video ID of the currently loaded video.
  final String videoId;

  /// Video title of the currently loaded video.
  final String title;

  /// Channel name or uploader of the currently loaded video.
  final String author;

  /// Total duration of the currently loaded video.
  final Duration duration;

  @override
  String toString() => "YoutubeMetaData("
      "videoId: $videoId, "
      "title: $title, "
      "author: $author, "
      "duration: ${duration.inSeconds} sec.)";
}
