module
public import Fmxai.Map.Geometry
public import Fmxai.Map.Data

/-!
# Placing the category circles

A port of the force simulation the JavaScript ran, in fixed-point integer arithmetic
(positions in thousandths of a pixel) so that it is deterministic, total and reducible in
the kernel. Circles that share an organisation attract each other to a target overlap;
circles that share none repel until they are well apart.

Nothing here is part of the specification. What the simulation produces is *checked*
afterwards (`Fmxai.Map.circlePairOk` in `Fmxai.Map.Layout`): if it ever placed two
unrelated circles too close, the build fails rather than draw a misleading map.
-/

namespace Fmxai.Map

@[expose] public section

/-- Integer square root by binary search over 32 bits (enough for the squared distances
here, which stay below `2^60`... the result is at most `2^32`). Structural, no fuel needed
beyond the bit count. -/
def isqrt (n : Nat) : Nat := go 32 0
where
  /-- Sets the bits of the root from high to low. -/
  go : Nat → Nat → Nat
    | 0, acc => acc
    | k + 1, acc => let cand := acc + 2 ^ k; if cand * cand ≤ n then go k cand else go k acc

/-- Bhāskara's rational approximation of the sine, on angles in tenths of a degree, scaled
by 1000. Accurate to about two parts in a thousand, which is plenty for placing circles. -/
def sinMilli (x : Nat) : Int :=
  let x := x % 3600
  if x ≤ 1800 then half x else -(half (x - 1800))
where
  /-- The approximation on `[0, 180°]`. -/
  half (x : Nat) : Int :=
    ((16 * x * (1800 - x) * 1000) / (5 * 1800 * 1800 - 4 * x * (1800 - x)) : Nat)

/-- Cosine, from the sine. -/
def cosMilli (x : Nat) : Int := sinMilli (x + 900)

/-- A circle while it is being laid out: position in milli-pixels, radius in pixels. -/
structure CircleState where
  /-- Which category. -/
  cat : Category
  /-- Horizontal position, milli-pixels. -/
  x : Int
  /-- Vertical position, milli-pixels. -/
  y : Int
  /-- Radius, pixels. -/
  r : Int
  deriving Repr

/-- The index of a category in `Category.all`, for the initial angle. -/
def Category.index : Category → Nat
  | .mathematics => 0 | .securePS => 1 | .legalTech => 2
  | .accelerator => 3 | .models => 4 | .researchLab => 5

/-- How many organisations are in a category. -/
def Category.count (os : List Org) (c : Category) : Nat :=
  (os.filter fun o => o.inCat c).length

/-- A circle's radius grows with its population: 80px for an empty one, 160px for the
fullest. -/
def Category.radius (os : List Org) (c : Category) : Int :=
  let maxCount := (Category.all.map (Category.count os)).foldl max 1
  80 + (80 * c.count os) / maxCount

/-- The width and height of the canvas the JavaScript used. -/
def canvasW : Int := 1000
/-- See `canvasW`. -/
def canvasH : Int := 800

/-- Circles start on a ring around the centre. -/
def initial (os : List Org) : List CircleState :=
  Category.all.map fun c =>
    let angle := 3600 * c.index / Category.all.length
    { cat := c
      x := canvasW * 500 + 150 * cosMilli angle
      y := canvasH * 500 + 150 * sinMilli angle
      r := c.radius os }

/-- The force `b` exerts on `a`, in milli-pixels. -/
def force (os : List Org) (a b : CircleState) : Int × Int :=
  let dx := b.x - a.x
  let dy := b.y - a.y
  let d : Int := max 1 (isqrt (dx * dx + dy * dy).toNat)
  if Category.shares os a.cat b.cat then
    -- Attract towards an overlap: distance = 0.7 × (rᵢ + rⱼ), gain 0.02.
    let target := (a.r + b.r) * 700
    let f := (d - target) / 50
    (dx * f / d, dy * f / d)
  else
    -- Repel until the gap is 180px, gain 0.03.
    let minSep := (a.r + b.r + 180) * 1000
    if d < minSep then
      let f := (minSep - d) * 3 / 100
      (-(dx * f / d), -(dy * f / d))
    else (0, 0)

/-- One step of the simulation, damping 0.9. -/
def step (os : List Org) (cs : List CircleState) : List CircleState :=
  cs.map fun a =>
    let (fx, fy) := cs.foldl
      (fun (acc : Int × Int) b =>
        if b.cat = a.cat then acc
        else
          let (gx, gy) := force os a b
          (acc.1 + gx, acc.2 + gy))
      (0, 0)
    { a with x := a.x + fx * 9 / 10, y := a.y + fy * 9 / 10 }

/-- `k` steps. -/
def simulate (os : List Org) : Nat → List CircleState → List CircleState
  | 0, cs => cs
  | k + 1, cs => simulate os k (step os cs)

/-- The circles, in pixels, after 200 steps. -/
def circleLayout (os : List Org) : List (Category × Circle) :=
  (simulate os 200 (initial os)).map fun s => (s.cat, ⟨⟨s.x / 1000, s.y / 1000⟩, s.r⟩)

end

/-! ## The simulation moves circles; it never adds, drops or reorders them -/

theorem step_cats (os : List Org) (cs : List CircleState) :
    (step os cs).map CircleState.cat = cs.map CircleState.cat := by
  simp only [step, List.map_map]
  rfl

theorem simulate_cats (os : List Org) (k : Nat) (cs : List CircleState) :
    (simulate os k cs).map CircleState.cat = cs.map CircleState.cat := by
  induction k generalizing cs with
  | zero => rfl
  | succ k ih => simp only [simulate, ih, step_cats]

theorem initial_cats (os : List Org) : (initial os).map CircleState.cat = Category.all := by
  simp only [initial, List.map_map]
  rfl

/-- The circle list is indexed by exactly `Category.all`, in order. -/
public theorem circleLayout_cats (os : List Org) :
    (circleLayout os).map Prod.fst = Category.all := by
  simp only [circleLayout, List.map_map]
  have : (Prod.fst ∘ fun s : CircleState => (s.cat, (⟨⟨s.x / 1000, s.y / 1000⟩, s.r⟩ : Circle))) =
      CircleState.cat := rfl
  rw [this, simulate_cats, initial_cats]

end Fmxai.Map
