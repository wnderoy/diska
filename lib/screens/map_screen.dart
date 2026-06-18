import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/show_event.dart';
import '../services/show_service.dart';
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

  /// Build a lookup map from position key -> RSVP count.
  /// Used by the cluster builder since Marker has no data field.
  Map<String, int> _buildRsvpLookup(List<ShowEvent> shows) {
    final lookup = <String, int>{};
    for (final show in shows) {
      lookup[_posKey(show.position)] = show.rsvpCount;
    }
    return lookup;
  }

  String _posKey(LatLng p) => '${p.latitude},${p.longitude}';

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
    final rsvpLookup = _buildRsvpLookup(filtered);

    return Stack(
      children: [
        // ---- Loading overlay ----
        if (_isLoadingShows)
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Loading shows...',
                  style: TextStyle(
                    color: Colors.black,
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
                  // Sum RSVPs by looking up each marker's point
                  int totalRsvp = 0;
                  for (final m in clusterMarkers) {
                    final key = _posKey(m.point);
                    totalRsvp += rsvpLookup[key] ?? 1;
                  }
                  return _ClusterWidget(count: totalRsvp);
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
                onTap: () => _mapController.move(
                  _mapController.camera.center,
                  (_currentZoom + 1).clamp(8.0, 18.0),
                ),
              ),
              const SizedBox(height: 1),
              Container(height: 1, width: 20, color: Colors.black),
              const SizedBox(height: 1),
              _MapButton(
                icon: Icons.remove,
                onTap: () => _mapController.move(
                  _mapController.camera.center,
                  (_currentZoom - 1).clamp(8.0, 18.0),
                ),
              ),
              const SizedBox(height: 12),
              _MapButton(
                icon: Icons.my_location,
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
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: Text(
                  '${filtered.length} show${filtered.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Colors.black,
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
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  child: Center(
                    child: _isRefreshing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(Icons.refresh, size: 18, color: Colors.black),
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
// Cluster widget — large circle with RSVP count
// ---------------------------------------------------------------------------
class _ClusterWidget extends StatelessWidget {
  final int count;
  const _ClusterWidget({required this.count});

  @override
  Widget build(BuildContext context) {
    final radius = min(20.0 + count * 0.3, 34.0);
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compact marker — photo circle + artist name
// ---------------------------------------------------------------------------
class _CompactMarker extends StatelessWidget {
  final ShowEvent show;
  const _CompactMarker({required this.show});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[200],
            border: Border.all(color: Colors.black, width: 1.5),
          ),
          child: Center(
            child: Text(
              show.artist[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 1),
          ),
          child: Text(
            show.artist,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Very close marker — full photo card with overlay info
// ---------------------------------------------------------------------------
class _VeryCloseMarker extends StatelessWidget {
  final ShowEvent show;
  const _VeryCloseMarker({required this.show});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 120,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            border: Border.all(color: Colors.black, width: 1.5),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _PhotoPlaceholderPainter(letter: show.artist[0]),
                ),
              ),
              // Bottom overlay: artist + date
              Positioned(
                left: 4,
                right: 4,
                bottom: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  color: Colors.black.withValues(alpha: 0.85),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        show.artist,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${_formatDate(show.startTime)} · ${_formatTime(show.startTime)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 7,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // RSVP count badge top-right
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  color: Colors.black,
                  child: Text(
                    '${show.rsvpCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        if (show.genre.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 1),
            ),
            child: Text(
              show.genre,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 8,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month]}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:${dt.minute.toString().padLeft(2, '0')}$ampm';
  }
}

// ---------------------------------------------------------------------------
// Photo placeholder painter — B&W diagonal pattern with initial
// ---------------------------------------------------------------------------
class _PhotoPlaceholderPainter extends CustomPainter {
  final String letter;
  _PhotoPlaceholderPainter({required this.letter});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFE0E0E0);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final stripePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (double i = -size.height; i < size.width + size.height; i += 8) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i - size.height, size.height),
        stripePaint,
      );
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          color: Colors.black.withValues(alpha: 0.15),
          fontSize: size.height * 0.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: 'Search artists, venues...',
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 20),
          suffixIcon: _controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _controller.clear();
                    widget.onChanged('');
                    setState(() {});
                  },
                  child: Icon(Icons.close, color: Colors.grey[600], size: 18),
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
                color: isActive ? Colors.black : Colors.white,
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: Center(
                child: Text(
                  genre,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.black,
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

  const _MapButton({
    required this.icon,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : Icon(icon, size: 20, color: Colors.black),
        ),
      ),
    );
  }
}
