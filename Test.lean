module
public meta import Sites
public meta import Fmxai
import Sites
import Fmxai

/-!
# Tests and audit

`#guard` lines run the compiled code on the real site. `#guard_msgs` lines pin the axioms the
headline theorems depend on: exactly the three standard axioms of Lean's logic, no `sorryAx`
and no `Lean.ofReduceBool` (so no `native_decide`). `lake build Test` fails if either breaks.
-/

open Sites Sites.Html Fmxai Fmxai.Map

/-! ## Routes -/

#guard site.url .home = "/"
#guard site.url .y2026 = "/2026/"
#guard site.url .map = "/map/"
#guard site.route? "/2025/" = some .y2025
#guard site.route? "/nope/" = none

/-! ## Every page parses back to its document (executed; `Site.parse_html` proves it) -/

#guard routes.all fun r => (parseDocument site.route? (site.html r).toList).isSome
#guard (site.html .home).startsWith "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"utf-8\">"

/-! ## The map -/

#guard (solve orgs).isSome
#guard theLayout.orgs.length = orgs.length
#guard theLayout.circles.length = Category.all.length
#guard theLayout.labels.length = Category.all.length
-- The geometry the theorem talks about is the geometry that is printed.
#guard theLayout.orgs.all fun x =>
  ((site.html .map).splitOn s!"<circle class=\"org-circle\" cx=\"{x.2.x}\" cy=\"{x.2.y}\" r=\"5\"></circle><text class=\"org-text\" x=\"{x.2.x}\" y=\"{x.2.y + 20}\">").length == 2
#guard ((site.html .map).splitOn "<a class=\"org-link\" href=").length == orgs.length + 1
#guard (careerOrgs orgs).map (·.1.name) = ["Axiom", "ForMACE Lab", "Formal Computing and AI Lab",
  "NDEA", "Reasonable", "Sigil Logic", "Theorem"]

-- The specification is a real constraint: nudging a dot into another circle breaks it.
#guard match theLayout.orgs with
  | x :: _ =>
    let moved : Org × Pt := (x.1, (theLayout.circles.head?.map (·.2.center)).getD x.2)
    dotOk theLayout.circles moved.1 moved.2 = false || x.1.categories.length = Category.all.length
  | [] => false

/-! ## Search -/

#guard choose (fun a b => a != b) [[1, 2], [1, 2], [1, 2]] [] = none
#guard choose (fun a b => a != b) [[1, 2], [1, 2], [3]] [] = some [3, 2, 1]
#guard sortBy id [3, 1, 2] = [1, 2, 3]

/-! ## Geometry -/

#guard (Pt.mk 0 0).insideBy ⟨⟨0, 0⟩, 100⟩ 15
#guard !(Pt.mk 90 0).insideBy ⟨⟨0, 0⟩, 100⟩ 15
#guard (Pt.mk 130 0).outsideBy ⟨⟨0, 0⟩, 100⟩ 25
#guard isqrt 1000000 = 1000
#guard isqrt 999999 = 999
#guard sinMilli 900 = 1000
#guard sinMilli 0 = 0
#guard (sinMilli 300 - 500).natAbs ≤ 3

/-! ## Axiom audit -/

/-- info: 'Fmxai.Map.solve_valid' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms Fmxai.Map.solve_valid

/-- info: 'Fmxai.Map.theLayout_valid' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms Fmxai.Map.theLayout_valid

/-- info: 'Fmxai.Map.choose_pairwise' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in
#print axioms Fmxai.Map.choose_pairwise

/-- info: 'Fmxai.site' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms Fmxai.site

/-- info: 'Sites.Site.build_pages' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms Sites.Site.build_pages

/-! ## Negative cases, at the type level -/

-- SVG content is not flow content and text is not SVG content.
example : Fits Tag.circle.ctx Ctx.flow → False := fun h => nomatch h
example : TextCtx Ctx.svg → False := fun ⟨h⟩ => nomatch h
-- A dead internal link is not a `Route`, so it cannot be written.
#guard routes.all fun r => site.url r != "/2024/"
