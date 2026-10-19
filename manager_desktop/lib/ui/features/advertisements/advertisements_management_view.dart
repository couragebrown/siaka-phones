import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/repositories/manager_repository.dart';
import '../../../domain/models/advertisement_banner.dart';
import '../../../domain/models/banner_playlist.dart';

class AdvertisementsManagementView extends StatefulWidget {
  final ManagerRepository repository;

  const AdvertisementsManagementView({
    super.key,
    required this.repository,
  });

  @override
  State<AdvertisementsManagementView> createState() =>
      _AdvertisementsManagementViewState();
}

class _AdvertisementsManagementViewState
    extends State<AdvertisementsManagementView> {
  final ScrollController _scrollController = ScrollController();

  // 5 Banner Playlists State
  String _selectedPlaylistId = 'banner_home_1';

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Backwards-compatible router for New Video Advertisement dialog
  void _showAddEditAdDialog(BuildContext context, [AdvertisementBanner? existingAd]) {
    _showAddEditVideoDialog(
      context,
      initialPlaylistId: _selectedPlaylistId == 'banner_search_1' ? 'banner_search_1' : 'banner_home_1',
      existingAd: existingAd,
    );
  }

  void _showAddEditVideoDialog(
    BuildContext context, {
    String? initialPlaylistId,
    BannerVideoItem? existingVideo,
    AdvertisementBanner? existingAd,
  }) {
    final isEditing = existingVideo != null || existingAd != null;
    final initialId = (initialPlaylistId == 'banner_search_1')
        ? 'banner_search_1'
        : 'banner_home_1';
    String targetBanner = initialId;

    final titleController = TextEditingController(
      text: existingVideo?.title ?? existingAd?.title ?? '',
    );
    final descController = TextEditingController(
      text: existingVideo?.description ?? existingAd?.description ?? '',
    );
    final videoUrlController = TextEditingController(
      text: existingVideo?.videoUrl ??
          existingAd?.videoUrl ??
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    );
    final badgeController = TextEditingController(
      text: existingVideo?.badgeText ?? existingAd?.badgeText ?? 'PROMO',
    );
    final ctaController = TextEditingController(
      text: existingVideo?.callToActionText ?? existingAd?.callToActionText ?? 'Shop Now',
    );
    String target = existingVideo?.targetCategoryOrProduct ??
        existingAd?.targetCategoryOrProduct ??
        'Smartphones';
    bool isActive = existingVideo?.isActive ?? existingAd?.isActive ?? true;

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isEditing ? Icons.edit_note_rounded : Icons.videocam_rounded,
                      color: const Color(0xFF1C7BFF),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Edit Video Advertisement' : 'Create Video Advertisement',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Configure banner video link, headline, badge, and call to action',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 580,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // Target Video Banner Selection (Only banner_home_1 and banner_search_1)
                        const Text(
                          'Target Video Banner Slot *',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: targetBanner,
                              isExpanded: true,
                              style: const TextStyle(
                                color: Color(0xFF1E293B),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'banner_home_1',
                                  child: Text('Homepage Banner 1 (Discover Smartphones - Video Slide 1)'),
                                ),
                                DropdownMenuItem(
                                  value: 'banner_search_1',
                                  child: Text('Search Page Banner (Catalog Search - Video Banner)'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => targetBanner = val);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Note: Only Homepage Slide 1 and the Search Page Banner support video ads.',
                          style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 16),

                        // Title
                        const Text(
                          'Campaign Headline *',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: titleController,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Headline is required' : null,
                          decoration: InputDecoration(
                            hintText: 'e.g. Flagship Smartphone Arrivals',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Description
                        const Text(
                          'Description / Subtitle *',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: descController,
                          maxLines: 2,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Description is required' : null,
                          decoration: InputDecoration(
                            hintText: 'e.g. iPhone 16 Pro Max & Galaxy S24 Ultra with 1-year store warranty',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Video Link
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            const Text(
                              'Video Link / Network Stream URL *',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            Text(
                              'Supports https:// or asset path',
                              style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: videoUrlController,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Video link is required' : null,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.link_rounded, size: 18, color: Color(0xFF64748B)),
                            hintText: 'https://example.com/promo.mp4 or assets/videos/promo.mp4',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Sample Links Quick Buttons
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            const Text(
                              'Quick links:',
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                            ),
                            InkWell(
                              onTap: () {
                                setDialogState(() {
                                  videoUrlController.text = 'assets/videos/phone_promo.mp4';
                                });
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Local Asset Video',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setDialogState(() {
                                  videoUrlController.text =
                                      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4';
                                });
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Google CDN Sample 1',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setDialogState(() {
                                  videoUrlController.text =
                                      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4';
                                });
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Google CDN Sample 2',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Badge & CTA
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Promo Badge Tag',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: badgeController,
                                    decoration: InputDecoration(
                                      hintText: 'e.g. PROMO, HOT DEAL',
                                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Call to Action (CTA)',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: ctaController,
                                    decoration: InputDecoration(
                                      hintText: 'e.g. Shop Now, Apply',
                                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Destination & Active Switch
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Destination Page / Action',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: target,
                                        isExpanded: true,
                                        style: const TextStyle(
                                          color: Color(0xFF1E293B),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        items: const [
                                          DropdownMenuItem(value: 'Smartphones', child: Text('Smartphones Catalog')),
                                          DropdownMenuItem(value: 'Phones', child: Text('Keypad Phones')),
                                          DropdownMenuItem(value: 'Laptops', child: Text('Laptops Catalog')),
                                          DropdownMenuItem(value: 'Accessories', child: Text('Accessories Catalog')),
                                          DropdownMenuItem(value: 'BNPL', child: Text('Buy Now Pay Later')),
                                          DropdownMenuItem(value: 'TradeIn', child: Text('Device Trade-In / Swap')),
                                          DropdownMenuItem(value: 'Repairs', child: Text('Repairs Desk')),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) {
                                            setDialogState(() => target = val);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Active in Video Banner',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          isActive ? 'Active (Streaming)' : 'Disabled (Paused)',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: isActive ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                                          ),
                                        ),
                                        Switch.adaptive(
                                          value: isActive,
                                          activeTrackColor: const Color(0xFF1C7BFF),
                                          onChanged: (v) {
                                            setDialogState(() => isActive = v);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      final title = titleController.text.trim();
                      final desc = descController.text.trim();
                      final videoUrl = videoUrlController.text.trim();
                      final badge = badgeController.text.trim().isNotEmpty
                          ? badgeController.text.trim()
                          : 'PROMO';
                      final cta = ctaController.text.trim().isNotEmpty
                          ? ctaController.text.trim()
                          : 'Shop Now';

                      if (existingVideo != null) {
                        final updated = existingVideo.copyWith(
                          title: title,
                          description: desc,
                          videoUrl: videoUrl,
                          badgeText: badge,
                          callToActionText: cta,
                          targetCategoryOrProduct: target,
                          isActive: isActive,
                        );
                        widget.repository.updatePlaylistVideo(targetBanner, updated);
                      } else {
                        final newVideo = BannerVideoItem(
                          id: 'VID-${DateTime.now().millisecondsSinceEpoch}',
                          videoUrl: videoUrl,
                          title: title,
                          description: desc,
                          badgeText: badge,
                          callToActionText: cta,
                          targetCategoryOrProduct: target,
                          isActive: isActive,
                          createdAt: DateTime.now(),
                        );
                        widget.repository.addVideoToPlaylist(targetBanner, newVideo);
                      }

                      setState(() {
                        _selectedPlaylistId = targetBanner;
                      });

                      Navigator.of(dialogCtx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEditing
                                ? 'Video advertisement updated successfully'
                                : 'New video advertisement added to ${targetBanner == "banner_home_1" ? "Homepage Banner 1" : "Search Page Banner"}',
                          ),
                          backgroundColor: const Color(0xFF059669),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1C7BFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Text(isEditing ? 'Save Changes' : 'Add to Video Banner'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSmartBannerImage(
    String url, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: const Color(0xFF0F172A),
        child: const Center(
          child: Icon(Icons.broken_image_rounded, size: 20, color: Colors.white38),
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
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _errorBannerWidget(width, height),
        );
      } catch (_) {}
    }

    if (trimmed.startsWith('file://')) {
      try {
        final file = File(Uri.parse(trimmed).toFilePath());
        if (file.existsSync()) {
          return Image.file(
            file,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => _errorBannerWidget(width, height),
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
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => _errorBannerWidget(width, height),
          );
        }
      } catch (_) {}
    }

    return Image.network(
      trimmed,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _errorBannerWidget(width, height),
    );
  }

  Widget _errorBannerWidget(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFF0F172A),
      child: const Center(
        child: Icon(Icons.broken_image_rounded, size: 20, color: Colors.white38),
      ),
    );
  }

  void _showAddImageDialog(BuildContext context, [String? initialPlaylistId]) {
    String targetPlaylist = (initialPlaylistId == 'banner_home_1' ||
            initialPlaylistId == 'banner_home_2' ||
            initialPlaylistId == 'banner_home_3' ||
            initialPlaylistId == 'banner_home_4')
        ? initialPlaylistId!
        : 'banner_home_2';

    final urlController = TextEditingController();
    final titleController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String previewUrl = '';

    final presets = [
      (
        label: 'iPhone 15 Pro Max',
        url: 'https://images.unsplash.com/photo-1695048133142-1a20484d2569?auto=format&fit=crop&w=800&q=80',
        title: 'iPhone 15 Pro Max • Natural Titanium',
      ),
      (
        label: 'Galaxy S24 Ultra',
        url: 'https://images.unsplash.com/photo-1610945415295-d9bbf067e59c?auto=format&fit=crop&w=800&q=80',
        title: 'Samsung Galaxy S24 Ultra • Titanium Gray',
      ),
      (
        label: 'Pixel 9 Pro XL',
        url: 'https://images.unsplash.com/photo-1598327105666-5b89351aff97?auto=format&fit=crop&w=800&q=80',
        title: 'Google Pixel 9 Pro XL • Hazel Glass',
      ),
      (
        label: 'Galaxy Z Fold 6',
        url: 'https://images.unsplash.com/photo-1585060544812-6b45742d762f?auto=format&fit=crop&w=800&q=80',
        title: 'Galaxy Z Fold 6 • Silver Shadow',
      ),
      (
        label: 'Screen Protector',
        url: 'https://images.unsplash.com/photo-1565849904461-04a58ad377e0?auto=format&fit=crop&w=800&q=80',
        title: 'Diamond Glass Screen & Lens Guard',
      ),
      (
        label: 'High-Res Camera',
        url: 'https://images.unsplash.com/photo-1580910051074-3eb694886505?auto=format&fit=crop&w=800&q=80',
        title: 'Ultra High-Res Camera Series',
      ),
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.add_photo_alternate_rounded,
                      color: Color(0xFF059669),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Image to Banner Playlist',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'This image will cycle inside the selected promotional image banner slide',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 580,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // Playlist Destination Dropdown (Only Image Banners: 2, 3, 4)
                        const Text(
                          'Select Target Image Banner Slide *',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: targetPlaylist,
                              isExpanded: true,
                              style: const TextStyle(
                                color: Color(0xFF1E293B),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'banner_home_1',
                                  child: Text('Homepage Banner 1 (Discover Smartphones - Slide 1)'),
                                ),
                                DropdownMenuItem(
                                  value: 'banner_home_2',
                                  child: Text('Homepage Banner 2 (Flagship Deals 20% Off - Slide 2)'),
                                ),
                                DropdownMenuItem(
                                  value: 'banner_home_3',
                                  child: Text('Homepage Banner 3 (Trade-in Deals & Credit - Slide 3)'),
                                ),
                                DropdownMenuItem(
                                  value: 'banner_home_4',
                                  child: Text('Homepage Banner 4 (Premium Care Protection - Slide 4)'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => targetPlaylist = val);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Select which homepage promotional banner slide will display this image.',
                          style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 16),

                        // Image Presets
                        const Text(
                          'Quick Preset Images (1-Click Fill)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: presets.map((preset) {
                            return ActionChip(
                              avatar: const Icon(Icons.photo_size_select_actual_outlined, size: 14, color: Color(0xFF0D62FE)),
                              label: Text(preset.label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                              backgroundColor: const Color(0xFFF1F5F9),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              onPressed: () {
                                setDialogState(() {
                                  urlController.text = preset.url;
                                  titleController.text = preset.title;
                                  previewUrl = preset.url;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Choose from PC File Picker
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    final file = await FilePicker.pickFile(
                                      type: FileType.custom,
                                      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
                                    );
                                    if (file != null) {
                                      final bytes = await file.xFile.readAsBytes();
                                      if (bytes.isNotEmpty) {
                                        final ext = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : 'png';
                                        final mimeExt = (ext == 'jpg' || ext == 'jpeg') ? 'jpeg' : (ext == 'webp' ? 'webp' : 'png');
                                        final dataUri = 'data:image/$mimeExt;base64,${base64Encode(bytes)}';
                                        setDialogState(() {
                                          urlController.text = dataUri;
                                          previewUrl = dataUri;
                                          if (titleController.text.trim().isEmpty) {
                                            titleController.text = file.name;
                                          }
                                        });
                                      }
                                    }
                                  } catch (e) {
                                    debugPrint('Error picking image file: $e');
                                  }
                                },
                                icon: const Icon(Icons.computer_rounded, size: 18),
                                label: const Text('Browse PC for Image File'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F172A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Image URL / Local File Path
                        const Text(
                          'Image Path / Web URL *',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: urlController,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Image path or URL is required' : null,
                          onChanged: (v) {
                            setDialogState(() {
                              previewUrl = v.trim();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'PC file path (e.g. C:\\Images\\banner.png) or https:// link',
                            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            suffixIcon: previewUrl.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      urlController.clear();
                                      setDialogState(() => previewUrl = '');
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Image Title / Label
                        const Text(
                          'Image Title / Caption',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: titleController,
                          decoration: InputDecoration(
                            hintText: 'e.g. iPhone 15 Pro Max • Natural Titanium',
                            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Live Preview Box
                        const Text(
                          'Live Image Preview',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: previewUrl.isNotEmpty
                              ? _buildSmartBannerImage(previewUrl, fit: BoxFit.contain)
                              : const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image_outlined, color: Colors.white38, size: 28),
                                      SizedBox(height: 4),
                                      Text('Browse PC or enter an image URL above to preview', style: TextStyle(color: Colors.white60, fontSize: 11)),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      final existingImages = widget.repository.getBannerPlaylist(targetPlaylist)?.images ?? [];
                      if (existingImages.length >= 3) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Maximum 3 images allowed for ${widget.repository.getBannerPlaylist(targetPlaylist)?.name ?? "this banner"} (Positions 1, 2, and 3). Please remove an image first.',
                            ),
                            backgroundColor: const Color(0xFFDC2626),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      String imgUrl = urlController.text.trim();
                      if (!imgUrl.startsWith('http://') &&
                          !imgUrl.startsWith('https://') &&
                          !imgUrl.startsWith('data:image')) {
                        try {
                          final pathClean = imgUrl.startsWith('file://')
                              ? Uri.parse(imgUrl).toFilePath()
                              : imgUrl;
                          final localFile = File(pathClean);
                          if (localFile.existsSync()) {
                            final bytes = await localFile.readAsBytes();
                            final ext = localFile.path.contains('.')
                                ? localFile.path.split('.').last.toLowerCase()
                                : 'png';
                            final mimeExt = (ext == 'jpg' || ext == 'jpeg') ? 'jpeg' : (ext == 'webp' ? 'webp' : 'png');
                            imgUrl = 'data:image/$mimeExt;base64,${base64Encode(bytes)}';
                          }
                        } catch (e) {
                          debugPrint('Note: could not convert file path to data URI: $e');
                        }
                      }

                      final newImage = BannerImageItem(
                        id: 'IMG-${DateTime.now().millisecondsSinceEpoch}',
                        imageUrl: imgUrl,
                        title: titleController.text.trim().isNotEmpty
                            ? titleController.text.trim()
                            : 'Banner Image',
                        isActive: true,
                        createdAt: DateTime.now(),
                      );
                      widget.repository.addImageToPlaylist(targetPlaylist, newImage);
                      if (mounted) {
                        setState(() {
                          _selectedPlaylistId = targetPlaylist;
                        });
                      }
                      if (dialogCtx.mounted) {
                        Navigator.of(dialogCtx).pop();
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Image added to ${widget.repository.getBannerPlaylist(targetPlaylist)?.name ?? "playlist"}!'),
                            backgroundColor: const Color(0xFF059669),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('Add Image to Playlist'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.repository,
      builder: (context, _) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isCompact = screenWidth < 1050;

        final bannerPlaylists = widget.repository.bannerPlaylists;
        final activePlaylistsCount = bannerPlaylists.where((p) => p.isActive).length;

        // Video playlists (banner_home_1 and banner_search_1)
        final videoPlaylists = bannerPlaylists.where((p) => p.isVideoBanner);
        final totalVideos = videoPlaylists.fold<int>(0, (sum, p) => sum + p.videos.length);
        final activeVideos = videoPlaylists.fold<int>(0, (sum, p) => sum + p.activeVideos.length);

        // Image playlists (banner_home_2, banner_home_3, banner_home_4)
        final imagePlaylists = bannerPlaylists.where((p) => p.isImageBanner);
        final totalImages = imagePlaylists.fold<int>(0, (sum, p) => sum + p.images.length);
        final activeImages = imagePlaylists.fold<int>(0, (sum, p) => sum + p.activeImages.length);

        final selectedPlaylist = widget.repository.getBannerPlaylist(_selectedPlaylistId) ??
            (bannerPlaylists.isNotEmpty ? bannerPlaylists.first : null);

        return Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.all(isCompact ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Advertisement & Video Banner Hub',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage the 5 Mobile Banner Playlists (2 Video-only banner slots + 3 Promotional image slides)',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _showAddImageDialog(context, _selectedPlaylistId),
                          icon: const Icon(Icons.add_photo_alternate_rounded, size: 20),
                          label: const Text('Add Image to Playlist'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showAddEditAdDialog(context),
                          icon: const Icon(Icons.videocam_rounded, size: 20),
                          label: const Text('New Video Advertisement'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1C7BFF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // KPI Metric Cards
                isCompact
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 220,
                              child: _buildMetric(
                                label: '5 BANNER SLOTS',
                                value: '2 Video • 3 Image',
                                icon: Icons.dashboard_customize_rounded,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 220,
                              child: _buildMetric(
                                label: 'VIDEO ADVERTISEMENTS',
                                value: '$activeVideos Active ($totalVideos Total)',
                                icon: Icons.videocam_rounded,
                                color: const Color(0xFF1C7BFF),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 220,
                              child: _buildMetric(
                                label: 'PROMOTIONAL IMAGES',
                                value: '$activeImages Active ($totalImages Total)',
                                icon: Icons.photo_library_rounded,
                                color: const Color(0xFF059669),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 220,
                              child: _buildMetric(
                                label: 'MOBILE APP SYNC',
                                value: '$activePlaylistsCount / 5 Active',
                                icon: Icons.sync_rounded,
                                color: const Color(0xFF7C3AED),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _buildMetric(
                              label: '5 BANNER SLOTS',
                              value: '2 Video • 3 Image',
                              icon: Icons.dashboard_customize_rounded,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetric(
                              label: 'VIDEO ADVERTISEMENTS',
                              value: '$activeVideos Active ($totalVideos Total)',
                              icon: Icons.videocam_rounded,
                              color: const Color(0xFF1C7BFF),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetric(
                              label: 'PROMOTIONAL IMAGES',
                              value: '$activeImages Active ($totalImages Total)',
                              icon: Icons.photo_library_rounded,
                              color: const Color(0xFF059669),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetric(
                              label: 'MOBILE APP SYNC',
                              value: '$activePlaylistsCount / 5 Active',
                              icon: Icons.sync_rounded,
                              color: const Color(0xFF7C3AED),
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 20),

                // Notice Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFF1D4ED8), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Banner Architecture: Homepage Slide 1 and the Search Page Banner are dedicated solely to Video Ads. Homepage Slides 2, 3 & 4 are dedicated solely to Promotional Image playlists. Managers can only add video ads to the video banners, and promotional images to the image slides.',
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 5 Playlists Selector Bar
                _buildPlaylistsSelector(bannerPlaylists, _selectedPlaylistId, isCompact),
                const SizedBox(height: 20),

                // Selected Playlist Studio Panel (Full Width)
                if (selectedPlaylist != null) ...[
                  if (selectedPlaylist.isVideoBanner) ...[
                    _buildPlaylistVideosPanel(selectedPlaylist),
                    if (selectedPlaylist.images.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildPlaylistImagesPanel(selectedPlaylist),
                    ],
                  ] else
                    _buildPlaylistImagesPanel(selectedPlaylist),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaylistsSelector(
    List<BannerPlaylist> playlists,
    String selectedId,
    bool isCompact,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, headerConstraints) {
              final isHeaderNarrow = headerConstraints.maxWidth < 650;
              if (isHeaderNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.collections_bookmark_rounded, color: Color(0xFF1C7BFF), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'The 5 Mobile Banner Playlists',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                '1-to-1 sync with the 4 Homepage slides and 1 Search banner on the customer mobile app',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Text(
                        '5 OF 5 SYNCHRONIZED',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                      ),
                    ),
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.collections_bookmark_rounded, color: Color(0xFF1C7BFF), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'The 5 Mobile Banner Playlists',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                '1-to-1 sync with the 4 Homepage slides and 1 Search banner on the customer mobile app',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Text(
                      '5 OF 5 SYNCHRONIZED',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          // 5 Playlist Cards Row
          LayoutBuilder(
            builder: (context, constraints) {
              final shouldScroll = isCompact || constraints.maxWidth < 1000;
              final cardWidth = shouldScroll ? 240.0 : (constraints.maxWidth - 48) / 5;
              final items = playlists.map((p) => _buildPlaylistCard(p, p.id == selectedId, cardWidth)).toList();

              if (shouldScroll) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: items.map((w) => Padding(padding: const EdgeInsets.only(right: 12), child: w)).toList(),
                  ),
                );
              }

              return Row(
                children: [
                  for (int i = 0; i < items.length; i++) ...[
                    Expanded(child: items[i]),
                    if (i < items.length - 1) const SizedBox(width: 12),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistCard(BannerPlaylist playlist, bool isSelected, double width) {
    final isHome = playlist.targetPage == 'home';
    final isVideo = playlist.isVideoBanner;

    final String slideBadge;
    final Color badgeColor;
    final IconData typeIcon;
    final String countLabel;

    if (isVideo) {
      slideBadge = isHome ? 'VIDEO ONLY • SLIDE 1' : 'VIDEO ONLY • SEARCH';
      badgeColor = isHome ? const Color(0xFF1C7BFF) : const Color(0xFF7C3AED);
      typeIcon = Icons.videocam_rounded;
      final activeCount = playlist.activeVideos.length;
      final totalCount = playlist.videos.length;
      countLabel = '$activeCount / $totalCount Active Videos';
    } else {
      slideBadge = 'IMAGES • SLIDE ${playlist.bannerIndex + 1}';
      badgeColor = const Color(0xFF059669);
      typeIcon = Icons.photo_library_outlined;
      final activeCount = playlist.activeImages.length;
      final totalCount = playlist.images.length;
      countLabel = '$activeCount / $totalCount Active Images';
    }

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPlaylistId = playlist.id;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F7FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1C7BFF) : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1C7BFF).withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    slideBadge,
                    style: TextStyle(
                      fontSize: 9.0,
                      fontWeight: FontWeight.w800,
                      color: badgeColor,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Switch(
                  value: playlist.isActive,
                  onChanged: (val) => widget.repository.togglePlaylistActive(playlist.id),
                  activeTrackColor: const Color(0xFF16A34A),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              playlist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isSelected ? const Color(0xFF1C7BFF) : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              playlist.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      typeIcon,
                      size: 13,
                      color: isVideo ? const Color(0xFF1C7BFF) : const Color(0xFF059669),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      countLabel,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isVideo ? const Color(0xFF1C7BFF) : const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF1C7BFF))
                else
                  const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Videos Panel for banner_home_1 and banner_search_1 (Solely for video ads)
  Widget _buildPlaylistVideosPanel(BannerPlaylist playlist) {
    final videos = playlist.videos;
    final isHome = playlist.targetPage == 'home';
    final targetLabel = isHome
        ? 'Homepage Banner Slide 1 (Solely Video Ads)'
        : 'Search Page Banner (Solely Video Ads)';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Text(
                          playlist.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Text(
                            targetLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Solely video ads play sequentially inside this mobile banner slot. Only video streaming links can be added.',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddEditVideoDialog(context, initialPlaylistId: playlist.id),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Video to Banner'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C7BFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),

          if (videos.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.video_library_outlined, size: 48, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 10),
                  Text(
                    'No video advertisements in ${playlist.name}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'This banner slot is solely for video ads. Add MP4 or streaming video links to play live on customer devices.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditVideoDialog(context, initialPlaylistId: playlist.id),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add First Video Ad'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1C7BFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: videos.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final video = videos[index];
                final isFirst = index == 0;
                final isLast = index == videos.length - 1;
                final isNetworkUrl = video.videoUrl.startsWith('http://') || video.videoUrl.startsWith('https://');

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: video.isActive ? Colors.white : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: video.isActive ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Order Badge, Badge Tag, Title, Reorder arrows, Active Switch
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'VIDEO #${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: Text(
                                  video.badgeText,
                                  style: const TextStyle(
                                    color: Color(0xFF1D4ED8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                video.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: video.isActive ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                                color: isFirst ? Colors.grey.shade300 : const Color(0xFF475569),
                                onPressed: isFirst
                                    ? null
                                    : () => widget.repository.reorderPlaylistVideos(playlist.id, index, index - 1),
                                tooltip: 'Move Up',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                                color: isLast ? Colors.grey.shade300 : const Color(0xFF475569),
                                onPressed: isLast
                                    ? null
                                    : () => widget.repository.reorderPlaylistVideos(playlist.id, index, index + 1),
                                tooltip: 'Move Down',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                              const SizedBox(width: 6),
                              Tooltip(
                                message: video.isActive ? 'Active on banner' : 'Disabled from banner',
                                child: Switch.adaptive(
                                  value: video.isActive,
                                  activeTrackColor: const Color(0xFF1C7BFF),
                                  onChanged: (_) => widget.repository.togglePlaylistVideoStatus(playlist.id, video.id),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Description
                      if (video.description.isNotEmpty) ...[
                        Text(
                          video.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF475569),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Video Stream URL Box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isNetworkUrl ? Icons.cloud_done_rounded : Icons.folder_zip_rounded,
                              size: 16,
                              color: isNetworkUrl ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                video.videoUrl,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: video.videoUrl));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Video link copied to clipboard!'),
                                    duration: Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.copy_rounded, size: 14, color: Color(0xFF1C7BFF)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Copy',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF1C7BFF),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Footer Row: CTA + Actions
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.touch_app_rounded, size: 13, color: Color(0xFF475569)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'CTA: "${video.callToActionText}"',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_right_alt_rounded, size: 16, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 6),
                              Text(
                                video.targetCategoryOrProduct,
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 17, color: Color(0xFF475569)),
                                tooltip: 'Edit Video Ad',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                onPressed: () => _showAddEditVideoDialog(
                                  context,
                                  initialPlaylistId: playlist.id,
                                  existingVideo: video,
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 17, color: Color(0xFFDC2626)),
                                tooltip: 'Delete',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                onPressed: () => _confirmDeletePlaylistVideo(context, playlist.id, video),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _confirmDeletePlaylistVideo(BuildContext context, String playlistId, BannerVideoItem video) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Video Advertisement?'),
        content: Text(
          'Are you sure you want to remove "${video.title}" from this video banner? It will no longer play on customer mobile devices.',
          style: const TextStyle(color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              widget.repository.removeVideoFromPlaylist(playlistId, video.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Removed "${video.title}" from video banner'),
                  backgroundColor: const Color(0xFFDC2626),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistImagesPanel(BannerPlaylist playlist) {
    final images = playlist.images;
    final targetLabel = 'Homepage Banner Slide ${playlist.bannerIndex + 1} (Max 3 Images: Positions 1, 2, 3)';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Text(
                          playlist.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Text(
                            targetLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Up to 3 promotional images can be added. Image 1 renders in Position 1 (Back), Image 2 in Position 2 (Middle), and Image 3 in Position 3 (Front).',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddImageDialog(context, playlist.id),
                icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                label: Text(images.length >= 3 ? 'Banner Full (3/3)' : 'Add Image (${images.length}/3)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: images.length >= 3 ? const Color(0xFF94A3B8) : const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),

          if (images.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.image_outlined, size: 48, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 10),
                  Text(
                    'No images in ${playlist.name}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Add up to 3 phone photos or promotional graphics to display in Positions 1, 2, and 3 on this mobile banner slide.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddImageDialog(context, playlist.id),
                    icon: const Icon(Icons.add_photo_alternate_rounded, size: 16),
                    label: const Text('Add First Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: images.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final img = images[index];
                final isFirst = index == 0;
                final isLast = index == images.length - 1;
                final positionTag = index == 0
                    ? 'POS 1 (BACK CARD)'
                    : (index == 1 ? 'POS 2 (MIDDLE CARD)' : 'POS 3 (FRONT CARD)');

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: img.isActive ? Colors.white : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: img.isActive ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Order & Position Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '#${index + 1}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              positionTag,
                              style: const TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF38BDF8),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Image Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 54,
                          height: 54,
                          color: const Color(0xFF0F172A),
                          child: _buildSmartBannerImage(
                            img.imageUrl,
                            fit: BoxFit.cover,
                            width: 54,
                            height: 54,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Title & URL
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              img.title.isNotEmpty ? img.title : 'Banner Image #${index + 1}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: img.isActive ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              img.imageUrl,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Reorder buttons
                      IconButton(
                        icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                        color: isFirst ? Colors.grey.shade300 : const Color(0xFF475569),
                        onPressed: isFirst
                            ? null
                            : () => widget.repository.reorderPlaylistImages(playlist.id, index, index - 1),
                        tooltip: 'Move Up',
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                        color: isLast ? Colors.grey.shade300 : const Color(0xFF475569),
                        onPressed: isLast
                            ? null
                            : () => widget.repository.reorderPlaylistImages(playlist.id, index, index + 1),
                        tooltip: 'Move Down',
                      ),
                      const SizedBox(width: 4),

                      // Active Switch
                      Switch(
                        value: img.isActive,
                        onChanged: (val) => widget.repository.togglePlaylistImageStatus(playlist.id, img.id),
                        activeTrackColor: const Color(0xFF16A34A),
                      ),
                      const SizedBox(width: 4),

                      // Delete button
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 19, color: Color(0xFFDC2626)),
                        onPressed: () => _confirmDeletePlaylistImage(context, playlist.id, img),
                        tooltip: 'Delete Image',
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _confirmDeletePlaylistImage(BuildContext context, String playlistId, BannerImageItem img) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Image from Playlist?'),
        content: Text(
          'Are you sure you want to remove "${img.title.isNotEmpty ? img.title : 'this image'}" from the playlist? It will no longer be rendered on the customer mobile app banner.',
          style: const TextStyle(color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              widget.repository.removeImageFromPlaylist(playlistId, img.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Removed image from playlist'),
                  backgroundColor: Color(0xFFDC2626),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
