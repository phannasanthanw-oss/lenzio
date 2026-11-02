// หน้ารายการ Recipe และ BottomSheet แสดงรายละเอียดสูตรถ่ายภาพ
import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../widgets/async_view.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/image_widgets.dart';
import '../camera/camera_detail_page.dart' show ReviewTile;

class RecipePage extends StatefulWidget {
  const RecipePage({super.key});
  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Align(alignment: Alignment.centerLeft, child: PageTitle('Recipe')),
      ChipBar(options: kCategories, selected: _category, onChanged: (v) => setState(() => _category = v)),
      const SizedBox(height: 8),
      Expanded(
        child: AsyncView<List<Map<String, dynamic>>>(
          key: ValueKey(_category),
          load: () async => asList(await apiGet('/recipes', {if (_category != null) 'category': _category!, 'limit': '200'})),
          builder: (context, recipes) {
            if (recipes.isEmpty) return const Center(child: Text('ไม่พบสูตร'));
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: recipes.length,
              itemBuilder: (context, i) {
                final r = recipes[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: GestureDetector(
                    onTap: () => showRecipeSheet(context, r['recipe_id'] as int),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(children: [
                        Img(r['cover_image_url'] as String?,
                            width: double.infinity, height: 190, fit: BoxFit.cover, fallback: Icons.auto_awesome, radius: 0),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                                stops: const [0.4, 1],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 12,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(r['title'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text('${r['camera_name']} + ${r['lens_name']}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ]),
                        ),
                      ]),
                    ),
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

/// เปิด BottomSheet แสดงรายละเอียด Recipe
void showRecipeSheet(BuildContext context, int recipeId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, controller) => AsyncView<Map<String, dynamic>>(
        load: () async => (await apiGet('/recipes/$recipeId')) as Map<String, dynamic>,
        builder: (context, r) {
          final reviews = asList(r['reviews']);
          return ListView(controller: controller, padding: const EdgeInsets.all(16), children: [
            Img(r['cover_image_url'] as String?, height: 170, width: double.infinity, fit: BoxFit.cover, fallback: Icons.auto_awesome),
            const SizedBox(height: 12),
            Text(r['title'] as String, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Align(alignment: Alignment.centerLeft, child: Tag(txt(r['category']))),
            const SizedBox(height: 8),
            Text(txt(r['description'])),
            const Divider(height: 24),
            ListTile(
              dense: true,
              leading: Img(r['camera_image_url'] as String?, width: 56, height: 40),
              title: Text(r['camera_name'] as String),
              subtitle: const Text('กล้อง'),
            ),
            ListTile(
              dense: true,
              leading: Img(r['lens_image_url'] as String?, width: 56, height: 40, fallback: Icons.camera),
              title: Text(r['lens_name'] as String),
              subtitle: const Text('เลนส์'),
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              Tag('f/${r['aperture']}'),
              Tag('${r['shutter_speed']}'),
              Tag('ISO ${r['iso']}'),
            ]),
            SectionTitle('รีวิว (${reviews.length})'),
            if (reviews.isEmpty) const Text('ยังไม่มีรีวิว'),
            for (final rv in reviews) ReviewTile(rv),
          ]);
        },
      ),
    ),
  );
}

