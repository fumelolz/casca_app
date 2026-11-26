class InvitationModel {
  const InvitationModel({
    required this.id,
    required this.storeName,
    required this.tenantName,
    required this.roleName,
    this.businessType,
  });

  factory InvitationModel.fromJson(Map<String, dynamic> json) {
    return InvitationModel(
      id: json['invitationId'] as String,
      storeName: json['storeName'] as String,
      tenantName: json['tenantName'] as String,
      roleName: json['roleName'] as String,
      businessType: json['businessType'] as String?,
    );
  }

  final String id;
  final String storeName;
  final String tenantName;
  final String roleName;
  final String? businessType;
}
