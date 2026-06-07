
#import "@preview/cetz:0.5.2"
#import "@preview/cetz-plot:0.1.4"
#import "ellipse.typ": add-ellipse
#import "plotdata.typ": load, spectral-path

#let spectral-data = load(spectral-path)

#let qf-plot(r, size: 3.1, body) = cetz.canvas(length: 1cm, {
  cetz.draw.set-style(axes: (
    stroke: (dash: "dotted", paint: gray),
    tick: (stroke: gray + 0.5pt),
  ))
  cetz-plot.plot.plot(
    name: "p",
    size: (size, size),
    x-min: -r,
    x-max: r,
    y-min: -r,
    y-max: r,
    x-tick-step: none,
    y-tick-step: none,
    x-grid: "both",
    y-grid: "both",
    axis-style: "school-book",
    body,
  )
})

#let antitone-pair(red-ell, green-ell, relation, r) = stack(
  spacing: 0.5em,
  qf-plot(r, size: 4.2, {
    add-ellipse(
      radii: (1, 1),
      rotation: 0deg,
      stroke: (paint: gray, dash: "dashed", thickness: 0.6pt),
    )
    add-ellipse(
      radii: (red-ell.a, red-ell.b),
      rotation: red-ell.angle_rad * 1rad,
      stroke: red + 1.1pt,
    )
    add-ellipse(
      radii: (green-ell.a, green-ell.b),
      rotation: green-ell.angle_rad * 1rad,
      stroke: green + 1.1pt,
    )
  }),
  align(center, text(size: 9.5pt, relation)),
)

#let panel-antitone(data) = {
  let a = data.antitone
  let rel-ab = [#text(fill: red)[$A$] #h(0.15em) $prec.eq$ #h(0.15em) #text(
      fill: green,
    )[$B$]]
  let rel-inv = [
    #text(fill: green)[$B^(-1)$] #h(0.15em) $prec.eq$ #h(0.15em) #text(
      fill: red,
    )[$A^(-1)$]
  ]
  grid(
    columns: (auto, auto),
    column-gutter: 1.6em,
    align: bottom,
    antitone-pair(a.A.qform_ellipse, a.B.qform_ellipse, rel-ab, 1.25),
    antitone-pair(a.A_inv.qform_ellipse, a.B_inv.qform_ellipse, rel-inv, 3.4),
  )
}

#let frac-or-int(x) = {
  let r = calc.round(1 / x)
  if calc.abs(1 / x - r) < 1e-6 and r != 1 { $1 \/ #r$ } else {
    $#calc.round(x, digits: 2)$
  }
}
#let eigpair(e) = $(#frac-or-int(e.at(0)), #frac-or-int(e.at(1)))$

#let spectral-note(data) = {
  let a = data.antitone
  text(size: 9pt)[
    $lambda(A) = #eigpair(a.A.eig)$, #h(0.3em)
    $lambda(A^(-1)) = #eigpair(a.A_inv.eig)$;
    #h(0.6em)
    $lambda(B) = #eigpair(a.B.eig)$, #h(0.3em)
    $lambda(B^(-1)) = #eigpair(a.B_inv.eig)$
  ]
}

#let spectral-figure(data: spectral-data) = stack(
  spacing: 0.7em,
  panel-antitone(data),
  align(center, spectral-note(data)),
)
