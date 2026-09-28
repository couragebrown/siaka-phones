import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/manager_repository.dart';
import '../../../domain/models/advertisement_banner.dart';

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
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedStatus = 'All'; // All, Active Only, Inactive Only
  int _selectedPreviewIndex = 0;
  bool _simulatorPlaying = true;

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<AdvertisementBanner> _getFilteredAdvertisements() {
    final ads = widget.repository.advertisements;
    return ads.where((ad) {
      if (_selectedStatus == 'Active Only' && !ad.isActive) return false;
      if (_selectedStatus == 'Inactive Only' && ad.isActive) return false;

      if (_selectedCategory != 'All' &&
          ad.targetCategoryOrProduct.toLowerCase() !=
              _selectedCategory.toLowerCase()) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = ad.title.toLowerCase().contains(query);
        final matchesDesc = ad.description.toLowerCase().contains(query);
        final matchesBadge = ad.badgeText.toLowerCase().contains(query);
        final matchesUrl = ad.videoUrl.toLowerCase().contains(query);
        if (!matchesTitle && !matchesDesc && !matchesBadge && !matchesUrl) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _showAddEditAdDialog(BuildContext context, [AdvertisementBanner? existingAd]) {
    final isEditing = existingAd != null;
    final titleController = TextEditingController(text: existingAd?.title ?? '');
    final descController = TextEditingController(text: existingAd?.description ?? '');
    final videoUrlController = TextEditingController(
      text: existingAd?.videoUrl ?? 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    );
    final backupAssetController = TextEditingController(text: existingAd?.backupAsset ?? 'assets/videos/phone_promo.mp4');
    final badgeController = TextEditingController(text: existingAd?.badgeText ?? 'PROMO');
    final ctaController = TextEditingController(text: existingAd?.callToActionText ?? 'Shop Now');
    String target = existingAd?.targetCategoryOrProduct ?? 'Smartphones';
    bool isActive = existingAd?.isActive ?? true;

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
                      isEditing ? Icons.edit_note_rounded : Icons.campaign_rounded,
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
                          'Configure banner video link, title, and call to action',
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
                                    'Active in Video Playlist',
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
                                          isActive ? 'Active (Playing)' : 'Disabled (Skipped)',
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
                      if (isEditing) {
                        final updated = existingAd.copyWith(
                          title: titleController.text.trim(),
                          description: descController.text.trim(),
                          videoUrl: videoUrlController.text.trim(),
                          backupAsset: backupAssetController.text.trim(),
                          badgeText: badgeController.text.trim(),
                          callToActionText: ctaController.text.trim(),
                          targetCategoryOrProduct: target,
                          isActive: isActive,
                        );
                        widget.repository.updateAdvertisement(updated);
                      } else {
                        final newId = 'AD-2026-${widget.repository.advertisements.length + 1}'.padLeft(3, '0');
                        final newAd = AdvertisementBanner(
                          id: newId,
                          title: titleController.text.trim(),
                          description: descController.text.trim(),
                          videoUrl: videoUrlController.text.trim(),
                          backupAsset: backupAssetController.text.trim(),
                          badgeText: badgeController.text.trim(),
                          callToActionText: ctaController.text.trim(),
                          targetCategoryOrProduct: target,
                          isActive: isActive,
                          displayOrder: widget.repository.advertisements.length + 1,
                          createdAt: DateTime.now(),
                        );
                        widget.repository.addAdvertisement(newAd);
                      }
                      Navigator.of(dialogCtx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEditing ? 'Advertisement updated successfully' : 'New advertisement added to playlist',
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
                  child: Text(isEditing ? 'Save Changes' : 'Add to Playlist'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteAd(BuildContext context, AdvertisementBanner ad) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Advertisement?'),
        content: Text(
          'Are you sure you want to remove "${ad.title}" from the video playlist? This action cannot be undone.',
          style: const TextStyle(color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              widget.repository.deleteAdvertisement(ad.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Removed "${ad.title}" from playlist'),
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.repository,
      builder: (context, _) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isCompact = screenWidth < 1050;
        final filteredAds = _getFilteredAdvertisements();

        final totalAds = widget.repository.advertisements.length;
        final activeAds = widget.repository.activeAdvertisementsCount;
        final totalImpressions = widget.repository.totalAdImpressions;
        final totalClicks = widget.repository.totalAdClicks;
        final ctr = totalImpressions > 0 ? ((totalClicks / totalImpressions) * 100).toStringAsFixed(1) : '0.0';

        // Clamp selected preview index
        if (_selectedPreviewIndex >= filteredAds.length && filteredAds.isNotEmpty) {
          _selectedPreviewIndex = filteredAds.length - 1;
        }

        final currentPreviewAd = filteredAds.isNotEmpty
            ? filteredAds[_selectedPreviewIndex.clamp(0, filteredAds.length - 1)]
            : null;

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
                          'Manage video links, promotion campaigns, and sequential ads played on the mobile home banner',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddEditAdDialog(context),
                      icon: const Icon(Icons.add_rounded, size: 20),
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
                                label: 'ACTIVE PROMO ADS',
                                value: '$activeAds Active',
                                icon: Icons.play_circle_fill_rounded,
                                color: const Color(0xFF059669),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 220,
                              child: _buildMetric(
                                label: 'TOTAL PLAYLIST VIDEOS',
                                value: '$totalAds Videos',
                                icon: Icons.video_library_rounded,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 220,
                              child: _buildMetric(
                                label: 'TOTAL IMPRESSIONS',
                                value: NumberFormat.compact().format(totalImpressions),
                                icon: Icons.visibility_rounded,
                                color: const Color(0xFF7C3AED),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 220,
                              child: _buildMetric(
                                label: 'CLICK-THROUGH RATE',
                                value: '$ctr%',
                                icon: Icons.ads_click_rounded,
                                color: const Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _buildMetric(
                              label: 'ACTIVE PROMO ADS',
                              value: '$activeAds Active',
                              icon: Icons.play_circle_fill_rounded,
                              color: const Color(0xFF059669),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetric(
                              label: 'TOTAL PLAYLIST VIDEOS',
                              value: '$totalAds Videos',
                              icon: Icons.video_library_rounded,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetric(
                              label: 'TOTAL IMPRESSIONS',
                              value: NumberFormat.compact().format(totalImpressions),
                              icon: Icons.visibility_rounded,
                              color: const Color(0xFF7C3AED),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetric(
                              label: 'CLICK-THROUGH RATE',
                              value: '$ctr%',
                              icon: Icons.ads_click_rounded,
                              color: const Color(0xFFD97706),
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
                          'Sequential Video Player: The mobile app automatically plays video links in the order listed below. When a video reaches the end, it immediately advances to the next video before advancing the home banner.',
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

                // Filters & Search Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Search box
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 260, maxWidth: 360),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            hintText: 'Search by headline, badge, or link...',
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                        ),
                      ),

                      // Status Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStatus,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
                            items: const [
                              DropdownMenuItem(value: 'All', child: Text('All Statuses')),
                              DropdownMenuItem(value: 'Active Only', child: Text('Active Only')),
                              DropdownMenuItem(value: 'Inactive Only', child: Text('Inactive Only')),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedStatus = v);
                            },
                          ),
                        ),
                      ),

                      // Category Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
                            items: const [
                              DropdownMenuItem(value: 'All', child: Text('All Categories')),
                              DropdownMenuItem(value: 'Smartphones', child: Text('Smartphones')),
                              DropdownMenuItem(value: 'Phones', child: Text('Phones')),
                              DropdownMenuItem(value: 'Laptops', child: Text('Laptops')),
                              DropdownMenuItem(value: 'Accessories', child: Text('Accessories')),
                              DropdownMenuItem(value: 'BNPL', child: Text('BNPL')),
                              DropdownMenuItem(value: 'TradeIn', child: Text('Trade-in')),
                              DropdownMenuItem(value: 'Repairs', child: Text('Repairs')),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedCategory = v);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Main Content Area: Left Queue + Right Simulator
                if (!isCompact)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Queue (60%)
                      Expanded(
                        flex: 6,
                        child: _buildPlaylistQueue(filteredAds),
                      ),
                      const SizedBox(width: 20),
                      // Right Simulator (40%)
                      Expanded(
                        flex: 4,
                        child: _buildMobileSimulator(currentPreviewAd, filteredAds),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildMobileSimulator(currentPreviewAd, filteredAds),
                      const SizedBox(height: 20),
                      _buildPlaylistQueue(filteredAds),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaylistQueue(List<AdvertisementBanner> ads) {
    if (ads.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.campaign_outlined, size: 48, color: Color(0xFF94A3B8)),
              const SizedBox(height: 12),
              const Text(
                'No advertisements found',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 4),
              const Text(
                'Try adjusting your search query or add a new video advertisement.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showAddEditAdDialog(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Video Ad'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C7BFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(
              'Sequential Video Playlist Queue (${ads.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Use ▲▼ arrows to set playback order',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ads.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final ad = ads[index];
            final isSelected = index == _selectedPreviewIndex;

            return _buildAdCard(ad, index, ads.length, isSelected);
          },
        ),
      ],
    );
  }

  Widget _buildAdCard(AdvertisementBanner ad, int index, int totalCount, bool isSelected) {
    final isNetworkUrl = ad.videoUrl.startsWith('http://') || ad.videoUrl.startsWith('https://');

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPreviewIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1C7BFF) : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1C7BFF).withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Order, Badge, Title, Reorder arrows, Active Switch
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Order badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'PLAYLIST #${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Promo Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    ad.badgeText,
                    style: const TextStyle(
                      color: Color(0xFF1D4ED8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Title
                Expanded(
                  child: Text(
                    ad.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),

                // Reorder arrows
                IconButton(
                  icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                  tooltip: 'Move Up in Sequence',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  color: index > 0 ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  onPressed: index > 0
                      ? () {
                          widget.repository.reorderAdvertisement(index, index - 1);
                        }
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                  tooltip: 'Move Down in Sequence',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  color: index < totalCount - 1 ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  onPressed: index < totalCount - 1
                      ? () {
                          widget.repository.reorderAdvertisement(index, index + 1);
                        }
                      : null,
                ),
                const SizedBox(width: 8),

                // Active toggle
                Tooltip(
                  message: ad.isActive ? 'Active on Mobile Home' : 'Disabled from Mobile Banner',
                  child: Switch.adaptive(
                    value: ad.isActive,
                    activeTrackColor: const Color(0xFF1C7BFF),
                    onChanged: (_) {
                      widget.repository.toggleAdvertisementStatus(ad.id);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Description
            Text(
              ad.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),

            // Video Link Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      ad.videoUrl,
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
                      Clipboard.setData(ClipboardData(text: ad.videoUrl));
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
            const SizedBox(height: 12),

            // Bottom Footer: CTA Destination, Performance, Actions
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                // CTA and Target
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
                            'CTA: "${ad.callToActionText}"',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_right_alt_rounded, size: 16, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 6),
                    Text(
                      ad.targetCategoryOrProduct,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),

                // Metrics & Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${NumberFormat.compact().format(ad.impressionsCount)} views • ${ad.clicksCount} clicks (${ad.clickThroughRate.toStringAsFixed(1)}% CTR)',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 17, color: Color(0xFF475569)),
                      tooltip: 'Edit Advertisement',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                      onPressed: () => _showAddEditAdDialog(context, ad),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 17, color: Color(0xFFDC2626)),
                      tooltip: 'Delete',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                      onPressed: () => _confirmDeleteAd(context, ad),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileSimulator(AdvertisementBanner? ad, List<AdvertisementBanner> allAds) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.smartphone_rounded, color: Color(0xFF1C7BFF), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Live Mobile Banner Simulator',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fiber_manual_record, size: 8, color: Color(0xFF16A34A)),
                    SizedBox(width: 4),
                    Text(
                      'PREVIEW',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF16A34A)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Preview how this ad looks inside the 16:10 video player on mobile',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          if (ad == null)
            Container(
              height: 200,
              alignment: Alignment.center,
              child: const Text('No ad selected for simulation', style: TextStyle(color: Color(0xFF94A3B8))),
            )
          else ...[
            // The Simulated Mobile Hero Slide Banner
            Container(
              height: 175,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0D1B2A),
                    Color(0xFF1B263B),
                    Color(0xFF1E3A8A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Subtle glow circle
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      ),
                    ),
                  ),

                  // Left Side Content & Right Side 16:10 Player
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        // Left Content (flex: 10)
                        Expanded(
                          flex: 10,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1C7BFF),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  ad.badgeText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Title
                              Text(
                                ad.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Description
                              Text(
                                ad.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 10,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // CTA Button
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      ad.callToActionText,
                                      style: const TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_forward_rounded, size: 11, color: Color(0xFF0F172A)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Right 16:10 Player Container (flex: 11)
                        Expanded(
                          flex: 11,
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: 16 / 10,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Simulated video frame / animation
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(9),
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFF1E293B),
                                            const Color(0xFF0F172A),
                                            Colors.blue.shade900.withValues(alpha: 0.4),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.play_circle_fill_rounded,
                                              size: 32,
                                              color: Colors.white.withValues(alpha: 0.9),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '16:10 Video Link Player',
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.8),
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Top Playlist Badge (e.g. PROMO 1/3)
                                    Positioned(
                                      top: 6,
                                      left: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.65),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'PROMO ${_selectedPreviewIndex + 1}/${allAds.length}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Bottom controls overlay
                                    Positioned(
                                      bottom: 4,
                                      left: 6,
                                      right: 6,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _simulatorPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                                size: 14,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(
                                                Icons.volume_up_rounded,
                                                size: 14,
                                                color: Colors.white,
                                              ),
                                            ],
                                          ),
                                          const Icon(
                                            Icons.fullscreen_rounded,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Simulator Control Buttons
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Playlist Simulation Controls:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _simulatorPlaying = !_simulatorPlaying;
                            });
                          },
                          icon: Icon(
                            _simulatorPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: 16,
                          ),
                          label: Text(_simulatorPlaying ? 'Pause Video' : 'Play Video'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1E293B),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: allAds.length > 1
                              ? () {
                                  setState(() {
                                    _selectedPreviewIndex = (_selectedPreviewIndex + 1) % allAds.length;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.skip_next_rounded, size: 16),
                          label: const Text('Next In Playlist'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
                    fontSize: 18,
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
