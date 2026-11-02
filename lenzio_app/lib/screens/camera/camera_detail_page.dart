// หน้ารายละเอียดกล้อง — สเปก, เลนส์ที่ใช้ได้, รีวิว และปุ่ม Favorite
import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../widgets/async_view.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/image_widgets.dart';
import '../../widgets/rating_widgets.dart';

class CameraDetailPage extends StatefulWidget {
  final int cameraId;
  const CameraDetailPage({super.key, required this.cameraId});
  @override
  State<CameraDetailPage> createState() => _CameraDetailPageState();
}

class _CameraDetailPageState extends State<CameraDetailPage> {
  late Future<Map<String, dynamic>> _future;
  bool _fav = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final m = (await apiGet('/cameras/${widget.cameraId}', {'user_id': '$kUserId'})) as Map<String, dynamic>;
    if (mounted) setState(() => _fav = m['is_favorite'] == true);
    return m;
  }

  Future<void> _toggleFav() async {
    if (_busy) return;
    final next = !_fav;
    setState(() {
      _fav = next;
      _busy = true;
    });
    try {
      if (next) {
        await apiSend('POST', '/favorites', {'user_id': kUserId, 'camera_id': widget.cameraId});
      } else {
        await apiSend('DELETE', '/favorites/$kUserId/${widget.cameraId}');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next ? 'เพิ่มในรายการโปรดแล้ว' : 'ลบออกจากรายการโปรดแล้ว'), duration: const Duration(seconds: 1)));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _fav = !next);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ทำรายการไม่สำเร็จ: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('รายละเอียดกล้อง', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: _toggleFav,
            icon: Icon(_fav ? Icons.favorite : Icons.favorite_border, color: _fav ? Colors.red : null),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) {
            return ErrorBox(error: '${snap.error}', onRetry: () => setState(() => _future = _load()));
          }
          final c = snap.data!;
          final lenses = asList(c['compatible_lenses']);
          final reviews = asList(c['reviews']);

          Widget row(String k, String v) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  Expanded(child: Text(k, style: const TextStyle(color: Colors.grey))),
                  Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
                ]),
              );

          return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
            Img(c['image_url'] as String?, height: 280, width: double.infinity, radius: 0, bg: Colors.white),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c['model_name'] as String, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  Tag(txt(c['sensor_format'])),
                  Tag('${mp(c['megapixels'])} MP'),
                  Tag(txt(c['video_spec'])),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Stars(c['avg_rating'] as num?),
                  const SizedBox(width: 6),
                  Text('(${c['review_count']} รีวิว)', style: const TextStyle(color: Colors.grey)),
                ]),
              ]),
            ),
            SectionTitle('เลนส์ที่ใช้งานได้ (${lenses.length})'),
            SizedBox(
              height: 200,
              child: lenses.isEmpty
                  ? const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('ไม่มีข้อมูลเลนส์'))
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: lenses.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final l = lenses[i];
                        return Container(
                          width: 165,
                          clipBehavior: Clip.antiAlias,
                          padding: EdgeInsets.zero,
                          decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFE5E8F0)), borderRadius: BorderRadius.circular(14)),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Img(l['image_url'] as String?, width: double.infinity, height: 105, fallback: Icons.camera, radius: 0, bg: Colors.white),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                              child: Text(l['lens_name'] as String,
                                  maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                            const Spacer(),
                            Padding(padding: const EdgeInsets.fromLTRB(8, 0, 8, 8), child: Tag(txt(l['brand']))),
                          ]),
                        );
                      },
                    ),
            ),
            const SectionTitle('ข้อมูลสรุป'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: [
                row('เซนเซอร์', txt(c['sensor_format'])),
                const Divider(height: 1),
                row('วิดีโอ', txt(c['video_spec'])),
                const Divider(height: 1),
                row('ISO', '${txt(c['iso_min'])} - ${txt(c['iso_max'])}'),
                const Divider(height: 1),
                row('เมาท์', txt(c['mount'])),
                const Divider(height: 1),
                row('เปิดตัว', txt(c['release_year'])),
                const Divider(height: 1),
                row('ราคาโดยประมาณ', baht(c['price_thb'])),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: SizedBox(
                height: 48,
                child: _fav
                    ? OutlinedButton.icon(
                        onPressed: _toggleFav,
                        icon: const Icon(Icons.favorite, color: Colors.red),
                        label: const Text('อยู่ในรายการโปรดแล้ว'),
                      )
                    : FilledButton.icon(
                        onPressed: _toggleFav,
                        icon: const Icon(Icons.favorite_border),
                        label: const Text('เพิ่มในรายการโปรด'),
                      ),
              ),
            ),
            SectionTitle('รีวิว (${reviews.length})'),
            if (reviews.isEmpty) const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('ยังไม่มีรีวิว')),
            for (final r in reviews) ReviewTile(r),
          ]);
        },
      ),
    );
  }
}

/// รีวิวแบบ Compact ใช้ในหน้า Camera Detail และ Recipe Sheet
class ReviewTile extends StatelessWidget {
  final Map<String, dynamic> r;
  const ReviewTile(this.r, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Avatar(url: null, name: txt(r['display_name'])),
      title: Row(children: [
        Expanded(child: Text(txt(r['display_name']), overflow: TextOverflow.ellipsis)),
        Stars(r['rating'] as num?, size: 14),
      ]),
      subtitle: Text(txt(r['comment'])),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.thumb_up_alt_outlined, size: 14),
        const SizedBox(width: 4),
        Text('${r['like_count']}'),
      ]),
    );
  }
}

