// หน้า Home — แสดง Hero Banner, กรองแบรนด์ และ Grid กล้องทั้งหมด
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../../core/utils.dart';
import '../../widgets/async_view.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/image_widgets.dart';
import '../../widgets/rating_widgets.dart';
import '../camera/camera_detail_page.dart';

/// การ์ดกล้องแบบ Grid ใช้ในหน้า Home
class CameraCard extends StatelessWidget {
  final Map<String, dynamic> c;
  const CameraCard(this.c, {super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CameraDetailPage(cameraId: c['camera_id'] as int))),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E8F0)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Img(c['image_url'] as String?, width: double.infinity, height: 150, radius: 0, bg: Colors.white),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c['model_name'] as String,
                    maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Tag(txt(c['sensor_format'])),
                const SizedBox(height: 6),
                RatingRow(c['avg_rating'] as num?, c['review_count']),
                const SizedBox(height: 4),
                const Text('สอบถามราคา', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const Spacer(),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text('ดูสินค้า →', style: TextStyle(fontSize: 13, color: kPrimary, fontWeight: FontWeight.bold)),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _brand;
  String? _sensor; // 'Full frame' | 'APS-C' | null
  String _q = '';
  String _sort = 'popular';
  late Future<List<Map<String, dynamic>>> _future;
  final _gridKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async => asList(await apiGet('/cameras', {
        if (_brand != null) 'brand': _brand!,
        if (_q.isNotEmpty) 'q': _q,
        'sort': _sort,
        'limit': '200',
      }));

  void _reload() => setState(() => _future = _load());

  void _scrollToGrid() {
    final ctx = _gridKey.currentContext;
    if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
  }

  Future<void> _openFilter() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('กรองตามขนาดเซนเซอร์', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          for (final o in const ['ทั้งหมด', 'Full frame', 'APS-C'])
            ListTile(
              title: Text(o),
              trailing: (_sensor ?? 'ทั้งหมด') == o ? const Icon(Icons.check, color: kPrimary) : null,
              onTap: () => Navigator.of(context).pop(o),
            ),
        ]),
      ),
    );
    if (picked != null) setState(() => _sensor = picked == 'ทั้งหมด' ? null : picked);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: SearchField(
          hint: 'ค้นหากล้อง เช่น A7 IV',
          onSubmitted: (v) {
            _q = v.trim();
            _reload();
          },
        ),
      ),
      // Hero Banner
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: const DecorationImage(
            image: NetworkImage('https://bypixvora.com/uploads/webp/sony-mirrorless-camera-table_bypixvora-a4def944.webp'),
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [const Color(0xFF1E3A8A).withOpacity(0.92), const Color(0xFF1E3A8A).withOpacity(0.0)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('กล้องที่ใช่\nเลนส์ที่ชอบ',
                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, height: 1.25)),
            const SizedBox(height: 6),
            const Text('รวมกล้อง เลนส์ สูตรถ่ายภาพ และรีวิว จาก 5 แบรนด์',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _scrollToGrid,
              style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: kPrimary),
              child: const Text('ดูสินค้าแนะนำ', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 14),
      ChipBar(
        options: kBrands,
        selected: _brand,
        onChanged: (v) {
          _brand = v;
          _reload();
        },
      ),
      Padding(
        key: _gridKey,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(children: [
          const Expanded(child: Text('สินค้าทั้งหมด', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          OutlinedButton.icon(
            onPressed: _openFilter,
            icon: const Icon(Icons.tune, size: 16),
            label: Text(_sensor ?? 'กรอง'),
            style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
          const SizedBox(width: 8),
          SortButton(
            value: _sort,
            prefix: '',
            onChanged: (v) {
              _sort = v;
              _reload();
            },
          ),
        ]),
      ),
      FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()));
          }
          if (snap.hasError) {
            return SizedBox(height: 240, child: ErrorBox(error: '${snap.error}', onRetry: _reload));
          }
          var cams = snap.data!;
          if (_sensor != null) {
            cams = cams.where((c) => txt(c['sensor_format']).toLowerCase() == _sensor!.toLowerCase()).toList();
          }
          if (cams.isEmpty) return const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('ไม่พบสินค้า')));
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: cams.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 345),
            itemBuilder: (context, i) => CameraCard(cams[i]),
          );
        },
      ),
    ]);
  }
}

