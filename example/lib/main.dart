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
  Marker makeMarker(LatLng point, Color color) => Marker(
      point: point,
      height: 15,
      width: 15,
      builder: (ctx) => CircleAvatar(
            backgroundColor: color,
          ));

  var polylineLayer = AnimatedPolylineLayerOptions(
    polylineCulling: true,
    polylines: [
      //higher z-index lower in list

      AnimatedPolyline(
        // isDotted: true,
        gradientColors: [Colors.green, Colors.green[900]],
        colorsStop: [0.0, 1.0],
        points: getPoints(0),
        strokeWidth: 3.0,
      ),
      AnimatedPolyline(
        // isDotted: true,
        gradientColors: [Colors.blue, Colors.blue[900]],
        colorsStop: [0.0, 1.0],
        points: getPoints(1),
        strokeWidth: 3.0,
      ),
    ],
  );

  var longestDuration = Duration(seconds: 5);

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Animated Polyline'),
        actions: [
          Icon(Icons.animation),
          Icon(Icons.arrow_forward_ios),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    minimumSize: Size.zero, padding: EdgeInsets.all(5)),
                child: Text('SMALL',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  var an = polylineLayer.polylines[1].newAnimation(
                      Duration(
                          milliseconds:
                              (polylineLayer.polylines[1].meterLength /
                                      polylineLayer.maxMeterLength *
                                      longestDuration.inMilliseconds)
                                  .toInt()),
                      Curves.easeInOut,
                      () {});
                  an.forward();
                }),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    minimumSize: Size.zero, padding: EdgeInsets.all(5)),
                child:
                    Text('BIG', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  var an = polylineLayer.polylines[0].newAnimation(
                      Duration(
                          milliseconds:
                              (polylineLayer.polylines[0].meterLength /
                                      polylineLayer.maxMeterLength *
                                      longestDuration.inMilliseconds)
                                  .toInt()),
                      Curves.easeInOut,
                      () {});
                  an.forward();
                }),
          ),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          plugins: [
            AnimatedPolylineMapPlugin(),
          ],
          bounds: LatLngBounds.fromPoints([...getPoints(0), ...getPoints(1)]),
          boundsOptions: FitBoundsOptions(padding: EdgeInsets.all(30)),
        ),
        layers: [
          TileLayerOptions(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          polylineLayer,
          MarkerLayerOptions(markers: [
            makeMarker(getPoints(0)[0], Colors.green),
            makeMarker(
                getPoints(0)[getPoints(0).length - 1], Colors.green[900]),
            makeMarker(getPoints(1)[0], Colors.blue),
            makeMarker(getPoints(1)[getPoints(1).length - 1], Colors.blue[900]),
          ])
        ],
      ),
    );
  }
}
