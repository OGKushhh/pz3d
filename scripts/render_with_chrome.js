// Render MoGen GLB files via Chrome + three.js (real WebGL PBR rendering).
// Launches headless Chrome, loads render_glb.html with a query string for
// each GLB, waits for the render to complete, screenshots to PNG.

// Use the puppeteer that ships with mermaid-cli (already installed globally)
const puppeteer = require('/home/z/.npm-global/lib/node_modules/@mermaid-js/mermaid-cli/node_modules/puppeteer');
const path = require('path');
const fs = require('fs');

const HTML_PATH = '/home/z/my-project/scripts/gl_renderer/render_glb.html';
const GLB_DIR   = '/home/z/my-project/mogen-examples';
const OUT_DIR   = '/home/z/my-project/download/mogen-lookbook';
const CHROME    = '/home/z/.cache/puppeteer/chrome/linux-152.0.7977.54/chrome-linux64/chrome';

if (!fs.existsSync(OUT_DIR)) fs.mkdirSync(OUT_DIR, { recursive: true });

const scenes = [
  // [out_name, glb_base, yaw_deg, pitch_deg, title]
  ['chair',                  'chair',              35,  18, 'chair.mog — 6 nodes, 1.1k tris, 1 material'],
  ['table',                  'table',              35,  18, 'table.mog — 396 tris'],
  ['cup',                    'cup',                35,  12, 'cup.mog — 150 tris'],
  ['fence',                  'fence',              60,  12, 'fence.mog — 318 tris, 31 meshes'],
  ['suburban_house',         'suburban_house',     45,  22, 'suburban_house.mog — 49 nodes, 2.8k tris, 11 materials'],
  ['suburban_house_aerial',  'suburban_house',     45,  65, 'suburban_house.mog — aerial'],
  ['suburban_house_street',  'suburban_house',      8,   5, 'suburban_house.mog — street view'],
  ['simple_house',           'simple_house',       35,  22, 'simple_house.mog — 12 nodes'],
  ['broken_window',          'broken_window',      35,  15, 'broken_window.mog — CSG difference demo'],
  ['humanoid',               'humanoid',           35,   8, 'humanoid.mog — DSL character, skinned rig'],
  ['humanoid_side',          'humanoid',           90,   3, 'humanoid.mog — side view'],
];

(async () => {
  const browser = await puppeteer.launch({
    executablePath: CHROME,
    headless: 'new',
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--enable-unsafe-swiftshader',
      '--use-angle=swiftshader',
      '--enable-webgl',
      '--ignore-gpu-blocklist',
      '--disable-dev-shm-usage',
      '--allow-file-access-from-files',
    ],
  });

  for (const [outName, glbBase, yaw, pitch, title] of scenes) {
    const glbPath = path.join(GLB_DIR, glbBase + '.glb');
    if (!fs.existsSync(glbPath)) {
      console.log(`  X ${outName}: missing GLB ${glbPath}`);
      continue;
    }
    const outPath = path.join(OUT_DIR, outName + '.png');
    const url = `file://${HTML_PATH}?glb=file://${glbPath}&size=1024&yaw=${yaw}&pitch=${pitch}&title=${encodeURIComponent(title)}`;

    const page = await browser.newPage();
    await page.setViewport({ width: 1024, height: 1024 });

    let errText = '';
    page.on('console',  m => { if (m.type() === 'error') errText += m.text() + '\n'; });
    page.on('pageerror', e => { errText += e.message + '\n'; });

    try {
      await page.goto(url, { waitUntil: 'networkidle0', timeout: 30000 });
      // wait for our readiness flag
      await page.waitForFunction('window.__RENDER_DONE__ === true', { timeout: 25000 });
      // small extra delay so the canvas finishes painting
      await new Promise(r => setTimeout(r, 300));
      await page.screenshot({ path: outPath, type: 'png' });
      const sz = fs.statSync(outPath).size;
      console.log(`  OK ${outName} -> ${path.basename(outPath)} (${sz} bytes)${errText ? '  [errors: ' + errText.trim() + ']' : ''}`);
    } catch (e) {
      console.log(`  X ${outName}: ${e.message}${errText ? '  [errors: ' + errText.trim() + ']' : ''}`);
    } finally {
      await page.close();
    }
  }

  await browser.close();
  console.log('done.');
})();
