module
public meta import Sites
public meta import Fmxai
import Sites
import Fmxai

/-!
# Tests and audit

`#guard` lines run the compiled code on the real site. `#guard_msgs` lines pin the axioms the
site and the library's build theorem depend on: exactly the three standard axioms of Lean's
logic, no `sorryAx` and no `Lean.ofReduceBool` (so no `native_decide`). `lake build Test` fails
if either breaks.
-/

open Sites Sites.Html Fmxai

/-! ## Routes -/

#guard site.url .home = "/"
#guard site.url .y2026 = "/2026/"
#guard site.url .vibecheck = "/vibecheck/"
#guard site.route? "/2025/" = some .y2025
#guard site.route? "/nope/" = none

/-! ## Every page parses back to its document (executed; `Site.parse_html` proves it) -/

#guard routes.all fun r => (parseDocument site.route? (site.html r).toList).isSome
#guard (site.html .home).startsWith "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"utf-8\">"

/-! ## Axiom audit -/

/-- info: 'Fmxai.site' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms Fmxai.site

/-- info: 'Sites.Site.build_pages' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms Sites.Site.build_pages

/-! ## Negative cases, at the type level -/

-- A dead internal link is not a `Route`, so it cannot be written.
#guard routes.all fun r => site.url r != "/2024/"
