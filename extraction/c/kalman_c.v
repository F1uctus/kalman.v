(*
  Точки входа CertiRocq для сырых данных фигур фильтра Калмана.

  Компилируются документы из extraction/common/figures_Q.v, то есть те же
  восемь документов, что собирает генератор данных в extraction/data, но
  инстанцированные на точных рациональных числах Q. Значения совпадают с
  доказанными термами над bigQ (леммы q_run_eq_bigq, q_run3_eq_bigq,
  q_dare_iters_eq_bigq), которые удовлетворяют проверкам коридора
  (sim_run_in_band, sim3_run_in_band) и уточнению из inst_bigQ.v
  (riccati_iter_seqmxC). Конвейер по умолчанию: все проходы стирания
  верифицированы.

  Печать документа определена в figures.v и figures_Q.v; здесь остаются только
  команды компиляции.
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
