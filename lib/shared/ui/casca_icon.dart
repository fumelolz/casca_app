import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

abstract final class CascaIcons {
  static const String arrowLeft = 'assets/icons/arrow-left.svg';
  static const String brandBag = 'assets/brand/casca-bag.svg';
  static const String basketShopping = 'assets/icons/basket-shopping.svg';
  static const String check = 'assets/icons/check.svg';
  static const String chevronDown = 'assets/icons/chevron-down.svg';
  static const String circle = 'assets/icons/circle.svg';
  static const String circleCheck = 'assets/icons/circle-check.svg';
  static const String key = 'assets/icons/key.svg';
  static const String envelope = 'assets/icons/envelope.svg';
  static const String eye = 'assets/icons/eye.svg';
  static const String eyeSlash = 'assets/icons/eye-slash.svg';
  static const String gem = 'assets/icons/gem.svg';
  static const String lock = 'assets/icons/lock.svg';
  static const String screwdriverWrench = 'assets/icons/screwdriver-wrench.svg';
  static const String store = 'assets/icons/store.svg';
  static const String xmark = 'assets/icons/xmark.svg';
  static const String addressBook = 'assets/icons/address-book.svg';
  static const String bars = 'assets/icons/bars.svg';
  static const String bell = 'assets/icons/bell.svg';
  static const String bellSlash = 'assets/icons/bell-slash.svg';
  static const String building = 'assets/icons/building.svg';
  static const String cashRegister = 'assets/icons/cash-register.svg';
  static const String chartColumn = 'assets/icons/chart-column.svg';
  static const String chevronRight = 'assets/icons/chevron-right.svg';
  static const String chevronLeft = 'assets/icons/chevron-left.svg';
  static const String dotsThree = 'assets/icons/dots-three.svg';
  static const String minus = 'assets/icons/minus.svg';
  static const String money = 'assets/icons/money.svg';
  static const String creditCard = 'assets/icons/credit-card.svg';
  static const String bank = 'assets/icons/bank.svg';
  static const String arrowRight = 'assets/icons/arrow-right.svg';
  static const String shuffle = 'assets/icons/shuffle.svg';
  static const String barcode = 'assets/icons/barcode.svg';
  static const String plus = 'assets/icons/plus.svg';
  static const String trash = 'assets/icons/trash.svg';
  static const String pencilSimple = 'assets/icons/pencil-simple.svg';
  static const String magnifyingGlass = 'assets/icons/magnifying-glass.svg';
  static const String sortAscending = 'assets/icons/sort-ascending.svg';
  static const String sortDescending = 'assets/icons/sort-descending.svg';
  static const String arrowsDownUp = 'assets/icons/arrows-down-up.svg';
  static const String clipboardList = 'assets/icons/clipboard-list.svg';
  static const String clock = 'assets/icons/clock.svg';
  static const String clockRotateLeft = 'assets/icons/clock-rotate-left.svg';
  static const String cube = 'assets/icons/cube.svg';
  static const String gear = 'assets/icons/gear.svg';
  static const String globe = 'assets/icons/globe.svg';
  static const String house = 'assets/icons/house.svg';
  static const String list = 'assets/icons/list.svg';
  static const String palette = 'assets/icons/palette.svg';
  static const String print = 'assets/icons/print.svg';
  static const String receipt = 'assets/icons/receipt.svg';
  static const String rightFromBracket = 'assets/icons/right-from-bracket.svg';
  static const String tags = 'assets/icons/tags.svg';
  static const String userShield = 'assets/icons/user-shield.svg';
  static const String users = 'assets/icons/users.svg';
  static const String wallet = 'assets/icons/wallet.svg';
}

class CascaIcon extends StatelessWidget {
  const CascaIcon(
    this.asset, {
    super.key,
    this.size = 16,
    this.color,
    this.filled = false,
  });

  final String asset;
  final double size;
  final Color? color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final resolvedColor =
        color ?? IconTheme.of(context).color ?? context.casca.textSecondary;

    return SvgPicture.asset(
      filled ? asset.replaceFirst('.svg', '-fill.svg') : asset,
      height: size,
      colorFilter: ColorFilter.mode(resolvedColor, BlendMode.srcIn),
    );
  }
}
