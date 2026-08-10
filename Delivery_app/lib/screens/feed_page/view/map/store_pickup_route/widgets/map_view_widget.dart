import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hyper_local/config/constant.dart';

class MapViewWidget extends StatelessWidget {
  final MapController mapController;
  final LatLng initialCenter;
  final List<Polyline> polylines;
  final List<Marker> markers;
  final VoidCallback onMapReady;
  final bool showMapContent;

  const MapViewWidget({
    super.key,
    required this.mapController,
    required this.initialCenter,
    required this.polylines,
    required this.markers,
    required this.onMapReady,
    required this.showMapContent,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 15.0, // Increased default zoom for better visibility
        onMapReady: onMapReady,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://server.arcgisonline.com/ArcGIS/rest/services/'
              'World_Topo_Map/MapServer/tile/{z}/{y}/{x}',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: packageName,
        ),
        // Only show polylines and markers when content is available
        if (showMapContent) ...[
          PolylineLayer(polylines: polylines),
          MarkerLayer(markers: markers),
        ],
      ],
    );
  }
}
