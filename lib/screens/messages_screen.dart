import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/show_event.dart';
import '../services/auth_service.dart';
import 'chat_room_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<ShowEvent> _shows = [];
  StreamSubscription<List<ShowEvent>>? _savedSub;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  void _initStream() {
    final uid = AuthService.userId;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Real-time stream: listen to the user's saved_shows array
    _savedSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .asyncMap((snapshot) async {
      if (!snapshot.exists) return <ShowEvent>[];
      final data = snapshot.data()!;
      final savedIds = (data['saved_shows'] as List<dynamic>?)?.cast<String>() ?? [];
      if (savedIds.isEmpty) return <ShowEvent>[];

      // Fetch the show documents for the saved IDs
      final showsSnapshot = await FirebaseFirestore.instance
          .collection('shows')
          .where(FieldPath.documentId, whereIn: savedIds.take(10).toList())
          .get(const GetOptions(source: Source.server));

      return showsSnapshot.docs
          .map((doc) => ShowEvent.fromJson({...doc.data(), 'show_id': doc.id}))
          .toList();
    }).listen(
      (shows) {
        if (!mounted) return;
        setState(() {
          _shows = shows;
          _isLoading = false;
        });
      },
      onError: (_) {
        if (mounted) setState(() => _isLoading = false);
      },
    );
  }

  @override
  void dispose() {
    _savedSub?.cancel();
    super.dispose();
  }

  void _openChat(ShowEvent show) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatRoomScreen(show: show)),
    );
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
              child: Text('Messages', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Your active show chats', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ),
            const SizedBox(height: 16),
            Divider(color: AppColors.divider, height: 1),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      ),
                    )
                  : _shows.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.message_outlined, size: 56, color: AppColors.textLight),
                              const SizedBox(height: 16),
                              Text('No chats yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Text('Save a show to start chatting', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: _shows.length,
                          separatorBuilder: (_, _) => Divider(color: AppColors.divider, height: 1),
                          itemBuilder: (context, i) => _ChatChannelTile(show: _shows[i], onTap: () => _openChat(_shows[i])),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatChannelTile extends StatelessWidget {
  final ShowEvent show;
  final VoidCallback onTap;
  const _ChatChannelTile({required this.show, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: AppColors.primary, border: Border.fromBorderSide(BorderSide(color: AppColors.divider))),
              child: Center(
                child: Text(
                  show.title.isNotEmpty ? show.title[0].toUpperCase() : '?',
                  style: TextStyle(color: AppColors.textOnPrimary, fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(show.title, style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${show.rsvpCount} going · ${show.primaryGenre}', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textLight, size: 20),
          ],
        ),
      ),
    );
  }
}
