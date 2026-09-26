import Sites
import Fmxai

/-!
# `fmxai build [DIR]` / `fmxai serve [PORT]`

The site is the constant `Fmxai.site`; the map layout inside it was computed and checked when
`Fmxai.Map.Verified` compiled. Everything under `public/` is copied into the output next to
the generated pages.
-/

open Sites Std Std.Http Std.Async

/-- The static assets. -/
def publicDir : System.FilePath := "public"

/-- Copies `public/` into `out/`. -/
def copyPublic (out : System.FilePath) : IO Unit := do
  for entry in ← publicDir.walkDir do
    unless ← entry.isDir do
      let rel := (entry.toString.drop (publicDir.toString.length + 1)).toString
      let dst := out / rel
      if let some parent := dst.parent then IO.FS.createDirAll parent
      IO.FS.writeBinFile dst (← IO.FS.readBinFile entry)

/-- Content type of a static file, by extension. -/
def contentType (p : System.FilePath) : String :=
  match p.extension with
  | some "css" => "text/css; charset=utf-8"
  | some "svg" => "image/svg+xml"
  | some "png" => "image/png"
  | some "jpg" | some "jpeg" => "image/jpeg"
  | some "avif" => "image/avif"
  | _ => "application/octet-stream"

/-- Serves pages from memory and static files from `public/`. Development only. -/
def respond (site : Site Fmxai.Route) (req : Request Body.Stream) :
    ContextAsync (Response Body.Any) := do
  let target := toString req.line.uri
  let path := (target.splitOn "?").headD "/"
  match site.lookup path with
  | some (content, ctype) =>
    let resp ← (Response.ok.header! "Content-Type" ctype).fromBytes content.toUTF8
    return { resp with body := .ofBody resp.body }
  | none =>
    let file := publicDir / (path.drop 1).toString
    if !(path.splitOn "/").contains ".." && (← file.pathExists) && !(← file.isDir) then
      let bytes ← IO.FS.readBinFile file
      let resp ← (Response.ok.header! "Content-Type" (contentType file)).fromBytes bytes
      return { resp with body := .ofBody resp.body }
    else
      let resp ← (Response.notFound.header! "Content-Type" "text/html; charset=utf-8").fromBytes
        ((notFoundDoc (ρ := Fmxai.Route)).toString site.url).toUTF8
      return { resp with body := .ofBody resp.body }

/-- Serves on `127.0.0.1:port`. -/
def serve (site : Site Fmxai.Route) (port : UInt16) : IO Unit := do
  IO.println s!"Serving {site.name} at http://127.0.0.1:{port}/"
  Async.block do
    let server ← Server.serve (.v4 { addr := .ofParts 127 0 0 1, port })
      (Server.Handler.ofFn (respond site))
    server.waitShutdown

/-- `build [DIR]` or `serve [PORT]`. -/
def main (args : List String) : IO UInt32 := do
  let site := Fmxai.site
  let build (out : System.FilePath) : IO UInt32 := do
    site.build out
    copyPublic out
    IO.println s!"wrote {out}/"
    return 0
  match args with
  | ["build"] => build "dist"
  | ["build", out] => build out
  | ["serve"] => serve site 8080; return 0
  | ["serve", port] =>
    match port.toNat? with
    | some p => serve site p.toUInt16; return 0
    | none => IO.eprintln (Sites.Cli.usage "fmxai"); return 1
  | _ => IO.eprintln (Sites.Cli.usage "fmxai"); return 1
