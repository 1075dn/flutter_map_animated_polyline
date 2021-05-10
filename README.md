# flutter_map_animated_polyline

### Ideas/Optimizations
- Call `computeMetrics()` only once (not every time draw is called), and keep result for following tweener values
- Let map know full polyline length so it can change the animation duration accordingly? How could we do that? Maybe create the animation in the plugin?