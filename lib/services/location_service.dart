import 'package:country_state_city/country_state_city.dart' as csc;

class LocationService {
  List<csc.Country>? _countriesCache;

  final Map<String, List<csc.City>> _citiesCache = {};

  /// Load all countries.
  Future<List<csc.Country>> getCountries() async {
    if (_countriesCache != null) {
      return _countriesCache!;
    }

    final countries = await csc.getAllCountries();

    countries.sort(
      (a, b) => a.name.compareTo(b.name),
    );

    _countriesCache = countries;

    return countries;
  }

  /// Load all cities belonging to one country.
  Future<List<csc.City>> getCities(
    String countryCode,
  ) async {
    if (_citiesCache.containsKey(countryCode)) {
      return _citiesCache[countryCode]!;
    }

    final cities =
        await csc.getCountryCities(countryCode);

    cities.sort(
      (a, b) => a.name.compareTo(b.name),
    );

    _citiesCache[countryCode] = cities;

    return cities;
  }
}