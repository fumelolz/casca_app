enum BusinessType { abarrotes, ferreteria, joyeria, otro }

class RegisterRequest {
  const RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    required this.tenantName,
    required this.businessType,
  });

  final String name;
  final String email;
  final String password;
  final String phone;
  final String tenantName;
  final BusinessType businessType;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'tenantName': tenantName,
      'businessType': businessType.name,
    };
  }
}
