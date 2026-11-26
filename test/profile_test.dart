import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usus/core/settings/app_settings.dart';
import 'package:usus/features/auth/data/auth_repository.dart';
import 'package:usus/features/cart/data/cart_controller.dart';
import 'package:usus/main.dart';

void main() {
  for (final wide in [false, true]) {
    testWidgets(
      'Perfil, favoritos y preferencias en ${wide ? 'escritorio' : 'móvil'}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = wide
            ? const Size(1280, 900)
            : const Size(390, 844);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        final preferences = await SharedPreferences.getInstance();
        final auth = DemoAuthRepository();
        await auth.register(
          const AccountProfile(
            'Ana',
            'Luna',
            'ana@example.org',
            'Calle Luna 12',
          ),
          'Clave1234',
        );
        await tester.pumpWidget(UsusApp(auth: auth, preferences: preferences));
        await tester.pumpAndSettle();

        Future<void> tap(Finder target) async {
          await tester.ensureVisible(target);
          await tester.tap(target);
          await tester.pumpAndSettle();
        }

        Future<void> section(String name) async {
          if (!wide) await tap(find.byTooltip('Menú del perfil'));
          await tap(find.text(name).first);
        }

        await tap(
          wide ? find.text('Iniciar sesión') : find.byTooltip('Iniciar sesión'),
        );
        await tester.enterText(
          find.byType(TextFormField).first,
          'ana@example.org',
        );
        await tester.enterText(find.byType(TextFormField).last, 'Clave1234');
        await tap(find.byType(ElevatedButton));
        await tap(find.byTooltip('Guardar en favoritos').first);
        await tap(find.byTooltip('Mi perfil'));
        expect(find.text('Ana Luna'), findsOneWidget);
        expect(find.text('Calle Luna 12'), findsOneWidget);

        await tap(find.widgetWithText(ListTile, '1 artículo guardado'));
        expect(find.text('Taladro percutor profesional'), findsOneWidget);
        await tap(find.byTooltip('Quitar de favoritos'));
        expect(find.text('Aún no tienes favoritos'), findsOneWidget);

        await section('Ayuda');
        await tap(
          find.widgetWithText(
            ListTile,
            'Consulta cómo rentar, guardar artículos y elegir la entrega.',
          ),
        );
        await tap(find.text('¿Cómo elijo las fechas de renta?'));
        expect(
          find.textContaining('El periodo incluye ambos días'),
          findsOneWidget,
        );
        await section('Cupones');
        expect(find.text('Sin cupones disponibles'), findsOneWidget);
        await section('Términos y condiciones');
        expect(find.text('Uso de la demostración'), findsOneWidget);
        await section('Acerca de');
        expect(find.text('Acerca de Usus'), findsOneWidget);
        await section('Configuración');
        await tap(find.text('Tema oscuro'));
        expect(
          Theme.of(tester.element(find.text('Tema oscuro'))).brightness,
          Brightness.dark,
        );
        await tap(find.text('Recomendados'));
        await tap(find.text('Menor precio').last);
        await tap(find.text('Recoger con el arrendador'));
        await tap(find.text('Envío a domicilio').last);
        final saved = AppSettings(preferences);
        expect(saved.darkMode, isTrue);
        expect(saved.catalogSort, 'Menor precio');
        expect(saved.preferredDelivery, DeliveryMethod.delivery);
        saved.dispose();
        await tap(find.byTooltip('Volver al inicio'));
        expect(
          Theme.of(tester.element(find.byTooltip('Carrito'))).brightness,
          Brightness.dark,
        );
        expect(find.text('Menor precio'), findsOneWidget);
        await tap(find.text('Agregar al carrito').first);
        await tap(find.byTooltip('Carrito'));
        final delivery = tester.widget<RadioGroup<DeliveryMethod>>(
          find.byType(RadioGroup<DeliveryMethod>),
        );
        expect(delivery.groupValue, DeliveryMethod.delivery);
      },
    );
  }
}
