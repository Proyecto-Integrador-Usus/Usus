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

  for (final wide in [false, true]) {
    testWidgets(
      'Carrito solo visible tras iniciar sesión en ${wide ? 'escritorio' : 'móvil'}',
      (tester) async {
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

        // Sin sesión iniciada, el botón de carrito no aparece.
        expect(find.byTooltip('Carrito'), findsNothing);
        expect(find.text('Agregar al carrito'), findsNothing);

        // Registrar usuario para iniciar sesión.
        await tap(find.text(wide ? 'Crear cuenta' : 'Crear'));
        final fields = find.byType(TextFormField);
        final values = [
          'Juan',
          'Arriaga',
          'Av. Universidad 940, Centro, Aguascalientes',
          'juan@example.org',
          'Clave1234',
          'Clave1234',
        ];
        for (var i = 0; i < values.length; i++) {
          await tester.enterText(fields.at(i), values[i]);
        }
        await tap(find.byType(ElevatedButton));

        // Con sesión iniciada, el botón de carrito es visible.
        expect(find.byTooltip('Carrito'), findsOneWidget);

        // Agregar primer artículo al carrito.
        await tap(find.text('Agregar al carrito').first);
        await tap(find.byTooltip('Carrito'));

        expect(find.text('Carrito de rentas'), findsOneWidget);
        expect(find.text('Taladro percutor profesional'), findsOneWidget);
        expect(find.text('\$180 MXN'), findsWidgets);

        // Aumentar días de renta a 2 días.
        await tap(find.byTooltip('Aumentar Días'));
        expect(find.text('2 días'), findsOneWidget);
        expect(find.text('\$360 MXN'), findsWidgets);

        // Vaciar carrito.
        await tap(find.text('Vaciar'));
        expect(find.text('Tu carrito de rentas está vacío'), findsOneWidget);
      },
    );
  }

  for (final wide in [false, true]) {
    testWidgets(
      'Publicar artículo solo disponible tras iniciar sesión en ${wide ? 'escritorio' : 'móvil'}',
      (tester) async {
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

        final publishButton = wide
            ? find.text('Publicar artículo')
            : find.byTooltip('Publicar artículo');

        // Sin sesión iniciada, el botón + / Publicar artículo no aparece.
        expect(publishButton, findsNothing);

        // Registrar usuario para iniciar sesión.
        await tap(find.text(wide ? 'Crear cuenta' : 'Crear'));
        final authFields = find.byType(TextFormField);
        final authValues = [
          'Juan',
          'Arriaga',
          'Av. Universidad 940, Centro, Aguascalientes',
          'juan.pub@example.org',
          'Clave1234',
          'Clave1234',
        ];
        for (var i = 0; i < authValues.length; i++) {
          await tester.enterText(authFields.at(i), authValues[i]);
        }
        await tap(find.byType(ElevatedButton));

        // Abrir formulario de publicación.
        await tap(publishButton);
        expect(find.text('Publicar artículo en renta'), findsOneWidget);

        // Validar campos vacíos (título y descripción).
        await tap(find.byType(ElevatedButton));
        expect(find.text('Completa este campo.'), findsNWidgets(2));

        // Llenar título, descripción, precio y depósito.
        final formFields = find.byType(TextFormField);
        // 0: URL de imagen, 1: Título, 2: Descripción, 3: Precio, 4: Depósito, 5: Ubicación
        await tester.enterText(
          formFields.at(1),
          'Tablón rectangular para 8 personas',
        );
        await tester.enterText(
          formFields.at(2),
          'Tablón plegable resistente para eventos y fiestas con mantel.',
        );
        await tester.enterText(formFields.at(3), '150');
        await tester.enterText(formFields.at(4), '300');

        await tap(find.text('Zona Norte'));
        await tap(find.byType(ElevatedButton));

        // El nuevo producto aparece en el catálogo principal.
        expect(find.text('Tablón rectangular para 8 personas'), findsOneWidget);
      },
    );
  }
}
