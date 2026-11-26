import 'package:casca_app/core/auth/register_request.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_select.dart';

const businessTypeOptions = [
  CascaSelectOption(
    value: BusinessType.abarrotes,
    label: 'Abarrotes y tienda',
    icon: CascaIcons.basketShopping,
  ),
  CascaSelectOption(
    value: BusinessType.ferreteria,
    label: 'Ferretería',
    icon: CascaIcons.screwdriverWrench,
  ),
  CascaSelectOption(
    value: BusinessType.joyeria,
    label: 'Joyería y platería',
    icon: CascaIcons.gem,
  ),
  CascaSelectOption(
    value: BusinessType.otro,
    label: 'Otro',
    icon: CascaIcons.store,
  ),
];
