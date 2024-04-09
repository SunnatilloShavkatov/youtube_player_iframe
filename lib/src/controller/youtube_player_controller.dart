// ignore_for_file: discarded_futures, always_specify_types

import "dart:async";
import "dart:convert";
import "dart:developer";

import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:meta/meta.dart";
import "package:url_launcher/url_launcher.dart" as uri_launcher;
import "package:webview_flutter/webview_flutter.dart";
import "package:webview_flutter_android/webview_flutter_android.dart";
// import "package:webview_flutter_platform_interface/src/platform_webview_controller.dart";
import "package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart";
import "package:youtube_player_iframe/src/controller/youtube_player_event_handler.dart";
import "package:youtube_player_iframe/youtube_player_iframe.dart";

/// The Web Resource Error.
typedef YoutubeWebResourceError = WebResourceError;

const String pattern =
    r"^(?:https?:\/\/)?(?:www\.)?(?:m\.|youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|shorts\/))((\w|-){11})(?:\S+)?$";
const String shortsUrlPattern = r"^https:\/\/(?:www\.|m\.)?youtube\.com\/shorts\/";
final RegExp regExp = RegExp(pattern);
final RegExp shortsRegExp = RegExp(shortsUrlPattern);

/// Controls the youtube player, and provides updates when the state is changing.
///
/// The video is displayed in a Flutter app by creating a [YoutubePlayer] widget.
///
/// After [YoutubePlayerController.close] all further calls are ignored.
class YoutubePlayerController implements YoutubePlayerIFrameAPI {
  /// Creates [YoutubePlayerController].
  YoutubePlayerController({
    this.params = const YoutubePlayerParams(),
    ValueChanged<YoutubeWebResourceError>? onWebResourceError,
  }) {
    _eventHandler = YoutubePlayerEventHandler(this);

    late final PlatformWebViewControllerCreationParams webViewParams;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      webViewParams = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      webViewParams = const PlatformWebViewControllerCreationParams();
    }

    final NavigationDelegate navigationDelegate = NavigationDelegate(
      onWebResourceError: (WebResourceError error) {
        log(error.description, name: error.errorType.toString());
        onWebResourceError?.call(error);
      },
      onNavigationRequest: (NavigationRequest request) {
        final Uri? uri = Uri.tryParse(request.url);
        return _decideNavigation(uri);
      },
    );

    webViewController = WebViewController.fromPlatformCreationParams(
      webViewParams,
    )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(navigationDelegate)
      ..setUserAgent(params.userAgent)
      ..addJavaScriptChannel(
        _youtubeJSChannelName,
        onMessageReceived: _eventHandler.call,
      )
      ..enableZoom(false);

    final webViewPlatform = webViewController.platform;
    if (webViewPlatform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(false);
      webViewPlatform.setMediaPlaybackRequiresUserGesture(false);
    } else if (webViewPlatform is WebKitWebViewController) {
      webViewPlatform.setAllowsBackForwardNavigationGestures(false);
    }
  }

  /// Creates a [YoutubePlayerController] and initializes the player with [videoId].
  factory YoutubePlayerController.fromVideoId({
    required String videoId,
    YoutubePlayerParams params = const YoutubePlayerParams(),
    bool autoPlay = false,
    double? startSeconds,
    double? endSeconds,
  }) {
    final YoutubePlayerController controller = YoutubePlayerController(params: params);

    if (autoPlay) {
      controller.loadVideoById(
        videoId: videoId,
        startSeconds: startSeconds,
        endSeconds: endSeconds,
      );
    } else {
      controller.cueVideoById(
        videoId: videoId,
        startSeconds: startSeconds,
        endSeconds: endSeconds,
      );
    }

    return controller;
  }

  final String _youtubeJSChannelName = "YoutubePlayer";

  /// Defines player parameters for the youtube player.
  final YoutubePlayerParams params;

  /// The [WebViewController] that drives the player
  @internal
  late final WebViewController webViewController;

  late final YoutubePlayerEventHandler _eventHandler;
  final Completer<void> _initCompleter = Completer();

  late bool _youtubeShorts = false;
  final StreamController<YoutubePlayerValue> _valueController =
      StreamController.broadcast();
  YoutubePlayerValue _value = YoutubePlayerValue();

  /// A Stream of [YoutubePlayerValue], which allows you to subscribe to changes
  /// in the controller value.
  Stream<YoutubePlayerValue> get stream => _valueController.stream;

  /// The [YoutubePlayerValue].
  YoutubePlayerValue get value => _value;

  bool get isYoutubeShorts => _youtubeShorts;

  @override
  Future<void> cuePlaylist({
    required List<String> list,
    ListType? listType,
    int? index,
    double? startSeconds,
  }) => _run(
      "cuePlaylist",
      data: <String, dynamic>{
        list.length == 1 ? "list" : "playlist": list,
        "listType": listType?.value,
        "index": index,
        "startSeconds": startSeconds,
      },
    );

  @override
  Future<void> cueVideoById({
    required String videoId,
    double? startSeconds,
    double? endSeconds,
  }) => _run(
      "cueVideoById",
      data: <String, dynamic>{
        "videoId": videoId,
        "startSeconds": startSeconds,
        "endSeconds": endSeconds,
      },
    );

  @override
  Future<void> cueVideoByUrl({
    required String mediaContentUrl,
    double? startSeconds,
    double? endSeconds,
  }) => _run(
      "cueVideoByUrl",
      data: <String, dynamic>{
        "mediaContentUrl": mediaContentUrl,
        "startSeconds": startSeconds,
        "endSeconds": endSeconds,
      },
    );

  @override
  Future<void> loadPlaylist({
    required List<String> list,
    ListType? listType,
    int? index,
    double? startSeconds,
  }) => _run(
      "loadPlaylist",
      data: <String, dynamic>{
        list.length == 1 ? "list" : "playlist": list,
        "listType": listType?.value,
        "index": index,
        "startSeconds": startSeconds,
      },
    );

  @override
  Future<void> loadVideoById({
    required String videoId,
    double? startSeconds,
    double? endSeconds,
  }) => _run(
      "loadVideoById",
      data: <String, dynamic>{
        "videoId": videoId,
        "startSeconds": startSeconds,
        "endSeconds": endSeconds,
      },
    );

  @override
  Future<void> loadVideoByUrl({
    required String mediaContentUrl,
    double? startSeconds,
    double? endSeconds,
  }) => _run(
      "loadVideoByUrl",
      data: <String,dynamic >{
        "mediaContentUrl": mediaContentUrl,
        "startSeconds": startSeconds,
        "endSeconds": endSeconds,
      },
    );

  /// Loads the video with the given [url].
  ///
  /// The [url] must be a valid youtube video watch url.
  /// i.e. https://www.youtube.com/watch?v=VIDEO_ID
  Future<void> loadVideo(String url) {
    _youtubeShorts = shortsRegExp.hasMatch(url);
    assert(
      regExp.hasMatch(url),
      "Only YouTube watch URLs are supported.",
    );

    final Map<String, String> params = Uri.parse(url).queryParameters;
    String videoId;
    if (_youtubeShorts) {
      videoId = convertUrlToId(url) ?? "";
    } else {
      videoId = params["v"]!;
    }
    assert(
      videoId.isNotEmpty,
      "Video ID is missing from the provided url.",
    );

    return loadVideoById(
      videoId: videoId,
      startSeconds: double.tryParse(params["t"] ?? "0"),
    );
  }

  /// Loads the player with default [params].
  @internal
  Future<void> init() async {
    await load(params: params, baseUrl: params.origin);

    if (!_initCompleter.isCompleted) {
      _initCompleter.complete();
    }
  }

  /// Loads the player with the given [params].
  ///
  /// [baseUrl] sets the origin for the iframe player.
  Future<void> load({
    required YoutubePlayerParams params,
    String? baseUrl,
  }) async {
    final String playerHtml = await rootBundle.loadString(
      "packages/youtube_player_iframe/assets/player.html",
    );

    final String platform = kIsWeb ? "web" : defaultTargetPlatform.name.toLowerCase();

    await webViewController.loadHtmlString(
      playerHtml
          .replaceFirst("<<pointerEvents>>", params.pointerEvents.name)
          .replaceFirst("<<playerVars>>", params.toJson())
          .replaceFirst("<<platform>>", platform)
          .replaceFirst("<<host>>", params.origin ?? "https://www.youtube.com"),
      baseUrl: baseUrl,
    );
  }

  Future<void> _run(
    String functionName, {
    Map<String, dynamic>? data,
  }) async {
    await _initCompleter.future;

    final String varArgs = await _prepareData(data);

    return webViewController.runJavaScript("player.$functionName($varArgs);");
  }

  Future<String> _runWithResult(
    String functionName, {
    Map<String, dynamic>? data,
  }) async {
    await _initCompleter.future;

    final String varArgs = await _prepareData(data);

    final Object result = await webViewController.runJavaScriptReturningResult(
      "player.$functionName($varArgs);",
    );
    return result.toString();
  }

  Future<void> _eval(String javascript) async {
    await _eventHandler.isReady;

    return webViewController.runJavaScript(javascript);
  }

  Future<String> _evalWithResult(String javascript) async {
    await _eventHandler.isReady;

    final Object result = await webViewController.runJavaScriptReturningResult(
      javascript,
    );

    return result.toString();
  }

  Future<String> _prepareData(Map<String, dynamic>? data) async {
    await _eventHandler.isReady;
    return data == null ? "" : jsonEncode(data);
  }

  /// MetaData for the currently loaded or cued video.
  YoutubeMetaData get metadata => _value.metaData;

  /// Creates new [YoutubePlayerValue] with assigned parameters and overrides
  /// the old one.
  void update({
    FullScreenOption? fullScreenOption,
    PlayerState? playerState,
    double? playbackRate,
    String? playbackQuality,
    YoutubeError? error,
    YoutubeMetaData? metaData,
  }) {
    final YoutubePlayerValue updatedValue = YoutubePlayerValue(
      fullScreenOption: fullScreenOption ?? value.fullScreenOption,
      playerState: playerState ?? value.playerState,
      playbackRate: playbackRate ?? value.playbackRate,
      playbackQuality: playbackQuality ?? value.playbackQuality,
      error: error ?? value.error,
      metaData: metaData ?? value.metaData,
    );

    _valueController.add(updatedValue);
  }

  /// Listen to updates in [YoutubePlayerController].
  StreamSubscription<YoutubePlayerValue> listen(
    void Function(YoutubePlayerValue event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => _valueController.stream.listen(
      (YoutubePlayerValue value) {
        _value = value;
        onData?.call(value);
      },
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );

  /// Converts fully qualified YouTube Url to video id.
  ///
  /// If videoId is passed as url then no conversion is done.
  static String? convertUrlToId(String url, {bool trimWhitespaces = true}) {
    if (!url.contains("http") && (url.length == 11)) {
      return url;
    }
    if (trimWhitespaces) {
      url = url.trim();
    }

    const String contentUrlPattern = r"^https:\/\/(?:www\.|m\.)?youtube\.com\/watch\?";
    const String embedUrlPattern =
        r"^https:\/\/(?:www\.|m\.)?youtube(?:-nocookie)?\.com\/embed\/";
    const String altUrlPattern = r"^https:\/\/youtu\.be\/";
    const String musicUrlPattern = r"^https:\/\/(?:music\.)?youtube\.com\/watch\?";
    const String idPattern = r"([_\-a-zA-Z0-9]{11}).*$";

    for (final String regex in <String>[
      "${contentUrlPattern}v=$idPattern",
      '$embedUrlPattern$idPattern',
      '$altUrlPattern$idPattern',
      '$shortsUrlPattern$idPattern',
      "$musicUrlPattern?v=$idPattern",
    ]) {
      final Match? match = RegExp(regex).firstMatch(url);
      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
    }

    return null;
  }

  /// Grabs YouTube video's thumbnail for provided video id.
  ///
  /// If [webp] is true, webp version of the thumbnail will be retrieved,
  /// Otherwise a JPG thumbnail.
  static String getThumbnail({
    required String videoId,
    String quality = ThumbnailQuality.standard,
    bool webp = true,
  }) => webp
        ? "https://i3.ytimg.com/vi_webp/$videoId/$quality.webp"
        : "https://i3.ytimg.com/vi/$videoId/$quality.jpg";

  @override
  Future<double> get duration async {
    final String duration = await _runWithResult("getDuration");
    return double.tryParse(duration) ?? 0;
  }

  @override
  Future<List<String>> get playlist async {
    final String playlist = await _evalWithResult("getPlaylist()");

    return List.from(jsonDecode(playlist));
  }

  @override
  Future<int> get playlistIndex async {
    final String index = await _runWithResult("getPlaylistIndex");

    return int.tryParse(index) ?? 0;
  }

  @override
  Future<VideoData> get videoData async {
    final String videoData = await _evalWithResult("getVideoData()");

    return VideoData.fromMap(jsonDecode(videoData));
  }

  @override
  Future<String> get videoEmbedCode => _runWithResult("getVideoEmbedCode");

  @override
  Future<String> get videoUrl async {
    final String videoUrl = await _runWithResult("getVideoUrl");

    if (videoUrl.startsWith('"')) {
      return videoUrl.substring(1, videoUrl.length - 1);
    }

    return videoUrl;
  }

  @override
  Future<List<double>> get availablePlaybackRates async {
    final String rates = await _evalWithResult("getAvailablePlaybackRates()");

    return List<num>.from(jsonDecode(rates))
        .map((num r) => r.toDouble())
        .toList(growable: false);
  }

  @override
  Future<double> get playbackRate async {
    final String rate = await _runWithResult("getPlaybackRate");

    return double.tryParse(rate) ?? 0;
  }

  @override
  Future<void> setLoop({required bool loopPlaylists}) => _eval("player.setLoop($loopPlaylists)");

  @override
  Future<void> setPlaybackRate(double suggestedRate) => _eval("player.setPlaybackRate($suggestedRate)");

  @override
  Future<void> setShuffle({required bool shufflePlaylists}) => _eval("player.setShuffle($shufflePlaylists)");

  @override
  Future<void> setSize(double width, double height) => _eval("player.setSize($width, $height)");

  @override
  Future<bool> get isMuted async {
    final String isMuted = await _runWithResult("isMuted");
    return isMuted == "1";
  }

  @override
  Future<void> mute() => _run("mute");

  @override
  Future<void> nextVideo() => _run("nextVideo");

  @override
  Future<void> pauseVideo() => _run("pauseVideo");

  @override
  Future<void> playVideo() => _run("playVideo");

  @override
  Future<void> playVideoAt(int index) => _eval("player.playVideoAt($index)");

  @override
  Future<void> previousVideo() => _run("previousVideo");

  @override
  Future<void> seekTo({required double seconds, bool allowSeekAhead = false}) => _eval("player.seekTo($seconds, $allowSeekAhead)");

  @override
  Future<void> setVolume(int volume) => _eval("player.setVolume($volume)");

  @override
  Future<void> stopVideo() => _run("stopVideo");

  @override
  Future<void> unMute() => _run("unMute");

  @override
  Future<int> get volume async {
    final String volume = await _runWithResult("getVolume");

    return int.tryParse(volume) ?? 0;
  }

  @override
  Future<double> get currentTime async {
    final String time = await _runWithResult("getCurrentTime");

    return double.tryParse(time) ?? 0;
  }

  @override
  Future<PlayerState> get playerState async {
    final String stateCode = await _runWithResult("getPlayerState");

    return PlayerState.values.firstWhere(
      (PlayerState state) => state.code.toString() == stateCode,
      orElse: () => PlayerState.unknown,
    );
  }

  @override
  Future<double> get videoLoadedFraction async {
    final String loadedFraction = await _runWithResult("getVideoLoadedFraction");

    return double.tryParse(loadedFraction) ?? 0;
  }

  /// Enters fullscreen mode.
  ///
  /// If [lock] is true, auto rotate will be disabled.
  void enterFullScreen({bool lock = true}) {
    update(fullScreenOption: FullScreenOption(enabled: true, locked: lock));
    _onFullscreenChanged?.call(true);
  }

  /// Exits fullscreen mode.
  ///
  /// If [lock] is true, auto rotate will be disabled.
  void exitFullScreen({bool lock = true}) {
    update(fullScreenOption: FullScreenOption(enabled: false, locked: lock));
    _onFullscreenChanged?.call(false);
  }

  ValueChanged<bool>? _onFullscreenChanged;

  /// Sets the full screen listener.
  // ignore: use_setters_to_change_properties
  void setFullScreenListener(ValueChanged<bool> callback) {
    _onFullscreenChanged = callback;
  }

  /// Toggles fullscreen mode.
  ///
  /// If [lock] is true, auto rotate will be disabled.
  void toggleFullScreen({bool lock = true}) {
    if (value.fullScreenOption.enabled) {
      exitFullScreen(lock: lock);
    } else {
      enterFullScreen(lock: lock);
    }
  }

  /// The stream for [YoutubeVideoState] changes.
  Stream<YoutubeVideoState> get videoStateStream => _eventHandler.videoStateController.stream;

  /// Creates a stream that repeatedly emits current time at [period] intervals.
  @Deprecated("Use videoStateStream instead")
  Stream<Duration> getCurrentPositionStream({
    // Unused
    Duration period = const Duration(seconds: 1),
  }) => videoStateStream.map((YoutubeVideoState state) => state.position);

  NavigationDecision _decideNavigation(Uri? uri) {
    if (uri == null) {
      return NavigationDecision.prevent;
    }

    final Map<String, String> params = uri.queryParameters;
    final String host = uri.host;
    final String path = uri.path;

    String? featureName;
    if (host.contains("facebook") ||
        host.contains("twitter") ||
        host == "youtu") {
      featureName = "social";
    } else if (params.containsKey("feature")) {
      featureName = params["feature"];
    } else if (path == "/watch") {
      featureName = "emb_info";
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return NavigationDecision.navigate;
    }

    switch (featureName) {
      case "emb_rel_pause":
      case "emb_rel_end":
      case "emb_info":
        final String? videoId = params["v"];
        if (videoId != null) {
          loadVideoById(videoId: videoId);
        }
      case "emb_title":
      case "emb_logo":
      case "social":
      case "wl_button":
        uri_launcher.launchUrl(uri);
    }

    return NavigationDecision.prevent;
  }

  /// Disposes the resources created by [YoutubePlayerController].
  Future<void> close() async {
    await stopVideo();
    await webViewController.removeJavaScriptChannel(_youtubeJSChannelName);
    await _eventHandler.videoStateController.close();
    await _valueController.close();
  }
}

/// The current state of the Youtube video.
class YoutubeVideoState {
  /// Creates a new instance of [YoutubeVideoState].
  const YoutubeVideoState({
    this.position = Duration.zero,
    this.loadedFraction = 0,
  });

  /// Creates a new instance of [YoutubeVideoState] from the given [json].
  factory YoutubeVideoState.fromJson(String json) {
    final Map state = jsonDecode(json);
    final num currentTime = state["currentTime"] as num? ?? 0;
    final num loadedFraction = state["loadedFraction"] as num? ?? 0;
    final int positionInMs = (currentTime * 1000).truncate();

    return YoutubeVideoState(
      position: Duration(milliseconds: positionInMs),
      loadedFraction: loadedFraction.toDouble(),
    );
  }

  /// The current position of the video.
  final Duration position;

  /// The fraction of the video that has been buffered.
  final double loadedFraction;
}
