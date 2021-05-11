import 'package:latlong/latlong.dart' as latlong;
import 'package:maps_toolkit/maps_toolkit.dart' as toolkit;

num routeLength(List<latlong.LatLng> points) {
  toolkit.LatLng convert(latlong.LatLng point) =>
      toolkit.LatLng(point.latitude, point.longitude);
  var distance = 0.0;
  for (int i = 1; i < points.length; i++) {
    distance += toolkit.SphericalUtil.computeDistanceBetween(
        convert(points[i - 1]), convert(points[i]));
  }
  return distance;
}
