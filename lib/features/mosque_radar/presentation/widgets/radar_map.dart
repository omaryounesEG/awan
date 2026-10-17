import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';

import 'package:awan/core/constants/app_colors.dart';
import 'package:awan/core/constants/app_constants.dart';
import 'package:awan/features/mosque_radar/domain/entities/mosque_entity.dart';
import 'package:awan/features/mosque_radar/presentation/widgets/map_style.dart';

/// The radar's map, in whichever renderer this build can afford.
///
/// * **Google** (`google_maps_flutter`) when a Maps key is present — merged with
///   [minimalistMapStyleJson], a 2 km radius circle and the same green mosque
///   markers as the card list.
/// * **OpenStreetMap** (`flutter_map`) otherwise. This is not a downgrade for
///   the sake of it: a Google map without a key renders as a grey grid with an
///   error banner, so the keyless build would look broken. OSM tiles need no key,
///   they are already a dependency, and they keep the radar usable on a fresh
///   clone.
///
/// Either way the markers come from the same `List<MosqueEntity>`, so the map and
/// the cards can never disagree about who is nearest.
class RadarMap extends StatelessWidget {
  const RadarMap({
    super.key,
    required this.center,
    required this.mosques,
    required this.radiusMeters,
    this.onMarkerTap,
  });

  final LatLng center;
  final List<MosqueEntity> mosques;
  final int radiusMeters;
  final void Function(MosqueEntity mosque)? onMarkerTap;

  bool get _useGoogle => AppConstants.hasGoogleMapsKey;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: _useGoogle
          ? _buildGoogle(context, theme)
          : _buildOsm(context, theme),
    );
  }

  // ------------------------------------------------------------------ google

  Widget _buildGoogle(BuildContext context, ThemeData theme) {
    final gmaps.LatLng target = gmaps.LatLng(center.latitude, center.longitude);

    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(target: target, zoom: 14.2),
      style: minimalistMapStyleJson,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      circles: <gmaps.Circle>{
        gmaps.Circle(
          circleId: const gmaps.CircleId('search-radius'),
          center: target,
          radius: radiusMeters.toDouble(),
          // A whisper of colour: the circle is context, not content.
          fillColor: AppColors.radar.withOpacity(0.07),
          strokeColor: AppColors.radar.withOpacity(0.35),
          strokeWidth: 1,
        ),
      },
      markers: <gmaps.Marker>{
        gmaps.Marker(
          markerId: const gmaps.MarkerId('me'),
          position: target,
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueAzure,
          ),
        ),
        for (final MosqueEntity mosque in mosques)
          gmaps.Marker(
            markerId: gmaps.MarkerId(mosque.id),
            position: gmaps.LatLng(mosque.latitude, mosque.longitude),
            icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
              gmaps.BitmapDescriptor.hueGreen,
            ),
            infoWindow: gmaps.InfoWindow(title: mosque.name),
            onTap: () => onMarkerTap?.call(mosque),
          ),
      },
    );
  }

  // ------------------------------------------------------------- openstreetmap

  Widget _buildOsm(BuildContext context, ThemeData theme) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14.2,
        // Rotation on a mosque radar is a way to lose your bearings, not find
        // them: everything else stays interactive.
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: <Widget>[
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.saip.awan',
          maxZoom: 19,
        ),
        CircleLayer(
          circles: <CircleMarker>[
            CircleMarker(
              point: center,
              radius: radiusMeters.toDouble(),
              useRadiusInMeter: true,
              color: AppColors.radar.withOpacity(0.07),
              borderColor: AppColors.radar.withOpacity(0.35),
              borderStrokeWidth: 1,
            ),
          ],
        ),
        MarkerLayer(
          markers: <Marker>[
            Marker(
              point: center,
              width: 22,
              height: 22,
              child: const _UserDot(),
            ),
            for (final MosqueEntity mosque in mosques)
              Marker(
                point: LatLng(mosque.latitude, mosque.longitude),
                width: 88,
                height: 52,
                child: GestureDetector(
                  onTap: () => onMarkerTap?.call(mosque),
                  child: _MosquePin(name: mosque.name),
                ),
              ),
          ],
        ),
        // Required by the OSM tile usage policy.
        const SimpleAttributionWidget(
          source: Text('OpenStreetMap contributors'),
        ),
      ],
    );
  }
}

class _UserDot extends StatelessWidget {
  const _UserDot();

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.radar, width: 3),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      );
}

/// A mosque pin: a small rounded card with an icon and the name, so the map is
/// self-explanatory without first reading the list underneath.
class _MosquePin extends StatelessWidget {
  const _MosquePin({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.radar.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.mosque, size: 13, color: AppColors.radar),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.radar),
      ],
    );
  }
}
