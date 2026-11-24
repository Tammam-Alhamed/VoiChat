import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/widgets/settings_widgets.dart';
import 'chat_with_support.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  static const _purple = Color(0xFF5B35C8);
  static const _deep = Color(0xFF211052);
  static const _muted = Color(0xFF6E6B80);
  static const _answerStyle = TextStyle(
    fontSize: 14,
    height: 1.65,
    color: Color(0xFF555267),
  );

  late final Future<List<_FaqSection>> _sections = _loadSections();
  final _searchController = TextEditingController();
  String _query = '';

  Future<List<_FaqSection>> _loadSections() async {
    final language = Get.locale?.languageCode ?? 'en';
    String json;
    try {
      json = await rootBundle.loadString('assets/help/faq_$language.json');
    } catch (_) {
      json = await rootBundle.loadString('assets/help/faq.json');
    }
    return (jsonDecode(json) as List<dynamic>)
        .map((value) => _FaqSection.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ColoredBox(
          color: const Color(0xFFF7F6FC),
          child: FutureBuilder<List<_FaqSection>>(
            future: _sections,
            builder: (context, snapshot) {
              final query = _query.trim().toLowerCase();
              final sections = (snapshot.data ?? const <_FaqSection>[])
                  .map((section) => section.filtered(query))
                  .where((section) => section.items.isNotEmpty)
                  .toList();
              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _header(),
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: -19,
                        child: _searchBox(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(5, 0, 5, 5),
                          child: Text(
                            'faq_search_hint_detail'.tr,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: _muted,
                            ),
                          ),
                        ),
                        if (query.isEmpty) _introduction(),
                        if (snapshot.hasError)
                          _panel(Text('faq_load_error'.tr))
                        else if (!snapshot.hasData)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (sections.isEmpty)
                          _panel(Text('faq_no_results'.tr))
                        else
                          for (final section in sections)
                            _section(section, query),
                        _footer(),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header() => Container(
    padding: const EdgeInsets.fromLTRB(0, 14, 0, 47),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4827AE), Color(0xFF6336CF), Color(0xFF813FE2)],
      ),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      boxShadow: [
        BoxShadow(
          color: Color(0x2043229B),
          blurRadius: 28,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 56,
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back_ios_new),
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'voichat'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: SettingsMetrics.screenTitleSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 17),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            'help_faq'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 31,
              fontWeight: FontWeight.w800,
              height: 1.17,
            ),
          ),
        ),
        const SizedBox(height: 9),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            'help_faq_description'.tr,
            style: const TextStyle(
              color: Color(0xFFF0EAFF),
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _searchBox() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE4DEF2)),
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D2B1B5A),
          blurRadius: 22,
          offset: Offset(0, 7),
        ),
      ],
    ),
    child: Row(
      children: [
        const Icon(Icons.search, size: 22, color: _purple),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            style: const TextStyle(fontSize: 15, color: Color(0xFF201B35)),
            decoration: InputDecoration(
              hintText: 'faq_search_hint'.tr,
              hintStyle: const TextStyle(color: Color(0xFF9290A2)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        if (_query.isNotEmpty)
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() => _query = '');
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFF1ECFF),
              foregroundColor: _purple,
            ),
            child: Text('clear'.tr),
          ),
      ],
    ),
  );

  Widget _introduction() => _panel(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'faq_introduction'.tr,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _deep,
          ),
        ),
        const SizedBox(height: 10),
        Text('faq_intro_body'.tr, style: _answerStyle),
        const SizedBox(height: 8),
        Text('faq_intro_support'.tr, style: _answerStyle),
      ],
    ),
  );

  Widget _section(_FaqSection section, String query) => _panel(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          section.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _deep,
          ),
        ),
        const SizedBox(height: 11),
        const Divider(height: 1, color: Color(0xFFF0EDF7)),
        for (final item in section.items)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                key: ValueKey('${section.title}:${item.question}:$query'),
                initiallyExpanded: query.isNotEmpty,
                tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 13),
                iconColor: _purple,
                collapsedIconColor: _purple,
                backgroundColor: Colors.white,
                collapsedBackgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Color(0xFFDED3FF)),
                  borderRadius: BorderRadius.circular(12),
                ),
                collapsedShape: RoundedRectangleBorder(
                  side: const BorderSide(color: Color(0xFFEFEDF5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text(
                  item.question,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                    color: Color(0xFF27213B),
                  ),
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(item.answer, style: _answerStyle),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );

  Widget _panel(Widget child) => Container(
    margin: const EdgeInsets.only(top: 14),
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFEEEBF6)),
      borderRadius: BorderRadius.circular(17),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0824154B),
          blurRadius: 18,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: child,
  );

  Widget _footer() => Padding(
    padding: const EdgeInsets.fromLTRB(12, 25, 12, 8),
    child: Column(
      children: [
        TextButton(
          onPressed: () => Get.to(() => const SupportChatScreen()),
          child: Text(
            'faq_footer_support'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF7A7A7A),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'faq_footer_copyright'.tr,
          style: const TextStyle(fontSize: 12, color: Color(0xFF898598)),
        ),
      ],
    ),
  );
}

class _FaqSection {
  const _FaqSection(this.title, this.items);
  final String title;
  final List<_FaqItem> items;

  factory _FaqSection.fromJson(Map<String, dynamic> json) => _FaqSection(
    json['title'] as String,
    (json['items'] as List<dynamic>)
        .map((item) => _FaqItem.fromJson(item as Map<String, dynamic>))
        .toList(),
  );

  _FaqSection filtered(String query) => query.isEmpty
      ? this
      : _FaqSection(
          title,
          items
              .where(
                (item) =>
                    item.question.toLowerCase().contains(query) ||
                    item.answer.toLowerCase().contains(query),
              )
              .toList(),
        );
}

class _FaqItem {
  const _FaqItem(this.question, this.answer);
  final String question;
  final String answer;
  factory _FaqItem.fromJson(Map<String, dynamic> json) =>
      _FaqItem(json['question'] as String, json['answer'] as String);
}
