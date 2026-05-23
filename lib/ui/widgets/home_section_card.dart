import 'package:flutter/material.dart';

class HomeSectionCard extends StatelessWidget {
  final String title;

  final String subtitle;

  final String description;

  final List<Color> gradient;

  final IconData icon;

  final VoidCallback onTap;

  const HomeSectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.gradient,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        margin: const EdgeInsets.only(bottom: 18),

        padding: const EdgeInsets.all(24),

        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),

          borderRadius: BorderRadius.circular(30),

          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.25),

              blurRadius: 20,

              offset: const Offset(0, 12),
            ),
          ],
        ),

        child: Row(
          children: [
            Container(
              width: 66,
              height: 66,

              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),

                borderRadius: BorderRadius.circular(22),
              ),

              child: Icon(icon, color: Colors.white, size: 34),
            ),

            const SizedBox(width: 18),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    title,

                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    subtitle,

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    description,

                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),

                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ],
        ),
      ),
    );
  }
}
