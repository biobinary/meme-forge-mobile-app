import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/meme_model.dart';

class MemeDetailView extends StatelessWidget {
  final MemeModel meme;

  const MemeDetailView({
    super.key,
    required this.meme,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateStr = meme.createdAt != null
        ? '${meme.createdAt!.day}/${meme.createdAt!.month}/${meme.createdAt!.year}'
        : '-';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'DETAIL MEME',
          style: GoogleFonts.anton(
            fontSize: 24,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Meme Image Container ──
            Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.onSurface,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.onSurface,
                    offset: const Offset(8, 8),
                    blurRadius: 0,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                meme.imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 300,
                    color: colorScheme.surfaceContainerHighest,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 300,
                    color: colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image_outlined, size: 64),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            // ── Caption Section ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primary, // Vibrant Yellow
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.onSurface,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CAPTION',
                    style: GoogleFonts.anton(
                      fontSize: 18,
                      color: colorScheme.onSurface,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    meme.caption,
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Metadata Row ──
            Row(
              children: [
                // Date
                Expanded(
                  child: _buildInfoCard(
                    context,
                    label: 'DIBUAT PADA',
                    value: dateStr,
                    icon: Icons.calendar_today_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                // Likes
                Expanded(
                  child: _buildInfoCard(
                    context,
                    label: 'LIKES',
                    value: meme.likes.length.toString(),
                    icon: Icons.favorite_rounded,
                    valueColor: Colors.redAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.onSurface,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: colorScheme.onSurface.withOpacity(0.6)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.anton(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.6),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: valueColor ?? colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
