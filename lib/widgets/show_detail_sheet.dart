import 'package:flutter/material.dart';
import '../models/show_event.dart';
import '../services/chat_service.dart';
import '../screens/chat_room_screen.dart';

class ShowDetailSheet extends StatefulWidget {
  final ShowEvent show;
  final VoidCallback? onJoinedChat;

  const ShowDetailSheet({
    super.key,
    required this.show,
    this.onJoinedChat,
  });

  @override
  State<ShowDetailSheet> createState() => _ShowDetailSheetState();
}

class _ShowDetailSheetState extends State<ShowDetailSheet> {
  bool _isSaved = false;
  bool _hasJoined = false;

  @override
  void initState() {
    super.initState();
    _checkJoined();
  }

  Future<void> _checkJoined() async {
    final joined = await ChatService.hasJoinedShow(widget.show.showId);
    if (mounted) setState(() => _hasJoined = joined);
  }

  Future<void> _enterChat() async {
    // Increment RSVP if first join
    final wasNew = await ChatService.incrementRsvpIfNew(widget.show.showId);
    if (wasNew && mounted) {
      setState(() => _hasJoined = true);
      widget.onJoinedChat?.call();
    }

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(show: widget.show),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final show = widget.show;
    final isVeryShort =
        show.description.isEmpty && show.externalTicketLink.isEmpty;

    return DraggableScrollableSheet(
      initialChildSize: isVeryShort ? 0.30 : 0.40,
      minChildSize: 0.25,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.black, width: 1.5),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // -- Half-height content (always visible) --
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Artist name
                    Text(
                      show.title,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Date + venue
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          '${_formatDate(show.startTime)} · ${_formatTime(show.startTime)}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            show.addressText.isNotEmpty
                                ? show.addressText
                                : '${show.latitude.toStringAsFixed(4)}, ${show.longitude.toStringAsFixed(4)}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // RSVP count
                    Row(
                      children: [
                        Icon(Icons.people_outline,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          '${show.rsvpCount} going',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(color: Colors.black, height: 24),

              // -- Full-height content (scroll to reveal) --
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Genre tag
                    if (show.primaryGenre.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          border: Border.all(color: Colors.black),
                        ),
                        child: Text(
                          show.primaryGenre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Description
                    if (show.description.isNotEmpty) ...[
                      Text(
                        show.description,
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Action buttons
                    Row(
                      children: [
                        // Save Event
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _isSaved = !_isSaved),
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: _isSaved ? Colors.black : Colors.white,
                                border:
                                    Border.all(color: Colors.black, width: 1),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isSaved
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 18,
                                    color:
                                        _isSaved ? Colors.white : Colors.black,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isSaved ? 'Saved' : 'Save Event',
                                    style: TextStyle(
                                      color: _isSaved
                                          ? Colors.white
                                          : Colors.black,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Enter Group Chat
                        Expanded(
                          child: GestureDetector(
                            onTap: _enterChat,
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                border:
                                    Border.all(color: Colors.black, width: 1),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.message_outlined,
                                      size: 18, color: Colors.white),
                                  const SizedBox(width: 6),
                                  Text(
                                    _hasJoined
                                        ? 'Open Chat'
                                        : 'Enter Group Chat',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m $ampm';
  }
}
