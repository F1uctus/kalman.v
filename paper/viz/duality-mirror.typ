// viz/duality-mirror.typ — the estimation/control duality dictionary.
//
// Two columns, one mirror. Every estimation object (left) has a control twin
// (right) obtained by the conjugate transpose (·)*; each connecting arrow is a
// machine-checked theorem of theories/duality.v (solid) or the classical
// optimal-Riccati correspondence that we do not re-prove (dashed). No data —
// a schematic figure drawn with raw cetz primitives.

#import "@preview/cetz:0.5.2"
#import "../common/markup-shorthands.typ": *
#import "style.typ": viz-canvas, viz-resolve

// Lemma names deliberately keep their fixed 10pt size: they are the theorem
// identifiers, not labels, and stay recognizable at every figure scale.
#let duality-mirror-figure(style: (:)) = {
  let st = viz-resolve(style)
  viz-canvas(st, cetz.canvas(length: 1.4cm, {
    let xLc = -3.7 // left (estimation) column centre
    let xRc = 3.7 // right (control) column centre
    let ax = 0.0 // mirror axis
    let agap = 2.0 // half-width of the transpose arrows
    let ytop = 1.55

    // rows: estimation object <-> control object, labelled by the proving lemma
    let rows = (
      (
        y: 0.0,
        l: [наблюдаемость $(H, F)$],
        r: [управляемость $(F, G)$],
        lem: "controllable_dual",
        dash: false,
      ),
      (
        y: -1.15,
        l: [детектируемость],
        r: [стабилизируемость],
        lem: "stabilizable_dual",
        dash: false,
      ),
      (
        y: -2.3,
        l: [грамиан $cal(O)_k$],
        r: [грамиан $cal(C)_k$],
        lem: "ctrl_gram_dual",
        dash: false,
      ),
      (
        y: -3.45,
        l: [коррекция $F - K H$],
        r: [связь $F - G K$],
        lem: "stabilizable_stabilizing_dual",
        dash: false,
      ),
      (
        y: -4.6,
        l: [фильтр Риккати $P_ss$],
        r: [LQR Риккати $S_ss$],
        lem: "",
        dash: true,
      ),
    )

    // mirror axis + its label
    cetz.draw.line(
      (ax, ytop + 0.5),
      (ax, -5.05),
      stroke: (paint: gray, dash: "dashed", thickness: 0.8pt),
    )
    cetz.draw.content((ax, ytop + 0.78), text(size: st.label + 2pt)[$(dot)^*$])

    // column headers
    cetz.draw.content((xLc, ytop), text(
      weight: "bold",
      size: st.label + 1pt,
    )[ОЦЕНИВАНИЕ])
    cetz.draw.content((xRc, ytop), text(
      weight: "bold",
      size: st.label + 1pt,
    )[УПРАВЛЕНИЕ])
    cetz.draw.content(
      (xLc, ytop - 0.42),
      text(size: st.annot, fill: gray.darken(25%))[фильтр Калмана],
    )
    cetz.draw.content(
      (xRc, ytop - 0.42),
      text(size: st.annot, fill: gray.darken(25%))[LQR-регулятор],
    )

    // rows
    for row in rows {
      cetz.draw.content((xLc, row.y), text(size: st.label, row.l))
      cetz.draw.content((xRc, row.y), text(size: st.label, row.r))
      let st = if row.dash {
        (paint: gray.darken(5%), dash: "dashed", thickness: 0.9pt)
      } else { (paint: black, thickness: 0.9pt) }
      cetz.draw.line(
        (ax - agap, row.y),
        (ax + agap, row.y),
        mark: (start: ">", end: ">", scale: 0.5),
        stroke: st,
      )
      cetz.draw.content(
        (ax, row.y + 0.27),
        box(
          fill: white,
          inset: (x: 1.5pt),
          text(
            size: 10pt,
            fill: if row.dash { gray.darken(20%) } else { rgb(20, 90, 160) },
            if row.dash { emph(row.lem) } else { raw(row.lem) },
          ),
        ),
      )
    }

    // legend
    let yl = -5.7
    cetz.draw.line(
      (xLc - 0.9, yl),
      (xLc - 0.3, yl),
      stroke: (paint: black, thickness: 0.9pt),
    )
    cetz.draw.content(
      (xLc - 0.15, yl),
      anchor: "west",
      text(size: st.legend)[формализовано в `duality.v`],
    )
    cetz.draw.line(
      (0.9, yl),
      (1.5, yl),
      stroke: (paint: gray.darken(5%), dash: "dashed", thickness: 0.9pt),
    )
    cetz.draw.content(
      (1.65, yl),
      anchor: "west",
      text(size: st.legend)[вне объёма работы],
    )
  }))
}
