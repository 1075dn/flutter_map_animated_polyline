import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animated_polyline/v3/projected_polyline.dart';
import 'package:flutter_map_animated_polyline/v3/animator.dart';
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
    projected = ProjectedPointList(getPoints(1));
  }

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
                    print('${DateTime.now().millisecondsSinceEpoch} $value');

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
          bounds: LatLngBounds.fromPoints(getPoints(1)),
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
                gradientColors: [Colors.blue, Colors.blue[900]],
                colorsStop: [0.0, 1.0],
                strokeWidth: 10.0,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
