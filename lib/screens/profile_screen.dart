import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/show_event.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  UserModel? _user;
  List<ShowEvent> _savedShows = [];
  List<ShowEvent> _showHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    _user = await AuthService.fetchProfile();
    if (_user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // Fetch saved shows
    final savedIds = await AuthService.getSavedShowIds();
    List<ShowEvent> saved = [];
    if (savedIds.isNotEmpty) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('shows')
            .where(FieldPath.documentId, whereIn: savedIds.take(10).toList())
            .get(const GetOptions(source: Source.server));
        saved = snap.docs
            .map((doc) => ShowEvent.fromJson({...doc.data(), 'show_id': doc.id}))
            .toList();
      } catch (_) {}
    }

    // Show history: fetch from a subcollection or use mock for now
    List<ShowEvent> history = [];
    try {
      final historySnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(AuthService.userId)
          .collection('show_history')
          .orderBy('start_time', descending: true)
          .limit(10)
          .get(const GetOptions(source: Source.server));
      history = historySnap.docs
          .map((doc) => ShowEvent.fromJson({...doc.data(), 'show_id': doc.id}))
          .toList();
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _savedShows = saved;
      _showHistory = history;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: SizedBox(
          width: 20, height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
        ),
      );
    }

    final user = _user;
    if (user == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline, size: 56, color: AppColors.textLight),
            const SizedBox(height: 12),
            Text('Could not load profile', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    final displayedPatches = user.displayedPatchIds.take(3).toList();

    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 24),

                  // Avatar + perimeter badges
                  Center(
                    child: SizedBox(
                      width: 110,
                      height: 110,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                              border: Border.fromBorderSide(BorderSide(color: AppColors.divider, width: 2)),
                            ),
                            child: Center(
                              child: Text(
                                user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                                style: TextStyle(color: AppColors.textOnPrimary, fontSize: 32, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          ...List.generate(displayedPatches.length, (i) {
                            final positions = [
                              const Offset(0, -48),
                              const Offset(-44, 20),
                              const Offset(44, 20),
                            ];
                            return Positioned(
                              left: 55 + positions[i].dx,
                              top: 55 + positions[i].dy,
                              child: Container(
                                width: 22, height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.background,
                                  border: Border.all(color: AppColors.divider, width: 1.5),
                                ),
                                child: Icon(Icons.auto_awesome, size: 12, color: AppColors.textSecondary),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Username + verified badge
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(user.username, style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                        if (user.isVerified) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 18, height: 18,
                            decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                            child: Icon(Icons.check, size: 12, color: AppColors.textOnPrimary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (user.bio.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(user.bio, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ),
                  const SizedBox(height: 16),

                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _statBox('Shows', '${_showHistory.length}'),
                      const SizedBox(width: 32),
                      _statBox('Following', '${user.followingCount}'),
                      const SizedBox(width: 32),
                      _statBox('Followers', '${user.followersCount}'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Artist section
                  if (user.isArtist && _savedShows.isNotEmpty) ...[
                    Divider(color: AppColors.divider, height: 1),
                    _sectionHeader('My Upcoming Performances'),
                    ..._savedShows.take(3).map((show) => _ShowListTile(show: show)),
                    const SizedBox(height: 8),
                  ],

                  // Tabs
                  Divider(color: AppColors.divider, height: 1),
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primary,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
                    tabs: const [Tab(text: 'Saved Shows'), Tab(text: 'Show History')],
                  ),
                  Divider(color: AppColors.divider, height: 1),

                  SizedBox(
                    height: ((_tabController.index == 0 ? _savedShows.length : _showHistory.length).clamp(1, 10) * 72.0) + 16,
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

  Widget _statBox(String label, String value) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Text(title, style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildTabList(List<ShowEvent> shows, String emptyText) {
    if (shows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Text(emptyText, style: TextStyle(color: AppColors.textLight, fontSize: 13)),
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: shows.length,
      separatorBuilder: (_, _) => Divider(color: AppColors.surfaceAlt, height: 1),
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
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.surfaceAlt, border: Border.all(color: AppColors.divider, width: 1)),
            child: Center(
              child: Text(show.title.isNotEmpty ? show.title[0].toUpperCase() : '?',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(show.title, style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('${show.primaryGenre} · ${_formatDate(show.startTime)}', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textLight, size: 18),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month]}';
  }
}
