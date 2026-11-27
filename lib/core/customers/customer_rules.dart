import 'package:casca_app/core/customers/customer_model.dart';

const int maxNameLength = 100;
const int minPhoneLength = 10;
const int maxPhoneLength = 15;
const int maxEmailLength = 150;
const int maxNotesLength = 1000;

final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

enum CustomerStatusFilter {
  all('Todos', null),
  confirmed('Confirmados', 'Confirmed'),
  pending('Pendientes', 'Pending');

  const CustomerStatusFilter(this.label, this.value);

  final String label;
  final String? value;
}

String? validateFirstName(String? value) {
  return (value ?? '').trim().isEmpty ? 'Escribe el nombre.' : null;
}

String? validateCustomerPhone(String? value) {
  final phone = (value ?? '').trim();
  return phone.isNotEmpty && phone.length < minPhoneLength
      ? 'Escribe al menos $minPhoneLength dígitos.'
      : null;
}

String? validateCustomerEmail(String? value) {
  final email = (value ?? '').trim();
  return email.isNotEmpty && !_emailPattern.hasMatch(email)
      ? 'Escribe un correo válido.'
      : null;
}

String? validateRequiredEmail(String? value) {
  return (value ?? '').trim().isEmpty
      ? 'Escribe el correo.'
      : validateCustomerEmail(value);
}

bool hasContact(String phone, String email) {
  return phone.trim().isNotEmpty || email.trim().isNotEmpty;
}

Map<String, dynamic> createCustomerRequest({
  required String firstName,
  String lastName = '',
  String phone = '',
  String email = '',
  String notes = '',
}) {
  String? orNull(String value) => value.trim().isEmpty ? null : value.trim();

  return {
    'firstName': firstName.trim(),
    'lastName': orNull(lastName),
    'phone': orNull(phone),
    'email': orNull(email),
    'notes': orNull(notes),
  };
}

String normalizeEmail(String email) => email.trim().toLowerCase();

String customerName(CustomerModel customer) {
  return [
    customer.firstName,
    customer.lastName ?? '',
  ].map((part) => part.trim()).where((part) => part.isNotEmpty).join(' ');
}

String customerInitials(CustomerModel customer) {
  return customerName(customer)
      .split(' ')
      .take(2)
      .map((part) => String.fromCharCode(part.runes.first))
      .join()
      .toUpperCase();
}

String customerContact(CustomerModel customer) {
  return customer.phone ?? customer.email ?? '—';
}
