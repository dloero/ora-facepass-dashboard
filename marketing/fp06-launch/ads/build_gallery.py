"""Assemble the creative-kit gallery page with previews inlined as data URIs."""
import base64, json, os, re

HERE = os.path.dirname(os.path.abspath(__file__))
prev = os.path.join(HERE, "prev")
src = open(os.path.join(HERE, "concepts.js"), encoding="utf-8").read()

def uri(name):
    return "data:image/webp;base64," + base64.b64encode(open(os.path.join(prev, name), "rb").read()).decode()

imgs = {f: uri(f) for f in sorted(os.listdir(prev)) if f.endswith(".webp")}

page = r'''<title>FP06 Creative Kit</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Archivo:wdth,wght@62..125,400..800&family=IBM+Plex+Sans:wght@400;500;600&family=IBM+Plex+Mono:wght@500;600&display=swap">
<style>
:root { --bg:#E8E4DD; --paper:#F7F5F1; --ink:#14161A; --muted:#4D515A; --line:rgba(20,22,26,.14); --accent:#C9821A; --accent-ink:#8F5A0C; --accent-soft:rgba(201,130,26,.14); --warn-bg:rgba(201,130,26,.12);
  --display:"Archivo","Arial Black",sans-serif; --body:"IBM Plex Sans","Helvetica Neue",Arial,sans-serif; --mono:"IBM Plex Mono",ui-monospace,Menlo,monospace; color-scheme: light; }
@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) { --bg:#0E1114; --paper:#171B21; --ink:#F3F0EA; --muted:#A8ADB5; --line:rgba(243,240,234,.16); --accent:#F0B248; --accent-ink:#F0B248; --accent-soft:rgba(240,178,72,.14); --warn-bg:rgba(240,178,72,.12); color-scheme: dark; } }
:root[data-theme="dark"] { --bg:#0E1114; --paper:#171B21; --ink:#F3F0EA; --muted:#A8ADB5; --line:rgba(243,240,234,.16); --accent:#F0B248; --accent-ink:#F0B248; --accent-soft:rgba(240,178,72,.14); --warn-bg:rgba(240,178,72,.12); color-scheme: dark; }
* { box-sizing: border-box; }
body { margin:0; background:var(--bg); color:var(--ink); font-family:var(--body); font-size:16px; line-height:1.5; -webkit-font-smoothing:antialiased; }
.wrap { width:min(1180px, calc(100% - 40px)); margin:0 auto; }
h1,h2,h3 { font-family:var(--display); font-variation-settings:"wdth" 116; font-weight:740; letter-spacing:-.02em; line-height:1.02; margin:0; text-wrap:balance; }
h1 { font-size:clamp(36px,5vw,60px); } h2 { font-size:28px; } h3 { font-size:20px; font-variation-settings:"wdth" 110; }
p { margin:0; text-wrap:pretty; }
.eyebrow { display:inline-flex; align-items:center; gap:10px; font-family:var(--mono); font-weight:600; font-size:12.5px; letter-spacing:.14em; text-transform:uppercase; color:var(--muted); }
.eyebrow i { width:8px; height:8px; border-radius:50%; background:var(--accent); box-shadow:0 0 0 4px var(--accent-soft); }
header { padding:56px 0 28px; border-bottom:1px solid var(--line); }
header .wrap { display:grid; grid-template-columns:1.2fr .8fr; gap:40px; align-items:end; }
header p { color:var(--muted); font-size:18px; max-width:36em; margin-top:14px; }
.stats { display:grid; grid-template-columns:repeat(3,1fr); gap:10px; }
.stat { border:1.5px solid var(--line); border-radius:14px; padding:14px 16px; background:var(--paper); }
.stat b { display:block; font-family:var(--display); font-variation-settings:"wdth" 112; font-weight:740; font-size:28px; letter-spacing:-.02em; }
.stat span { font-family:var(--mono); font-size:12px; letter-spacing:.06em; text-transform:uppercase; color:var(--muted); }
@media (max-width:860px) { header .wrap { grid-template-columns:1fr; } }
.toolbar { position:sticky; top:0; z-index:10; background:color-mix(in srgb, var(--bg) 88%, transparent); backdrop-filter:blur(10px); border-bottom:1px solid var(--line); }
.toolbar .wrap { display:flex; flex-wrap:wrap; gap:10px; align-items:center; padding:12px 0; }
.toolbar button { font:inherit; font-family:var(--mono); font-size:13px; letter-spacing:.04em; padding:8px 14px; border-radius:999px; border:1.5px solid var(--line); background:var(--paper); color:var(--ink); cursor:pointer; }
.toolbar button[aria-pressed="true"] { background:var(--ink); color:var(--bg); border-color:var(--ink); }
.toolbar .sp { flex:1; }
.toolbar .hint { font-family:var(--mono); font-size:12.5px; color:var(--muted); }
.system { padding:36px 0; display:grid; grid-template-columns:repeat(3,1fr); gap:20px; border-bottom:1px solid var(--line); }
.system > div { display:flex; flex-direction:column; gap:8px; }
.system p { color:var(--muted); font-size:15px; }
.swatches { display:flex; gap:6px; }
.swatches i { width:34px; height:34px; border-radius:8px; border:1px solid var(--line); }
@media (max-width:860px) { .system { grid-template-columns:1fr; } }
.concept { padding:44px 0; border-bottom:1px solid var(--line); }
.concept[hidden] { display:none; }
.c-head { display:flex; flex-wrap:wrap; gap:12px 20px; align-items:baseline; margin-bottom:18px; }
.c-head .id { font-family:var(--mono); font-weight:600; font-size:13px; letter-spacing:.14em; color:var(--accent-ink); }
.c-head .tags { display:flex; gap:8px; flex-wrap:wrap; margin-left:auto; }
.tag { font-family:var(--mono); font-size:12px; letter-spacing:.04em; padding:5px 10px; border-radius:999px; border:1.5px solid var(--line); color:var(--muted); }
.grid { display:grid; grid-template-columns:1.3fr 1fr; gap:28px; align-items:start; }
.shots { display:grid; grid-template-columns:auto auto auto; gap:14px; align-items:start; }
.shot { display:flex; flex-direction:column; gap:8px; }
.shot img { width:100%; height:auto; border-radius:10px; box-shadow:0 14px 30px rgba(0,0,0,.18); }
.shot .lab { font-family:var(--mono); font-size:12px; letter-spacing:.08em; color:var(--muted); display:flex; justify-content:space-between; }
.shot.r11 { width:200px; } .shot.r45 { width:200px; } .shot.r916 { width:158px; }
.copy { display:flex; flex-direction:column; gap:14px; }
.block { border:1.5px solid var(--line); border-radius:14px; background:var(--paper); padding:14px 16px; position:relative; }
.block .lab { font-family:var(--mono); font-weight:600; font-size:11.5px; letter-spacing:.12em; text-transform:uppercase; color:var(--muted); margin-bottom:8px; display:flex; justify-content:space-between; align-items:center; }
.block pre { margin:0; white-space:pre-wrap; font:inherit; font-size:15px; line-height:1.5; }
.block button { font:inherit; font-family:var(--mono); font-size:11.5px; letter-spacing:.06em; padding:4px 10px; border-radius:999px; border:1.5px solid var(--line); background:transparent; color:var(--ink); cursor:pointer; }
.block button:focus-visible, .toolbar button:focus-visible { outline:3px solid var(--accent); outline-offset:2px; }
.verify { background:var(--warn-bg); border-color:color-mix(in srgb, var(--accent) 50%, transparent); }
.verify ul { margin:0; padding-left:18px; font-size:14.5px; }
.files { font-family:var(--mono); font-size:12.5px; color:var(--muted); line-height:1.7; }
@media (max-width:960px) { .grid { grid-template-columns:1fr; } .shots { grid-template-columns:repeat(3, 1fr); } .shot.r11,.shot.r45,.shot.r916 { width:auto; } }
.howto { padding:44px 0 72px; display:grid; grid-template-columns:1fr 1fr; gap:28px; }
.howto ol, .howto ul { margin:10px 0 0; padding-left:20px; color:var(--muted); font-size:15.5px; display:flex; flex-direction:column; gap:6px; }
.howto code { font-family:var(--mono); font-size:13px; background:var(--paper); border:1px solid var(--line); padding:1px 6px; border-radius:6px; }
@media (max-width:860px) { .howto { grid-template-columns:1fr; } }
</style>
<header><div class="wrap">
  <div>
    <span class="eyebrow"><i></i>Ora FacePass · FP06 launch · September 2026</span>
    <h1 style="margin-top:12px">FP06 Creative Kit</h1>
    <p>Fourteen static concepts, each rendered at 1:1, 4:5 and 9:16 for Meta feed, Stories and Reels. Eleven for homeowners (the Lowe's retail lane), three for Colorado property managers. Every ad makes one claim, keeps the face as one option among several, and carries a Reserve or Walkthrough call to action.</p>
  </div>
  <div class="stats"><div class="stat"><b>14</b><span>Concepts</span></div><div class="stat"><b>42</b><span>Files</span></div><div class="stat"><b>3</b><span>Ratios</span></div></div>
</div></header>
<div class="toolbar"><div class="wrap">
  <button aria-pressed="true" data-f="all">All 14</button><button aria-pressed="false" data-f="homeowner">Homeowner (11)</button><button aria-pressed="false" data-f="pm">Property managers (3)</button>
  <span class="sp"></span><span class="hint">Full-resolution PNGs live in the repo under marketing/fp06-launch/ads/png</span>
</div></div>
<div class="wrap">
  <div class="system">
    <div><span class="eyebrow"><i></i>Palette</span><div class="swatches"><i style="background:#E8E4DD"></i><i style="background:#F7F5F1"></i><i style="background:#14161A"></i><i style="background:#0E1114"></i><i style="background:#C9821A"></i><i style="background:#F0B248"></i></div><p>Stone and paper for daylight concepts, dusk for night and privacy concepts. One amber accent that stands for sunlight and the unlock moment. The lock is charcoal, so every ground was picked to give it an edge.</p></div>
    <div><span class="eyebrow"><i></i>Type</span><p style="font-family:var(--display); font-variation-settings:'wdth' 118; font-weight:740; font-size:26px; color:var(--ink); letter-spacing:-.02em">Archivo, extended</p><p>Headlines in Archivo at a wide width. Body in IBM Plex Sans. Spec labels and eyebrows in IBM Plex Mono, the way a spec sheet reads.</p></div>
    <div><span class="eyebrow"><i></i>Layout rules</span><p>Product photography on a door slab, never floating. Headline never crosses the product. Text kept out of the top 14% and bottom 20% on 9:16. Minimum type size 22 px at 1080 wide so it survives a phone screen.</p></div>
  </div>
  <div id="list"></div>
  <div class="howto">
    <div><h2>How to use the kit</h2>
      <ol>
        <li>Upload the 4:5 file for feeds, 9:16 for Stories and Reels, 1:1 for Marketplace and right column. Meta will crop anything else.</li>
        <li>Paste the primary text, headline and description from the copy panel. Do not rewrite the headline in the image to match; the image and the text are meant to say two different things.</li>
        <li>Name every ad <code>OFP_FP06_HO_H03_4x5_v1</code> style: entity, product, set (HO or PM), concept, ratio, version. The concept ID matches the file name.</li>
        <li>Hold any concept with an open verify note until Jacky confirms the fact. The notes are in amber under each concept.</li>
        <li>Rotate: launch with H01, H03, H04 and H10 in the homeowner set. Add the rest after the first 48 hours of data.</li>
      </ol>
    </div>
    <div><h2>Re-render or edit</h2>
      <ul>
        <li>Source: <code>marketing/fp06-launch/ads/src/template.html</code> and <code>concepts.js</code>. Edit copy in <code>concepts.js</code>, then run <code>node render.mjs</code>.</li>
        <li>Fonts and product cutouts ship with the source, so the render is reproducible on any machine with Node and Playwright.</li>
        <li>Product images are Jacky's renders with the background removed. Do not replace them with AI-generated renders of the lock.</li>
        <li>No em dashes anywhere in copy. Sentence case. One claim per ad.</li>
      </ul>
    </div>
  </div>
</div>
<script>
__CONCEPTS__
const IMGS = __IMGS__;
const esc = s => String(s).replace(/&/g,"&amp;").replace(/</g,"&lt;");
const list = document.getElementById("list");
list.innerHTML = window.FP06_CONCEPTS.map(c => `
<section class="concept" data-set="${c.set}" id="${c.id}">
  <div class="c-head"><span class="id">${c.id}</span><h2>${esc(c.name)}</h2>
    <div class="tags"><span class="tag">${esc(c.format)}</span><span class="tag">${c.set === "pm" ? "Property managers" : "Homeowner"}</span><span class="tag">${c.theme === "dark" ? "Dusk" : "Daylight"}</span></div></div>
  <div class="grid">
    <div class="shots">
      ${[["1x1","r11","1:1 · 1080×1080"],["4x5","r45","4:5 · 1080×1350"],["9x16","r916","9:16 · 1080×1920"]].map(([r,cls,lab]) => `<figure class="shot ${cls}" style="margin:0"><img src="${IMGS[c.id + "_" + r + ".webp"]}" alt="${esc(c.name)} ${r}"><figcaption class="lab"><span>${lab}</span></figcaption></figure>`).join("")}
    </div>
    <div class="copy">
      <div class="block"><div class="lab">Primary text <button data-copy>Copy</button></div><pre>${esc(c.meta.primary)}</pre></div>
      <div class="block"><div class="lab">Headline <button data-copy>Copy</button></div><pre>${esc(c.meta.headline)}</pre></div>
      <div class="block"><div class="lab">Description <button data-copy>Copy</button></div><pre>${esc(c.meta.description)}</pre></div>
      <div class="block"><div class="lab">On the image</div><pre>${esc(c.h1)}${c.sub ? "\n" + esc(c.sub) : ""}${c.cta ? "\nCTA: " + esc(c.cta) : ""}</pre></div>
      ${c.verify && c.verify.length ? `<div class="block verify"><div class="lab">Verify before running</div><ul>${c.verify.map(v => `<li>${esc(v)}</li>`).join("")}</ul></div>` : ""}
      <div class="files">${c.id}_1x1.png · ${c.id}_4x5.png · ${c.id}_9x16.png</div>
    </div>
  </div>
</section>`).join("");
document.querySelectorAll("[data-copy]").forEach(b => b.addEventListener("click", async () => {
  const txt = b.closest(".block").querySelector("pre").innerText;
  try { await navigator.clipboard.writeText(txt); b.textContent = "Copied"; setTimeout(() => b.textContent = "Copy", 1400); } catch (e) { b.textContent = "Select and copy"; }
}));
document.querySelectorAll(".toolbar button").forEach(b => b.addEventListener("click", () => {
  document.querySelectorAll(".toolbar button").forEach(x => x.setAttribute("aria-pressed", x === b ? "true" : "false"));
  const f = b.dataset.f;
  document.querySelectorAll(".concept").forEach(s => s.hidden = !(f === "all" || s.dataset.set === f));
}));
</script>
'''
page = page.replace("__CONCEPTS__", src).replace("__IMGS__", json.dumps(imgs))
out = os.path.join(HERE, "creative-kit.html")
open(out, "w", encoding="utf-8").write(page)
print("creative-kit.html KB", os.path.getsize(out) // 1024)
