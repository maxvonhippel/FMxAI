module
public import Fmxai.Route
public import Fmxai.Pages.Home
public import Fmxai.Pages.Y2025
public import Fmxai.Pages.Y2026
public import Fmxai.Pages.MapPage
public import Fmxai.Map.Verified

/-!
# The site

Routes, pages and the document chrome, assembled into a `Sites.Site`. The two proof
obligations (`routes_complete`, `urls_nodup`) are discharged by `decide`; the library then
gives us `Site.parse_html` and `Site.build_pages` for every page, including the map.

The stylesheets are the hand-written CSS files in `public/`, served verbatim so that the
site looks exactly as it did; the typed CSS DSL is not used here.
-/

namespace Fmxai

open Sites Sites.Html

@[expose] public section

/-- Google Fonts, as before. -/
def fontsUrl : String :=
  "https://fonts.googleapis.com/css2?family=Source+Serif+4:ital,opsz,wght@0,8..60,400;0,8..60,600;0,8..60,700;1,8..60,400&family=Inter:wght@400;500;600&display=swap"

/-- The document around each page: meta, icons, fonts and the right stylesheet. -/
def chrome : Sites.Layout Route := fun input =>
  { lang := "en"
    head := Nodes.ofList <|
      [ «meta» [.charset "utf-8"],
        «meta» [.name "viewport", .content "width=device-width, initial-scale=1.0"],
        title input.page.title,
        link [.rel "icon", .type "image/svg+xml", .href (.url "/favicon.svg")],
        link [.rel "apple-touch-icon", .href (.url "/favicon.svg")] ] ++
      (if input.page.description = "" then []
       else [«meta» [.name "description", .content input.page.description]]) ++
      (match input.route with
       | .map => [link [.rel "stylesheet", .href (.url "/map.css")]]
       | _ =>
         [ link [.rel "preconnect", .href (.url "https://fonts.googleapis.com")],
           link [.rel "preconnect", .href (.url "https://fonts.gstatic.com"), .crossorigin ""],
           link [.href (.url fontsUrl), .rel "stylesheet"],
           link [.rel "stylesheet", .href (.url "/styles.css")] ])
    body := Nodes.ofList input.page.body }

/-- fmxai.org. The map page is built from `Map.theLayout`, the layout the kernel computed and
`Map.theLayout_valid` specifies. -/
def site : Site Route :=
  { name := "FMxAI"
    routes
    routes_complete := by intro r; cases r <;> decide
    path
    urls_nodup := by decide
    page := fun
      | .home => Pages.home
      | .y2025 => Pages.y2025
      | .y2026 => Pages.y2026
      | .map => Pages.mapPage Map.theLayout
    layout := chrome }

end

end Fmxai
