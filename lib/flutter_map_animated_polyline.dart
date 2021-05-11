library flutter_map_animated_polyline;

import 'dart:math' as Math;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong/latlong.dart';
import 'package:flutter_test/flutter_test.dart';

import './utils.dart';
import './painter.dart';

class AnimatedPolylineMapPlugin extends MapPlugin {
  @override
  bool supportsLayer(LayerOptions options) =>
      options is AnimatedPolylineLayerOptions;

  @override
  Widget createLayer(
      LayerOptions options, MapState mapState, Stream<Null> stream) {
    return AnimatedPolylineLayer(options, mapState, stream);
  }
}

class AnimatedPolyline extends Polyline {
  double _showPortion;

  AnimatedPolyline(
      {List<LatLng> points,
      double strokeWidth = 1.0,
      Color color = const Color(0xFF00FF00),
      List<Color> gradientColors,
      List<double> colorsStop,
      bool isDotted = false,
      double initialShowPortion})
      : super(
            points: points,
            strokeWidth: strokeWidth,
            color: color,
            borderStrokeWidth: 0.0,
            borderColor: const Color(0xFFFFFF00),
            gradientColors: gradientColors,
            colorsStop: colorsStop,
            isDotted: isDotted) {
    _showPortion = initialShowPortion ?? 0.0;
  }

  double get showPortion => _showPortion;

  AnimationController _curController;

  bool get isAnimating {
    return _curController != null;
  }

  AnimationController get currentController {
    return _curController;
  }

  num get meterLength => routeLength(points);

  AnimationController _createController(
      Duration animationDuration,
      Curve animationCurve,
      void Function(double) animateCallback,
      void Function() finishCallback) {
    var _tween = Tween<double>(begin: 0, end: 1);
    var animationController =
        AnimationController(duration: animationDuration, vsync: TestVSync());
    Animation<double> animation =
        CurvedAnimation(parent: animationController, curve: animationCurve);
    var lastValue = -1;
    animationController.addListener(() {
      var curValue = _tween.evaluate(animation);

      if (curValue == lastValue) return;

      animateCallback(curValue);
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        animationController.dispose();
        animationController = null;
        finishCallback();
      }
    });

    return animationController;
  }

  AnimationController newAnimation(Duration animationDuration,
      Curve animationCurve, void Function() onFinish) {
    if (isAnimating) return null;
    return _createController(animationDuration, animationCurve, (curValue) {
      _showPortion = curValue;
    }, onFinish);
  }
}

/// The options allowing animated polyline tweaks
class AnimatedPolylineLayerOptions extends PolylineLayerOptions {
  @override
  final List<AnimatedPolyline> polylines;

  /// The ability to render only polylines in current view bounds
  @override
  final bool polylineCulling;

  AnimatedPolylineLayerOptions({
    this.polylines = const [],
    Stream<Null> rebuild,
    this.polylineCulling = false,
  }) : super(rebuild: rebuild, polylineCulling: polylineCulling);

  num get maxMeterLength =>
      polylines.map((e) => e.meterLength).reduce(Math.max);
}

class AnimatedPolylineLayer extends StatelessWidget {
  /// The options allowing animated polyline tweaks
  final AnimatedPolylineLayerOptions polylineOpts;

  /// The flutter_map [MapState]
  final MapState map;

  /// The Stream used by flutter_map to notify us when a redraw is required
  final Stream<Null> stream;

  AnimatedPolylineLayer(this.polylineOpts, this.map, this.stream);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints bc) {
        final size = Size(bc.maxWidth, bc.maxHeight);
        return _build(context, size);
      },
    );
  }

  Widget _build(BuildContext context, Size size) {
    return StreamBuilder<void>(
      stream: stream, // a Stream<void> or null
      builder: (BuildContext context, _) {
        for (var polylineOpt in polylineOpts.polylines) {
          polylineOpt.offsets.clear();

          if (polylineOpts.polylineCulling &&
              !polylineOpt.boundingBox.isOverlapping(map.bounds)) {
            // Skip this polyline as it is not within the current map bounds (i.e not visible on screen)
            continue;
          }

          var i = 0;
          for (var point in polylineOpt.points) {
            var pos = map.project(point);
            pos = pos.multiplyBy(map.getZoomScale(map.zoom, map.zoom)) -
                map.getPixelOrigin();
            polylineOpt.offsets.add(Offset(pos.x.toDouble(), pos.y.toDouble()));
            if (i > 0 && i < polylineOpt.points.length) {
              polylineOpt.offsets
                  .add(Offset(pos.x.toDouble(), pos.y.toDouble()));
            }
            i++;
          }
        }

        return Container(
          child: Stack(
            children: [
              for (final polylineOpt in polylineOpts.polylines)
                CustomPaint(
                  painter: AnimatedPolylinePainter(polylineOpt),
                  size: size,
                ),
            ],
          ),
        );
      },
    );
  }
}
