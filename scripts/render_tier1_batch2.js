// Render the 4 new Tier 1 assets (#6-9) to PNGs.
const puppeteer = require('/home/z/.npm-global/lib/node_modules/@mermaid-js/mermaid-cli/node_modules/puppeteer');
const path = require('path');
const fs = require('fs');

const HTML_PATH = '/home/z/my-project/scripts/gl_renderer/render_glb.html';
const CHROME    = '/home/z/.cache/puppeteer/chrome/linux-152.0.7977.54/chrome-linux64/chrome';

// [name, glb_path, yaw, pitch, out_dir]
const assets = [
  ['sedan',                  '/home/z/my-project/assets/vehicles/out/sedan.glb',          30, 12, '/home/z/my-project/assets/vehicles/renders'],
  ['pickup_truck',           '/home/z/my-project/assets/vehicles/out/pickup_truck.glb',  30, 12, '/home/z/my-project/assets/vehicles/renders'],
  ['blood_splatter_decal',   '/home/z/my-project/assets/decals/out/blood_splatter_decal.glb',  45, 60, '/home/z/my-project/assets/decals/renders'],
  ['asphalt_road_segment',   '/home/z/my-project/assets/environment/out/asphalt_road_segment.glb',  45, 50, '/home/z/my-project/assets/environment/renders'],
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
