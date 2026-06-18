class PatchModel {
  final String patchId;
  final String title;
  final String description;
  final String vectorArtUrl;
  final String unlockConditionType;
  final int unlockThreshold;

  const PatchModel({
    required this.patchId,
    required this.title,
    required this.description,
    required this.vectorArtUrl,
    required this.unlockConditionType,
    required this.unlockThreshold,
  });

  factory PatchModel.fromJson(Map<String, dynamic> json) {
    return PatchModel(
      patchId: json['patch_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      vectorArtUrl: json['vector_art_url'] as String? ?? '',
      unlockConditionType: json['unlock_condition_type'] as String? ?? '',
      unlockThreshold: json['unlock_threshold'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patch_id': patchId,
      'title': title,
      'description': description,
      'vector_art_url': vectorArtUrl,
      'unlock_condition_type': unlockConditionType,
      'unlock_threshold': unlockThreshold,
    };
  }
}
