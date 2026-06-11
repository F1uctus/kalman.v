(*
  Математическое ожидание матричнозначных случайных величин на основе infotheo.

  Вероятностная база: конечное распределение `fdist` из infotheo
  (`probability.fdist`), обобщённое в библиотеке до произвольного
  `numDomainType`. Математическое ожидание случайной матрицы задаётся
  формулой оператора `Ex` из `probability.proba` (сумма значений с
  весами `μ ω`); свойства линейности доказываются дословно как леммы
  `E_add_RV`, `E_scale_RV`, `E_opp_RV` из infotheo. На вещественном поле
  наш оператор совпадает с `E из infotheo с точностью до конвертируемости,
  а свойства линейности выводятся из одноимённых лемм библиотеки
  (секция ExpectationInfotheo ниже).

  Оператор `Ex` из infotheo напрямую не применим: он объявлен для
  `R : realType`, тогда как поле скаляров фильтра Калмана есть
  алгебраически замкнутое `numClosedFieldType`, которое вещественным
  полем не является. Поэтому ожидание определено здесь заново той же
  формулой, но над `numDomainType`, что покрывает оба случая.
*)

From Stdlib.Unicode Require Import Utf8.
From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix.
From mathcomp.reals Require Import reals.
From infotheo.probability Require Import fdist proba.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory.
Local Open Scope ring_scope.
Local Open Scope fdist_scope.
Local Open Scope proba_scope.

Section Expectation.

  Variable ℂ : numDomainType.

  (* Конечное вероятностное пространство: носитель Ω и распределение μ. *)
  Variables (Ω : finType) (μ : fdist ℂ Ω).

  (*
    Математическое ожидание случайной матрицы.

    Формула повторяет определение `Ex` из infotheo для случайных величин
    со значениями в модуле: $EE X = sum_(ω in Ω) μ(ω) dot X(ω)$.
  *)
  Definition Exp r c (X : Ω -> 'M[ℂ]_(r, c)) : 'M[ℂ]_(r, c) :=
    \sum_(ω in Ω) μ ω *: X ω.

  (* Конгруэнтность по поточечному равенству случайных величин. *)
  Lemma eq_Exp r c (X Y : Ω -> 'M[ℂ]_(r, c)) :
    X =1 Y -> Exp X = Exp Y.
  Proof. by move=> XY; apply: eq_bigr => ω _; rewrite XY. Qed.

  (* Аддитивность; доказательство дословно как `E_add_RV` в infotheo. *)
  Lemma Exp_add r c (X Y : Ω -> 'M[ℂ]_(r, c)) :
    Exp (fun ω => X ω + Y ω) = Exp X + Exp Y.
  Proof.
    rewrite /Exp -big_split /=.
    by apply: eq_bigr => ω _; rewrite scalerDr.
  Qed.

  (* Однородность; доказательство дословно как `E_scale_RV` в infotheo. *)
  Lemma Exp_scale r c (a : ℂ) (X : Ω -> 'M[ℂ]_(r, c)) :
    Exp (fun ω => a *: X ω) = a *: Exp X.
  Proof.
    rewrite /Exp scaler_sumr.
    by apply: eq_bigr => ω _; rewrite !scalerA mulrC.
  Qed.

  (* Вынос постоянной матрицы из-под знака ожидания слева. *)
  Lemma Exp_mulmx_l r c s (A : 'M[ℂ]_(r, c))
      (X : Ω -> 'M[ℂ]_(c, s)) :
    Exp (fun ω => A *m X ω) = A *m Exp X.
  Proof.
    rewrite /Exp mulmx_sumr.
    by apply: eq_bigr => ω _; rewrite scalemxAr.
  Qed.

  (*
    Ожидание постоянной случайной величины.

    Единственное место, где используется полная масса распределения
    (`FDist.f1`: $sum_ω μ(ω) = 1$); ср. `E_const_RV` в infotheo.
  *)
  Lemma Exp_const r c (M : 'M[ℂ]_(r, c)) : Exp (fun _ => M) = M.
  Proof. by rewrite /Exp -scaler_suml FDist.f1 scale1r. Qed.

  (* Производные тождества. *)

  Lemma Exp_zero r c : Exp (fun _ => 0 : 'M[ℂ]_(r, c)) = 0.
  Proof. exact: Exp_const. Qed.

  Lemma Exp_opp r c (X : Ω -> 'M[ℂ]_(r, c)) :
    Exp (fun ω => - X ω) = - Exp X.
  Proof.
    rewrite /Exp -sumrN.
    by apply: eq_bigr => ω _; rewrite scalerN.
  Qed.

  Lemma Exp_sub r c (X Y : Ω -> 'M[ℂ]_(r, c)) :
    Exp (fun ω => X ω - Y ω) = Exp X - Exp Y.
  Proof.
    by rewrite (Exp_add X (fun ω => - Y ω)) Exp_opp.
  Qed.

End Expectation.

(*
  Распределение μ входит только в заключение лемм, поэтому неявным
  аргументом само не становится; объявляем неявность вручную, чтобы
  пользоваться леммами при локальном обозначении 𝔼 := Exp μ.
*)
Arguments eq_Exp {ℂ Ω μ r c X Y}.
Arguments Exp_add {ℂ Ω μ r c} X Y.
Arguments Exp_scale {ℂ Ω μ r c} a X.
Arguments Exp_mulmx_l {ℂ Ω μ r c s} A X.
Arguments Exp_const {ℂ Ω μ r c} M.
Arguments Exp_zero {ℂ Ω μ r c}.
Arguments Exp_opp {ℂ Ω μ r c} X.
Arguments Exp_sub {ℂ Ω μ r c} X Y.

Section ExpectationInfotheo.

  (*
    Мост к infotheo: на вещественном поле наш оператор совпадает с `E,
    а свойства линейности следуют из одноимённых лемм библиотеки.
  *)
  Variables (R : realType) (Ω : finType) (μ : fdist R Ω).
  Variables (r c : nat).

  (* Совпадение определений с точностью до конвертируемости. *)
  Lemma ExpE (X : {RV μ -> 'M[R]_(r, c)}) : Exp μ X = `E X.
  Proof. by []. Qed.

  (* Аддитивность как следствие `E_add_RV` из infotheo. *)
  Lemma Exp_addE (X Y : {RV μ -> 'M[R]_(r, c)}) :
    Exp μ (fun ω => X ω + Y ω) = Exp μ X + Exp μ Y.
  Proof. by rewrite !ExpE (E_add_RV X Y). Qed.

  (* Однородность как следствие `E_scale_RV` из infotheo. *)
  Lemma Exp_scaleE (a : R) (X : {RV μ -> 'M[R]_(r, c)}) :
    Exp μ (fun ω => a *: X ω) = a *: Exp μ X.
  Proof. by rewrite !ExpE (E_scale_RV X a). Qed.

End ExpectationInfotheo.
