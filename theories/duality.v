(*
  Двойственность оценивания и управления.

  Структурные условия сходимости фильтра Калмана
  (наблюдаемость, детектируемость, грамиан наблюдаемости) и парные им условия
  управления (управляемость, стабилизируемость, грамиан управляемости) - не два
  независимых набора, а образы друг друга при эрмитовом сопряжении $(dot)†$.
  Здесь это сделано явным: каждая лемма переводит объект оценивания в его
  двойственник по управлению заменой $(F, G) |-> (F†, G†)$. Для левого и правого
  PBH-тестов собственное значение при этом сопрягается, $λ |-> λ^*$, а его
  модуль $|λ|$ сохраняется (`norm_conjC`), поэтому граница неустойчивости
  $|λ| >= 1$ переносится без изменений.

  Доказанные соответствия:
  - `stabilizable_dual` - стабилизируемость пары $(F, G)$ равносильна
    детектируемости двойственной пары $(F†, G†)$
    (левый PBH-тест переходит в правый);
  - `controllable_dual` - управляемость равносильна наблюдаемости двойственной
    пары (ядерные ранговые условия);
  - `ctrl_gram_dual` - грамиан управляемости совпадает с грамианом наблюдаемости
    двойственной пары (с весом `invmx Q`);
  - `stabilizable_stabilizing_dual` - существование стабилизирующей обратной
    связи по состоянию $F - G K$ равносильно существованию стабилизирующей
    коррекции по выходу $F† - K' H'$ двойственной системы.

  Двойственность самих оптимальных решений уравнения Риккати
  (фильтр Калмана и LQR-регулятор) классическая и здесь не формализуется: для
  неё требуется отдельно определить управляющее уравнение Риккати (LQR), что
  вынесено в направления дальнейшей работы.

  Прямое направление PBH-двойственности уже доказано как
  `lyap_inv.stabilizable_detectable_conj`; ниже оно дополнено обратным.

  - @kailath2000[App. C, § C.3-C.4].
*)

Set Warnings "-notation-overridden,-coercions,-default".

From Stdlib.Unicode Require Import Utf8.
From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra.
From mathcomp.algebra Require Import sesquilinear spectral.
From mathcomp Require Import order.
From mathcomp.classical Require Import boolp.
From Kalman Require Import mxnotation mxherm mxdefinite kalman spec_rad
  detectability obsv_bound lyap_inv.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory Num.Theory Order.Theory.
Local Open Scope ring_scope.
Local Open Scope sesquilinear_scope.

Section Duality.

  Variable ℂ : numClosedFieldType.

  (*
    Обратное направление к `lyap_inv.stabilizable_detectable_conj`:
    детектируемость пары $(A, H)$ даёт стабилизируемость двойственной пары
    $(A†, H†)$. Правый собственный вектор $A v = λ v$ переходит в левый
    $w A† = λ^* w$ при $w := v†$.

    - @kailath2000[App. C, § C.4].
  *)
  Lemma detectable_stabilizable_conj n p (A : 'M[ℂ]_n) (H : 'M[ℂ]_(p, n)) :
    detectable A H -> stabilizable (A^t*) (H^t*).
  Proof.
    move=> Hdet mu w wNZ wA mu_ge1.
    set v := w^t*.
    have vNZ : v != 0 by rewrite /v trmxC_eq0.
    have Av : A *m v = mu^* *: v.
      by rewrite /v -{1}(trmxCK A) -trmxC_mul wA trmxC_scale.
    have mu_conj_ge1 : 1 <= `|mu^*| by rewrite norm_conjC.
    have Hv := Hdet mu^* v vNZ Av mu_conj_ge1.
    apply: contra_neq Hv => wH0.
    by rewrite -[H *m v]trmxCK trmxC_mul /v trmxCK wH0 trmxC0.
  Qed.

  (*
    PBH-двойственность: стабилизируемость пары $(F, G)$ равносильна
    детектируемости двойственной пары $(F†, G†)$.

    - @kailath2000[App. C, § C.3 "Controllability and Stabilizability"].
  *)
  Theorem stabilizable_dual n m (F : 'M[ℂ]_n) (G : 'M[ℂ]_(n, m)) :
    stabilizable F G <-> detectable (F^t*) (G^t*).
  Proof.
    split; first exact: stabilizable_detectable_conj.
    move=> Hdet; have h := detectable_stabilizable_conj Hdet.
    by rewrite !trmxCK in h.
  Qed.

  (*
    Управляемость пары $(F, G)$ влечёт наблюдаемость двойственной пары: блок
    управляемости $F^i G$ переходит в блок наблюдаемости $G† (F†)^i = (F^i G)†$,
    а ядро строк - в ядро столбцов.

    - @kailath2000[App. C, § C.3].
  *)
  Lemma controllable_observable_conj n m (F : 'M[ℂ]_n) (G : 'M[ℂ]_(n, m)) :
    controllable F G -> observable (F^t*) (G^t*).
  Proof.
    move=> Hctrl x Hx.
    have Hy : forall i : 'I_n, x^t* *m ctrl_block F G i = 0.
      move=> i; apply/eqP.
      rewrite -trmxC_eq0 trmxC_mul trmxCK /ctrl_block trmxC_mul trmxCX.
      by have := Hx i; rewrite /obsv_block => ->.
    by have /eqP := Hctrl _ Hy; rewrite trmxC_eq0 => /eqP.
  Qed.

  (* Двойственно: наблюдаемость влечёт управляемость двойственной пары. *)
  Lemma observable_controllable_conj n p (F : 'M[ℂ]_n) (H : 'M[ℂ]_(p, n)) :
    observable F H -> controllable (F^t*) (H^t*).
  Proof.
    move=> Hobs y Hy.
    have Hx : forall i : 'I_n, obsv_block F H i *m y^t* = 0.
      move=> i; apply/eqP.
      rewrite -trmxC_eq0 trmxC_mul trmxCK /obsv_block trmxC_mul trmxCX.
      by have := Hy i; rewrite /ctrl_block => ->.
    by have /eqP := Hobs _ Hx; rewrite trmxC_eq0 => /eqP.
  Qed.

  (*
    Двойственность наблюдаемости и управляемости (ранговые/ядерные условия).

    - @kailath2000[App. C, § C.3 "Controllability and Stabilizability"].
  *)
  Theorem controllable_dual n m (F : 'M[ℂ]_n) (G : 'M[ℂ]_(n, m)) :
    controllable F G <-> observable (F^t*) (G^t*).
  Proof.
    split; first exact: controllable_observable_conj.
    move=> Hobs; have h := observable_controllable_conj Hobs.
    by rewrite !trmxCK in h.
  Qed.

  (*
    Двойственность грамианов.

    $cal(C)_k (F, G, Q) = cal(O)_k (F†, G†, Q^(-1))$ при обратимой $Q$.

    - @kailath2000[App. C, § C.3 "Controllability and Stabilizability"].
  *)
  Theorem ctrl_gram_dual n m (F : 'M[ℂ]_n) (G : 'M[ℂ]_(n, m))
      (Q : 'M[ℂ]_m) (k : nat) :
    Q \in unitmx ->
    ctrl_gram F G Q k = obsv_gram (F^t*) (G^t*) (invmx Q) k.
  Proof.
    move=> Qunit; rewrite /ctrl_gram /obsv_gram.
    apply: eq_bigr => j _.
    by rewrite -!trmxCX !trmxCK invmxK.
  Qed.

  (*
    Двойственность стабилизирующих связей.

    Стабилизируемость с обратной связью по состоянию $F - G K$
    (устойчивость по Шуру) равносильна стабилизируемости двойственной системы
    коррекцией по выходу $F† - K' H†$; эрмитово сопряжение сохраняет спектр по
    модулю.

    - @kailath2000[App. C, § C.3 "Controllability and Stabilizability"].
  *)
  Theorem stabilizable_stabilizing_dual n m
      (F : 'M[ℂ]_n.+1) (G : 'M[ℂ]_(n.+1, m)) :
    stabilizable_stabilizing F G <-> detectable_stabilizing (F^t*) (G^t*).
  Proof.
    split=> -[K HK].
    - exists (K^t*).
      have -> : F^t* - K^t* *m G^t* = (F - G *m K)^t*
        by rewrite trmxCB trmxC_mul.
      exact: spec_rad_lt1_trmxC HK.
    - exists (K^t*).
      have h := spec_rad_lt1_trmxC HK.
      by rewrite trmxCB trmxC_mul !trmxCK in h.
  Qed.

End Duality.
