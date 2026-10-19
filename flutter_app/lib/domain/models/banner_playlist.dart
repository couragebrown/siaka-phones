class BannerImageItem {
  final String id;
  final String imageUrl;
  final String title;
  final bool isActive;
  final int displayOrder;
  final DateTime createdAt;

  const BannerImageItem({
    required this.id,
    required this.imageUrl,
    this.title = '',
    this.isActive = true,
    this.displayOrder = 1,
    required this.createdAt,
  });

  BannerImageItem copyWith({
    String? id,
    String? imageUrl,
    String? title,
    bool? isActive,
    int? displayOrder,
    DateTime? createdAt,
  }) {
    return BannerImageItem(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      title: title ?? this.title,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'imageUrl': imageUrl,
        'title': title,
        'isActive': isActive,
        'displayOrder': displayOrder,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BannerImageItem.fromJson(Map<String, dynamic> json) =>
      BannerImageItem(
        id: json['id'] as String? ?? 'IMG-1',
        imageUrl: json['imageUrl'] as String? ?? '',
        title: json['title'] as String? ?? '',
        isActive: json['isActive'] as bool? ?? true,
        displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 1,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime(2026, 1, 1)
            : DateTime(2026, 1, 1),
      );
}

class BannerVideoItem {
  final String id;
  final String videoUrl;
  final String title;
  final String description;
  final String badgeText;
  final String callToActionText;
  final String targetCategoryOrProduct;
  final bool isActive;
  final int displayOrder;
  final DateTime createdAt;

  const BannerVideoItem({
    required this.id,
    required this.videoUrl,
    this.title = '',
    this.description = '',
    this.badgeText = 'PROMO',
    this.callToActionText = 'Shop Now',
    this.targetCategoryOrProduct = 'Smartphones',
    this.isActive = true,
    this.displayOrder = 1,
    required this.createdAt,
  });

  BannerVideoItem copyWith({
    String? id,
    String? videoUrl,
    String? title,
    String? description,
    String? badgeText,
    String? callToActionText,
    String? targetCategoryOrProduct,
    bool? isActive,
    int? displayOrder,
    DateTime? createdAt,
  }) {
    return BannerVideoItem(
      id: id ?? this.id,
      videoUrl: videoUrl ?? this.videoUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      badgeText: badgeText ?? this.badgeText,
      callToActionText: callToActionText ?? this.callToActionText,
      targetCategoryOrProduct: targetCategoryOrProduct ?? this.targetCategoryOrProduct,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'videoUrl': videoUrl,
        'title': title,
        'description': description,
        'badgeText': badgeText,
        'callToActionText': callToActionText,
        'targetCategoryOrProduct': targetCategoryOrProduct,
        'isActive': isActive,
        'displayOrder': displayOrder,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BannerVideoItem.fromJson(Map<String, dynamic> json) =>
      BannerVideoItem(
        id: json['id'] as String? ?? 'VID-1',
        videoUrl: json['videoUrl'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        badgeText: json['badgeText'] as String? ?? 'PROMO',
        callToActionText: json['callToActionText'] as String? ?? 'Shop Now',
        targetCategoryOrProduct:
            json['targetCategoryOrProduct'] as String? ?? 'Smartphones',
        isActive: json['isActive'] as bool? ?? true,
        displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 1,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime(2026, 1, 1)
            : DateTime(2026, 1, 1),
      );
}

class BannerPlaylist {
  final String id; // 'banner_home_1', 'banner_home_2', 'banner_home_3', 'banner_home_4', 'banner_search_1'
  final String name; // e.g. 'Homepage Banner 1'
  final String subtitle; // e.g. 'Discover Smartphones (Slide 1)'
  final String targetPage; // 'home' or 'search'
  final int bannerIndex; // 0, 1, 2, 3 for home, 0 for search
  final String bannerType; // 'video' for banner_home_1 and banner_search_1, 'image' for 2, 3, 4
  final bool isActive;
  final List<BannerImageItem> images;
  final List<BannerVideoItem> videos;

  const BannerPlaylist({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.targetPage,
    required this.bannerIndex,
    this.bannerType = 'image',
    this.isActive = true,
    this.images = const [],
    this.videos = const [],
  });

  bool get isVideoBanner =>
      bannerType == 'video' || id == 'banner_home_1' || id == 'banner_search_1';
  bool get isImageBanner => !isVideoBanner;

  List<BannerImageItem> get activeImages {
    final list =
        images.where((img) => img.isActive && img.imageUrl.trim().isNotEmpty).toList();
    list.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return list;
  }

  List<BannerVideoItem> get activeVideos {
    final list =
        videos.where((v) => v.isActive && v.videoUrl.trim().isNotEmpty).toList();
    list.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return list;
  }

  BannerPlaylist copyWith({
    String? id,
    String? name,
    String? subtitle,
    String? targetPage,
    int? bannerIndex,
    String? bannerType,
    bool? isActive,
    List<BannerImageItem>? images,
    List<BannerVideoItem>? videos,
  }) {
    return BannerPlaylist(
      id: id ?? this.id,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      targetPage: targetPage ?? this.targetPage,
      bannerIndex: bannerIndex ?? this.bannerIndex,
      bannerType: bannerType ?? this.bannerType,
      isActive: isActive ?? this.isActive,
      images: images ?? this.images,
      videos: videos ?? this.videos,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'subtitle': subtitle,
        'targetPage': targetPage,
        'bannerIndex': bannerIndex,
        'bannerType': isVideoBanner ? 'video' : 'image',
        'isActive': isActive,
        'images': images.map((i) => i.toJson()).toList(),
        'videos': videos.map((v) => v.toJson()).toList(),
      };

  factory BannerPlaylist.fromJson(Map<String, dynamic> json) {
    final pid = json['id'] as String? ?? '';
    final isVid = (json['bannerType'] == 'video') ||
        pid == 'banner_home_1' ||
        pid == 'banner_search_1';
    return BannerPlaylist(
      id: pid,
      name: json['name'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      targetPage: json['targetPage'] as String? ?? 'home',
      bannerIndex: (json['bannerIndex'] as num?)?.toInt() ?? 0,
      bannerType: isVid ? 'video' : 'image',
      isActive: json['isActive'] as bool? ?? true,
      images: (json['images'] as List?)
              ?.map((i) =>
                  BannerImageItem.fromJson(Map<String, dynamic>.from(i)))
              .toList() ??
          [],
      videos: (json['videos'] as List?)
              ?.map((v) =>
                  BannerVideoItem.fromJson(Map<String, dynamic>.from(v)))
              .toList() ??
          [],
    );
  }
}
