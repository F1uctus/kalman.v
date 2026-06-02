(*
  Спектральный радиус через разложение Шура.

  Над `numClosedFieldType` каждая квадратная матрица унитарно подобна
  верхнетреугольной (теорема Шура, mathcomp 2.x `algebra/spectral.v`). Диагональ
  `T = U A U†` содержит собственные значения `A`; `spec_rad A := max_i ‖T_ii‖` -
  спектральный радиус.

  Здесь введён Prop-предикат `spec_rad_lt1 A`
  (разложение Шура, у которого вся диагональ строго внутри открытого единичного диска)
  и доказана достаточность сжатия по норме Фробениуса:
  `frob_sq A < 1 -> spec_rad_lt1 A.`

  ([kailath2000], App. E): устойчивость по Шуру - настоящее условие сходимости
  итераций A^k, более слабое чем frob_sq A < 1, но достаточное для всего
  аппарата ДАУР.
*)

Set Warnings "-notation-overridden,-coercions,-default".

From Stdlib.Unicode Require Import Utf8.
From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra archimedean.
From mathcomp.algebra Require Import sesquilinear spectral mxred.
From mathcomp Require Import order.
From mathcomp.classical Require Import boolp classical_sets.
From mathcomp Require Import topology normedtype sequences.
From mathcomp.reals Require Import reals.
From Kalman Require Import mxnotation mxherm mxdefinite mxloewner mxfrob mxtopo.
From Kalman Require Import mxmonotone lyapunov.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory Num.Theory Order.Theory.
Import numFieldTopology.Exports.
Local Open Scope ring_scope.
Local Open Scope classical_set_scope.
Local Open Scope sesquilinear_scope.

(* Инвариантность квадрата нормы Фробениуса относительно сопряжения. *)
Section FrobUnitary.

  Variable (ℂ : numClosedFieldType).

  (* Унитарная `U` слева: frob_sq (U M) = frob_sq M. *)
  Lemma frob_sq_unitary_left n m (U : 'M[ℂ]_n) (M : 'M[ℂ]_(n, m)) :
    U \is unitarymx -> frob_sq (U *m M) = frob_sq M.
  Proof.
    move=> hU.
    have hUCU : U^t* *m U = 1%:M.
      rewrite -invmx_unitary //.
      by apply: mulVmx; exact: unitarymx_unit.
    rewrite /frob_sq trmxC_mul -[(M^t* *m U^t*) *m _]mulmxA.
    by rewrite [U^t* *m _]mulmxA hUCU mul1mx.
  Qed.

  (* Унитарная `U` справа: frob_sq (M U) = frob_sq M. *)
  Lemma frob_sq_unitary_right n m (U : 'M[ℂ]_n) (M : 'M[ℂ]_(m, n)) :
    U \is unitarymx -> frob_sq (M *m U) = frob_sq M.
  Proof.
    move=> hU.
    rewrite -[in RHS]frob_sq_trmxC -[in LHS]frob_sq_trmxC.
    rewrite trmxC_mul.
    apply: frob_sq_unitary_left.
    by rewrite trmxC_unitary.
  Qed.

  (* Сопряжение унитарными: frob_sq (U M U†) = frob_sq M. *)
  Lemma frob_sq_conj_unitary n (U M : 'M[ℂ]_n) :
    U \is unitarymx -> frob_sq (U *m M *m U^t*) = frob_sq M.
  Proof.
    move=> hU.
    rewrite frob_sq_unitary_right; first exact: frob_sq_unitary_left.
    by rewrite trmxC_unitary.
  Qed.

End FrobUnitary.

(* Оценка модуля диагонального элемента через квадрат нормы Фробениуса. *)
Section DiagBound.

  Variable (ℂ : numClosedFieldType).

  (*
    Для каждого диагонального элемента M_ii: ‖M_ii‖² <= frob_sq M. Тривиально
    через frob_sqE: ∑_(i,j) M_ij^* M_ij >= единичное слагаемое
    `M_ii^* M_ii = ‖M_ii‖²`.
  *)
  Lemma diag_normCK_le_frob_sq n (M : 'M[ℂ]_n) (i : 'I_n) :
    `|M i i| ^+ 2 <= frob_sq M.
  Proof.
    rewrite normCKC frob_sqE.
    have h_nn : forall j k : 'I_n, 0 <= (M k j)^* * M k j.
      by move=> j k; rewrite mulrC; exact: mul_conjC_ge0.
    rewrite (bigD1 i) //=.
    rewrite (bigD1 i) //=.
    (* Цель: X <= (X + S_inner) + S_outer; разделяем lerD на две части. *)
    rewrite -[X in X <= _]addr0.
    apply: lerD; last by apply: sumr_ge0=> j _; apply: sumr_ge0=> k _; exact: h_nn.
    rewrite lerDl.
    by apply: sumr_ge0=> k _; exact: h_nn.
  Qed.

End DiagBound.

(* Спектральный радиус: формулировка через разложение Шура. *)
Section SpecRad.

  Variable (ℂ : numClosedFieldType).

  (*
    `spec_rad_lt1 A` - существование разложения Шура с диагональю строго внутри
    открытого единичного диска. Не утверждает максимум
    (это потребовало бы `bigmax`), но достаточно для последующих результатов:
    спектральный анализ через любую конкретную треугольную форму.
    ([kailath2000], App. C, § C.3)
  *)
  Definition spec_rad_lt1 n (A : 'M[ℂ]_n) : Prop :=
    exists U T : 'M[ℂ]_n,
      [/\ U \is unitarymx,
          A = U^t* *m T *m U,
          is_trig_mx T &
          forall i : 'I_n, `|T i i| < 1].

  (*
    ============================================================================
    Главная теорема: Сжатие в норме Фробениуса => Устойчивость по Шуру
    ============================================================================
  *)

  (*
    Для n+1: устраняем граничный случай n = 0
    (устойчивость по Шуру требует n > 0).
  *)
  Theorem frob_sq_contract_spec_rad_lt1 n (A : 'M[ℂ]_n.+1) :
    frob_sq A < 1 -> spec_rad_lt1 A.
  Proof.
    move=> Ac.
    (* Шаг 1: теорема Шура даёт унитарную U и треугольную conjmx U A. *)
    have HSchur : (0 < n.+1)%N := isT.
    have [U Uunit Atrig] := Schur A HSchur.
    (* Atrig : is_trig_mx (conjmx U A); conjmx U A = U A U† при унитарной U. *)
    have HTeq : conjmx U A = U *m A *m U^t* := conjymx A Uunit.
    set T := conjmx U A.
    (* Шаг 2: A = U† T U (обратное разложение Шура). *)
    have hUUC : U *m U^t* = 1%:M by apply/unitarymxP.
    have hUCU : U^t* *m U = 1%:M.
      rewrite -invmx_unitary //.
      by apply: mulVmx; exact: unitarymx_unit.
    have HAdec : A = U^t* *m T *m U.
      rewrite /T HTeq.
      have ->: U^t* *m (U *m A *m U^t*) *m U
            = U^t* *m U *m A *m U^t* *m U
        by rewrite !mulmxA.
      rewrite hUCU mul1mx -mulmxA hUCU.
      by rewrite mulmx1.
    (* Шаг 3: frob_sq T = frob_sq A (унитарная инвариантность). *)
    have HfrobEq : frob_sq T = frob_sq A.
      by rewrite /T HTeq; exact: frob_sq_conj_unitary.
    (* Шаг 4: для каждого i диагональный элемент в модуле < 1. *)
    exists U, T; split=> //.
    move=> i.
    have Hsq : `|T i i| ^+ 2 < 1.
      have step1 : `|T i i| ^+ 2 <= frob_sq T := diag_normCK_le_frob_sq T i.
      rewrite HfrobEq in step1.
      exact: le_lt_trans step1 Ac.
    (* ‖Tᵢᵢ‖² < 1 => ‖Tᵢᵢ‖ < 1 - через mono `ltr_pXn2r` на Num.nneg. *)
    rewrite -(@ltr_pXn2r _ 2 isT _ _ _ _) ?nnegrE //.
    by rewrite expr1n; exact: Hsq.
  Qed.

  (*
    ============================================================================
    Устойчивость по Шуру => нет собственных значений с |λ| >= 1.
    ============================================================================
  *)

  (*
    Спектральная характеризация `spec_rad_lt1`: любой корень характеристического
    многочлена (т.е. любое собственное значение) лежит строго внутри единичного
    диска. Нужна для определения детектируемости ([kailath2000], App. C, § C.4):
    пара (F, H) с замыкающим K, делающим F − KH устойчивой по Шуру, не имеет
    ненаблюдаемых неустойчивых мод.

    ([kailath2000], App. D, Lemma D.3.1)
  *)
  Lemma spec_rad_lt1_det_eig n (A : 'M[ℂ]_n) (lam : ℂ) :
    spec_rad_lt1 A -> \det (lam%:M - A) == 0 -> `|lam| < 1.
  (*
    Схема: A = U† T U (разложение Шура), унитарное сопряжение сохраняет
    определитель, поэтому det (λE − A) = det (λE − T); матрица λE − T
    треугольна, её det = ∏ᵢ (λ − Tᵢᵢ). Если det = 0, то λ = Tᵢᵢ для некоторого
    i, откуда |λ| = |Tᵢᵢ| < 1.
  *)
  Proof.
    move=> [U [T [Uunit Adec Ttrig Tdiag]]] Hdet.
    have hUCU : U^t* *m U = 1%:M.
      rewrite -invmx_unitary //.
      by apply: mulVmx; exact: unitarymx_unit.
    have hdetU : \det U * \det (U^t*) = 1.
      by rewrite -det_mulmx -invmx_unitary // mulmxV ?det1 // unitarymx_unit.
    (* Унитарное сопряжение не меняет определитель характеристической формы. *)
    have detEq : \det (lam%:M - A) = \det (lam%:M - T).
      have conj_id : U^t* *m (lam%:M - T) *m U = lam%:M - A.
        rewrite mulmxBr mulmxBl Adec; congr (_ - _).
        by rewrite mul_mx_scalar -scalemxAl hUCU scalemx1.
      rewrite -conj_id !det_mulmx -mulrA [\det (lam%:M - T) * \det U]mulrC mulrA.
      by rewrite [\det (U^t*) * \det U]mulrC hdetU mul1r.
    rewrite detEq in Hdet.
    (* λE − T треугольна => det = ∏ᵢ (λ − Tᵢᵢ). *)
    have htrig : is_trig_mx (lam%:M - T : 'M[ℂ]_n).
      apply/is_trig_mxP=> i j ltij.
      have ij : (i == j) = false by apply: ltn_eqF.
      have Tz : T i j = 0 by apply: (elimT is_trig_mxP Ttrig).
      by rewrite !mxE ij /= Tz subr0.
    rewrite (det_trig htrig) in Hdet.
    move/prodf_eq0: Hdet => [i _ Hi].
    move: Hi; rewrite !mxE eqxx mulr1n subr_eq0 => /eqP ->.
    exact: Tdiag i.
  Qed.

  (*
    Правый собственный вектор: `A v = λ v, v != 0 => |λ| < 1`. Через
    вырожденность λE − A (`ker ∋ v != 0`) и `det0P`
    (транспонируем к строчной форме det0P).
  *)
  Lemma spec_rad_lt1_eigval n (A : 'M[ℂ]_n) (lam : ℂ) (v : 'cV[ℂ]_n) :
    spec_rad_lt1 A -> v != 0 -> A *m v = lam *: v -> `|lam| < 1.
  Proof.
    move=> Hsr vNZ Av; apply: (spec_rad_lt1_det_eig Hsr).
    rewrite -det_tr; apply/det0P.
    exists v^T; first by rewrite trmx_eq0.
    rewrite -trmx_mul.
    have -> : (lam%:M - A) *m v = 0 by rewrite mulmxBl mul_scalar_mx Av subrr.
    by rewrite trmx0.
  Qed.

  (*
    Левый собственный вектор: w A = λ w, w != 0 => |λ| < 1. Прямо через строчную
    форму `det0P` (без транспонирования). Нужна для стабилизируемости
    (двойственной детектируемости).
  *)
  Lemma spec_rad_lt1_left_eigval n (A : 'M[ℂ]_n) (lam : ℂ)
      (w : 'rV[ℂ]_n) :
    spec_rad_lt1 A -> w != 0 -> w *m A = lam *: w -> `|lam| < 1.
  Proof.
    move=> Hsr wNZ wA; apply: (spec_rad_lt1_det_eig Hsr); apply/det0P.
    exists w => //.
    by rewrite mulmxBr mul_mx_scalar wA subrr.
  Qed.

  (*
    Обратная характеризация: если все корни характеристического многочлена
    (т.е. все собственные значения) лежат строго внутри единичного диска, то
    выполнено `spec_rad_lt1 A` - строится разложение Шура. Любая `'M_n.+1` имеет
    разложение Шура `A = U† T U` (T треугольна); диагональ `Tᵢᵢ` - корни
    характеристического многочлена `(det((Tᵢᵢ)E − A) = 0)`, откуда по гипотезе
    `|Tᵢᵢ| < 1`. Двойственно к `spec_rad_lt1_det_eig`.
  *)
  Lemma spec_rad_lt1_of_dets n (A : 'M[ℂ]_n.+1) :
    (forall lam : ℂ, \det (lam%:M - A) == 0 -> `|lam| < 1) -> spec_rad_lt1 A.
  Proof.
    move=> Hroots.
    have [U Uunit Atrig] := Schur A isT.
    have HTeq : conjmx U A = U *m A *m U^t* := conjymx A Uunit.
    set T := conjmx U A.
    have Atrig' : is_trig_mx T := Atrig.
    have hUCU : U^t* *m U = 1%:M.
      rewrite -invmx_unitary //.
      by apply: mulVmx; exact: unitarymx_unit.
    have hdetU : \det U * \det (U^t*) = 1.
      by rewrite -det_mulmx -invmx_unitary // mulmxV ?det1 // unitarymx_unit.
    have HAdec : A = U^t* *m T *m U.
      rewrite /T HTeq.
      have ->: U^t* *m (U *m A *m U^t*) *m U
            = U^t* *m U *m A *m U^t* *m U by rewrite !mulmxA.
      by rewrite hUCU mul1mx -mulmxA hUCU mulmx1.
    clearbody T.
    exists U, T; split=> //.
    move=> i.
    apply: Hroots.
    have detEq : \det ((T i i)%:M - A) = \det ((T i i)%:M - T).
      have conj_id : U^t* *m ((T i i)%:M - T) *m U = (T i i)%:M - A.
        rewrite mulmxBr mulmxBl HAdec; congr (_ - _).
        by rewrite mul_mx_scalar -scalemxAl hUCU scalemx1.
      rewrite -conj_id !det_mulmx -mulrA [\det ((T i i)%:M - T) * \det U]mulrC mulrA.
      by rewrite [\det (U^t*) * \det U]mulrC hdetU mul1r.
    rewrite detEq.
    have htrig : is_trig_mx ((T i i)%:M - T : 'M[ℂ]_n.+1).
      apply/is_trig_mxP=> a b ltab.
      have ab : (a == b) = false by apply: ltn_eqF.
      have Tz : T a b = 0 by apply: (elimT is_trig_mxP Atrig').
      by rewrite !mxE ab /= Tz subr0.
    rewrite (det_trig htrig).
    apply/prodf_eq0; exists i => //.
    by rewrite !mxE eqxx mulr1n subrr.
  Qed.

  (* Эрмитово сопряжение сохраняет устойчивость по Шуру. *)
  Lemma spec_rad_lt1_trmxC n (A : 'M[ℂ]_n.+1) :
    spec_rad_lt1 A -> spec_rad_lt1 (A^t*).
  (*
    Через детерминант: корни характеристического многочлена `A†` суть сопряжения
    корней `A` (λ⋅E − A† = (λ*⋅E − A)†, а det эрмитовой = сопряжению det), а
    модуль при сопряжении не меняется.
  *)
  Proof.
    move=> Hsr; apply: spec_rad_lt1_of_dets => lam.
    have key : lam%:M - A^t* = (lam^*%:M - A)^t*.
      rewrite trmxCB; congr (_ - _).
      by rewrite -[lam^*%:M]scalemx1 trmxC_scale trmxC1 conjCK scalemx1.
    rewrite key det_map_mx det_tr conjC_eq0 => Hdet.
    have := spec_rad_lt1_det_eig Hsr Hdet.
    by rewrite norm_conjC.
  Qed.

End SpecRad.

(*
  ==============================================================================
  Степени матрицы при устойчивости по Шуру
  ==============================================================================
  Алгебраическая часть пути к сходимости A^k -> 0 при spec_rad_lt1 A:
  субмультипликативность Фробениуса, оценка степени, выражение A^k через
  унитарное сопряжение T^k. Конкретное предельное утверждение `A^k @ ∞ --> 0`
  требует архимедова замыкания (для доказательства `r^k -> 0` при `0 <= r < 1`).
*)
Section SchurPow.

  Variable (ℂ : numClosedFieldType).

  (*
    Субмультипликативность Фробениусова квадрата:
    `frob_sq (A ⋅ B) <= frob_sq A * frob_sq B`.
  *)
  Lemma frob_sq_mulmx_le n m p
      (A : 'M[ℂ]_(n, m)) (B : 'M[ℂ]_(m, p)) :
    frob_sq (A *m B) <= frob_sq A * frob_sq B.
  (*
    Схема: `tr((AB)† AB) = tr(B† (A† A) B)`; `tr_conj_frob_le` с `Fm := B†`,
    `M := A† A` (неотрицательно определённая по psd_frob) даёт
    `tr(B† (A† A) (B†)†) <= frob_sq B† * tr(A† A)`. `(B†)† = B` (trmxCK) и
    `frob_sq B† = frob_sq B` (frob_sq_trmxC), `tr(A† A) = frob_sq A`
    (по определению).
  *)
  Proof.
    rewrite /frob_sq trmxC_mul.
    have step : B^t* *m A^t* *m (A *m B) = B^t* *m (A^t* *m A) *m B
      by rewrite !mulmxA.
    rewrite step.
    have H := tr_conj_frob_le (B^t*) (psd_frob A).
    rewrite trmxCK frob_sq_trmxC in H.
    by apply: (le_trans H); rewrite mulrC.
  Qed.

  (*
    Оценка нормы Фробениуса степени:
    ```
    frob_sq A^(k+1) <= (frob_sq A)^(k+1)
    ```
  *)
  Lemma frob_sq_exp_le n (A : 'M[ℂ]_n.+1) k :
    frob_sq (A ^+ k.+1) <= (frob_sq A) ^+ k.+1.
  (*
    Индукция по k через субмультипликативность. Граничный случай `k = 0`
    отсутствует, для `k = 0`: `A^0 = 1`, `frob_sq 1 = n.+1` в общем случае,
    тогда как `(frob_sq A)^0 = 1`.
  *)
  Proof.
    elim: k => [|k IHk]; first by rewrite !expr1.
    have rew_pow : A ^+ k.+2 = A *m A ^+ k.+1 by rewrite exprS mulmxE.
    rewrite rew_pow.
    have step1 : frob_sq (A *m A ^+ k.+1) <= frob_sq A * frob_sq (A ^+ k.+1)
      := frob_sq_mulmx_le A (A ^+ k.+1).
    apply: (le_trans step1).
    rewrite [in X in _ <= X]exprS.
    by rewrite ler_wpM2l ?frob_sq_ge0 // IHk.
  Qed.

  (*
    Унитарное сопряжение коммутирует со степенями: при унитарной `U` и
    `A = U† T U` выполнено `A^k = U† T^k U`.
  *)
  Lemma schur_exp_conj n (U A T : 'M[ℂ]_n) (k : nat) :
    U \is unitarymx -> A = U^t* *m T *m U ->
    A ^+ k = U^t* *m T ^+ k *m U.
  (*
    Доказательство: индукция по `k`; шаг использует `U⋅U† = E` для сокращения
    среднего множителя `U⋅U†` в произведении.
  *)
  Proof.
    move=> hU hA.
    have hUU : U *m U^t* = 1%:M by apply/unitarymxP.
    elim: k => [|k IHk].
      rewrite !expr0 mulmx1.
      by rewrite -invmx_unitary // mulVmx //; exact: unitarymx_unit.
    rewrite exprS IHk [in LHS]hA -mulmxE.
    rewrite exprS -mulmxE.
    have step : U^t* *m T *m U *m (U^t* *m T ^+ k *m U)
              = U^t* *m T *m (U *m U^t*) *m T ^+ k *m U
      by rewrite !mulmxA.
    by rewrite step hUU mulmx1 !mulmxA.
  Qed.

End SchurPow.

(*
  ==============================================================================
  Сходимость степеней при Фробениусовом сжатии
  ==============================================================================
  Предельная ступень: A^k -> 0 при frob_sq A < 1. Объединяет алгебраические
  оценки frob_sq_exp_le с архимедовым затуханием r^k -> 0 (mxtopo.r_pow_cvgn0)
  через squeeze и мост Фробениуса frob_sq_cvgn0_to_mxcvgn. Архимедовость - явная
  гипотеза (см. mxtopo: над numClosedFieldType cvg_expr неприменима).
*)
Section SchurPowCvg.

  Variable (ℂ : numClosedFieldType).

  Hypothesis ℂ_archi : Num.archimedean_axiom ℂ.

  (*
    Сходимость Фробениусова квадрата степени: frob_sq (A^(k+1)) -> 0. Squeeze: 0
    <= frob_sq (A^(k+1)) <= (frob_sq A)^(k+1) (frob_sq_exp_le), и
    (frob_sq A)^(k+1) -> 0 (r_pow_cvgn0, т.к. 0 <= frob_sq A < 1).
  *)
  Lemma frob_sq_pow_cvgn0 n (A : 'M[ℂ]_n.+1) :
    frob_sq A < 1 ->
    (fun k => frob_sq (A ^+ k.+1)) @ \oo --> (0 : ℂ).
  Proof.
    move=> Ac.
    apply: (cvgC_le0_squeeze (t := fun k => (frob_sq A) ^+ k.+1)).
    - by move=> k; exact: frob_sq_ge0.
    - by move=> k; exact: frob_sq_exp_le.
    - apply: r_pow_cvgn0 => //; exact: frob_sq_ge0.
  Qed.

  (*
    Поэлементная сходимость степеней: `A^(k+1) -> 0` при `frob_sq A < 1`. Мост
    `frob_sq_cvgn0_to_mxcvgn` с пределом L = 0: достаточно `frob_sq` разности
    `-> 0`, а `frob_sq (A^(k+1) - 0) = frob_sq (A^(k+1))`.
  *)
  Lemma mx_pow_cvgn0_frob_lt1 n (A : 'M[ℂ]_n.+1) :
    frob_sq A < 1 ->
    (fun k => A ^+ k.+1) @ \oo --> (0 : 'M[ℂ]_n.+1).
  Proof.
    move=> Ac.
    apply: frob_sq_cvgn0_to_mxcvgn.
    under eq_cvg=> k do rewrite subr0.
    exact: frob_sq_pow_cvgn0.
  Qed.

  (*
    Связка двух нитей пути ([kailath2000], App. E): сжатие по норме Фробениуса
    даёт одновременно устойчивость по Шуру (spec_rad_lt1) и сходимость степеней
    к нулю.
  *)
  Corollary pow_cvgn0_spec_rad_via_frob n (A : 'M[ℂ]_n.+1) :
    frob_sq A < 1 ->
    spec_rad_lt1 A /\ (fun k => A ^+ k.+1) @ \oo --> (0 : 'M[ℂ]_n.+1).
  Proof.
    move=> Ac; split.
    - exact: frob_sq_contract_spec_rad_lt1.
    - exact: mx_pow_cvgn0_frob_lt1.
  Qed.

End SchurPowCvg.

(*
  ==================================================================
  spec_rad_lt1 A -> A^k -> 0
  ================================================================== Сходимость
  степеней устойчивой по Шуру матрицы к нулю.

  Схема ([kailath2000], App. E, шаг 2): через разложение Шура для A = U† T U
  сводим к T (треугольной). Для верхнетреугольной формы
  (транспонируем `is_trig_mx`) ведём индукцию по размеру, выделяя первый индекс
  блоком 1+n. Диагональ T^k и нижний правый блок сходятся к нулю по
  предположению индукции, а наддиагональный блок `ursubmx (T^k)` подчиняется
  скалярной ISS-рекурсии `S(k+1) = a S k + r T'^k` (поэлементно), которую
  замыкает `lin_filter_cvgn0` (lyapunov.v). Архимедовость нужна только для
  геометрического затухания `r^k -> 0`.

  Степени верхнетреугольного блока block_mx a r 0 T': T^k = block_mx (a^k) (S k)
  0 (T'^k), где наддиагональный блок S = ursubmx подчиняется рекурсии S(k+1) = a
  S k + r T'^k.
*)
Section BlockPowUpper.

  Variable (ℂ : numClosedFieldType) (n' : nat).

  Variables (a : 'M[ℂ]_1) (r : 'M[ℂ]_(1, n')) (T' : 'M[ℂ]_n').

  Let T : 'M[ℂ]_(1 + n') := block_mx a r 0 T'.

  Lemma block_pow_parts k :
    [/\ ulsubmx (T ^+ k) = a ^+ k,
        dlsubmx (T ^+ k) = (0 : 'M[ℂ]_(n', 1)) &
        drsubmx (T ^+ k) = T' ^+ k].
  Proof.
    elim: k => [|k [IHul IHdl IHdr]].
      rewrite !expr0 -!idmxE; split.
      - by rewrite {1}scalar_mx_block block_mxKul.
      - by rewrite {1}scalar_mx_block block_mxKdl.
      - by rewrite {1}scalar_mx_block block_mxKdr.
    have decomp : T ^+ k = block_mx (a ^+ k) (ursubmx (T ^+ k)) 0 (T' ^+ k).
      by rewrite -[in LHS](submxK (T ^+ k)) IHul IHdl IHdr.
    have expand : T ^+ k.+1
        = block_mx (a ^+ k.+1) (a *m ursubmx (T ^+ k) + r *m T' ^+ k) 0 (T' ^+ k.+1).
      rewrite exprS -mulmxE {1}/T {1}decomp mulmx_block !mulmx0 !mul0mx !addr0 !add0r.
      by congr block_mx; rewrite exprS mulmxE.
    by split; rewrite expand ?block_mxKul ?block_mxKdl ?block_mxKdr.
  Qed.

  Lemma block_pow_eq k :
    T ^+ k = block_mx (a ^+ k) (ursubmx (T ^+ k)) 0 (T' ^+ k).
  Proof.
    have [u d c] := block_pow_parts k.
    by rewrite -[in LHS](submxK (T ^+ k)) u d c.
  Qed.

  Lemma block_ur_rec k :
    ursubmx (T ^+ k.+1) = a *m ursubmx (T ^+ k) + r *m T' ^+ k.
  Proof.
    by rewrite {1}exprS -mulmxE {1}/T {1}[T ^+ k]block_pow_eq mulmx_block block_mxKur.
  Qed.

End BlockPowUpper.

(* Поэлементная (блочная) сходимость матриц и непрерывность транспонирования. *)
Section BlockCvg.

  Variable (ℂ : numClosedFieldType).

  Lemma cvgn_row_mx m n1 n2 (Af : nat -> 'M[ℂ]_(m, n1))
      (Bf : nat -> 'M[ℂ]_(m, n2)) (LA : 'M[ℂ]_(m, n1)) (LB : 'M[ℂ]_(m, n2)) :
    Af @ \oo --> LA -> Bf @ \oo --> LB ->
    (fun k => row_mx (Af k) (Bf k)) @ \oo --> row_mx LA LB.
  Proof.
    move=> HA HB; apply/mxcvgn_to_cvgn => i j.
    have HAe := cvgn_to_mxcvgn HA; have HBe := cvgn_to_mxcvgn HB.
    case: (split_ordP j) => j' ->.
      under eq_cvg => k do rewrite row_mxEl.
      rewrite row_mxEl; exact: (HAe i j').
    under eq_cvg => k do rewrite row_mxEr.
    rewrite row_mxEr; exact: (HBe i j').
  Qed.

  Lemma cvgn_col_mx m1 m2 n (Af : nat -> 'M[ℂ]_(m1, n))
      (Bf : nat -> 'M[ℂ]_(m2, n)) (LA : 'M[ℂ]_(m1, n)) (LB : 'M[ℂ]_(m2, n)) :
    Af @ \oo --> LA -> Bf @ \oo --> LB ->
    (fun k => col_mx (Af k) (Bf k)) @ \oo --> col_mx LA LB.
  Proof.
    move=> HA HB; apply/mxcvgn_to_cvgn => i j.
    have HAe := cvgn_to_mxcvgn HA; have HBe := cvgn_to_mxcvgn HB.
    case: (split_ordP i) => i' ->.
      under eq_cvg => k do rewrite col_mxEu.
      rewrite col_mxEu; exact: (HAe i' j).
    under eq_cvg => k do rewrite col_mxEd.
    rewrite col_mxEd; exact: (HBe i' j).
  Qed.

  Lemma cvgn_block_mx m1 m2 n1 n2
      (Aul : nat -> 'M[ℂ]_(m1, n1)) (Aur : nat -> 'M[ℂ]_(m1, n2))
      (Adl : nat -> 'M[ℂ]_(m2, n1)) (Adr : nat -> 'M[ℂ]_(m2, n2))
      (Lul : 'M[ℂ]_(m1, n1)) (Lur : 'M[ℂ]_(m1, n2))
      (Ldl : 'M[ℂ]_(m2, n1)) (Ldr : 'M[ℂ]_(m2, n2)) :
    Aul @ \oo --> Lul -> Aur @ \oo --> Lur ->
    Adl @ \oo --> Ldl -> Adr @ \oo --> Ldr ->
    (fun k => block_mx (Aul k) (Aur k) (Adl k) (Adr k)) @ \oo -->
      block_mx Lul Lur Ldl Ldr.
  Proof.
    by move=> H1 H2 H3 H4; apply: cvgn_col_mx; apply: cvgn_row_mx.
  Qed.

  Lemma cvgn_trmx r c (M : nat -> 'M[ℂ]_(r, c)) (L : 'M[ℂ]_(r, c)) :
    M @ \oo --> L -> (fun k => (M k)^T) @ \oo --> L^T.
  Proof.
    move=> HM; apply/mxcvgn_to_cvgn => i j.
    have HMe : (fun k => M k j i) @ \oo --> L j i by exact: cvgn_to_mxcvgn HM j i.
    under eq_cvg => k do rewrite mxE.
    by rewrite mxE; exact: HMe.
  Qed.

  Lemma trmxX m (M : 'M[ℂ]_m) k : (M ^+ k)^T = (M^T) ^+ k.
  Proof.
    elim: k => [|k IH]; first by rewrite !expr0 trmx1.
    by rewrite exprS -mulmxE trmx_mul IH mulmxE -exprSr.
  Qed.

End BlockCvg.

Section SchurStablePowCvg.

  Variable (ℂ : numClosedFieldType).

  Hypothesis ℂ_archi : Num.archimedean_axiom ℂ.

  (* Норма стремится к нулю => последовательность стремится к нулю. *)
  Lemma cvgC_norm0 (f : nat -> ℂ) :
    (fun k => `|f k|) @ \oo --> (0 : ℂ) -> f @ \oo --> (0 : ℂ).
  Proof.
    move=> hn.
    suff HO : (f : nat -> ℂ^o) @ \oo --> (0 : ℂ^o) by exact: HO.
    apply/cvgrPdistC_lt => eps eps_pos.
    have hn_o : ((fun k => `|f k|) : nat -> ℂ^o) @ \oo --> (0 : ℂ^o) by exact: hn.
    have /cvgrPdistC_lt /(_ _ eps_pos) hnear := hn_o.
    near=> k.
    have hk : `|(`|f k|) - 0| < eps by near: k; exact: hnear.
    rewrite subr0 normr_id in hk.
    by rewrite /= subr0.
    Unshelve.
    all: by end_near.
  Qed.

  (* Бесконечно убывающая геометрическая прогрессия: |z| < 1 => z^k -> 0. *)
  Lemma cpow_cvgn0 (z : ℂ) :
    `|z| < 1 -> (fun k => z ^+ k) @ \oo --> (0 : ℂ).
  Proof.
    move=> z1; apply: cvgC_norm0.
    have -> : (fun k => `|z ^+ k|) = (fun k => `|z| ^+ k).
      by apply/funext => k; rewrite normrX.
    by rewrite -(cvg_shiftS (fun j => `|z| ^+ j)); apply: r_pow_cvgn0 => //.
  Qed.

  (* База индукции: 1×1 матрица. *)
  Lemma trig1_pow_cvgn0 (M : 'M[ℂ]_1) :
    `|M ord0 ord0| < 1 -> (fun k => M ^+ k) @ \oo --> (0 : 'M[ℂ]_1).
  Proof.
    move=> Md; apply: mxcvgn_to_cvgn => i j.
    rewrite [i]ord1 [j]ord1 mxE.
    have pow11 : forall k, (M ^+ k) ord0 ord0 = (M ord0 ord0) ^+ k.
      by elim=> [|k IH];
        [rewrite expr0 mxE eqxx | rewrite exprS -mulmxE mxE big_ord1 IH -exprS].
    under eq_cvg => k do rewrite pow11.
    exact: cpow_cvgn0.
  Qed.

  (*
    Сходимость степеней верхнетреугольной матрицы к нулю
    (индукция по размеру, выделение первой строки и столбца). Условие -
    `is_trig_mx (T^T)` (верхнетреугольность) + вся диагональ строго в единичном
    диске.
  *)
  Lemma utrig_pow_cvgn0 n (T : 'M[ℂ]_(1 + n)) :
    is_trig_mx (T^T) -> (forall i, `|T i i| < 1) ->
    (fun k => T ^+ k) @ \oo --> (0 : 'M[ℂ]_(1 + n)).
  Proof.
    elim: n T => [|n IH] T Tutri Tdiag.
      exact: trig1_pow_cvgn0 (Tdiag ord0).
    set a := ulsubmx T.
    set r := ursubmx T.
    set Tdr := drsubmx T.
    have dl0 : dlsubmx T = 0.
      apply: trmx_inj; rewrite trmx_dlsub trmx0.
      exact: ursubmx_trig (leqnn _) Tutri.
    have Tblock : T = block_mx a r 0 Tdr by rewrite /a /r /Tdr -dl0 submxK.
    have Tdr_utri : is_trig_mx (Tdr^T).
      have HT : is_trig_mx (T^T) := Tutri.
      move: HT; rewrite -{1}[T^T]submxK is_trig_block_mx // => /and3P[_ _ HT].
      by rewrite /Tdr trmx_drsub.
    have Tdr_diag : forall i, `|Tdr i i| < 1.
      by move=> i; rewrite /Tdr !mxE; exact: Tdiag.
    have a_diag : `|a ord0 ord0| < 1 by rewrite /a !mxE; exact: Tdiag.
    have hT' := IH Tdr Tdr_utri Tdr_diag.
    have ha := trig1_pow_cvgn0 a_diag.
    have hcr : (fun _ : nat => r) @ \oo --> r by exact: cvg_cst.
    have hS : (fun k => ursubmx ((block_mx a r 0 Tdr) ^+ k))
                @ \oo --> (0 : 'M[ℂ]_(1, n.+1)).
      apply/mxcvgn_to_cvgn => i j; rewrite [i]ord1 mxE.
      have ucvg : (fun k => (r *m Tdr ^+ k) ord0 j) @ \oo --> (0 : ℂ).
        have HX : (fun k => r *m Tdr ^+ k) @ \oo --> (0 : 'M[ℂ]_(1, n.+1)).
          have HX0 := cvgn_mulmx hcr hT'.
          by rewrite mulmx0 in HX0.
        have HXe := cvgn_to_mxcvgn HX.
        have HU := HXe ord0 j.
        by rewrite mxE in HU.
      apply: (@lin_filter_cvgn0 _ ℂ_archi `|a ord0 ord0|
                (fun k => (r *m Tdr ^+ k) ord0 j)
                (fun k => ursubmx ((block_mx a r 0 Tdr) ^+ k) ord0 j)).
      - exact: normr_ge0.
      - exact: a_diag.
      - move=> k; rewrite block_ur_rec mxE [(a *m _) ord0 j]mxE big_ord1.
        apply: (le_trans (ler_normD _ _)).
        by rewrite normrM.
      - exact: ucvg.
    rewrite Tblock.
    have e : (fun k => (block_mx a r 0 Tdr) ^+ k)
          = (fun k => block_mx (a ^+ k)
                        (ursubmx ((block_mx a r 0 Tdr) ^+ k)) 0 (Tdr ^+ k)).
      by apply/funext => k; exact: block_pow_eq.
    rewrite e.
    have hc0 : (fun _ : nat => (0 : 'M[ℂ]_(n.+1, 1)))
                @ \oo --> (0 : 'M[ℂ]_(n.+1, 1)) by exact: cvg_cst.
    have HB := cvgn_block_mx ha hS hc0 hT'.
    by rewrite block_mx0 in HB.
  Qed.

  (*
    Устойчивость по Шуру => сходимость степеней. Через разложение Шура A = U† T
    U; T - нижнетреугольная (is_trig_mx); транспонируем к верхнетреугольной и
    применяем `utrig_pow_cvgn0`.

    ([kailath2000], App. D, Lemma D.3.1)
  *)
  Theorem schur_stable_pow_cvgn n (A : 'M[ℂ]_n.+1) :
    spec_rad_lt1 A -> (fun k => A ^+ k) @ \oo --> (0 : 'M[ℂ]_n.+1).
  Proof.
    move=> [U [T [Uunit Adec Ttrig Tdiag]]].
    have hT : (fun k => T ^+ k) @ \oo --> (0 : 'M[ℂ]_n.+1).
      have hS : (fun k => (T^T) ^+ k) @ \oo --> (0 : 'M[ℂ]_n.+1).
        apply: utrig_pow_cvgn0; first by rewrite trmxK.
        by move=> i; rewrite mxE; exact: Tdiag.
      have e : (fun k => T ^+ k) = (fun k => ((T^T) ^+ k)^T).
        by apply/funext => k; rewrite -trmxX trmxK.
      rewrite e.
      have := cvgn_trmx hS; by rewrite trmx0.
    have e2 : (fun k => A ^+ k) = (fun k => U^t* *m T ^+ k *m U).
      by apply/funext => k; exact: schur_exp_conj Uunit Adec.
    rewrite e2.
    have hcUt : (fun _ : nat => U^t*) @ \oo --> U^t* by exact: cvg_cst.
    have hcU : (fun _ : nat => U) @ \oo --> U by exact: cvg_cst.
    have H := cvgn_mulmx (cvgn_mulmx hcUt hT) hcU.
    by rewrite mulmx0 mul0mx in H.
  Qed.

  (*
    ==============================================================================
    Единственность решений уравнения Ляпунова при устойчивости по Шуру
    (двойственно суммируемости грамиана `lyap_partial_le_bnd_schur`).
    ==============================================================================

    Однородное замкнуто-контурное тождество, итерированное по степеням: D = A D
    B† => D = A^k D (B^k)† для всех k.
  *)
  Lemma lyap_hom_pow n (A B D : 'M[ℂ]_n) :
    D = A *m D *m B^t* -> forall k, D = A^+k *m D *m (B^+k)^t*.
  Proof.
    move=> Deq; elim=> [|k IH]; first by rewrite !expr0 trmxC1 mul1mx mulmx1.
    rewrite exprS exprS trmxC_mul.
    have ->: A *m A^+k *m D *m ((B^+k)^t* *m B^t*)
          = A *m (A^+k *m D *m (B^+k)^t*) *m B^t* by rewrite !mulmxA.
    by rewrite -IH; exact: Deq.
  Qed.

  (*
    Двусторонняя единственность: при устойчивости по Шуру обеих матриц
    однородное уравнение `D = A D B†` имеет лишь нулевое решение.
    Доказательство: `D = A^k D (B^k)†` (lyap_hom_pow), а правая часть -> 0
    (степени устойчивых по Шуру матриц затухают, `schur_stable_pow_cvgn`).
    Постоянная последовательность `D` сходится к `0`, откуда `D = 0` (Хаусдорф).

    ([kailath2000], App. D, Lemma D.1.1)
  *)
  Lemma lyap_two_sided_zero_schur n (A B D : 'M[ℂ]_n.+1) :
    spec_rad_lt1 A -> spec_rad_lt1 B ->
    D = A *m D *m B^t* -> D = 0.
  Proof.
    move=> HA HB Deq.
    have powereq := lyap_hom_pow Deq.
    have HAk : (fun k => A^+k) @ \oo --> (0 : 'M[ℂ]_n.+1)
      := schur_stable_pow_cvgn HA.
    have HBk : (fun k => B^+k) @ \oo --> (0 : 'M[ℂ]_n.+1)
      := schur_stable_pow_cvgn HB.
    have HBkt : (fun k => (B^+k)^t*) @ \oo --> (0 : 'M[ℂ]_n.+1).
      have h := cvgn_trmxC HBk; by rewrite trmxC0 in h.
    have HDcst : (fun _ : nat => D) @ \oo --> D by exact: cvg_cst.
    have Hprod : (fun k => A^+k *m D *m (B^+k)^t*) @ \oo --> (0 : 'M[ℂ]_n.+1).
      have h := cvgn_mulmx (cvgn_mulmx HAk HDcst) HBkt.
      by rewrite mulmx0 in h.
    have Hconst : (fun k => A^+k *m D *m (B^+k)^t*) = (fun _ : nat => D).
      by apply/funext=> k; rewrite -powereq.
    rewrite Hconst in Hprod.
    have Haus : hausdorff_space ('M[ℂ]_n.+1 : pseudoMetricNormedZmodType ℂ).
      exact: norm_hausdorff.
    have Hprod_n :
      ((fun _ : nat => D) : nat -> ('M[ℂ]_n.+1 : pseudoMetricNormedZmodType ℂ))
        @ \oo --> (0 : ('M[ℂ]_n.+1 : pseudoMetricNormedZmodType ℂ)) := Hprod.
    have HDD_n :
      ((fun _ : nat => D) : nat -> ('M[ℂ]_n.+1 : pseudoMetricNormedZmodType ℂ))
        @ \oo --> (D : ('M[ℂ]_n.+1 : pseudoMetricNormedZmodType ℂ)) := HDcst.
    by have := cvg_unique Haus HDD_n Hprod_n => ->.
  Qed.

  (*
    Единственность эрмитова решения уравнения Ляпунова `X = A X A† + Q` при
    устойчивости по Шуру `spec_rad_lt1 A`
    (двойственно Фробениусовой `lyap_fix_unique`, но при спектральной устойчивости по Шуру).

    ([kailath2000], App. D, Lemma D.1.1)
  *)
  Lemma lyap_fix_unique_schur n (A Q X1 X2 : 'M[ℂ]_n.+1) :
    spec_rad_lt1 A ->
    X1 = A *m X1 *m A^t* + Q -> X2 = A *m X2 *m A^t* + Q -> X1 = X2.
  Proof.
    move=> HA eq1 eq2.
    have Deq : X1 - X2 = A *m (X1 - X2) *m A^t*.
      rewrite mulmxBr mulmxBl.
      have e1 : X1 - Q = A *m X1 *m A^t* by rewrite {1}eq1 addrK.
      have e2 : X2 - Q = A *m X2 *m A^t* by rewrite {1}eq2 addrK.
      by rewrite -e1 -e2 opprB addrA subrK.
    have := lyap_two_sided_zero_schur HA HA Deq.
    by move/eqP; rewrite subr_eq0 => /eqP.
  Qed.

End SchurStablePowCvg.

(*
  Решение уравнения Ляпунова при устойчивости по Шуру.

  Через блочную декомпозицию: из `A^k -> 0` (schur_stable_pow_cvgn) есть `N0` с
  `frob_sq (A^N0) < 1`, и lyap_partial A Q (N0 k) = lyap_partial (A^N0)
  (lyap_partial A Q N0) k (lyap_partial_block) сводит равномерную оценку к уже
  доказанной Фробениусовой `lyap_partial_le_bnd` на `B = A^N0`.
*)
Section SchurLyapunov.

  Variables (ℝ : realType) (ℂ : numClosedFieldType).
  Variable r2c : {rmorphism ℝ -> ℂ}.
  Variable c2r : ℂ -> ℝ.
  Hypothesis ler_r2c : {mono r2c : x y / x <= y}.
  Hypothesis c2rK : {in Num.real, cancel c2r r2c}.
  Hypothesis c2r_continuous : continuous (c2r : ℂ -> ℝ).
  Hypothesis r2c_continuous : continuous (r2c : ℝ -> ℂ).
  Hypothesis ℂ_archi : Num.archimedean_axiom ℂ.

  (*
    Из устойчивости по Шуру степень < 1 по норме Фробениуса (через A^k -> 0).
  *)
  Lemma exists_frob_pow_lt1 n (A : 'M[ℂ]_n.+1) :
    spec_rad_lt1 A -> exists N, frob_sq (A^+N.+1) < 1.
  Proof.
    move=> Hsr.
    have Hcvg : (fun k => A^+k) @ \oo --> (0 : 'M[ℂ]_n.+1)
      := schur_stable_pow_cvgn ℂ_archi Hsr.
    have Htr0 : (fun k => (A^+k)^t*) @ \oo --> (0 : 'M[ℂ]_n.+1).
      have := cvgn_trmxC Hcvg; by rewrite trmxC0.
    have Hmul0 : (fun k => (A^+k)^t* *m A^+k) @ \oo --> (0 : 'M[ℂ]_n.+1).
      have := cvgn_mulmx Htr0 Hcvg; by rewrite mulmx0.
    have Htr : (fun k => \tr ((A^+k)^t* *m A^+k)) @ \oo --> (0 : ℂ).
      have := cvgn_mxtrace Hmul0; by rewrite mxtrace0.
    have Htr_o :
        ((fun k => \tr ((A^+k)^t* *m A^+k)) : nat -> ℂ^o) @ \oo --> (0 : ℂ^o)
      := Htr.
    have /cvgrPdistC_lt /(_ 1 ltr01) Hnear := Htr_o.
    case: Hnear => N _ HN.
    exists N.
    have := HN N.+1 (leqnSn N); rewrite /= subr0 => Hnorm.
    have Hpos : 0 <= \tr ((A^+N.+1)^t* *m A^+N.+1) := frob_sq_ge0 (A^+N.+1).
    by rewrite /frob_sq -(ger0_norm Hpos).
  Qed.

  (*
    Равномерная неотрицательно определённая мажоранта частичных сумм Ляпунова
    при устойчивости по Шуру.
  *)
  Lemma lyap_partial_le_bnd_schur n (A Q : 'M[ℂ]_n.+1) :
    psd Q -> spec_rad_lt1 A ->
    exists Bnd : 'M[ℂ]_n.+1, forall k, psd_le (lyap_partial A Q k) Bnd.
  Proof.
    move=> psdQ Hsr.
    have [N HN] := exists_frob_pow_lt1 Hsr.
    exists (lyap_bnd (A^+N.+1) (lyap_partial A Q N.+1)) => k.
    apply: (psd_le_trans (B := lyap_partial A Q (N.+1 * k))).
    - by apply: (lyap_partial_le_mono A psdQ); rewrite leq_pmull.
    - rewrite lyap_partial_block.
      apply: lyap_partial_le_bnd; last exact: HN.
      apply: lyap_partial_psd; exact: psdQ.
  Qed.

  Section SchurLyapunovSolution.

    Variable (n : nat).
    Variables (A Q : 'M[ℂ]_n.+1).
    Hypothesis Q_psd : psd Q.
    Hypothesis A_schur : spec_rad_lt1 A.

    (* Сходимость частичных сумм к lyap_sol при устойчивости по Шуру. *)
    Theorem lyap_sol_cvgn_schur : lyap_partial A Q @ \oo --> lyap_sol A Q.
    Proof.
      have [Bnd HBnd] := lyap_partial_le_bnd_schur Q_psd A_schur.
      exact: (mx_mono_cvgn ler_r2c c2rK r2c_continuous
                (S := lyap_partial A Q) (B := Bnd)
                (fun k => lyap_partial_psd A Q_psd k)
                (fun k => lyap_partial_mono A Q_psd k) HBnd).
    Qed.

    Theorem lyap_sol_psd_schur : psd (lyap_sol A Q).
    Proof.
      have [Bnd HBnd] := lyap_partial_le_bnd_schur Q_psd A_schur.
      exact: (mx_mono_lim_psd ler_r2c c2rK c2r_continuous r2c_continuous
                (S := lyap_partial A Q) (B := Bnd)
                (fun k => lyap_partial_psd A Q_psd k)
                (fun k => lyap_partial_mono A Q_psd k) HBnd).
    Qed.

    (*
      Каждая частичная сумма <= предела (`lyap_sol`) в порядке Лёвнера: член
      монотонно возрастающей ограниченной последовательности мажорируется её
      супремумом (`mx_mono_lim_ge_term`). Нужна, в частности, для оценки
      оптимальности ([kailath2000], § 14.2, факт (b)): `P°_i <= Π` через
      конечный Грамиан замкнутого контура.

      ([kailath2000], § 14.2)
    *)
    Theorem lyap_partial_le_sol_schur k :
      psd_le (lyap_partial A Q k) (lyap_sol A Q).
    Proof.
      rewrite /lyap_sol.
      have [Bnd HBnd] := lyap_partial_le_bnd_schur Q_psd A_schur.
      exact: (mx_mono_lim_ge_term ler_r2c c2rK c2r_continuous r2c_continuous
                (S := lyap_partial A Q) (B := Bnd)
                (fun j => lyap_partial_psd A Q_psd j)
                (fun j => lyap_partial_mono A Q_psd j) HBnd k).
    Qed.

    (*
      Неподвижная точка: lyap_sol = (A (lyap_sol) A†) + Q.

      ([kailath2000], App. D, Lemma D.1.2)
    *)
    Theorem lyap_sol_fix_schur :
      lyap_sol A Q = A *m lyap_sol A Q *m A^t* + Q.
    Proof.
      have Hcvg := lyap_sol_cvgn_schur.
      have Hshift : (fun k => lyap_partial A Q k.+1) @ \oo --> lyap_sol A Q.
        have Hsh : addn 1 @ \oo --> (\oo : set_system nat) := cvg_addnl 1.
        have Hcomp : (lyap_partial A Q \o addn 1) @ \oo --> lyap_sol A Q
          := cvg_comp (addn 1) (lyap_partial A Q) Hsh Hcvg.
        have Heq : lyap_partial A Q \o addn 1 = (fun k => lyap_partial A Q k.+1)
          by apply/funext=> k; rewrite /= add1n.
        by rewrite -Heq.
      have eqf : (fun k => lyap_partial A Q k.+1)
              = (fun k => Q + A *m lyap_partial A Q k *m A^t*)
        by apply/funext=> k; exact: lyap_partial_shift.
      rewrite eqf in Hshift.
      have Hrhs : (fun k => Q + A *m lyap_partial A Q k *m A^t*) @ \oo -->
                  Q + A *m lyap_sol A Q *m A^t* := cvgn_lyap_step Hcvg.
      have HausM : hausdorff_space ('M[ℂ]_n.+1 : pseudoMetricNormedZmodType ℂ)
        by exact: norm_hausdorff.
      have Hshift_n : (fun k => Q + A *m lyap_partial A Q k *m A^t*)
          @ \oo --> (lyap_sol A Q : ('M[ℂ]_n.+1 : pseudoMetricNormedZmodType ℂ))
        by exact: Hshift.
      have Hrhs_n : (fun k => Q + A *m lyap_partial A Q k *m A^t*)
          @ \oo --> ((Q + A *m lyap_sol A Q *m A^t*)
                      : ('M[ℂ]_n.+1 : pseudoMetricNormedZmodType ℂ))
        by exact: Hrhs.
      have eqLim : lyap_sol A Q = Q + A *m lyap_sol A Q *m A^t*
        := cvg_unique HausM Hshift_n Hrhs_n.
      by rewrite [LHS]eqLim addrC.
    Qed.

  End SchurLyapunovSolution.

End SchurLyapunov.
