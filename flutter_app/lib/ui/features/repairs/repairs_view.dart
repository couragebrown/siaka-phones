import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'repairs_view_model.dart';

class RepairsView extends StatefulWidget {
  final RepairsViewModel viewModel;

  const RepairsView({super.key, required this.viewModel});

  @override
  State<RepairsView> createState() => _RepairsViewState();
}

class _RepairsViewState extends State<RepairsView> {
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.viewModel.description);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  IconData _getIssueIcon(String issue) {
    if (issue.contains('Screen') || issue.contains('Crack')) {
      return Icons.phone_android_rounded;
    }
    if (issue.contains('Battery') || issue.contains('Drain')) {
      return Icons.battery_alert_rounded;
    }
    if (issue.contains('Charging') || issue.contains('USB-C')) {
      return Icons.power_rounded;
    }
    if (issue.contains('Water') || issue.contains('Liquid')) {
      return Icons.water_drop_rounded;
    }
    if (issue.contains('Camera') || issue.contains('Sensor')) {
      return Icons.camera_alt_rounded;
    }
    if (issue.contains('Speaker') || issue.contains('Audio')) {
      return Icons.volume_up_rounded;
    }
    if (issue.contains('Back Glass') || issue.contains('Chassis')) {
      return Icons.broken_image_rounded;
    }
    if (issue.contains('Motherboard') || issue.contains('Boot Loop')) {
      return Icons.memory_rounded;
    }
    return Icons.handyman_rounded;
  }

  void _showImageSourceModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Send Device Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Take a live photo with camera, upload from your gallery, or choose a damage preset.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Color(0xFF0066FF)),
                  ),
                  title: const Text(
                    'Take Photo with Camera',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  subtitle: const Text('Capture live picture of the phone damage'),
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.viewModel.attachDamagePhoto(
                        'CAMERA_CAPTURE_${DateTime.now().millisecondsSinceEpoch % 10000}.jpg');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Camera photo attached to repair ticket.'),
                        backgroundColor: Color(0xFF16A34A),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library_rounded,
                        color: Color(0xFF16A34A)),
                  ),
                  title: const Text(
                    'Choose from Gallery',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  subtitle: const Text('Select existing photo from phone gallery'),
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.viewModel.attachDamagePhoto(
                        'GALLERY_IMG_${DateTime.now().millisecondsSinceEpoch % 10000}.jpg');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Gallery photo attached to repair ticket.'),
                        backgroundColor: Color(0xFF16A34A),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                const Text(
                  'Or Select Damage Category Preset',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPresetChip(ctx, 'Screen Shattered Crack',
                        Icons.phone_android_rounded),
                    _buildPresetChip(ctx, 'Battery Bulging Fault',
                        Icons.battery_alert_rounded),
                    _buildPresetChip(ctx, 'Water Moisture Stain',
                        Icons.water_drop_rounded),
                    _buildPresetChip(ctx, 'Camera Lens Scratch',
                        Icons.camera_alt_rounded),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPresetChip(BuildContext ctx, String label, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 14, color: const Color(0xFF0066FF)),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F172A),
        ),
      ),
      backgroundColor: const Color(0xFFF1F5F9),
      side: const BorderSide(color: Color(0xFFE2E8F0)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onPressed: () {
        Navigator.pop(ctx);
        widget.viewModel.attachDamagePhoto('${label.replaceAll(' ', '_')}.jpg');
      },
    );
  }

  void _handleSubmit() {
    final text = _descriptionController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe what is actually wrong in the text box.'),
          backgroundColor: Color(0xFFE11D48),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    widget.viewModel.setDescription(text);
    widget.viewModel.bookAppointment();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        if (widget.viewModel.lastBooking != null) {
          return _buildSuccessView(context);
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: Color(0xFF0F172A)),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            title: const Text(
              'Express Repair Service',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // Hero Guarantee Banner
              _buildCertifiedBanner(),

              const SizedBox(height: 20),

              // Step 1: Select Problem to be Fixed
              _buildSectionTitle(
                number: '1',
                title: 'Select Problem to be Fixed',
                subtitle:
                    'Tap the primary issue you want our certified technicians to fix.',
              ),
              const SizedBox(height: 10),
              _buildIssueSelector(),

              const SizedBox(height: 24),

              // Step 2: Send a Picture of the Device
              _buildSectionTitle(
                number: '2',
                title: 'Send a Picture of the Device',
                subtitle:
                    'Attach a clear photo of the cracked screen or fault for fast inspection.',
              ),
              const SizedBox(height: 10),
              _buildPhotoUploadCard(),

              const SizedBox(height: 24),

              // Step 3: Large Text Box - What is Actually Wrong
              _buildSectionTitle(
                number: '3',
                title: 'What is Actually Wrong?',
                subtitle:
                    'Tell us details of the problem or symptoms you are experiencing.',
              ),
              const SizedBox(height: 10),
              _buildDescriptionInput(),

              const SizedBox(height: 24),

              // Step 4: Device Model & Drop-off Location
              _buildSectionTitle(
                number: '4',
                title: 'Device Model & Drop-off Branch',
                subtitle:
                    'Choose your device and your preferred Siaka Phones store.',
              ),
              const SizedBox(height: 10),
              _buildDeviceAndBranchCard(),

              const SizedBox(height: 24),

              // Step 5: Cost Estimate & Submit Button
              _buildEstimateAndSubmitCard(),

              const SizedBox(height: 28),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle({
    required String number,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFF0066FF),
                shape: BoxShape.circle,
              ),
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCertifiedBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: Color(0xFFD97706),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Official Certified Technicians',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Genuine OEM parts, express same-day fixes & 90-day official repair warranty.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueSelector() {
    final issues = widget.viewModel.issuePricing.entries.toList();

    return Column(
      children: issues.map((entry) {
        final isSelected = widget.viewModel.selectedIssue == entry.key;
        final icon = _getIssueIcon(entry.key);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => widget.viewModel.setSelectedIssue(entry.key),
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF0F6FF) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0066FF)
                      : const Color(0xFFE2E8F0),
                  width: isSelected ? 1.8 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF0066FF).withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF0066FF)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF0066FF)
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Estimated from ₵${entry.value.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF0284C7)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? const Color(0xFF0066FF)
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF0066FF)
                            : const Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPhotoUploadCard() {
    final photoPath = widget.viewModel.photoPath;

    if (photoPath != null && photoPath.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF22C55E), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF22C55E).withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Thumbnail preview
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 64,
                    height: 64,
                    color: const Color(0xFFF1F5F9),
                    child: _buildPhotoWidget(photoPath),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    size: 13, color: Color(0xFF16A34A)),
                                SizedBox(width: 4),
                                Text(
                                  'Photo Attached',
                                  style: TextStyle(
                                    color: Color(0xFF16A34A),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        photoPath.split(Platform.pathSeparator).last,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Ready to submit with diagnostic request',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remove Photo',
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Color(0xFFEF4444)),
                  onPressed: () => widget.viewModel.removePhoto(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF0066FF)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size(double.infinity, 38),
              ),
              icon: const Icon(Icons.sync_rounded,
                  size: 16, color: Color(0xFF0066FF)),
              label: const Text(
                'Change / Retake Photo',
                style: TextStyle(
                  color: Color(0xFF0066FF),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              onPressed: () => _showImageSourceModal(context),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_a_photo_rounded,
              color: Color(0xFF0066FF),
              size: 28,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Add a photo of what needs fixing',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Helps technicians inspect damage and prepare parts in advance',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.camera_alt_rounded, size: 16),
                  label: const Text(
                    'Take Photo',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _showImageSourceModal(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.photo_library_rounded,
                      size: 16, color: Color(0xFF475569)),
                  label: const Text(
                    'From Gallery',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _showImageSourceModal(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoWidget(String path) {
    if (!kIsWeb) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.phone_android_rounded,
                size: 28, color: Color(0xFF0066FF)),
          ),
        );
      }
    }
    return Container(
      color: const Color(0xFFEFF6FF),
      child: const Center(
        child: Icon(Icons.phone_android_rounded,
            size: 28, color: Color(0xFF0066FF)),
      ),
    );
  }

  Widget _buildDescriptionInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _descriptionController,
        maxLines: 5,
        minLines: 4,
        onChanged: (val) => widget.viewModel.setDescription(val),
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 14,
          height: 1.4,
        ),
        decoration: InputDecoration(
          hintText:
              'Describe what is actually wrong with the device...\nFor example:\n• Dropped on concrete, screen cracked and touch not working on bottom\n• Phone turns off suddenly at 30% battery\n• Water spilled near charging port, won\'t charge',
          hintStyle: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12.5,
            height: 1.4,
          ),
          contentPadding: const EdgeInsets.all(16),
          border: InputBorder.none,
          suffixIcon: _descriptionController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      size: 18, color: Color(0xFF94A3B8)),
                  onPressed: () {
                    _descriptionController.clear();
                    widget.viewModel.setDescription('');
                    setState(() {});
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildDeviceAndBranchCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
          const Text(
            'Device Model',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: widget.viewModel.deviceModel,
                isExpanded: true,
                style:
                    const TextStyle(color: Color(0xFF0F172A), fontSize: 13.5),
                items: [
                  'Siaka Quantum Titan 16 Pro',
                  'Siaka Apex Fold V3',
                  'Siaka Nova Lite 5G',
                  'Siaka Pulse Cyberwatch Ultra',
                  'Apple iPhone (All Models)',
                  'Samsung Galaxy (All Models)',
                  'Google Pixel / Android Other',
                ]
                    .map((model) =>
                        DropdownMenuItem(value: model, child: Text(model)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) widget.viewModel.setDeviceModel(val);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select Drop-off Store Branch',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: widget.viewModel.selectedBranch,
                isExpanded: true,
                style:
                    const TextStyle(color: Color(0xFF0F172A), fontSize: 13.5),
                items: [
                  'Siaka Phones Circle',
                  'Siaka Phones Madina',
                  'Siaka Phones Kasoa',
                ]
                    .map((branch) => DropdownMenuItem(
                          value: branch,
                          child: Row(
                            children: [
                              const Icon(Icons.storefront_rounded,
                                  size: 18, color: Color(0xFF0066FF)),
                              const SizedBox(width: 8),
                              Text(branch,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) widget.viewModel.setSelectedBranch(val);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Preferred Time Window',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: widget.viewModel.timeSlot,
                isExpanded: true,
                style:
                    const TextStyle(color: Color(0xFF0F172A), fontSize: 13.5),
                items: [
                  '09:00 AM - 11:00 AM',
                  '10:00 AM - 12:00 PM',
                  '01:00 PM - 03:00 PM',
                  '03:00 PM - 05:00 PM',
                  '05:00 PM - 07:00 PM',
                ]
                    .map((slot) =>
                        DropdownMenuItem(value: slot, child: Text(slot)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) widget.viewModel.setTimeSlot(val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimateAndSubmitCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimated Starting Cost',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 13, color: Color(0xFF16A34A)),
                      SizedBox(width: 4),
                      Text(
                        'Includes OEM Parts & Diagnostic',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF16A34A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                '₵${widget.viewModel.estimatedCost.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed:
                  widget.viewModel.isSubmitting ? null : _handleSubmit,
              child: widget.viewModel.isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Submit Repair Request',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    final booking = widget.viewModel.lastBooking!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Repair Request Confirmation',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF16A34A),
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Repair Request Submitted!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Ticket ID: ${booking.id}',
                  style: const TextStyle(
                    color: Color(0xFF0066FF),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Booking Details Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Device Model', booking.deviceModel),
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  _buildSummaryRow('Problem to Fix', booking.issueType),
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  _buildSummaryRow(
                      'Drop-off Store', booking.dropOffBranch ?? 'Siaka Phones Circle'),
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  _buildSummaryRow('Time Window', booking.timeSlot),
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  _buildSummaryRow('Starting Estimate',
                      '₵${booking.estimatedCost.toStringAsFixed(2)}'),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // What was actually wrong (User's input description)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notes_rounded,
                          size: 18, color: Color(0xFF0066FF)),
                      SizedBox(width: 8),
                      Text(
                        'Reported Fault Details',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    booking.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF334155),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Attached Photo if available
            if (booking.photoPath != null && booking.photoPath!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.photo_rounded,
                            size: 18, color: Color(0xFF16A34A)),
                        SizedBox(width: 8),
                        Text(
                          'Attached Damage Photo',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        color: const Color(0xFFF1F5F9),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: const Color(0xFFE2E8F0)),
                              ),
                              child: const Icon(Icons.phone_android_rounded,
                                  size: 28, color: Color(0xFF0066FF)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    booking.photoPath!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Verified attachment for diagnostic inspection',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => widget.viewModel.resetBookingState(),
                child: const Text(
                  'Done / Back to Repairs',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12.5,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    );
  }
}
