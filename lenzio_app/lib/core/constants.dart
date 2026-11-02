// ค่าคงที่ทั่วทั้งแอป เช่น URL ของ API, สีหลัก, รายการแบรนด์
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Web/iOS -> http://localhost:8000 | Android emulator -> http://10.0.2.2:8000
const String kApiBase = kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000';

/// Demo user สำหรับทดสอบ Favorites และ Reviews (user_id 1 มีอยู่ในฐานข้อมูลแล้ว)
const int kUserId = 1;

const Color kPrimary = Color(0xFF2563EB);

const List<String> kBrands = ['Sony', 'Fujifilm', 'Canon', 'Nikon', 'Panasonic'];
const List<String> kCategories = ['ภาพบุคคล', 'วิวทิวทัศน์', 'อาหาร', 'กลางคืน'];

const Map<String, String> kSortLabels = {
  'popular': 'ยอดนิยม',
  'name': 'ชื่อ A-Z',
  'price': 'ราคาสูง-ต่ำ',
  'year': 'ใหม่ล่าสุด',
};

const Map<String, String> kTypeLabels = {
  'camera': 'กล้อง',
  'lens': 'เลนส์',
  'recipe': 'Recipe',
};

