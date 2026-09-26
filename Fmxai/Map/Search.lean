module

/-!
# A verified pick-one-from-each search

The old map used Z3 to choose, for every organisation and every category label, one position
out of a list of candidates such that no two chosen positions conflict. This module is the
replacement: a depth-first search that picks one candidate from each list, backtracking when
the remaining lists cannot be completed.

It is small enough to prove things about:

* `choose_pairwise`: everything it returns is pairwise compatible under `ok`;
* `choose_mem`: every returned element came from one of the candidate lists;
* `choose_map`: when the candidate lists are indexed by items, the result carries exactly
  those items, in order, so nothing is dropped or duplicated.

The search is structurally recursive on the list of candidate lists, so it reduces inside the
kernel and needs no fuel.
-/

namespace Fmxai.Map

variable {α : Type}

@[expose] public section

/-- Picks one element from each list so that every pick is `ok` with every earlier pick.
`chosen` holds the picks so far, most recent first; the result is in that order too. -/
def choose (ok : α → α → Bool) : List (List α) → List α → Option (List α)
  | [], chosen => some chosen
  | cands :: rest, chosen =>
    cands.findSome? fun c =>
      if chosen.all (ok c) then choose ok rest (c :: chosen) else none

end

/-- The picks are pairwise `ok`, later picks against earlier ones. -/
public theorem choose_pairwise (ok : α → α → Bool) :
    ∀ (cands : List (List α)) (chosen sel : List α),
      choose ok cands chosen = some sel →
      chosen.Pairwise (fun a b => ok a b = true) → sel.Pairwise (fun a b => ok a b = true) := by
  intro cands
  induction cands with
  | nil => intro chosen sel h hp; simp [choose] at h; subst h; exact hp
  | cons cs rest ih =>
    intro chosen sel h hp
    simp only [choose] at h
    obtain ⟨c, _, hc⟩ := List.exists_of_findSome?_eq_some h
    split at hc
    · rename_i hall
      refine ih (c :: chosen) sel hc ?_
      rw [List.pairwise_cons]
      exact ⟨fun d hd => List.all_eq_true.mp hall d hd, hp⟩
    · simp at hc

/-- Every pick was either already chosen or came from one of the lists. -/
public theorem choose_mem (ok : α → α → Bool) :
    ∀ (cands : List (List α)) (chosen sel : List α),
      choose ok cands chosen = some sel →
      ∀ x ∈ sel, x ∈ chosen ∨ ∃ l ∈ cands, x ∈ l := by
  intro cands
  induction cands with
  | nil => intro chosen sel h x hx; simp [choose] at h; subst h; exact Or.inl hx
  | cons cs rest ih =>
    intro chosen sel h x hx
    simp only [choose] at h
    obtain ⟨c, hcmem, hc⟩ := List.exists_of_findSome?_eq_some h
    split at hc
    · rcases ih (c :: chosen) sel hc x hx with hin | ⟨l, hl, hxl⟩
      · simp only [List.mem_cons] at hin
        rcases hin with rfl | hin
        · exact Or.inr ⟨cs, by simp, hcmem⟩
        · exact Or.inl hin
      · exact Or.inr ⟨l, by simp [hl], hxl⟩
    · simp at hc

/-- When each list is the candidates of one item, tagged with it, the result is tagged with
exactly the items, most recent first. -/
public theorem choose_map {ι : Type} (ok : ι × α → ι × α → Bool) (cand : ι → List α) :
    ∀ (items : List ι) (chosen sel : List (ι × α)),
      choose ok (items.map fun i => (cand i).map fun p => (i, p)) chosen = some sel →
      sel.map Prod.fst = items.reverse ++ chosen.map Prod.fst := by
  intro items
  induction items with
  | nil => intro chosen sel h; simp [choose] at h; subst h; simp
  | cons i rest ih =>
    intro chosen sel h
    simp only [List.map_cons, choose] at h
    obtain ⟨c, hcmem, hc⟩ := List.exists_of_findSome?_eq_some h
    obtain ⟨p, _, rfl⟩ := List.mem_map.mp hcmem
    split at hc
    · have := ih ((i, p) :: chosen) sel hc
      simpa [List.reverse_cons, List.append_assoc] using this
    · simp at hc

end Fmxai.Map
