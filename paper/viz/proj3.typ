
#let default-view = (
  ex: (0.50, 0.50),    // image of the x (P11) unit axis  — up-right
  ey: (-0.52, -0.34),  // image of the y (P12) unit axis  — into the page
  ez: (-0.50, 0.50),   // image of the z (P22) unit axis  — up-left
  scale: 6.5,          // cm per unit value
)

#let proj(p, view: default-view) = {
  let (x, y, z) = p
  (
    view.scale * (x * view.ex.at(0) + y * view.ey.at(0) + z * view.ez.at(0)),
    view.scale * (x * view.ex.at(1) + y * view.ey.at(1) + z * view.ez.at(1)),
  )
}
