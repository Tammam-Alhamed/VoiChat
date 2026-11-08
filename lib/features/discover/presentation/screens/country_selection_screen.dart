import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/countries.dart';
import '../../../../core/helpers/toast_helper.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/themes/app_dark_colors.dart';
import '../../../../core/widgets/app_search_field.dart';

import 'package:get/get.dart';
import '../../../session/presentation/controllers/session_controller.dart';
import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/get_country_online_counts.dart';

/// The floor the filter must never drop below — the person can remove any
/// selected country as long as at least this many stay checked. See
/// [toggleCountry].
const int _kMinSelected = 1;

/// How many countries are pre-checked the first time the picker opens with
/// no existing filter: the user's own country + the top (_kDefaultSelectedCount
/// - 1) countries by online users right now. See [_applyDefaultSelection].
const int _kDefaultSelectedCount = 3;

class CountrySelectionScreen extends StatefulWidget {
  final String? initialValue;

  const CountrySelectionScreen({super.key, this.initialValue});

  @override
  State<CountrySelectionScreen> createState() => _CountrySelectionScreenState();
}

class _CountrySelectionScreenState extends State<CountrySelectionScreen> {
  static const Set<String> _recommendedCodes = {
    'US',
    'GB',
    'CA',
    'AU',
    'DE',
    'FR',
    'IT',
    'ES',
    'PT',
    'NL',
    'SA',
    'AE',
    'TR',
    'LB',
    'SY',
  };

  late List<Map<String, dynamic>> allCountries;
  List<Map<String, dynamic>> selectedCountries = [];

  /// True once we've either applied the default selection or determined we
  /// don't need to (an initialValue was already provided) — guards against
  /// re-applying defaults if _loadOnlineCounts ever re-runs.
  bool _defaultsApplied = false;

  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredCountries = [];
  bool isSearching = false;
  bool _isLoadingCounts = true;

  final Color primaryPurple = const Color(0xFFA055F5);

  @override
  void initState() {
    super.initState();
    _buildCountryList();
    _parseInitialValue();
    searchController.addListener(_onSearchChanged);
    _loadOnlineCounts();
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _buildCountryList() {
    allCountries = MyCountries.allCountriesData.map((c) {
      final code = c['code']!;
      return {
        'name': c['name'],
        'code': code,
        'count': 0,
        'isChecked': false,
        'isRecommended': _recommendedCodes.contains(code),
      };
    }).toList();
  }

  void _parseInitialValue() {
    if (widget.initialValue == null || widget.initialValue!.isEmpty) return;

    final codes = widget.initialValue!.split(',').map((e) => e.trim()).toSet();
    for (var country in allCountries) {
      if (codes.contains(country['code'])) {
        country['isChecked'] = true;
        selectedCountries.add(country);
      }
    }
    // A filter was already set previously — keep it as-is, don't overwrite
    // it with the default selection once counts load.
    _defaultsApplied = true;
  }

  Map<String, dynamic>? _findCountry(String code) {
    for (final c in allCountries) {
      if (c['code'] == code) return c;
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────
  // Real online counts per country
  // ─────────────────────────────────────────────────────────────

  Future<void> _loadOnlineCounts() async {
    final result = await sl<GetCountryOnlineCounts>()(const NoParams());
    if (!mounted) return;

    switch (result) {
      case Ok(data: final counts):
        setState(() {
          for (final country in allCountries) {
            country['count'] = counts[country['code']] ?? 0;
          }
          _applyDefaultSelection(counts);
          _isLoadingCounts = false;
        });
      case Err():
        // Offline or a server hiccup: still pre-select the default
        // countries (country order as the ranking) instead of leaving the
        // picker with nothing selected.
        setState(() {
          _applyDefaultSelection(const {});
          _isLoadingCounts = false;
        });
    }
  }

  /// Pre-checks exactly [_kDefaultSelectedCount] countries the first time
  /// the picker opens with no existing filter: the user's own country +
  /// the top countries by online users right now (deduplicated — if my
  /// country already IS one of the top ones, the next-highest fills that
  /// slot instead). No-ops if an initialValue was already provided (see
  /// _parseInitialValue) or if this has already run once.
  void _applyDefaultSelection(Map<String, int> counts) {
    if (_defaultsApplied) return;
    _defaultsApplied = true;

    final myCountryCode = Get.find<SessionController>().session?.country;

    final sortedCodes = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));

    final seen = <String>{};
    void selectIfPossible(String? code) {
      if (seen.length >= _kDefaultSelectedCount) return;
      if (code == null || code.isEmpty || seen.contains(code)) return;
      final match = _findCountry(code);
      if (match == null || match['isChecked'] == true) return;
      match['isChecked'] = true;
      selectedCountries.add(match);
      seen.add(code);
    }

    selectIfPossible(myCountryCode);
    for (final code in sortedCodes) {
      if (seen.length >= _kDefaultSelectedCount) break;
      selectIfPossible(code);
    }
    // Still short (e.g. no online-count data at all) — fall back to the
    // first countries in the list so the default count is always met.
    for (final country in allCountries) {
      if (seen.length >= _kDefaultSelectedCount) break;
      selectIfPossible(country['code'] as String);
    }
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  void _onSearchChanged() {
    final query = searchController.text.trim();
    setState(() {
      isSearching = query.isNotEmpty;
      if (isSearching) {
        filteredCountries = allCountries
            .where(
              (c) => (c['name'] as String).toLowerCase().contains(
                query.toLowerCase(),
              ),
            )
            .toList();
      }
    });
  }

  void toggleCountry(Map<String, dynamic> country) {
    final bool isCurrentlyChecked = country['isChecked'] as bool;

    // Unchecking would drop below the floor (at least one country must
    // always stay selected) — block it.
    if (isCurrentlyChecked && selectedCountries.length <= _kMinSelected) {
      ToastHelper.showInfoToast(
        message: 'Select at least $_kMinSelected country',
      );
      return;
    }

    setState(() {
      final newStatus = !isCurrentlyChecked;
      country['isChecked'] = newStatus;

      if (newStatus) {
        selectedCountries.add(country);
      } else {
        selectedCountries.removeWhere((c) => c['code'] == country['code']);
      }
    });
  }

  void applySelection() {
    if (selectedCountries.isEmpty) {
      Navigator.pop(context, null);
    } else {
      final result = selectedCountries.map((c) => c['code']).join(',');
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.shellBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: context.shellTextPrimary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppSearchField(
                      controller: searchController,
                      hintText: "Search country",
                    ),
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: ListView(
                physics: const ClampingScrollPhysics(),
                children: [
                  if (!isSearching) ...[
                    // 1. Selected Section — starts pre-filled with the
                    // default 2 (see _applyDefaultSelection) instead of a
                    // separate "Suggested" row above it.
                    if (selectedCountries.isNotEmpty) ...[
                      _buildSectionHeader("Selected"),
                      ...selectedCountries.map((c) => _buildCountryItem(c)),
                    ],

                    // 2. Recommended Section
                    _buildSectionHeader("Recommended"),
                    ...allCountries
                        .where(
                          (c) =>
                              c['isRecommended'] == true &&
                              c['isChecked'] == false,
                        )
                        .map((c) => _buildCountryItem(c)),

                    // 3. All Countries Section
                    _buildSectionHeader("All Countries"),
                    ...allCountries
                        .where(
                          (c) =>
                              c['isRecommended'] == false &&
                              c['isChecked'] == false,
                        )
                        .map((c) => _buildCountryItem(c)),
                  ] else ...[
                    // Search results
                    ...filteredCountries.map((c) => _buildCountryItem(c)),
                    if (filteredCountries.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text(
                            'No countries found',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),

            // Apply button
            _buildApplyButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildApplyButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: GestureDetector(
        onTap: applySelection,
        child: Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B3EE8), Color(0xFFC769EE)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              selectedCountries.isEmpty ? "Clear Filter" : "Apply",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountryItem(Map<String, dynamic> country) {
    final bool checked = country['isChecked'] as bool;
    final String code = country['code'] as String;
    final int count = country['count'] as int? ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: () => toggleCountry(country),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: checked ? primaryPurple : Colors.transparent,
                border: Border.all(color: primaryPurple, width: 1.5),
              ),
              child: checked
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            ClipOval(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CountryFlag.fromCountryCode(code),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                country['name'] as String,
                style: TextStyle(
                  fontSize: 16,
                  color: context.shellTextPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (!_isLoadingCounts) ...[
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _formatCount(count),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 10),
            ],
          ],
        ),
      ),
    );
  }
}
