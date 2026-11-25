import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usus/features/auth/data/auth_repository.dart';
import 'package:usus/main.dart';

void main() {
  for (final wide in [false, true]) {
    testWidgets('Registro y acceso en ${wide ? 'escritorio' : 'móvil'}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = wide
          ? const Size(1280, 900)
          : const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(UsusApp(auth: DemoAuthRepository()));
      await tester.pumpAndSettle();

      Future<void> tap(Finder target) async {
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      final fields = find.byType(TextFormField);
      final submit = find.byType(ElevatedButton);
      await tap(find.text(wide ? 'Crear cuenta' : 'Crear'));
      expect(find.text('Quiero publicar'), findsNothing);
      final values = [
        'Ana',
        'Luna',
        '   ',
        'ana@example.org',
        'Clave1234',
        'Clave1234',
      ];
      for (var i = 0; i < values.length; i++) {
        await tester.enterText(fields.at(i), values[i]);
      }
      await tap(submit);
      expect(find.text('Completa este campo.'), findsOneWidget);
      await tester.enterText(fields.at(2), 'Calle Luna 12, Centro, CDMX');
      final publish = wide
          ? find.text('Publicar artículo')
          : find.byTooltip('Publicar artículo');
      await tap(submit);
      expect(publish, findsOneWidget);
      await tap(find.byType(PopupMenuButton<String>));
      await tap(find.text('Cerrar sesión'));
      await tap(
        wide ? find.text('Iniciar sesión') : find.byTooltip('Iniciar sesión'),
      );
      expect(fields, findsNWidgets(2));
      await tester.enterText(fields.first, 'ANA@example.org');
      await tester.enterText(fields.last, 'Clave1234');
      await tester.enterText(fields.last, 'Incorrecta');
      await tap(submit);
      expect(find.text('Revisa tu correo y contraseña.'), findsOneWidget);
      await tester.enterText(fields.last, 'Clave1234');
      await tap(submit);
      expect(find.byTooltip('Carrito'), findsOneWidget);
      expect(publish, findsOneWidget);
    });
  }
}
