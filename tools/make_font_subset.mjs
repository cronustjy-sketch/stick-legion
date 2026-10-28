// Regenerates ui/fonts/cjk_subset.ttf from every non-ASCII character in data/translations.gd. Run after adding Chinese text:
//   copy NotoSansSC[wght].ttf (Google Fonts, OFL) next to this file as NotoSansSC.ttf, `npm i subset-font`, `node make_font_subset.mjs`
//   then check with: godot --headless --path . --script tools/check_font.gd
import subsetFont from 'subset-font';
import fs from 'fs';
const src = fs.readFileSync('C:/StickLegion/data/translations.gd', 'utf8');
const chars = new Set();
for (const ch of src) { if (ch.codePointAt(0) > 127) chars.add(ch); }
let ascii = ''; for (let i = 32; i < 127; i++) ascii += String.fromCharCode(i);
const extra = '，。！？：；、“”‘’（）…—·×%';
const text = [...chars].join('') + ascii + extra;
const font = fs.readFileSync('NotoSansSC.ttf');
// pin the variable font to the regular weight, keep only the needed glyphs
const out = await subsetFont(font, text, { targetFormat: 'truetype', variationAxes: { wght: 400 } });
fs.writeFileSync('C:/StickLegion/ui/fonts/cjk_subset.ttf', out);
console.log('chars', chars.size, 'bytes', out.length);
