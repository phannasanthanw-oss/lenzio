// หน้ารายการรีวิว — กรองตามประเภท, การ์ดรีวิว และฟอร์มเขียนรีวิว
import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../widgets/async_view.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/image_widgets.dart';
import '../../widgets/rating_widgets.dart';

// ================================================================ ReviewPage
class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});
  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  String? _type; // camera | lens | recipe | null
  int _version = 0;

  Future<void> _write() async {
    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const ReviewForm(),
    );
    if (done == true) setState(() => _version++);
  }

  @override
  Widget build(BuildContext context) {
    final labelToType = {for (final e in kTypeLabels.entries) e.value: e.key};
    return Column(children: [
      const Align(alignment: Alignment.centerLeft, child: PageTitle('รีวิว')),
      ChipBar(
        options: kTypeLabels.values.toList(),
        selected: _type == null ? null : kTypeLabels[_type],
        onChanged: (v) => setState(() => _type = v == null ? null : labelToType[v]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _write,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF1F3F7), borderRadius: BorderRadius.circular(14)),
            child: const Row(children: [
              Icon(Icons.edit_outlined, color: kPrimary),
              SizedBox(width: 10),
              Expanded(child: Text('เขียนรีวิวของคุณ', style: TextStyle(color: Colors.black54))),
              Icon(Icons.chevron_right, color: Colors.grey),
            ]),
          ),
        ),
      ),
      Expanded(
        child: AsyncView<List<Map<String, dynamic>>>(
          key: ValueKey('$_type|$_version'),
          load: () async => asList(await apiGet('/reviews', {if (_type != null) 'type': _type!, 'limit': '100'})),
          builder: (context, reviews) {
            if (reviews.isEmpty) return const Center(child: Text('ยังไม่มีรีวิว'));
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: reviews.length,
              itemBuilder: (context, i) => ReviewCard(reviews[i]),
            );
          },
        ),
      ),
    ]);
  }
}

// ================================================================ ReviewCard
class ReviewCard extends StatefulWidget {
  final Map<String, dynamic> r;
  const ReviewCard(this.r, {super.key});
  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  late int _likes;
  bool _liked = false;

  @override
  void initState() {
    super.initState();
    _likes = (widget.r['like_count'] as num?)?.toInt() ?? 0;
  }

  Future<void> _like() async {
    if (_liked) return;
    setState(() {
      _liked = true;
      _likes++;
    });
    try {
      await apiSend('POST', '/reviews/${widget.r['review_id']}/like');
    } catch (_) {
      if (mounted) {
        setState(() {
          _liked = false;
          _likes--;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.r;
    final type = '${r['target_type']}';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E8F0)), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Avatar(url: r['avatar_url'] as String?, name: txt(r['display_name'])),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(txt(r['display_name']), style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(ago(r['created_at']), style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
          ),
          Stars(r['rating'] as num?, size: 15),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Img(
            r['target_image_url'] as String?,
            width: 44,
            height: 44,
            radius: 8,
            fit: type == 'recipe' ? BoxFit.cover : BoxFit.contain,
            fallback: type == 'lens' ? Icons.camera : (type == 'recipe' ? Icons.auto_awesome : Icons.photo_camera),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(txt(r['target_name']), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(txt(r['comment'])),
        const SizedBox(height: 8),
        Row(children: [
          Tag(kTypeLabels[type] ?? type),
          const Spacer(),
          InkWell(
            onTap: _like,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_liked ? Icons.thumb_up : Icons.thumb_up_alt_outlined, size: 16, color: _liked ? kPrimary : Colors.grey),
                const SizedBox(width: 4),
                Text('$_likes'),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ================================================================ ReviewForm
class ReviewForm extends StatefulWidget {
  const ReviewForm({super.key});
  @override
  State<ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  // ประเภท -> [api path, id field, name field]
  static const Map<String, List<String>> _src = {
    'camera': ['/cameras', 'camera_id', 'model_name'],
    'lens': ['/lenses', 'lens_id', 'lens_name'],
    'recipe': ['/recipes', 'recipe_id', 'title'],
  };

  String _type = 'camera';
  List<Map<String, dynamic>> _items = [];
  int? _itemId;
  bool _loadingItems = true;
  int _rating = 5;
  final _comment = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() {
      _loadingItems = true;
      _itemId = null;
      _error = null;
    });
    try {
      final items = asList(await apiGet(_src[_type]![0], {'limit': '200'}));
      if (!mounted) return;
      setState(() {
        _items = items;
        _loadingItems = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingItems = false;
        _error = '$e';
      });
    }
  }

  Future<void> _submit() async {
    if (_itemId == null) {
      setState(() => _error = 'กรุณาเลือกสิ่งที่จะรีวิว');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await apiSend('POST', '/reviews', {
        'user_id': kUserId,
        _src[_type]![1]: _itemId,
        'rating': _rating,
        'comment': _comment.text.trim().isEmpty ? null : _comment.text.trim(),
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = '$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final idKey = _src[_type]![1];
    final nameKey = _src[_type]![2];
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('เขียนรีวิวของคุณ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: [for (final e in kTypeLabels.entries) ButtonSegment(value: e.key, label: Text(e.value))],
            selected: {_type},
            onSelectionChanged: (s) {
              _type = s.first;
              _loadItems();
            },
          ),
          const SizedBox(height: 12),
          if (_loadingItems)
            const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
          else
            DropdownButton<int>(
              isExpanded: true,
              value: _itemId,
              hint: Text('เลือก${kTypeLabels[_type]}'),
              items: [
                for (final it in _items)
                  DropdownMenuItem<int>(value: it[idKey] as int, child: Text('${it[nameKey]}', overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => setState(() => _itemId = v),
            ),
          Row(children: [
            for (var i = 1; i <= 5; i++)
              IconButton(
                onPressed: () => setState(() => _rating = i),
                icon: Icon(_rating >= i ? Icons.star : Icons.star_border, color: Colors.amber, size: 32),
              ),
          ]),
          TextField(
            controller: _comment,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'ความคิดเห็น (ไม่บังคับ)', border: OutlineInputBorder()),
          ),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(onPressed: _busy ? null : _submit, child: Text(_busy ? 'กำลังส่ง...' : 'ส่งรีวิว')),
          ),
        ]),
      ),
    );
  }
}

