import 'package:flutter/material.dart';
import '../../core/widgets/brand_logo.dart';

class BrandItem {
  final String name;
  final dynamic icon;
  final bool isIcon;
  final Color bg;
  final Color textColor;
  final String tagline;

  const BrandItem({
    required this.name,
    required this.icon,
    this.isIcon = false,
    this.bg = const Color(0xFFF2F4F7),
    this.textColor = const Color(0xFF111827),
    this.tagline = '',
  });
}

class BrandsView extends StatefulWidget {
  final Function(String brand)? onBrandSelected;

  const BrandsView({super.key, this.onBrandSelected});

  static const List<BrandItem> allBrands = [
    BrandItem(
      name: 'Apple',
      icon: Icons.apple,
      isIcon: true,
      tagline: 'iPhone & Mac',
    ),
    BrandItem(
      name: 'Samsung',
      icon: 'S',
      tagline: 'Galaxy Series',
    ),
    BrandItem(
      name: 'Google',
      icon: 'G',
      tagline: 'Pixel Series',
    ),
    BrandItem(
      name: 'OnePlus',
      icon: '1+',
      tagline: 'Never Settle',
    ),
    BrandItem(
      name: 'Xiaomi',
      icon: 'MI',
      tagline: 'Smart Tech',
    ),
    BrandItem(
      name: 'Honor',
      icon: 'HONOR',
      tagline: 'Magic Series',
    ),
    BrandItem(
      name: 'HP',
      icon: 'hp',
      tagline: 'Spectre & Pavilion',
    ),
    BrandItem(
      name: 'Dell',
      icon: 'DELL',
      tagline: 'XPS & Alienware',
    ),
    BrandItem(
      name: 'Lenovo',
      icon: 'L',
      tagline: 'ThinkPad & Legion',
    ),
    BrandItem(
      name: 'Asus',
      icon: 'ASUS',
      tagline: 'ROG & ZenBook',
    ),
    BrandItem(
      name: 'Sony',
      icon: 'SONY',
      tagline: 'Xperia & Audio',
    ),
    BrandItem(
      name: 'Huawei',
      icon: 'H',
      tagline: 'Mate & P Series',
    ),
    BrandItem(
      name: 'Oppo',
      icon: 'oppo',
      tagline: 'Find & Reno',
    ),
    BrandItem(
      name: 'Vivo',
      icon: 'vivo',
      tagline: 'X & V Series',
    ),
    BrandItem(
      name: 'Realme',
      icon: 'R',
      tagline: 'GT Series',
    ),
    BrandItem(
      name: 'Motorola',
      icon: 'M',
      tagline: 'Edge & Razr',
    ),
    BrandItem(
      name: 'Nothing',
      icon: '( )',
      tagline: 'Phone (2) & Ear',
    ),
    BrandItem(
      name: 'Infinix',
      icon: 'INF',
      tagline: 'Zero & GT',
    ),
    BrandItem(
      name: 'Tecno',
      icon: 'TECNO',
      tagline: 'Phantom & Camon',
    ),
    BrandItem(
      name: 'Nokia',
      icon: 'NOK',
      tagline: 'Reliable Pure Android',
    ),
    BrandItem(
      name: 'Microsoft',
      icon: Icons.window,
      isIcon: true,
      tagline: 'Surface Series',
    ),
    BrandItem(
      name: 'Acer',
      icon: 'acer',
      tagline: 'Predator & Swift',
    ),
    BrandItem(
      name: 'Razer',
      icon: Icons.sports_esports_outlined,
      isIcon: true,
      tagline: 'Gaming Hardware',
    ),
    BrandItem(
      name: 'LG',
      icon: 'LG',
      tagline: 'Electronics & Displays',
    ),
    BrandItem(
      name: 'TCL',
      icon: 'TCL',
      tagline: 'NxtPaper Series',
    ),
    BrandItem(
      name: 'Poco',
      icon: 'POCO',
      tagline: 'Power & Speed',
    ),
    BrandItem(
      name: 'ZTE',
      icon: 'ZTE',
      tagline: 'Nubia & RedMagic',
    ),
    BrandItem(
      name: 'HTC',
      icon: 'htc',
      tagline: 'U Series & Vive',
    ),
    BrandItem(
      name: 'BlackBerry',
      icon: 'BB',
      tagline: 'Security Heritage',
    ),
    BrandItem(
      name: 'Alienware',
      icon: Icons.smart_toy_outlined,
      isIcon: true,
      tagline: 'High-End Gaming',
    ),
  ];

  @override
  State<BrandsView> createState() => _BrandsViewState();
}

class _BrandsViewState extends State<BrandsView> {
  final TextEditingController _searchController = TextEditingController();
  String _filterQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredBrands = BrandsView.allBrands.where((brand) {
      if (_filterQuery.isEmpty) return true;
      final q = _filterQuery.toLowerCase();
      return brand.name.toLowerCase().contains(q) ||
          brand.tagline.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F4F6),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: Color(0xFF1E2432),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Shop by Brand',
          style: TextStyle(
            color: Color(0xFF1E2432),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search & stats bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE1E5EA)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.search, color: Color(0xFF8A93A6), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _filterQuery = val.trim()),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF111827),
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search brand (e.g. HP, Honor, Dell)...',
                          hintStyle: TextStyle(
                            color: Color(0xFF8A93A6),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_filterQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            size: 18, color: Color(0xFF8A93A6)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _filterQuery = '');
                        },
                      )
                    else
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F4F7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${BrandsView.allBrands.length}',
                          style: const TextStyle(
                            color: Color(0xFF4B5563),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Header info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _filterQuery.isEmpty
                        ? 'All Brands (${BrandsView.allBrands.length})'
                        : 'Matching Brands (${filteredBrands.length})',
                    style: const TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(
                    'Tap to view products',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Brands Grid matching the exact design and size of the home page
            Expanded(
              child: filteredBrands.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'No brands found for "$_filterQuery"',
                            style: const TextStyle(
                              color: Color(0xFF4B5563),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: filteredBrands.length,
                      itemBuilder: (context, index) {
                        final brand = filteredBrands[index];
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              if (widget.onBrandSelected != null) {
                                widget.onBrandSelected!(brand.name);
                              } else {
                                Navigator.of(context).pop();
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFFE5E7EB)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 8),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: 26,
                                      child: Center(
                                        child: BrandLogo(brand: brand.name),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      brand.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
