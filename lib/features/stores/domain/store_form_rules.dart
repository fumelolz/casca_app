class StoreFormValues {
  const StoreFormValues({
    this.name = '',
    this.phone = '',
    this.email = '',
    this.street = '',
    this.exteriorNumber = '',
    this.interiorNumber = '',
    this.municipality = '',
    this.city = '',
    this.state = '',
    this.postalCode = '',
    this.country = 'México',
  });

  factory StoreFormValues.fromDetail(Map<String, dynamic> detail) {
    final business = detail['businessInformation'] as Map<String, dynamic>;
    final contact = detail['contactInformation'] as Map<String, dynamic>;
    final address = detail['address'] as Map<String, dynamic>;
    String text(Map<String, dynamic> map, String key) =>
        map[key] as String? ?? '';

    return StoreFormValues(
      name: text(business, 'name'),
      phone: text(contact, 'phone'),
      email: text(contact, 'email'),
      street: text(address, 'street'),
      exteriorNumber: text(address, 'exteriorNumber'),
      interiorNumber: text(address, 'interiorNumber'),
      municipality: text(address, 'municipality'),
      city: text(address, 'city'),
      state: text(address, 'state'),
      postalCode: text(address, 'postalCode'),
      country: text(address, 'country'),
    );
  }

  final String name;
  final String phone;
  final String email;
  final String street;
  final String exteriorNumber;
  final String interiorNumber;
  final String municipality;
  final String city;
  final String state;
  final String postalCode;
  final String country;
}

String? _textOrNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

Map<String, dynamic> _contactAndAddress(StoreFormValues values) => {
  'contactInformation': {
    'phone': _textOrNull(values.phone),
    'email': _textOrNull(values.email),
  },
  'address': {
    'street': values.street.trim(),
    'city': values.city.trim(),
    'municipality': values.municipality.trim(),
    'state': values.state.trim(),
    'country': values.country.trim(),
    'postalCode': values.postalCode.trim(),
    'interiorNumber': _textOrNull(values.interiorNumber),
    'exteriorNumber': _textOrNull(values.exteriorNumber),
  },
};

Map<String, dynamic> toCreateStoreRequest(
  StoreFormValues values,
  String tenantId,
) => {
  'tenantId': tenantId,
  'isDefault': false,
  'businessInformation': {'name': values.name.trim(), 'website': null},
  'operatingHours': {
    'is24Hours': false,
    'openingTime': null,
    'closingTime': null,
  },
  'operationalStatus': {
    'isOpen': true,
    'isUnderMaintenance': false,
    'isActive': true,
  },
  'socialMediaLinks': <Object>[],
  ..._contactAndAddress(values),
};

Map<String, dynamic> toUpdateStoreRequest(
  StoreFormValues values,
  Map<String, dynamic> current,
) {
  final business = current['businessInformation'] as Map<String, dynamic>;
  final settings = current['settings'] as Map<String, dynamic>;

  return {
    'businessInformation': {
      'name': values.name.trim(),
      'website': business['website'],
    },
    'operatingHours': current['operatingHours'],
    'operationalStatus': current['operationalStatus'],
    'socialMediaLinks': current['socialMediaLinks'],
    'taxesEnabled': settings['taxesEnabled'],
    'defaultTaxRate': settings['defaultTaxRate'],
    'pricesIncludeTax': settings['pricesIncludeTax'],
    ..._contactAndAddress(values),
  };
}

final RegExp _phonePattern = RegExp(r'^[\d\s\-+()]{10,20}$');
final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final RegExp _postalCodePattern = RegExp(r'^[0-9A-Za-z\-\s]+$');

String? validateStoreName(String? value) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) return 'Ingresa el nombre';
  return name.length < 2 ? 'Usa al menos 2 caracteres' : null;
}

String? validateRequired(String? value) {
  return (value?.trim() ?? '').isEmpty ? 'Campo obligatorio' : null;
}

String? validatePhone(String? value) {
  final phone = value?.trim() ?? '';
  if (phone.isEmpty || _phonePattern.hasMatch(phone)) return null;
  return 'Ingresa un teléfono de 10 a 20 dígitos';
}

String? validateOptionalEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty || _emailPattern.hasMatch(email)) return null;
  return 'Ingresa un correo válido';
}

String? validatePostalCode(String? value) {
  final code = value?.trim() ?? '';
  if (code.isEmpty) return 'Campo obligatorio';
  return _postalCodePattern.hasMatch(code) ? null : 'Código postal no válido';
}
