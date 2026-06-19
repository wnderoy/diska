import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/show_event.dart';
import '../services/show_service.dart';
import '../theme/app_theme.dart';
import '../widgets/show_detail_sheet.dart';

class MapScreen extends StatefulWidget {
  final int refreshCounter;

  const MapScreen({super.key, this.refreshCounter = 0});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  List<ShowEvent> _shows = [];
  final Set<String> _activeFilters = {};
  String _searchQuery = '';
  bool _isLocating = false;
  bool _isLoadingShows = true;
  bool _isRefreshing = false;
  double _currentZoom = _initialZoom;

  static const double _initialZoom = 11.0;
  static const LatLng _telAvivCenter = LatLng(32.0853, 34.7818);

  // Zoom threshold for very-detailed markers
  static const double _closeZoom = 15.5;

  @override
  void initState() {
    super.initState();
    _loadShows();
  }

  @override
  void didUpdateWidget(MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshCounter != oldWidget.refreshCounter) {
      _loadShows();
    }
  }

  Future<void> _loadShows() async {
    final shows = await ShowService.fetchShows();
    if (mounted) {
      setState(() {
        _shows = shows;
        _isLoadingShows = false;
      });
    }
  }

  List<ShowEvent> get _filteredShows {
    return _shows.where((show) {
      if (_activeFilters.isNotEmpty && !_activeFilters.contains(show.genre)) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!show.title.toLowerCase().contains(q) &&
            !show.artist.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  List<String> get _allGenres =>
      _shows.map((s) => s.genre).toSet().toList()..sort();

  ShowEvent? _findShowByPoint(LatLng point) {
    for (final show in _shows) {
      final d = (point.latitude - show.latitude).abs() +
          (point.longitude - show.longitude).abs();
      if (d < 0.001) return show;
    }
    return null;
  }

  void _onMarkerTap(ShowEvent? show) {
    if (show == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShowDetailSheet(
        show: show,
        onJoinedChat: () {
          // Refresh show data after joining chat
          _loadShows();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredShows;

    return Stack(
      children: [
        // ---- Loading overlay ----
        if (_isLoadingShows)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Loading shows...',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else ...[
        // ---- Map ----
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _telAvivCenter,
            initialZoom: _initialZoom,
            minZoom: 8,
            maxZoom: 18,
            onMapReady: () {
              setState(() => _currentZoom = _initialZoom);
            },
            onMapEvent: (event) {
              if (event is MapEventMoveEnd || event is MapEventRotateEnd) {
                setState(() => _currentZoom = _mapController.camera.zoom);
              }
            },
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            // Black-and-white tile layer (CartoDB Positron)
            TileLayer(
              urlTemplate:
                  'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png',
              userAgentPackageName: 'com.bamap.app',
              maxZoom: 19,
            ),
            // Marker cluster layer
            MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                maxClusterRadius: 50,
                size: const Size(44, 44),
                markers: filtered
                    .map((show) => _buildMarker(show, _currentZoom))
                    .toList(),
                showPolygon: false,
                disableClusteringAtZoom: 16,
                onMarkerTap: (marker) => _onMarkerTap(_findShowByPoint(marker.point)),
                builder: (context, clusterMarkers) {
                  return _ClusterWidget(count: clusterMarkers.length);
                },
              ),
            ),
          ],
        ),

        // ---- Search bar ----
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          right: 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SearchBar(
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
              const SizedBox(height: 6),
              _FilterChips(
                genres: _allGenres,
                activeFilters: _activeFilters,
                onToggle: (genre) {
                  setState(() {
                    if (_activeFilters.contains(genre)) {
                      _activeFilters.remove(genre);
                    } else {
                      _activeFilters.add(genre);
                    }
                  });
                },
              ),
            ],
          ),
        ),

        // ---- Zoom & Recenter controls ----
        Positioned(
          right: 12,
          bottom: 24,
          child: Column(
            children: [
              _MapButton(
                icon: Icons.add,
                colorIndex: 0,
                onTap: () => _mapController.move(
                  _mapController.camera.center,
                  (_currentZoom + 1).clamp(8.0, 18.0),
                ),
              ),
              const SizedBox(height: 1),
              Container(height: 1, width: 20, color: AppColors.divider),
              const SizedBox(height: 1),
              _MapButton(
                icon: Icons.remove,
                colorIndex: 1,
                onTap: () => _mapController.move(
                  _mapController.camera.center,
                  (_currentZoom - 1).clamp(8.0, 18.0),
                ),
              ),
              const SizedBox(height: 12),
              _MapButton(
                icon: Icons.my_location,
                colorIndex: 2,
                isLoading: _isLocating,
                onTap: _recenter,
              ),
            ],
          ),
        ),

        // ---- Show count badge + refresh (bottom left) ----
        Positioned(
          left: 12,
          bottom: 24,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border.all(color: AppColors.divider, width: 1),
                ),
                child: Text(
                  '${filtered.length} show${filtered.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _isRefreshing
                    ? null
                    : () async {
                        setState(() => _isRefreshing = true);
                        await _loadShows();
                        if (mounted) {
                          setState(() => _isRefreshing = false);
                        }
                      },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    border: Border.all(color: AppColors.divider, width: 1),
                  ),
                  child: Center(
                    child: _isRefreshing
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : Icon(Icons.refresh, size: 18, color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ---- Close else spread ----
        ],
      ],
    );
  }

  Marker _buildMarker(ShowEvent show, double zoom) {
    if (zoom >= _closeZoom) {
      // Very close: full detail marker with photo + overlays
      return Marker(
        point: show.position,
        width: 140,
        height: 160,
        child: _VeryCloseMarker(show: show),
      );
    } else {
      // Default: compact marker with photo thumbnail + artist
      return Marker(
        point: show.position,
        width: 100,
        height: 120,
        child: _CompactMarker(show: show),
      );
    }
  }

  Future<void> _recenter() async {
    setState(() => _isLocating = true);
    try {
      if (await Geolocator.isLocationServiceEnabled()) {
        final status = await Geolocator.checkPermission();
        if (status == LocationPermission.denied) {
          await Geolocator.requestPermission();
        }
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        ).timeout(const Duration(seconds: 12), onTimeout: () {
          throw Exception('Location timeout');
        });
        if (mounted) {
          _mapController.move(LatLng(pos.latitude, pos.longitude), 15.0);
        }
      } else {
        _mapController.move(_telAvivCenter, 13.0);
      }
    } catch (_) {
      _mapController.move(_telAvivCenter, 13.0);
    }
    if (mounted) {
      setState(() => _isLocating = false);
    }
  }
}

// ---------------------------------------------------------------------------
// Cluster widget — colorful circle with RSVP count
// ---------------------------------------------------------------------------
class _ClusterWidget extends StatelessWidget {
  final int count;
  const _ClusterWidget({required this.count});

  @override
  Widget build(BuildContext context) {
    final radius = min(20.0 + count * 0.3, 34.0);
    final accent = AppColors.accentByIndex(count);
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent,
        border: Border.all(color: AppColors.background, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$count',
          style: TextStyle(
            color: AppColors.textOnPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compact marker — photo thumbnail + colorful sticker tags
// ---------------------------------------------------------------------------
class _CompactMarker extends StatelessWidget {
  final ShowEvent show;
  const _CompactMarker({required this.show});

  String get _photoUrl =>
      'https://picsum.photos/seed/${show.showId}/200/200';

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accentByIndex(show.showId.hashCode);
    return SizedBox(
      width: 96,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Photo with colorful border + floating sticker
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accent, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                  image: DecorationImage(
                    image: NetworkImage(_photoUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Floating genre sticker (bottom-right edge)
              if (show.genre.isNotEmpty)
                Positioned(
                  bottom: -2,
                  right: -4,
                  child: Transform.rotate(
                    angle: 0.12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.accentByIndex(
                            show.showId.hashCode + 2),
                        border: Border.all(
                          color: AppColors.accentByIndex(
                              show.showId.hashCode + 2),
                          width: 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors
                                .accentByIndex(
                                    show.showId.hashCode + 2)
                                .withValues(alpha: 0.4),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        show.genre,
                        style: TextStyle(
                          color: _textOnAccent(
                              show.showId.hashCode + 2),
                          fontSize: 6,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          // Artist name tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border.all(color: accent, width: 1),
            ),
            child: Text(
              show.artist,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Very close marker — full photo card with colorful sticker overlays
// ---------------------------------------------------------------------------
class _VeryCloseMarker extends StatelessWidget {
  final ShowEvent show;
  const _VeryCloseMarker({required this.show});

  String get _photoUrl =>
      'https://picsum.photos/seed/${show.showId}/240/160';

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accentByIndex(show.showId.hashCode);
    final dateStr = _formatDate(show.startTime);
    final genreStr = show.genre;

    return SizedBox(
      width: 130,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Photo card with colorful border
          Container(
            width: 120,
            height: 76,
            decoration: BoxDecoration(
              border: Border.all(color: accent, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
              image: DecorationImage(
                image: NetworkImage(_photoUrl),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                // Dark gradient overlay for readability
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.primary.withValues(alpha: 0.7),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                ),
                // --- FLOATING CORNER STICKER: date (top-left) ---
                Positioned(
                  top: -1,
                  left: -1,
                  child: Transform.rotate(
                    angle: -0.08,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: accent,
                        border: Border.all(
                            color: accent, width: 0.5),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.4),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        _formatDate(show.startTime),
                        style: TextStyle(
                          color: _textOnAccent(
                              show.showId.hashCode),
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                // --- FLOATING CORNER STICKER: genre (bottom-right) ---
                if (show.genre.isNotEmpty)
                  Positioned(
                    bottom: -1,
                    right: -1,
                    child: Transform.rotate(
                      angle: 0.06,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentByIndex(
                              show.showId.hashCode + 1),
                          border: Border.all(
                            color: AppColors.accentByIndex(
                                show.showId.hashCode + 1),
                            width: 0.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors
                                  .accentByIndex(
                                      show.showId.hashCode + 1)
                                  .withValues(alpha: 0.4),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          show.genre,
                          style: TextStyle(
                            color: _textOnAccent(
                                show.showId.hashCode + 1),
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Artist name bottom-left
                Positioned(
                  left: 5,
                  right: 5,
                  bottom: 4,
                  child: Text(
                    show.artist,
                    style: TextStyle(
                      color: AppColors.textOnPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // RSVP badge top-right
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    color: accent,
                    child: Text(
                      '${show.interestedCount}',
                      style: TextStyle(
                        color: AppColors.textOnPrimary,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Colorful sticker row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Date sticker
              if (dateStr.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: accent,
                      border: Border.all(color: accent, width: 1),
                    ),
                    child: Text(
                      dateStr,
                      style: TextStyle(
                        color: AppColors.textOnPrimary,
                        fontSize: 7,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              // Genre sticker (different accent color)
              if (genreStr.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.accentByIndex(show.showId.hashCode + 1),
                    border: Border.all(
                      color: AppColors.accentByIndex(show.showId.hashCode + 1),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    genreStr,
                    style: TextStyle(
                      color: _textOnAccent(show.showId.hashCode + 1),
                      fontSize: 7,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// Helpers
Color _textOnAccent(int i) {
  if (i % 3 == 1) return AppColors.primary;
  return AppColors.textOnPrimary;
}

String _formatDate(DateTime dt) {
  const months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${dt.day} ${months[dt.month]}';
}

// ---------------------------------------------------------------------------
// Search bar
// ---------------------------------------------------------------------------
class _SearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.onChanged});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.pink.withValues(alpha: 0.15),
        border: Border.all(color: AppColors.purple, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        onChanged: (v) {
          widget.onChanged(v);
          setState(() {});
        },
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: 'Search artists, venues...',
          hintStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(Icons.search, color: AppColors.primary, size: 20),
          suffixIcon: _controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _controller.clear();
                    widget.onChanged('');
                    setState(() {});
                  },
                  child: Icon(Icons.close, color: AppColors.primary, size: 18),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter chips row
// ---------------------------------------------------------------------------
class _FilterChips extends StatelessWidget {
  final List<String> genres;
  final Set<String> activeFilters;
  final ValueChanged<String> onToggle;

  const _FilterChips({
    required this.genres,
    required this.activeFilters,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: genres.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final genre = genres[i];
          final isActive = activeFilters.contains(genre);
          return GestureDetector(
            onTap: () => onToggle(genre),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? AppColors.lime : AppColors.primary.withValues(alpha: 0.08),
                border: Border.all(color: isActive ? AppColors.lime : AppColors.primary, width: 1),
              ),
              child: Center(
                child: Text(
                  genre,
                  style: TextStyle(
                    color: isActive ? AppColors.primary : AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Map floating button (zoom in/out, recenter)
// ---------------------------------------------------------------------------
class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isLoading;
  final int colorIndex;

  const _MapButton({
    required this.icon,
    required this.onTap,
    this.isLoading = false,
    this.colorIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = AppColors.accentByIndex(colorIndex);
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: borderColor,
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: 0.4),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textOnPrimary,
                  ),
                )
              : Icon(icon, size: 20, color: AppColors.primary),
        ),
      ),
    );
  }
}
