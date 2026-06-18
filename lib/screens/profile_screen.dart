import 'package:flutter/material.dart';
import '../models/show_event.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Placeholder user data (replace with Firebase auth later)
  final String _username = 'melody_maven';
  final String _bio = 'Indie music lover · Tel Aviv';
  final bool _isArtist = true;
  final int _showsAttended = 24;
  final int _following = 89;
  final int _followers = 142;
  final List<String> _patchIds = ['patch_rock', 'patch_indie', 'patch_elixir'];

  // Mock lists
  final List<ShowEvent> _savedShows = [];
  final List<ShowEvent> _showHistory = [];
  final List<ShowEvent> _upcomingPerformances = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMockData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadMockData() {
    // Pull some mock shows for display purposes
    final all = ShowEvent.mockShows;
    _savedShows
      ..clear()
      ..addAll(all.take(4));
    _showHistory
      ..clear()
      ..addAll(all.skip(4).take(4));
    _upcomingPerformances
      ..clear()
      ..addAll(all.take(2));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 20),

                  // ---- Avatar with perimeter badges ----
                  Center(
                    child: SizedBox(
                      width: 110,
                      height: 110,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Avatar circle
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black,
                              border: Border.all(
                                  color: Colors.black, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                _username.isNotEmpty
                                    ? _username[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          // Perimeter badges
                          ..._buildPerimeterBadges(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ---- User name + verification ----
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _username,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (_isArtist) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_bio.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _bio,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // ---- Stats row ----
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _statBox('Shows', '$_showsAttended'),
                      const SizedBox(width: 32),
                      _statBox('Following', '$_following'),
                      const SizedBox(width: 32),
                      _statBox('Followers', '$_followers'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ---- Artist section ----
                  if (_isArtist && _upcomingPerformances.isNotEmpty) ...[
                    const Divider(color: Colors.black, height: 1),
                    _sectionHeader('My Upcoming Performances'),
                    ..._upcomingPerformances.map(
                        (show) => _ShowListTile(show: show)),
                    const SizedBox(height: 8),
                  ],

                  // ---- Saved / History tabs ----
                  const Divider(color: Colors.black, height: 1),
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.black,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                    tabs: const [
                      Tab(text: 'Saved Shows'),
                      Tab(text: 'Show History'),
                    ],
                  ),
                  const Divider(color: Colors.black, height: 1),

                  // Tab content
                  SizedBox(
                    height: _tabContentHeight(),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTabList(_savedShows, 'No saved shows yet'),
                        _buildTabList(_showHistory, 'No shows attended yet'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPerimeterBadges() {
    final patches = _patchIds.take(3).toList();
    final positions = <Offset>[
      const Offset(0, -48), // top
      const Offset(-44, 20), // bottom-left
      const Offset(44, 20), // bottom-right
    ];

    return List.generate(patches.length, (i) {
      return Positioned(
        left: 55 + positions[i].dx,
        top: 55 + positions[i].dy,
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 1.5),
          ),
          child: Icon(
            Icons.auto_awesome,
            size: 12,
            color: Colors.grey[700],
          ),
        ),
      );
    });
  }

  Widget _statBox(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  double _tabContentHeight() {
    // Rough estimate based on item count
    final tab = _tabController.index;
    final count = tab == 0 ? _savedShows.length : _showHistory.length;
    return (count.clamp(1, 10) * 72.0) + 16;
  }

  Widget _buildTabList(List<ShowEvent> shows, String emptyText) {
    if (shows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Text(
            emptyText,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: shows.length,
      separatorBuilder: (_, _) =>
          const Divider(color: Color(0xFFEEEEEE), height: 1),
      itemBuilder: (context, i) => _ShowListTile(show: shows[i]),
    );
  }
}

class _ShowListTile extends StatelessWidget {
  final ShowEvent show;

  const _ShowListTile({required this.show});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border.all(color: Colors.black, width: 1),
            ),
            child: Center(
              child: Text(
                show.title.isNotEmpty ? show.title[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
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
                  '${show.primaryGenre} · ${_formatDate(show.startTime)}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[300], size: 18),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month]}';
  }
}
