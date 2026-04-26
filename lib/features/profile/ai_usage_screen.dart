import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/providers/auth_provider.dart';

class AIUsageScreen extends ConsumerWidget {
  const AIUsageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final usageAsync = ref.watch(aiUsageProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'MONITOR AI',
          style: GoogleFonts.anton(
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: usageAsync.when(
        data: (usage) {
          int count = usage?['count'] ?? 0;
          
          if (usage != null && usage['lastReset'] != null) {
            final lastReset = (usage['lastReset'] as Timestamp).toDate();
            final now = DateTime.now();
            final isSameDay = lastReset.year == now.year && 
                              lastReset.month == now.month && 
                              lastReset.day == now.day;
            if (!isSameDay) {
              count = 0;
            }
          }

          final remaining = (5 - count).clamp(0, 5);
          final percent = (count / 5).clamp(0.0, 1.0);

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Status Card ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorScheme.onSurface, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.onSurface,
                        offset: const Offset(8, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'SISA KUOTA HARI INI',
                        style: GoogleFonts.anton(
                          fontSize: 20,
                          color: colorScheme.onSurface,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$remaining',
                        style: GoogleFonts.anton(
                          fontSize: 84,
                          color: colorScheme.onSurface,
                          height: 1,
                        ),
                      ),
                      Text(
                        'REQUEST TERSISA',
                        style: GoogleFonts.anton(
                          fontSize: 16,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // ── Progress Section ──
                Text(
                  'PENGGUNAAN',
                  style: GoogleFonts.anton(
                    fontSize: 18,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 32,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.onSurface, width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        widthFactor: percent,
                        child: Container(
                          decoration: BoxDecoration(
                            color: percent > 0.8 ? const Color(0xFFFF5555) : const Color(0xFF4338CA),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$count digunakan',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Batas: 5',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // ── Info Card ──
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.onSurface, width: 2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reset Harian',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Kuota kamu akan direset secara otomatis setiap 24 jam.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Gagal memuat data: $err')),
      ),
    );
  }
}
