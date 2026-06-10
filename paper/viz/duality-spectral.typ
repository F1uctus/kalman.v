// viz/duality-spectral.typ — PBH spectral mirror of estimation/control duality.
//
// Data: paper/data/duality_spectral.json (extraction/ocaml/driver.exe, gen_duality).
// A didactic 2×2 real-spectrum system. For each eigenmode the PBH criterion asks
// two questions:
//   • detectability  — does the output see it?    (H v ≠ 0, right eigenvector v)
//   • stabilizability — does the input reach it?   (w G ≠ 0, left  eigenvector w)
// Only the UNSTABLE modes (|λ| ≥ 1) matter for convergence. The dual system
// (F*, output G*, input H*) is computed independently and the two verdicts SWAP —
// the content of theories/duality.v `stabilizable_dual` / `controllable_dual`.

#import "@preview/cetz:0.5.2"
#import "@preview/cetz-plot:0.1.4"
#import "plotdata.typ": load
#import "style.typ": viz-canvas, viz-resolve

#let duality-spectral-data = load("/paper/data/duality_spectral.json")

#let circle-curve(r) = t => (r * calc.cos(t), r * calc.sin(t))

// A PBH verdict badge: green ✓ if the mode passes the test, red ✗ otherwise.
#let ds-flag(label, ok, st) = {
  let c = if ok { rgb(20, 130, 40) } else { rgb(200, 40, 40) }
  text(size: st.annot, fill: c)[#label #if ok [✓] else [✗]]
}

#let duality-panel(modes, st) = viz-canvas(st, cetz.canvas(length: 1cm, {
  cetz.draw.set-style(axes: (
    stroke: (dash: "dotted", paint: gray),
    tick: (stroke: gray + 0.5pt),
  ))
  cetz-plot.plot.plot(
    name: "p",
    size: (6.2, 6.2),
    x-min: -1.5, x-max: 1.5, y-min: -1.5, y-max: 1.5,
    x-label: text(size: st.label, $Re$),
    y-label: text(size: st.label, $Im$),
    x-tick-step: 0.5, y-tick-step: 0.5,
    x-grid: "both", y-grid: "both",
    axis-style: "school-book",
    {
      // the unit circle: |λ| = 1 is the stability boundary
      cetz-plot.plot.add(
        domain: (-3.15, 3.15), samples: 200, circle-curve(1),
        style: (stroke: gray + 0.8pt),
      )
      // eigenvalues — unstable (|λ| ≥ 1) in red, stable in gray
      for m in modes {
        cetz-plot.plot.add(
          ((m.re, m.im),),
          mark: "o", mark-size: 0.17, style: (stroke: none),
          mark-style: (
            stroke: if m.unstable { rgb(200, 40, 40) } else { gray.darken(10%) },
            fill: if m.unstable { rgb(200, 40, 40).lighten(55%) } else {
              gray.lighten(55%)
            },
          ),
        )
      }
      // per-mode PBH verdicts, anchored above each eigenvalue
      cetz-plot.plot.annotate(resize: false, {
        for m in modes {
          cetz.draw.content(
            (m.re, m.im + 0.13),
            anchor: "south",
            box(inset: 1pt, stack(
              spacing: 1.5pt,
              ds-flag([Д], m.detectable, st),
              ds-flag([С], m.stabilizable, st),
            )),
          )
        }
      })
    },
  )
}))

#let duality-spectral-figure(data: duality-spectral-data, style: (:)) = {
  let st = viz-resolve(style)
  grid(
    columns: (auto, auto, auto),
    column-gutter: 0.8em,
    align: horizon,
    stack(
      spacing: 0.5em,
      duality-panel(data.primal, st),
      align(center, text(size: st.subcaption)[(а) исходная пара $(F, H, G)$]),
    ),
    align(center + horizon, stack(
      spacing: 0.2em,
      text(size: st.label + 2pt)[$(dot)^*$],
      text(size: st.label + 7pt)[$arrow.l.r$],
    )),
    stack(
      spacing: 0.5em,
      duality-panel(data.dual, st),
      align(center, text(size: st.subcaption)[(б) двойственная
        $(F^*, G^*, H^*)$]),
    ),
  )
}
