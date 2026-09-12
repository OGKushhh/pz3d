// Render all 40 batch 011 assets.
const puppeteer = require('/home/z/.npm-global/lib/node_modules/@mermaid-js/mermaid-cli/node_modules/puppeteer');
const path = require('path');
const fs = require('fs');
const HTML_PATH = '/home/z/my-project/scripts/gl_renderer/render_glb.html';
const CHROME    = '/home/z/.cache/puppeteer/chrome/linux-152.0.7977.54/chrome-linux64/chrome';

// 40 batch 011 assets with appropriate camera angles
// [name, category, yaw, pitch]
const assets = [
  // Downtown (6) — large buildings, 3/4 view
  ['hospital',              'buildings', 215, 18],
  ['police_station',        'buildings', 215, 18],
  ['highrise_office',       'buildings', 215, 25],
  ['parking_garage',        'buildings', 215, 22],
  ['broadcast_tower',       'buildings', 215, 30],
  ['railway_station',       'buildings', 215, 18],
  // Farmland (4)
  ['grain_silo',            'buildings', 215, 22],
  ['windmill',              'buildings', 215, 18],
  ['tractor_shed',          'buildings', 215, 15],
  ['farmhouse',             'buildings', 215, 18],
  // Forest (4)
  ['hunting_cabin',         'buildings', 215, 18],
  ['ranger_station',        'buildings', 215, 18],
  ['camping_tent',          'buildings', 215, 15],
  ['deer_stand',            'buildings', 215, 18],
  // River/Coastal (5)
  ['lighthouse',            'buildings', 215, 25],
  ['fishing_hut',           'buildings', 215, 18],
  ['pier_dock',             'buildings', 215, 30],
  ['houseboat',             'buildings', 215, 18],
  ['bridge_section',        'buildings', 215, 25],
  // Military (5)
  ['military_checkpoint',   'buildings', 215, 22],
  ['watchtower',            'buildings', 215, 25],
  ['bunker_entrance',       'buildings', 215, 18],
  ['helipad',               'buildings', 215, 50],
  ['field_hospital_tent',   'buildings', 215, 18],
  // Subway (4)
  ['subway_platform',       'buildings', 215, 18],
  ['subway_tunnel',         'buildings', 215, 12],
  ['subway_train_car',      'buildings', 215, 15],
  ['ticket_booth',          'buildings', 215, 15],
  // Commercial (4)
  ['strip_mall',            'buildings', 215, 25],
  ['auto_repair_shop',      'buildings', 215, 18],
  ['laundromat',            'buildings', 215, 18],
  ['barber_shop',           'buildings', 215, 18],
  // Backyard building (1)
  ['treehouse',            'buildings', 215, 22],
  // Environment (5)
  ['campfire_ring',         'environment', 215, 40],
  ['barbed_wire_fence',     'environment', 215, 12],
  ['turnstile',             'environment', 215, 12],
  ['crop_field_corn',       'environment', 215, 50],
  ['seesaw',                'environment', 215, 18],
  // Props (2)
  ['basketball_hoop',       'props', 215, 12],
  ['traffic_camera',        'props', 215, 18],
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
  console.log(`\n=== Rendered ${ok}/${assets.length} (${fail} failed) ===`);
})();
