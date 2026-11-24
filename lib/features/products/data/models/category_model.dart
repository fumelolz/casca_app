class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.parentCategoryId,
    this.parentCategoryName,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      parentCategoryId: json['parentCategoryId'] as String?,
      parentCategoryName: json['parentCategoryName'] as String?,
    );
  }

  final String id;
  final String name;
  final String? description;
  final String? parentCategoryId;
  final String? parentCategoryName;
}
