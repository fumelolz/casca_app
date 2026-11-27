class EmployeeModel {
  const EmployeeModel({
    required this.id,
    required this.name,
    required this.email,
    required this.roleId,
    required this.roleName,
    required this.isActive,
    this.phone = '',
    this.invitationPending = false,
    this.acceptancePending = false,
    this.acceptanceDeclined = false,
    this.hasFullCashRegisterAccess = false,
    this.cashRegisterNames = const [],
    this.lastLogin,
    this.createdAt,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    DateTime? date(String key) => DateTime.tryParse(json[key] as String? ?? '');

    return EmployeeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String? ?? '',
      roleId: json['roleId'] as String,
      roleName: json['roleName'] as String,
      isActive: json['isActive'] as bool,
      invitationPending: json['invitationPending'] as bool? ?? false,
      acceptancePending: json['acceptancePending'] as bool? ?? false,
      acceptanceDeclined: json['acceptanceDeclined'] as bool? ?? false,
      hasFullCashRegisterAccess:
          json['hasFullCashRegisterAccess'] as bool? ?? false,
      cashRegisterNames: [
        for (final item in json['cashRegisters'] as List<Object?>? ?? const [])
          (item as Map<String, dynamic>)['name'] as String,
      ],
      lastLogin: date('lastLogin'),
      createdAt: date('createdOnUtc'),
    );
  }

  final String id;
  final String name;
  final String email;
  final String phone;
  final String roleId;
  final String roleName;
  final bool isActive;
  final bool invitationPending;
  final bool acceptancePending;
  final bool acceptanceDeclined;
  final bool hasFullCashRegisterAccess;
  final List<String> cashRegisterNames;
  final DateTime? lastLogin;
  final DateTime? createdAt;
}

class EmployeeRoleOption {
  const EmployeeRoleOption({required this.id, required this.name});

  factory EmployeeRoleOption.fromJson(Map<String, dynamic> json) {
    return EmployeeRoleOption(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  final String id;
  final String name;
}

class CashRegisterAccess {
  const CashRegisterAccess({
    required this.id,
    required this.name,
    required this.hasAccess,
  });

  factory CashRegisterAccess.fromJson(Map<String, dynamic> json) {
    return CashRegisterAccess(
      id: json['cashRegisterId'] as String,
      name: json['name'] as String,
      hasAccess: json['hasAccess'] as bool,
    );
  }

  final String id;
  final String name;
  final bool hasAccess;
}

class CreateEmployeeResult {
  const CreateEmployeeResult({
    required this.invitationSent,
    this.addedToExistingUser = false,
    this.pendingAcceptance = false,
  });

  factory CreateEmployeeResult.fromJson(Map<String, dynamic> json) {
    return CreateEmployeeResult(
      invitationSent: json['invitationSent'] as bool? ?? false,
      addedToExistingUser: json['addedToExistingUser'] as bool? ?? false,
      pendingAcceptance: json['pendingAcceptance'] as bool? ?? false,
    );
  }

  final bool invitationSent;
  final bool addedToExistingUser;
  final bool pendingAcceptance;
}
