import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/meme_model.dart';
import '../providers/auth_provider.dart';
import '../providers/meme_provider.dart';

class MemeDetailView extends ConsumerStatefulWidget {
  final MemeModel meme;

  const MemeDetailView({
    super.key,
    required this.meme,
  });

  @override
  ConsumerState<MemeDetailView> createState() => _MemeDetailViewState();
}

class _MemeDetailViewState extends ConsumerState<MemeDetailView> {

  late List<String> _localLikes;
  bool _isLikeLoading = false;

  @override
  void initState() {
    super.initState();
    _localLikes = List<String>.from(widget.meme.likes);
  }

  Future<void> _handleLikeTap(String currentUserId) async {
    if (_isLikeLoading) return;
    if (widget.meme.id == null) return;

    final isLiked = _localLikes.contains(currentUserId);

    // Optimistic update
    setState(() {
      _isLikeLoading = true;
      if (isLiked) {
        _localLikes.remove(currentUserId);
      } else {
        _localLikes.add(currentUserId);
      }
    });

    try {
      await ref.read(memeRepositoryProvider).toggleLike(
            memeId: widget.meme.id!,
            userId: currentUserId,
            currentlyLiked: isLiked,
          );
    } catch (e) {
      // Rollback on failure
      if (mounted) {
        setState(() {
          if (isLiked) {
            _localLikes.add(currentUserId);
          } else {
            _localLikes.remove(currentUserId);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menyimpan like: $e',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLikeLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authStateProvider);
    final currentUserId = authState.value?.uid;
    final isOwner = currentUserId == widget.meme.userId;
    final isLiked =
        currentUserId != null && _localLikes.contains(currentUserId);

    final dateStr = widget.meme.createdAt != null
        ? '${widget.meme.createdAt!.day}/${widget.meme.createdAt!.month}/${widget.meme.createdAt!.year}'
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
        actions: [
          if (isOwner)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              offset: const Offset(0, 48),
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditCaptionDialog(context, ref);
                } else if (value == 'delete') {
                  _showDeleteConfirmation(context, ref);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit_note_rounded, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Edit Caption',
                        style:
                            GoogleFonts.nunito(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline_rounded,
                          size: 20, color: Colors.redAccent),
                      const SizedBox(width: 12),
                      Text(
                        'Delete Meme',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w600,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.black, width: 1),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            _InlineAuthor(userId: widget.meme.userId),
            const SizedBox(height: 12),

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
                widget.meme.imageUrl,
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
                    child:
                        const Icon(Icons.broken_image_outlined, size: 64),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primary,
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
                    widget.meme.caption,
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                // Date Info Card
                Expanded(
                  child: _buildInfoCard(
                    context,
                    label: 'DIBUAT PADA',
                    value: dateStr,
                    icon: Icons.calendar_today_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _LikeButton(
                    likeCount: _localLikes.length,
                    isLiked: isLiked,
                    isLoading: _isLikeLoading,
                    isLoggedIn: currentUserId != null,
                    onTap: currentUserId != null
                        ? () => _handleLikeTap(currentUserId)
                        : null,
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

  void _showEditCaptionDialog(BuildContext context, WidgetRef ref) {
    final controller =
        TextEditingController(text: widget.meme.caption);
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'EDIT CAPTION',
          style: GoogleFonts.anton(letterSpacing: 1),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Tulis caption baru...',
            filled: true,
            fillColor:
                colorScheme.surfaceContainerHighest.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Colors.black, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Colors.black, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'BATAL',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newCaption = controller.text.trim();
              if (newCaption.isEmpty) return;

              Navigator.pop(dialogContext);

              try {
                await ref
                    .read(memeRepositoryProvider)
                    .updateMemeCaption(widget.meme.id!, newCaption);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Caption berhasil diperbarui!')),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Gagal memperbarui caption: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(100, 45),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child: const Text('SIMPAN'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'HAPUS MEME?',
          style: GoogleFonts.anton(letterSpacing: 1),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        content: Text(
          'Apakah kamu yakin ingin menghapus meme ini? Tindakan ini tidak bisa dibatalkan.',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'TIDAK',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              try {
                await ref
                    .read(memeRepositoryProvider)
                    .deleteMeme(widget.meme.id!, widget.meme.imageUrl);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Meme berhasil dihapus!')),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Gagal menghapus meme: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(100, 45),
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('HAPUS'),
          ),
        ],
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
              Icon(icon,
                  size: 16,
                  color: colorScheme.onSurface.withOpacity(0.6)),
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


class _LikeButton extends StatelessWidget {
  final int likeCount;
  final bool isLiked;
  final bool isLoading;
  final bool isLoggedIn;
  final VoidCallback? onTap;

  const _LikeButton({
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
    final borderColor =
        isLiked ? Colors.redAccent : colorScheme.onSurface;
    final textColor = isLiked ? Colors.white : colorScheme.onSurface;
    final iconColor = isLiked ? Colors.white : Colors.redAccent;
    final iconData =
        isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded;

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
                    color: textColor.withOpacity(isLiked ? 0.85 : 0.6),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Like count + tap hint
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
                      size: 14, color: textColor.withOpacity(0.5)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineAuthor extends ConsumerWidget {
  final String userId;

  const _InlineAuthor({required this.userId});

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

