// หน้ารายการเลนส์ทั้งหมด — ค้นหาและกรองแบรนด์
import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../widgets/async_view.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/image_widgets.dart';
import '../../widgets/rating_widgets.dart';

class LensListPage extends StatefulWidget {
  const LensListPage({super.key});
  @override
  State<LensListPage> createState() => _LensListPageState();
}

class _LensListPageState extends State<LensListPage> {
  String? _brand;
  String _q = '';

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Align(alignment: Alignment.centerLeft, child: PageTitle('เลนส์')),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: SearchField(hint: 'ค้นหาเลนส์', onSubmitted: (v) => setState(() => _q = v.trim())),
      ),
      ChipBar(options: kBrands, selected: _brand, onChanged: (v) => setState(() => _brand = v)),
      const SizedBox(height: 6),
      Expanded(
        child: AsyncView<List<Map<String, dynamic>>>(
          key: ValueKey('$_brand|$_q'),
          load: () async => asList(await apiGet('/lenses', {
            if (_brand != null) 'brand': _brand!,
            if (_q.isNotEmpty) 'q': _q,
            'limit': '200',
          })),
          builder: (context, lenses) {
            if (lenses.isEmpty) return const Center(child: Text('ไม่พบเลนส์'));
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: lenses.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final l = lenses[i];
                final focal = l['focal_min_mm'] == l['focal_max_mm']
                    ? '${l['focal_min_mm']}mm'
                    : '${l['focal_min_mm']}-${l['focal_max_mm']}mm';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(children: [
                    Img(l['image_url'] as String?, width: 120, height: 96, fallback: Icons.camera, bg: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(l['lens_name'] as String,
                            maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Wrap(spacing: 6, children: [Tag(txt(l['brand'])), Tag('$focal  f/${txt(l['max_aperture'])}')]),
                        const SizedBox(height: 4),
                        Row(children: [
                          RatingRow(l['avg_rating'] as num?, l['review_count']),
                          const Spacer(),
                          Text(baht(l['price_thb']), style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimary)),
                        ]),
                      ]),
                    ),
                  ]),
                );
              },
            );
          },
        ),
      ),
    ]);
  }
}

