// Render all 10 new Tier 1 assets (batch 003) to PNGs.
const puppeteer = require('/home/z/.npm-global/lib/node_modules/@mermaid-js/mermaid-cli/node_modules/puppeteer');
const path = require('path');
const fs = require('fs');

const HTML_PATH = '/home/z/my-project/scripts/gl_renderer/render_glb.html';
const CHROME    = '/home/z/.cache/puppeteer/chrome/linux-152.0.7977.54/chrome-linux64/chrome';

// [name, glb_path, yaw, pitch, out_dir]
const assets = [
  ['two_story_colonial',  '/home/z/my-project/assets/buildings/out/two_story_colonial.glb',  215, 18, '/home/z/my-project/assets/buildings/renders'],
  ['bungalow',             '/home/z/my-project/assets/buildings/out/bungalow.glb',            215, 18, '/home/z/my-project/assets/buildings/renders'],
  ['bookshelf',            '/home/z/my-project/assets/props/out/bookshelf.glb',              35, 12, '/home/z/my-project/assets/props/renders'],
  ['bed_single',           '/home/z/my-project/assets/props/out/bed_single.glb',              35, 18, '/home/z/my-project/assets/props/renders'],
  ['kitchen_counter',     '/home/z/my-project/assets/props/out/kitchen_counter.glb',        35, 20, '/home/z/my-project/assets/props/renders'],
  ['refrigerator',         '/home/z/my-project/assets/props/out/refrigerator.glb',            35, 10, '/home/z/my-project/assets/props/renders'],
  ['pine_tree',            '/home/z/my-project/assets/foliage/out/pine_tree.glb',              35, 12, '/home/z/my-project/assets/foliage/renders'],
  ['grass_tuft',           '/home/z/my-project/assets/foliage/out/grass_tuft.glb',            45, 60, '/home/z/my-project/assets/foliage/renders'],
  ['picket_fence',         '/home/z/my-project/assets/environment/out/picket_fence.glb',    45, 15, '/home/z/my-project/assets/environment/renders'],
  ['street_light',         '/home/z/my-project/assets/environment/out/street_light.glb',      35, 12, '/home/z/my-project/assets/environment/renders'],
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
