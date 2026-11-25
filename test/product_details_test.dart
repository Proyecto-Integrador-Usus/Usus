import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usus/features/auth/data/auth_repository.dart';
import 'package:usus/features/cart/data/cart_controller.dart';
import 'package:usus/features/catalog/data/demo_catalog_repository.dart';
import 'package:usus/features/rentals/domain/rental_period.dart';
import 'package:usus/main.dart';

void main() {
  test(
    'Un artículo conserva periodos independientes y cobra días inclusivos',
    () {
      final cart = CartController();
      final product = demoProducts.first;
      final start = DateTime(2028, 2, 29);
      final one = RentalPeriod(start, start);
      final two = RentalPeriod(start, DateTime(2028, 3, 1));
      expect(two.toJson(), {
        'fecha_inicio': '2028-02-29',
        'fecha_fin': '2028-03-01',
      });
      expect(one.days, 1);
      expect(two.days, 2);
      expect(() => RentalPeriod(two.end, start), throwsArgumentError);
      cart.addProduct(product, period: one);
      cart.addProduct(product, period: two);
      cart.addProduct(product, period: one);
      expect(cart.items.length, 2);
      expect(cart.rentalSubtotal, product.pricePerDay * 4);
      cart.removeProduct(cart.items.first.lineId);
      expect(cart.items.single.period?.days, 2);
      cart.dispose();
    },
  );

  testWidgets(
    'Fechas desde el catálogo hasta el carrito pasando por el registro',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(UsusApp(auth: DemoAuthRepository()));
      await tester.pumpAndSettle();
      Future<void> tap(Finder target) async {
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      await tap(find.text('Ver artículo').first);
      expect(find.text('Detalles del artículo'), findsOneWidget);
      await tap(find.text('Fecha de inicio'));
      final picker = find.byType(DatePickerDialog);
      final today = tester.widget<DatePickerDialog>(picker).firstDate;
      await tap(find.text('Elegir'));
      await tap(find.text('1 día'));
      expect(find.text('Renta por 1 día: \$180 MXN'), findsOneWidget);

      await tap(find.text('Último día de renta'));
      expect(tester.widget<DatePickerDialog>(picker).firstDate, today);
      final end = DateTime(today.year, today.month, today.day + 2);
      final localizations = MaterialLocalizations.of(tester.element(picker));
      await tap(find.byTooltip(localizations.inputDateModeButtonLabel));
      await tester.enterText(
        find.byType(TextField),
        localizations.formatCompactDate(end),
      );
      await tap(find.text('Elegir'));
      expect(find.text('Renta por 3 días: \$540 MXN'), findsOneWidget);
      await tap(find.text('Iniciar sesión para rentar'));
      await tap(find.text('Soy nuevo · Crear cuenta'));
      final fields = find.byType(TextFormField);
      const entries = [
        'Ana',
        'Luna',
        'Centro',
        'ana@example.org',
        'Clave1234',
        'Clave1234',
      ];
      for (var i = 0; i < entries.length; i++) {
        await tester.enterText(fields.at(i), entries[i]);
      }
      await tap(find.byType(ElevatedButton));
      await tap(find.byTooltip('Carrito'));
      expect(
        find.text('${RentalPeriod(today, end).label} · 3 días'),
        findsOneWidget,
      );
      expect(find.text('\$540 MXN'), findsWidgets);
    },
  );
}
