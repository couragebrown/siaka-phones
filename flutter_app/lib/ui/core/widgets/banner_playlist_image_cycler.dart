import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../domain/models/banner_playlist.dart';

class BannerPlaylistImageCycler extends StatefulWidget {
  final List<BannerImageItem> images;
  final double? width;
  final double? height;
  final double? aspectRatio;
  final BoxFit fit;

  const BannerPlaylistImageCycler({
    super.key,
    required this.images,
    this.width,
    this.height,
    this.aspectRatio,
    this.fit = BoxFit.cover,
  });

  @override
  State<BannerPlaylistImageCycler> createState() =>
      _BannerPlaylistImageCyclerState();
}

class _BannerPlaylistImageCyclerState extends State<BannerPlaylistImageCycler> {
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(BannerPlaylistImageCycler oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.images.length != oldWidget.images.length) {
      if (_currentIndex >= widget.images.length) {
        _currentIndex = 0;
      }
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.images.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.images.length;
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildSmartImage(String url, Key key) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return Container(
        key: key,
        width: widget.width,
        height: widget.height,
        color: const Color(0xFF1E222A),
        child: const Center(
          child: Icon(Icons.broken_image_rounded, color: Colors.white24, size: 24),
        ),
      );
    }

    if (trimmed.startsWith('data:image')) {
      try {
        final commaIdx = trimmed.indexOf(',');
        final base64Str = commaIdx != -1 ? trimmed.substring(commaIdx + 1) : trimmed;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          key: key,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          errorBuilder: (_, __, ___) => _errorWidget(key),
        );
      } catch (_) {}
    }

    if (trimmed.startsWith('file://')) {
      try {
        final file = File(Uri.parse(trimmed).toFilePath());
        if (file.existsSync()) {
          return Image.file(
            file,
            key: key,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            errorBuilder: (_, __, ___) => _errorWidget(key),
          );
        }
      } catch (_) {}
    }

    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      try {
        final file = File(trimmed);
        if (file.existsSync()) {
          return Image.file(
            file,
            key: key,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            errorBuilder: (_, __, ___) => _errorWidget(key),
          );
        }
      } catch (_) {}
    }

    return Image.network(
      trimmed,
      key: key,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (_, __, ___) => _errorWidget(key),
    );
  }

  Widget _errorWidget(Key key) {
    return Container(
      key: key,
      width: widget.width,
      height: widget.height,
      color: const Color(0xFF1E222A),
      child: const Center(
        child: Icon(Icons.broken_image_rounded, color: Colors.white24, size: 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return const SizedBox.shrink();
    }
    final imageItem = widget.images[_currentIndex % widget.images.length];
    Widget imageWidget = AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: _buildSmartImage(imageItem.imageUrl, ValueKey(imageItem.id)),
    );

    if (widget.aspectRatio != null) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio!,
        child: imageWidget,
      );
    }
    return imageWidget;
  }
}
