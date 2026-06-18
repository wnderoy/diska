import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/show_event.dart';
import '../services/show_service.dart';
import '../theme/app_theme.dart';

class AddShowScreen extends StatefulWidget {
  final VoidCallback? onShowCreated;

  const AddShowScreen({super.key, this.onShowCreated});

  @override
  State<AddShowScreen> createState() => _AddShowScreenState();
}

class _AddShowScreenState extends State<AddShowScreen> {
  final _formKey = GlobalKey<FormState>();
  final _artistNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _venueNameController = TextEditingController();
  final _ticketLinkController = TextEditingController();

  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 20, minute: 0);
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _endTime = const TimeOfDay(hour: 23, minute: 0);
  String _selectedGenre = 'Indie Rock';
  bool _isOfficial = false;
  bool _isSubmitting = false;

  // Location picker state
  double? _selectedLatitude;
  double? _selectedLongitude;
  bool _pinDropped = false;

  final List<String> _genres = [
    'Indie Rock',
    'Electronic',
    'Jazz',
    'Folk',
    'Hip Hop',
    'Punk',
    'Reggae',
    'Blues',
    'Alternative',
    'Techno',
    'Metal',
    'Pop',
    'R&B',
    'Soul',
    'Experimental',
  ];

  @override
  void dispose() {
    _artistNameController.dispose();
    _descriptionController.dispose();
    _venueNameController.dispose();
    _ticketLinkController.dispose();
    super.dispose();
  }

  String get _formattedDate {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${_startDate.day}/${months[_startDate.month]}';
  }

  String get _autoTitle {
    final artist = _artistNameController.text.trim();
    final venue = _venueNameController.text.trim();
    if (artist.isEmpty && venue.isEmpty) return 'Untitled Show';
    if (artist.isEmpty) return '$venue - $_formattedDate';
    if (venue.isEmpty) return '$artist - $_formattedDate';
    return '$artist - $venue - $_formattedDate';
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: AppColors.textOnPrimary,
            surface: AppColors.background,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: AppColors.textOnPrimary,
            surface: AppColors.background,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _openMapPicker() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MiniMapPicker(
        initialLat: _selectedLatitude ?? 32.0853,
        initialLng: _selectedLongitude ?? 34.7818,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedLatitude = result['lat'] as double;
        _selectedLongitude = result['lng'] as double;
        _pinDropped = true;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Venue name is required when pin is dropped
    if (!_pinDropped) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please drop a pin on the map first'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
      return;
    }

    if (_selectedLatitude == null || _selectedLongitude == null) return;

    setState(() => _isSubmitting = true);

    final startDt = _combineDateAndTime(_startDate, _startTime);
    final endDt = _combineDateAndTime(_endDate, _endTime);

    if (endDt.isBefore(startDt) || endDt.isAtSameMomentAs(startDt)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('End time must be after start time'),
            backgroundColor: AppColors.primary,
          ),
        );
        setState(() => _isSubmitting = false);
      }
      return;
    }

    final show = ShowEvent(
      showId: '',
      title: _autoTitle,
      description: _descriptionController.text.trim(),
      primaryGenre: _selectedGenre,
      latitude: _selectedLatitude!,
      longitude: _selectedLongitude!,
      addressText: _venueNameController.text.trim(),
      startTime: startDt,
      endTime: endDt,
      isOfficial: _isOfficial,
      externalTicketLink: _ticketLinkController.text.trim(),
    );

    try {
      final id = await ShowService.createShow(show);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              id != null ? 'Show published!' : 'Could not create show',
            ),
            backgroundColor: AppColors.primary,
          ),
        );

        if (id != null) {
          // Reset form
          _formKey.currentState?.reset();
          _artistNameController.clear();
          _descriptionController.clear();
          _venueNameController.clear();
          _ticketLinkController.clear();
          setState(() {
            _isSubmitting = false;
            _isOfficial = false;
            _selectedGenre = 'Indie Rock';
            _selectedLatitude = null;
            _selectedLongitude = null;
            _pinDropped = false;
          });

          // Notify the map to refresh
          widget.onShowCreated?.call();
        } else {
          setState(() => _isSubmitting = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.primary,
          ),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Add a Show',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Drop a pin, fill the details, publish.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),

              // -- Artist / Band Name --
              _buildField('Artist / Band Name', _artistNameController,
                  hint: 'e.g. The Lost Trio'),
              const SizedBox(height: 14),

              // -- Genre dropdown --
              _buildGenreDropdown(),
              const SizedBox(height: 14),

              // -- Description --
              _buildField('Description', _descriptionController,
                  hint: 'Describe the vibe...', maxLines: 3,
                  required: false),
              const SizedBox(height: 14),

              // -- Location picker --
              _buildLocationSection(),
              const SizedBox(height: 14),

              // -- Venue name (appears after pin is dropped) --
              if (_pinDropped) ...[
                _buildField('Venue Name', _venueNameController,
                    hint: 'e.g. Levontin 7'),
                const SizedBox(height: 14),
              ],

              // -- Start date/time --
              _buildDateTimeRow('Start', _startDate, _startTime, true),
              const SizedBox(height: 14),

              // -- End date/time --
              _buildDateTimeRow('End', _endDate, _endTime, false),
              const SizedBox(height: 14),

              // -- Ticket link --
              _buildField('WhatsApp / Ticket Link (optional)',
                  _ticketLinkController,
                  hint: 'https://...', required: false),
              const SizedBox(height: 14),

              // -- Official toggle --
              _buildOfficialToggle(),
              const SizedBox(height: 28),

              // -- Preview of auto-generated title --
              if (_artistNameController.text.isNotEmpty ||
                  _venueNameController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Preview: $_autoTitle',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

              // -- Submit --
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    elevation: 0,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textOnPrimary,
                          ),
                        )
                      : const Text(
                          'Publish Event',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Location section: "Drop Pin on Map" button + pin confirmation
  // ---------------------------------------------------------------------------
  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _openMapPicker,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color: _pinDropped ? AppColors.primary : AppColors.surface,
              border: Border.all(color: AppColors.divider, width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  _pinDropped ? Icons.location_on : Icons.map_outlined,
                  size: 18,
                  color: _pinDropped ? AppColors.textOnPrimary : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _pinDropped
                        ? 'Pin dropped · ${_selectedLatitude!.toStringAsFixed(4)}, ${_selectedLongitude!.toStringAsFixed(4)}'
                        : 'Drop Pin on Map',
                    style: TextStyle(
                      color: _pinDropped ? AppColors.textOnPrimary : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight:
                          _pinDropped ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
                if (_pinDropped)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _pinDropped = false;
                        _selectedLatitude = null;
                        _selectedLongitude = null;
                        _venueNameController.clear();
                      });
                    },
                    child: const Icon(Icons.close,
                        size: 18, color: Colors.white70),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Generic form field
  // ---------------------------------------------------------------------------
  Widget _buildField(String label, TextEditingController controller,
      {String? hint, int maxLines = 1, bool required = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.divider, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.divider, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.divider, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          validator: (v) {
            if (!required) return null; // optional field — always valid
            return (v == null || v.trim().isEmpty) ? 'Required' : null;
          },
        ),
      ],
    );
  }

  Widget _buildGenreDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Genre',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.divider, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedGenre,
              isExpanded: true,
              dropdownColor: AppColors.background,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              items: _genres
                  .map((g) => DropdownMenuItem(
                        value: g,
                        child: Text(g),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedGenre = v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeRow(
      String label, DateTime date, TimeOfDay time, bool isStart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label Date & Time',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _pickDate(isStart),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.divider, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        '${date.day}/${date.month}/${date.year}',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => _pickTime(isStart),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.divider, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        time.format(context),
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOfficialToggle() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => setState(() => _isOfficial = !_isOfficial),
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _isOfficial ? AppColors.primary : AppColors.background,
              border: Border.all(color: AppColors.divider, width: 1.5),
            ),
            child: _isOfficial
                ? Icon(Icons.check, size: 16, color: AppColors.textOnPrimary)
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Mark as official event',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Mini-map location picker bottom sheet
// ---------------------------------------------------------------------------
class _MiniMapPicker extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  const _MiniMapPicker({
    required this.initialLat,
    required this.initialLng,
  });

  @override
  State<_MiniMapPicker> createState() => _MiniMapPickerState();
}

class _MiniMapPickerState extends State<_MiniMapPicker> {
  final MapController _mapController = MapController();
  LatLng? _tappedPoint;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.zero),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.divider, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Tap the map to drop a pin',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(Icons.close, size: 20, color: AppColors.primary),
                ),
              ],
            ),
          ),
          // Map
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter:
                        LatLng(widget.initialLat, widget.initialLng),
                    initialZoom: 13.0,
                    minZoom: 8,
                    maxZoom: 18,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                    onTap: (tapPosition, point) {
                      setState(() => _tappedPoint = point);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png',
                      userAgentPackageName: 'com.bamap.app',
                      maxZoom: 19,
                    ),
                    if (_tappedPoint != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _tappedPoint!,
                            width: 40,
                            height: 40,
                            child: const _DropPinMarker(),
                          ),
                        ],
                      ),
                  ],
                ),
                // Crosshair hint
                if (_tappedPoint == null)
                  const Center(
                    child: Icon(
                      Icons.touch_app,
                      size: 32,
                      color: Colors.black54,
                    ),
                  ),
                // Confirm button
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16 + bottomInset,
                  child: SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _tappedPoint == null
                          ? null
                          : () {
                              Navigator.of(context).pop({
                                'lat': _tappedPoint!.latitude,
                                'lng': _tappedPoint!.longitude,
                              });
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _tappedPoint != null ? AppColors.primary : Colors.grey[300],
                        foregroundColor: AppColors.textOnPrimary,
                        elevation: 0,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: Text(
                        _tappedPoint != null
                            ? 'Use This Location'
                            : 'Tap the map to place pin',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated bouncing pin marker for the mini-map picker.
class _DropPinMarker extends StatefulWidget {
  const _DropPinMarker();

  @override
  State<_DropPinMarker> createState() => _DropPinMarkerState();
}

class _DropPinMarkerState extends State<_DropPinMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bounce = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounce,
      builder: (_, child) {
        return Transform.translate(
          offset: Offset(0, -20 * (1 - _bounce.value)),
          child: child,
        ) as Widget;
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on, size: 32, color: AppColors.primary),
          SizedBox(height: 2),
          Text(
            '📍',
            style: TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
