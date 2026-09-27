module
public import Fmxai.Route

/-! # `/vibecheck/` -/

namespace Fmxai.Pages

open Sites Sites.Html Fmxai

@[expose] public section

/-- A way to take part, as the sign-up form offers it. -/
def role (heading : String) (body : List (Node Route .phrasing)) : Node Route .flow :=
  div [.cls "card"] [h3 [] [heading], p [] body]

/-- The Vibecheck hackathon page. The prose follows the sign-up form. -/
def vibecheck : Page Route :=
  { title := "Vibecheck — the usable formal methods hackathon"
    description := "Vibecheck: a hackathon on whether formal methods are ready for real-world software. Build a piece of production software and formally verify it. Weekend of November 1, 2026."
    body :=
      [ siteHeader "Vibecheck"
          ([ a [.href (.url "#about")] ["About"], a [.href (.url "#roles")] ["Take part"],
             a [.href (.url "#signup")] ["Sign up"], a [.href (.route .home)] ["FMxAI"] ] ++ navTail),
        div [.cls "hero"]
          [ div [.cls "container"]
              [ div [.cls "eyebrow"] ["Weekend of November 1, 2026"],
                h1 [] ["Vibecheck"],
                p [.cls "lede"] ["The usable formal methods hackathon. Build a piece of real-world production software, and formally verify it."],
                div [.cls "facts"]
                  [ div [] [strong [] ["Date"], " ", span [] ["· Weekend of November 1, 2026"]],
                    div [] [strong [] ["Who"], " ", span [] ["· Competitors, experts and sponsors"]],
                    div [] [strong [] ["Experience"], " ", span [] ["· None required"]] ],
                div [.cls "btn-row"]
                  [ ext' [.cls "btn"] vibecheckFormUrl ["Sign up ↗"],
                    a [.cls "btn-ghost", .href (.url "#about")] ["What is this?"] ] ] ],
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
                p [.cls "narrow"] ["Whatever your formal methods background, from nonexistent to a career's worth, there is a way in."],
                div [.cls "cards"]
                  [ role "Compete" ["Build a piece of real-world production software and formally verify it. Solo, with a team you bring, or with people you meet on the day."],
                    role "Help" ["Walk around the room and unstick people who are new to formal methods. Experienced practitioners wanted."],
                    role "Sponsor" ["Provide prizes, swag, food, compute, tokens, and other things that make a weekend go better."] ],
                div [.cls "callout mt-2"]
                  [ p [] ["Looking to hire formal methods people, or to be hired? The sign-up form asks, so we can put you in touch."],
                    ext vibecheckFormUrl ["Say so on the form ↗"] ] ] ],
        «section» [.id "signup"]
          [ div [.cls "container narrow"]
              [ h2 [] ["Sign up"],
                p [] ["If you're interested in participating, in any capacity, fill out the form. It asks about your availability, how you'd like to take part, your FM background, a few prior projects you're proud of, and whether there's something specific you want to build. No project idea is needed to sign up."],
                div [.cls "btn-row"]
                  [ ext' [.cls "btn"] vibecheckFormUrl ["Open the sign-up form ↗"] ],
                p [.cls "mt-2"] ["Questions? Email ", a [.href (.url contactUrl)] ["fmxai@atlasignota.org"], "."] ] ],
        siteFooter true ] }

end

end Fmxai.Pages
