# Ora FacePass FP06 launch campaign

Everything for the FP06MY26 launch: the ad creative kit, the campaign swipe file, and the landing page.
Built September 9, 2026. Entity: Ora FacePass LLC. Run by Peak Revenue Partners under the ISO agreement.

## Shareable pages

| Deliverable | Link | What it is |
|---|---|---|
| Creative kit | https://claude.ai/code/artifact/203b1294-3127-40dd-b43a-b2dc1fb3d204 | 14 concepts x 3 ratios with paste-ready Meta copy and verify flags |
| Swipe file | https://claude.ai/code/artifact/97fa9229-8505-45c5-9e50-d30e4e797c5c | Campaign build, copy bank, hooks, scripts, GHL sequences, guardrails, 14-day test |
| Landing page | https://claude.ai/code/artifact/816e7281-a83d-4bfa-b505-dceb59e185fd | Launch-list page with the reserve form and a property manager section |

## The decision

Run the FP06 as a launch-list (reservation) campaign until Jacky confirms price, ship date, and retail availability.
Homeowner track feeds the Lowe's retail lane. Property manager track feeds the Colorado multifamily lane.

## Confirmed vs. assumed

- Confirmed (Jacky Shi, Aug 30, 2026): solar panel charging, dual-battery design, dual cameras (full-body doorbell cam plus package monitoring), 4-inch HD interior screen with two-way intercom, patented triangle latch.
- MY26-line facts assumed to carry over (confirm before public use): 3D IR face recognition under 0.5 s, works in darkness and offline, on-device encrypted biometrics, IP65, 2.4 GHz Wi-Fi with Alexa and Google Home, USB-C emergency port, 14 days of video on device, 2-yr electronics and 3-yr mechanical warranty.
- Not confirmed for FP06: palm vein (hold concept H07), price, ship date, install time, face capacity, any monthly fee.
- Never say: "no subscription", a monthly fee, "at Lowe's", cloud storage, Apple Home, Z-Wave, "never needs charging".

## Folder map

```
ads/
  template.html      ad template (HTML/CSS), reads ?c=H01&s=11|45|916
  concepts.js        all 14 concepts: on-image copy, Meta copy, verify flags (single source of truth)
  render.mjs         node render.mjs [outDir] [ids...]  -> PNGs via Playwright
  build_gallery.py   builds creative-kit.html from concepts.js + prev/ thumbnails
  creative-kit.html  the gallery page (self-contained)
  png/               42 final ads: <ID>_1x1.png, <ID>_4x5.png, <ID>_9x16.png
  sheet_*.jpg        contact sheets for a quick review
fonts/               Archivo, IBM Plex Sans, IBM Plex Mono (woff2, latin)
img/out/             product cutouts (transparent) at render and web sizes; prep_images.py rebuilds them from the 2560px sources
landing/
  index.html + img/  the standalone landing page (host on an Ora-owned domain)
  landing.template.html, build.py   source and the build that makes index.html and the inline-image artifact version
swipe/
  swipe-file.html    the campaign playbook (self-contained)
  swipe.template.html
```

## Re-render the ads

```
cd marketing/fp06-launch/ads
node render.mjs ./png            # all concepts
node render.mjs ./png H03 P01    # selected concepts
```
Requires Node and Playwright with Chromium. Edit copy in `concepts.js`, not in the PNGs.
Then `python3 build_gallery.py` to refresh the gallery (needs the `prev/` thumbnails, rebuilt from `png/` with Pillow).

## Landing page wiring

- Set `GHL_WEBHOOK_URL` in the script at the bottom of `landing/index.html` to the Ora FacePass GHL sub-account inbound webhook.
- Delete the `#review-banner` block before the page goes public.
- Host on an Ora FacePass domain (for example fp06.orafacepass.com) with the Meta pixel installed. Not on a PRP domain.

## Ownership

Ad account, page, pixel, domain, GHL sub-account, sending mailbox, SMS number: all owned by Ora FacePass LLC with PRP holding partner access. Details in the swipe file, section 11.
