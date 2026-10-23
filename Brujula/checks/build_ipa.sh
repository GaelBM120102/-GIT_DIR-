#!/bin/bash
# Runs on macOS with Xcode. Produces an unsigned IPA for local signing on Windows.
set -euo pipefail
brujula_root="$(cd "$(dirname "$0")/.." && pwd)"
brujula_output="${BRUJULA_BUILD_DIR:-$brujula_root/build}"

mkdir -p "$brujula_output"
xcodebuild \
  -project "$brujula_root/Brujula.xcodeproj" \
  -scheme Brujula \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$brujula_output/DerivedData" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY='' \
  build

brujula_app="$brujula_output/DerivedData/Build/Products/Release-iphoneos/Brujula.app"
test -d "$brujula_app"
test -f "$brujula_app/Brujula"
brujula_staging="$(mktemp -d "$brujula_output/package.XXXXXX")"
trap 'rm -rf "$brujula_staging"' EXIT
mkdir -p "$brujula_staging/Payload"
ditto "$brujula_app" "$brujula_staging/Payload/Brujula.app"
ditto -c -k --keepParent "$brujula_staging/Payload" "$brujula_output/GAPPEL-sin-firmar.ipa"
lipo "$brujula_app/Brujula" -verify_arch arm64
python3 - "$brujula_output/GAPPEL-sin-firmar.ipa" <<'PY'
import plistlib
import sys
import zipfile

with zipfile.ZipFile(sys.argv[1]) as package:
    assert package.testzip() is None, 'El IPA contiene un archivo corrupto'
    prefix = 'Payload/Brujula.app/'
    info = plistlib.loads(package.read(prefix + 'Info.plist'))
    assert info['CFBundleDisplayName'] == 'GAPPEL', info
    assert info['CFBundleName'] == 'GAPPEL', info
    assert info['CFBundleExecutable'] == 'Brujula', info
    assert info['CFBundleSupportedPlatforms'] == ['iPhoneOS'], info
    assert info['MinimumOSVersion'] == '17.0', info
    assert float(info['MinimumOSVersion']) >= 17
    assert prefix + info['CFBundleExecutable'] in package.namelist()
    assert len(info['UIAppFonts']) == 2
    for font in info['UIAppFonts']:
        assert prefix + font in package.namelist(), font
    assert prefix + 'Assets.car' in package.namelist()
    print('IPA verificado: GAPPEL, iPhoneOS, arm64, iOS 17+, icono y ambas fuentes incluidos.')
PY
shasum -a 256 "$brujula_output/GAPPEL-sin-firmar.ipa" > "$brujula_output/SHA256.txt"
printf '%s\n' 'IPA creado. Debe firmarse con tu cuenta gratuita de Apple desde Sideloadly antes de instalarlo.'
