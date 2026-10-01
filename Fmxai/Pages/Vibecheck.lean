module
public import Fmxai.Route

/-! # `/vibecheck/` -/

namespace Fmxai.Pages

open Sites Sites.Html Fmxai

@[expose] public section

/-- A way to take part, as the sign-up form offers it. -/
def role (heading : String) (body : List (Node Route .phrasing)) : Node Route .flow :=
  div [.cls "card"] [h3 [] [heading], p [] body]

/-- A sponsor: its name, linking to its site. -/
def sponsor (name url : String) : Node Route .flow :=
  ext' [.cls "sponsor"] url [name]

/-- The venue, 447 Battery St, on Google Maps. -/
def vibecheckVenueMapUrl : String :=
  "https://maps.google.com/?q=447+Battery+St,+San+Francisco,+CA"

/-- The Vibecheck hackathon page. The prose follows the sign-up form. -/
def vibecheck : Page Route :=
  { title := "Vibecheck — the usable formal methods hackathon"
    description := "Vibecheck: a hackathon on whether formal methods are ready for real-world software. Build a piece of production software and formally verify it. Weekend of November 1, 2026, at TheGP, 447 Battery St, San Francisco."
    body :=
      [ siteHeader "Vibecheck"
          ([ a [.href (.url "#about")] ["About"], a [.href (.url "#roles")] ["Take part"],
             a [.href (.url "#signup")] ["Sign up"], a [.href (.url "#sponsors")] ["Sponsors"],
             a [.href (.route .home)] ["FMxAI"] ] ++ navTail),
        div [.cls "hero"]
          [ div [.cls "container"]
              [ div [.cls "eyebrow"] ["Weekend of November 1, 2026 · TheGP, San Francisco"],
                h1 [] ["Vibecheck"],
                p [.cls "lede"] ["The usable formal methods hackathon. Build a piece of real-world production software, and formally verify it."],
                div [.cls "facts"]
                  [ div [] [strong [] ["Date"], " ", span [] ["· Weekend of November 1, 2026"]],
                    div [] [strong [] ["Where"], " ", span [] ["· ", ext vibecheckVenueMapUrl ["TheGP, 447 Battery St, San Francisco"]]],
                    div [] [strong [] ["Who"], " ", span [] ["· Competitors, experts and sponsors"]],
                    div [] [strong [] ["Experience"], " ", span [] ["· None required"]] ],
                div [.cls "btn-row"]
                  [ ext' [.cls "btn"] vibecheckFormUrl ["Sign up ↗"],
                    a [.cls "btn-ghost", .href (.url "#about")] ["What is this?"] ],
                div [.cls "promo"]
                  [ iframe [.cls "promo-frame", .src (vibecheckPromoUrl ++ "#embed"),
                      .title "Vibecheck promo animation"] [],
                    p [.cls "promo-caption"] ["A 25-second loop. Click it to pause, or ",
                      a [.href (.url vibecheckPromoUrl)] ["open it on its own page"],
                      " to jump between scenes."] ] ] ],
        «section» [.id "about"]
          [ div [.cls "container narrow"]
              [ h2 [] ["Is FM ready for prime time?"],
                p [] [ext "https://x.com/bcherny/status/2102543349102338309" ["Formal methods have officially entered the zeitgeist"],
                  ". But are these techniques actually ready for prime time?"],
                p [] ["We know FM can be brought to bear on stodgy academic software: basically mathematical in nature, not reliant on external dependencies, and lacking a GUI, a database, or third-party APIs. But could it be brought to bear on Microsoft Word, or Flappy Bird, or Claude Code? Is FM ready for truly mainstream adoption? Could the next hot YC company build its product to be formally verified from the very start, without needing to first complete a PhD at Carnegie Mellon?"],
                p [] ["To answer these questions, we're running a hackathon. Teams pick a piece of software people would actually use, build it, and prove it correct. Work alone, bring a team, or find one in the room."] ] ],
        «section» [.id "roles"]
          [ div [.cls "container"]
              [ h2 [] ["Take part"],
                p [.cls "narrow"] ["Competitors are people with little or no formal methods experience; experts are people with a lot of it."],
                div [.cls "cards"]
                  [ role "Compete" [strong [] ["Zero to not a lot of FM experience."], " Build a piece of real-world production software and formally verify it. Solo, with a team you bring, or with people you meet on the day."],
                    role "Help" [strong [] ["Significant FM experience."], " A year or more of full-time work with at least one FM tool, or close to it. Walk around the room and unstick competitors when they get stuck."],
                    role "Sponsor" ["Provide prizes, swag, food, compute, tokens, and other things that make a weekend go better."] ],
                div [.cls "callout mt-2"]
                  [ p [] ["We are targeting a ratio of roughly ", strong [] ["five competitors to one expert"],
                      ", so there is always someone nearby who has seen your error before."] ] ] ],
        «section» [.id "signup"]
          [ div [.cls "container narrow"]
              [ h2 [] ["Sign up"],
                p [] ["If you're interested in participating, in any capacity, fill out the form. It asks about your availability, how you'd like to take part, your FM background, a few prior projects you're proud of, and whether there's something specific you want to build. No project idea is needed to sign up."],
                div [.cls "btn-row"]
                  [ ext' [.cls "btn"] vibecheckFormUrl ["Open the sign-up form ↗"] ],
                p [.cls "mt-2"] ["Questions? Email ", a [.href (.url contactUrl)] ["quinn@for-all.dev"], "."] ] ],
        «section» [.id "sponsors"]
          [ div [.cls "container"]
              [ h2 [] ["Sponsors"],
                p [.cls "narrow"] ["Vibecheck is made possible by these organizations. Thank you."],
                div [.cls "sponsors"]
                  [ sponsor "Theorem" "https://theorem.dev",
                    sponsor "workers.io" "https://workers.io",
                    sponsor "Anthropic" "https://www.anthropic.com",
                    sponsor "TheGP" "https://www.thegp.com",
                    sponsor "omni.co" "https://omni.co",
                    sponsor "Prime Intellect" "https://www.primeintellect.ai",
                    sponsor "Math Inc" "https://www.math.inc",
                    sponsor "Forall R&D" "https://for-all.dev",
                    sponsor "Atlas Ignota" "https://atlasignota.org",
                    sponsor "Lanyon AI" "https://lanyon.ai",
                    sponsor "Astrio Labs" "https://astriolabs.com",
                    sponsor "OpenAI" "https://openai.com",
                    sponsor "Harmonic" "https://www.harmonic.fun/",
                    sponsor "Party" "https://party.build",
                    sponsor "Random Labs" "https://randomlabs.ai",
                    sponsor "Theoric" "https://theoric.com" ],

                p [.cls "mt-2 narrow"] ["Want to sponsor too? ", a [.href (.url "#signup")] ["Sign up"],
                  " as a sponsor, or email ", a [.href (.url contactUrl)] ["quinn@for-all.dev"], "."] ] ],
        siteFooter ] }

end

end Fmxai.Pages
