"""Abre o APK no emulador conectado, confere a tela Hoje e salva evidência real."""
from pathlib import Path
import subprocess, time, xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
output = ROOT / 'work/android-smoke'
output.mkdir(parents=True, exist_ok=True)

def adb(*arguments):
    return subprocess.run(['adb', *arguments], check=True, capture_output=True, text=True).stdout

adb('shell', 'am', 'start', '-W', '-n', 'org.kotoba.android/.MainActivity')
deadline = time.monotonic() + 45
visible = []
while time.monotonic() < deadline:
    time.sleep(2)
    try:
        adb('shell', 'uiautomator', 'dump', '/sdcard/kotoba-ui.xml')
        adb('pull', '/sdcard/kotoba-ui.xml', str(output / 'ui.xml'))
        tree = ET.parse(output / 'ui.xml')
        visible = [element.get('text', '') for element in tree.iter()]
        if any('Um pouco' in text for text in visible) and any('PALAVRA DO MOMENTO' in text for text in visible):
            break
    except (subprocess.CalledProcessError, ET.ParseError):
        pass
else:
    (output / 'logcat.txt').write_text(adb('shell', 'logcat', '-d', '-t', '400'), encoding='utf-8')
    raise AssertionError('A tela Hoje não apareceu no emulador: ' + repr(visible))
adb('shell', 'screencap', '-p', '/sdcard/kotoba-android.png')
adb('pull', '/sdcard/kotoba-android.png', str(output / 'kotoba-android.png'))
print('OK: app nativo abriu a tela Hoje com palavra do momento no emulador Android.')
