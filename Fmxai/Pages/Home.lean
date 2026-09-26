module
public import Fmxai.Route

/-! # `/` -/

namespace Fmxai.Pages

open Sites Sites.Html Fmxai

@[expose] public section

/-- An event card. The old markup wrapped the card in an `a`; block content inside `a` is not
expressible in the typed DSL, so the card is a `div` and its call to action is a link that CSS
stretches over the whole card (`.event .go::after`). -/
def eventCard (tag tagCls heading when : String) (blurb : List (Node Route .phrasing))
    (go : Option (Link Route × String)) : Node Route .flow :=
  div [.cls "event"]
    ([span [.cls ("tag " ++ tagCls)] [tag], h3 [] [heading], div [.cls "when"] [when], p [] blurb] ++
     match go with
     | none => []
     | some (.route r, label) => [a [.cls "go", .href (.route r)] [label]]
     | some (.url u, label) => [a [.cls "go", .href (.url u), .target "_blank", .rel "noopener"] [label]])

/-- The home page. -/
def home : Page Route :=
  { title := "Formal Methods × AI"
    description := "Formal Methods × AI — a community and event series for researchers, labs, and funders working at the intersection of formal methods and artificial intelligence."
    body :=
      [ siteHeader "FMxAI" ([a [.href (.url "#events")] ["Events"]] ++ navTail),
        div [.cls "hero"]
          [ div [.cls "container"]
              [ div [.cls "eyebrow"] ["Formal Methods × Artificial Intelligence"],
                h1 [] ["Proof-grade software, at the speed of AI."],
                p [.cls "lede"] ["AI is making it cheap to write code and proofs; formal methods make it possible to trust them. The intersection is where verifiable, safety-critical systems get built — and it's badly under-coordinated. FMxAI brings the two communities into one room to scope what to build next."],
                div [.cls "btn-row"]
                  [ a [.cls "btn", .href (.url contactUrl)] ["Express interest in FMxAI 2027 →"],
                    a [.cls "btn-ghost", .href (.route .map)] ["Explore the map"] ] ] ],
        «section» [.id "events"]
          [ div [.cls "container"]
              [ h2 [] ["The event series"],
                p [.cls "narrow"] ["An invitation-only gathering of FM researchers, frontier AI labs, government research staff, startup founders, and funders — built for shared problem-scoping, not paper presentations. Organized by Atlas Computing."],
                div [.cls "events"]
                  [ eventCard "Upcoming" "upcoming" "FMxAI 2027" "March 8–10, 2027 · London"
                      ["There's no event page yet. Want to express interest in attending? Email ",
                       a [.href (.url "mailto:fmxai@atlascomputing.org")] ["fmxai@atlascomputing.org"], "."]
                      none,
                    eventCard "Past" "past" "FMxAI 2026" "June 1–3, 2026 · SRI International, Menlo Park"
                      ["~80 people, two and a half days of shared problem-scoping at SRI. Speakers, agenda, and venue."]
                      (some (.route .y2026, "View the 2026 conference →")),
                    eventCard "Past" "past" "FMxAI 2025" "September 30 – October 2, 2025 · SRI International, Menlo Park"
                      ["The inaugural edition — 50+ invited attendees. Recap, speakers, and outcomes."]
                      (some (.route .y2025, "View the 2025 recap →")),
                    eventCard "Past" "past" "Proof Scaling 2024" "December 5–6, 2024 · Lighthaven, Berkeley"
                      ["The precursor gathering that started the series."]
                      (some (.url "https://proof-scaling-meeting.vercel.app", "Visit the 2024 site ↗")) ] ] ],
        «section» [.id "more"]
          [ div [.cls "container"]
              [ h2 [] ["Beyond the conference"],
                div [.cls "callout"]
                  [ p [] ["The ", strong [] ["FMxAI map"], " tracks groups, projects, and resources at the intersection of formal methods and AI."],
                    a [.href (.route .map)] ["Open the map →"] ],
                div [.cls "callout"]
                  [ p [] ["The ", strong [] ["Secure Program Synthesis Fellowship"], ", run with Apart Research, supports work on trustworthy AI-generated code."],
                    ext fellowshipUrl ["Learn about the fellowship ↗"] ] ] ],
        siteFooter false ] }

end

end Fmxai.Pages
