String salePaymentMethodLabel(int method) {
  return switch (method) {
    0 => 'Efectivo',
    1 => 'Transferencia',
    2 => 'Cheque',
    3 => 'Tarjeta de débito',
    4 => 'Tarjeta de crédito',
    5 => 'Puntos',
    _ => '—',
  };
}
