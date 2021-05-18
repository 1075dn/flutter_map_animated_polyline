import 'dart:math' as Math;

import 'package:flutter_map/plugin_api.dart';
import 'package:latlong/latlong.dart';
// import 'package:maps_toolkit/maps_toolkit.dart';

// v3

// static vSyncTest, better animation controller management

// like this we don't need a custom painter (i think)

CustomPoint project(Crs crs, LatLng point) {
  return crs.projection.project(point);
}

List<CustomPoint> projectPolyline(Crs crs, List<LatLng> polyline) {
  return polyline.map((point) => project(crs, point));
}

class ProjectedPolyline2 {
  List<LatLng> polyline;
  List<CustomPoint> points;
  num projectedLength;
  Crs crs;

  ProjectedPolyline2(this.polyline, this.crs) {
    _projectAll();
  }

  List<CustomPoint> transform(double zoom) {
    return transformPolyline(points, crs, zoom);
  }

  List<CustomPoint> portion(double portion) {
    return calculatePortionOfPolyline(points, portion, projectedLength);
  }

  List<CustomPoint> transformPortion(double portion, double zoom) {
    return transformPolyline(
        calculatePortionOfPolyline(points, portion, projectedLength),
        crs,
        zoom);
  }

  void changeCrs(Crs crs) {
    this.crs = crs;
    _projectAll();
  }

  void _projectAll() {
    points = projectPolyline(crs, polyline);
    var totalLength = 0.0;
    for (int i = 1; i < points.length; i++) {
      totalLength += distance(points[i - 1], points[i]);
    }
    projectedLength = totalLength;
  }
}

// UPDATE ON ANIMATION VALUE CHANGE!

// On update transform cached projected point list
CustomPoint transform(CustomPoint projectedPoint, Crs crs, double zoom) {
  return crs.transformation
      .transform(projectedPoint, crs.scale(zoom).toDouble());
}

List<CustomPoint> transformPolyline(
    List<CustomPoint> polyline, Crs crs, double zoom) {
  return polyline.map((point) => transform(point, crs, zoom));
}

double distance(CustomPoint pointA, CustomPoint pointB) {
  return Math.sqrt(
      Math.pow(pointA.x - pointB.x, 2) + Math.pow(pointA.y - pointB.y, 2));
}

CustomPoint pointBetween(
    CustomPoint pointA, CustomPoint pointB, num distanceFromPointA) {
  var distanceBetweenPoints = distance(pointA, pointB);
  var newX = pointA.x +
      (distanceFromPointA / distanceBetweenPoints) * (pointB.x - pointA.x);
  var newY = pointA.y +
      (distanceFromPointA / distanceBetweenPoints) * (pointB.y - pointA.y);
  return CustomPoint(newX, newY);
}

// TODO: USE DISTANCETOPREVIOUS
List<CustomPoint> calculatePortionOfPolyline(
    List<CustomPoint> polyline, double portion, double projectedLength) {
  var newLength = projectedLength * portion;
  var newPolyline = [polyline[0]];
  var currentLength = 0.0;
  var lastIndex;

  for (lastIndex = 1; lastIndex < polyline.length; lastIndex++) {
    var distanceFromPreviousToCurrent =
        distance(polyline[lastIndex - 1], polyline[lastIndex]);
    if (currentLength + distanceFromPreviousToCurrent > newLength) break;
    currentLength += distanceFromPreviousToCurrent;
    newPolyline.add(polyline[lastIndex]);
  }

  var distanceLeft = projectedLength - currentLength;

  if (distanceLeft > 0) {
    var lastPoint = polyline[lastIndex - 1];
    var thisPoint = polyline[lastIndex];
    var newPoint = pointBetween(lastPoint, thisPoint, distanceLeft);
    newPolyline.add(newPoint);
  }

  return newPolyline;
}
