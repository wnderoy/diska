import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/show_event.dart';
import '../services/show_service.dart';
import '../services/chat_service.dart';

class SavedShowsScreen extends StatefulWidget {
  const SavedShowsScreen({super.key});

  @override
  State<SavedShowsScreen> createState() => _SavedShowsScreenState();
}

class _SavedShowsScreenState extends State<SavedShowsScreen> {
  List<ShowEvent> _shows = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final joinedIds = await ChatService.getJoinedShowIds();
    if (joinedIds.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final allShows = await ShowService.fetchShows();
      final saved = allShows.where((s) => joinedIds.contains(s.showId)).toList();
      if (mounted) setState(() { _shows = saved; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text('Saved Shows', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Your bookmarked events', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ),
            const SizedBox(height: 16),
            Divider(color: AppColors.divider, height: 1),
            Expanded(
              child: _isLoading
                  ? Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
                  : _shows.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_border, size: 56, color: AppColors.textLight),
                              const SizedBox(height: 16),
                              Text('No saved shows', style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Text('Save a show from its detail page', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: _shows.length,
                          separatorBuilder: (_, _) => Divider(color: AppColors.divider, height: 1),
                          itemBuilder: (context, i) => _SavedTile(show: _shows[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedTile extends StatelessWidget {
  final ShowEvent show;
  const _SavedTile({required this.show});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.primary, border: Border.fromBorderSide(BorderSide(color: AppColors.divider))),
            child: Center(
              child: Text(show.title.isNotEmpty ? show.title[0].toUpperCase() : '?',
                  style: TextStyle(color: AppColors.textOnPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(show.title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('${show.primaryGenre} · ${show.rsvpCount} going', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textLight, size: 20),
        ],
      ),
    );
  }
}
