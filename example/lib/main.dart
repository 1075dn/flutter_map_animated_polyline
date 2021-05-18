import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animated_polyline/flutter_map_animated_polyline.dart';
import 'package:latlong/latlong.dart';
import './data.dart';

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

class _MyHomePageState extends State<MyHomePage> {
  List<LatLng> pointsToShow = [];
  ProjectedPointList projected;

  var animator = EasyAnimationController();

  @override
  void initState() {
    super.initState();
    projected = ProjectedPointList(getPoints(0));
  }

  Marker makeMarker(LatLng point, Color color) => Marker(
      point: point,
      height: 15,
      width: 15,
      builder: (ctx) => CircleAvatar(
            backgroundColor: color,
          ));

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.play_arrow_rounded),
            onPressed: () {
              animator.start(
                  initialPortion: 0.0,
                  finishedPortion: 1.0,
                  animationDuration: Duration(seconds: 10),
                  animationCurve: Curves.easeInOutCubic,
                  onValueChange: (value) {
                    setState(() {
                      pointsToShow = projected.portion(value);
                    });
                  });
            },
          ),
          IconButton(
            icon: Icon(Icons.fast_rewind_rounded),
            onPressed: () {
              animator.start(
                  initialPortion: 1.0,
                  finishedPortion: 0.0,
                  animationDuration: Duration(seconds: 10),
                  animationCurve: Curves.easeInSine,
                  onValueChange: (value) {
                    setState(() {
                      pointsToShow = projected.portion(value);
                    });
                  });
            },
          )
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          bounds: LatLngBounds.fromPoints(getPoints(0)),
          boundsOptions: FitBoundsOptions(padding: EdgeInsets.all(30)),
        ),
        layers: [
          TileLayerOptions(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          PolylineLayerOptions(
            polylines: [
              Polyline(
                points: pointsToShow,
                gradientColors: [Colors.orange, Colors.orange[900]],
                colorsStop: [0.0, 1.0],
                strokeWidth: 5.0,
                // isDotted: true,
              ),
            ],
          ),
          MarkerLayerOptions(
            markers: [
              makeMarker(getPoints(0).first, Colors.orange),
              makeMarker(getPoints(0).last, Colors.orange[900]),
            ],
          ),
        ],
      ),
    );
  }
}
