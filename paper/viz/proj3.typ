// viz/proj3.typ — minimal axonometric 3D -> 2D projection for cetz canvases.
//
// A point is (x, y, z); the three unit axes map to fixed 2D screen vectors
// (ex, ey, ez), so projection is linear. Used by dare-cone.typ to draw the PSD
// cone of 2x2 covariances in (P11, P12, P22)-space.

// In the coordinates v = (P11-P22)/2, w = P12, u = (P11+P22)/2 (trace/2) the PSD
// cone is the CIRCULAR cone u >= sqrt(v^2 + w^2): the trace axis u is the axis of
// symmetry and the cross-section at height u is a disk of radius u in the (v, w)
// plane. We put u straight up, the diagonal spread v = (P11-P22)/2 horizontal,
// and the off-diagonal w = P12 into the page (foreshortened depth). Hence
//   P11 = u + v  -> up-right,   P22 = u - v  -> up-left,   P12 = w -> depth.
// The two diagonal edges lean up-right / up-left while an interior trajectory
// (with P12 != 0) leans nearly straight up, so the climb separates from both
// rank-1 edges instead of hugging the P11 axis.
#let default-view = (
  ex: (0.50, 0.50),    // image of the x (P11) unit axis  — up-right
  ey: (-0.52, -0.34),  // image of the y (P12) unit axis  — into the page
  ez: (-0.50, 0.50),   // image of the z (P22) unit axis  — up-left
  scale: 6.5,          // cm per unit value
)

// Project a 3D point (array of 3) to 2D canvas coordinates.
#let proj(p, view: default-view) = {
  let (x, y, z) = p
  (
    view.scale * (x * view.ex.at(0) + y * view.ey.at(0) + z * view.ez.at(0)),
    view.scale * (x * view.ex.at(1) + y * view.ey.at(1) + z * view.ez.at(1)),
  )
}
