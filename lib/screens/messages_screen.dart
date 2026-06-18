import 'package:flutter/material.dart';
import '../models/show_event.dart';
import '../services/chat_service.dart';
import 'chat_room_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<ShowEvent> _shows = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShows();
  }

  Future<void> _loadShows() async {
    final shows = await ChatService.getUserShows();
    if (mounted) {
      setState(() {
        _shows = shows;
        _isLoading = false;
      });
    }
  }

  void _openChat(ShowEvent show) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(show: show),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text(
                'Messages',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Your active show chats',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.black, height: 1),
            // List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      ),
                    )
                  : _shows.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.message_outlined,
                                  size: 56, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                'No chats yet',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Join a show chat to see it here',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadShows,
                          child: ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: _shows.length,
                            separatorBuilder: (_, _) =>
                                const Divider(color: Colors.black, height: 1),
                            itemBuilder: (context, i) {
                              final show = _shows[i];
                              return _ChatChannelTile(
                                show: show,
                                onTap: () => _openChat(show),
                              );
                            },
                          ),
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

  const _ChatChannelTile({
    required this.show,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // Avatar placeholder
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.black),
              ),
              child: Center(
                child: Text(
                  show.title.isNotEmpty ? show.title[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    show.title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${show.rsvpCount} going · ${show.primaryGenre}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Chevron
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}
