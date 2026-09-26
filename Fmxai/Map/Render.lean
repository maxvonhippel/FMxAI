module
public import Sites
public import Fmxai.Map.Layout

/-!
# Drawing the map

A `Layout` becomes an inline SVG in the typed HTML DSL: one `circle` and one `text` per
category, and per organisation an `a` wrapping its dot and its label. There is no script:
hover effects are CSS, links are links. What the theorem in `Fmxai.Map.Layout` says about the
coordinates is what the browser draws, because the coordinates are printed verbatim.
-/

namespace Fmxai.Map

open Sites Sites.Html

@[expose] public section

variable {ρ : Type}

/-- Radius of an organisation's dot. -/
def dotRadius : Int := 5

/-- The `viewBox`, fitted around everything drawn, with 50px of padding. -/
def viewBox (l : Layout) : String :=
  let xs := l.circles.flatMap (fun x => [x.2.center.x - x.2.r, x.2.center.x + x.2.r]) ++
    l.labels.flatMap (fun x => [x.2.x - 100, x.2.x + 100]) ++
    l.orgs.flatMap (fun x => [x.2.x - 50, x.2.x + 50])
  let ys := l.circles.flatMap (fun x => [x.2.center.y - x.2.r, x.2.center.y + x.2.r]) ++
    l.labels.flatMap (fun x => [x.2.y - 20, x.2.y + 20]) ++
    l.orgs.flatMap (fun x => [x.2.y - 10, x.2.y + 30])
  let minX := xs.foldl min 0 - 50
  let maxX := xs.foldl max 0 + 50
  let minY := ys.foldl min 0 - 50
  let maxY := ys.foldl max 0 + 50
  s!"{minX} {minY} {maxX - minX} {maxY - minY}"

/-- A category's circle. -/
def circleNode (x : Category × Circle) : Node ρ .svg :=
  circle [.cls "circle", .cx (toString x.2.center.x), .cy (toString x.2.center.y),
    .r (toString x.2.r), .fill x.1.color, .stroke x.1.color] []

/-- A category's label. -/
def labelNode (x : Category × Pt) : Node ρ .svg :=
  svgText [.cls "label", .x (toString x.2.x), .y (toString x.2.y), .fill x.1.color] [x.1.name]

/-- An organisation: a link around its dot and its label. -/
def orgNode (x : Org × Pt) : Node ρ .svg :=
  svgA [.cls "org-link", .href (.url x.1.url), .target "_blank"]
    [ circle [.cls "org-circle", .cx (toString x.2.x), .cy (toString x.2.y),
        .r (toString dotRadius)] [],
      svgText [.cls "org-text", .x (toString (orgLabelAnchor x.2).x),
        .y (toString (orgLabelAnchor x.2).y)] [x.1.name] ]

/-- The whole map. -/
def mapSvg (l : Layout) : Node ρ .flow :=
  svg [.id "venn", .viewBox (viewBox l)]
    (l.circles.map circleNode ++ l.labels.map labelNode ++ l.orgs.map orgNode)

/-- Organisations with a careers page, alphabetically. -/
def careerOrgs (os : List Org) : List (Org × String) :=
  (os.filterMap fun o => o.careers.map fun c => (o, c)).mergeSort fun a b =>
    a.1.name < b.1.name || a.1.name == b.1.name

/-- The careers list next to the map. -/
def careersList (os : List Org) : Node ρ .flow :=
  div [.cls "jobs-list", .id "jobs-list"]
    ((careerOrgs os).map fun x => a [.href (.url x.2), .target "_blank"] [x.1.name])

end

end Fmxai.Map
