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
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  AnimationController animationController;
  var pct = 0.0;

  void _animate() {
    // Create some tweens. These serve to split up the transition from one location to another.
    // In our case, we want to split the transition be<tween> our current map center and the destination.
    var _tween = Tween<double>(begin: 0.00, end: 1.0);

    // Create a animation animationController that has a duration and a TickerProvider.
    animationController =
        AnimationController(duration: const Duration(seconds: 5), vsync: this);
    // The animation determines what path the animation will take. You can try different Curves values, although I found
    // fastOutSlowIn to be my favorite.
    Animation<double> animation =
        CurvedAnimation(parent: animationController, curve: Curves.easeInOut);

    animationController.addListener(() {
      setState(() {
        pct = _tween.evaluate(animation);
      });
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        animationController.dispose();
        animationController = null;
      }
    });

    animationController.forward();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Animated Polyline'),
        actions: [
          IconButton(icon: Icon(Icons.play_arrow), onPressed: _animate)
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          plugins: [
            AnimatedPolylineMapPlugin(),
          ],
          center: LatLng(45.1313258, 5.5171205),
          zoom: 11.0,
        ),
        layers: [
          TileLayerOptions(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          AnimatedPolylineLayerOptions(
            polylineCulling: true,
            polylines: [
              PctPolyline(
                isDotted: true,
                points: getPoints(0),
                color: Colors.red,
                strokeWidth: 5.0,
                pct: pct,
              ),
            ],
          )
        ],
      ),
    );
  }
}
