// Widgets แสดงรูปภาพ: Img (รูปทั่วไป) และ Avatar (รูปโปรไฟล์วงกลม)
import 'package:flutter/material.dart';
import '../core/constants.dart';

/// รูปภาพจาก Network พร้อม fallback icon เมื่อ URL ว่างหรือโหลดไม่ได้
class Img extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData fallback;
  final double radius;
  final Color bg;
  const Img(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.fallback = Icons.photo_camera,
    this.radius = 12,
    this.bg = const Color(0xFFF1F3F7),
  });

  @override
  Widget build(BuildContext context) {
    final icon = Center(child: Icon(fallback, size: 32, color: Colors.grey));
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: width,
        height: height,
        color: bg,
        child: (url == null || url!.isEmpty)
            ? icon
            : Image.network(
                url!,
                fit: fit,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                errorBuilder: (_, __, ___) => icon,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const Center(
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
              ),
      ),
    );
  }
}

/// รูปโปรไฟล์วงกลม — แสดงตัวอักษรแรกของชื่อเมื่อไม่มีรูป
class Avatar extends StatelessWidget {
  final String? url;
  final String name;
  final double size;
  const Avatar({super.key, required this.url, required this.name, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name.characters.first;
    final fallback = Container(
      color: kPrimary.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Text(initial, style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
    );
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: (url == null || url!.isEmpty)
            ? fallback
            : Image.network(url!, fit: BoxFit.cover, webHtmlElementStrategy: WebHtmlElementStrategy.prefer, errorBuilder: (_, __, ___) => fallback),
      ),
    );
  }
}

