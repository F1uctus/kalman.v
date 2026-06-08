
#import "@preview/cetz:0.5.2"
#import "@preview/cetz-plot:0.1.4"
#import "ellipse.typ": add-ellipse
#import "frames.typ": frame-grid
#import "plotdata.typ": load

#let gramian-data = load("/paper/data/gramian.json")

#let gram-lim = 2.0 // shared square scale (all four gramians fit, comparably)
#let gram-pd-color = rgb("#1f6f6b") // PD => a proper 2-D ellipse
#let gram-deg-color = luma(45%) // degenerate => a flat sliver

#let gram-frame(it, lim: gram-lim) = cetz.canvas(length: 1.4cm, {
  cetz-plot.plot.plot(
    size: (2, 2),
    axis-style: "scientific",
    x-label: none,
    y-label: none,
    x-min: -lim,
    x-max: lim,
    y-min: -lim,
    y-max: lim,
    x-tick-step: none,
    y-tick-step: none,
    {
      let e = it.ellipse
      if it.pd {
        add-ellipse(
          radii: (e.a, e.b),
          rotation: e.angle_rad * 1rad,
          stroke: gram-pd-color + 1.2pt,
        )
      } else {
        add-ellipse(
          radii: (e.a, 0),
          rotation: e.angle_rad * 1rad,
          stroke: gram-deg-color + 1.4pt,
        )
        let tip = (e.a * calc.cos(e.angle_rad), e.a * calc.sin(e.angle_rad))
        cetz-plot.plot.add(
          (tip, (-tip.at(0), -tip.at(1))),
          style: (stroke: none),
          mark: "o",
          mark-size: 0.13,
          mark-style: (stroke: gram-deg-color, fill: gram-deg-color),
        )
      }
    },
  )
})

#let gram-row-label(c) = {
  let sym = if c.kind == "obsv" { $cal(O)_k$ } else { $cal(C)_k$ }
  let qual = if c.kind == "obsv" {
    if c.positive { [$(H,F)$ набл.] } else { [$(H,F)$ ненабл.] }
  } else {
    if c.positive { [$(F,G)$ упр.] } else { [$(F,G)$ неупр.] }
  }
  stack(spacing: 0.3em, sym, text(size: 7.5pt, qual))
}

#let gram-top-labels(data) = range(1, data.kmax + 1).map(k => if k == data.n {
  text(size: 8.5pt, weight: "bold")[$k = #k = n$]
} else {
  text(size: 8.5pt)[$k = #k$]
})

#let gramian-figure(data: gramian-data) = frame-grid(
  data.cases.map(c => (label: gram-row-label(c), items: c.frames)),
  it => gram-frame(it),
  top-labels: gram-top-labels(data),
)
