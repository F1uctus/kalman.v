
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra ssrint.
From mathcomp Require Import order rat.
From mathcomp.algebra Require Import sesquilinear spectral.
From CoqEAL Require Import hrel param refinements seqmx binint binrat.
From Bignums Require Import BigQ.
From Kalman Require Import mxnotation riccati_def faddeev.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory Num.Theory Num.Def.
Import Refinements.Op.
Local Open Scope ring_scope.
Local Open Scope sesquilinear_scope.

(*
  Операции коммутативного кольца с обратимыми как инстансы над CoqEAL. Это
  позволяет seqmx-программам исполняться на конкретном кольце (`rat`, `ℂ`). Для
  `bigQ` (не `comUnitRingType`) используются экземпляры из `CoqEAL.binrat`.
*)
#[local] Instance ring_zero (R : comUnitRingType) : zero_of R := 0%R.
#[local] Instance ring_one  (R : comUnitRingType) : one_of R  := 1%R.
#[local] Instance ring_opp  (R : comUnitRingType) : opp_of R  := -%R.
#[local] Instance ring_add  (R : comUnitRingType) : add_of R  := +%R.
#[local] Instance ring_mul  (R : comUnitRingType) : mul_of R  := *%R.
#[local] Instance ring_eq   (R : comUnitRingType) : eq_of R   := eqtype.eq_op.
#[local] Instance ring_inv  (R : comUnitRingType) : inv_of R  := GRing.inv.

(*
  Исполнимая программа над слоем операций CoqEAL.

  Программа параметризована типом `C` и операциями `zero_of`, ..., `eq_of`,
  поэтому один и тот же терм исполняется на любом `C` с такими операциями
  (`rat`, `bigQ`, ...).
*)
Section EffPrograms.

Context (C : Type).
Context `{!zero_of C, !one_of C, !opp_of C, !add_of C, !mul_of C, !eq_of C}.
Variable conj : C -> C.
Variables (m n p : nat).
Variables (sF sG sH sQ sRm : @seqmx C).
Variable cinv : @seqmx C -> @seqmx C.

  (* Эрмитово сопряжение: транспонируем и применяем `conj` поэлементно. *)
Definition ctr_seqmx (a b : nat) (A : @seqmx C) : @seqmx C :=
  map_seqmx conj (@trseqmx C a b A).

Definition predict_cov_seqmx (sP : @seqmx C) : @seqmx C :=
  add_seqmx
    (@hmul_op _ _ _ n n n (@hmul_op _ _ _ n n n sF sP) (ctr_seqmx n n sF))
    (@hmul_op _ _ _ n m n (@hmul_op _ _ _ n m m sG sQ) (ctr_seqmx n m sG)).

Definition innov_cov_seqmx (sP : @seqmx C) : @seqmx C :=
  add_seqmx
    (@hmul_op _ _ _ p n p (@hmul_op _ _ _ p n n sH sP) (ctr_seqmx p n sH))
    sRm.

  Definition filter_gain_seqmx (sP : @seqmx C) : @seqmx C :=
  @hmul_op _ _ _ n p p
    (@hmul_op _ _ _ n n p sP (ctr_seqmx p n sH))
    (cinv (innov_cov_seqmx sP)).

Definition update_cov_seqmx (sP : @seqmx C) : @seqmx C :=
    let K := filter_gain_seqmx sP in
  @hmul_op _ _ _ n n n
    (sub_seqmx (seqmx1 n) (@hmul_op _ _ _ n p n K sH)) sP.

  (*
    Альтернативный шаг обновления с заданным усилением `sKp` в форме Джозефа:
    $(E_n - K_p H) P (E_n - K_p H)† + K_p R K_p†$. Исполнимый аналог
    `alt_update_cov`.
  *)
Definition alt_update_cov_seqmx (sKp sP : @seqmx C) : @seqmx C :=
    let EmKH := sub_seqmx (seqmx1 n) (@hmul_op _ _ _ n p n sKp sH) in
  add_seqmx
      (@hmul_op _ _ _ n n n (@hmul_op _ _ _ n n n EmKH sP) (ctr_seqmx n n EmKH))
    (@hmul_op _ _ _ n p n (@hmul_op _ _ _ n p p sKp sRm) (ctr_seqmx n p sKp)).

  (*
    Исполнимый шаг Риккати.

    Композиция исполнимых полушагов предсказания и обновления; дословный аналог
    оператора `riccati_step` из `riccati_def.v`.
  *)
Definition riccati_step_seqmx (sP : @seqmx C) : @seqmx C :=
  update_cov_seqmx (predict_cov_seqmx sP).

End EffPrograms.

(* Корректность: подстановка C := R и уточнения. *)
Section RefineRiccati.

Variable R : comUnitRingType.

Existing Instance Rseqmx_add.
Existing Instance Rseqmx_opp.
Existing Instance Rseqmx_mul.
Existing Instance Rseqmx_1.
Existing Instance Rseqmx_trseqmx.
Existing Instance Rseqmx_map_seqmx.

Variable conj : R -> R.
#[local] Instance refines_conj :
  refines (@eq (R -> R)) conj conj := trivial_refines erefl.

#[export] Instance refines_ctr_seqmx (a b : nat) (A : 'M[R]_(a, b))
    (sA : @seqmx R)
    (rA : refines (Rseqmx (nat_Rxx a) (nat_Rxx b)) A sA) :
  refines (Rseqmx (nat_Rxx b) (nat_Rxx a)) (map_mx conj A^T)
    (ctr_seqmx conj a b sA).
Proof.
  rewrite /ctr_seqmx.
  exact: (refines_apply
            (refines_apply (Rseqmx_map_seqmx _ _) refines_conj)
            (refines_apply (Rseqmx_trseqmx _ _) rA)).
Qed.

Lemma refines_mulmx (a b c : nat) (X : 'M[R]_(a, b)) (Y : 'M[R]_(b, c))
    (sX sY : @seqmx R)
    (rX : refines (Rseqmx (nat_Rxx a) (nat_Rxx b)) X sX)
    (rY : refines (Rseqmx (nat_Rxx b) (nat_Rxx c)) Y sY) :
  refines (Rseqmx (nat_Rxx a) (nat_Rxx c)) (X *m Y)
    (@hmul_op _ _ _ a b c sX sY).
Proof. exact: refines_apply. Qed.

Lemma refines_addmx (a b : nat) (X Y : 'M[R]_(a, b)) (sX sY : @seqmx R)
    (rX : refines (Rseqmx (nat_Rxx a) (nat_Rxx b)) X sX)
    (rY : refines (Rseqmx (nat_Rxx a) (nat_Rxx b)) Y sY) :
  refines (Rseqmx (nat_Rxx a) (nat_Rxx b)) (X + Y) (add_seqmx sX sY).
Proof. exact: refines_apply. Qed.

Lemma refines_oppmx (a b : nat) (X : 'M[R]_(a, b)) (sX : @seqmx R)
    (rX : refines (Rseqmx (nat_Rxx a) (nat_Rxx b)) X sX) :
  refines (Rseqmx (nat_Rxx a) (nat_Rxx b)) (- X) (opp_seqmx sX).
Proof. exact: refines_apply. Qed.

Section System.

Variables (m n p : nat).
Variables (F : 'M[R]_n) (G : 'M[R]_(n, m)) (H : 'M[R]_(p, n)).
Variables (Q : 'M[R]_m) (Rm : 'M[R]_p).

Variables (sF sG sH sQ sRm : @seqmx R).
Hypothesis rF : refines (Rseqmx (nat_Rxx n) (nat_Rxx n)) F sF.
Hypothesis rG : refines (Rseqmx (nat_Rxx n) (nat_Rxx m)) G sG.
Hypothesis rH : refines (Rseqmx (nat_Rxx p) (nat_Rxx n)) H sH.
Hypothesis rQ : refines (Rseqmx (nat_Rxx m) (nat_Rxx m)) Q sQ.
Hypothesis rRm : refines (Rseqmx (nat_Rxx p) (nat_Rxx p)) Rm sRm.

    (* Обращение p*p-матрицы (см. заголовок файла). *)
Variable cinv : @seqmx R -> @seqmx R.

Hypothesis cinv_correct : forall (S : 'M[R]_p) (sS : @seqmx R),
  refines (Rseqmx (nat_Rxx p) (nat_Rxx p)) S sS ->
  refines (Rseqmx (nat_Rxx p) (nat_Rxx p)) (invmx S) (cinv sS).

Lemma predict_cov_seqmx_correct (P : 'M[R]_n) (sP : @seqmx R)
    (rP : refines (Rseqmx (nat_Rxx n) (nat_Rxx n)) P sP) :
  refines (Rseqmx (nat_Rxx n) (nat_Rxx n))
        (predict_cov conj F G Q P) (predict_cov_seqmx conj m n sF sG sQ sP).
Proof.
      rewrite /predict_cov /predict_cov_seqmx.
  have rX := refines_mulmx (refines_mulmx rF rP) (refines_ctr_seqmx rF).
  have rY := refines_mulmx (refines_mulmx rG rQ) (refines_ctr_seqmx rG).
  exact: refines_apply.
Qed.

Lemma innov_cov_seqmx_correct (P : 'M[R]_n) (sP : @seqmx R)
    (rP : refines (Rseqmx (nat_Rxx n) (nat_Rxx n)) P sP) :
  refines (Rseqmx (nat_Rxx p) (nat_Rxx p))
        (innov_cov conj H Rm P) (innov_cov_seqmx conj n p sH sRm sP).
Proof.
      rewrite /innov_cov /innov_cov_seqmx.
  have rX := refines_mulmx (refines_mulmx rH rP) (refines_ctr_seqmx rH).
  exact: refines_apply.
Qed.

    Lemma filter_gain_seqmx_correct (P : 'M[R]_n) (sP : @seqmx R)
    (rP : refines (Rseqmx (nat_Rxx n) (nat_Rxx n)) P sP) :
  refines (Rseqmx (nat_Rxx n) (nat_Rxx p))
        (filter_gain conj H Rm P)
        (filter_gain_seqmx conj n p sH sRm cinv sP).
Proof.
      rewrite /filter_gain /filter_gain_seqmx.
  have rinv := cinv_correct (innov_cov_seqmx_correct rP).
  exact: (refines_mulmx (refines_mulmx rP (refines_ctr_seqmx rH)) rinv).
Qed.

Lemma update_cov_seqmx_correct (P : 'M[R]_n) (sP : @seqmx R)
    (rP : refines (Rseqmx (nat_Rxx n) (nat_Rxx n)) P sP) :
  refines (Rseqmx (nat_Rxx n) (nat_Rxx n))
        (update_cov conj H Rm P)
    (update_cov_seqmx conj n p sH sRm cinv sP).
Proof.
      rewrite /update_cov /update_cov_seqmx.
      have rK := filter_gain_seqmx_correct rP.
  have rKH := refines_mulmx rK rH.
  have r1 := Rseqmx_1 R (nat_Rxx n).
  have rsub := refines_addmx r1 (refines_oppmx rKH).
  exact: (refines_mulmx rsub rP).
Qed.

Lemma alt_update_cov_seqmx_correct (Kp : 'M[R]_(n, p)) (sKp : @seqmx R)
    (rKp : refines (Rseqmx (nat_Rxx n) (nat_Rxx p)) Kp sKp)
    (P : 'M[R]_n) (sP : @seqmx R)
    (rP : refines (Rseqmx (nat_Rxx n) (nat_Rxx n)) P sP) :
  refines (Rseqmx (nat_Rxx n) (nat_Rxx n))
        (alt_update_cov conj H Rm Kp P)
    (alt_update_cov_seqmx conj n p sH sRm sKp sP).
Proof.
      rewrite /alt_update_cov /alt_update_cov_seqmx.
  have rKpH := refines_mulmx rKp rH.
  have r1 := Rseqmx_1 R (nat_Rxx n).
      have rEmKH := refines_addmx r1 (refines_oppmx rKpH).
      have rT1 := refines_mulmx (refines_mulmx rEmKH rP) (refines_ctr_seqmx rEmKH).
  have rT2 := refines_mulmx (refines_mulmx rKp rRm) (refines_ctr_seqmx rKp).
  exact: (refines_addmx rT1 rT2).
Qed.

Lemma riccati_step_seqmx_correct (P : 'M[R]_n) (sP : @seqmx R)
    (rP : refines (Rseqmx (nat_Rxx n) (nat_Rxx n)) P sP) :
  refines (Rseqmx (nat_Rxx n) (nat_Rxx n))
        (riccati_step conj F G H Q Rm P)
    (riccati_step_seqmx conj m n p sF sG sH sQ sRm cinv sP).
Proof.
      rewrite /riccati_step /riccati_step_seqmx.
  exact: (update_cov_seqmx_correct (predict_cov_seqmx_correct rP)).
Qed.

    (*
      Корректность итерации исполнимого шага.

      Программа `iter k riccati_step_seqmx sP0` уточняет абстрактную итерацию
      `iter k riccati_step P0`, что позволяет вычислять конечные приближения к
      установившейся ковариации $P_ss$ без обращения к пределу `mx_mono_lim`.
    *)
Lemma riccati_iter_seqmx_correct (k : nat) (P0 : 'M[R]_n) (sP0 : @seqmx R)
    (rP0 : refines (Rseqmx (nat_Rxx n) (nat_Rxx n)) P0 sP0) :
  refines (Rseqmx (nat_Rxx n) (nat_Rxx n))
        (iter k (riccati_step conj F G H Q Rm) P0)
    (iter k (riccati_step_seqmx conj m n p sF sG sH sQ sRm cinv) sP0).
Proof.
  elim: k => [|k IHk] /=; first exact: rP0.
  exact: (riccati_step_seqmx_correct IHk).
Qed.

End System.

End RefineRiccati.

  (*
    Обращение произвольной p*p-матрицы методом Фаддеева-Леверье. Снимает
    обязательство cinv для любого числа выходов p через рекурренту по следу:
    $M_1 = E, c_(n-j) = - tr(A M_j) / j, M_(j+1) = A M_j + c_(n-j) E$,
    $A^(-1) = - c_0^(-1) M_n$. `S \in unitmx` берётся из спецификации:
    kalman.innov_cov_pd даёт innov_cov ... \in unitmx. При $p = 1$ обращение
    верно безусловно (cinv_fl_correct1, так как в поле $0^(-1) = 0$).
  *)
  Section EffInverseFL.
  Context (C : Type).
  Context `{!zero_of C, !one_of C, !opp_of C, !add_of C, !mul_of C, !inv_of C}.

  (* j-кратная сумма единиц как элемент C (образ j%:R). *)
  Definition cnat (j : nat) : C := iter j (fun x => (1 + x)%C) 0%C.

  (* Матрица $M_(j+1)$ рекуррентности Фаддеева-Леверье для n*n-матрицы sA. *)
  Fixpoint fl_M (n : nat) (sA : @seqmx C) (j : nat) : @seqmx C :=
    if j is j'.+1 then
      let AM := @hmul_op _ _ _ n n n sA (fl_M n sA j') in
      add_seqmx AM (scalar_seqmx n (- trace_seqmx (m:=n) AM * (cnat j'.+1)^-1)%C)
    else scalar_seqmx n 1%C.

  (*
    Исполнимое обращение методом Фаддеева-Леверье.

    Последний член рекуррентности `fl_M` нормируется свободным коэффициентом
    характеристического многочлена; программа дословно повторяет `fl_inv` из
    `faddeev.v` на слое операций CoqEAL.
  *)
  Definition cinv_fl (n : nat) (sS : @seqmx C) : @seqmx C :=
    let M := fl_M n sS n.-1 in
    let c := (- trace_seqmx (m:=n) (@hmul_op _ _ _ n n n sS M) * (cnat n)^-1)%C in
    @hmul_op _ _ _ n n n (scalar_seqmx n (- c^-1)%C) M.

  End EffInverseFL.

  Section InverseFLcorrect.
  Variable F : numFieldType.
  Local Notation RR a := (Rseqmx (nat_Rxx a) (nat_Rxx a)).

  Existing Instance Rseqmx_mul.
  Existing Instance Rseqmx_add.
  Existing Instance Rseqmx_scalar_seqmx.
  Existing Instance Rseqmx_trace_seqmx.
  Existing Instance Rseqmx_1.

  Lemma refines_mulmx_fl a b c (X : 'M[F]_(a, b)) (Y : 'M[F]_(b, c))
      (sX sY : @seqmx F) :
    refines (Rseqmx (nat_Rxx a) (nat_Rxx b)) X sX ->
    refines (Rseqmx (nat_Rxx b) (nat_Rxx c)) Y sY ->
    refines (Rseqmx (nat_Rxx a) (nat_Rxx c)) (X *m Y) (@hmul_op _ _ _ a b c sX sY).
  Proof. move=> rX rY; exact: refines_apply. Qed.

  Lemma refines_scalarmx a (x : F) : refines (RR a) (x%:M) (scalar_seqmx a x).
  Proof.
  exact: (refines_apply (Rseqmx_scalar_seqmx _ (nat_Rxx _)) (trivial_refines erefl)).
  Qed.

  Lemma cnat_natr (j : nat) : (cnat j : F) = j%:R.
  Proof.
  elim: j => [//|j IH]; rewrite /cnat /= -/(cnat j).
  by rewrite IH mulrSr addrC.
  Qed.

  Lemma fl_M_refines (n' : nat) (A : 'M[F]_n'.+1) (sA : @seqmx F) j :
    refines (RR n'.+1) A sA ->
    refines (RR n'.+1) (flM A j) (fl_M n'.+1 sA j).
  Proof.
  move=> rA; elim: j => [|j IH].
    rewrite /=.
    exact: (refines_apply (Rseqmx_scalar_seqmx _ (nat_Rxx _))
                          (trivial_refines erefl)).
  have eflM : flM A j.+1
            = A *m flM A j + (- \tr (A *m flM A j) / (j.+1)%:R) *: 1%:M by [].
  have eM : fl_M n'.+1 sA j.+1
          = add_seqmx (@hmul_op _ _ _ n'.+1 n'.+1 n'.+1 sA (fl_M n'.+1 sA j))
              (scalar_seqmx n'.+1
                (- trace_seqmx (m:=n'.+1) (@hmul_op _ _ _ n'.+1 n'.+1 n'.+1 sA
                     (fl_M n'.+1 sA j)) * (cnat j.+1)^-1)) by [].
  rewrite eflM eM.
  have rAM : refines (RR n'.+1) (A *m flM A j)
                     (@hmul_op _ _ _ n'.+1 n'.+1 n'.+1 sA (fl_M n'.+1 sA j)).
    exact: refines_apply.
  have htr : \tr (A *m flM A j)
           = trace_seqmx (m:=n'.+1)
               (@hmul_op _ _ _ n'.+1 n'.+1 n'.+1 sA (fl_M n'.+1 sA j)).
    by apply: refines_eq; exact: refines_apply.
  have hcoef : (- \tr (A *m flM A j) / (j.+1)%:R
              = - trace_seqmx (m:=n'.+1)
                    (@hmul_op _ _ _ n'.+1 n'.+1 n'.+1 sA (fl_M n'.+1 sA j))
                  * (cnat j.+1)^-1 :> F).
    by rewrite htr cnat_natr.
  have -> : - \tr (A *m flM A j) / (j.+1)%:R *: 1%:M
          = (- \tr (A *m flM A j) / (j.+1)%:R)%:M :> 'M[F]_n'.+1.
    by rewrite scale_scalar_mx mulr1.
  rewrite hcoef.
  apply: refines_apply.
  apply: refines_apply.
  by rewrite refinesE.
  Qed.

  (* Уточнение исполнимого обращения абстрактным fl_inv (без условия). *)
  Lemma cinv_fl_refines (n' : nat) (S : 'M[F]_n'.+1) (sS : @seqmx F) :
    refines (RR n'.+1) S sS ->
    refines (RR n'.+1) (fl_inv S) (cinv_fl n'.+1 sS).
  Proof.
  move=> rS; rewrite /fl_inv /cinv_fl.
  have predE : (n'.+1).-1 = n' by [].
  rewrite predE.
  have rM : refines (RR n'.+1) (flM S n') (fl_M n'.+1 sS n').
    exact: fl_M_refines.
  have rAM : refines (RR n'.+1) (S *m flM S n')
                     (@hmul_op _ _ _ n'.+1 n'.+1 n'.+1 sS (fl_M n'.+1 sS n')).
    exact: refines_apply.
  have htr : \tr (S *m flM S n')
           = trace_seqmx (m:=n'.+1)
               (@hmul_op _ _ _ n'.+1 n'.+1 n'.+1 sS (fl_M n'.+1 sS n')).
    by apply: refines_eq; exact: refines_apply.
  have hflc : flc S n'
            = (- trace_seqmx (m:=n'.+1)
                  (@hmul_op _ _ _ n'.+1 n'.+1 n'.+1 sS (fl_M n'.+1 sS n'))
                * (cnat n'.+1)^-1 :> F).
    by rewrite /flc htr cnat_natr.
  rewrite hflc -mul_scalar_mx.
  exact: (refines_mulmx_fl (refines_scalarmx _ _) rM).
  Qed.

  (* cinv_fl уточняет invmx для обратимой $p*p$-матрицы. *)
  Lemma cinv_fl_correct (n' : nat) (S : 'M[F]_n'.+1) (sS : @seqmx F) :
    S \in unitmx ->
    refines (RR n'.+1) S sS ->
    refines (RR n'.+1) (invmx S) (cinv_fl n'.+1 sS).
  Proof.
  by move=> Sunit rS; rewrite -(fl_inv_correct Sunit); exact: cinv_fl_refines.
  Qed.

  (* При $p = 1$ обращение верно безусловно (снимает cinv при $p = 1$). *)
  Lemma cinv_fl_correct1 (S : 'M[F]_1) (sS : @seqmx F) :
    refines (RR 1) S sS ->
    refines (RR 1) (invmx S) (cinv_fl 1 sS).
  Proof. by move=> rS; rewrite -(fl_inv1 S); exact: (cinv_fl_refines (n':=0)). Qed.

  End InverseFLcorrect.

(* Мост к kalman.v: при conj := conjC возвращаемся к спецификации над $ℂ$. *)
Section BridgeC.
  Variable ℂ : numClosedFieldType.

  Variables (m n p : nat).
  Variables (F : 'M[ℂ]_n) (G : 'M[ℂ]_(n, m)) (H : 'M[ℂ]_(p, n)).
  Variables (Q : 'M[ℂ]_m) (Rm : 'M[ℂ]_p).

  Variables (sF sG sH sQ sRm : @seqmx ℂ).
  
  Hypothesis rF : refines (Rseqmx (nat_Rxx n) (nat_Rxx n)) F sF.
  Hypothesis rG : refines (Rseqmx (nat_Rxx n) (nat_Rxx m)) G sG.
  Hypothesis rH : refines (Rseqmx (nat_Rxx p) (nat_Rxx n)) H sH.
  Hypothesis rQ : refines (Rseqmx (nat_Rxx m) (nat_Rxx m)) Q sQ.
  Hypothesis rRm : refines (Rseqmx (nat_Rxx p) (nat_Rxx p)) Rm sRm.
  
  Variable cinv : @seqmx ℂ -> @seqmx ℂ.
  
  Hypothesis cinv_correct : forall (S : 'M[ℂ]_p) (sS : @seqmx ℂ),
    refines (Rseqmx (nat_Rxx p) (nat_Rxx p)) S sS ->
    refines (Rseqmx (nat_Rxx p) (nat_Rxx p)) (invmx S) (cinv sS).

  (*
    Исполнимый шаг seqmx уточняет `riccati_step conjC`, то есть оператор
    `kalman.riccati_step` (по определению).
  *)
  Corollary kalman_riccati_step_seqmx_correct (P : 'M[ℂ]_n) (sP : @seqmx ℂ)
      (rP : refines (Rseqmx (nat_Rxx n) (nat_Rxx n)) P sP) :
    refines (Rseqmx (nat_Rxx n) (nat_Rxx n))
      (riccati_step conjC F G H Q Rm P)
      (riccati_step_seqmx conjC m n p sF sG sH sQ sRm cinv sP).
  Proof.
    apply: riccati_step_seqmx_correct; assumption.
  Qed.

End BridgeC.

(* Конкретное исполнение над rat (conj := idfun, p = 1). *)
Section ConcreteRat.

  Existing Instance Rseqmx_map_seqmx.

  (* Уточнение скалярной матрицы её singleton-литералом seqmx. *)
  Lemma rseqmx_11 (a : rat) :
    refines (Rseqmx (nat_Rxx 1) (nat_Rxx 1)) (a%:M : 'M[rat]_1) [:: [:: a]].
  Proof.
    rewrite refinesE; constructor.
    - by [].
    - by case=> [|?].
    - by move=> i j; rewrite !ord1 mxE eqxx mulr1n.
  Qed.

  (* Скалярная система: $F = 2, G = H = Q = R = P_0 = 1$. *)
  Definition exF : 'M[rat]_1 := (2%:R)%:M.
  Definition exG : 'M[rat]_1 := 1%:M.
  Definition exH : 'M[rat]_1 := 1%:M.
  Definition exQ : 'M[rat]_1 := 1%:M.
  Definition exR : 'M[rat]_1 := 1%:M.
  Definition exP0 : 'M[rat]_1 := 1%:M.

  Definition sxF : @seqmx rat := [:: [:: 2%:R : rat]].
  Definition sxG : @seqmx rat := [:: [:: 1 : rat]].
  Definition sxH : @seqmx rat := [:: [:: 1 : rat]].
  Definition sxQ : @seqmx rat := [:: [:: 1 : rat]].
  Definition sxR : @seqmx rat := [:: [:: 1 : rat]].
  Definition sxP0 : @seqmx rat := [:: [:: 1 : rat]].

  Definition ex_step : @seqmx rat -> @seqmx rat :=
    riccati_step_seqmx (idfun : rat -> rat) 1 1 1 sxF sxG sxH sxQ sxR (cinv_fl 1).

  (* Итерация исполнимого шага уточняет абстрактную итерацию над rat. *)
  Lemma ex_iter_correct (k : nat) :
    refines (Rseqmx (nat_Rxx 1) (nat_Rxx 1))
      (iter k (riccati_step idfun exF exG exH exQ exR) exP0)
      (iter k ex_step sxP0).
  Proof.
    apply: (@riccati_iter_seqmx_correct rat idfun 1 1 1
              exF exG exH exQ exR sxF sxG sxH sxQ sxR
              (rseqmx_11 _) (rseqmx_11 _) (rseqmx_11 _) (rseqmx_11 _) (rseqmx_11 _)
              (cinv_fl 1) (@cinv_fl_correct1 rat) k exP0 sxP0).
    exact: rseqmx_11.
  Qed.

  End ConcreteRat.

  (*
    Два шага: скалярное ДАУР из $P_0 = 1$ даёт $5/6$, затем $13/16$. Значение
    проверено через `vm_compute` и связано со спецификацией через
    `ex_iter_correct` (отношение `Rseqmx` функционально).
  *)
  Definition ex_two : @seqmx rat := iter 2 ex_step sxP0.

  Lemma ex_two_val :
    (ex_two == [:: [:: (13%:R / 16%:R : rat)]] :> @seqmx rat) = true.
  Proof. by vm_compute. Qed.

(*
  Мост параметричности rat -> bigQ через RseqmxC r_ratBigQ

  Уточнение из `RefineRiccati` доказано на одном кольце (`Rseqmx`, поле = rat).
  Здесь оно поднимается до гетерогенного отношения `RseqmxC r_ratBigQ`,
  связывающего абстрактную матрицу `'M[rat]` напрямую с seqmx-программой над
  `bigQ`. Композиция (`RseqmxC rAC = Rseqmx \o list_R (list_R rAC)`) выполняется
  через те же экземпляры `RseqmxC_*` библиотеки CoqEAL и поэлементные уточнения
  `binrat` (`refine_ratBigQ_*`). Зеркало `RefineRiccati`, но
  `Rseqmx -> RseqmxC`.

  Итоговая теорема `riccati_iter_seqmxC` устанавливает, что итерация шага
  Риккати над `bigQ` уточняет абстрактную `rat`-итерацию спецификации.
*)
Section BridgeBigQ.

  Notation RC a b := (RseqmxC r_ratBigQ (nat_Rxx a) (nat_Rxx b)).

  Variable conj : rat -> rat.
  Variable conjC : bigQ -> bigQ.
  Context (rconj : refines (r_ratBigQ ==> r_ratBigQ) conj conjC).

  Lemma refinesC_ctr (a b : nat) (A : 'M[rat]_(a, b)) (sA : @seqmx bigQ)
      (rA : refines (RC a b) A sA) :
    refines (RC b a) (map_mx conj A^T) (ctr_seqmx conjC a b sA).
  Proof.
    rewrite /ctr_seqmx.
    exact: (refines_apply
              (refines_apply (refine_map_seqmx r_ratBigQ r_ratBigQ b a) rconj)
              (refines_apply (refine_trseqmx r_ratBigQ a b) rA)).
  Qed.

  Lemma refinesC_mulmx (a b c : nat) (X : 'M[rat]_(a, b)) (Y : 'M[rat]_(b, c))
      (sX sY : @seqmx bigQ)
      (rX : refines (RC a b) X sX) (rY : refines (RC b c) Y sY) :
    refines (RC a c) (X *m Y) (@hmul_op _ _ _ a b c sX sY).
  Proof. exact: refines_apply. Qed.

  Lemma refinesC_addmx (a b : nat) (X Y : 'M[rat]_(a, b)) (sX sY : @seqmx bigQ)
      (rX : refines (RC a b) X sX) (rY : refines (RC a b) Y sY) :
    refines (RC a b) (X + Y) (add_seqmx sX sY).
  Proof. exact: refines_apply. Qed.

  Lemma refinesC_oppmx (a b : nat) (X : 'M[rat]_(a, b)) (sX : @seqmx bigQ)
      (rX : refines (RC a b) X sX) :
    refines (RC a b) (- X) (opp_seqmx sX).
  Proof. exact: refines_apply. Qed.

Section System.

  Variables (m n p : nat).
  Variables (F : 'M[rat]_n) (G : 'M[rat]_(n, m)) (H : 'M[rat]_(p, n)).
  Variables (Q : 'M[rat]_m) (Rm : 'M[rat]_p).
  Variables (sF sG sH sQ sRm : @seqmx bigQ).

  Hypothesis rF : refines (RC n n) F sF.
  Hypothesis rG : refines (RC n m) G sG.
  Hypothesis rH : refines (RC p n) H sH.
  Hypothesis rQ : refines (RC m m) Q sQ.
  Hypothesis rRm : refines (RC p p) Rm sRm.

  Variable cinv : @seqmx bigQ -> @seqmx bigQ.

  Hypothesis cinv_correct : forall (S : 'M[rat]_p) (sS : @seqmx bigQ),
    refines (RC p p) S sS -> refines (RC p p) (invmx S) (cinv sS).

  Lemma predict_cov_seqmxC (P : 'M[rat]_n) (sP : @seqmx bigQ)
      (rP : refines (RC n n) P sP) :
    refines (RC n n)
      (predict_cov conj F G Q P) (predict_cov_seqmx conjC m n sF sG sQ sP).
  Proof.
    rewrite /predict_cov /predict_cov_seqmx.
    have rX := refinesC_mulmx (refinesC_mulmx rF rP) (refinesC_ctr rF).
    have rY := refinesC_mulmx (refinesC_mulmx rG rQ) (refinesC_ctr rG).
    exact: refines_apply.
  Qed.

  Lemma innov_cov_seqmxC (P : 'M[rat]_n) (sP : @seqmx bigQ)
      (rP : refines (RC n n) P sP) :
    refines (RC p p)
      (innov_cov conj H Rm P) (innov_cov_seqmx conjC n p sH sRm sP).
  Proof.
    rewrite /innov_cov /innov_cov_seqmx.
    have rX := refinesC_mulmx (refinesC_mulmx rH rP) (refinesC_ctr rH).
    exact: refines_apply.
  Qed.

  Lemma filter_gain_seqmxC (P : 'M[rat]_n) (sP : @seqmx bigQ)
      (rP : refines (RC n n) P sP) :
    refines (RC n p)
      (filter_gain conj H Rm P)
      (filter_gain_seqmx conjC n p sH sRm cinv sP).
  Proof.
    rewrite /filter_gain /filter_gain_seqmx.
    have rinv := cinv_correct (innov_cov_seqmxC rP).
    exact: (refinesC_mulmx (refinesC_mulmx rP (refinesC_ctr rH)) rinv).
  Qed.

  Lemma update_cov_seqmxC (P : 'M[rat]_n) (sP : @seqmx bigQ)
      (rP : refines (RC n n) P sP) :
    refines (RC n n)
      (update_cov conj H Rm P)
      (update_cov_seqmx conjC n p sH sRm cinv sP).
  Proof.
    rewrite /update_cov /update_cov_seqmx.
    have rK := filter_gain_seqmxC rP.
    have rKH := refinesC_mulmx rK rH.
    have r1 : refines (RC n n) 1%:M (seqmx1 n) by tc.
    have rsub := refinesC_addmx r1 (refinesC_oppmx rKH).
    exact: (refinesC_mulmx rsub rP).
  Qed.

  Lemma riccati_step_seqmxC (P : 'M[rat]_n) (sP : @seqmx bigQ)
      (rP : refines (RC n n) P sP) :
    refines (RC n n)
      (riccati_step conj F G H Q Rm P)
      (riccati_step_seqmx conjC m n p sF sG sH sQ sRm cinv sP).
  Proof.
    rewrite /riccati_step /riccati_step_seqmx.
    exact: (update_cov_seqmxC (predict_cov_seqmxC rP)).
  Qed.

  Lemma riccati_iter_seqmxC (k : nat) (P0 : 'M[rat]_n) (sP0 : @seqmx bigQ)
      (rP0 : refines (RC n n) P0 sP0) :
    refines (RC n n)
      (iter k (riccati_step conj F G H Q Rm) P0)
      (iter k (riccati_step_seqmx conjC m n p sF sG sH sQ sRm cinv) sP0).
  Proof.
    elim: k => [|k IHk] /=; first exact: rP0.
    exact: (riccati_step_seqmxC IHk).
  Qed.

  End System.

End BridgeBigQ.
