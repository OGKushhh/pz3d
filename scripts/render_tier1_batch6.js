// Render all 10 new assets (batch 006) to PNGs.
const puppeteer = require('/home/z/.npm-global/lib/node_modules/@mermaid-js/mermaid-cli/node_modules/puppeteer');
const path = require('path');
const fs = require('fs');

const HTML_PATH = '/home/z/my-project/scripts/gl_renderer/render_glb.html';
const CHROME    = '/home/z/.cache/puppeteer/chrome/linux-152.0.7977.54/chrome-linux64/chrome';

const assets = [
  ['shed',                '/home/z/my-project/assets/buildings/out/shed.glb',                215, 18, '/home/z/my-project/assets/buildings/renders'],
  ['garage_detached',     '/home/z/my-project/assets/buildings/out/garage_detached.glb',     215, 18, '/home/z/my-project/assets/buildings/renders'],
  ['sofa',                '/home/z/my-project/assets/props/out/sofa.glb',                     35, 15, '/home/z/my-project/assets/props/renders'],
  ['coffee_table',        '/home/z/my-project/assets/props/out/coffee_table.glb',            35, 18, '/home/z/my-project/assets/props/renders'],
  ['toilet',              '/home/z/my-project/assets/props/out/toilet.glb',                  35, 12, '/home/z/my-project/assets/props/renders'],
  ['bathtub',             '/home/z/my-project/assets/props/out/bathtub.glb',                35, 20, '/home/z/my-project/assets/props/renders'],
  ['mailbox',              '/home/z/my-project/assets/environment/out/mailbox.glb',            35, 10, '/home/z/my-project/assets/environment/renders'],
  ['trash_can',           '/home/z/my-project/assets/environment/out/trash_can.glb',          35, 12, '/home/z/my-project/assets/environment/renders'],
  ['birch_tree',          '/home/z/my-project/assets/foliage/out/birch_tree.glb',            35, 12, '/home/z/my-project/assets/foliage/renders'],
  ['brick_wall_segment',  '/home/z/my-project/assets/environment/out/brick_wall_segment.glb', 35, 15, '/home/z/my-project/assets/environment/renders'],
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
