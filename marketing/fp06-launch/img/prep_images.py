"""Trim transparent margins from the product cutouts and write web-ready variants.

Outputs (in work/img/out):
  <name>-cut.png      trimmed, max 1700px tall, lossless PNG (ad rendering)
  <name>-web.webp     trimmed, max 1300px tall, WebP with alpha (landing page)
  <name>-prev.webp    trimmed, max 640px tall (gallery previews / inline)
  front-only-cut.png  / back-only-cut.png  split from the straight front+back shot
"""
from PIL import Image
import os, json

SRC = "/tmp/claude-0/-home-user-ora-facepass-dashboard/5b3e6d00-57af-5da7-94df-498be0aaa1a4/scratchpad/work/img"
OUT = os.path.join(SRC, "out")
os.makedirs(OUT, exist_ok=True)

def trim(im, pad=6):
    a = im.getchannel("A")
    bbox = a.getbbox()
    l, t, r, b = bbox
    l = max(0, l - pad); t = max(0, t - pad); r = min(im.width, r + pad); b = min(im.height, b + pad)
    return im.crop((l, t, r, b)), (l, t, r, b)

def save_variants(im, name, meta):
    h_cut, h_web, h_prev = 1700, 1300, 640
    for suffix, h, fmt in (("cut", h_cut, "PNG"), ("web", h_web, "WEBP"), ("prev", h_prev, "WEBP")):
        scale = min(1.0, h / im.height)
        out = im.resize((round(im.width * scale), round(im.height * scale)), Image.LANCZOS) if scale < 1 else im.copy()
        path = os.path.join(OUT, f"{name}-{suffix}.{ 'png' if fmt=='PNG' else 'webp'}")
        if fmt == "PNG":
            out.save(path, "PNG", optimize=True)
        else:
            out.save(path, "WEBP", quality=88, method=6)
        meta[f"{name}-{suffix}"] = {"w": out.width, "h": out.height, "bytes": os.path.getsize(path)}

meta = {}
names = ["front-straight", "front-angle", "front-back-straight", "front-back-angle", "interior-screen-closeup"]
for n in names:
    im = Image.open(os.path.join(SRC, n + ".png")).convert("RGBA")
    t, bbox = trim(im)
    meta[n + "-bbox"] = bbox
    save_variants(t, n, meta)

# Split the straight front+back shot into two cutouts (front is left half, back is right half)
im = Image.open(os.path.join(SRC, "front-back-straight.png")).convert("RGBA")
w = im.width
left = im.crop((0, 0, w // 2, im.height)); right = im.crop((w // 2, 0, w, im.height))
lt, _ = trim(left); rt, _ = trim(right)
save_variants(lt, "front-only", meta)
save_variants(rt, "back-only", meta)

# Same for the angled pair
im = Image.open(os.path.join(SRC, "front-back-angle.png")).convert("RGBA")
w = im.width
left = im.crop((0, 0, w // 2, im.height)); right = im.crop((w // 2, 0, w, im.height))
lt, _ = trim(left); rt, _ = trim(right)
save_variants(lt, "front-angle-only", meta)
save_variants(rt, "back-angle-only", meta)

json.dump(meta, open(os.path.join(OUT, "meta.json"), "w"), indent=1)
for k, v in meta.items():
    print(k, v)
