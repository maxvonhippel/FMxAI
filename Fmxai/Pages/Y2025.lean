module
public import Fmxai.Route

/-! # `/2025/` -/

namespace Fmxai.Pages

open Sites Sites.Html Fmxai

@[expose] public section

/-- The FMxAI 2025 page. -/
def y2025 : Page Route :=
  { title := "Formal Methods × AI 2025"
    description := "Formal Methods × AI 2025 — an exclusive gathering of researchers, industry leaders, and funders at the intersection of formal methods and AI. September 30 – October 2, 2025, SRI International, Menlo Park, CA."
    body :=
      [ siteHeader "FMxAI 2025"
          ([ a [.href (.url "#speakers")] ["Speakers"], a [.href (.url "#venue")] ["Venue"],
             a [.href (.route .y2026)] ["2026"] ] ++ navTail),
        div [.cls "hero hero-2025"]
          [ div [.cls "container"]
              [ div [.cls "archived-banner"] ["This event concluded on October 2, 2025. The ",
                  a [.href (.route .y2026)] ["2026 edition"], " is now open."],
                div [.cls "eyebrow"] ["September 30 – October 2, 2025 · SRI International, Menlo Park"],
                h1 [] ["Formal Methods × AI 2025"],
                p [.cls "lede"] ["A high-bandwidth, high-trust, high-impact exclusive gathering of top researchers, industry leaders, and funders dedicated to exploring opportunities arising at the intersection of Formal Methods (FM) and Artificial Intelligence (AI)."],
                img [.cls "hero-photo", .src "/2025/hero.png",
                  .alt "FMxAI 2025 attendees gathered on the steps at SRI International"],
                p [.cls "hero-photo-caption"] ["The inaugural FMxAI gathering — 50+ invited attendees at SRI International."] ] ],
        «section» [.id "goals"]
          [ div [.cls "container narrow"]
              [ h2 [] ["The goal"],
                p [] ["The inaugural edition brought together senior FM researchers, frontier AI lab engineers, government research staff, startup founders, and funders to:"],
                ol [.cls "goals"]
                  [ li [] ["Bring together key contributors across both domains."],
                    li [] ["Foster collaboration between individuals and disparate teams."],
                    li [] ["Identify important problems and high-value neglected projects at the intersection."] ] ] ],
        «section» [.id "schedule"]
          [ div [.cls "container"]
              [ h2 [] ["Schedule"],
                div [.cls "schedule"]
                  [ day "Sep 30" "Welcome Reception at 6:30 PM",
                    day "Oct 1" "Day 1, 9:00 AM – 5:30 PM",
                    day "Oct 2" "Day 2, 9:00 AM – 5:30 PM" ] ] ],
        «section» [.id "speakers"]
          [ div [.cls "container"]
              [ h2 [] ["Speakers"],
                div [.cls "speakers"]
                  [ speaker "Max Tegmark" "MIT / Beneficial AI Foundation",
                    speaker "Stuart Russell" "CHAI",
                    speaker "Clark Barrett" "Stanford CS",
                    speaker "Zac Hatfield-Dodds" "Anthropic",
                    speaker "Swarat Chaudhuri" "Google DeepMind / UT Austin",
                    speaker "Mike Dodds" "Galois, Principal Scientist",
                    speaker "Rajashree Agarwal" "Theorem Labs, Co-founder",
                    speaker "Leo de Moura" "AWS, Lean FRO Chief Architect",
                    speaker "Adam Chlipala" "MIT CSAIL",
                    speaker "Joe Kiniry" "Free & Fair, Principal Scientist" ] ] ],
        «section» [.id "feedback"]
          [ div [.cls "container narrow"]
              [ h2 [] ["What attendees valued"],
                div [.cls "quotes"]
                  [ blockquote [] ["Meeting and interacting with the leading lights."],
                    blockquote [] ["The working groups on near-term impact and the ask/offer sessions were valuable."],
                    blockquote [] ["Connection with frontier researchers and their research."] ] ] ],
        «section» [.id "venue"]
          [ div [.cls "container"]
              [ h2 [] ["Venue & logistics"],
                logisticsGrid
                  [ p [] ["SRI International", br, "333 Ravenswood Ave", br, "Menlo Park, CA 94025"] ]
                  [ li [] ["~10 min walk from Menlo Park Caltrain station"] ]
                  "A reserved room block was available; attendees covered their own costs." ] ],
        «section» [.id "organizers"]
          [ div [.cls "container narrow"]
              [ h2 [] ["Organization & support"],
                p [] ["Organized by Atlas Computing, with funding support from the Beneficial AI Foundation."],
                p [.cls "mt-125"] [a [.cls "btn", .href (.route .y2026)] ["See FMxAI 2026 →"]] ] ],
        siteFooter true ] }

end

end Fmxai.Pages
