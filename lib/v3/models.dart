library flutter_map_animated_polyline;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_animated_polyline/v3/painter.dart';
import 'package:flutter_test/flutter_test.dart';

class AnimatedPolylineMapPlugin extends MapPlugin {
  @override
  bool supportsLayer(LayerOptions options) =>
      options is ProjectedPolylineLayerOptions;

  @override
  Widget createLayer(
      LayerOptions options, MapState mapState, Stream<Null> stream) {
    return ProjectedPolylineLayer(options, mapState, stream);
  }
}

class ProjectedPolyline {
  final List<CustomPoint> points;
  final List<Offset> offsets = [];
  final double strokeWidth;
  final Color color;
  final double borderStrokeWidth;
  final Color borderColor;
  final List<Color> gradientColors;
  final List<double> colorsStop;
  final bool isDotted;
  LatLngBounds boundingBox;

  ProjectedPolyline({
    this.points,
    this.strokeWidth = 1.0,
    this.color = const Color(0xFF00FF00),
    this.borderStrokeWidth = 0.0,
    this.borderColor = const Color(0xFFFFFF00),
    this.gradientColors,
    this.colorsStop,
    this.isDotted = false,
  });
}

/// The options allowing animated polyline tweaks
class ProjectedPolylineLayerOptions extends LayerOptions {
  final List<ProjectedPolyline> polylines;

  /// The ability to render only polylines in current view bounds
  final bool polylineCulling;

  ProjectedPolylineLayerOptions({
    this.polylines = const [],
    Stream<Null> rebuild,
    this.polylineCulling = false,
  }) : super(rebuild: rebuild);
}

class ProjectedPolylineLayer extends StatelessWidget {
  /// The options allowing animated polyline tweaks
  final ProjectedPolylineLayerOptions polylineOpts;

  /// The flutter_map [MapState]
  final MapState map;

  /// The Stream used by flutter_map to notify us when a redraw is required
  final Stream<Null> stream;

  ProjectedPolylineLayer(this.polylineOpts, this.map, this.stream);

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
            var pos = point;
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
                  painter: ProjectedPolylinePainter(polylineOpt),
                  size: size,
                ),
            ],
          ),
        );
      },
    );
  }
}
