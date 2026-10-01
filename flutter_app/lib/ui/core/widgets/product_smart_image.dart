import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

/// A robust product image renderer that completely eliminates all flickering, ghosting, and blinking:
/// 1. Uses a static cache of [ImageProvider] instances so images are never re-decoded or re-fetched across rebuilds.
/// 2. Relies on Flutter's native [gaplessPlayback: true] so the existing image is never blanked out.
/// 3. Does NOT paint fallback mockups behind transparent images to avoid ghosting/visual thrashing.
class ProductSmartImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final Widget? fallback;
  final double? width;
  final double? height;

  const ProductSmartImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.contain,
    this.fallback,
    this.width,
    this.height,
  });

  @override
  State<ProductSmartImage> createState() => _ProductSmartImageState();
}

class _ProductSmartImageState extends State<ProductSmartImage> {
  static final Map<String, ImageProvider> _providerCache = {};
  static final Set<String> _failedUrls = {};
  static bool _imageCacheConfigured = false;
  ImageProvider? _provider;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (!_imageCacheConfigured) {
      _imageCacheConfigured = true;
      PaintingBinding.instance.imageCache.maximumSize = 2000;
      PaintingBinding.instance.imageCache.maximumSizeBytes = 150 * 1024 * 1024;
    }
    _initProvider();
  }

  @override
  void didUpdateWidget(ProductSmartImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl.trim() != widget.imageUrl.trim()) {
      _hasError = false;
      _initProvider();
    }
  }

  void _initProvider() {
    final trimmed = widget.imageUrl.trim();
    if (trimmed.isEmpty || _failedUrls.contains(trimmed)) {
      _hasError = _failedUrls.contains(trimmed);
      _provider = null;
      return;
    }

    if (_providerCache.containsKey(trimmed)) {
      _provider = _providerCache[trimmed];
      return;
    }

    try {
      if (trimmed.startsWith('data:image') ||
          (trimmed.length > 100 &&
              !trimmed.startsWith('http') &&
              !trimmed.contains('/') &&
              !trimmed.contains('\\'))) {
        final commaIdx = trimmed.indexOf(',');
        final base64Str = commaIdx != -1 ? trimmed.substring(commaIdx + 1) : trimmed;
        final bytes = base64Decode(base64Str);
        _provider = MemoryImage(bytes);
      } else if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        _provider = NetworkImage(trimmed);
      } else if (trimmed.startsWith('assets/')) {
        _provider = AssetImage(trimmed);
      } else {
        final file = File(trimmed);
        if (file.existsSync()) {
          _provider = FileImage(file);
        } else {
          _provider = null;
        }
      }

      if (_provider != null) {
        if (_providerCache.length > 200) {
          _providerCache.clear();
        }
        _providerCache[trimmed] = _provider!;
      }
    } catch (_) {
      _provider = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultFallback = widget.fallback ??
        Container(
          width: widget.width,
          height: widget.height,
          color: const Color(0xFFF1F5F9),
          child: const Center(
            child: Icon(Icons.phone_android_rounded, size: 28, color: Color(0xFF94A3B8)),
          ),
        );

    if (_provider == null || _hasError) {
      return defaultFallback;
    }

    return Image(
      image: _provider!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) {
        final trimmed = widget.imageUrl.trim();
        if (trimmed.isNotEmpty) {
          _failedUrls.add(trimmed);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_hasError) {
            setState(() => _hasError = true);
          }
        });
        return defaultFallback;
      },
    );
  }
}
