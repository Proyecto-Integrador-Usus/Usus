import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/cart/data/cart_controller.dart';

class AppSettings extends ChangeNotifier {
  AppSettings([this._store]) {
    darkMode = _store?.getBool('darkMode') ?? false;
    final savedSort = _store?.getString('catalogSort');
    catalogSort = sortOptions.contains(savedSort)
        ? savedSort!
        : sortOptions.first;
    preferredDelivery =
        _store?.getString('preferredDelivery') == DeliveryMethod.delivery.name
        ? DeliveryMethod.delivery
        : DeliveryMethod.pickup;
  }

  static const sortOptions = [
    'Recomendados',
    'Menor precio',
    'Mejor valorados',
  ];
  final SharedPreferences? _store;
  late bool darkMode;
  late String catalogSort;
  late DeliveryMethod preferredDelivery;

  void setDarkMode(bool value) {
    darkMode = value;
    _store?.setBool('darkMode', value);
    notifyListeners();
  }

  void setCatalogSort(String value) {
    catalogSort = value;
    _store?.setString('catalogSort', value);
    notifyListeners();
  }

  void setPreferredDelivery(DeliveryMethod value) {
    preferredDelivery = value;
    _store?.setString('preferredDelivery', value.name);
    notifyListeners();
  }
}
