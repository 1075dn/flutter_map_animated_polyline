# flutter_map_animated_polyline

### Ideas/Optimizations
- Call `computeMetrics()` only once (not every time draw is called), and keep result for following tweener values