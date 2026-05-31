(*
  Теорема инверсии Ляпунова (Kailath–Sayed–Hassibi, Thm E.5.1, частный случай).

  Если PD-решение `X` дискретного уравнения Ляпунова

      X = A† X A + Q   (или замкнуто-контурная форма  X = A X A† + Q)

  имеет PSD «вход» `Q`, то спектр `A` лежит в ЗАМКНУТОМ единичном диске:
  любое собственное значение `lam` удовлетворяет `|lam| ≤ 1`.

  При наблюдаемости пары `(A, H)` с `Q = H† H` (соотв. управляемости
  `(A, G)` с `Q = G G†`) спектр строго внутри: `|lam| < 1` — это и есть
  Шуровость `A`.

  Доказательство — прямое спектральное (одна квадратичная форма на
  собственном векторе):

      v† X v = |lam|² v† X v + v† Q v
    ⟹ (1 - |lam|²) v† X v = v† Q v ≥ 0,

  и `v† X v > 0` (X PD, v ≠ 0) даёт `|lam|² ≤ 1`.  Строгость следует из
  PBH-детектируемости: при `|lam| = 1` правая часть зануляется, откуда
  `H v = 0`, что противоречит детектируемости.

  Ни одной новой аксиомы: все главные теоремы замкнуты в глобальном
  контексте.  Это книжная альтернатива (более слабая гипотеза, чем
  `frob_sq A < 1`) для установления стабильности замкнутого контура `Fp`
  в `dare.v` (Session 25).
*)

Set Warnings "-notation-overridden,-coercions,-default".

From Stdlib.Unicode Require Import Utf8.
From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra.
From mathcomp.algebra Require Import sesquilinear spectral.
From mathcomp Require Import order.
From mathcomp.classical Require Import boolp.
From Kalman Require Import mxnotation mxherm mxdefinite mxfrob detectability.
From Kalman Require Import spec_rad.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory Num.Theory Order.Theory.
Local Open Scope ring_scope.
Local Open Scope sesquilinear_scope.

Section LyapInv.
Variable (ℂ : numClosedFieldType).

(* ================================================================== *)
(*  Правые собственные векторы: форма X = A† X A + Q                   *)
(* ================================================================== *)

(* Баланс квадратичной формы на собственном векторе `A v = lam v`:     *)
(*   (1 - |lam|²) · (v† X v) = v† Q v.                                 *)
(* Ключ: v† (A† X A) v = (A v)† X (A v) = |lam|² · (v† X v).           *)
Lemma lyap_qf_balance n (X A Q : 'M[ℂ]_n) (lam : ℂ) (v : 'cV[ℂ]_n) :
  X = A^t* *m X *m A + Q ->
  A *m v = lam *: v ->
  (1 - `|lam| ^+ 2) * \tr (v^t* *m X *m v) = \tr (v^t* *m Q *m v).
Proof.
move=> lyapeq Fv.
have key : \tr (v^t* *m (A^t* *m X *m A) *m v)
         = `|lam| ^+ 2 * \tr (v^t* *m X *m v).
  have e1 : v^t* *m (A^t* *m X *m A) *m v
          = (A *m v)^t* *m X *m (A *m v) by rewrite trmxC_mul !mulmxA.
  rewrite e1 Fv trmxC_scale -scalemxAl -scalemxAl -scalemxAr scalerA.
  by rewrite mxtraceZ normCKC.
have expand : \tr (v^t* *m X *m v)
            = `|lam| ^+ 2 * \tr (v^t* *m X *m v) + \tr (v^t* *m Q *m v).
  by rewrite {1}lyapeq mulmxDr mulmxDl mxtraceD key.
by rewrite mulrBl mul1r {1}expand addrAC subrr add0r.
Qed.

(* Без наблюдаемости: спектр в замкнутом единичном диске `|lam| ≤ 1`.  *)
Lemma lyap_eigval_le1 n (X A Q : 'M[ℂ]_n) (lam : ℂ) (v : 'cV[ℂ]_n) :
  pd X -> psd Q -> X = A^t* *m X *m A + Q ->
  v != 0 -> A *m v = lam *: v -> `|lam| <= 1.
Proof.
move=> Xpd Qpsd lyapeq vNZ Fv.
have bal := lyap_qf_balance lyapeq Fv.
have qfX_pos : 0 < \tr (v^t* *m X *m v) by case: Xpd => _ /(_ v vNZ).
have qfQ_ge0 : 0 <= \tr (v^t* *m Q *m v) by case: Qpsd => _ /(_ v).
have h : 0 <= (1 - `|lam| ^+ 2) * \tr (v^t* *m X *m v) by rewrite bal.
rewrite pmulr_lge0 // in h.
rewrite subr_ge0 in h.
rewrite -(@ler_pXn2r _ 2 isT) ?nnegrE ?normr_ge0 ?ler01 //.
by rewrite expr1n.
Qed.

(* С детектируемостью пары (A, H), Q = H† H: строгая Шуровость `|lam| < 1`. *)
Lemma lyap_eigval_lt1 n p (X A Q : 'M[ℂ]_n) (H : 'M[ℂ]_(p, n))
    (lam : ℂ) (v : 'cV[ℂ]_n) :
  pd X -> Q = H^t* *m H -> X = A^t* *m X *m A + Q ->
  detectable A H -> v != 0 -> A *m v = lam *: v -> `|lam| < 1.
Proof.
move=> Xpd Qfact lyapeq Hdet vNZ Fv.
have Qpsd : psd Q by rewrite Qfact; exact: psd_frob.
have le1 := lyap_eigval_le1 Xpd Qpsd lyapeq vNZ Fv.
rewrite lt_neqAle le1 andbT.
apply/negP=> /eqP lam1.
have bal := lyap_qf_balance lyapeq Fv.
rewrite lam1 expr1n subrr mul0r in bal.
have qfQ0 : \tr (v^t* *m Q *m v) = 0 by rewrite -bal.
have HvF0 : frob_sq (H *m v) = 0.
  by rewrite /frob_sq trmxC_mul -qfQ0 Qfact !mulmxA.
have Hv0 := frob_sq_eq0 HvF0.
have HvNZ : H *m v != 0 by apply: (Hdet lam v vNZ Fv); rewrite lam1.
by move: HvNZ; rewrite Hv0 eqxx.
Qed.

(* ================================================================== *)
(*  Левые собственные векторы: форма X = A X A† + Q (замкнутый контур) *)
(* ================================================================== *)

(* Двойственность PBH: управляемость (A, G) даёт детектируемость           *)
(* (A†, G†) (левый собственный вектор `w A = lam w` ↔ правый                *)
(* `A† w† = lam^* w†`).                                                     *)
Lemma stabilizable_detectable_conj n m (A : 'M[ℂ]_n) (G : 'M[ℂ]_(n, m)) :
  stabilizable A G -> detectable (A^t*) (G^t*).
Proof.
move=> Hstab mu u uNZ Au mu_ge1.
set w := u^t*.
have wNZ : w != 0 by rewrite /w trmxC_eq0.
have wA : w *m A = mu^* *: w.
  by rewrite /w -{1}(trmxCK A) -trmxC_mul Au trmxC_scale.
have mu_conj_ge1 : 1 <= `|mu^*| by rewrite norm_conjC.
have wG := Hstab mu^* w wNZ wA mu_conj_ge1.
apply: contra_neq wG => GtU0.
by rewrite -[w *m G]trmxCK trmxC_mul /w trmxCK GtU0 trmxC0.
Qed.

(* Замкнуто-контурная форма, без управляемости: `|lam| ≤ 1`.               *)
Lemma lyap_inversion_le n (X A Q : 'M[ℂ]_n) (lam : ℂ) (w : 'rV[ℂ]_n) :
  pd X -> psd Q -> X = A *m X *m A^t* + Q ->
  w != 0 -> w *m A = lam *: w -> `|lam| <= 1.
Proof.
move=> Xpd Qpsd lyapeq wNZ wA.
have lyapeq' : X = (A^t*)^t* *m X *m A^t* + Q by rewrite trmxCK.
have wtNZ : w^t* != 0 by rewrite trmxC_eq0.
have Aw : A^t* *m w^t* = lam^* *: w^t*.
  by rewrite -trmxC_mul wA trmxC_scale.
have h := lyap_eigval_le1 Xpd Qpsd lyapeq' wtNZ Aw.
by rewrite norm_conjC in h.
Qed.

(* Теорема инверсии Ляпунова (замкнуто-контурная форма):                    *)
(*   PD-решение X = A X A† + Q с Q = G G† под управляемостью (A, G)          *)
(*   ⟹ A Шуров: все собственные значения строго внутри единичного диска.    *)
Lemma lyap_inversion n m (X A Q : 'M[ℂ]_n) (G : 'M[ℂ]_(n, m))
    (lam : ℂ) (w : 'rV[ℂ]_n) :
  pd X -> Q = G *m G^t* -> X = A *m X *m A^t* + Q ->
  stabilizable A G -> w != 0 -> w *m A = lam *: w -> `|lam| < 1.
Proof.
move=> Xpd Qfact lyapeq Hstab wNZ wA.
have lyapeq' : X = (A^t*)^t* *m X *m A^t* + Q by rewrite trmxCK.
have Qfact' : Q = (G^t*)^t* *m G^t* by rewrite trmxCK.
have wtNZ : w^t* != 0 by rewrite trmxC_eq0.
have Aw : A^t* *m w^t* = lam^* *: w^t*.
  by rewrite -trmxC_mul wA trmxC_scale.
have Hdet : detectable (A^t*) (G^t*) by exact: stabilizable_detectable_conj.
have h := lyap_eigval_lt1 Xpd Qfact' lyapeq' Hdet wtNZ Aw.
by rewrite norm_conjC in h.
Qed.

(* ================================================================== *)
(*  PD-вес: строгая Шуровость без наблюдаемости                        *)
(* ================================================================== *)

(* Если «вход» `W` ПОЛОЖИТЕЛЬНО ОПРЕДЕЛЁН (а не только PSD), строгая      *)
(* Шуровость `|lam| < 1` следует напрямую: при `|lam| = 1` баланс         *)
(* зануляет `v† W v`, что невозможно для PD `W` и `v ≠ 0`.  Это снимает   *)
(* нужду в наблюдаемости/детектируемости (ср. `lyap_eigval_lt1`).        *)
Lemma lyap_eigval_pdW_lt1 n (X A W : 'M[ℂ]_n) (lam : ℂ) (v : 'cV[ℂ]_n) :
  pd X -> pd W -> X = A^t* *m X *m A + W ->
  v != 0 -> A *m v = lam *: v -> `|lam| < 1.
Proof.
move=> Xpd Wpd lyapeq vNZ Fv.
have Wpsd : psd W := pd_psd Wpd.
have le1 := lyap_eigval_le1 Xpd Wpsd lyapeq vNZ Fv.
rewrite lt_neqAle le1 andbT.
apply/negP=> /eqP lam1.
have bal := lyap_qf_balance lyapeq Fv.
rewrite lam1 expr1n subrr mul0r in bal.
have qfW0 : \tr (v^t* *m W *m v) = 0 by rewrite -bal.
have qfW_pos : 0 < \tr (v^t* *m W *m v) by case: Wpd => _ /(_ v vNZ).
by rewrite qfW0 ltxx in qfW_pos.
Qed.

(* Замкнуто-контурная форма (левый собственный вектор), PD-вес.          *)
Lemma lyap_inversion_pdW_lt1 n (X A W : 'M[ℂ]_n) (lam : ℂ) (w : 'rV[ℂ]_n) :
  pd X -> pd W -> X = A *m X *m A^t* + W ->
  w != 0 -> w *m A = lam *: w -> `|lam| < 1.
Proof.
move=> Xpd Wpd lyapeq wNZ wA.
have lyapeq' : X = (A^t*)^t* *m X *m A^t* + W by rewrite trmxCK.
have wtNZ : w^t* != 0 by rewrite trmxC_eq0.
have Aw : A^t* *m w^t* = lam^* *: w^t*.
  by rewrite -trmxC_mul wA trmxC_scale.
have h := lyap_eigval_pdW_lt1 Xpd Wpd lyapeq' wtNZ Aw.
by rewrite norm_conjC in h.
Qed.

(* Свидетель Шуровости из PD-неподвижной точки замкнутого контура.        *)
(*   PD `X`, PD `W`, `X = A X A† + W`  ⟹  `spec_rad_lt1 A`.              *)
(* Каждый корень char-многочлена `A` (левый собственный вектор)          *)
(* строго внутри единичного диска (`lyap_inversion_pdW_lt1`), откуда      *)
(* `spec_rad_lt1_of_dets` строит Schur-свидетель.  Эта лемма устраняет    *)
(* `Hypothesis Fp_contract` в `dare.v`: `predict_cov Pss` — PD-           *)
(* неподвижная точка с PD-весом `Kp Rn Kp† + G Q G†` (PD по `pd_GQGt`).   *)
Lemma lyap_inv_spec_rad n (X A W : 'M[ℂ]_n.+1) :
  pd X -> pd W -> X = A *m X *m A^t* + W -> spec_rad_lt1 A.
Proof.
move=> Xpd Wpd lyapeq.
apply: spec_rad_lt1_of_dets => lam Hdet.
move/det0P: Hdet => [w wNZ Hw].
have wA : w *m A = lam *: w.
  move/eqP: Hw; rewrite mulmxBr mul_mx_scalar subr_eq0 => /eqP heq.
  by rewrite heq.
exact: lyap_inversion_pdW_lt1 Xpd Wpd lyapeq wNZ wA.
Qed.

End LyapInv.
