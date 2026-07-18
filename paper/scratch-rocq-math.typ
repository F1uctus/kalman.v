// Демонстрация рендеринга утверждений Rocq в математическую разметку Typst.
// Не входит в сборку диссертации; служит визуальной проверкой генератора
// extraction/typst (paper/data/rocq2typst.json). Сборка:
//   typst compile paper/scratch-rocq-math.typ --root . \
//     --package-path paper/packages --font-path paper/fonts --ignore-system-fonts
#set page(width: auto, height: auto, margin: 1.2cm)
#set text(size: 13pt)

#let data = json("data/rocq2typst.json")

#for (k, v) in data [
  #block(below: 2em)[
    #text(fill: gray, size: 8pt)[#raw(k)] \
    //#text(fill: rgb("#777"), size: 9pt)[#raw(v)] \
    // Блочное уравнение, как в rocq-doc: переносы и выравнивание строк
    // (разметка со знаками \ и & из генератора) действуют только в блоке.
    #math.equation(block: true, eval(v, mode: "math"))
  ]
]
