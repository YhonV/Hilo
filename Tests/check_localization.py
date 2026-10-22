"""Validate Spanish/English catalogs, format arguments and literal UI references.
Run: python3 Tests/check_localization.py
"""
import json
from pathlib import Path
import re
import subprocess
import sys
import plistlib

ROOT = Path(__file__).resolve().parents[1] / 'Hilo'

def catalog(path):
    text = path.read_text()
    keys = re.findall(r'^\s*"((?:[^"\\]|\\.)*)"\s*=', text, re.M)
    assert len(keys) == len(set(keys)), f'Duplicate keys: {path}'
    return json.loads(subprocess.check_output(['plutil', '-convert', 'json', '-o', '-', str(path)]))

catalogs = {lang: catalog(ROOT / f'{lang}.lproj/Localizable.strings') for lang in ['en', 'es']}
assert catalogs['en'].keys() == catalogs['es'].keys(), 'Language catalogs have different keys'

def placeholders(value):
    return sorted(re.findall(r'%(?:\d+\$)?(?:\d+)?(?:\.\d+)?(?:ll|l)?[@difus]', value.replace('%%', '')))

for key, english in catalogs['en'].items():
    spanish = catalogs['es'][key]
    assert english and spanish, f'Empty translation: {key}'
    assert placeholders(english) == placeholders(spanish), f'Format mismatch: {key}'

# SwiftUI literal labels and explicit Foundation lookups must resolve in both languages.
pattern = re.compile(r'(?:String\(localized:\s*|(?:Text|Label|Button|Picker|TextField|SecureField|Tab|NavigationLink|ContentUnavailableView)\(\s*|\.(?:navigationTitle|alert|accessibilityLabel|accessibilityValue)\(\s*)"([^"\\]*)"')
for source in ROOT.rglob('*.swift'):
    text = re.sub(r'/\*.*?\*/', '', source.read_text(), flags=re.S)
    text = re.sub(r'//[^\n]*', '', text)
    for key in pattern.findall(text):
        if key:
            assert key in catalogs['en'], f'Unlocalized UI literal {key!r}: {source}'
    for key in re.findall(r'errorMessage\s*=\s*"([^"\\]+)"', text):
        assert key in catalogs['en'], f'Missing error key: {key}'

for lang in ['en', 'es']:
    permissions = catalog(ROOT / f'{lang}.lproj/InfoPlist.strings')
    assert permissions.get('NSCameraUsageDescription'), f'Missing camera prompt: {lang}'
print(f'PASS: {len(catalogs["en"])} keys in each language, matching format arguments, UI references and camera permission prompts')

# Optionally verify Xcode embedded the exact catalogs, not stale resources.
if len(sys.argv) > 1:
    app = Path(sys.argv[1])
    for lang in ['en', 'es']:
        for table in ['Localizable', 'InfoPlist']:
            expected = catalog(ROOT / f'{lang}.lproj/{table}.strings')
            with (app / f'{lang}.lproj/{table}.strings').open('rb') as resource:
                assert plistlib.load(resource) == expected, f'Stale or missing {lang}/{table} in app'
    print('PASS: both language catalogs and camera prompts are embedded in the built app')
