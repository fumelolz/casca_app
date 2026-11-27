class CustomerModel {
  const CustomerModel({
    required this.id,
    required this.firstName,
    required this.isConfirmed,
    this.lastName,
    this.phone,
    this.email,
    this.notes,
    this.createdAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      notes: json['notes'] as String?,
      isConfirmed: json['status'] == 'Confirmed',
      createdAt: DateTime.tryParse(json['createdOnUtc'] as String? ?? ''),
    );
  }

  final String id;
  final String firstName;
  final String? lastName;
  final String? phone;
  final String? email;
  final String? notes;
  final bool isConfirmed;
  final DateTime? createdAt;
}
