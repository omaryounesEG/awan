/// The Google Maps JSON style used by the radar.
///
/// Hand-written for this app rather than lifted from a gallery: the goal is the
/// same "zen" the rest of Awan uses — sand land, blue-grey water, no POI pins, no
/// transit clutter, no road labels except the major ones, and the entire
/// business layer hidden. A map full of shop logos would undo the calm of the
/// dashboard in one glance.
///
/// Only used with `google_maps_flutter`. The keyless OpenStreetMap renderer has
/// its own calmer tiles and no style parameter.
const String minimalistMapStyleJson = '''
[
  { "elementType": "geometry", "stylers": [ { "color": "#F1EDE3" } ] },
  { "elementType": "labels.icon", "stylers": [ { "visibility": "off" } ] },
  { "elementType": "labels.text.fill", "stylers": [ { "color": "#5B6159" } ] },
  { "elementType": "labels.text.stroke", "stylers": [ { "color": "#F5F2EB" } ] },
  { "featureType": "administrative", "elementType": "geometry", "stylers": [ { "color": "#DAD3C4" } ] },
  { "featureType": "administrative.land_parcel", "stylers": [ { "visibility": "off" } ] },
  { "featureType": "administrative.neighborhood", "stylers": [ { "visibility": "off" } ] },
  { "featureType": "poi", "stylers": [ { "visibility": "off" } ] },
  { "featureType": "poi.park", "elementType": "geometry", "stylers": [ { "color": "#E4E9D8" }, { "visibility": "on" } ] },
  { "featureType": "transit", "stylers": [ { "visibility": "off" } ] },
  { "featureType": "road", "elementType": "geometry", "stylers": [ { "color": "#FFFFFF" } ] },
  { "featureType": "road", "elementType": "labels", "stylers": [ { "visibility": "off" } ] },
  { "featureType": "road.arterial", "elementType": "geometry", "stylers": [ { "color": "#F7F4EC" } ] },
  { "featureType": "road.highway", "elementType": "geometry", "stylers": [ { "color": "#E8DFC9" } ] },
  { "featureType": "road.highway", "elementType": "labels", "stylers": [ { "visibility": "simplified" }, { "color": "#8A8577" } ] },
  { "featureType": "water", "elementType": "geometry", "stylers": [ { "color": "#CBD9D6" } ] },
  { "featureType": "water", "elementType": "labels", "stylers": [ { "visibility": "off" } ] }
]
''';
