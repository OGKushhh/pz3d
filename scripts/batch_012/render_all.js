// Render all 36 batch 012 assets.
const puppeteer = require('/home/z/.npm-global/lib/node_modules/@mermaid-js/mermaid-cli/node_modules/puppeteer');
const path = require('path');
const fs = require('fs');
const HTML_PATH = '/home/z/my-project/scripts/gl_renderer/render_glb.html';
const CHROME    = '/home/z/.cache/puppeteer/chrome/linux-152.0.7977.54/chrome-linux64/chrome';

const assets = [
  // Fixes (2)
  ['broadcast_tower',          'buildings', 215, 25],
  ['parking_garage',           'buildings', 215, 22],
  // Heroes (4) — large, low pitch for full view
  ['government_palace',        'buildings', 215, 25],
  ['stadium',                  'buildings', 215, 30],
  ['old_royal_palace',         'buildings', 215, 25],
  ['fort_sarran',              'buildings', 215, 30],
  // Characters (5) — front view, eye-level
  ['walker_zombie_male',       'characters', 0, 5],
  ['walker_zombie_female',    'characters', 0, 5],
  ['crawler_zombie',          'characters', 0, 30],
  ['npc_survivor',            'characters', 0, 8],
  ['npc_soldier',            'characters', 0, 8],
  // Decals (4) — top-down for surface decals
  ['blood_splatter',          'decals', 0, 90],
  ['poster_torn',             'decals', 0, 90],
  ['grime_dirt',              'decals', 0, 90],
  ['crack_road',              'decals', 0, 90],
  // Forest (3)
  ['cave_entrance',           'buildings', 215, 15],
  ['logging_camp_shed',       'buildings', 215, 18],
  ['ranger_lean_to',          'buildings', 215, 18],
  // Farmland (3)
  ['irrigation_canal',        'environment', 215, 25],
  ['hay_bale',                'environment', 215, 18],
  ['grain_storage_shed',      'buildings', 215, 18],
  // Coastal (3)
  ['boardwalk_section',       'environment', 215, 18],
  ['marsh_grass',             'foliage', 215, 30],
  ['marsh_pier',              'buildings', 215, 22],
  // Subway (3)
  ['maintenance_tunnel_junction', 'buildings', 215, 15],
  ['emergency_exit_stairs',   'buildings', 215, 18],
  ['subway_pipe_cluster',     'buildings', 215, 8],
  // Military (2)
  ['mass_grave',              'environment', 215, 35],
  ['helipad_control_room',    'buildings', 215, 18],
  // Commercial (3)
  ['salon',                   'buildings', 215, 15],
  ['grocery_store',           'buildings', 215, 22],
  ['bank_branch',             'buildings', 215, 18],
  // Suburban/misc (4)
  ['bird_house',              'props', 215, 15],
  ['garden_pergola',          'props', 215, 15],
  ['apartment_tower_high',    'buildings', 215, 25],
  ['train_boxcar_derelict',   'buildings', 215, 12],
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
