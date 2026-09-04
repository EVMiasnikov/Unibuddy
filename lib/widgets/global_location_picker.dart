import 'package:country_state_city/country_state_city.dart'
    as csc;
import 'package:flutter/material.dart';

import '../services/location_service.dart';

class LocationSelection {
  final String country;
  final String countryCode;
  final String city;

  const LocationSelection({
    required this.country,
    required this.countryCode,
    required this.city,
  });
}

class GlobalLocationPicker extends StatefulWidget {
  final String? initialCountry;
  final String? initialCity;

  final ValueChanged<LocationSelection?> onChanged;

  const GlobalLocationPicker({
    super.key,
    this.initialCountry,
    this.initialCity,
    required this.onChanged,
  });

  @override
  State<GlobalLocationPicker> createState() =>
      _GlobalLocationPickerState();
}

class _GlobalLocationPickerState
    extends State<GlobalLocationPicker> {
  final LocationService _locationService =
      LocationService();

  List<csc.Country> _countries = [];
  List<csc.City> _cities = [];

  csc.Country? _selectedCountry;
  csc.City? _selectedCity;

  bool _loadingCountries = true;
  bool _loadingCities = false;

  @override
  void initState() {
    super.initState();

    _loadCountries();
  }

  Future<void> _loadCountries() async {
    final countries =
        await _locationService.getCountries();

    if (!mounted) {
      return;
    }

    csc.Country? initialCountry;

    if (widget.initialCountry != null &&
        widget.initialCountry!.trim().isNotEmpty) {
      final target =
          widget.initialCountry!.trim().toLowerCase();

      for (final country in countries) {
        if (country.name.toLowerCase() == target) {
          initialCountry = country;
          break;
        }
      }
    }

    setState(() {
      _countries = countries;
      _selectedCountry = initialCountry;
      _loadingCountries = false;
    });

    if (initialCountry != null) {
      await _loadCities(
        initialCountry.isoCode,
        initialCity: widget.initialCity,
      );
    }
  }

  Future<void> _loadCities(
  String countryCode, {
  String? initialCity,
}) async {
  setState(() {
    _loadingCities = true;
    _cities = [];
    _selectedCity = null;
  });

  final cities =
      await _locationService.getCities(
    countryCode,
  );

  if (!mounted) {
    return;
  }

  csc.City? selectedCity;

  if (initialCity != null &&
      initialCity.trim().isNotEmpty) {
    final target =
        initialCity.trim().toLowerCase();

    for (final city in cities) {
      if (city.name.toLowerCase() ==
          target) {
        selectedCity = city;
        break;
      }
    }
  }

  setState(() {
    _cities = cities;
    _selectedCity = selectedCity;
    _loadingCities = false;
  });

  if (_selectedCountry != null &&
      selectedCity != null) {
    _notifyParent();
  } else if (initialCity != null &&
      initialCity.trim().isNotEmpty) {
    // Old saved city is not found in the
    // standardized global city list.
    widget.onChanged(null);
  }
}

  void _notifyParent() {
    final country = _selectedCountry;
    final city = _selectedCity;

    if (country == null || city == null) {
      return;
    }

    widget.onChanged(
      LocationSelection(
        country: country.name,
        countryCode: country.isoCode,
        city: city.name,
      ),
    );
  }

  Future<void> _chooseCountry() async {
    if (_loadingCountries) {
      return;
    }

    final result =
        await showSearch<csc.Country?>(
      context: context,
      delegate: _CountrySearchDelegate(
        _countries,
      ),
    );

    if (result == null) {
      return;
    }

    setState(() {
      _selectedCountry = result;
      _selectedCity = null;
    });
    widget.onChanged(null);
    await _loadCities(
      result.isoCode,
    );
  }

  Future<void> _chooseCity() async {
    if (_selectedCountry == null ||
        _loadingCities) {
      return;
    }

    final result =
        await showSearch<csc.City?>(
      context: context,
      delegate: _CitySearchDelegate(
        _cities,
      ),
    );

    if (result == null) {
      return;
    }

    setState(() {
      _selectedCity = result;
    });

    _notifyParent();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: _chooseCountry,
          borderRadius:
              BorderRadius.circular(4),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Country *',
              border: OutlineInputBorder(),
              suffixIcon:
                  Icon(Icons.arrow_drop_down),
            ),
            child: Text(
              _loadingCountries
                  ? 'Loading countries...'
                  : _selectedCountry?.name ??
                      'Select country',
            ),
          ),
        ),

        const SizedBox(height: 16),

        InkWell(
          onTap: _selectedCountry == null
              ? null
              : _chooseCity,
          borderRadius:
              BorderRadius.circular(4),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'City *',
              border: OutlineInputBorder(),
              suffixIcon:
                  Icon(Icons.search),
            ),
            child: Text(
              _selectedCountry == null
                  ? 'Select a country first'
                  : _loadingCities
                      ? 'Loading cities...'
                      : _selectedCity?.name ??
                          'Select city',
            ),
          ),
        ),
      ],
    );
  }
}

class _CountrySearchDelegate
    extends SearchDelegate<csc.Country?> {
  final List<csc.Country> countries;

  _CountrySearchDelegate(
    this.countries,
  );

  @override
  String get searchFieldLabel =>
      'Search country';

  @override
  List<Widget>? buildActions(
    BuildContext context,
  ) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(
    BuildContext context,
  ) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  List<csc.Country> _results() {
    final q = query.trim().toLowerCase();

    if (q.isEmpty) {
      return countries;
    }

    return countries
        .where(
          (country) =>
              country.name
                  .toLowerCase()
                  .contains(q),
        )
        .toList();
  }

  @override
  Widget buildResults(
    BuildContext context,
  ) {
    return _buildList(context);
  }

  @override
  Widget buildSuggestions(
    BuildContext context,
  ) {
    return _buildList(context);
  }

  Widget _buildList(
    BuildContext context,
  ) {
    final results = _results();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final country = results[index];

        return ListTile(
          title: Text(country.name),
          subtitle:
              Text(country.isoCode),
          onTap: () {
            close(
              context,
              country,
            );
          },
        );
      },
    );
  }
}

class _CitySearchDelegate
    extends SearchDelegate<csc.City?> {
  final List<csc.City> cities;

  _CitySearchDelegate(
    this.cities,
  );

  @override
  String get searchFieldLabel =>
      'Search city';

  @override
  List<Widget>? buildActions(
    BuildContext context,
  ) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(
    BuildContext context,
  ) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  List<csc.City> _results() {
    final q = query.trim().toLowerCase();

    if (q.isEmpty) {
      return cities;
    }

    return cities
        .where(
          (city) =>
              city.name
                  .toLowerCase()
                  .contains(q),
        )
        .toList();
  }

  @override
  Widget buildResults(
    BuildContext context,
  ) {
    return _buildList(context);
  }

  @override
  Widget buildSuggestions(
    BuildContext context,
  ) {
    return _buildList(context);
  }

  Widget _buildList(
    BuildContext context,
  ) {
    final results = _results();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final city = results[index];

        return ListTile(
          title: Text(city.name),
          onTap: () {
            close(
              context,
              city,
            );
          },
        );
      },
    );
  }
}