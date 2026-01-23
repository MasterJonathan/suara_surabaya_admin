import 'package:suara_surabaya_admin/core/navigation/navigation_service.dart'; 
import 'package:flutter/material.dart';

class SidebarMenuItem {
  final String title;
  final IconData icon;
  final DashboardPage? page;
  final List<SidebarMenuItem>? subItems;
  bool isExpanded;

  SidebarMenuItem({
    required this.title,
    required this.icon,
    this.page,
    this.subItems,
    this.isExpanded = false,
  }) : assert(page != null || (subItems != null && subItems.isNotEmpty));
}