import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Video player widget displayed inside the promotional banner on the Home page.
/// - Rectangular widescreen format (16:10 aspect ratio).
/// - Plays single or multiple videos sequentially (playlist).
/// - Supports both web links (URLs) and local assets.
/// - Autoplays muted by default with an audio toggle.
/// - Interactive Play and Pause button.
/// - Previous / Next video navigation for playlists.
/// - Maximize / Minimize fullscreen view for large screen playback.
/// - Keeps alive across PageView swipes to prevent disposal glitches.
/// - Notifies [onVideoCompleted] when all videos in the playlist finish playing.
class BannerVideoPlayer extends StatefulWidget {
  final bool isActive;
  final VoidCallback? onVideoCompleted;
  final String? videoAsset;
  final String? videoUrl;
  final List<String>? videoSources;
  final double aspectRatio;
  final Duration postVideoDelay;
  final bool autoReplay;
  final Duration replayDelay;

  const BannerVideoPlayer({
    super.key,
    required this.isActive,
    this.onVideoCompleted,
    this.videoAsset = defaultVideoAsset,
    this.videoUrl,
    this.videoSources,
    this.aspectRatio = 16 / 10,
    this.postVideoDelay = const Duration(seconds: 3),
    this.autoReplay = false,
    this.replayDelay = const Duration(seconds: 3),
  });

  /// Default bundled high-definition phone promo video asset
  static const String defaultVideoAsset = 'assets/videos/phone_promo.mp4';

  @override
  State<BannerVideoPlayer> createState() => _BannerVideoPlayerState();
}

class _BannerVideoPlayerState extends State<BannerVideoPlayer>
    with AutomaticKeepAliveClientMixin {
  VideoPlayerController? _controller;
  int _currentSourceIndex = 0;
  bool _isInitialized = false;
  bool _isError = false;
  bool _isMuted = true;
  bool _isPlaying = false;
  bool _hasEnded = false;
  bool _isFullscreen = false;
  bool _isDisposed = false;
  Timer? _fallbackTimer;
  Timer? _endDelayTimer;
  int _lastRenderedSecond = -1;

  @override
  bool get wantKeepAlive => true;

  List<String> get _playlist {
    if (widget.videoSources != null && widget.videoSources!.isNotEmpty) {
      return widget.videoSources!;
    }
    if (widget.videoUrl != null) {
      return [widget.videoUrl!];
    }
    return [widget.videoAsset ?? BannerVideoPlayer.defaultVideoAsset];
  }

  @override
  void initState() {
    super.initState();
    _currentSourceIndex = 0;
    _initializeCurrentVideo();
  }

  Future<void> _initializeCurrentVideo() async {
    final playlist = _playlist;
    if (playlist.isEmpty) return;

    if (_currentSourceIndex >= playlist.length) {
      _currentSourceIndex = 0;
    }

    final currentSource = playlist[_currentSourceIndex];

    // Safely dispose prior controller before loading next video
    final oldController = _controller;
    _controller = null;
    if (oldController != null) {
      try {
        oldController.removeListener(_videoListener);
        await oldController.dispose();
      } catch (_) {}
    }

    if (!mounted || _isDisposed) return;

    setState(() {
      _isInitialized = false;
      _isError = false;
    });

    try {
      final VideoPlayerController controller;
      if (currentSource.startsWith('http://') ||
          currentSource.startsWith('https://')) {
        controller = VideoPlayerController.networkUrl(
          Uri.parse(currentSource),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
      } else {
        controller = VideoPlayerController.asset(
          currentSource,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
      }

      _controller = controller;
      await controller.initialize();

      if (!mounted || _isDisposed) {
        await controller.dispose();
        return;
      }

      await controller.setLooping(false);
      await controller.setVolume(_isMuted ? 0.0 : 1.0);

      controller.addListener(_videoListener);

      setState(() {
        _isInitialized = true;
      });

      if (widget.isActive && !_isDisposed) {
        controller.play();
        setState(() {
          _isPlaying = true;
        });
      }
    } catch (e) {
      if (!mounted || _isDisposed) return;
      setState(() {
        _isError = true;
      });

      // If a video link fails, attempt to advance to the next video or fallback
      _scheduleFallbackTimer();
    }
  }

  void _scheduleFallbackTimer() {
    _fallbackTimer?.cancel();
    if (widget.isActive && !_isDisposed) {
      _fallbackTimer = Timer(const Duration(seconds: 4), () {
        if (!mounted || _isDisposed || !widget.isActive) return;

        // Try next video in playlist if available
        final playlist = _playlist;
        if (_currentSourceIndex + 1 < playlist.length) {
          setState(() {
            _currentSourceIndex++;
          });
          _initializeCurrentVideo();
        } else {
          // Pause/wait for a few seconds before moving to next banner or replaying
          _endDelayTimer?.cancel();
          final delay = widget.autoReplay ? widget.replayDelay : widget.postVideoDelay;
          _endDelayTimer = Timer(delay, () {
            if (mounted && !_isDisposed && widget.isActive) {
              if (widget.autoReplay) {
                _restartPlaylist();
              } else {
                widget.onVideoCompleted?.call();
              }
            }
          });
        }
      });
    }
  }

  void _restartPlaylist() {
    if (!mounted || _isDisposed || !widget.isActive) return;
    final playlist = _playlist;
    if (playlist.length > 1) {
      setState(() {
        _hasEnded = false;
        _currentSourceIndex = 0;
      });
      _initializeCurrentVideo();
    } else {
      final controller = _controller;
      if (controller != null && _isInitialized && !_isDisposed) {
        _lastRenderedSecond = -1;
        setState(() {
          _hasEnded = false;
          _isPlaying = true;
        });
        controller.seekTo(Duration.zero).then((_) {
          if (mounted && !_isDisposed && widget.isActive) {
            controller.play();
          }
        });
      }
    }
  }

  void _videoListener() {
    final controller = _controller;
    if (controller == null || !mounted || _isDisposed || !_isInitialized) return;

    final value = controller.value;
    final isPlaying = value.isPlaying;
    final position = value.position;
    final duration = value.duration;

    // Check if video reached the end (with 150ms buffer to prevent EOS jitter/oscillation)
    if (duration > Duration.zero &&
        position >= (duration - const Duration(milliseconds: 150))) {
      if (!_hasEnded) {
        _hasEnded = true;
        _isPlaying = false;
        // Pause controller to prevent continuous EOS buffer looping
        controller.pause();

        final playlist = _playlist;
        if (_currentSourceIndex + 1 < playlist.length) {
          // Play next video in the playlist
          setState(() {
            _currentSourceIndex++;
          });
          _initializeCurrentVideo();
        } else {
          // All videos in playlist finished!
          _endDelayTimer?.cancel();
          final delay =
              widget.autoReplay ? widget.replayDelay : widget.postVideoDelay;
          _endDelayTimer = Timer(delay, () {
            if (mounted && !_isDisposed && widget.isActive && _hasEnded) {
              if (widget.autoReplay) {
                _restartPlaylist();
              } else {
                widget.onVideoCompleted?.call();
              }
            }
          });
        }
        if (mounted && !_isDisposed) {
          setState(() {});
        }
      }
      return;
    }

    // Video is in progress: throttle rebuilds so the Flutter UI thread stays silky smooth
    bool needsUpdate = false;
    if (isPlaying != _isPlaying) {
      _isPlaying = isPlaying;
      needsUpdate = true;
    }

    final currentSec = position.inSeconds;
    if (currentSec != _lastRenderedSecond) {
      _lastRenderedSecond = currentSec;
      needsUpdate = true;
    }

    if (needsUpdate && mounted && !_isDisposed) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant BannerVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive != oldWidget.isActive) {
      final controller = _controller;
      if (controller != null && _isInitialized && !_isDisposed) {
        if (widget.isActive) {
          _endDelayTimer?.cancel();
          if (_hasEnded ||
              (controller.value.duration > Duration.zero &&
                  controller.value.position >=
                      (controller.value.duration -
                          const Duration(milliseconds: 150)))) {
            _hasEnded = false;
            final playlist = _playlist;
            if (playlist.length > 1) {
              _currentSourceIndex = 0;
              _initializeCurrentVideo();
            } else {
              _lastRenderedSecond = -1;
              controller.seekTo(Duration.zero).then((_) {
                if (mounted && !_isDisposed && widget.isActive) {
                  controller.play();
                  setState(() => _isPlaying = true);
                }
              });
            }
          } else {
            controller.play();
            setState(() => _isPlaying = true);
          }
        } else {
          _endDelayTimer?.cancel();
          controller.pause();
          setState(() => _isPlaying = false);
        }
      } else if (_isError) {
        if (widget.isActive) {
          _scheduleFallbackTimer();
        } else {
          _fallbackTimer?.cancel();
          _endDelayTimer?.cancel();
        }
      }
    }
  }

  void _togglePlayPause() {
    final controller = _controller;
    if (controller == null || !_isInitialized || _isDisposed) return;

    if (controller.value.isPlaying) {
      _endDelayTimer?.cancel();
      controller.pause();
      setState(() => _isPlaying = false);
    } else {
      _endDelayTimer?.cancel();
      if (_hasEnded ||
          (controller.value.duration > Duration.zero &&
              controller.value.position >=
                  (controller.value.duration -
                      const Duration(milliseconds: 150)))) {
        _hasEnded = false;
        _lastRenderedSecond = -1;
        controller.seekTo(Duration.zero).then((_) {
          if (mounted && !_isDisposed) {
            controller.play();
            setState(() => _isPlaying = true);
          }
        });
      } else {
        controller.play();
        setState(() => _isPlaying = true);
      }
    }
  }

  void _toggleSound() {
    final controller = _controller;
    if (controller == null || !_isInitialized || _isDisposed) return;

    final nextMuted = !_isMuted;
    controller.setVolume(nextMuted ? 0.0 : 1.0);
    setState(() {
      _isMuted = nextMuted;
    });
  }

  void _playNextVideo() {
    final playlist = _playlist;
    if (playlist.length > 1) {
      _endDelayTimer?.cancel();
      setState(() {
        _currentSourceIndex = (_currentSourceIndex + 1) % playlist.length;
      });
      _initializeCurrentVideo();
    }
  }

  void _playPreviousVideo() {
    final playlist = _playlist;
    if (playlist.length > 1) {
      _endDelayTimer?.cancel();
      setState(() {
        _currentSourceIndex = (_currentSourceIndex - 1 + playlist.length) % playlist.length;
      });
      _initializeCurrentVideo();
    }
  }

  Future<void> _openFullscreen() async {
    final controller = _controller;
    if (controller == null || !_isInitialized || _isDisposed) return;

    setState(() {
      _isFullscreen = true;
    });

    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.9),
        barrierDismissible: true,
        pageBuilder: (context, _, __) {
          return BannerVideoFullscreenModal(
            controller: controller,
            initialMuted: _isMuted,
            playlistTotal: _playlist.length,
            currentPlaylistIndex: _currentSourceIndex,
            onNextVideo: _playlist.length > 1 ? _playNextVideo : null,
            onPrevVideo: _playlist.length > 1 ? _playPreviousVideo : null,
            onVideoCompleted: widget.onVideoCompleted,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );

    if (mounted && !_isDisposed) {
      setState(() {
        _isFullscreen = false;
        _isMuted = controller.value.volume <= 0.0;
        _isPlaying = controller.value.isPlaying;
      });
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString();
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _isDisposed = true;
    _fallbackTimer?.cancel();
    _endDelayTimer?.cancel();
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      try {
        controller.removeListener(_videoListener);
        controller.dispose();
      } catch (_) {}
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final totalInPlaylist = _playlist.length;
    final promoLabel = totalInPlaylist > 1
        ? 'PROMO ${_currentSourceIndex + 1}/$totalInPlaylist'
        : 'PROMO';

    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.45),
            width: 1.2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video surface or placeholder
              if (_isInitialized && _controller != null && !_isFullscreen)
                GestureDetector(
                  onTap: _togglePlayPause,
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller!.value.size.width > 0
                            ? _controller!.value.size.width
                            : 16,
                        height: _controller!.value.size.height > 0
                            ? _controller!.value.size.height
                            : 9,
                        child: VideoPlayer(_controller!),
                      ),
                    ),
                  ),
                )
              else
                _buildPlaceholder(),

              // Top dark gradient overlay for top controls
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 38,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom dark gradient overlay for bottom controls
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 36,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.75),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Top-left "PROMO" live badge (with playlist index if multiple videos)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 4.5,
                        height: 4.5,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 3.5),
                      Text(
                        promoLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Top-right action buttons: Sound toggle + Maximize
              Positioned(
                top: 4,
                right: 4,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Previous video (if playlist > 1)
                    if (totalInPlaylist > 1)
                      _buildMiniIconButton(
                        icon: Icons.skip_previous_rounded,
                        tooltip: 'Previous Video',
                        onTap: _playPreviousVideo,
                      ),
                    if (totalInPlaylist > 1)
                      const SizedBox(width: 3),
                    // Next video (if playlist > 1)
                    if (totalInPlaylist > 1)
                      _buildMiniIconButton(
                        icon: Icons.skip_next_rounded,
                        tooltip: 'Next Video',
                        onTap: _playNextVideo,
                      ),
                    if (totalInPlaylist > 1)
                      const SizedBox(width: 3),
                    // Sound toggle button
                    if (_isInitialized && _controller != null)
                      _buildMiniIconButton(
                        icon: _isMuted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        tooltip: _isMuted ? 'Unmute' : 'Mute',
                        onTap: _toggleSound,
                      ),
                    const SizedBox(width: 4),
                    // Maximize / Fullscreen button
                    if (_isInitialized && _controller != null)
                      _buildMiniIconButton(
                        icon: Icons.fullscreen_rounded,
                        tooltip: 'Maximize',
                        onTap: _openFullscreen,
                      ),
                  ],
                ),
              ),

              // Center Play button overlay when paused
              if (_isInitialized && _controller != null && !_isPlaying)
                Center(
                  child: GestureDetector(
                    onTap: _togglePlayPause,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.7),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),

              // Bottom Control Bar (Play/Pause mini button, time counter, progress bar)
              if (_isInitialized && _controller != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Row(
                          children: [
                            // Mini Play/Pause button
                            GestureDetector(
                              onTap: _togglePlayPause,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  _isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            // Current time / duration
                            Text(
                              '${_formatDuration(_controller!.value.position)} / ${_formatDuration(_controller!.value.duration)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            // Maximize quick icon on bottom right
                            GestureDetector(
                              onTap: _openFullscreen,
                              child: const Icon(
                                Icons.open_in_full_rounded,
                                color: Colors.white,
                                size: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildProgressBar(),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 0.7,
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final controller = _controller;
    if (controller == null) return const SizedBox.shrink();

    final duration = controller.value.duration.inMilliseconds;
    final position = controller.value.position.inMilliseconds;
    final progress = (duration > 0)
        ? (position / duration).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: double.infinity,
      height: 3.0,
      alignment: Alignment.centerLeft,
      color: Colors.black.withValues(alpha: 0.45),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        heightFactor: 1.0,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF3B82F6), Color(0xFF1C7BFF)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF1C7BFF).withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF1C7BFF).withValues(alpha: 0.4),
                  width: 1.2,
                ),
              ),
              child: const Icon(
                Icons.play_circle_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Featured Promotion',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fullscreen modal overlay displaying the promo video in widescreen/large format.
/// Supports play/pause, seek scrubber slider, audio toggle, and minimize.
class BannerVideoFullscreenModal extends StatefulWidget {
  final VideoPlayerController controller;
  final bool initialMuted;
  final int playlistTotal;
  final int currentPlaylistIndex;
  final VoidCallback? onNextVideo;
  final VoidCallback? onPrevVideo;
  final VoidCallback? onVideoCompleted;

  const BannerVideoFullscreenModal({
    super.key,
    required this.controller,
    required this.initialMuted,
    this.playlistTotal = 1,
    this.currentPlaylistIndex = 0,
    this.onNextVideo,
    this.onPrevVideo,
    this.onVideoCompleted,
  });

  @override
  State<BannerVideoFullscreenModal> createState() =>
      _BannerVideoFullscreenModalState();
}

class _BannerVideoFullscreenModalState
    extends State<BannerVideoFullscreenModal> {
  late bool _isMuted;
  bool _showControls = true;
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
    _isMuted = widget.initialMuted;
    widget.controller.addListener(_onControllerTick);
    _startControlsTimer();
  }

  void _onControllerTick() {
    if (mounted) {
      setState(() {});
    }
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    if (widget.controller.value.isPlaying) {
      _controlsTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startControlsTimer();
    }
  }

  void _togglePlayPause() {
    final controller = widget.controller;
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      if (controller.value.duration > Duration.zero &&
          controller.value.position >= controller.value.duration) {
        controller.seekTo(Duration.zero).then((_) {
          if (mounted) controller.play();
        });
      } else {
        controller.play();
      }
    }
    _startControlsTimer();
    setState(() {});
  }

  void _toggleSound() {
    final nextMuted = !_isMuted;
    widget.controller.setVolume(nextMuted ? 0.0 : 1.0);
    setState(() {
      _isMuted = nextMuted;
    });
    _startControlsTimer();
  }

  void _seekRelative(int seconds) {
    final current = widget.controller.value.position;
    final total = widget.controller.value.duration;
    final target = current + Duration(seconds: seconds);
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > total ? total : target);
    widget.controller.seekTo(clamped);
    _startControlsTimer();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    try {
      widget.controller.removeListener(_onControllerTick);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final value = controller.value;
    final isPlaying = value.isPlaying;
    final duration = value.duration;
    final position = value.position;

    final promoBadgeText = widget.playlistTotal > 1
        ? 'PROMO ${widget.currentPlaylistIndex + 1}/${widget.playlistTotal}'
        : 'PROMO';

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: SafeArea(
        child: GestureDetector(
          onTap: _toggleControls,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Full widescreen video player in center
              Center(
                child: AspectRatio(
                  aspectRatio: value.aspectRatio > 0 ? value.aspectRatio : 16 / 9,
                  child: VideoPlayer(controller),
                ),
              ),

              // Center large Play/Pause icon button
              if (_showControls || !isPlaying)
                Center(
                  child: GestureDetector(
                    onTap: _togglePlayPause,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1C7BFF).withValues(alpha: 0.4),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ),

              // Top Bar: Title, Promo badge, Minimize / Close button
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                top: _showControls ? 0 : -80,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.85),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      // Minimize / Back button
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.fullscreen_exit_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                        tooltip: 'Minimize',
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Siaka Phones Promotion',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          promoBadgeText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Close button
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Bar: Controls, Scrubber Slider, Time, Audio Toggle, Minimize
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                bottom: _showControls ? 0 : -100,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.9),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Interactive Seek Scrubber Slider
                      Slider(
                        value: (duration.inMilliseconds > 0)
                            ? (position.inMilliseconds /
                                    duration.inMilliseconds)
                                .clamp(0.0, 1.0)
                            : 0.0,
                        activeColor: const Color(0xFF1C7BFF),
                        inactiveColor: Colors.white.withValues(alpha: 0.25),
                        thumbColor: const Color(0xFF1C7BFF),
                        onChanged: (val) {
                          final targetMs = (val * duration.inMilliseconds).toInt();
                          controller.seekTo(Duration(milliseconds: targetMs));
                          _startControlsTimer();
                        },
                      ),

                      // Control buttons row
                      Row(
                        children: [
                          // Previous video button (if playlist > 1)
                          if (widget.onPrevVideo != null)
                            IconButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                widget.onPrevVideo?.call();
                              },
                              icon: const Icon(
                                Icons.skip_previous_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                              tooltip: 'Previous Video',
                            ),
                          // Play / Pause button
                          IconButton(
                            onPressed: _togglePlayPause,
                            icon: Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          // Next video button (if playlist > 1)
                          if (widget.onNextVideo != null)
                            IconButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                widget.onNextVideo?.call();
                              },
                              icon: const Icon(
                                Icons.skip_next_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                              tooltip: 'Next Video',
                            ),
                          // Replay / Rewind 5s
                          IconButton(
                            onPressed: () => _seekRelative(-5),
                            icon: const Icon(
                              Icons.replay_5_rounded,
                              color: Colors.white70,
                              size: 22,
                            ),
                            tooltip: 'Rewind 5s',
                          ),
                          // Forward 5s
                          IconButton(
                            onPressed: () => _seekRelative(5),
                            icon: const Icon(
                              Icons.forward_5_rounded,
                              color: Colors.white70,
                              size: 22,
                            ),
                            tooltip: 'Forward 5s',
                          ),
                          const SizedBox(width: 8),
                          // Time display
                          Text(
                            '${_formatDuration(position)} / ${_formatDuration(duration)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          // Mute/Unmute sound
                          IconButton(
                            onPressed: _toggleSound,
                            icon: Icon(
                              _isMuted
                                  ? Icons.volume_off_rounded
                                  : Icons.volume_up_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            tooltip: _isMuted ? 'Unmute' : 'Mute',
                          ),
                          // Minimize button
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.fullscreen_exit_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                            tooltip: 'Minimize',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
