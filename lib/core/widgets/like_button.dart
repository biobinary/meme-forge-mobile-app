import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LikeButton extends StatelessWidget {
  final int likeCount;
  final bool isLiked;
  final bool isLoading;
  final bool isLoggedIn;
  final VoidCallback? onTap;

  const LikeButton({
    super.key,
    required this.likeCount,
    required this.isLiked,
    required this.isLoading,
    required this.isLoggedIn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final bgColor = isLiked ? Colors.redAccent : colorScheme.surface;
    final borderColor = isLiked ? Colors.redAccent : colorScheme.onSurface;
    final textColor = isLiked ? Colors.white : colorScheme.onSurface;
    final iconColor = isLiked ? Colors.white : Colors.redAccent;
    final iconData = isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isLoading
                      ? SizedBox(
                          key: const ValueKey('loading'),
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: iconColor,
                          ),
                        )
                      : Icon(
                          iconData,
                          key: ValueKey(isLiked),
                          size: 16,
                          color: iconColor,
                        ),
                ),
                const SizedBox(width: 6),
                Text(
                  'LIKES',
                  style: GoogleFonts.anton(
                    fontSize: 12,
                    color: textColor.withValues(alpha: isLiked ? 0.85 : 0.6),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Text(
                    likeCount.toString(),
                    key: ValueKey(likeCount),
                    style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                ),
                if (!isLoggedIn)
                  Icon(Icons.lock_outline_rounded,
                      size: 14, color: textColor.withValues(alpha: 0.5)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
