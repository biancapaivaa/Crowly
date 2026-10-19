"""Patch idempotente dos arquivos gerados pelo flutter create."""
from pathlib import Path
import plistlib
import xml.etree.ElementTree as ET

root=Path(__file__).resolve().parents[1]
android=root/'android/app/src/main/AndroidManifest.xml'
if android.exists():
    text=android.read_text()
    if 'android.permission.INTERNET' not in text:
        text=text.replace('<application', '<uses-permission android:name="android.permission.INTERNET"/>\n    <application',1)
    if 'io.crowly.app' not in text:
        text=text.replace('</activity>', '''<intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="io.crowly.app" android:host="login-callback" />
            </intent-filter>
        </activity>''',1)
    text=text.replace('android:label="crowly"','android:label="CROWLY"')
    ET.fromstring(text)
    android.write_text(text)
ios=root/'ios/Runner/Info.plist'
if ios.exists():
    data=plistlib.loads(ios.read_bytes())
    data['CFBundleDisplayName']='CROWLY'
    urls=data.setdefault('CFBundleURLTypes',[])
    if not any('io.crowly.app' in entry.get('CFBundleURLSchemes',[]) for entry in urls):
        urls.append({'CFBundleURLName':'io.crowly.app','CFBundleURLSchemes':['io.crowly.app']})
    ios.write_bytes(plistlib.dumps(data))
print('Plataformas configuradas.')
