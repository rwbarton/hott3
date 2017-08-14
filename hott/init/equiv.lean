/-
Copyright (c) 2014 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Jeremy Avigad, Jakob von Raumer, Floris van Doorn

Ported from Coq HoTT
-/
import hott.init.path hott.init.rewrite

universes u v w
hott_theory

namespace hott
open function

/- Equivalences -/

-- This is our @[hott] def of equivalence. In the HoTT-book it's called
-- ihae (half-adjoint equivalence).
class is_equiv {A : Type u} {B : Type v} (f : A → B) := mk' ::
(inv : B → A)
(right_inv : Πb, f (inv b) = b)
(left_inv : Πa, inv (f a) = a)
(adj : Πx, right_inv (f x) = ap f (left_inv x))

attribute [reducible] is_equiv.inv

-- A more bundled version of equivalence
structure equiv (A : Type u) (B : Type v) :=
  (to_fun : A → B)
  (to_is_equiv : is_equiv to_fun)

namespace is_equiv
  /- Some instances and closure properties of equivalences -/
  postfix ⁻¹ := inv
  /- a second notation for the inverse, which is not overloaded -/
  postfix [parsing_only] `⁻¹ᶠ`:std.prec.max_plus := inv

  section
  variables {A : Type u} {B : Type v} {C : Type w} (g : B → C) (f : A → B) {f' : A → B}

  -- The variant of mk' where f is explicit.
  @[hott] protected def mk := @is_equiv.mk' A B f

  -- The identity function is an equivalence.
  instance is_equiv_id (A : Type v) : (is_equiv (id : A → A)) :=
  is_equiv.mk id id (λa, idp) (λa, idp) (λa, idp)

  -- The composition of two equivalences is, again, an equivalence.
  @[hott, instance] def is_equiv_compose [Hf : is_equiv f] [Hg : is_equiv g]
    : is_equiv (g ∘ f) :=
  is_equiv.mk (g ∘ f) (f⁻¹ ∘ g⁻¹)
    begin intro c, apply (⬝), tactic.swap,
      apply right_inv g, apply ap g, apply right_inv f end
    begin intro a, simp [(∘)], apply (⬝),
      {apply ap (inv f), apply left_inv g}, {apply left_inv} end
    begin abstract { exact  (λa, (whisker_left _ (adj g (f a))) ⬝
        (ap_con g _ _)⁻¹ ⬝
        ap02 g ((ap_con_eq_con (right_inv f) (left_inv g (f a)))⁻¹ ⬝
                (ap_compose f (inv f) _ ◾  adj f a) ⬝
                (ap_con f _ _)⁻¹
                ) ⬝
        (ap_compose g f _)⁻¹) } end

  -- Any function equal to an equivalence is an equivlance as well.
  @[hott] def is_equiv_eq_closed {f : A → B} [Hf : is_equiv f] (Heq : f = f') : is_equiv f' :=
  eq.rec_on Heq Hf
  end

  section
  parameters {A : Type u} {B : Type v} (f : A → B) (g : B → A)
            (ret : Πb, f (g b) = b) (sec : Πa, g (f a) = a)

  @[hott] def adjointify_left_inv' (a : A) : g (f a) = a :=
  ap g (ap f (inverse (sec a))) ⬝ ap g (ret (f a)) ⬝ sec a

  def adjointify_adj' (a : A) : ret (f a) = ap f (adjointify_left_inv' a) :=
  let fgretrfa := ap f (ap g (ret (f a))) in
  let fgfinvsect := ap f (ap g (ap f (sec a)⁻¹)) in
  let fgfa := f (g (f a)) in
  let retrfa := ret (f a) in
  have eq1 : ap f (sec a) = _,
    from calc ap f (sec a)
          = idp ⬝ ap f (sec a)                                     : by rwr idp_con
      ... = (ret (f a) ⬝ (ret (f a))⁻¹) ⬝ ap f (sec a)             : by rwr con.right_inv
      ... = ((ret fgfa)⁻¹ ⬝ ((ap (f ∘ g) (ret (f a))) : _)) ⬝ ap f (sec a) :
          by rwr con_ap_eq_con (λ x, (ret x)⁻¹)
      ... = ((ret fgfa)⁻¹ ⬝ fgretrfa) ⬝ ap f (sec a)               : by rwr ap_compose
      ... = (ret fgfa)⁻¹ ⬝ (fgretrfa ⬝ ap f (sec a))               : by rwr con.assoc,
  have eq2 : ap f (sec a) ⬝ idp = (ret fgfa)⁻¹ ⬝ (fgretrfa ⬝ ap f (sec a)),
    from con_idp _ ⬝ eq1,
  have eq3 : idp = _,
    from calc idp
          = (ap f (sec a))⁻¹ ⬝ ((ret fgfa)⁻¹ ⬝ (fgretrfa ⬝ ap f (sec a))) : eq_inv_con_of_con_eq eq2
      ... = ((ap f (sec a))⁻¹ ⬝ (ret fgfa)⁻¹) ⬝ (fgretrfa ⬝ ap f (sec a)) : by rwr con.assoc'
      ... = (ap f (sec a)⁻¹ ⬝ (ret fgfa)⁻¹) ⬝ (fgretrfa ⬝ ap f (sec a))   : by rwr ap_inv
      ... = ((ap f (sec a)⁻¹ ⬝ (ret fgfa)⁻¹) ⬝ fgretrfa) ⬝ ap f (sec a)   : by rwr con.assoc'
      ... = ((retrfa⁻¹ ⬝ (ap (f ∘ g) (ap f (sec a)⁻¹): _)) ⬝ fgretrfa) ⬝ ap f (sec a) :
         by rwr con_ap_eq_con (λ x, (ret x)⁻¹: _)
      ... = ((retrfa⁻¹ ⬝ fgfinvsect) ⬝ fgretrfa) ⬝ ap f (sec a)           : by rwr ap_compose
      ... = (retrfa⁻¹ ⬝ (fgfinvsect ⬝ fgretrfa)) ⬝ ap f (sec a)           : by rwr con.assoc'
      ... = retrfa⁻¹ ⬝ ap f (ap g (ap f (sec a)⁻¹) ⬝ ap g (ret (f a))) ⬝ ap f (sec a)   : by rwr ap_con
      ... = retrfa⁻¹ ⬝ (ap f (ap g (ap f (sec a)⁻¹) ⬝ ap g (ret (f a))) ⬝ ap f (sec a)) : by rwr con.assoc'
      ... = retrfa⁻¹ ⬝ ap f ((ap g (ap f (sec a)⁻¹) ⬝ ap g (ret (f a))) ⬝ sec a)        : by rwr (ap_con _ _ _).symm,
  show ret (f a) = ap f ((ap g (ap f (sec a)⁻¹) ⬝ ap g (ret (f a))) ⬝ sec a),
    from eq_of_idp_eq_inv_con eq3

  @[hott] def adjointify : is_equiv f :=
  is_equiv.mk f g ret adjointify_left_inv' adjointify_adj'
  end

  -- Any function pointwise equal to an equivalence is an equivalence as well.
  @[hott] def homotopy_closed {A B : Type _} (f : A → B) {f' : A → B} [Hf : is_equiv f]
    (Hty : f ~ f') : is_equiv f' :=
  adjointify f'
             (inv f)
             (λ b, (Hty (inv f b))⁻¹ ⬝ right_inv f b)
             (λ a, (ap (inv f) (Hty a))⁻¹ ⬝ left_inv f a)

  @[hott] def inv_homotopy_closed {A B : Type _} {f : A → B} {f' : B → A}
    [Hf : is_equiv f] (Hty : inv f ~ f') : is_equiv f :=
  adjointify f
             f'
             (λ b, ap f (Hty _)⁻¹ ⬝ right_inv f b)
             (λ a, (Hty _)⁻¹ ⬝ left_inv f a)

  @[hott] def inv_homotopy_inv {A B : Type _} {f g : A → B} [is_equiv f] [is_equiv g] (p : f ~ g)
    : inv f ~ inv g :=
  λb, (left_inv g (f⁻¹ b))⁻¹ ⬝ ap g⁻¹ ((p (f⁻¹ b))⁻¹ ⬝ right_inv f b)

  instance is_equiv_up (A : Type _)
    : is_equiv (ulift.up : A → ulift A) :=
  adjointify ulift.up ulift.down (λa, by induction a;reflexivity) (λa, idp)

  section
  variables {A : Type _} {B: Type _} {C : Type _} (f : A → B) {f' : A → B} [Hf : is_equiv f] (g : B → C)
  include Hf

  -- The function equiv_rect says that given an equivalence f : A → B,
  -- and a hypothesis from B, one may always assume that the hypothesis
  -- is in the image of e.

  -- In fibrational terms, if we have a fibration over B which has a section
  -- once pulled back along an equivalence f : A → B, then it has a section
  -- over all of B.

  @[hott] def is_equiv_rect (P : B → Type _) (g : Πa, P (f a)) (b : B) : P b :=
  right_inv f b ▸ g (f⁻¹ b)

  @[hott] def is_equiv_rect' (P : A → B → Type _) (g : Πb, P (f⁻¹ b) b) (a : A) : P a (f a) :=
  (transport (λ x, P x (f a)) (left_inv f a) (g (f a)): _)

  @[hott] def is_equiv_rect_comp (P : B → Type _)
      (df : Π (x : A), P (f x)) (x : A) : is_equiv_rect f P df (f x) = df x :=
  calc
    is_equiv_rect f P df (f x)
          = right_inv f (f x) ▸ df (f⁻¹ (f x))   : by refl
      ... = ap f (left_inv f x) ▸ df (f⁻¹ (f x)) : by rwr adj
      ... = (transport (P∘f) (left_inv f x: _) (df (f⁻¹ (f x))): _) : by rwr tr_compose
      ... = df x                                 : by rwr (apdt df (left_inv f x))

  @[hott]
  def adj_inv (b : B) : left_inv f (f⁻¹ b) = ap f⁻¹ (right_inv f b) :=
  (is_equiv_rect f (λ fa, left_inv f (f⁻¹ fa) = ap f⁻¹ (right_inv f fa))
    (λa, (eq.cancel_right (left_inv f (id a): _): _)
           (whisker_left _ (ap_id _)⁻¹ᵖ ⬝ (ap_con_eq_con_ap (left_inv f) (left_inv f a))⁻¹) ⬝
      ap_compose _ _ _ ⬝ (ap02 f⁻¹ (adj f a)⁻¹): _)
    b: _)

  --The inverse of an equivalence is, again, an equivalence.
  @[instance,hott] def is_equiv_inv : is_equiv f⁻¹ :=
  is_equiv.mk f⁻¹ f (left_inv f) (right_inv f) (adj_inv f)

  -- The 2-out-of-3 properties
  @[hott] def cancel_right (g : B → C) [Hgf : is_equiv (g ∘ f)] : (is_equiv g) :=
  have Hfinv : is_equiv f⁻¹, from is_equiv_inv f,
  @homotopy_closed _ _ _ _ (is_equiv_compose (g ∘ f) f⁻¹) (λb, (ap g (@right_inv _ _ f _ b): _))

  @[hott] def cancel_left (g : C → A) [Hgf : is_equiv (f ∘ g)] : (is_equiv g) :=
  have Hfinv : is_equiv f⁻¹, from is_equiv_inv f,
  @homotopy_closed _ _ _ _ (is_equiv_compose f⁻¹ (f ∘ g)) (λa, left_inv f (g a))

  @[hott] def eq_of_fn_eq_fn' {x y : A} (q : f x = f y) : x = y :=
  (left_inv f x)⁻¹ ⬝ ap f⁻¹ q ⬝ left_inv f y

  @[hott] def ap_eq_of_fn_eq_fn' {x y : A} (q : f x = f y) : ap f (eq_of_fn_eq_fn' f q) = q :=
  ap_con _ _ _ ⬝ whisker_right _ (ap_con _ _ _)
          ⬝ ((ap_inv _ _ ⬝ inverse2 (adj f _)⁻¹)
            ◾ (inverse (ap_compose f f⁻¹ _))
            ◾ (adj f _)⁻¹)
          ⬝ con_ap_con_eq_con_con (right_inv f) _ _
          ⬝ whisker_right _ (con.left_inv _)
          ⬝ !idp_con

  @[hott] def eq_of_fn_eq_fn'_ap {x y : A} (q : x = y) : eq_of_fn_eq_fn' f (ap f q) = q :=
  by induction q; apply con.left_inv

  @[instance,hott] def is_equiv_ap (x y : A) : is_equiv (ap f : x = y → f x = f y) :=
  adjointify
    (ap f)
    (eq_of_fn_eq_fn' f)
    (ap_eq_of_fn_eq_fn' f)
    (eq_of_fn_eq_fn'_ap f)

  end

  section
  variables {A : Type u} {B : Type v} {C : Type w} {f : A → B} [Hf : is_equiv f]
  include Hf

  section rewrite_rules
    variables {a : A} {b : B}
    @[hott] def eq_of_eq_inv (p : a = f⁻¹ b) : f a = b :=
    ap f p ⬝ right_inv f b

    @[hott] def eq_of_inv_eq (p : f⁻¹ b = a) : b = f a :=
    (eq_of_eq_inv p⁻¹)⁻¹

    @[hott] def inv_eq_of_eq (p : b = f a) : f⁻¹ b = a :=
    ap f⁻¹ p ⬝ left_inv f a

    @[hott] def eq_inv_of_eq (p : f a = b) : a = f⁻¹ b :=
    (inv_eq_of_eq p⁻¹)⁻¹
  end rewrite_rules

  variable (f)

  section pre_compose
    variables (α : A → C) (β : B → C)

    @[hott] def homotopy_of_homotopy_inv_pre (p : β ~ α ∘ f⁻¹) : β ∘ f ~ α :=
    λ a, p (f a) ⬝ ap α (left_inv f a)

    @[hott] def homotopy_of_inv_homotopy_pre (p : α ∘ f⁻¹ ~ β) : α ~ β ∘ f :=
    λ a, (ap α (left_inv f a))⁻¹ ⬝ p (f a)

    @[hott] def inv_homotopy_of_homotopy_pre (p : α ~ β ∘ f) : α ∘ f⁻¹ ~ β :=
    λ b, p (f⁻¹ b) ⬝ ap β (right_inv f b)

    @[hott] def homotopy_inv_of_homotopy_pre (p : β ∘ f ~ α) : β ~ α ∘ f⁻¹  :=
    λ b, (ap β (right_inv f b))⁻¹ ⬝ p (f⁻¹ b)
  end pre_compose

  section post_compose
    variables (α : C → A) (β : C → B)

    @[hott] def homotopy_of_homotopy_inv_post (p : α ~ f⁻¹ ∘ β) : f ∘ α ~ β :=
    λ c, (ap f (p c): _) ⬝ (right_inv f (β c): _)

    @[hott] def homotopy_of_inv_homotopy_post (p : f⁻¹ ∘ β ~ α) : β ~ f ∘ α :=
    λ c, (right_inv f (β c))⁻¹ ⬝ ap f (p c)

    @[hott] def inv_homotopy_of_homotopy_post (p : β ~ f ∘ α) : f⁻¹ ∘ β ~ α :=
    λ c, (ap f⁻¹ (p c): _) ⬝ (left_inv f (α c))

    @[hott] def homotopy_inv_of_homotopy_post (p : f ∘ α ~ β) : α ~ f⁻¹ ∘ β :=
    λ c, (left_inv f (α c))⁻¹ ⬝ ap f⁻¹ (p c)
  end post_compose

  end

  --Transporting is an equivalence
  @[hott] def is_equiv_tr {A : Type u} (P : A → Type v) {x y : A}
    (p : x = y) : (is_equiv (transport P p)) :=
  is_equiv.mk _ (transport P p⁻¹: _) (tr_inv_tr p) (inv_tr_tr p) (tr_inv_tr_lemma p)

  -- a version where the transport is a cast. Note: A and B live in the same universe here.
  @[hott, instance] def is_equiv_cast {A B : Type _} (H : A = B) : is_equiv (cast H) :=
  is_equiv_tr (λX, X) H

  section
  variables {A : Type _} {B : A → Type _} {C : A → Type _} (f : Π{a}, B a → C a) [H : Πa, is_equiv (@f a)]
            {g : A → A} {g' : A → A} (h : Π{a}, B (g' a) → B (g a)) (h' : Π{a}, C (g' a) → C (g a))

  include H
  @[hott] def inv_commute' (p : Π⦃a : A⦄ (b : B (g' a)), f (h b) = h' (f b)) {a : A}
    (c : C (g' a)) : f⁻¹ (h' c) = h (f⁻¹ c) :=
  eq_of_fn_eq_fn' f (right_inv f (h' c) ⬝ ap h' (right_inv f c)⁻¹ ⬝ (p (f⁻¹ c))⁻¹)

  @[hott] def fun_commute_of_inv_commute' (p : Π⦃a : A⦄ (c : C (g' a)), f⁻¹ (h' c) = h (f⁻¹ c))
    {a : A} (b : B (g' a)) : f (h b) = h' (f b) :=
  eq_of_fn_eq_fn' f⁻¹ (left_inv f (h b) ⬝ ap h (left_inv f b)⁻¹ ⬝ (p (f b))⁻¹)

  @[hott] def ap_inv_commute' (p : Π⦃a : A⦄ (b : B (g' a)), f (h b) = h' (f b)) {a : A}
    (c : C (g' a)) : ap f (inv_commute' @f @h @h' p c)
                       = right_inv f (h' c) ⬝ ap h' (right_inv f c)⁻¹ ⬝ (p (f⁻¹ c))⁻¹ :=
  ap_eq_of_fn_eq_fn' _ _

  -- inv_commute'_fn is in types.equiv
  end

  -- This is inv_commute' for A ≡ unit
  @[hott] def inv_commute1' {B C : Type _} (f : B → C) [is_equiv f] (h : B → B) (h' : C → C)
    (p : Π(b : B), f (h b) = h' (f b)) (c : C) : f⁻¹ (h' c) = h (f⁻¹ c) :=
  eq_of_fn_eq_fn' f (right_inv f (h' c) ⬝ ap h' (right_inv f c)⁻¹ ⬝ (p (f⁻¹ c))⁻¹)

end is_equiv
open is_equiv

namespace eq
  local attribute [instance] is_equiv_tr

  @[hott] def tr_inv_fn {A : Type _} {B : A → Type _} {a a' : A} (p : a = a') :
    transport B p⁻¹ = (transport B p)⁻¹ := idp
  @[hott] def tr_inv {A : Type _} {B : A → Type _} {a a' : A} (p : a = a') (b : B a') :
    p⁻¹ ▸ b = (transport B p)⁻¹ b := idp

  @[hott] def cast_inv_fn {A B : Type _} (p : A = B) : cast p⁻¹ = (cast p)⁻¹ := idp
  @[hott] def cast_inv {A B : Type _} (p : A = B) (b : B) : cast p⁻¹ b = (cast p)⁻¹ b := idp
end eq

infix ` ≃ `:25 := equiv
attribute [instance] equiv.to_is_equiv

namespace equiv
  section
  variables {A : Type u} {B : Type v} {C : Type w}

  instance: has_coe_to_fun (A ≃ B) := ⟨_, to_fun⟩

  open is_equiv

  @[hott] protected def MK (f : A → B) (g : B → A)
    (right_inv : Πb, f (g b) = b) (left_inv : Πa, g (f a) = a) : A ≃ B :=
  equiv.mk f (adjointify f g right_inv left_inv)

  @[hott] def to_inv  (f : A ≃ B) : B → A := (to_fun f)⁻¹
  @[hott] def to_right_inv (f : A ≃ B) (b : B) : f ((to_fun f)⁻¹ b) = b :=
  right_inv (to_fun f) b
  @[hott] def to_left_inv (f : A ≃ B) (a : A) : (to_fun f)⁻¹ (f a) = a :=
  left_inv (to_fun f) a

  @[refl, hott]
  protected def rfl : A ≃ A :=
  equiv.mk id (hott.is_equiv.is_equiv_id _)

  @[hott]
  protected def refl (A : Type _) : A ≃ A :=
  @equiv.rfl A

  @[symm, hott]
  protected def symm (f : A ≃ B) : B ≃ A :=
  equiv.mk (inv f.to_fun) (hott.is_equiv.is_equiv_inv f.to_fun)

  @[trans, hott]
  protected def trans (f : A ≃ B) (g : B ≃ C) : A ≃ C :=
  equiv.mk (to_fun g ∘ to_fun f) (is_equiv_compose _ _)

  infixl ` ⬝e `:75 := equiv.trans
  postfix `⁻¹ᵉ`:(max + 1) := equiv.symm
    -- notation for inverse which is not overloaded
  notation `erfl` := @equiv.rfl

  @[hott] def to_inv_trans (f : A ≃ B) (g : B ≃ C)
    : to_inv (f ⬝e g) = to_fun (g⁻¹ᵉ ⬝e f⁻¹ᵉ) :=
  idp

  @[hott,instance] def is_equiv_to_inv (f : A ≃ B) : is_equiv f.to_inv :=
  is_equiv.is_equiv_inv _

  @[hott] def equiv_change_fun (f : A ≃ B) {f' : A → B} (Heq : f.to_fun ~ f') : A ≃ B :=
  equiv.mk f' (is_equiv.homotopy_closed f.to_fun Heq)

  @[hott] def equiv_change_inv (f : A ≃ B) {f' : B → A} (Heq : f.to_inv ~ f')
    : A ≃ B :=
  equiv.mk f.to_fun (inv_homotopy_closed Heq)

  --rename: eq_equiv_fn_eq_fn_of_is_equiv
  @[hott] def eq_equiv_fn_eq (f : A → B) [H : is_equiv f] (a b : A) : (a = b) ≃ (f a = f b) :=
  equiv.mk (ap f) (is_equiv_ap _ _ _)

  --rename: eq_equiv_fn_eq_fn
  @[hott] def eq_equiv_fn_eq_of_equiv (f : A ≃ B) (a b : A) : (a = b) ≃ (f.to_fun a = f.to_fun b) :=
  equiv.mk (ap f.to_fun) (is_equiv_ap _ _ _)

  @[hott] def equiv_ap (P : A → Type _) {a b : A} (p : a = b) : P a ≃ P b :=
  equiv.mk (transport P p) (is_equiv_tr _ _)

  @[hott] def equiv_of_eq {A B : Type u} (p : A = B) : A ≃ B :=
  equiv.mk (cast p) (is_equiv_tr id _)

  @[hott] def equiv_of_eq_refl (A : Type _)
    : equiv_of_eq (refl A) = equiv.refl A :=
  idp

  @[hott] def eq_of_fn_eq_fn (f : A ≃ B) {x y : A} (q : f x = f y) : x = y :=
  (left_inv _ x)⁻¹ ⬝ ap f.to_fun⁻¹ q ⬝ left_inv _ y

  @[hott] def eq_of_fn_eq_fn_inv (f : A ≃ B) {x y : B} (q : f.to_fun⁻¹ x = f.to_fun⁻¹ y) : x = y :=
  (right_inv f.to_fun x)⁻¹ ⬝ ap f.to_fun q ⬝ right_inv f.to_fun y

  @[hott] def ap_eq_of_fn_eq_fn (f : A ≃ B) {x y : A} (q : f x = f y) : ap f.to_fun (eq_of_fn_eq_fn' f.to_fun q) = q :=
  ap_eq_of_fn_eq_fn' f.to_fun q

  @[hott] def eq_of_fn_eq_fn_ap (f : A ≃ B) {x y : A} (q : x = y) : eq_of_fn_eq_fn' f.to_fun (ap f.to_fun q) = q :=
  eq_of_fn_eq_fn'_ap f.to_fun q

  @[hott] def to_inv_homotopy_inv {f g : A ≃ B} (p : f.to_fun ~ g.to_fun) : f⁻¹ᵉ.to_fun ~ g⁻¹ᵉ.to_fun :=
  inv_homotopy_inv p

  --we need this theorem for the funext_of_ua proof
  @[hott] theorem inv_eq {A B : Type _} (eqf eqg : A ≃ B) (p : eqf = eqg) : (to_fun eqf)⁻¹ = (to_fun eqg)⁻¹ :=
  eq.rec_on p idp

  @[trans, hott]
  def equiv_of_equiv_of_eq {A B C : Type _} (p : A = B) (q : B ≃ C) : A ≃ C :=
  equiv_of_eq p ⬝e q
  @[trans, hott]
  def equiv_of_eq_of_equiv {A B C : Type _} (p : A ≃ B) (q : B = C) : A ≃ C :=
  p ⬝e equiv_of_eq q

  @[hott] def equiv_lift (A : Type _) : A ≃ ulift A := equiv.mk ulift.up (by apply_instance)

  @[hott] def equiv_rect (f : A ≃ B) (P : B → Type _) (g : Πa, P (f a)) (b : B) : P b :=
  right_inv f.to_fun b ▸ g (f.to_fun⁻¹ b)

  @[hott] def equiv_rect' (f : A ≃ B) (P : A → B → Type _) (g : Πb, P (f.to_fun⁻¹ b) b) (a : A) : P a (f a) :=
  (transport (λ x : A, P x (f a)) (left_inv f.to_fun a) (g (f a)): _)

  @[hott] def equiv_rect_comp (f : A ≃ B) (P : B → Type _)
      (df : Π (x : A), P (f x)) (x : A) : equiv_rect f P df (f x) = df x :=
    calc
      equiv_rect f P df (f x)
            = right_inv f.to_fun (f x) ▸ df (f.to_inv (f x))   : by refl
        ... = ap f.to_fun (left_inv f.to_fun x) ▸ df (f.to_inv (f x)) : by rwr (adj _ _).symm
        ... = (transport (P∘f.to_fun) (left_inv f.to_fun x: _) (df (f.to_inv (f x)): _): _) : by rwr tr_compose
        ... = df x                                 : by apply apdt df (left_inv f.to_fun x)
  end

  section

  variables {A : Type _} {B : Type _} (f : A ≃ B) {a : A} {b : B}
  @[hott] def to_eq_of_eq_inv (p : a = f.to_fun⁻¹ b) : f a = b :=
  ap f.to_fun p ⬝ right_inv f.to_fun b

  @[hott] def to_eq_of_inv_eq (p : f.to_fun⁻¹ b = a) : b = f a :=
  (eq_of_eq_inv p⁻¹)⁻¹

  @[hott] def to_inv_eq_of_eq (p : b = f a) : f.to_fun⁻¹ b = a :=
  ap f.to_fun⁻¹ p ⬝ left_inv f.to_fun a

  @[hott] def to_eq_inv_of_eq (p : f a = b) : a = f.to_fun⁻¹ b :=
  (inv_eq_of_eq p⁻¹)⁻¹

  end

  section

  variables {A : Type _} {B : A → Type _} {C : A → Type _} (f : Π{a}, B a ≃ C a)
            {g : A → A} {g' : A → A} (h : Π{a}, B (g' a) → B (g a)) (h' : Π{a}, C (g' a) → C (g a))

  @[hott] def inv_commute (p : Π⦃a : A⦄ (b : B (g' a)), f.to_fun (h b) = h' (f.to_fun b)) {a : A}
    (c : C (g' a)) : f.to_fun⁻¹ (h' c) = h (f.to_fun⁻¹ c) :=
  inv_commute' (λ a, f.to_fun) @h @h' p c

  @[hott] def fun_commute_of_inv_commute (p : Π⦃a : A⦄ (c : C (g' a)), f.to_inv (h' c) = h (f.to_inv c))
    {a : A} (b : B (g' a)) : f.to_fun (h b) = h' (f.to_fun b) :=
  fun_commute_of_inv_commute' (λ a, f.to_fun) @h @h' p b

  @[hott] def inv_commute1 {B C : Type _} (f : B ≃ C) (h : B → B) (h' : C → C)
    (p : Π(b : B), f (h b) =   h' (f b)) (c : C) : f.to_inv (h' c) = h (f.to_inv c) :=
  inv_commute1' (to_fun f) h h' p c

  end

  infixl ` ⬝pe `:75 := equiv_of_equiv_of_eq
  infixl ` ⬝ep `:75 := equiv_of_eq_of_equiv

end equiv

open equiv
namespace is_equiv

  @[hott] def is_equiv_of_equiv_of_homotopy {A B : Type _} (f : A ≃ B)
    {f' : A → B} (Hty : f.to_fun ~ f') : is_equiv f' :=
  @homotopy_closed _ _ f.to_fun f' _ Hty

end is_equiv

end hott