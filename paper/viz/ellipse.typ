
#import "@preview/cetz:0.5.2"
#import "@preview/cetz-plot:0.1.4"

#let ellipse-defaults = (
  domain: (-3.15, 3.15),
  samples: 200,
  ellipse-stroke: 1pt,
)

#let ellipse-curve(radii: (1, 1), rotation: 0deg) = t => {
  let a = rotation
  let x = radii.at(0) * calc.cos(t)
  let y = radii.at(1) * calc.sin(t)
  let rx = x * calc.cos(a) - y * calc.sin(a)
  let ry = x * calc.sin(a) + y * calc.cos(a)
  (rx, ry)
}

#let ellipse-axis-segments(radii: (1, 1), rotation: 0deg) = {
  let (a, b) = radii
  let ca = calc.cos(rotation)
  let sa = calc.sin(rotation)
  (
    ((a * ca, a * sa), (-a * ca, -a * sa)),
    ((-b * sa, b * ca), (b * sa, -b * ca)),
  )
}

#let default-radius-stroke(base) = {
  let s = stroke(base)
  let paint = if s.paint == auto { gray } else { s.paint }
  (paint: paint, dash: "dashed", thickness: 0.75pt)
}

#let add-ellipse(
  radii: (1, 1),
  rotation: 0deg,
  stroke: black + ellipse-defaults.ellipse-stroke,
  show-radii: false,
  label: none,
  domain: ellipse-defaults.domain,
  samples: ellipse-defaults.samples,
) = {
  cetz-plot.plot.add(
    domain: domain,
    samples: samples,
    ellipse-curve(radii: radii, rotation: rotation),
    style: (stroke: stroke),
    label: label,
  )
  if show-radii {
    let radius-stroke = default-radius-stroke(stroke)
    for segment in ellipse-axis-segments(radii: radii, rotation: rotation) {
      cetz-plot.plot.add(segment, style: (stroke: radius-stroke))
    }
  }
}
