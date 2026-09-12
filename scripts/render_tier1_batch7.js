// Render all 18 new/fixed assets (batch 007).
const puppeteer = require('/home/z/.npm-global/lib/node_modules/@mermaid-js/mermaid-cli/node_modules/puppeteer');
const path = require('path');
const fs = require('fs');

const HTML_PATH = '/home/z/my-project/scripts/gl_renderer/render_glb.html';
const CHROME    = '/home/z/.cache/puppeteer/chrome/linux-152.0.7977.54/chrome-linux64/chrome';

const assets = [
  ['corner_store',        '/home/z/my-project/assets/buildings/out/corner_store.glb',      215, 18, '/home/z/my-project/assets/buildings/renders'],
  ['cottage',             '/home/z/my-project/assets/buildings/out/cottage.glb',           215, 18, '/home/z/my-project/assets/buildings/renders'],
  ['apartment_small',     '/home/z/my-project/assets/buildings/out/apartment_small.glb',  215, 18, '/home/z/my-project/assets/buildings/renders'],
  ['desk',                '/home/z/my-project/assets/props/out/desk.glb',                  35, 18, '/home/z/my-project/assets/props/renders'],
  ['lamp_floor',          '/home/z/my-project/assets/props/out/lamp_floor.glb',           35, 10, '/home/z/my-project/assets/props/renders'],
  ['tv',                  '/home/z/my-project/assets/props/out/tv.glb',                    35, 12, '/home/z/my-project/assets/props/renders'],
  ['wardrobe',            '/home/z/my-project/assets/props/out/wardrobe.glb',            35, 15, '/home/z/my-project/assets/props/renders'],
  ['sink_bathroom',       '/home/z/my-project/assets/props/out/sink_bathroom.glb',       35, 15, '/home/z/my-project/assets/props/renders'],
  ['door_interior',       '/home/z/my-project/assets/props/out/door_interior.glb',       35, 8,  '/home/z/my-project/assets/props/renders'],
  ['birch_tree',          '/home/z/my-project/assets/foliage/out/birch_tree.glb',        35, 12, '/home/z/my-project/assets/foliage/renders'],
  ['dead_tree',           '/home/z/my-project/assets/foliage/out/dead_tree.glb',         35, 12, '/home/z/my-project/assets/foliage/renders'],
  ['flower_patch',        '/home/z/my-project/assets/foliage/out/flower_patch.glb',      45, 60, '/home/z/my-project/assets/foliage/renders'],
  ['fire_hydrant',        '/home/z/my-project/assets/environment/out/fire_hydrant.glb',  35, 10, '/home/z/my-project/assets/environment/renders'],
  ['dumpster',            '/home/z/my-project/assets/environment/out/dumpster.glb',     35, 15, '/home/z/my-project/assets/environment/renders'],
  ['traffic_cone',        '/home/z/my-project/assets/environment/out/traffic_cone.glb',   35, 8,  '/home/z/my-project/assets/environment/renders'],
  ['road_sign',           '/home/z/my-project/assets/environment/out/road_sign.glb',     35, 8,  '/home/z/my-project/assets/environment/renders'],
  ['dirt_road_segment',   '/home/z/my-project/assets/environment/out/dirt_road_segment.glb', 35, 50, '/home/z/my-project/assets/environment/renders'],
];

(async () => {
  const browser = await puppeteer.launch({
    executablePath: CHROME,
    headless: 'new',
    args: ['--no-sandbox','--disable-setuid-sandbox','--enable-unsafe-swiftshader','--use-angle=swiftshader','--enable-webgl','--ignore-gpu-blocklist','--disable-dev-shm-usage','--allow-file-access-from-files'],
  });
  for (const [name, glbPath, yaw, pitch, outDir] of assets) {
    if (!fs.existsSync(glbPath)) { console.log(`  X ${name}: missing GLB`); continue; }
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
      console.log(`  OK ${name} (${fs.statSync(outPath).size} bytes)`);
    } catch (e) { console.log(`  X ${name}: ${e.message}`); }
    await page.close();
  }
  await browser.close();
  console.log('done.');
})().catch(e => { console.error(e); process.exit(1); });
