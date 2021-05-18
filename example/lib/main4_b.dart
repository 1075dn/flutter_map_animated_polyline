import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animated_polyline/flutter_map_animated_polyline.dart';
import 'package:latlong/latlong.dart';
import './data.dart';
import 'dart:math';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animated Polyline Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  Animation<double> animation;
  AnimationController controller;
  List<LatLng> builtPoints = [];

  @override
  void initState() {
    super.initState();
    var points = getPoints(0);
    bool interpolateBetweenPoints = true;
    var interpolatedPoint;

    Function(LatLng, LatLng) myDistanceFunc = haversine;

    builtPoints.add(LatLng(points[0].latitude, points[0].longitude));

    int lastPointIndex = 1;

    List<Map<String, dynamic>> pointDistanceSteps = [
      {'dist': 0.0, 'perc': 0.0}
    ];

    var totalDistance = 0.0;

    /// build up a list of distances that each point must pass before being displayed
    for (var c = 0; c < points.length - 1; c++) {
      totalDistance += myDistanceFunc(points[c], points[c + 1]);
      pointDistanceSteps.add({'dist': totalDistance, 'perc': null});
    }

    /// build a list of percentages now we know the length, for how far the point is along
    for (var c = 0; c < points.length - 2; c++) {
      pointDistanceSteps[c]['perc'] =
          pointDistanceSteps[c]['dist'] / totalDistance;
    }

    controller =
        AnimationController(duration: Duration(seconds: 10), vsync: this);
    animation = Tween<double>(begin: 0, end: totalDistance).animate(controller)
      ..addListener(() {
        setState(() {
          for (var c = lastPointIndex; c < points.length - 1; c++) {
            if (animation.value > pointDistanceSteps[c]['dist']) {
              /// Our animation is past the next point, so add it in
              /// but remove any interpolated point that we were using
              if (interpolatedPoint != null) {
                builtPoints
                    .removeLast(); // dont nec need the interpolated point any more
                interpolatedPoint = null;
              }

              builtPoints.add(LatLng(points[c].latitude, points[c].longitude));
              lastPointIndex = c + 1;
            } else {
              /// only need this if we want to draw inbetween points...
              /// use our point steps and interpolate
              if (interpolateBetweenPoints) {
                var lastPerc = pointDistanceSteps[c - 1]['perc'];
                var nextPerc = pointDistanceSteps[c]['perc'];

                if (nextPerc == null) return;
                var perc =
                    (controller.value - lastPerc) / (nextPerc - lastPerc);

                var intermediateLat =
                    (points[c].latitude - points[c - 1].latitude) * perc +
                        points[c - 1].latitude;
                var intermediateLon =
                    (points[c].longitude - points[c - 1].longitude) * perc +
                        points[c - 1].longitude;

                interpolatedPoint =
                    LatLng(intermediateLat, intermediateLon); // last tail point

                if (builtPoints.length >= c) {
                  builtPoints[c - 1] = interpolatedPoint;
                } else {
                  builtPoints.add(interpolatedPoint);
                }
              }

              return;
            }
          }
        });
      });
    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
        body: FlutterMap(
            options: MapOptions(
              plugins: [
                AnimatedPolylineMapPlugin(),
              ],
              bounds:
                  LatLngBounds.fromPoints([...getPoints(0), ...getPoints(1)]),
              boundsOptions: FitBoundsOptions(padding: EdgeInsets.all(30)),
            ),
            layers: [
              TileLayerOptions(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: ['a', 'b', 'c'],
              ),
              PolylineLayerOptions(polylines: [
                Polyline(
                    points: builtPoints,
                    strokeWidth: 2.0,
                    color: Colors.purple),
              ]),
            ]));
  }
}

// https://github.com/yeradis/haversine.dart
double haversine(LatLng p1, LatLng p2) {
  var lat1 = p1.latitudeInRad, lat2 = p2.latitudeInRad;
  var lon1 = p1.longitudeInRad, lon2 = p2.longitudeInRad;

  var earthRadius = 6378137.0; // WGS84 major axis
  double distance = 2 *
      earthRadius *
      asin(sqrt(pow(sin(lat2 - lat1) / 2, 2) +
          cos(lat1) * cos(lat2) * pow(sin(lon2 - lon1) / 2, 2)));

  return distance;
}
