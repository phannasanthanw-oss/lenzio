// Widgets ใช้ร่วมกันทั่วแอป: Tag, ChipBar, SearchField, PageTitle, SectionTitle, SortButton
import 'package:flutter/material.dart';
import '../core/constants.dart';

/// ป้ายกำกับขนาดเล็กแบบมนเช่น "Full frame", "Sony"
class Tag extends StatelessWidget {
  final String text;
  final Color color;
  const Tag(this.text, {super.key, this.color = kPrimary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

/// แถบ filter chips แนวนอน มีตัวเลือก "ทั้งหมด" เป็นตัวแรก
class ChipBar extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onChanged;
  final String allLabel;
  const ChipBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.allLabel = 'ทั้งหมด',
  });

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, bool on, VoidCallback tap) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(label),
            selected: on,
            showCheckmark: false,
            selectedColor: kPrimary,
            labelStyle: TextStyle(color: on ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
            side: BorderSide(color: on ? kPrimary : const Color(0xFFD9DEE8)),
            backgroundColor: Colors.white,
            onSelected: (_) => tap(),
          ),
        );
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          chip(allLabel, selected == null, () => onChanged(null)),
          for (final o in options) chip(o, selected == o, () => onChanged(o)),
        ],
      ),
    );
  }
}

/// ช่องค้นหา — กด Enter/Search แล้วเรียก onSubmitted
class SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onSubmitted;
  const SearchField({super.key, required this.hint, required this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    return TextField(
      textInputAction: TextInputAction.search,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF1F3F7),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }
}

/// หัวข้อหน้าจอขนาดใหญ่ (24 px)
class PageTitle extends StatelessWidget {
  final String text;
  const PageTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Text(text, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      );
}

/// หัวข้อส่วนย่อยในหน้า (17 px)
class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      );
}

/// ปุ่มเปิด popup เลือกวิธีเรียงลำดับ
class SortButton extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final String prefix;
  const SortButton({super.key, required this.value, required this.onChanged, this.prefix = 'เรียง: '});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final e in kSortLabels.entries) PopupMenuItem(value: e.key, child: Text(e.value)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD9DEE8)), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.swap_vert, size: 16),
          const SizedBox(width: 4),
          Text('$prefix${kSortLabels[value]}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

