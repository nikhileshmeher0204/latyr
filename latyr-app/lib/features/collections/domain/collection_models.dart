import 'package:flutter/cupertino.dart';
import 'package:latyr_app/core/database/app_database.dart';

class CategoryGroup {
  final String categoryName;
  final List<LocalCapture> captures;
  final IconData icon;
  final Color color;

  const CategoryGroup({
    required this.categoryName,
    required this.captures,
    required this.icon,
    required this.color,
  });
}

class SubCategoryGroup {
  final String subCategoryName;
  final List<LocalCapture> captures;

  const SubCategoryGroup({
    required this.subCategoryName,
    required this.captures,
  });
}
