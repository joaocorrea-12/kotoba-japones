"""Verificações portáveis de conteúdo e referências; não compila nem executa Swift."""
from pathlib import Path
import json, re, struct

ROOT = Path(__file__).resolve().parents[1]
source = ROOT/'Packages/KotobaCore/Sources/KotobaCore/Resources/words.json'
words = json.loads(source.read_text(encoding='utf-8'))
assert len(words) >= 100
assert len({w['id'] for w in words}) == len(words)
assert len({w['japanese'] for w in words}) == len(words)
fields = ['id','japanese','kana','romaji','meaning','partOfSpeech','example','exampleMeaning','note']
for word in words:
    assert all(isinstance(word[k],str) and word[k].strip() for k in fields), word['id']
    assert 1 <= word['jlpt'] <= 5
    assert re.fullmatch(r'[\u3041-\u3096ー・\s]+', word['kana']), word['id']
    assert word['example'].endswith(('。','！','？'))
assert source.read_bytes() == (ROOT/'web-prototype/dist/words.json').read_bytes(), 'Vocabulários divergentes'
for relative in ['iOS/App','iOS/Shared','iOS/Widgets','iOS/Tests','Packages/KotobaCore/Tests/KotobaCoreTests','project.yml','README.md','docs/TESTES.md']:
    assert (ROOT/relative).exists(), relative
for file in ROOT.rglob('*.json'):
    if '.git' not in file.parts: json.loads(file.read_text(encoding='utf-8'))
png=(ROOT/'iOS/App/Assets.xcassets/AppIcon.appiconset/Kotoba-1024.png').read_bytes()
assert png[:8]==b'\x89PNG\r\n\x1a\n'
assert struct.unpack('!II',png[16:24])==(1024,1024)
for swift in (ROOT/'iOS').rglob('*.swift'):
    text=swift.read_text(encoding='utf-8')
    assert '.accessibilityLanguage(' not in text, 'Modificador SwiftUI inexistente'
    assert 'TODO' not in text and 'fatalError(' not in text, swift
print(f'OK: {len(words)} palavras únicas e completas; kana, JSON, assets e referências validados.')
print('Esta verificação não substitui swift test, xcodebuild ou revisão linguística humana.')
