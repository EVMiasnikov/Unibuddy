import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Adds buddy-request events to the device's native calendar.
class CalendarService {
  final DeviceCalendarPlugin _plugin = DeviceCalendarPlugin();
  bool _timezonesInitialized = false;

  void _ensureTimezonesInitialized() {
    if (_timezonesInitialized) return;
    tz_data.initializeTimeZones();
    _timezonesInitialized = true;
  }

  Future<bool> _ensurePermissions() async {
    var permissionsResult = await _plugin.hasPermissions();
    if (permissionsResult.isSuccess && permissionsResult.data == true) {
      return true;
    }

    permissionsResult = await _plugin.requestPermissions();
    return permissionsResult.isSuccess && permissionsResult.data == true;
  }

  Future<Calendar?> _findWritableCalendar() async {
    final calendarsResult = await _plugin.retrieveCalendars();
    if (!calendarsResult.isSuccess || calendarsResult.data == null) {
      return null;
    }

    for (final calendar in calendarsResult.data!) {
      if (calendar.isReadOnly != true) {
        return calendar;
      }
    }

    return null;
  }

  /// Adds an event to the device calendar. Returns an error message on
  /// failure, or null on success.
  Future<String?> addEvent({
    required String title,
    required String description,
    required String location,
    required DateTime start,
    required Duration duration,
  }) async {
    _ensureTimezonesInitialized();

    final hasPermission = await _ensurePermissions();
    if (!hasPermission) {
      return 'Calendar permission was not granted.';
    }

    final calendar = await _findWritableCalendar();
    if (calendar == null) {
      return 'No writable calendar was found on this device.';
    }

    final localTz = tz.local;
    final tzStart = tz.TZDateTime.from(start, localTz);
    final tzEnd = tz.TZDateTime.from(start.add(duration), localTz);

    final event = Event(
      calendar.id,
      title: title,
      description: description,
      location: location,
      start: tzStart,
      end: tzEnd,
    );

    final createResult = await _plugin.createOrUpdateEvent(event);
    if (createResult == null || !createResult.isSuccess) {
      return createResult?.errors.map((e) => e.errorMessage).join(', ') ??
          'Failed to add the event to your calendar.';
    }

    return null;
  }
}