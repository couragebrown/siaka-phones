import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/manager_repository.dart';
import '../../../domain/models/manager_product.dart';

class InventoryView extends StatefulWidget {
  final ManagerRepository repository;

  const InventoryView({super.key, required this.repository});

  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _onlyLowStock = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalTableScrollController = ScrollController();
  final ScrollController _outerScrollController = ScrollController();

  List<String> get _categories {
    final list = <String>['All'];
    for (final c in widget.repository.categories) {
      final upper = c.trim().toUpperCase();
      if (upper == 'ORDER_RECORD' ||
          upper == 'BNPL_RECORD' ||
          upper == 'REPAIR_RECORD' ||
          upper == 'SWAP_RECORD' ||
          upper == 'CATEGORY' ||
          upper.startsWith('ORDER_') ||
          upper.startsWith('BNPL_') ||
          upper.startsWith('REPAIR_')) {
        continue;
      }
      if (!list.contains(c)) list.add(c);
    }
    return list;
  }

  Map<String, List<String>> get _brandModels => widget.repository.brandModels;


  static const List<String> _storageOptions = [
    '64GB',
    '128GB',
    '256GB',
    '512GB',
    '1TB',
    '2TB',
  ];

  static const List<String> _ramOptions = [
    '3GB',
    '4GB',
    '6GB',
    '8GB',
    '12GB',
    '16GB',
    '24GB',
    '32GB',
  ];

  static const List<Map<String, dynamic>> _colorPresets = [
    {'name': 'Natural Titanium', 'color': Color(0xFF9E9A93), 'border': Color(0xFF7E7A73)},
    {'name': 'Space Black', 'color': Color(0xFF1E2022), 'border': Color(0xFF0F1011)},
    {'name': 'Titanium Gray', 'color': Color(0xFF6E7175), 'border': Color(0xFF4E5155)},
    {'name': 'Silver / White', 'color': Color(0xFFF1F3F5), 'border': Color(0xFFCBD5E1)},
    {'name': 'Desert Titanium / Gold', 'color': Color(0xFFDFCBB5), 'border': Color(0xFFBFA78D)},
    {'name': 'Deep Purple', 'color': Color(0xFF5E4B66), 'border': Color(0xFF3F3045)},
    {'name': 'Sierra Blue', 'color': Color(0xFF6D8FA3), 'border': Color(0xFF4C6D80)},
    {'name': 'Midnight Blue', 'color': Color(0xFF1E2D4A), 'border': Color(0xFF131D31)},
    {'name': 'Emerald Green', 'color': Color(0xFF2E6347), 'border': Color(0xFF1C422E)},
    {'name': 'Rose Gold / Pink', 'color': Color(0xFFE8B4B8), 'border': Color(0xFFC79196)},
    {'name': 'Obsidian Black', 'color': Color(0xFF252627), 'border': Color(0xFF121314)},
    {'name': 'Amber Yellow', 'color': Color(0xFFE5A93C), 'border': Color(0xFFC48618)},
  ];

  static Color _getColorValue(String colorName) {
    for (final preset in _colorPresets) {
      if (preset['name'] == colorName) return preset['color'] as Color;
    }
    final lower = colorName.toLowerCase();
    if (lower.contains('black') || lower.contains('dark') || lower.contains('midnight')) return const Color(0xFF1E2022);
    if (lower.contains('gray') || lower.contains('grey') || lower.contains('graphite')) return const Color(0xFF6E7175);
    if (lower.contains('white') || lower.contains('silver') || lower.contains('snow')) return const Color(0xFFE2E8F0);
    if (lower.contains('gold') || lower.contains('desert') || lower.contains('champagne')) return const Color(0xFFDFCBB5);
    if (lower.contains('blue') || lower.contains('sierra') || lower.contains('pacific') || lower.contains('ocean')) return const Color(0xFF3B82F6);
    if (lower.contains('green') || lower.contains('emerald') || lower.contains('forest') || lower.contains('alpine')) return const Color(0xFF10B981);
    if (lower.contains('purple') || lower.contains('violet') || lower.contains('lavender')) return const Color(0xFF8B5CF6);
    if (lower.contains('pink') || lower.contains('rose')) return const Color(0xFFEC4899);
    if (lower.contains('yellow') || lower.contains('amber')) return const Color(0xFFF59E0B);
    if (lower.contains('red') || lower.contains('coral')) return const Color(0xFFEF4444);
    if (lower.contains('titanium')) return const Color(0xFF9E9A93);
    return const Color(0xFF64748B);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    _verticalTableScrollController.dispose();
    _outerScrollController.dispose();
    super.dispose();
  }

  List<ManagerProduct> _getFilteredProducts() {
    final list = widget.repository.products.where((product) {
      if (!product.isMerchandise) {
        return false;
      }
      if (_onlyLowStock && !product.lowStock && product.stock > 0) {
        return false;
      }
      if (_selectedCategory != 'All') {
        final matchesCat = product.category.toLowerCase() == _selectedCategory.toLowerCase() ||
            (_selectedCategory == 'Smartphones' && product.category.toLowerCase() == 'phones');
        if (!matchesCat) return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = product.name.toLowerCase().contains(query);
        final matchesBrand = product.brand.toLowerCase().contains(query);
        final matchesSpecs = product.specs.toLowerCase().contains(query);
        final matchesCategory = product.category.toLowerCase().contains(query);
        final matchesColor = product.color.toLowerCase().contains(query) ||
            product.colors.any((c) => c.toLowerCase().contains(query));
        return matchesName || matchesBrand || matchesSpecs || matchesCategory || matchesColor;
      }
      return true;
    }).toList();

    // Ensure newest products appear on the top of the list
    list.sort((a, b) {
      if (a.createdAt != null && b.createdAt != null) {
        return b.createdAt!.compareTo(a.createdAt!);
      }
      if (a.createdAt != null) return -1;
      if (b.createdAt != null) return 1;
      return b.id.compareTo(a.id);
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'GH₵ ', decimalDigits: 2);
    final filteredProducts = _getFilteredProducts();

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isCompact = screenWidth < 900;
        final isShortHeight = constraints.maxHeight < 680;

        final headerRow = Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Inventory & Catalog Control',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Real-time stock monitoring, wholesale & retail pricing, SKU additions for ${widget.repository.currentBranch}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showAddCategoryDialog(context),
                  icon: const Icon(Icons.category_outlined, size: 18),
                  label: const Text('Add Category'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showAddDeviceModelDialog(context),
                  icon: const Icon(Icons.phonelink_setup_rounded, size: 18),
                  label: const Text('Add Device Model'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditProductDialog(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add New Product'),
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
        );

        final metricCards = isCompact
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SizedBox(
                      width: 220,
                      child: _buildMiniMetric(
                        label: 'TOTAL CATALOG SKUS',
                        value: '${widget.repository.products.length}',
                        icon: Icons.inventory_2_outlined,
                        color: const Color(0xFF1C7BFF),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 220,
                      child: _buildMiniMetric(
                        label: 'LOW STOCK ALERTS',
                        value: '${widget.repository.lowStockProductsCount}',
                        icon: Icons.warning_amber_rounded,
                        color: const Color(0xFFD97706),
                        hasWarning: widget.repository.lowStockProductsCount > 0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 220,
                      child: _buildMiniMetric(
                        label: 'TOTAL UNITS IN STOCK',
                        value: '${widget.repository.products.fold(0, (acc, p) => acc + p.stock)}',
                        icon: Icons.check_circle_outline_rounded,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              )
            : Row(
                children: [
                  Expanded(
                    child: _buildMiniMetric(
                      label: 'TOTAL CATALOG SKUS',
                      value: '${widget.repository.products.length}',
                      icon: Icons.inventory_2_outlined,
                      color: const Color(0xFF1C7BFF),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMiniMetric(
                      label: 'LOW STOCK ALERTS',
                      value: '${widget.repository.lowStockProductsCount}',
                      icon: Icons.warning_amber_rounded,
                      color: const Color(0xFFD97706),
                      hasWarning: widget.repository.lowStockProductsCount > 0,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMiniMetric(
                      label: 'TOTAL UNITS IN STOCK',
                      value: '${widget.repository.products.fold(0, (acc, p) => acc + p.stock)}',
                      icon: Icons.check_circle_outline_rounded,
                      color: const Color(0xFF059669),
                    ),
                  ),
                ],
              );

        final filtersBar = Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Search Field
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search products by name, model, brand, or specifications...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF1C7BFF), width: 1.5),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Low Stock Toggle
                  FilterChip(
                    avatar: Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: _onlyLowStock ? const Color(0xFFD97706) : const Color(0xFF64748B),
                    ),
                    label: const Text('Low Stock Only (≤ 5)'),
                    selected: _onlyLowStock,
                    onSelected: (val) => setState(() => _onlyLowStock = val),
                    backgroundColor: const Color(0xFFF1F5F9),
                    selectedColor: const Color(0xFFFEF3C7),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: _onlyLowStock ? FontWeight.w700 : FontWeight.w500,
                      color: _onlyLowStock ? const Color(0xFFD97706) : const Color(0xFF475569),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    side: BorderSide(
                      color: _onlyLowStock ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Category Tabs
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCategory = cat);
                    },
                    backgroundColor: const Color(0xFFF1F5F9),
                    selectedColor: const Color(0xFF1C7BFF).withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? const Color(0xFF1C7BFF) : const Color(0xFF475569),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF1C7BFF) : const Color(0xFFE2E8F0),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );

        final tableCard = Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: filteredProducts.isEmpty
              ? Center(
                  child: widget.repository.isLoading
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Color(0xFF1C7BFF),
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Loading inventory catalog...',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 54, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              'No products match your criteria',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try clearing the filters or click "Add New Product" to expand the catalog.',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                )
              : LayoutBuilder(
                  builder: (context, tableConstraints) {
                    final availableWidth = tableConstraints.maxWidth;
                    final tableMinWidth = math.max(1280.0, availableWidth);
                    const baseContentWidth = 1180.0;
                    final columnSpacing = ((tableMinWidth - baseContentWidth - 48) / 7).clamp(20.0, 110.0);

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Scrollbar(
                        controller: _verticalTableScrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _verticalTableScrollController,
                          child: Scrollbar(
                            controller: _horizontalScrollController,
                            thumbVisibility: true,
                            trackVisibility: true,
                            notificationPredicate: (notif) => notif.metrics.axis == Axis.horizontal,
                            child: SingleChildScrollView(
                              controller: _horizontalScrollController,
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minWidth: tableMinWidth),
                              child: DataTable(
                                dataRowMinHeight: 64,
                                dataRowMaxHeight: 78,
                                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                                horizontalMargin: 24,
                                columnSpacing: columnSpacing,
                                columns: const [
                                  DataColumn(label: Text('PRODUCT & IMAGE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('BRAND', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('CATEGORY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('STORAGE, RAM & COLOR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('PRICING (WHOLESALE / RETAIL)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('STOCK LEVEL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('CONDITION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                  DataColumn(label: Text('ACTIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
                                ],
                                rows: filteredProducts.map((product) {
                                  return DataRow(
                                    cells: [
                                      // Product & Image
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Product Thumbnail Image / Icon
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                              ),
                                              clipBehavior: Clip.antiAlias,
                                              child: product.imageBytes != null
                                                  ? Image.memory(
                                                      product.imageBytes!,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) => _buildCategoryIcon(product.category),
                                                    )
                                                  : product.imageUrl.isNotEmpty
                                                      ? _buildProductThumbnail(product.imageUrl, product.category)
                                                      : _buildCategoryIcon(product.category),
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  product.name,
                                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                                                ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    if (product.isFeatured)
                                                      Container(
                                                        margin: const EdgeInsets.only(right: 6),
                                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFFEF3C7),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: const Text(
                                                          '★ FEATURED',
                                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                                                        ),
                                                      ),
                                                    if (product.specsList.isNotEmpty)
                                                      Text(
                                                        '${product.specsList.length} specs listed',
                                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Brand
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            product.brand,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF334155)),
                                          ),
                                        ),
                                      ),

                                      // Category
                                      DataCell(Text(product.category, style: const TextStyle(fontSize: 12, color: Color(0xFF475569)))),

                                      // Storage & RAM & Color
                                      DataCell(
                                        Tooltip(
                                          message: product.specsList.isNotEmpty ? product.specsList.map((s) => '• $s').join('\n') : product.specs,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFEFF6FF),
                                                  borderRadius: BorderRadius.circular(5),
                                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                                ),
                                                child: Text(
                                                  product.storage,
                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF3E8FF),
                                                  borderRadius: BorderRadius.circular(5),
                                                  border: Border.all(color: const Color(0xFFDDD6FE)),
                                                ),
                                                child: Text(
                                                  product.ram,
                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6D28D9)),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF8FAFC),
                                                  borderRadius: BorderRadius.circular(5),
                                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    ...() {
                                                      final displayColors = product.colors.isNotEmpty ? product.colors : [product.color];
                                                      return displayColors.take(3).map((c) => Padding(
                                                        padding: const EdgeInsets.only(right: 3),
                                                        child: Container(
                                                          width: 8,
                                                          height: 8,
                                                          decoration: BoxDecoration(
                                                            shape: BoxShape.circle,
                                                            color: _getColorValue(c),
                                                            border: Border.all(color: Colors.black26, width: 0.5),
                                                          ),
                                                        ),
                                                      ));
                                                    }(),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      product.colors.length > 1
                                                          ? '${product.colors.first} (+${product.colors.length - 1})'
                                                          : (product.colors.isNotEmpty ? product.colors.first : product.color),
                                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Wholesale & Retail Pricing
                                      DataCell(
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  currencyFormat.format(product.wholesalePrice),
                                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFDCFCE7),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text(
                                                    'WHOLESALE',
                                                    style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'MSRP: ${currencyFormat.format(product.retailPrice)}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF94A3B8),
                                                  ),
                                                ),
                                                if (product.retailPrice > product.wholesalePrice) ...[
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '(-${product.marginPercentage.toStringAsFixed(0)}%)',
                                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Stock Level
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: product.stock == 0
                                                    ? const Color(0xFFFEE2E2)
                                                    : product.lowStock
                                                        ? const Color(0xFFFEF3C7)
                                                        : const Color(0xFFD1FAE5),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    product.stock == 0
                                                        ? Icons.cancel_outlined
                                                        : product.lowStock
                                                            ? Icons.warning_amber_rounded
                                                            : Icons.check_circle_rounded,
                                                    size: 13,
                                                    color: product.stock == 0
                                                        ? const Color(0xFFDC2626)
                                                        : product.lowStock
                                                            ? const Color(0xFFD97706)
                                                            : const Color(0xFF059669),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${product.stock} units',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                      color: product.stock == 0
                                                          ? const Color(0xFFDC2626)
                                                          : product.lowStock
                                                              ? const Color(0xFFD97706)
                                                              : const Color(0xFF059669),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            // Quick decrement
                                            IconButton(
                                              icon: const Icon(Icons.remove_circle_outline, size: 16),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              tooltip: 'Decrement Stock',
                                              onPressed: product.stock > 0
                                                  ? () {
                                                      widget.repository.updateStock(product.id, product.stock - 1);
                                                      setState(() {});
                                                    }
                                                  : null,
                                            ),
                                            const SizedBox(width: 4),
                                            // Quick increment
                                            IconButton(
                                              icon: const Icon(Icons.add_circle_outline, size: 16, color: Color(0xFF1C7BFF)),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              tooltip: 'Increment Stock',
                                              onPressed: () {
                                                widget.repository.updateStock(product.id, product.stock + 1);
                                                setState(() {});
                                              },
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Condition
                                      DataCell(
                                        _buildConditionPill(product.condition),
                                      ),

                                      // Actions
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF475569)),
                                              tooltip: 'Edit Product',
                                              onPressed: () => _showAddEditProductDialog(context, product: product),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                                              tooltip: 'Delete Product',
                                              onPressed: () => _confirmDeleteProduct(context, product),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                  },
                ),
        );

        if (isShortHeight) {
          return Scrollbar(
            controller: _outerScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _outerScrollController,
              padding: EdgeInsets.all(isCompact ? 16.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  headerRow,
                  const SizedBox(height: 20),
                  metricCards,
                  const SizedBox(height: 20),
                  filtersBar,
                  const SizedBox(height: 16),
                  SizedBox(height: 520, child: tableCard),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.all(isCompact ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              headerRow,
              const SizedBox(height: 20),
              metricCards,
              const SizedBox(height: 20),
              filtersBar,
              const SizedBox(height: 16),
              Expanded(child: tableCard),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryIcon(String category) {
    return Icon(
      category == 'Laptops'
          ? Icons.laptop_mac_rounded
          : category == 'Smartwatches'
              ? Icons.watch_rounded
              : category == 'Tablets'
                  ? Icons.tablet_mac_rounded
                  : category == 'Accessories'
                      ? Icons.headphones_rounded
                      : Icons.phone_iphone_rounded,
      size: 20,
      color: const Color(0xFF475569),
    );
  }

  Widget _buildProductThumbnail(String imageUrl, String category) {
    final trimmed = imageUrl.trim();
    final fallback = _buildCategoryIcon(category);

    // 1. Base64 Data URI
    if (trimmed.startsWith('data:image')) {
      try {
        final commaIdx = trimmed.indexOf(',');
        final base64Str = commaIdx != -1 ? trimmed.substring(commaIdx + 1) : trimmed;
        final bytes = base64Decode(base64Str);
        return Image.memory(bytes, fit: BoxFit.cover, errorBuilder: (e, s, t) => fallback);
      } catch (_) {
        return fallback;
      }
    }

    // 2. Network URL
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Image.network(trimmed, fit: BoxFit.cover, errorBuilder: (e, s, t) => fallback);
    }

    // 3. Local file path
    try {
      final file = File(trimmed);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover, errorBuilder: (e, s, t) => fallback);
      }
    } catch (_) {}

    return fallback;
  }

  Widget _buildDialogImagePreview(String imageUrl) {
    const placeholder = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined, size: 30, color: Color(0xFF1C7BFF)),
          SizedBox(height: 4),
          Text('Click to Add', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF1C7BFF))),
        ],
      ),
    );

    if (imageUrl.isEmpty) return placeholder;

    // 1. Base64 Data URI
    if (imageUrl.startsWith('data:image')) {
      try {
        final commaIdx = imageUrl.indexOf(',');
        final base64Str = commaIdx != -1 ? imageUrl.substring(commaIdx + 1) : imageUrl;
        final bytes = base64Decode(base64Str);
        return Image.memory(bytes, fit: BoxFit.cover,
            errorBuilder: (e, s, t) => const Center(child: Icon(Icons.broken_image_outlined, size: 32, color: Color(0xFF94A3B8))));
      } catch (_) {
        return placeholder;
      }
    }

    // 2. Network URL
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(imageUrl, fit: BoxFit.cover,
          errorBuilder: (e, s, t) => const Center(child: Icon(Icons.broken_image_outlined, size: 32, color: Color(0xFF94A3B8))));
    }

    // 3. Local file path
    try {
      final file = File(imageUrl);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover,
            errorBuilder: (e, s, t) => const Center(child: Icon(Icons.broken_image_outlined, size: 32, color: Color(0xFF94A3B8))));
      }
    } catch (_) {}

    return placeholder;
  }

  Widget _buildMiniMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool hasWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasWarning ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
          width: hasWarning ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

  void _showAddCategoryDialog(BuildContext context, {void Function(String category)? onAdded}) {
    final catCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Row(
              children: [
                Icon(Icons.category_outlined, color: Color(0xFF1C7BFF)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Add New Category',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Categories help group your inventory and will immediately sync across to the Customer App catalog and navigation.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: catCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Category Name',
                      hintText: 'e.g. Drones, Earbuds, Smartwatches',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label_outline, size: 20),
                    ),
                    onSubmitted: (val) {
                      final name = val.trim();
                      if (name.isNotEmpty && !isSubmitting) {
                        setDialogState(() => isSubmitting = true);
                        widget.repository.addCategory(name);
                        setState(() {});
                        if (onAdded != null) onAdded(name);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Category "$name" created and synced with Customer App.'),
                            backgroundColor: const Color(0xFF059669),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Existing categories:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.repository.categories.map(
                      (c) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Text(c, style: const TextStyle(fontSize: 11, color: Color(0xFF334155))),
                      ),
                    ).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C7BFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Add Category'),
                onPressed: isSubmitting
                    ? null
                    : () {
                        final name = catCtrl.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid category name.'),
                              backgroundColor: Color(0xFFDC2626),
                            ),
                          );
                          return;
                        }
                        setDialogState(() => isSubmitting = true);
                        widget.repository.addCategory(name);
                        setState(() {});
                        if (onAdded != null) onAdded(name);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Category "$name" created and synced with Customer App.'),
                            backgroundColor: const Color(0xFF059669),
                          ),
                        );
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddDeviceModelDialog(BuildContext context, {void Function(String brand, String model)? onAdded}) {
    final modelNameCtrl = TextEditingController();

    // Available categories from repository
    final existingCategories = widget.repository.categories.toList();
    String selectedCategoryOption = existingCategories.isNotEmpty ? existingCategories.first : 'Smartphones';
    bool isNewCategory = false;
    final newCategoryCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Row(
              children: [
                Icon(Icons.phonelink_setup_rounded, color: Color(0xFF1C7BFF)),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Add Device Model', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 480,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Register a new device model and product category into the catalog so managers can select them when adding or updating products.',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 18),
                    // Model Name
                    TextField(
                      controller: modelNameCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Device Model Name *',
                        hintText: 'e.g. Galaxy S25 Ultra, iPhone 17 Pro, DJI Drone',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_android_rounded, size: 18),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Category Selection Header with Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Device Category *',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setDialogState(() {
                              isNewCategory = !isNewCategory;
                              if (isNewCategory) {
                                selectedCategoryOption = '__NEW_CATEGORY__';
                              } else {
                                selectedCategoryOption = existingCategories.isNotEmpty ? existingCategories.first : 'Smartphones';
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isNewCategory ? Icons.list_rounded : Icons.add_circle_outline_rounded,
                                  size: 15,
                                  color: const Color(0xFF1C7BFF),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isNewCategory ? 'Choose Existing' : '+ Add New Category',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1C7BFF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      key: ValueKey('category_dropdown_${isNewCategory ? "new" : selectedCategoryOption}'),
                      initialValue: isNewCategory ? '__NEW_CATEGORY__' : selectedCategoryOption,
                      selectedItemBuilder: (context) {
                        return [
                          ...existingCategories,
                          '__NEW_CATEGORY__',
                        ].map((c) => Text(c == '__NEW_CATEGORY__' ? '+ Enter New Category...' : c, overflow: TextOverflow.ellipsis, maxLines: 1)).toList();
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category_outlined, size: 18),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      items: [
                        ...existingCategories.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis, maxLines: 1))),
                        const DropdownMenuItem(value: '__NEW_CATEGORY__', child: Text('+ Enter New Category...', overflow: TextOverflow.ellipsis, maxLines: 1)),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedCategoryOption = val;
                            isNewCategory = val == '__NEW_CATEGORY__';
                          });
                        }
                      },
                    ),
                    if (isNewCategory) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: newCategoryCtrl,
                        decoration: const InputDecoration(
                          labelText: 'New Category Name *',
                          hintText: 'e.g. Drones, VR Headsets, Cameras, Audio',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.new_label_outlined, size: 18),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final model = modelNameCtrl.text.trim();
                  final category = isNewCategory ? newCategoryCtrl.text.trim() : selectedCategoryOption.trim();
                  if (model.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a device model name.')),
                    );
                    return;
                  }
                  if (category.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter or select a product category.')),
                    );
                    return;
                  }

                  widget.repository.addCategory(category);
                  widget.repository.addDeviceModel(modelName: model, category: category);
                  Navigator.of(ctx).pop();
                  onAdded?.call('Other / Custom', model);
                  setState(() {});

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF059669),
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Model "$model" under "$category" added successfully!')),
                        ],
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('Save Model'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C7BFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddEditProductDialog(BuildContext context, {ManagerProduct? product}) {
    final isEditing = product != null;

    // Detect initial brand and model
    String initialBrand = product?.brand ?? 'Apple';
    if (!_brandModels.containsKey(initialBrand)) {
      initialBrand = 'Apple';
    }

    String initialModel = product?.name ?? _brandModels[initialBrand]!.first;
    bool isCustomModel = false;
    if (!_brandModels[initialBrand]!.contains(initialModel)) {
      isCustomModel = true;
    }

    String selectedBrand = initialBrand;
    String selectedModel = isCustomModel ? 'Custom / Unlisted Model' : initialModel;
    final customModelCtrl = TextEditingController(text: isCustomModel ? (product?.name ?? '') : '');

    final categoryCtrl = TextEditingController(text: product?.category ?? 'Smartphones');
    final wholesalePriceCtrl = TextEditingController(text: product != null ? product.wholesalePrice.toStringAsFixed(0) : '');
    final retailPriceCtrl = TextEditingController(text: product != null ? product.retailPrice.toStringAsFixed(0) : '');
    final stockCtrl = TextEditingController(text: product != null ? product.stock.toString() : '10');
    final imageUrlCtrl = TextEditingController(text: product?.imageUrl ?? '');
    Uint8List? pickedImageBytes = product?.imageBytes;
    String? pickedImageName;
    int? pickedImageSize;

    String selectedStorage = product?.storage ?? '256GB';
    if (!_storageOptions.contains(selectedStorage)) {
      selectedStorage = '256GB';
    }

    String selectedRam = product?.ram ?? '8GB';
    if (!_ramOptions.contains(selectedRam)) {
      selectedRam = '8GB';
    }

    final List<String> selectedColors = [];
    if (product != null) {
      if (product.colors.isNotEmpty) {
        selectedColors.addAll(product.colors);
      } else if (product.color.isNotEmpty) {
        selectedColors.add(product.color);
      }
    }
    if (selectedColors.isEmpty) {
      selectedColors.add('Natural Titanium');
    }
    final customColorCtrl = TextEditingController();

    final rawCondition = product?.condition ?? 'New';
    final initialCondition = rawCondition == 'Brand New' ? 'New' : rawCondition;
    final conditionCtrl = TextEditingController(text: initialCondition);
    bool isFeatured = product?.isFeatured ?? true;

    // Dynamic Specifications List
    final List<String> specsList = List<String>.from(product?.specsList ?? []);
    final TextEditingController newSpecCtrl = TextEditingController();
    final FocusNode specFocusNode = FocusNode();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          // Helper to pick image from PC file system
          Future<void> pickImageFile() async {
            try {
              final file = await FilePicker.pickFile(
                type: FileType.custom,
                allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
              );
              if (file != null) {
                final bytes = await file.xFile.readAsBytes();
                final length = await file.xFile.length();
                setDialogState(() {
                  pickedImageBytes = bytes;
                  pickedImageName = file.name;
                  pickedImageSize = length;
                  if (file.path != null && file.path!.isNotEmpty) {
                    imageUrlCtrl.text = file.path!;
                  } else {
                    imageUrlCtrl.text = file.name;
                  }
                });
              }
            } catch (e) {
              debugPrint('Error picking product image file: $e');
            }
          }

          // Helper to add specification
          void addSpecItem() {
            final text = newSpecCtrl.text.trim();
            if (text.isNotEmpty) {
              setDialogState(() {
                specsList.add(text);
                newSpecCtrl.clear();
              });
              specFocusNode.requestFocus();
            }
          }

          // Calculate margin preview
          final wholesaleVal = double.tryParse(wholesalePriceCtrl.text) ?? 0.0;
          final retailVal = double.tryParse(retailPriceCtrl.text) ?? 0.0;
          final hasMargin = retailVal > wholesaleVal && wholesaleVal > 0;
          final marginDiff = retailVal - wholesaleVal;
          final marginPct = retailVal > 0 ? (marginDiff / retailVal * 100).toStringAsFixed(1) : '0';

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Container(
              width: 760,
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.94,
                maxHeight: MediaQuery.of(context).size.height * 0.92,
              ),
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Bar
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C7BFF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isEditing ? Icons.edit_note_rounded : Icons.add_business_rounded,
                          color: const Color(0xFF1C7BFF),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isEditing ? 'Edit Product Catalog Item' : 'Add New Inventory SKU',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Configure model, pricing tiers, hardware specifications, and product assets',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: Color(0xFFE2E8F0)),

                  // Scrollable Body
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // -------------------------------------------------------------
                          // SECTION 1: PRODUCT IMAGE & DIMENSIONS
                          // -------------------------------------------------------------
                          const Text(
                            '1. PRODUCT IMAGE & MEDIA',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF475569), letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 10),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image Preview Box (Clickable to trigger open file dialog)
                              Tooltip(
                                message: 'Click to open file dialog and select an image from your computer',
                                child: InkWell(
                                  onTap: pickImageFile,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    width: 104,
                                    height: 104,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: pickedImageBytes != null
                                            ? const Color(0xFF1C7BFF)
                                            : const Color(0xFFCBD5E1),
                                        width: pickedImageBytes != null ? 2.0 : 1.5,
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: pickedImageBytes != null
                                              ? Image.memory(
                                                  pickedImageBytes!,
                                                  fit: BoxFit.cover,
                                                )
                                              : _buildDialogImagePreview(imageUrlCtrl.text.trim()),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            color: Colors.black.withValues(alpha: 0.65),
                                            padding: const EdgeInsets.symmetric(vertical: 2.5),
                                            child: Text(
                                              pickedImageBytes != null ? 'Change File' : 'Browse File',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 16),

                              // File Dialog Trigger & Image Inputs
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Wrap with "Open File" button and Selected File indicator
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 8,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: pickImageFile,
                                          icon: const Icon(Icons.folder_open_rounded, size: 18),
                                          label: const Text('Open File / Choose Image (PC)'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF0F172A),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            elevation: 0,
                                          ),
                                        ),
                                        if (pickedImageBytes != null)
                                          Container(
                                            constraints: const BoxConstraints(maxWidth: 320),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFECFDF5),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFFA7F3D0)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF059669)),
                                                const SizedBox(width: 6),
                                                Flexible(
                                                  child: Text(
                                                    '${pickedImageName ?? "File selected"} (${((pickedImageSize ?? pickedImageBytes!.length) / 1024).toStringAsFixed(0)} KB)',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF047857)),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                InkWell(
                                                  onTap: () {
                                                    setDialogState(() {
                                                      pickedImageBytes = null;
                                                      pickedImageName = null;
                                                      pickedImageSize = null;
                                                      imageUrlCtrl.clear();
                                                    });
                                                  },
                                                  child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF059669)),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),

                                    const SizedBox(height: 10),

                                    // Alternative Image Link / Asset input
                                    TextField(
                                      controller: imageUrlCtrl,
                                      onChanged: (text) => setDialogState(() {}),
                                      decoration: InputDecoration(
                                        labelText: 'Product Image Asset / Web Link (Optional)',
                                        hintText: 'Selected local file path or direct URL (e.g. https://...)',
                                        prefixIcon: const Icon(Icons.link_rounded, size: 18),
                                        suffixIcon: imageUrlCtrl.text.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.clear, size: 16),
                                                onPressed: () {
                                                  setDialogState(() {
                                                    imageUrlCtrl.clear();
                                                    pickedImageBytes = null;
                                                    pickedImageName = null;
                                                  });
                                                },
                                              )
                                            : null,
                                        border: const OutlineInputBorder(),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    // REQUIRED SIZE WRITTEN UNDER IT
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFBFDBFE)),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.aspect_ratio_rounded, size: 16, color: Color(0xFF1D4ED8)),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Required Image Size: 800 × 800 px (1:1 Square Aspect Ratio) • Maximum File Size: 2 MB • Supported Formats: JPG, PNG, WebP',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1E40AF),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 22),

                          // -------------------------------------------------------------
                          // SECTION 2: BRAND & MODEL SELECTION FROM LIST
                          // -------------------------------------------------------------
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  '2. DEVICE BRAND & MODEL SELECTION',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF475569), letterSpacing: 0.5),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _showAddDeviceModelDialog(context, onAdded: (newBrand, newModel) {
                                  setDialogState(() {
                                    selectedBrand = newBrand;
                                    selectedModel = newModel;
                                    isCustomModel = false;
                                    customModelCtrl.text = newModel;
                                  });
                                }),
                                icon: const Icon(Icons.add_circle_outline_rounded, size: 15),
                                label: const Text('+ Add New Model', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              // Brand Selection
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: selectedBrand,
                                  decoration: const InputDecoration(
                                    labelText: 'Brand *',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.branding_watermark_outlined, size: 18),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                  items: _brandModels.keys
                                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                                      .toList(),
                                  onChanged: (newBrand) {
                                    if (newBrand != null) {
                                      setDialogState(() {
                                        selectedBrand = newBrand;
                                        final availableModels = _brandModels[newBrand] ?? ['Custom / Unlisted Model'];
                                        selectedModel = availableModels.first;
                                        if (selectedModel == 'Custom / Unlisted Model') {
                                          isCustomModel = true;
                                        } else {
                                          isCustomModel = false;
                                          customModelCtrl.text = selectedModel;
                                        }
                                      });
                                    }
                                  },
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Model Selection Dropdown
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: (_brandModels[selectedBrand]?.contains(selectedModel) ?? false)
                                      ? selectedModel
                                      : 'Custom / Unlisted Model',
                                  decoration: const InputDecoration(
                                    labelText: 'Select Model From List *',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.phone_android_rounded, size: 18),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                  items: [
                                    ...?_brandModels[selectedBrand]?.map((m) => DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis))),
                                    if (!(_brandModels[selectedBrand]?.contains('Custom / Unlisted Model') ?? false))
                                      const DropdownMenuItem(value: 'Custom / Unlisted Model', child: Text('Custom / Unlisted Model...')),
                                  ],
                                  onChanged: (newModel) {
                                    if (newModel != null) {
                                      setDialogState(() {
                                        selectedModel = newModel;
                                        if (newModel == 'Custom / Unlisted Model') {
                                          isCustomModel = true;
                                        } else {
                                          isCustomModel = false;
                                          customModelCtrl.text = newModel;
                                        }
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),

                          // Custom Model Field if chosen
                          if (isCustomModel) ...[
                            const SizedBox(height: 10),
                            TextField(
                              controller: customModelCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Enter Custom Device Model Name *',
                                hintText: 'e.g. iPhone 16 Pro Max 1TB Limited Edition',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.edit_note_rounded, size: 18),
                              ),
                            ),
                          ],

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              // Category
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        initialValue: widget.repository.categories.contains(categoryCtrl.text)
                                            ? categoryCtrl.text
                                            : widget.repository.categories.first,
                                        decoration: const InputDecoration(
                                          labelText: 'Category',
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        ),
                                        items: widget.repository.categories
                                            .map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis)))
                                            .toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setDialogState(() {
                                              categoryCtrl.text = val;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      tooltip: 'Add New Category',
                                      icon: const Icon(Icons.add_circle_outline, color: Color(0xFF1C7BFF)),
                                      onPressed: () {
                                        _showAddCategoryDialog(context, onAdded: (newCat) {
                                          setDialogState(() {
                                            categoryCtrl.text = newCat;
                                          });
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Condition
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: conditionCtrl.text,
                                  decoration: const InputDecoration(
                                    labelText: 'Condition',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                  items: ['New', 'UK Used', 'Refurbished', 'Open Box']
                                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) conditionCtrl.text = val;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Stock Units
                              Expanded(
                                child: TextField(
                                  controller: stockCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Stock Units *',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    suffixText: 'pcs',
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 22),

                          // -------------------------------------------------------------
                          // SECTION 3: PRICING (WHOLESALE SELLING & RETAIL MSRP)
                          // -------------------------------------------------------------
                          const Text(
                            '3. PRICING STRUCTURE (WHOLESALE & RETAIL)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF475569), letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 10),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Wholesale Selling Price
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextField(
                                      controller: wholesalePriceCtrl,
                                      keyboardType: TextInputType.number,
                                      onChanged: (text) => setDialogState(() {}),
                                      decoration: const InputDecoration(
                                        labelText: 'Wholesale Selling Price (GH₵) *',
                                        hintText: 'e.g. 16500',
                                        prefixText: 'GH₵ ',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Active shop selling rate paid by customer/wholesaler',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 14),

                              // Retail Price (MSRP)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextField(
                                      controller: retailPriceCtrl,
                                      keyboardType: TextInputType.number,
                                      onChanged: (text) => setDialogState(() {}),
                                      decoration: const InputDecoration(
                                        labelText: 'Retail Price / MSRP (GH₵) *',
                                        hintText: 'e.g. 17500',
                                        prefixText: 'GH₵ ',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Official manufacturer suggested retail reference price',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Live Margin & Savings Indicator
                          if (hasMargin) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFBBF7D0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.trending_down_rounded, size: 16, color: Color(0xFF15803D)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Wholesale Discount: GH₵ ${marginDiff.toStringAsFixed(2)} ($marginPct% savings below official Retail MSRP)',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF166534)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 22),

                          // -------------------------------------------------------------
                          // SECTION 4: STORAGE & RAM SELECTION FROM LIST
                          // -------------------------------------------------------------
                          const Text(
                            '4. HARDWARE MEMORY & STORAGE (SELECT FROM LIST)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF475569), letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 10),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Storage Selector
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Internal Storage Capacity:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: _storageOptions.map((st) {
                                        final isSel = selectedStorage == st;
                                        return ChoiceChip(
                                          label: Text(st),
                                          selected: isSel,
                                          onSelected: (val) {
                                            if (val) setDialogState(() => selectedStorage = st);
                                          },
                                          selectedColor: const Color(0xFF1C7BFF),
                                          labelStyle: TextStyle(
                                            color: isSel ? Colors.white : const Color(0xFF1E293B),
                                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                          backgroundColor: const Color(0xFFF1F5F9),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 16),

                              // RAM Selector
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('System RAM Memory:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: _ramOptions.map((rm) {
                                        final isSel = selectedRam == rm;
                                        return ChoiceChip(
                                          label: Text(rm),
                                          selected: isSel,
                                          onSelected: (val) {
                                            if (val) setDialogState(() => selectedRam = rm);
                                          },
                                          selectedColor: const Color(0xFF7C3AED),
                                          labelStyle: TextStyle(
                                            color: isSel ? Colors.white : const Color(0xFF1E293B),
                                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                          backgroundColor: const Color(0xFFF1F5F9),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 22),

                          // -------------------------------------------------------------
                          // SECTION 5: PRODUCT COLOR FINISHES (SELECT 1 OR MORE COLOURS)
                          // -------------------------------------------------------------
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '5. PRODUCT COLOR FINISHES (SELECT 1 OR MORE COLOURS)',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF475569), letterSpacing: 0.5),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Assign one or multiple color variants for this SKU. Customers can choose between these finishes.',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: selectedColors.isNotEmpty ? const Color(0xFFEFF6FF) : const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: selectedColors.isNotEmpty ? const Color(0xFFBFDBFE) : const Color(0xFFFECACA),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      selectedColors.isNotEmpty ? Icons.palette_rounded : Icons.warning_amber_rounded,
                                      size: 15,
                                      color: selectedColors.isNotEmpty ? const Color(0xFF1C7BFF) : const Color(0xFFDC2626),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      selectedColors.isNotEmpty
                                          ? '${selectedColors.length} Color${selectedColors.length > 1 ? "s" : ""} Selected'
                                          : 'At least 1 color required *',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: selectedColors.isNotEmpty ? const Color(0xFF1E40AF) : const Color(0xFFDC2626),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Active Selected Colors Box
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: selectedColors.isNotEmpty ? const Color(0xFFF8FAFC) : const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selectedColors.isNotEmpty ? const Color(0xFFE2E8F0) : const Color(0xFFFED7AA),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline_rounded,
                                      size: 15,
                                      color: selectedColors.isNotEmpty ? const Color(0xFF059669) : const Color(0xFFEA580C),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      selectedColors.isNotEmpty
                                          ? 'Active Colors Assigned to this SKU (${selectedColors.length}):'
                                          : 'No colors selected yet! Please choose or add colors below:',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: selectedColors.isNotEmpty ? const Color(0xFF334155) : const Color(0xFFC2410C),
                                      ),
                                    ),
                                    const Spacer(),
                                    if (selectedColors.length > 1)
                                      TextButton(
                                        onPressed: () {
                                          setDialogState(() {
                                            selectedColors.clear();
                                          });
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text('Clear All', style: TextStyle(fontSize: 11, color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
                                      ),
                                  ],
                                ),
                                if (selectedColors.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: selectedColors.map((colorName) {
                                      final isPrimary = selectedColors.first == colorName;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isPrimary ? const Color(0xFF1C7BFF) : const Color(0xFFCBD5E1),
                                            width: isPrimary ? 1.5 : 1.0,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.04),
                                              blurRadius: 3,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 13,
                                              height: 13,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: _getColorValue(colorName),
                                                border: Border.all(color: Colors.black26, width: 0.8),
                                              ),
                                            ),
                                            const SizedBox(width: 7),
                                            Text(
                                              colorName,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: isPrimary ? FontWeight.w800 : FontWeight.w600,
                                                color: isPrimary ? const Color(0xFF1D4ED8) : const Color(0xFF1E293B),
                                              ),
                                            ),
                                            if (isPrimary && selectedColors.length > 1) ...[
                                              const SizedBox(width: 5),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFEFF6FF),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text('Primary', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8))),
                                              ),
                                            ],
                                            const SizedBox(width: 6),
                                            InkWell(
                                              onTap: () {
                                                setDialogState(() {
                                                  selectedColors.remove(colorName);
                                                });
                                              },
                                              borderRadius: BorderRadius.circular(10),
                                              child: const Padding(
                                                padding: EdgeInsets.all(2.0),
                                                child: Icon(Icons.close_rounded, size: 14, color: Color(0xFF94A3B8)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Preset Colors List Header
                          const Text(
                            'Quick Pick Preset Colors (Click to add or remove):',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                          ),
                          const SizedBox(height: 8),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _colorPresets.map((cp) {
                              final colorName = cp['name'] as String;
                              final swatchColor = cp['color'] as Color;
                              final isSel = selectedColors.contains(colorName);
                              return InkWell(
                                onTap: () {
                                  setDialogState(() {
                                    if (isSel) {
                                      selectedColors.remove(colorName);
                                    } else {
                                      selectedColors.add(colorName);
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: isSel ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSel ? const Color(0xFF1C7BFF) : const Color(0xFFE2E8F0),
                                      width: isSel ? 1.8 : 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: swatchColor,
                                          border: Border.all(color: (cp['border'] as Color?) ?? Colors.black26, width: 1),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.08),
                                              blurRadius: 2,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 7),
                                      Text(
                                        colorName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                          color: isSel ? const Color(0xFF1D4ED8) : const Color(0xFF334155),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        isSel ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                                        size: 14,
                                        color: isSel ? const Color(0xFF1C7BFF) : const Color(0xFF94A3B8),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 12),

                          // Add Custom Color Input
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: customColorCtrl,
                                  onSubmitted: (text) {
                                    final customName = text.trim();
                                    if (customName.isNotEmpty) {
                                      if (!selectedColors.any((c) => c.toLowerCase() == customName.toLowerCase())) {
                                        setDialogState(() {
                                          selectedColors.add(customName);
                                          customColorCtrl.clear();
                                        });
                                      } else {
                                        customColorCtrl.clear();
                                      }
                                    }
                                  },
                                  decoration: const InputDecoration(
                                    labelText: 'Add Custom Color Finish (Optional)',
                                    hintText: 'Type color name (e.g. Lavender, Mint, Sand) & press Enter or Add',
                                    prefixIcon: Icon(Icons.palette_outlined, size: 18),
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                onPressed: () {
                                  final customName = customColorCtrl.text.trim();
                                  if (customName.isNotEmpty) {
                                    if (!selectedColors.any((c) => c.toLowerCase() == customName.toLowerCase())) {
                                      setDialogState(() {
                                        selectedColors.add(customName);
                                        customColorCtrl.clear();
                                      });
                                    } else {
                                      customColorCtrl.clear();
                                    }
                                  }
                                },
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Add Color'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F172A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 22),

                          // -------------------------------------------------------------
                          // SECTION 6: SPECIFICATIONS LIST (TYPE + ENTER -> 1, 2... & DELETE CROSS)
                          // -------------------------------------------------------------
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text(
                                  '6. PRODUCT SPECIFICATIONS (DYNAMIC NUMBERED LIST)',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF475569), letterSpacing: 0.5),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${specsList.length} items configured',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1C7BFF)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Spec Input Field (Press Enter to add!)
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: newSpecCtrl,
                                  focusNode: specFocusNode,
                                  onSubmitted: (text) => addSpecItem(),
                                  textInputAction: TextInputAction.done,
                                  decoration: InputDecoration(
                                    hintText: 'Type a specification (e.g. 6.7" Super Retina XDR OLED 120Hz) and press Enter ↵',
                                    hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                                    prefixIcon: const Icon(Icons.format_list_numbered_rounded, size: 20, color: Color(0xFF1C7BFF)),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.add_circle, color: Color(0xFF1C7BFF)),
                                      tooltip: 'Add item (or press Enter)',
                                      onPressed: addSpecItem,
                                    ),
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Numbered Specifications Display Container
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(minHeight: 80, maxHeight: 180),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: specsList.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.playlist_add_rounded, size: 30, color: Colors.grey.shade400),
                                        const SizedBox(height: 6),
                                        Text(
                                          'No specifications added yet.',
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Type in the box above and press Enter key to add Item 1, next Enter for Item 2, etc.',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    itemCount: specsList.length,
                                    separatorBuilder: (context, index) => const SizedBox(height: 6),
                                    itemBuilder: (ctx, index) {
                                      final itemText = specsList[index];
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                        ),
                                        child: Row(
                                          children: [
                                            // Number badge (1, 2, 3...)
                                            Container(
                                              width: 24,
                                              height: 24,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0F172A),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '${index + 1}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),

                                            // Spec text
                                            Expanded(
                                              child: Text(
                                                itemText,
                                                style: const TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF1E293B),
                                                ),
                                              ),
                                            ),

                                            // Red Cross Delete Button
                                            Tooltip(
                                              message: 'Delete specification #${index + 1}',
                                              child: InkWell(
                                                onTap: () {
                                                  setDialogState(() {
                                                    specsList.removeAt(index);
                                                  });
                                                },
                                                borderRadius: BorderRadius.circular(6),
                                                child: Container(
                                                  padding: const EdgeInsets.all(5),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFEE2E2),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: const Icon(
                                                    Icons.close_rounded,
                                                    size: 15,
                                                    color: Color(0xFFDC2626), // Red cross
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),

                          const SizedBox(height: 14),

                          // Quick Specification Presets
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text('Quick Insert:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade600)),
                              ...[
                                '120Hz OLED Display',
                                '5000 mAh Battery',
                                '50MP Triple Camera',
                                '5G Dual SIM',
                                '67W Fast Charging',
                                'Titanium Aerospace Frame',
                              ].map((preset) {
                                return ActionChip(
                                  label: Text('+ $preset'),
                                  labelStyle: const TextStyle(fontSize: 11, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  onPressed: () {
                                    if (!specsList.contains(preset)) {
                                      setDialogState(() => specsList.add(preset));
                                    }
                                  },
                                );
                              }),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // Customer App Banner Carousel Toggle
                          CheckboxListTile(
                            title: const Text('Display on Customer App Banner Carousel & Spotlight', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                            subtitle: const Text('Automatically display this item with its price, photos, and buy button on the customer mobile app hero banner', style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
                            value: isFeatured,
                            onChanged: (val) {
                              setDialogState(() => isFeatured = val ?? true);
                            },
                            activeColor: const Color(0xFF1C7BFF),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 24, color: Color(0xFFE2E8F0)),

                  // Dialog Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: Icon(isEditing ? Icons.save_rounded : Icons.add_circle_outline_rounded, size: 18),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1C7BFF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          final resolvedName = isCustomModel
                              ? customModelCtrl.text.trim()
                              : selectedModel;

                          if (resolvedName.isEmpty || resolvedName == 'Custom / Unlisted Model') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select or specify a valid product model name'),
                                backgroundColor: Color(0xFFDC2626),
                              ),
                            );
                            return;
                          }

                          final wholesale = double.tryParse(wholesalePriceCtrl.text) ?? 0.0;
                          final retail = double.tryParse(retailPriceCtrl.text) ?? wholesale;
                          final stock = int.tryParse(stockCtrl.text) ?? 0;

                          if (wholesale <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please specify a valid wholesale selling price'),
                                backgroundColor: Color(0xFFDC2626),
                              ),
                            );
                            return;
                          }

                          if (selectedColors.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select or add at least 1 color finish for this SKU'),
                                backgroundColor: Color(0xFFDC2626),
                              ),
                            );
                            return;
                          }

                          final compiledSpecs = specsList.isNotEmpty ? specsList.join(' • ') : '';
                          final primaryColor = selectedColors.first;

                          // Determine product ID for image filename
                          final productId = isEditing
                              ? product.id
                              : 'prod_${DateTime.now().millisecondsSinceEpoch}';

                          // Resolve the final image URL
                          String imgUrl = imageUrlCtrl.text.trim();

                          // Determine image bytes: prefer pickedImageBytes, otherwise read local file
                          Uint8List? bytesToUpload = pickedImageBytes;
                          if (bytesToUpload == null &&
                              imgUrl.isNotEmpty &&
                              !imgUrl.startsWith('http') &&
                              !imgUrl.startsWith('data:')) {
                            try {
                              final localFile = File(imgUrl);
                              if (localFile.existsSync()) {
                                bytesToUpload = localFile.readAsBytesSync();
                              }
                            } catch (_) {}
                          }

                          // Upload to Supabase Storage if we have image bytes
                          if (bytesToUpload != null) {
                            setDialogState(() {});
                            final uploadedUrl = await widget.repository.supabase
                                .uploadProductImage(bytesToUpload, productId);
                            if (uploadedUrl != null) {
                              // ✅ Successfully uploaded to Supabase Storage — use public URL
                              imgUrl = uploadedUrl;
                            } else {
                              // ⚠️ Storage upload failed (bucket may not exist yet) —
                              // fall back to base64 Data URI so image is always saved
                              imgUrl = 'data:image/png;base64,${base64Encode(bytesToUpload)}';
                              debugPrint('⚠️ Storage upload failed, saved as base64 fallback');
                            }
                          }

                          if (isEditing) {
                            product.name = resolvedName;
                            product.brand = selectedBrand;
                            product.category = categoryCtrl.text;
                            product.wholesalePrice = wholesale;
                            product.retailPrice = retail;
                            product.stock = stock;
                            product.storage = selectedStorage;
                            product.ram = selectedRam;
                            product.color = primaryColor;
                            product.colors = List<String>.from(selectedColors);
                            product.specsList = List<String>.from(specsList);
                            product.specs = compiledSpecs;
                            product.condition = conditionCtrl.text;
                            product.isFeatured = isFeatured;
                            product.imageUrl = imgUrl;
                            product.imageBytes = pickedImageBytes;
                            widget.repository.updateProduct(product);
                          } else {
                            final newProduct = ManagerProduct(
                              id: productId,
                              name: resolvedName,
                              brand: selectedBrand,
                              category: categoryCtrl.text,
                              price: wholesale,
                              originalPrice: retail,
                              stock: stock,
                              specs: compiledSpecs,
                              specsList: List<String>.from(specsList),
                              storage: selectedStorage,
                              ram: selectedRam,
                              color: primaryColor,
                              colors: List<String>.from(selectedColors),
                              condition: conditionCtrl.text,
                              isFeatured: isFeatured,
                              imageUrl: imgUrl,
                              imageBytes: pickedImageBytes,
                            );
                            widget.repository.addProduct(newProduct);
                          }

                          if (ctx.mounted) Navigator.pop(ctx);
                          setState(() {});
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isEditing ? 'Product "$resolvedName" updated successfully' : 'New SKU "$resolvedName" added to inventory catalog'),
                                backgroundColor: const Color(0xFF059669),
                              ),
                            );
                          }
                        },
                        label: Text(isEditing ? 'Save Product Changes' : 'Create Inventory SKU'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteProduct(BuildContext context, ManagerProduct product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to remove "${product.name}" from the catalog? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () {
              widget.repository.deleteProduct(product.id);
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Product "${product.name}" removed from catalog'),
                  backgroundColor: const Color(0xFF1E293B),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionPill(String condition) {
    Color bg;
    Color text;
    Color border;
    switch (condition) {
      case 'UK Used':
        bg = const Color(0xFFFFF7ED);
        text = const Color(0xFFEA580C);
        border = const Color(0xFFFED7AA);
        break;
      case 'Refurbished':
        bg = const Color(0xFFECFDF5);
        text = const Color(0xFF059669);
        border = const Color(0xFFA7F3D0);
        break;
      case 'Open Box':
        bg = const Color(0xFFFAF5FF);
        text = const Color(0xFF9333EA);
        border = const Color(0xFFE9D5FF);
        break;
      case 'New':
      case 'Brand New':
      default:
        bg = const Color(0xFFEFF6FF);
        text = const Color(0xFF1C7BFF);
        border = const Color(0xFFBFDBFE);
        break;
    }

    final displayText = (condition == 'Brand New') ? 'New' : condition;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }
}
