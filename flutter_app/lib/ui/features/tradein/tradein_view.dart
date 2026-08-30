import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/neon_button.dart';
import 'tradein_view_model.dart';

class TradeInView extends StatelessWidget {
  final TradeInViewModel viewModel;
  final VoidCallback onApplyToPurchase;

  const TradeInView({
    super.key,
    required this.viewModel,
    required this.onApplyToPurchase,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Trade-In & Upgrade'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Value Estimator Box
              GlassContainer(
                padding: const EdgeInsets.all(20),
                borderColor: AppColors.cyan,
                child: Column(
                  children: [
                    const Text('INSTANT ESTIMATED VALUE', style: TextStyle(color: AppColors.cyan, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      '\$${viewModel.estimatedQuote.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'for ${viewModel.brand} ${viewModel.model} (${viewModel.storage})',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Brand Selector
              const Text('1. Brand', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Apple', 'Samsung', 'Google', 'Siaka', 'Other'].map((b) {
                  final isSel = viewModel.brand == b;
                  return ChoiceChip(
                    label: Text(b, style: TextStyle(color: isSel ? Colors.black : Colors.white, fontSize: 12)),
                    selected: isSel,
                    selectedColor: AppColors.cyan,
                    backgroundColor: AppColors.surfaceElevated,
                    onSelected: (_) => viewModel.setBrand(b),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Model Selector
              const Text('2. Model', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: viewModel.model,
                    dropdownColor: AppColors.surfaceElevated,
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    items: [
                      'iPhone 15 Pro Max',
                      'iPhone 15 Pro',
                      'iPhone 14 Pro',
                      'Samsung Galaxy S24 Ultra',
                      'Samsung Galaxy Z Fold 5',
                      'Google Pixel 8 Pro',
                    ].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (val) {
                      if (val != null) viewModel.setModel(val);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Storage Selector
              const Text('3. Storage', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['128 GB', '256 GB', '512 GB', '1 TB'].map((s) {
                  final isSel = viewModel.storage == s;
                  return ChoiceChip(
                    label: Text(s, style: TextStyle(color: isSel ? Colors.black : Colors.white, fontSize: 12)),
                    selected: isSel,
                    selectedColor: AppColors.cyan,
                    backgroundColor: AppColors.surfaceElevated,
                    onSelected: (_) => viewModel.setStorage(s),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Cosmetic Condition
              const Text('4. Cosmetic Condition', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Flawless', 'Good', 'Fair', 'Broken'].map((c) {
                  final isSel = viewModel.condition == c;
                  return ChoiceChip(
                    label: Text(c, style: TextStyle(color: isSel ? Colors.black : Colors.white, fontSize: 12)),
                    selected: isSel,
                    selectedColor: AppColors.cyan,
                    backgroundColor: AppColors.surfaceElevated,
                    onSelected: (_) => viewModel.setCondition(c),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Functional Checkboxes
              GlassContainer(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Device powers on & stays on', style: TextStyle(color: Colors.white, fontSize: 13)),
                      value: viewModel.turnsOn,
                      activeColor: AppColors.cyan,
                      onChanged: (v) => viewModel.setTurnsOn(v),
                    ),
                    const Divider(color: AppColors.borderLight, height: 1),
                    SwitchListTile(
                      title: const Text('Screen is intact (no dead pixels/burn-in)', style: TextStyle(color: Colors.white, fontSize: 13)),
                      value: viewModel.screenIntact,
                      activeColor: AppColors.cyan,
                      onChanged: (v) => viewModel.setScreenIntact(v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              NeonButton(
                label: 'Apply \$${viewModel.estimatedQuote.toStringAsFixed(0)} Credit at Checkout',
                icon: Icons.check_circle_outline,
                onPressed: () {
                  viewModel.lockQuote();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Trade-in credit of \$${viewModel.estimatedQuote.toStringAsFixed(0)} locked for 14 days!')),
                  );
                  onApplyToPurchase();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
