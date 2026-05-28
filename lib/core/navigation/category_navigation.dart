import 'package:flutter/material.dart';
import 'package:tw_stock_capital_flow/presentation/pages/sub_category_page.dart';
import 'package:tw_stock_capital_flow/presentation/models/category_ui_model.dart';

class CategoryNavigation {
  static void openCategory(BuildContext context, CategoryUiModel category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubCategoryPage(
          title: category.name,

          categories: category.children,
        ),
      ),
    );
  }
}
