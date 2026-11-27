import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/core/customers/customer_model.dart';
import 'package:casca_app/core/customers/customer_rules.dart';
import 'package:material_ui/material_ui.dart';

const double _avatarSize = 40;

class CustomerAvatar extends StatelessWidget {
  const CustomerAvatar({super.key, required this.customer});

  final CustomerModel customer;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;

    return ExcludeSemantics(
      child: Container(
        width: _avatarSize,
        height: _avatarSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.primarySoft,
          shape: BoxShape.circle,
        ),
        child: Text(
          customerInitials(customer),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colors.primary,
            fontWeight: CascaFontWeight.semibold,
          ),
        ),
      ),
    );
  }
}
