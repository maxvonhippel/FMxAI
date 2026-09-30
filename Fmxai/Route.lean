module
public import Sites

/-!
# Routes and shared chrome

The four pages of fmxai.org. Every internal link on the site is a `Route`, so a link to a
page that does not exist is a type error; `Fmxai.site` proves the route table complete and the
URLs distinct.
-/

namespace Fmxai

open Sites Sites.Html

@[expose] public section

/-- The pages. -/
inductive Route where
  /-- `/`: the series. -/
  | home
  /-- `/2025/`: the inaugural edition. -/
  | y2025
  /-- `/2026/`: the second edition. -/
  | y2026
  /-- `/vibecheck/`: the usable formal methods hackathon. -/
  | vibecheck
  deriving DecidableEq, Repr

/-- All routes. -/
def routes : List Route := [.home, .vibecheck, .y2026, .y2025]

/-- Where each route lives. -/
def path : Route → Path
  | .home => []
  | .y2025 => [seg "2025"]
  | .y2026 => [seg "2026"]
  | .vibecheck => [seg "vibecheck"]

/-- Route lookup. -/
def route? : List Char → Option Route := routeOfChars routes path

/-! ## Links used on more than one page -/

/-- The Secure Program Synthesis Fellowship. -/
def fellowshipUrl : String :=
  "https://apartresearch.com/fellowships/the-secure-program-synthesis-fellowship"
/-- This repository. -/
def sourceUrl : String := "https://github.com/maxvonhippel/FMxAI"
/-- Where to express interest in the next edition. -/
def contactUrl : String := "mailto:quinn@for-all.dev"
/-- The Vibecheck hackathon sign-up form. -/
def vibecheckFormUrl : String :=
  "https://docs.google.com/forms/d/e/1FAIpQLSeD10bRGSgyzlZ0KS7YdnX85THZ4FASLeQMGIvkrNW7PKINzg/viewform"
/-- The promo animation: a hand-written canvas page under `public/`, embedded on the Vibecheck
page with `#embed` (stage only) and linked on its own for the team to scrub and comment on. -/
def vibecheckPromoUrl : String := "/vibecheck/promo.html"

/-- An external link, opened in a new tab. -/
def ext {c : Ctx} (url : String) (children : List (Node Route .phrasing))
    (h : Fits .phrasing c := by fits) : Node Route c :=
  a [.href (.url url), .target "_blank", .rel "noopener"] children h

/-- An external link with extra attributes (a class, say), opened in a new tab. -/
def ext' {c : Ctx} (attrs : List (Attr Route)) (url : String) (children : List (Node Route .phrasing))
    (h : Fits .phrasing c := by fits) : Node Route c :=
  a (attrs ++ [.href (.url url), .target "_blank", .rel "noopener"]) children h

/-! ## Chrome -/

/-- The sticky header: brand on the left, navigation on the right. -/
def siteHeader (brand : String) (links : List (Node Route .flow)) : Node Route .flow :=
  header [.cls "site"]
    [ div [.cls "container"]
        [ a [.cls "brand", .href (.route .home)] [img [.src "/favicon.svg", .alt ""], span [] [brand]],
          nav [] links ] ]

/-- The navigation entry every page ends with. -/
def navTail : List (Node Route .flow) :=
  [ a [.cls "nav-keep cta-link", .href (.url fellowshipUrl), .target "_blank", .rel "noopener"]
      ["Fellowship ↗"] ]

/-- The footer. -/
def siteFooter : Node Route .flow :=
  footer [.cls "site"]
    [ div [.cls "container"]
        [ p [] [a [.href (.url "https://fmxai.org")] ["fmxai.org"], " · ",
            a [.href (.url sourceUrl)] ["source"]] ] ]

/-- The "Venue & logistics" grid shared by the event pages. -/
def logisticsGrid (venue : List (Node Route .flow)) (transit : List (Node Route .listItem))
    (hotel : String) : Node Route .flow :=
  div [.cls "logistics-grid"]
    [ div [] (h3 [] ["Venue"] :: venue),
      div [] [ h3 [] ["Closest airports"],
        ul [] [ li [] ["SFO (San Francisco) — 30 min drive"], li [] ["SJC (San Jose) — 30 min drive"],
                li [] ["OAK (Oakland) — 45 min drive"] ] ],
      div [] [ h3 [] ["Public transit"], ul [] transit ],
      div [] [ h3 [] ["Hotel"], p [] [hotel] ] ]

/-- A row of the schedule. -/
def day (when what : String) : Node Route .flow :=
  div [.cls "day"] [span [.cls "when"] [when], span [] [what]]

/-- A speaker card, with or without a headshot. -/
def speaker (name role : String) (photo : Option String := none) : Node Route .flow :=
  div [.cls "speaker"]
    ((match photo with
      | some src => [img [.cls "headshot", .src src, .alt name, .loading "lazy"]]
      | none => []) ++
     [div [.cls "name"] [name], div [.cls "role"] [role]])

end

end Fmxai
