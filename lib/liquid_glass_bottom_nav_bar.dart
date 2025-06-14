import 'package:flutter/material.dart';
import 'dart:ui';

class LiquidGlassBottomNavBar extends StatelessWidget {
  final bool isBlurEnabled;
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final List<_NavBarItemData> items;
  final VoidCallback? onSearchTap;

  const LiquidGlassBottomNavBar({
    super.key,
    required this.isBlurEnabled,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.items,
    this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(),
          width: MediaQuery.of(context).size.width * 0.7,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: isBlurEnabled
                ? BackdropGroup(
                  child: BackdropFilter.grouped(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (int i = 0; i < items.length; i++)
                            Expanded(
                              child: _buildNavItem(items[i], i,
                                  selectedIndex == i, () => onItemTapped(i)),
                            ),
                        ],
                      ),
                    ),
                  ),
                )
                : Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int i = 0; i < items.length; i++)
                          Expanded(
                            child: _buildNavItem(items[i], i,
                                selectedIndex == i, () => onItemTapped(i)),
                          ),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onSearchTap,
          child: Container(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: isBlurEnabled
                  ? BackdropGroup(
                    child: BackdropFilter.grouped(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.search,
                          color: selectedIndex == items.length
                              ? Colors.blue
                              : Colors.black54,
                          size: 40,
                        ),
                      ),
                    ),
                  )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.search,
                        color: selectedIndex == items.length
                            ? Colors.blue
                            : Colors.black54,
                        size: 40,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(
      _NavBarItemData item, int index, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: 0,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(isSelected ? 100 : 16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: isSelected ? 1.2 : 1.0,
              child: Icon(
                item.icon,
                color: isSelected ? Colors.blue : Colors.black54,
                size: 28,
              ),
            ),
            if (item.label.isNotEmpty) ...[
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isSelected ? Colors.blue : Colors.black54,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                child: Text(item.label),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavBarItemData {
  final IconData icon;
  final String label;
  _NavBarItemData({required this.icon, required this.label});
}

// 用于外部创建 items
List<_NavBarItemData> buildDefaultNavBarItems() => [
      _NavBarItemData(icon: Icons.home, label: 'Home'),
      _NavBarItemData(icon: Icons.grid_view, label: 'Hot'),
      _NavBarItemData(icon: Icons.grid_on_outlined, label: 'More'),
      _NavBarItemData(icon: Icons.newspaper_sharp, label: 'News'),
    ];
