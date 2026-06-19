import 'package:flutter/material.dart';
import '../models/show_event.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';
import 'chat_room_screen.dart';

class ShowPageScreen extends StatefulWidget {
  final ShowEvent show;

  const ShowPageScreen({super.key, required this.show});

  @override
  State<ShowPageScreen> createState() => _ShowPageScreenState();
}

class _ShowPageScreenState extends State<ShowPageScreen> {
  bool _isInterested = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkInterested();
  }

  Future<void> _checkInterested() async {
    final marked = await ChatService.hasMarkedInterested(widget.show.showId);
    if (mounted) setState(() => _isInterested = marked);
  }

  Future<void> _toggleInterested() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final success = await ChatService.markInterested(widget.show.showId);
    if (mounted) {
      setState(() {
        if (success) _isInterested = true;
        _isLoading = false;
      });
    }
  }

  void _navigateToChat() {
    if (!_isInterested) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(show: widget.show),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} · $h:$min $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final show = widget.show;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // -- Purple AppBar --
          SliverAppBar(
            backgroundColor: AppColors.purple,
            foregroundColor: Colors.white,
            pinned: true,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              show.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // -- Hero photo w/ gradient overlay --
          SliverToBoxAdapter(
            child: Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 260,
                  child: Image.network(
                    'https://picsum.photos/seed/${show.showId}/600/300',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surfaceDark,
                      child: Center(
                        child: Icon(
                          Icons.music_note,
                          size: 64,
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
                  ),
                ),
                // Dark gradient overlay at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 80,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // -- Show details --
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    show.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Date
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(show.startTime),
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Venue
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          show.addressText.isNotEmpty
                              ? show.addressText
                              : '${show.latitude.toStringAsFixed(4)}, ${show.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Genre tag + interested count
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.lime,
                          border: Border.all(
                              color: AppColors.divider, width: 1),
                        ),
                        child: Text(
                          show.primaryGenre,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.favorite_border,
                          size: 14, color: AppColors.pink),
                      const SizedBox(width: 4),
                      Text(
                        '${show.interestedCount} interested',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Description
                  if (show.description.isNotEmpty) ...[
                    Text(
                      show.description,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // -- Action buttons --
                  Row(
                    children: [
                      // "I'm Interested" button
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _toggleInterested,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.pink,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  AppColors.pink.withValues(alpha: 0.5),
                              disabledForegroundColor:
                                  Colors.white.withValues(alpha: 0.7),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _isInterested
                                            ? Icons.check
                                            : Icons.favorite_border,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _isInterested
                                            ? 'Interested ✓'
                                            : "I'm Interested",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // "Join Chat" button
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isInterested ? _navigateToChat : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.purple,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  AppColors.surfaceDark,
                              disabledForegroundColor:
                                  AppColors.textLight,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isInterested
                                      ? Icons.chat_bubble_outline
                                      : Icons.lock,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    _isInterested
                                        ? 'Join Chat'
                                        : 'Mark Interested First',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
