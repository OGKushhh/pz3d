// Render the suburban_house_v2 GLB from 4 angles for verification.
const puppeteer = require('/home/z/.npm-global/lib/node_modules/@mermaid-js/mermaid-cli/node_modules/puppeteer');
const path = require('path');
const fs = require('fs');

const HTML_PATH = '/home/z/my-project/scripts/gl_renderer/render_glb.html';
const GLB_PATH  = '/home/z/my-project/assets/buildings/out/suburban_house_v2.glb';
const OUT_DIR   = '/home/z/my-project/assets/buildings/renders';
const CHROME    = '/home/z/.cache/puppeteer/chrome/linux-152.0.7977.54/chrome-linux64/chrome';

if (!fs.existsSync(OUT_DIR)) fs.mkdirSync(OUT_DIR, { recursive: true });

const views = [
  // [name, yaw, pitch, title]
  ['suburban_house_v2_front',         0,    3,  'suburban_house_v2 — FRONT (yaw=0, pitch=3°) — verify door visible'],
  ['suburban_house_v2_threequarter',  35,   18, 'suburban_house_v2 — three-quarter view'],
  ['suburban_house_v2_aerial',        45,   65,  'suburban_house_v2 — aerial view'],
  ['suburban_house_v2_garage_close',  10,   5,   'suburban_house_v2 — garage door close-up'],
];

(async () => {
  const browser = await puppeteer.launch({
    executablePath: CHROME,
    headless: 'new',
    args: ['--no-sandbox','--disable-setuid-sandbox','--enable-unsafe-swiftshader','--use-angle=swiftshader','--enable-webgl','--ignore-gpu-blocklist','--disable-dev-shm-usage','--allow-file-access-from-files'],
  });

  for (const [name, yaw, pitch, title] of views) {
    const outPath = path.join(OUT_DIR, name + '.png');
    const url = `file://${HTML_PATH}?glb=file://${GLB_PATH}&size=1024&yaw=${yaw}&pitch=${pitch}&title=${encodeURIComponent(title)}`;
    const page = await browser.newPage();
    await page.setViewport({ width: 1024, height: 1024 });
    try {
      await page.goto(url, { waitUntil: 'networkidle0', timeout: 30000 });
      await page.waitForFunction('window.__RENDER_DONE__ === true', { timeout: 25000 });
      await new Promise(r => setTimeout(r, 400));
      await page.screenshot({ path: outPath, type: 'png' });
      const sz = fs.statSync(outPath).size;
      console.log(`  OK ${name} (${sz} bytes)`);
    } catch (e) {
      console.log(`  X ${name}: ${e.message}`);
    } finally {
      await page.close();
    }
  }
  await browser.close();
})().catch(e => { console.error(e); process.exit(1); });
