(*
  Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
  SPDX-License-Identifier: GPL-3.0-or-later

  Теорема инверсии Ляпунова - дискретный критерий Ляпунова
  - @kailath2000[App. D, Theorem D.3.1 "Lyapunov Condition"].

  Если положительно определённое решение $X$ дискретного уравнения Ляпунова

  $X = A† X A + Q$ (или форма замкнутого контура $X = A X A† + Q$)

  имеет неотрицательно определённую $Q$, то спектр $A$ лежит в замкнутом
  единичном диске: любое собственное значение $λ$ удовлетворяет $|λ| <= 1$.

  При наблюдаемости пары $(A, H)$ с $Q = H† H$
  (соотв. управляемости $(A, G)$ с $Q = G G†$) спектр строго внутри: $|λ| < 1$ -
  это и есть устойчивость по Шуру матрицы $A$.

  Доказательство - прямое спектральное
  (одна квадратичная форма на собственном векторе):
  $v† X v = |λ|^2 v† X v + v† Q v => (1 - |λ|^2) v† X v = v† Q v >= 0$, и
  $v† X v > 0$ ($X$ положительно определена, $v != 0$) даёт $|λ|^2 <= 1$.
  Строгость следует из PBH-детектируемости: при $|λ| = 1$ правая часть
  обращается в ноль, откуда $H v = 0$, что противоречит детектируемости.
*)

From Stdlib.Unicode Require Import Utf8.
From HB Require Import structures.
From mathcomp.boot Require Import all_boot.
From mathcomp.algebra Require Import ssralg ssrnum matrix mxalgebra.
From mathcomp.algebra Require Import sesquilinear spectral.
From mathcomp Require Import order.
From mathcomp.classical Require Import boolp.
From Kalman Require Import mxnotation mxherm mxdefinite mxfrob detectability
  spectral spec_rad.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory Num.Theory Order.Theory.
Local Open Scope ring_scope.
Local Open Scope sesquilinear_scope.

Section LyapInv.

  Variable (ℂ : numClosedFieldType).

  (*
    Правые собственные векторы: форма $X = A† X A + Q$.

    Баланс квадратичной формы на собственном векторе $A v = λ v$:
    $(1 - |λ|^2)(v† X v) = v† Q v$.
  *)
  Lemma lyap_qf_balance n (X A Q : 'M[ℂ]_n) (lam : ℂ) (v : 'cV[ℂ]_n) :
    X = A^t* *m X *m A + Q ->
    A *m v = lam *: v ->
    (1 - `|lam| ^+ 2) * \tr (v^t* *m X *m v) = \tr (v^t* *m Q *m v).
  (* Схема: $v† (A† X A) v = (A v)† X (A v) = |λ|² (v† X v).$ *)
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

  (* Без наблюдаемости: спектр в замкнутом единичном диске $|λ| <= 1$. *)
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

  (*
    С детектируемостью пары $(A, H)$, $Q = H† H$: строгая устойчивость по Шуру
    $|λ| < 1$.
  *)
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

  (*
    Левые собственные векторы: форма X = A X A† + Q (замкнутый контур).

    Двойственность PBH: управляемость (A, G) даёт детектируемость (A†, G†)
    (левый собственный вектор $w A = λ w$ <=> правый $A† w† = λ^* w†$).
    - @kailath2000[App. C, § C.4].
  *)
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

  (* Форма замкнутого контура, без управляемости: $|λ| <= 1$. *)
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

  (*
    Дискретный критерий Ляпунова (форма замкнутого контура): положительно
    определённое решение X = A X A† + Q с Q = G G† под управляемостью (A, G)
    влечёт устойчивость A по Шуру.

    - @kailath2000[App. D, Theorem D.3.1 "Lyapunov Condition"].
  *)
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

  (*
    Положительно определённый вес: строгая устойчивость по Шуру без
    наблюдаемости.

    Если $W$ положительно определена (а не только неотрицательно), строгая
    устойчивость по Шуру $|λ| < 1$ следует напрямую: при $|λ| = 1$ баланс
    обращает в ноль $v† W v$, что невозможно для положительно определённого $W$
    и $v != 0$. Это снимает нужду в наблюдаемости/детектируемости
    (ср. `lyap_eigval_lt1`).
  *)
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

  (*
    Форма замкнутого контура (левый собственный вектор), положительно
    определённый вес.
  *)
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

  (*
    Устойчивость по Шуру из положительно определённой неподвижной точки
    замкнутого контура: положительно определённые $X$, $W$, $X = A X A† + W$ =>
    `spec_rad_lt1 A`. Каждый корень характеристического многочлена $A$
    (левый собственный вектор) строго внутри единичного диска
    (`lyap_inversion_pdW_lt1`), откуда `spec_rad_lt1_of_dets` строит разложение
    Шура. Эта лемма устраняет `Hypothesis Fp_contract` в `Section DARE`:
    `predict_cov P_ss` - положительно определённая неподвижная точка с
    положительно определённым весом $K_p R K_p† + G Q G†$.
    - @kailath2000[App. D, Theorem D.3.1 "Lyapunov Condition"].
  *)
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

  (*
    Неотрицательно определённый вес + стабилизируемость: устойчивость по Шуру
    без положительной определённости. Критерий устойчивости замкнутого контура,
    ослабляющий `lyap_inv_spec_rad`: вместо положительно определённых `X` и веса
    `W` достаточно лишь неотрицательно определённых `X`, `W` и стабилизируемости
    пары $(A, W)$ (левый PBH на $|λ| >= 1$).

    - @kailath2000[App. D, Theorem D.3.1 "Lyapunov Condition"];
    - @kailath2000[App. E, Lemma E.4.2 "Stable F − K_{P,Z} H"].
  *)
  Lemma lyap_inv_spec_rad_stab n (X A W : 'M[ℂ]_n.+1) :
    psd X -> psd W ->
    X = A *m X *m A^t* + W ->
    stabilizable A W ->
    spec_rad_lt1 A.
  (*
    Энергетический баланс на левом собственном векторе $w A = λ w$ даёт
    $(1 - |λ|^2)(v† X v) = v† W v$; при $|λ| >= 1$ левая часть <= 0, правая >=
    0, обе обращаются в ноль, откуда
    (через `psd_qf0_mul0` для неотрицательно определённых матриц) $w W = 0$ -
    противоречие со стабилизируемостью.
  *)
    Proof.
    move=> Xpsd Wpsd lyapeq Hstab.
    apply: spec_rad_lt1_of_dets => lam Hdet.
    move/det0P: Hdet => [w wNZ Hw].
    have wA : w *m A = lam *: w.
      move/eqP: Hw; rewrite mulmxBr mul_mx_scalar subr_eq0 => /eqP heq.
      by rewrite heq.
    rewrite real_ltNge ?normr_real ?rpred1 //; apply/negP=> lam_ge1.
    (* энергетический баланс на левом собственном векторе через сопряжение *)
    set v := w^t*.
    have vNZ : v != 0 by rewrite /v trmxC_eq0.
    have Av : A^t* *m v = lam^* *: v.
      by rewrite /v -trmxC_mul wA trmxC_scale.
    have lyapeq' : X = (A^t*)^t* *m X *m A^t* + W by rewrite trmxCK.
    have bal := lyap_qf_balance lyapeq' Av.
    rewrite norm_conjC in bal.
    have qfX : 0 <= \tr (v^t* *m X *m v) by case: Xpsd => _ /(_ v).
    have qfW : 0 <= \tr (v^t* *m W *m v) by case: Wpsd => _ /(_ v).
    have lhs_le0 : (1 - `|lam| ^+ 2) * \tr (v^t* *m X *m v) <= 0.
      apply: mulr_le0_ge0 => //.
      by rewrite subr_le0 expr_ge1 ?normr_ge0.
    have qfW0 : \tr (v^t* *m W *m v) = 0.
      apply/eqP; rewrite eq_le qfW andbT -bal; exact: lhs_le0.
    have Wv0 : W *m v = 0 := psd_qf0_mul0 Wpsd qfW0.
    have wW0 : w *m W = 0.
      have e : w *m W = (W *m v)^t* by rewrite /v trmxC_mul trmxCK -(proj1 Wpsd).
      by rewrite e Wv0 trmxC0.
    have := Hstab lam w wNZ wA lam_ge1.
    by rewrite wW0 eqxx.
  Qed.

  (*
    Перенос стабилизируемости на замкнутый контур коррекции по выходу.

    Стабилизируемость пары $(A, Z)$ (PBH-вес $Z$ неотрицательно определён)
    переносится на замкнутый контур коррекции по выходу $A - K_p H$ с дополненным
    весом $K_p R K_p† + Z$ ($R$ положительно определена). Это
    - @kailath2000[App. E, Lemma E.4.2 "Stable F − K_{P,Z} H"]:
    если левый
    собственный вектор $w$
    замкнутого контура с $|λ| >= 1$ обращает в ноль весь вес, то
    $w K_p R K_p† w† = 0 => w K_p = 0$ ($R$ положительно определена) и
    $w Z w† = 0 => w Z = 0$ ($Z$ неотрицательно определена), откуда
    $w (A - K_p H) = w A$, т.е. $w A = λ w$ с $w Z = 0$ - противоречие со
    стабилизируемостью $(A, Z)$.

    В связке с `lyap_inv_spec_rad_stab` это даёт устойчивость по Шуру
    предсказательного контура $F_p = F - F K_f H$, из стабилизируемости пары
    $(F, G Q^(1/2))$.
  *)
  Lemma stabilizable_oi_reduce n p (A : 'M[ℂ]_n.+1) (Kp : 'M[ℂ]_(n.+1, p))
      (Hm : 'M[ℂ]_(p, n.+1)) (Z : 'M[ℂ]_n.+1) (R : 'M[ℂ]_p) :
    psd Z -> pd R ->
    stabilizable A Z ->
    stabilizable (A - Kp *m Hm) (Kp *m R *m Kp^t* + Z).
  Proof.
    move=> Zpsd R_pd HAZ lam w wNZ wFp lam_ge1.
    apply/negP=> /eqP wW0.
    set v := w^t*.
    have KRpsd : psd (Kp *m R *m Kp^t*) := psd_lcongr Kp (pd_psd R_pd).
    have qfW0 : \tr (v^t* *m (Kp *m R *m Kp^t* + Z) *m v) = 0.
      by rewrite /v trmxCK wW0 mul0mx mxtrace0.
    have split0 : \tr (v^t* *m (Kp *m R *m Kp^t*) *m v) = 0
              /\ \tr (v^t* *m Z *m v) = 0.
      move: qfW0; rewrite mulmxDr mulmxDl mxtraceD => /eqP.
      have hKR : 0 <= \tr (v^t* *m (Kp *m R *m Kp^t*) *m v)
        by case: KRpsd => _ /(_ v).
      have hZ : 0 <= \tr (v^t* *m Z *m v) by case: Zpsd => _ /(_ v).
      by rewrite paddr_eq0 // => /andP[/eqP ? /eqP ?].
    have wZ0 : w *m Z = 0.
      have Zv0 : Z *m v = 0 := psd_qf0_mul0 Zpsd (proj2 split0).
      have e : w *m Z = (Z *m v)^t* by rewrite /v trmxC_mul trmxCK -(proj1 Zpsd).
      by rewrite e Zv0 trmxC0.
    have wKp0 : w *m Kp = 0.
      set u := Kp^t* *m v.
      have qfu : \tr (u^t* *m R *m u) = 0.
        by rewrite -(proj1 split0) /u trmxC_mul trmxCK !mulmxA.
      have u0 : u = 0 := pd_qf0_col0 R_pd qfu.
      have e : (w *m Kp)^t* = 0 by rewrite trmxC_mul -/v -/u u0.
      by rewrite -(trmxCK (w *m Kp)) e trmxC0.
    have wA : w *m A = lam *: w.
      have h := wFp; rewrite mulmxBr mulmxA wKp0 mul0mx subr0 in h; exact: h.
    by have := HAZ lam w wNZ wA lam_ge1; rewrite wZ0 eqxx.
  Qed.

End LyapInv.
