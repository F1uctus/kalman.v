
#import "@preview/cetz:0.5.2"
#import "@preview/cetz-plot:0.1.4"
#import "plotdata.typ": load

#let duality-spectral-data = load("/paper/data/duality_spectral.json")

#let circle-curve(r) = t => (r * calc.cos(t), r * calc.sin(t))

#let ds-flag(label, ok) = {
  let c = if ok { rgb(20, 130, 40) } else { rgb(200, 40, 40) }
  text(size: 7.5pt, fill: c)[#label #if ok [✓] else [✗]]
}

#let duality-panel(modes) = cetz.canvas(length: 1cm, {
  cetz.draw.set-style(axes: (
    stroke: (dash: "dotted", paint: gray),
    tick: (stroke: gray + 0.5pt),
  ))
  cetz-plot.plot.plot(
    name: "p",
    size: (6.2, 6.2),
    x-min: -1.5, x-max: 1.5, y-min: -1.5, y-max: 1.5,
    x-label: $Re$, y-label: $Im$,
    x-tick-step: 0.5, y-tick-step: 0.5,
    x-grid: "both", y-grid: "both",
    axis-style: "school-book",
    {
      cetz-plot.plot.add(
        domain: (-3.15, 3.15), samples: 200, circle-curve(1),
        style: (stroke: gray + 0.8pt),
      )
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
      cetz-plot.plot.annotate(resize: false, {
        for m in modes {
          cetz.draw.content(
            (m.re, m.im + 0.13),
            anchor: "south",
            box(inset: 1pt, stack(
              spacing: 1.5pt,
              ds-flag([Д], m.detectable),
              ds-flag([С], m.stabilizable),
            )),
          )
        }
      })
    },
  )
})

#let duality-spectral-figure(data: duality-spectral-data) = grid(
  columns: (auto, auto, auto),
  column-gutter: 0.8em,
  align: horizon,
  stack(
    spacing: 0.5em,
    duality-panel(data.primal),
    align(center, text(size: 9pt)[(а) исходная пара $(F, H, G)$]),
  ),
  align(center + horizon, stack(
    spacing: 0.2em,
    text(size: 11pt)[$(dot)^*$],
    text(size: 16pt)[$arrow.l.r$],
  )),
  stack(
    spacing: 0.5em,
    duality-panel(data.dual),
    align(center, text(size: 9pt)[(б) двойственная $(F^*, G^*, H^*)$]),
  ),
)
