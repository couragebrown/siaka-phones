class AdvertisementBanner {
  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final String? backupAsset;
  final String badgeText;
  final String callToActionText;
  final String targetCategoryOrProduct;
  final bool isActive;
  final int displayOrder;
  final int impressionsCount;
  final int clicksCount;
  final DateTime createdAt;

  const AdvertisementBanner({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    this.backupAsset,
    this.badgeText = 'PROMO',
    this.callToActionText = 'Shop Now',
    this.targetCategoryOrProduct = 'Smartphones',
    this.isActive = true,
    this.displayOrder = 1,
    this.impressionsCount = 0,
    this.clicksCount = 0,
    required this.createdAt,
  });

  double get clickThroughRate {
    if (impressionsCount == 0) return 0.0;
    return (clicksCount / impressionsCount) * 100;
  }

  AdvertisementBanner copyWith({
    String? id,
    String? title,
    String? description,
    String? videoUrl,
    String? backupAsset,
    String? badgeText,
    String? callToActionText,
    String? targetCategoryOrProduct,
    bool? isActive,
    int? displayOrder,
    int? impressionsCount,
    int? clicksCount,
    DateTime? createdAt,
  }) {
    return AdvertisementBanner(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      backupAsset: backupAsset ?? this.backupAsset,
      badgeText: badgeText ?? this.badgeText,
      callToActionText: callToActionText ?? this.callToActionText,
      targetCategoryOrProduct: targetCategoryOrProduct ?? this.targetCategoryOrProduct,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      impressionsCount: impressionsCount ?? this.impressionsCount,
      clicksCount: clicksCount ?? this.clicksCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'backupAsset': backupAsset,
      'badgeText': badgeText,
      'callToActionText': callToActionText,
      'targetCategoryOrProduct': targetCategoryOrProduct,
      'isActive': isActive,
      'displayOrder': displayOrder,
      'impressionsCount': impressionsCount,
      'clicksCount': clicksCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AdvertisementBanner.fromJson(Map<String, dynamic> json) {
    return AdvertisementBanner(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      videoUrl: json['videoUrl'] as String,
      backupAsset: json['backupAsset'] as String?,
      badgeText: json['badgeText'] as String? ?? 'PROMO',
      callToActionText: json['callToActionText'] as String? ?? 'Shop Now',
      targetCategoryOrProduct: json['targetCategoryOrProduct'] as String? ?? 'Smartphones',
      isActive: json['isActive'] as bool? ?? true,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 1,
      impressionsCount: (json['impressionsCount'] as num?)?.toInt() ?? 0,
      clicksCount: (json['clicksCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
