// หน้ารายการกล้องทั้งหมด — ค้นหา, กรองแบรนด์, เรียงลำดับ
import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/utils.dart';
import '../../widgets/async_view.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/image_widgets.dart';
import '../../widgets/rating_widgets.dart';
import '../../core/constants.dart';
import 'camera_detail_page.dart';

class CameraListPage extends StatefulWidget {
  const CameraListPage({super.key});
  @override
  State<CameraListPage> createState() => _CameraListPageState();
}

class _CameraListPageState extends State<CameraListPage> {
  String? _brand;
  String _q = '';
  String _sort = 'popular';

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Align(alignment: Alignment.centerLeft, child: PageTitle('กล้อง')),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: SearchField(hint: 'ค้นหากล้อง', onSubmitted: (v) => setState(() => _q = v.trim())),
      ),
      ChipBar(options: kBrands, selected: _brand, onChanged: (v) => setState(() => _brand = v)),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        child: Align(
          alignment: Alignment.centerRight,
          child: SortButton(value: _sort, onChanged: (v) => setState(() => _sort = v)),
        ),
      ),
      Expanded(
        child: AsyncView<List<Map<String, dynamic>>>(
          key: ValueKey('$_brand|$_q|$_sort'),
          load: () async => asList(await apiGet('/cameras', {
            if (_brand != null) 'brand': _brand!,
            if (_q.isNotEmpty) 'q': _q,
            'sort': _sort,
            'limit': '200',
          })),
          builder: (context, cams) {
            if (cams.isEmpty) return const Center(child: Text('ไม่พบกล้อง'));
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: cams.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final c = cams[i];
                return InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CameraDetailPage(cameraId: c['camera_id'] as int))),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(children: [
                      Img(c['image_url'] as String?, width: 120, height: 96, bg: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(c['model_name'] as String,
                              maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Tag(txt(c['sensor_format'])),
                          const SizedBox(height: 4),
                          RatingRow(c['avg_rating'] as num?, c['review_count']),
                        ]),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ]),
                  ),
                );
              },
            );
          },
        ),
      ),
    ]);
  }
}

