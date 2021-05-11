import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'flutter_map_animated_polyline.dart';

class AnimatedPolylinePainter extends CustomPainter {
  final AnimatedPolyline polylineOpt;
  AnimatedPolylinePainter(this.polylineOpt);

  @override
  void paint(Canvas canvas, Size size) {
    if (polylineOpt.offsets.isEmpty) {
      return;
    }
    final rect = Offset.zero & size;
    canvas.clipRect(rect);
    final paint = Paint()
      ..strokeWidth = polylineOpt.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..blendMode = BlendMode.srcOver;

    if (polylineOpt.gradientColors == null) {
      paint.color = polylineOpt.color;
    } else {
      polylineOpt.gradientColors.isNotEmpty
          ? paint.shader = _paintGradient()
          : paint.color = polylineOpt.color;
    }

    Paint filterPaint;
    if (polylineOpt.borderColor != null) {
      filterPaint = Paint()
        ..color = polylineOpt.borderColor.withAlpha(255)
        ..strokeWidth = polylineOpt.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..blendMode = BlendMode.dstOut;
    }

    final borderPaint = polylineOpt.borderStrokeWidth > 0.0
        ? (Paint()
          ..color = polylineOpt.borderColor
          ..strokeWidth =
              polylineOpt.strokeWidth + polylineOpt.borderStrokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..blendMode = BlendMode.srcOver)
        : null;
    var radius = paint.strokeWidth / 2;
    var borderRadius = (borderPaint?.strokeWidth ?? 0) / 2;
    if (polylineOpt.isDotted) {
      var spacing = polylineOpt.strokeWidth * 1.5;
      canvas.saveLayer(rect, Paint());
      if (borderPaint != null) {
        _paintDottedLine(
            canvas, polylineOpt.offsets, borderRadius, spacing, borderPaint);
        _paintDottedLine(
            canvas, polylineOpt.offsets, radius, spacing, filterPaint);
      }
      _paintDottedLine(canvas, polylineOpt.offsets, radius, spacing, paint);
      canvas.restore();
    } else {
      paint.style = PaintingStyle.stroke;
      canvas.saveLayer(rect, Paint());
      if (borderPaint != null) {
        if (filterPaint != null) {
          filterPaint.style = PaintingStyle.stroke;
          _paintLine(canvas, polylineOpt.offsets, borderPaint);
        }
        borderPaint?.style = PaintingStyle.stroke;
        _paintLine(canvas, polylineOpt.offsets, filterPaint);
      }
      _paintLine(canvas, polylineOpt.offsets, paint);
      canvas.restore();
    }
  }

  void _paintDottedLine(Canvas canvas, List<Offset> offsets, double radius,
      double stepLength, Paint paint) {
    if (polylineOpt.showPortion == 0.0) return;
    final path = ui.Path();
    var startDistance = 0.0;
    for (var i = 0; i < offsets.length - 1; i++) {
      var o0 = offsets[i];
      var o1 = offsets[i + 1];
      var totalDistance = _dist(o0, o1);
      var distance = startDistance;
      while (distance < totalDistance) {
        var f1 = distance / totalDistance;
        var f0 = 1.0 - f1;
        var offset = Offset(o0.dx * f0 + o1.dx * f1, o0.dy * f0 + o1.dy * f1);
        path.addOval(Rect.fromCircle(center: offset, radius: radius));
        distance += stepLength;
      }
      startDistance = distance < totalDistance
          ? stepLength - (totalDistance - distance)
          : distance - totalDistance;
    }
    path.addOval(
        Rect.fromCircle(center: polylineOpt.offsets.last, radius: radius));
    canvas.drawPath(pctOf(path, polylineOpt.showPortion, true), paint);
  }

  void _paintLine(Canvas canvas, List<Offset> offsets, Paint paint) {
    if (offsets.isNotEmpty) {
      if (polylineOpt.showPortion == 0.0) return;

      final path = ui.Path()..moveTo(offsets[0].dx, offsets[0].dy);
      for (var offset in offsets) {
        path.lineTo(offset.dx, offset.dy);
      }
      canvas.drawPath(pctOf(path, polylineOpt.showPortion), paint);
    }
  }

  ui.Gradient _paintGradient() => ui.Gradient.linear(polylineOpt.offsets.first,
      polylineOpt.offsets.last, polylineOpt.gradientColors, _getColorsStop());

  List<double> _getColorsStop() => (polylineOpt.colorsStop != null &&
          polylineOpt.colorsStop.length == polylineOpt.gradientColors.length)
      ? polylineOpt.colorsStop
      : _calculateColorsStop();

  List<double> _calculateColorsStop() {
    final colorsStopInterval = 1.0 / polylineOpt.gradientColors.length;
    return polylineOpt.gradientColors
        .map((gradientColor) =>
            polylineOpt.gradientColors.indexOf(gradientColor) *
            colorsStopInterval)
        .toList();
  }

  @override
  bool shouldRepaint(AnimatedPolylinePainter other) => false;
}

double _dist(Offset v, Offset w) {
  return sqrt(_dist2(v, w));
}

double _dist2(Offset v, Offset w) {
  return _sqr(v.dx - w.dx) + _sqr(v.dy - w.dy);
}

double _sqr(double x) {
  return x * x;
}

Path pctOf(Path path, num proportion, [bool isDotted = false]) {
  var pathMetrics = path.computeMetrics().toList();
  var totalLength =
      pathMetrics.map((e) => e.length).reduce((sum, cur) => sum += cur);
  var ourLength = totalLength * proportion;
  List<Path> toDraw = [];
  double currentLength = 0;
  int lastIndex;
  for (lastIndex = 0; lastIndex < pathMetrics.length; lastIndex++) {
    var metric = pathMetrics[lastIndex];
    if (currentLength + metric.length > ourLength) break;
    currentLength += metric.length;
    toDraw.add(metric.extractPath(0, metric.length));
  }
  if (lastIndex < pathMetrics.length) {
    if (isDotted)
      toDraw.add(
          pathMetrics[lastIndex].extractPath(0, pathMetrics[lastIndex].length));
    else
      toDraw.add(
          pathMetrics[lastIndex].extractPath(0, ourLength - currentLength));
  }
  var pathPortion = Path();
  toDraw.forEach((p) {
    pathPortion.addPath(p, Offset.zero);
  });
  return pathPortion;
}
