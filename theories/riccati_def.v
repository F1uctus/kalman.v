(*
  Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
  SPDX-License-Identifier: GPL-3.0-or-later

  Определения над коммутативным кольцом, где некоторые элементы имеют обратный.

  Определения параметризованы кольцом `R : comUnitRingType` и операцией
  сопряжения `conj : R -> R`. Сопряжённое транспонирование `M^t*` из `kalman.v`
  (комплексный случай, `conj := conjC`) здесь записано как `map_mx conj M^T`,
  поскольку `M^t*` есть обозначение для `map_mx conjC M^T`. Это общий слой:
  `kalman.v` получает свои операторы подстановкой `conj := conjC` над
  `numClosedFieldType`, а вычислимое уточнение (`seqmx/riccati_seqmx.v`)
  подставляет `conj := idfun` над полем `rat` или арифметикой `bigQ`.

  Леммы с суффиксом `E` есть определяющие равенства операторов: они
  разворачивают оператор переписыванием `rewrite predict_covE` там, где короткое
  имя оператора закрыто обозначением, фиксирующим `conj := conjC`
  (тогда `rewrite /predict_cov` не сработает, т.к. `/` снимает определение, но не обозначение).
*)

From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg matrix mxalgebra.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory.
Local Open Scope ring_scope.

Section GenericDefs.

  Variable R : comUnitRingType.
  Variable conj : R -> R.

  Variables (m n p : nat).
  Variables (F : 'M[R]_n) (G : 'M[R]_(n, m)) (H : 'M[R]_(p, n)).
  Variables (Q : 'M[R]_m) (R_m : 'M[R]_p).

  (* Ковариация предсказания: $F P F† + G Q G†$. *)
  Definition predict_cov (P : 'M[R]_n) : 'M[R]_n :=
    F *m P *m map_mx conj F^T + G *m Q *m map_mx conj G^T.

  (* Инновационная ковариация: $R_(e,k) = H P H† + R$. *)
  Definition innov_cov (P : 'M[R]_n) : 'M[R]_p :=
    H *m P *m map_mx conj H^T + R_m.

  (* Усиление фильтра: $K_(f,k) = P H† R_(e,k)^(-1)$. *)
  Definition filter_gain (P : 'M[R]_n) : 'M[R]_(n, p) :=
    P *m map_mx conj H^T *m invmx (innov_cov P).

  (* Обновление ковариации: $(E_n - K H) P$. *)
  Definition update_cov (P : 'M[R]_n) : 'M[R]_n :=
    (1%:M - filter_gain P *m H) *m P.

  (*
    Шаг обновления с произвольным усилением $K_p$ в форме Джозефа:
    $(E_n - K_p H) P (E_n - K_p H)† + K_p R K_p†$.
  *)
  Definition alt_update_cov (K_p : 'M[R]_(n, p)) (P : 'M[R]_n) : 'M[R]_n :=
    let EmKH := 1%:M - K_p *m H in
    EmKH *m P *m map_mx conj EmKH^T + K_p *m R_m *m map_mx conj K_p^T.

  (*
    Шаг итерации Риккати: $P_(k+1|k+1) = "riccati_step"(P_(k|k))$, где
    $"riccati_step" := (P |-> (E_n - K H) P) ∘ (P |-> F P F† + G Q G†)$.
  *)
  Definition riccati_step (P : 'M[R]_n) : 'M[R]_n :=
    update_cov (predict_cov P).

  (* Неподвижная точка шага Риккати. *)
  Definition riccati_fixpoint (P_ss : 'M[R]_n) : Prop :=
    P_ss = riccati_step P_ss.

  Lemma predict_covE (P : 'M[R]_n) :
    predict_cov P = F *m P *m map_mx conj F^T + G *m Q *m map_mx conj G^T.
  Proof. by []. Qed.

  Lemma innov_covE (P : 'M[R]_n) :
    innov_cov P = H *m P *m map_mx conj H^T + R_m.
  Proof. by []. Qed.

  Lemma filter_gainE (P : 'M[R]_n) :
    filter_gain P = P *m map_mx conj H^T *m invmx (innov_cov P).
  Proof. by []. Qed.

  Lemma update_covE (P : 'M[R]_n) :
    update_cov P = (1%:M - filter_gain P *m H) *m P.
  Proof. by []. Qed.

  Lemma alt_update_covE (K_p : 'M[R]_(n, p)) (P : 'M[R]_n) :
    alt_update_cov K_p P =
    (1%:M - K_p *m H) *m P *m map_mx conj (1%:M - K_p *m H)^T
    + K_p *m R_m *m map_mx conj K_p^T.
  Proof. by []. Qed.

  Lemma riccati_stepE (P : 'M[R]_n) :
    riccati_step P = update_cov (predict_cov P).
  Proof. by []. Qed.

End GenericDefs.

(*
  Грамианы и матрица замкнутого контура над (R, conj). Те же определения при
  `conj := conjC` над `numClosedFieldType` дают грамианы `obsv_bound.v`, а при
  `conj := idfun` над `rat`/`bigQ` - исполнимый эталон. `obsv_gram` записан с
  весом `W` явно: грамиан `obsv_bound.obsv_gram F H R` отвечает `W := invmx R`.
*)
Section Gramians.

  Variable R : comUnitRingType.
  Variable conj : R -> R.

  (* Грамиан наблюдаемости с весом `W`. *)
  Definition obsv_gram (n p : nat) (F : 'M[R]_n) (H : 'M[R]_(p, n))
      (W : 'M[R]_p) (k : nat) : 'M[R]_n :=
    \sum_(j < k)
      map_mx conj (F ^+ j)^T *m map_mx conj H^T *m W *m H *m (F ^+ j).

  Lemma obsv_gram0 (n p : nat) (F : 'M[R]_n) (H : 'M[R]_(p, n))
      (W : 'M[R]_p) :
    obsv_gram F H W 0 = 0.
  Proof. by rewrite /obsv_gram big_ord0. Qed.

  Lemma obsv_gram_recr (n p : nat) (F : 'M[R]_n) (H : 'M[R]_(p, n))
      (W : 'M[R]_p) (k : nat) :
    obsv_gram F H W k.+1 =
    obsv_gram F H W k +
    map_mx conj (F ^+ k)^T *m map_mx conj H^T *m W *m H *m (F ^+ k).
  Proof. by rewrite /obsv_gram big_ord_recr. Qed.

  (* Грамиан управляемости. *)
  Definition ctrl_gram (n m : nat) (F : 'M[R]_n) (G : 'M[R]_(n, m))
      (Q : 'M[R]_m) (k : nat) : 'M[R]_n :=
    \sum_(j < k)
      (F ^+ j) *m G *m Q *m map_mx conj G^T *m map_mx conj (F ^+ j)^T.

  Lemma ctrl_gram0 (n m : nat) (F : 'M[R]_n) (G : 'M[R]_(n, m))
      (Q : 'M[R]_m) :
    ctrl_gram F G Q 0 = 0.
  Proof. by rewrite /ctrl_gram big_ord0. Qed.

  Lemma ctrl_gram_recr (n m : nat) (F : 'M[R]_n) (G : 'M[R]_(n, m))
      (Q : 'M[R]_m) (k : nat) :
    ctrl_gram F G Q k.+1 =
    ctrl_gram F G Q k +
    (F ^+ k) *m G *m Q *m map_mx conj G^T *m map_mx conj (F ^+ k)^T.
  Proof. by rewrite /ctrl_gram big_ord_recr. Qed.

  (*
    Матрица замкнутого контура (предиктор) $F - F K_f H$, где $K_f$ обозначает
    фильтрующее усиление на предсказанной ковариации `predict_cov`.
  *)
  Definition closed_loop (m n p : nat) (F : 'M[R]_n) (G : 'M[R]_(n, m))
      (H : 'M[R]_(p, n)) (Q : 'M[R]_m) (R_m : 'M[R]_p)
      (P : 'M[R]_n) : 'M[R]_n :=
    F - F *m filter_gain conj H R_m (predict_cov conj F G Q P) *m H.

End Gramians.
