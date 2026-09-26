module

/-!
# Integer geometry for the map

Everything the map's specification talks about is defined here, over `Int` so that it is
exact and decidable: points, circles, text boxes, and the predicates "inside a circle by a
margin", "outside a circle by a margin", "at least this far apart" and "these boxes do not
touch". Distances are compared squared, so there is no square root and no rounding anywhere
in the specification.
-/

namespace Fmxai.Map

@[expose] public section

/-- A point in SVG user units (pixels of the `viewBox`). -/
structure Pt where
  /-- Horizontal coordinate. -/
  x : Int
  /-- Vertical coordinate. -/
  y : Int
  deriving Repr, DecidableEq

/-- A circle. -/
structure Circle where
  /-- Centre. -/
  center : Pt
  /-- Radius. -/
  r : Int
  deriving Repr, DecidableEq

/-- An axis-aligned box. -/
structure Box where
  /-- Left edge. -/
  left : Int
  /-- Right edge. -/
  right : Int
  /-- Top edge (smaller `y`). -/
  top : Int
  /-- Bottom edge (larger `y`). -/
  bottom : Int
  deriving Repr, DecidableEq

/-- Squared Euclidean distance. -/
def distSq (p q : Pt) : Int :=
  (p.x - q.x) * (p.x - q.x) + (p.y - q.y) * (p.y - q.y)

/-- `p` is strictly inside `c`, at least `m` from its edge: `dist p c < r - m`. -/
def Pt.insideBy (p : Pt) (c : Circle) (m : Int) : Bool :=
  0 < c.r - m && distSq p c.center < (c.r - m) * (c.r - m)

/-- `p` is outside `c`, at least `m` from its edge: `dist p c ≥ r + m`. -/
def Pt.outsideBy (p : Pt) (c : Circle) (m : Int) : Bool :=
  0 ≤ c.r + m && (c.r + m) * (c.r + m) ≤ distSq p c.center

/-- `p` and `q` are at least `d` apart. -/
def Pt.apartBy (p q : Pt) (d : Int) : Bool :=
  d * d ≤ distSq p q

/-- The boxes are separated by more than `pad` along at least one axis. -/
def Box.disjointBy (a b : Box) (pad : Int) : Bool :=
  a.right + pad < b.left || b.right + pad < a.left ||
    a.bottom + pad < b.top || b.bottom + pad < a.top

/-- The box and the circle's interior intersect: the point of the box closest to the centre is
strictly inside the circle. -/
def Box.meetsCircle (b : Box) (c : Circle) : Bool :=
  let cx := max b.left (min c.center.x b.right)
  let cy := max b.top (min c.center.y b.bottom)
  distSq ⟨cx, cy⟩ c.center < c.r * c.r

/-- The circles are separated by at least `gap`. -/
def Circle.disjointBy (a b : Circle) (gap : Int) : Bool :=
  (a.r + b.r + gap) * (a.r + b.r + gap) ≤ distSq a.center b.center

/-! ## Text boxes

The map cannot measure text, so it uses the same per-character estimates the old JavaScript
did, rounded up to whole pixels: a category label is set at 14px, an organisation label at
12px and drawn 20px below its dot. -/

/-- The box a category label occupies when anchored (middle) at `p`. -/
def catLabelBox (len : Nat) (p : Pt) : Box :=
  let half : Int := 5 * len + 20
  { left := p.x - half, right := p.x + half, top := p.y - 21, bottom := p.y + 10 }

/-- Where an organisation's label is anchored, given its dot. -/
def orgLabelAnchor (dot : Pt) : Pt := ⟨dot.x, dot.y + 20⟩

/-- The box an organisation label occupies, given its dot. -/
def orgLabelBox (len : Nat) (dot : Pt) : Box :=
  let p := orgLabelAnchor dot
  let half : Int := 5 * len + 15
  { left := p.x - half, right := p.x + half, top := p.y - 18, bottom := p.y + 10 }

end

/-! ## Symmetry

The search checks each pair once; the specification is stated on a list in the other
order, so it needs these. -/

public theorem distSq_comm (p q : Pt) : distSq p q = distSq q p := by
  unfold distSq
  have h1 : (p.x - q.x) * (p.x - q.x) = (q.x - p.x) * (q.x - p.x) := by
    rw [← Int.neg_sub, Int.neg_mul_neg]
  have h2 : (p.y - q.y) * (p.y - q.y) = (q.y - p.y) * (q.y - p.y) := by
    rw [← Int.neg_sub, Int.neg_mul_neg]
  rw [h1, h2]

public theorem Pt.apartBy_comm (p q : Pt) (d : Int) : p.apartBy q d = q.apartBy p d := by
  simp [Pt.apartBy, distSq_comm]

public theorem Box.disjointBy_comm (a b : Box) (pad : Int) :
    a.disjointBy b pad = b.disjointBy a pad := by
  simp only [Box.disjointBy]
  cases h1 : decide (a.right + pad < b.left) <;> cases h2 : decide (b.right + pad < a.left) <;>
    cases h3 : decide (a.bottom + pad < b.top) <;> cases h4 : decide (b.bottom + pad < a.top) <;> rfl

public theorem Circle.disjointBy_comm (a b : Circle) (gap : Int) :
    a.disjointBy b gap = b.disjointBy a gap := by
  simp [Circle.disjointBy, distSq_comm, Int.add_comm a.r b.r]

end Fmxai.Map
