// Widgets แสดงคะแนนดาว: Stars และ RatingRow
import 'package:flutter/material.dart';

/// แถวดาว 1-5 ดาว รองรับครึ่งดาว
class Stars extends StatelessWidget {
  final num? rating;
  final double size;
  const Stars(this.rating, {super.key, this.size = 16});

  @override
  Widget build(BuildContext context) {
    final r = rating?.toDouble() ?? 0;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 1; i <= 5; i++)
        Icon(
          r >= i ? Icons.star : (r >= i - 0.5 ? Icons.star_half : Icons.star_border),
          size: size,
          color: Colors.amber,
        ),
    ]);
  }
}

/// แสดง "★ 4.5 (12)" ในบรรทัดเดียว
class RatingRow extends StatelessWidget {
  final num? avg;
  final dynamic count;
  final double size;
  const RatingRow(this.avg, this.count, {super.key, this.size = 13});

  @override
  Widget build(BuildContext context) {
    final a = avg;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.star, size: size + 2, color: Colors.amber),
      const SizedBox(width: 3),
      Text(
        a == null ? '-' : a.toStringAsFixed(1),
        style: TextStyle(fontSize: size, fontWeight: FontWeight.w600),
      ),
      const SizedBox(width: 3),
      Text('(${count ?? 0})', style: TextStyle(fontSize: size, color: Colors.grey)),
    ]);
  }
}

