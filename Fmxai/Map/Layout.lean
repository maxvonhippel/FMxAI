module
public import Fmxai.Map.Geometry
public import Fmxai.Map.Data
public import Fmxai.Map.Search
public import Fmxai.Map.Circles

/-!
# The layout, its specification, and the proof that the solver meets it

`Layout.Valid` says what a truthful, legible map is:

* the circles are exactly the categories, and two categories that share no organisation
  have visibly separate circles;
* the organisations are exactly the organisations in the data, in order; every dot lies well
  inside each circle its organisation belongs to and well outside every other; dots are far
  enough apart and their labels never touch;
* the labels are exactly the categories; no label touches a circle and no two labels touch.

`solve` computes a layout. `solve_valid` proves that anything it returns is `Valid`. There is
no step where a layout is checked after the fact: the guarantee comes from how the candidates
are generated (`List.mem_filter`) and from the search's theorems (`Fmxai.Map.Search`). The
only run-time check is on the circle simulation, which has no specification of its own.
-/

namespace Fmxai.Map

@[expose] public section

/-! ## Constants (pixels) -/

/-- A dot must be this far inside each of its circles. -/
def orgInMargin : Int := 15
/-- A dot must be this far outside every other circle. -/
def orgOutMargin : Int := 25
/-- Minimum distance between dots. -/
def dotMinDist : Int := 40
/-- Minimum gap between organisation labels. -/
def orgLabelPad : Int := 5
/-- Minimum gap between category labels. -/
def catLabelPad : Int := 20
/-- Minimum gap between circles of categories that share no organisation. -/
def circleGap : Int := 40
/-- Grid resolution for dot candidates. -/
def gridStep : Int := 15
/-- How many candidates to keep per organisation. -/
def orgCandidateLimit : Nat := 150
/-- How far outside its circle a category label sits. -/
def labelDistance : Int := 70
/-- How many directions to try for a category label. -/
def labelDirections : Nat := 32

/-! ## The predicates -/

/-- The dot is inside exactly the organisation's circles, with the margins widened by `m`. -/
def dotDeep (circles : List (Category × Circle)) (o : Org) (m : Int) (p : Pt) : Bool :=
  circles.all fun x =>
    if o.inCat x.1 then p.insideBy x.2 (orgInMargin + m) else p.outsideBy x.2 (orgOutMargin + m)

/-- The dot is inside exactly the organisation's circles. -/
def dotOk (circles : List (Category × Circle)) (o : Org) (p : Pt) : Bool :=
  dotDeep circles o 0 p

/-- Two placed organisations do not crowd each other. -/
def orgsOk (a b : Org × Pt) : Bool :=
  a.2.apartBy b.2 dotMinDist &&
    (orgLabelBox a.1.name.length a.2).disjointBy (orgLabelBox b.1.name.length b.2) orgLabelPad

/-- The label touches no circle. -/
def labelOk (circles : List (Category × Circle)) (c : Category) (p : Pt) : Bool :=
  circles.all fun x => !(catLabelBox c.name.length p).meetsCircle x.2

/-- Two labels do not touch. -/
def labelsOk (a b : Category × Pt) : Bool :=
  (catLabelBox a.1.name.length a.2).disjointBy (catLabelBox b.1.name.length b.2) catLabelPad

/-- Two circles may overlap only if some organisation is in both. -/
def circlePairOk (os : List Org) (a b : Category × Circle) : Bool :=
  Category.shares os a.1 b.1 || a.2.disjointBy b.2 circleGap

/-- `Bool` pairwise check, for the run-time check on circles. -/
def pairwiseB {α : Type} (f : α → α → Bool) : List α → Bool
  | [] => true
  | x :: xs => xs.all (f x) && pairwiseB f xs

/-! ## Ordering

The search places the most constrained organisations first, which is what keeps it from
backtracking through the easy ones. Insertion sort is structural, so it reduces in the kernel. -/

/-- Inserts into a list sorted ascending by `key`. -/
def insertBy {α : Type} (key : α → Nat) (x : α) : List α → List α
  | [] => [x]
  | y :: ys => if key x ≤ key y then x :: y :: ys else y :: insertBy key x ys

/-- Sorts ascending by `key`. -/
def sortBy {α : Type} (key : α → Nat) : List α → List α
  | [] => []
  | x :: xs => insertBy key x (sortBy key xs)

/-! ## Candidates -/

/-- `lo, lo + step, …` up to `hi`. -/
def gridRange (lo hi step : Int) : List Int :=
  (List.range (((hi - lo) / step).toNat + 1)).map fun i => lo + step * Int.ofNat i

/-- Grid points over the bounding box of the organisation's circles. -/
def grid (circles : List (Category × Circle)) (o : Org) : List Pt :=
  let req := (circles.filter fun x => o.inCat x.1).map Prod.snd
  match req with
  | [] => []
  | c :: cs =>
    let minX := (cs.map fun c => c.center.x - c.r).foldl min (c.center.x - c.r)
    let maxX := (cs.map fun c => c.center.x + c.r).foldl max (c.center.x + c.r)
    let minY := (cs.map fun c => c.center.y - c.r).foldl min (c.center.y - c.r)
    let maxY := (cs.map fun c => c.center.y + c.r).foldl max (c.center.y + c.r)
    (gridRange minX maxX gridStep).flatMap fun x => (gridRange minY maxY gridStep).map fun y => ⟨x, y⟩

/-- Depth buckets, deepest first: candidates far from every edge are tried first. -/
def depthBuckets : List Int := [75, 60, 45, 30, 15, 0]

/-- Where an organisation's dot may go: the valid grid points, deepest first, capped. -/
def orgCandidates (circles : List (Category × Circle)) (o : Org) : List Pt :=
  let valid := (grid circles o).filter (dotOk circles o)
  let ordered := depthBuckets.flatMap fun m =>
    valid.filter fun p => dotDeep circles o m p && (m ≥ 75 || !dotDeep circles o (m + 15) p)
  ordered.take orgCandidateLimit

/-- Where a category's label may go: points on a ring around its circle, from which the
label's box touches no circle. -/
def labelCandidates (circles : List (Category × Circle)) (c : Category) : List Pt :=
  match circles.find? fun x => x.1 = c with
  | none => []
  | some x =>
    let ring := (List.range labelDirections).map fun i =>
      let a := 3600 * i / labelDirections
      let d := x.2.r + labelDistance
      (⟨x.2.center.x + d * cosMilli a / 1000, x.2.center.y + d * sinMilli a / 1000⟩ : Pt)
    ring.filter (labelOk circles c)

/-! ## The layout -/

/-- A finished map. -/
structure Layout where
  /-- The category circles. -/
  circles : List (Category × Circle)
  /-- Each organisation and its dot. -/
  orgs : List (Org × Pt)
  /-- Each category and its label anchor. -/
  labels : List (Category × Pt)
  deriving Repr

/-- What a truthful, legible map is. -/
structure Layout.Valid (os : List Org) (l : Layout) : Prop where
  /-- One circle per category, in order. -/
  circles_cats : l.circles.map Prod.fst = Category.all
  /-- Circles overlap only when they share an organisation. -/
  circles_apart : l.circles.Pairwise fun a b => circlePairOk os a b = true
  /-- One dot per organisation: the dots are tagged with exactly the organisations. -/
  orgs_all : (l.orgs.map Prod.fst).Perm os
  /-- Every dot is inside exactly its organisation's circles. -/
  orgs_in : ∀ x ∈ l.orgs, dotOk l.circles x.1 x.2 = true
  /-- Dots are apart and their labels do not touch. -/
  orgs_apart : l.orgs.Pairwise fun a b => orgsOk a b = true
  /-- One label per category, in order. -/
  labels_cats : l.labels.map Prod.fst = Category.all
  /-- No label touches a circle. -/
  labels_clear : ∀ x ∈ l.labels, labelOk l.circles x.1 x.2 = true
  /-- No two labels touch. -/
  labels_apart : l.labels.Pairwise fun a b => labelsOk a b = true

/-- The organisations, most constrained first. -/
def orderedOrgs (circles : List (Category × Circle)) (os : List Org) : List Org :=
  sortBy (fun o => (orgCandidates circles o).length) os

/-- Lays out organisations and labels for given circles. -/
def solveWith (os : List Org) (circles : List (Category × Circle)) : Option Layout :=
  if pairwiseB (circlePairOk os) circles then
    match choose orgsOk ((orderedOrgs circles os).map fun o =>
        (orgCandidates circles o).map fun p => (o, p)) [] with
    | none => none
    | some orgSel =>
      match choose labelsOk
          (Category.all.map fun c => (labelCandidates circles c).map fun p => (c, p)) [] with
      | none => none
      | some labelSel => some { circles, orgs := orgSel.reverse, labels := labelSel.reverse }
  else none

/-- Lays out the map, or fails if the data cannot be drawn truthfully. -/
def solve (os : List Org) : Option Layout := solveWith os (circleLayout os)

end

/-! ## Lemmas -/

theorem pairwiseB_iff {α : Type} (f : α → α → Bool) (l : List α) :
    pairwiseB f l = true ↔ l.Pairwise fun a b => f a b = true := by
  induction l with
  | nil => simp [pairwiseB]
  | cons x xs ih => simp [pairwiseB, ih, List.pairwise_cons]

theorem insertBy_perm {α : Type} (key : α → Nat) (x : α) (l : List α) :
    (insertBy key x l).Perm (x :: l) := by
  induction l with
  | nil => exact List.Perm.refl _
  | cons y ys ih =>
    simp only [insertBy]
    split
    · exact List.Perm.refl _
    · exact (List.Perm.cons y ih).trans (List.Perm.swap x y ys)

theorem sortBy_perm {α : Type} (key : α → Nat) (l : List α) : (sortBy key l).Perm l := by
  induction l with
  | nil => exact List.Perm.refl _
  | cons x xs ih => exact (insertBy_perm key x _).trans (List.Perm.cons x ih)

theorem orgsOk_comm (a b : Org × Pt) : orgsOk a b = orgsOk b a := by
  simp only [orgsOk]
  rw [Pt.apartBy_comm, Box.disjointBy_comm]

theorem labelsOk_comm (a b : Category × Pt) : labelsOk a b = labelsOk b a := by
  simp only [labelsOk]
  rw [Box.disjointBy_comm]

theorem mem_orgCandidates {circles : List (Category × Circle)} {o : Org} {p : Pt}
    (h : p ∈ orgCandidates circles o) : dotOk circles o p = true := by
  simp only [orgCandidates] at h
  have h1 := List.mem_of_mem_take h
  obtain ⟨_, _, h2⟩ := List.mem_flatMap.mp h1
  exact (List.mem_filter.mp (List.mem_filter.mp h2).1).2

theorem mem_labelCandidates {circles : List (Category × Circle)} {c : Category} {p : Pt}
    (h : p ∈ labelCandidates circles c) : labelOk circles c p = true := by
  simp only [labelCandidates] at h
  split at h
  · simp at h
  · exact (List.mem_filter.mp h).2

/-- A pick from tagged candidate lists is a tagged candidate. -/
theorem mem_tagged {ι α : Type} {cand : ι → List α} {items : List ι} {x : ι × α}
    (h : ∃ l ∈ items.map (fun i => (cand i).map fun p => (i, p)), x ∈ l) : x.2 ∈ cand x.1 := by
  obtain ⟨l, hl, hx⟩ := h
  obtain ⟨i, _, rfl⟩ := List.mem_map.mp hl
  obtain ⟨p, hp, rfl⟩ := List.mem_map.mp hx
  exact hp

/-- **Whatever `solve` returns is a valid map.** -/
public theorem solve_valid (os : List Org) (l : Layout) (h : solve os = some l) : l.Valid os := by
  have hcats := circleLayout_cats os
  unfold solve solveWith at h
  -- Keep the simulation opaque: the unifier must never try to evaluate it.
  generalize circleLayout os = circles at h hcats
  split at h
  · rename_i hcirc
    split at h
    · simp at h
    · rename_i orgSel horg
      split at h
      · simp at h
      · rename_i labelSel hlabel
        simp only [Option.some.injEq] at h
        subst h
        have horgFst := choose_map orgsOk (orgCandidates circles) _ [] orgSel horg
        have hlabFst := choose_map labelsOk (labelCandidates circles) Category.all []
          labelSel hlabel
        refine ⟨hcats, (pairwiseB_iff _ _).mp hcirc, ?_, ?_, ?_, ?_, ?_, ?_⟩
        · show (orgSel.reverse.map Prod.fst).Perm os
          rw [List.map_reverse, horgFst, List.map_nil, List.append_nil, List.reverse_reverse]
          exact sortBy_perm _ os
        · intro x hx
          rw [List.mem_reverse] at hx
          rcases choose_mem orgsOk _ [] orgSel horg x hx with hnil | hmem
          · simp at hnil
          · exact mem_orgCandidates (mem_tagged hmem)
        · rw [List.pairwise_reverse]
          exact (choose_pairwise orgsOk _ [] orgSel horg List.Pairwise.nil).imp fun h => by
            rw [orgsOk_comm]; exact h
        · show labelSel.reverse.map Prod.fst = Category.all
          rw [List.map_reverse, hlabFst, List.map_nil, List.append_nil, List.reverse_reverse]
        · intro x hx
          rw [List.mem_reverse] at hx
          rcases choose_mem labelsOk _ [] labelSel hlabel x hx with hnil | hmem
          · simp at hnil
          · exact mem_labelCandidates (mem_tagged hmem)
        · rw [List.pairwise_reverse]
          exact (choose_pairwise labelsOk _ [] labelSel hlabel List.Pairwise.nil).imp fun h => by
            rw [labelsOk_comm]; exact h
  · simp at h

end Fmxai.Map
