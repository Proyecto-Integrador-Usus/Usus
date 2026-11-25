import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/auth_repository.dart';

enum AccountMode { login, register }

class AccountPage extends StatefulWidget {
  const AccountPage({
    super.key,
    required this.repository,
    required this.initialMode,
  });

  final AuthRepository repository;
  final AccountMode initialMode;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _form = GlobalKey<FormState>();
  late AccountMode _mode = widget.initialMode;
  final _address = TextEditingController();
  bool _busy = false;
  bool _visible = false;
  String? _error;
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  bool get _register => _mode == AccountMode.register;
  String get _action => _register ? 'Crear cuenta' : 'Iniciar sesión';

  @override
  void dispose() {
    for (final field in [
      _first,
      _last,
      _address,
      _email,
      _password,
      _confirmation,
    ]) {
      field.dispose();
    }
    super.dispose();
  }

  void _changeMode() {
    _form.currentState?.reset();
    _password.clear();
    _confirmation.clear();
    setState(() {
      _mode = _register ? AccountMode.login : AccountMode.register;
      _visible = false;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final account = _register
          ? await widget.repository.register(
              AccountProfile(
                _first.text.trim(),
                _last.text.trim(),
                _email.text.trim(),
                _address.text.trim(),
              ),
              _password.text,
            )
          : await widget.repository.login(_email.text.trim(), _password.text);
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        Navigator.of(context).pop(account);
      }
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No se pudo completar la solicitud. Intenta de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Completa este campo.' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 840;
            final back = TextButton.icon(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Volver al catálogo'),
              style: TextButton.styleFrom(foregroundColor: AppColors.espresso),
            );
            final fields = Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: _buildForm(context),
              ),
            );
            if (wide) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Expanded(flex: 5, child: _RentalPhoto()),
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: back,
                          ),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, pane) {
                                return SingleChildScrollView(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: pane.maxHeight,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 24,
                                      ),
                                      child: fields,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(alignment: Alignment.centerLeft, child: back),
                      const SizedBox(
                        height: 130,
                        child: _RentalPhoto(compact: true),
                      ),
                      const SizedBox(height: 24),
                      fields,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _nameField(
    TextEditingController controller,
    String label,
    String autofill,
  ) => TextFormField(
    controller: controller,
    validator: _required,
    autofillHints: [autofill],
    textInputAction: TextInputAction.next,
    textCapitalization: TextCapitalization.words,
    decoration: InputDecoration(labelText: label),
  );

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          fillColor: AppColors.white,
          floatingLabelStyle: const TextStyle(
            color: AppColors.espresso,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(_action, style: theme.textTheme.headlineLarge),
            ),
            const SizedBox(height: 8),
            Text(
              _register
                  ? 'Una cuenta para rentar y publicar artículos.'
                  : 'Entra con tu correo y contraseña.',
              style: const TextStyle(color: AppColors.espresso, fontSize: 16),
            ),
            const SizedBox(height: 28),
            if (_register) ...[
              LayoutBuilder(
                builder: (context, constraints) {
                  final first = _nameField(
                    _first,
                    'Nombre',
                    AutofillHints.givenName,
                  );
                  final last = _nameField(
                    _last,
                    'Apellido',
                    AutofillHints.familyName,
                  );
                  if (constraints.maxWidth < 400) {
                    return Column(
                      children: [first, const SizedBox(height: 12), last],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: first),
                      const SizedBox(width: 12),
                      Expanded(child: last),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _address,
                keyboardType: TextInputType.streetAddress,
                autofillHints: const [AutofillHints.fullStreetAddress],
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  hintText: 'Calle, número, colonia y ciudad',
                ),
                validator: _required,
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
              ),
              validator: (v) =>
                  RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                      .hasMatch(v?.trim() ?? '')
                  ? null
                  : 'Escribe un correo válido.',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: !_visible,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                suffixIcon: IconButton(
                  tooltip: _visible
                      ? 'Ocultar contraseña'
                      : 'Mostrar contraseña',
                  icon: Icon(
                    _visible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () => setState(() => _visible = !_visible),
                ),
              ),
              validator: (v) => _register && (v?.length ?? 0) < 8
                  ? 'Usa al menos 8 caracteres.'
                  : _required(v),
              onFieldSubmitted: (_) {
                if (!_register) _submit();
              },
            ),
            if (_register) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmation,
                obscureText: !_visible,
                enableSuggestions: false,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Confirmar contraseña',
                ),
                validator: (v) => v == _password.text
                    ? null
                    : 'Las contraseñas deben coincidir.',
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _busy ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mustard,
                foregroundColor: AppColors.espresso,
                elevation: 0,
                minimumSize: const Size.fromHeight(50),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_busy ? 'Un momento…' : _action),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: _busy ? null : _changeMode,
              style: TextButton.styleFrom(foregroundColor: AppColors.espresso),
              child: Text(
                _register
                    ? 'Ya tengo cuenta · Iniciar sesión'
                    : 'Soy nuevo · Crear cuenta',
              ),
            ),
            const Divider(height: 28, color: AppColors.border),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppColors.espresso,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Demo local. Usa datos de ejemplo. Las cuentas se borran al reiniciar la app.',
                    style: TextStyle(fontSize: 12, height: 1.45),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RentalPhoto extends StatelessWidget {
  const _RentalPhoto({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final padding = compact ? 16.0 : 32.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/auth/entrega-taladro.webp',
            fit: BoxFit.cover,
            alignment: const Alignment(0, -.15),
            excludeFromSemantics: true,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black38,
                  Colors.transparent,
                  compact ? Colors.transparent : Colors.black87,
                ],
                stops: const [0, .48, 1],
              ),
            ),
          ),
          Positioned(
            top: padding,
            left: padding,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.mustard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.swap_horiz_rounded,
                    color: AppColors.espresso,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 9),
                const Text(
                  'usus',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                  ),
                ),
              ],
            ),
          ),
          if (!compact && MediaQuery.sizeOf(context).height >= 460)
            Positioned(
              left: padding,
              right: padding,
              bottom: padding,
              child: const Text(
                'Renta lo que necesitas.\nComparte lo que tienes.',
                style: TextStyle(
                  fontFamily: 'serif',
                  color: AppColors.white,
                  fontSize: 36,
                  height: 1.12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
