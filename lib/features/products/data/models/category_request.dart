class CategoryRequest {
  const CategoryRequest({
    required this.name,
    this.description,
    this.parentCategoryId,
  });

  final String name;
  final String? description;
  final String? parentCategoryId;

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'parentCategoryId': parentCategoryId,
  };
}
