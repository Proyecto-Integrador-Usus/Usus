// Fechas de calendario de RENTA, sin hora ni conversión de zona horaria.
class RentalPeriod {
  RentalPeriod(DateTime from, DateTime through)
    : start = DateTime.utc(from.year, from.month, from.day),
      end = DateTime.utc(through.year, through.month, through.day) {
    if (end.isBefore(start)) {
      throw ArgumentError('El fin debe ser igual o posterior al inicio.');
    }
  }

  final DateTime start;
  final DateTime end;
  int get days => end.difference(start).inDays + 1;

  String _iso(DateTime date) => date.toIso8601String().split('T').first;
  Map<String, String> toJson() => {
    'fecha_inicio': _iso(start),
    'fecha_fin': _iso(end),
  };
  String _display(DateTime date) => _iso(date).split('-').reversed.join('/');
  String get label =>
      start == end ? _display(start) : '${_display(start)} – ${_display(end)}';
}
