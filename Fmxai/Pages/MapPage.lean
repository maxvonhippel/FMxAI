module
public import Fmxai.Route
public import Fmxai.Map.Render

/-! # `/map/`

The map page takes the layout as an argument: the only way to build this page is with a
`Layout`, and the only way the build gets one is from `Fmxai.Map.solve`, whose output is
proven valid (`Fmxai.Map.solve_valid`). -/

namespace Fmxai.Pages

open Sites Sites.Html Fmxai

@[expose] public section

/-- The map page. -/
def mapPage (l : Map.Layout) : Page Route :=
  { title := "Organizations in FMxAI"
    body :=
      [ div [.id "header"]
          [ h1 [] ["Formal Methods x Artificial Intelligence"],
            p [] ["This website tracks the FMxAI research community, mapping the landscape of groups, resources and projects. The site is ",
              a [.href (.url sourceUrl)] ["open source"], ". Contact: maxvh [at] hey [dot] com to get involved."] ],
        div [.id "main-container"]
          [ div [.id "left-panel"] [div [.id "venn-container"] [Map.mapSvg l]],
            div [.id "right-panel"]
              [ div [.cls "section-title"] ["Career Opportunities"], Map.careersList Map.orgs ] ] ] }

end

end Fmxai.Pages
