module
public import Fmxai.Map.Layout

/-!
# The map, computed and checked by the kernel

`solve_orgs_isSome` is proven by `decide +kernel`: Lean's kernel runs the whole pipeline on
the real data (the circle simulation, candidate generation and the search) and confirms it
produces a layout. It takes about a minute. `theLayout` is that layout, and `theLayout_valid`
is `solve_valid` applied to it, so the map that is published is one the kernel has both
computed and, through the theorem, specified.

If the data in `Fmxai.Map.Data` changes so that it can no longer be drawn truthfully, this
module stops compiling.
-/

namespace Fmxai.Map

set_option maxHeartbeats 0 in
set_option maxRecDepth 100000 in
/-- The data has a layout. Evaluated by the kernel. -/
public theorem solve_orgs_isSome : (solve orgs).isSome = true := by decide +kernel

/-- The layout of the published map. -/
@[expose] public def theLayout : Layout := (solve orgs).get solve_orgs_isSome

/-- The published map is valid. -/
public theorem theLayout_valid : theLayout.Valid orgs :=
  solve_valid orgs theLayout (Option.some_get solve_orgs_isSome).symm

end Fmxai.Map
