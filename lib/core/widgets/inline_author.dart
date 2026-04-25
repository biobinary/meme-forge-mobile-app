import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/meme_provider.dart';

class InlineAuthor extends ConsumerWidget {
  final String userId;

  const InlineAuthor({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final authorAsync = ref.watch(authorUsernameProvider(userId));

    return authorAsync.when(
      data: (username) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.onSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.onSurface, width: 2),
          ),
          child: Text(
            '@${username ?? 'unknown'}',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colorScheme.surface,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
      loading: () => Container(
        width: 90,
        height: 28,
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
