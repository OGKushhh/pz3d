// Render all 40 new assets from batch 008.
const puppeteer = require('/home/z/.npm-global/lib/node_modules/@mermaid-js/mermaid-cli/node_modules/puppeteer');
const path = require('path');
const fs = require('fs');
const HTML_PATH = '/home/z/my-project/scripts/gl_renderer/render_glb.html';
const CHROME    = '/home/z/.cache/puppeteer/chrome/linux-152.0.7977.54/chrome-linux64/chrome';

// All 40 new assets with their categories + render angles
const assets = [
  // Buildings (5)
  ['warehouse', 'buildings', 215, 18],
  ['gas_station', 'buildings', 215, 18],
  ['school_elementary', 'buildings', 215, 18],
  ['diner', 'buildings', 215, 18],
  ['church_small', 'buildings', 215, 18],
  // Props dynamic (10)
  ['nightstand', 'props', 35, 15],
  ['dresser', 'props', 35, 18],
  ['armchair', 'props', 35, 15],
  ['stool', 'props', 35, 12],
  ['rug', 'props', 45, 60],
  ['picture_frame', 'props', 35, 8],
  ['ceiling_lamp', 'props', 35, 8],
  ['clock_wall', 'props', 35, 8],
  ['crate_wood', 'props', 35, 15],
  ['chair_dining', 'props', 35, 15],
  // Props static (5)
  ['stove_freestanding', 'props', 35, 12],
  ['microwave', 'props', 35, 12],
  ['radiator', 'props', 35, 8],
  ['fireplace', 'props', 35, 15],
  ['stairs_wooden', 'props', 45, 25],
  // Foliage (8)
  ['hedge', 'foliage', 35, 12],
  ['weeds', 'foliage', 45, 60],
  ['fallen_log', 'foliage', 35, 20],
  ['rocks_small', 'foliage', 35, 20],
  ['mushrooms', 'foliage', 45, 50],
  ['fern', 'foliage', 35, 15],
  ['cattail', 'foliage', 35, 15],
  ['palm_tree', 'foliage', 35, 12],
  // Environment (12)
  ['chain_link_fence', 'environment', 35, 12],
  ['wood_fence_post', 'environment', 35, 8],
  ['traffic_light', 'environment', 35, 10],
  ['parking_meter', 'environment', 35, 8],
  ['bench_park', 'environment', 35, 15],
  ['manhole_cover', 'environment', 45, 60],
  ['sewer_grate', 'environment', 45, 60],
  ['bollard', 'environment', 35, 8],
  ['planter_box', 'environment', 35, 15],
  ['power_pole', 'environment', 35, 15],
  ['barrier_concrete', 'environment', 35, 15],
  ['sandbag', 'environment', 35, 15],
];

(async () => {
  const browser = await puppeteer.launch({
    executablePath: CHROME, headless: 'new',
    args: ['--no-sandbox','--disable-setuid-sandbox','--enable-unsafe-swiftshader','--use-angle=swiftshader','--enable-webgl','--ignore-gpu-blocklist','--disable-dev-shm-usage','--allow-file-access-from-files'],
  });
  let ok = 0, fail = 0;
  for (const [name, cat, yaw, pitch] of assets) {
    const glbPath = `/home/z/my-project/assets/${cat}/out/${name}.glb`;
    const outDir = `/home/z/my-project/assets/${cat}/renders`;
    if (!fs.existsSync(glbPath)) { console.log(`  X ${name}: missing GLB`); fail++; continue; }
    if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });
    const outPath = path.join(outDir, name + '.png');
    const url = `file://${HTML_PATH}?glb=file://${glbPath}&size=1024&yaw=${yaw}&pitch=${pitch}&title=${name}`;
    const page = await browser.newPage();
    await page.setViewport({ width: 1024, height: 1024 });
    try {
      await page.goto(url, { waitUntil: 'networkidle0', timeout: 30000 });
      await page.waitForFunction('window.__RENDER_DONE__ === true', { timeout: 25000 });
      await new Promise(r => setTimeout(r, 300));
      await page.screenshot({ path: outPath, type: 'png' });
      console.log(`  OK ${name}`);
      ok++;
    } catch (e) { console.log(`  X ${name}: ${e.message}`); fail++; }
    await page.close();
  }
  await browser.close();
  console.log(`\nDone: ${ok} OK, ${fail} failed`);
})().catch(e => { console.error(e); process.exit(1); });
