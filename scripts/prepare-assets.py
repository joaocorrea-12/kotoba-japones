"""Gera o ícone original, sem dependências, e mantém o vocabulário da prévia igual ao Swift."""
from pathlib import Path
import json, shutil, struct, zlib

ROOT = Path(__file__).resolve().parents[1]
assets = ROOT / 'iOS/App/Assets.xcassets'
icon = assets / 'AppIcon.appiconset'
icon.mkdir(parents=True, exist_ok=True)
(assets / 'Contents.json').write_text(json.dumps({'info': {'author': 'xcode', 'version': 1}}, indent=2)+'\n')
(icon / 'Contents.json').write_text(json.dumps({'images': [{'filename': 'Kotoba-1024.png', 'idiom': 'universal', 'platform': 'ios', 'size': '1024x1024'}], 'info': {'author': 'xcode', 'version': 1}}, indent=2)+'\n')
size = 1024
bg = (48,77,62)
fg = (245,244,238)
rectangles = [(430,165,594,237),(225,297,799,359),(307,430,717,492),(307,553,717,615),(287,686,737,891)]
hole = (358,748,666,830)
raw = bytearray()
for y in range(size):
    raw.append(0)
    for x in range(size):
        filled = any(a <= x < c and b <= y < d for a,b,c,d in rectangles)
        if hole[0] <= x < hole[2] and hole[1] <= y < hole[3]: filled = False
        raw.extend(fg if filled else bg)
def chunk(tag, data):
    return struct.pack('!I', len(data)) + tag + data + struct.pack('!I', zlib.crc32(tag+data)&0xffffffff)
png = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('!2I5B', size,size,8,2,0,0,0)) + chunk(b'IDAT', zlib.compress(raw,9)) + chunk(b'IEND',b'')
(icon / 'Kotoba-1024.png').write_bytes(png)
shutil.copyfile(ROOT/'Packages/KotobaCore/Sources/KotobaCore/Resources/words.json', ROOT/'web-prototype/dist/words.json')
print('Ícone original RGB 1024×1024 e vocabulário da prévia preparados.')
