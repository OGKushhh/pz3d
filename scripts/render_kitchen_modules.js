// Render the 4 modular kitchen pieces + a combined "demo layout" PNG.
// Layout: [empty_counter] [stove_unit] [empty_counter] [sink_unit] + 2 wall cabinets above.
// This shows how the modular pieces fit together to form a kitchen.

const puppeteer = require('/home/z/.npm-global/lib/node_modules/@mermaid-js/mermaid-cli/node_modules/puppeteer');
const path = require('path');
const fs = require('fs');

const HTML_PATH = '/home/z/my-project/scripts/gl_renderer/render_glb.html';
const CHROME    = '/home/z/.cache/puppeteer/chrome/linux-152.0.7977.54/chrome-linux64/chrome';

const assets = [
  ['kitchen_sink_unit',      '/home/z/my-project/assets/props/out/kitchen_sink_unit.glb',      35, 12, '/home/z/my-project/assets/props/renders'],
  ['kitchen_stove_unit',     '/home/z/my-project/assets/props/out/kitchen_stove_unit.glb',     35, 12, '/home/z/my-project/assets/props/renders'],
  ['kitchen_empty_counter',  '/home/z/my-project/assets/props/out/kitchen_empty_counter.glb',  35, 12, '/home/z/my-project/assets/props/renders'],
  ['kitchen_wall_cabinet',   '/home/z/my-project/assets/props/out/kitchen_wall_cabinet.glb',   35, 8,  '/home/z/my-project/assets/props/renders'],
];

(async () => {
  const browser = await puppeteer.launch({
    executablePath: CHROME,
    headless: 'new',
    args: ['--no-sandbox','--disable-setuid-sandbox','--enable-unsafe-swiftshader','--use-angle=swiftshader','--enable-webgl','--ignore-gpu-blocklist','--disable-dev-shm-usage','--allow-file-access-from-files'],
  });

  for (const [name, glbPath, yaw, pitch, outDir] of assets) {
    if (!fs.existsSync(glbPath)) {
      console.log(`  X ${name}: missing GLB`);
      continue;
    }
    if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });
    const outPath = path.join(outDir, name + '.png');
    const url = `file://${HTML_PATH}?glb=file://${glbPath}&size=1024&yaw=${yaw}&pitch=${pitch}&title=${name}`;
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
  console.log('done.');
})().catch(e => { console.error(e); process.exit(1); });
