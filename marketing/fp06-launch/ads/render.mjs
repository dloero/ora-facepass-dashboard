// Render every concept x size to PNG with Playwright.
// Usage: node render.mjs [outDir] [conceptId...]
import { createRequire } from "node:module";
import { fileURLToPath, pathToFileURL } from "node:url";
import path from "node:path";
import fs from "node:fs";
import { execSync } from "node:child_process";

const require = createRequire(import.meta.url);
const globalRoot = execSync("npm root -g").toString().trim();
const { chromium } = require(path.join(globalRoot, "playwright"));

const here = path.dirname(fileURLToPath(import.meta.url));
const outDir = process.argv[2] || path.join(here, "png");
const only = process.argv.slice(3);
fs.mkdirSync(outDir, { recursive: true });

// load concept ids from concepts.js without a DOM
const src = fs.readFileSync(path.join(here, "concepts.js"), "utf8");
const win = {};
new Function("window", src)(win);
const concepts = win.FP06_CONCEPTS.filter(c => !only.length || only.includes(c.id));

const SIZES = { "11": [1080, 1080], "45": [1080, 1350], "916": [1080, 1920] };
const browser = await chromium.launch();
const page = await browser.newPage({ deviceScaleFactor: 1 });
const tpl = pathToFileURL(path.join(here, "template.html")).href;

for (const c of concepts) {
  for (const [s, [w, h]] of Object.entries(SIZES)) {
    await page.setViewportSize({ width: w, height: h });
    await page.goto(`${tpl}?c=${c.id}&s=${s}`, { waitUntil: "load" });
    await page.evaluate(async () => {
      await document.fonts.ready;
      await Promise.all([...document.images].map(i => i.complete ? null : new Promise(r => { i.onload = i.onerror = r; })));
    });
    const label = { "11": "1x1", "45": "4x5", "916": "9x16" }[s];
    const file = path.join(outDir, `${c.id}_${label}.png`);
    await page.screenshot({ path: file, clip: { x: 0, y: 0, width: w, height: h } });
    process.stdout.write(`${path.basename(file)}  `);
  }
  process.stdout.write("\n");
}
await browser.close();
console.log("done ->", outDir);
