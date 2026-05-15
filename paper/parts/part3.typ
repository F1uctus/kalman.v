#import "../lib.typ": *
#import "@preview/cetz:0.3.2"

#part_count.step()

#cetz.canvas({
  import cetz.draw: *

  // --- STYLING CONFIGURATIONS ---
  let default-rect(name, pos, label, fill-color) = {
    rect(
      (pos.at(0) - 1.25, pos.at(1) - 0.25), 
      (pos.at(0) + 1.25, pos.at(1) + 0.25), 
      fill: fill-color, 
      stroke: 1pt + black, 
      name: name
    )
    content(name, text(font: "Courier", size: 9pt, weight: "bold", fill: if fill-color == rgb("008080") { white } else { black }, label))
  }

  let arrow-style = (mark: (end: ">"), stroke: 1pt + black)

  // --- DRAWING NODES ---
  
  // Top Level
  content((6.0, 4.0), text(font: "Courier", size: 10pt, weight: "bold", [Type]), name: "Type")
  
  // Level 1
  default-rect("predType", (1.5, 2.5), [predType T], white)
  default-rect("eqType", (6.0, 2.5), [eqType], rgb("D3D3D3"))
  
  // Level 2
  default-rect("choiceType", (6.0, 1.3), [choiceType], rgb("FF9999"))
  
  // Level 3
  default-rect("zmodType", (3.5, 0.5), [zmodType], rgb("008080"))
  
  // Level 4
  default-rect("lmodType", (-1.0, -0.5), [lmodType R], rgb("008080"))
  default-rect("ringType", (3.5, -0.5), [ringType], rgb("008080"))
  
  // Level 5
  default-rect("lalgType", (-1.0, -1.5), [lalgType R], rgb("008080"))
  default-rect("unitRingType", (2.0, -1.5), [unitRingType], rgb("008080"))
  default-rect("comRingType", (5.0, -1.5), [comRingType], rgb("008080"))
  
  // Level 6
  default-rect("algType", (-1.0, -2.5), [algType R], rgb("008080"))
  default-rect("comUnitRingType", (3.5, -2.5), [comUnitRingType], rgb("008080"))
  
  // Level 7
  default-rect("unitAlgType", (-1.0, -3.7), [unitAlgType R], rgb("008080"))
  default-rect("idomainType", (3.5, -3.7), [idomainType], rgb("008080"))
  
  // Level 8-11 (Right-hand long chain)
  default-rect("fieldType", (3.5, -4.9), [fieldType], rgb("008080"))
  default-rect("decFieldType", (3.5, -6.1), [decFieldType], rgb("008080"))
  default-rect("closedFieldType", (3.5, -7.3), [closedFieldType], rgb("008080"))

  // Isolated Orange/Yellow Groups (Left Bottom & Mid Bottom)
  default-rect("monoidLaw", (-4.5, -4.5), [Monoid.law idx], rgb("FFCC00"))
  default-rect("monoidComLaw", (-4.5, -5.7), [Monoid.com_law idx], rgb("FFCC00"))
  default-rect("monoidAddLaw", (-4.5, -6.9), [Monoid.add_law idx mop], rgb("FFCC00"))
  
  default-rect("monoidMulLaw", (0.0, -6.2), [Monoid.mul_law abz], rgb("FFCC00"))

  // --- DRAWING CONNECTIONS (ARROWS) ---
  
  // From Type
  line("Type.south", "predType.north", ..arrow-style)
  line("Type.south", "eqType.north", ..arrow-style)
  
  // Main Tree Links
  line("eqType.south", "choiceType.north", ..arrow-style)
  line("choiceType.south", "zmodType.north", ..arrow-style)
  
  line("zmodType.south", "lmodType.north", ..arrow-style)
  line("zmodType.south", "ringType.north", ..arrow-style)
  
  line("lmodType.south", "lalgType.north", ..arrow-style)
  
  line("ringType.south", "lalgType.north", ..arrow-style)
  line("ringType.south", "unitRingType.north", ..arrow-style)
  line("ringType.south", "comRingType.north", ..arrow-style)
  
  line("lalgType.south", "algType.north", ..arrow-style)
  line("algType.south", "unitAlgType.north", ..arrow-style)
  
  line("unitRingType.south", "unitAlgType.north", ..arrow-style)
  line("unitRingType.south", "comUnitRingType.north", ..arrow-style)
  line("comRingType.south", "comUnitRingType.north", ..arrow-style)
  
  // Linear vertical chain on right
  line("comUnitRingType.south", "idomainType.north", ..arrow-style)
  line("idomainType.south", "fieldType.north", ..arrow-style)
  line("fieldType.south", "decFieldType.north", ..arrow-style)
  line("decFieldType.south", "closedFieldType.north", ..arrow-style)

  // Monoid Chain Links
  line("monoidLaw.south", "monoidComLaw.north", ..arrow-style)
  line("monoidComLaw.south", "monoidAddLaw.north", ..arrow-style)
})

= Обзор литературы и исторический контекст <sec:literature>

== Welch и Bishop --- дискретный фильтр Калмана (UNC TR 95-041, 2006) <sec:welch-bishop>

_Источник:_ `docs/An Introduction to the Kalman Filter.pdf`.

+ Оценка состояния $x in RR^n$ дискретного процесса
+  $x_k = A x_(k-1) + B u_(k-1) + w_(k-1)$ с наблюдениями $z_k = H x_k + v_k$;
+  шумы $w ~ cal(N)(0,Q)$, $v ~ cal(N)(0,R)$.
+ Априорная и апостериорная оценки, инновация $(z_k - H hat(x)_k^-)$, усиление
+  $K_k = P_k^- H^top (H P_k^- H^top + R)^(-1)$.
+ Цикл предсказание--коррекция; форма $P_k = (E_n - K_k H) P_k^-$.
+ Расширенный фильтр Калмана (EKF): линеаризация якобианами.

== Kalman (1960) --- линейная оценка, пространство состояний, рекурсия Риккати <sec:kalman-1960>

_Источник:_ `docs/Kalman1960.pdf`.

+ Переход от формализма Винера--Хопфа к моделям в пространстве состояний.
+ Оптимальная оценка как условное среднее; для гауссовых процессов совпадает
+  с линейной MMSE-оценкой.
+ Ортогональные проекции: оценка как проекция на пространство наблюдений.
+ Теорема 3: рекурсия для ковариации ошибки (дискретное уравнение типа Риккати).
+ Теорема 4: двойственность фильтрации и регулирования.
