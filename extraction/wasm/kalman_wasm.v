(*
  Точки входа WebAssembly для сырых данных фигур фильтра Калмана.

  Компилируются документы из extraction/common/figures_Q.v, то есть те же
  восемь документов, что собирает генератор данных в extraction/data, но
  инстанцированные на точных рациональных числах Q. Это даёт независимую
  проверку: путь через dune считает на float64 и округляет, а здесь счёт
  точен, и значения должны совпадать в пределах округления двойной точности.

  Печать документа определена в figures.v и figures_Q.v; здесь остаются только
  команды компиляции. Компиляция идёт через backend C конвейера CertiRocq, в
  котором есть сборщик мусора gc_stack; прямой backend Wasm без сборки мусора
  для этих термов непригоден.
*)
Set Warnings "-all".
From Stdlib Require Import List Strings.Byte.
From KalmanShow Require Import figures_Q.
From CertiRocq.Plugin Require Import CertiRocq.

Set CertiRocq Build Directory "generated".

CertiRocq Compile -O 1 -file "dare" dare_json.
CertiRocq Generate Glue -file "glue_dare" [ list, byte ].
CertiRocq Compile -O 1 -file "gramian" gramian_json.
CertiRocq Generate Glue -file "glue_gramian" [ list, byte ].
CertiRocq Compile -O 1 -file "schur" schur_json.
CertiRocq Generate Glue -file "glue_schur" [ list, byte ].
CertiRocq Compile -O 1 -file "run" run_json.
CertiRocq Generate Glue -file "glue_run" [ list, byte ].
CertiRocq Compile -O 1 -file "run3" run3_json.
CertiRocq Generate Glue -file "glue_run3" [ list, byte ].
CertiRocq Compile -O 1 -file "orthogonality" ortho_json.
CertiRocq Generate Glue -file "glue_orthogonality" [ list, byte ].
CertiRocq Compile -O 1 -file "lyapunov" lyap_json.
CertiRocq Generate Glue -file "glue_lyapunov" [ list, byte ].
CertiRocq Compile -O 1 -file "spectral" spectral_json.
CertiRocq Generate Glue -file "glue_spectral" [ list, byte ].
