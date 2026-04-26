import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/meme_model.dart';
import '../providers/auth_provider.dart';
import '../providers/meme_provider.dart';
import '../theme/neo_brutal_ui.dart';
import 'like_button.dart';
import 'inline_author.dart';

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
    final isLiked = currentUserId != null && _localLikes.contains(currentUserId);

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
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
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
            InlineAuthor(userId: widget.meme.userId),
            const SizedBox(height: 12),
            Container(
              decoration: NeoBrutalUI.boxDecoration(
                context,
                color: Colors.black,
                radius: 20,
                width: 2.5,
                hasShadow: true,
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
                    child: const Icon(Icons.broken_image_outlined, size: 64),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: NeoBrutalUI.boxDecoration(
                context,
                color: colorScheme.primary,
                radius: 16,
                width: 2,
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
                  child: LikeButton(
                    likeCount: _localLikes.length,
                    isLiked: isLiked,
                    isLoading: _isLikeLoading,
                    isLoggedIn: currentUserId != null,
                    onTap: currentUserId != null ? () => _handleLikeTap(currentUserId) : null,
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
    final controller = TextEditingController(text: widget.meme.caption);
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
            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black, width: 1.5),
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
                await ref.read(memeRepositoryProvider).updateMemeCaption(widget.meme.id!, newCaption);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Caption berhasil diperbarui!')),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal memperbarui caption: $e')),
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
                await ref.read(memeRepositoryProvider).deleteMeme(widget.meme.id!, widget.meme.imageUrl);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Meme berhasil dihapus!')),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus meme: $e')),
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
      decoration: NeoBrutalUI.boxDecoration(
        context,
        radius: 16,
        width: 1.5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.anton(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
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
