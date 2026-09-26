module
public import Fmxai.Route

/-! # `/2026/` -/

namespace Fmxai.Pages

open Sites Sites.Html Fmxai

@[expose] public section

/-- A card in the "what attendees got out of it" grid. -/
def card (heading body : String) : Node Route .flow :=
  div [.cls "card"] [h3 [] [heading], p [] [body]]

/-- The FMxAI 2026 page. -/
def y2026 : Page Route :=
  { title := "Formal Methods × AI 2026"
    description := "Formal Methods × AI 2026 — 80 people, two and a half days, no spectators. Held June 1–3, 2026 at SRI International, Menlo Park, CA."
    body :=
      [ siteHeader "FMxAI 2026"
          ([ a [.href (.url "#about")] ["About"], a [.href (.url "#speakers")] ["Speakers"],
             a [.href (.url "#venue")] ["Venue"], a [.href (.route .y2025)] ["2025"] ] ++ navTail),
        div [.cls "hero"]
          [ div [.cls "container"]
              [ div [.cls "eyebrow"] ["June 1–3, 2026 · SRI International, Menlo Park"],
                h1 [] ["Formal Methods × AI 2026"],
                p [.cls "lede"] ["AI can write the code; formal methods can prove it correct. The hard part is coordination — that's what these 2.5 days were for."],
                div [.cls "facts"]
                  [ div [] [strong [] ["Date"], " ", span [] ["· June 1–3, 2026"]],
                    div [] [strong [] ["Location"], " ", span [] ["· SRI International, Menlo Park, CA"]],
                    div [] [strong [] ["Access"], " ", span [] ["· Invitation only"]] ],
                div [.cls "btn-row"]
                  [ a [.cls "btn", .href (.url contactUrl)] ["Express interest in FMxAI 2027"],
                    a [.cls "btn-ghost", .href (.url "#agenda")] ["View the agenda"] ] ] ],
        «section» [.id "results"]
          [ div [.cls "container narrow"]
              [ h2 [] ["The 2025 edition"],
                p [] ["The first edition gathered 50+ invited attendees at SRI International from September 30 to October 2, 2025 — senior FM researchers, frontier AI lab engineers, government research staff, startup founders, and funders."],
                img [.cls "hero-photo", .src "/static/event/fmxai25-hero.jpg",
                  .alt "FM x AI 2025 attendees at SRI International", .loading "lazy"],
                p [.cls "photo-caption"] ["FM x AI 2025 attendees at SRI International."],
                p [.cls "stat"] ["~95% of post-event survey respondents said they'd try their best to attend again."],
                div [.cls "quotes"]
                  [ blockquote [] ["The quality of people in the room was amazing. Please keep bar high."],
                    blockquote [] ["I got some great new perspectives on how AI might support FM and the (potential) future capabilities of models."],
                    blockquote [] ["The working groups on near-term impact, the ask/offer session… were very valuable."],
                    blockquote [] ["I definitely am going to do more with FM, specifically starting with learning LEAN."],
                    blockquote [] ["Hearing opinions from people that I would normally not have the chance to talk to."],
                    blockquote [] ["Yes, realized I'm not actually crazy."] ] ] ],
        «section» [.id "about"]
          [ div [.cls "container"]
              [ h2 [] ["What attendees got out of it"],
                p [.cls "narrow"] ["This was not a traditional academic conference. The format was built for shared problem-scoping, not paper presentations."],
                div [.cls "cards"]
                  [ card "Curated for complementary expertise" "About 80 people, hand-picked across formal methods, frontier AI labs, government research, and funders. The mix is the point.",
                    card "Working sessions, not broadcast" "Structured discussion is the default mode. Lightning talks and longer presentations exist to seed conversations, not fill the schedule.",
                    card "Scope real projects" "Working groups identify neglected high-value problems. Ask/offer sessions turn introductions into concrete collaborations.",
                    card "Outcomes that ship" "The 2025 edition produced new research collaborations, funded projects, and at least one Focused Research Organization that traces directly back to connections made in the room." ] ] ],
        «section» [.id "schedule"]
          [ div [.cls "container"]
              [ h2 [] ["Schedule"],
                p [] ["High-level shape of the 2.5 days. Detailed agenda below."],
                div [.cls "schedule"]
                  [ day "Mon, June 1" "Welcome Reception at 6:00 PM",
                    day "Tue, June 2" "Day 1, 9:15 AM – 5:30 PM",
                    day "Wed, June 3" "Day 2, 9:15 AM – 5:30 PM" ] ] ],
        «section» [.id "speakers"]
          [ div [.cls "container"]
              [ h2 [] ["Confirmed speakers"],
                div [.cls "speakers"]
                  [ speaker "Abbey Chaver" "Coefficient Giving, Associate Program Officer" "/static/speakers/abbey-chaver.png",
                    speaker "Buck Shlegeris" "Redwood Research, CEO" "/static/speakers/buck-shlegeris.jpg",
                    speaker "Evan Miyazono" "Atlas Computing, Founder & CEO" "/static/speakers/evan-miyazono.jpg",
                    speaker "Jason Fox" "KRY10, Co-Founder & COO" "/static/speakers/Jason-Fox.jpg",
                    speaker "Jesse Han" "Math Inc., CEO & Cofounder" "/static/speakers/jesse-han.jpg",
                    speaker "Keri Warr" "Anthropic, Member of Technical Staff" "/static/speakers/keri-warr.avif",
                    speaker "Lisa Thiergart" "Institute for Security and Technology, Senior Director, SL5 Task Force" "/static/speakers/Lisa-Thiergart.jpg",
                    speaker "Max von Hippel" "Benchify, Co-Founder & CTO" "/static/speakers/max-von-hippel.jpg",
                    speaker "Mike Dodds" "Galois, Principal Scientist" "/static/speakers/mike-dodds.jpg",
                    speaker "Nora Ammann" "ARIA, Programme Director, Safeguarded AI" "/static/speakers/nora-ammann.jpg",
                    speaker "Quinn Dougherty" "Forall R&D, Research Engineer" "/static/speakers/quinn-dougherty.jpg",
                    speaker "Tom Kalil" "Renaissance Philanthropy, CEO" "/static/speakers/tom-kalil.jpg" ] ] ],
        «section» [.id "venue"]
          [ div [.cls "container"]
              [ h2 [] ["Venue & logistics"],
                img [.cls "venue-photo", .src "/static/venue/sri.jpg", .alt "SRI International campus", .loading "lazy"],
                p [.cls "photo-caption"] ["SRI International campus, Menlo Park."],
                logisticsGrid
                  [ p [] ["SRI International, Innovation Center", br, "301 Ravenswood Avenue", br,
                      "Menlo Park, CA 94025", br,
                      ext "https://maps.app.goo.gl/odaHBPaUzCEbRYNE7" ["View on map ↗"]] ]
                  [ li [] ["~10 min walk from Menlo Park Caltrain station"],
                    li [] ["From SFO: BART to Millbrae → Caltrain south to Menlo Park"],
                    li [] ["From SJC: VTA Route 60 to Santa Clara Caltrain → Caltrain north to Menlo Park"] ]
                  "A room block has been reserved at a nearby hotel. Attendees cover their own rooms; booking details are sent after RSVP." ] ],
        «section» [.id "register"]
          [ div [.cls "container narrow"]
              [ h2 [] ["This event has concluded"],
                p [] ["FMxAI 2026 took place June 1–3, 2026 at SRI International, Menlo Park."],
                p [] ["The next edition is planned for March 8–10, 2027 in London. There's no event page yet — to express interest in attending, email ",
                  a [.href (.url contactUrl)] ["fmxai@atlasignota.org"], "."],
                h3 [.cls "mt-2"] ["Organization & support"],
                p [] ["Organized by Atlas Computing, with funding support from Coefficient Giving, Halcyon Futures, Harmonic, and ARIA."],
                p [] ["Interested in quarterly updates, or want more frequent news? Visit the ",
                  a [.href (.route .home)] ["FMxAI main page"], "."] ] ],
        «section» [.id "agenda"]
          [ div [.cls "container"]
              [ h2 [] ["Detailed agenda"],
                div [.cls "doc-meta"]
                  [ span [.cls "eyebrow"] ["Live from Google Docs"],
                    span [] ["Updates reflect within a few minutes of edits."] ],
                iframe [.cls "doc-frame",
                  .src "https://docs.google.com/document/d/1SbRW-7qws0z7VHSQlhcVJoog3gix0FMmuDsa0z7jYk8/preview",
                  .title "FMxAI 2026 detailed agenda", .loading "lazy"] [] ] ],
        siteFooter true ] }

end

end Fmxai.Pages
