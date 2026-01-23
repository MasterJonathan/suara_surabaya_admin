import 'package:suara_surabaya_admin/core/theme/app_colors.dart'; 
import 'package:flutter/material.dart';

class SidebarClickableItem extends StatefulWidget {
  
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final int level;
  final Color sidebarBackgroundColor;

  const SidebarClickableItem({
    
    super.key, 
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
    required this.sidebarBackgroundColor,
    this.level = 0,
  });

  @override
  State<SidebarClickableItem> createState() => _SidebarClickableItemState(); 
}

class _SidebarClickableItemState extends State<SidebarClickableItem> {
  
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color itemBackgroundColor;
    Color itemForegroundColor;

    if (widget.isSelected) {
      itemBackgroundColor = AppColors.primary;
      itemForegroundColor = AppColors.surface;

      
    } else {
      itemBackgroundColor = _isHovered ? AppColors.primary : AppColors.surface;

      itemForegroundColor =
          _isHovered ? AppColors.surface : AppColors.foreground;
    }

    return Material(
      color: itemBackgroundColor,
      child: InkWell(
        onTap: widget.onTap,
        onHover: (hovering) {
          setState(() {
            _isHovered = hovering;
          });
        },
        splashColor:
            widget.isSelected
                ? AppColors.surface.withValues(alpha: 0.1)
                : AppColors.primary.withValues(alpha: 0.1),
        highlightColor:
            widget.isSelected
                ? AppColors.surface.withValues(alpha: 0.05)
                : AppColors.primary.withValues(alpha: 0.05),
        hoverColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 16.0, 
            top: 12,
            bottom: 12,
            right: 16,
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                color: itemForegroundColor,
                size: widget.level > 0 ? 18 : 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    color: itemForegroundColor,
                    fontWeight:
                        widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: widget.level > 0 ? 14 : 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
