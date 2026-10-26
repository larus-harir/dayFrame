"""Generate Flutter platform scaffolding separately, then apply DAYFRAME integration.
Safe to rerun; never replace existing platform files except our three Kotlin files.
"""
from pathlib import Path
import shutil
import subprocess
import tempfile
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
android = root / 'android'
if not android.exists():
    with tempfile.TemporaryDirectory(prefix='dayframe-platform-') as tmp:
        subprocess.run(['flutter', 'create', '--platforms=android', '--org', 'com.example',
                        '--project-name', 'dayframe', '--no-pub', tmp], check=True)
        shutil.copytree(Path(tmp) / 'android', android)
namespace = 'http://schemas.android.com/apk/res/android'
ET.register_namespace('android', namespace)
manifest = android / 'app/src/main/AndroidManifest.xml'
tree = ET.parse(manifest)
app = tree.getroot().find('application')
assert app is not None
attr = lambda key: f'{{{namespace}}}{key}'
for permission in ['SYSTEM_ALERT_WINDOW', 'FOREGROUND_SERVICE', 'FOREGROUND_SERVICE_SPECIAL_USE', 'POST_NOTIFICATIONS']:
    name = 'android.permission.' + permission
    if not any(x.get(attr('name')) == name for x in tree.getroot().findall('uses-permission')):
        ET.SubElement(tree.getroot(), 'uses-permission', {attr('name'): name})
if not any(x.get(attr('name')) == '.LockOverlayService' for x in app.findall('service')):
    service = ET.SubElement(app, 'service', {attr('name'): '.LockOverlayService', attr('exported'): 'false', attr('foregroundServiceType'): 'specialUse'})
    ET.SubElement(service, 'property', {attr('name'): 'android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE', attr('value'): 'User-enabled interactive lock planner overlay on screen-on'})
if not any(x.get(attr('name')) == '.LockSummaryActivity' for x in app.findall('activity')):
    ET.SubElement(app, 'activity', {attr('name'): '.LockSummaryActivity', attr('exported'): 'false',
        attr('excludeFromRecents'): 'true', attr('theme'): '@android:style/Theme.Material.NoActionBar'})
if not any(x.get(attr('name')) == '.DayframeTileService' for x in app.findall('service')):
    service = ET.SubElement(app, 'service', {attr('name'): '.DayframeTileService', attr('exported'): 'true',
        attr('label'): 'DAYFRAME', attr('icon'): '@mipmap/ic_launcher',
        attr('permission'): 'android.permission.BIND_QUICK_SETTINGS_TILE'})
    intent = ET.SubElement(service, 'intent-filter')
    ET.SubElement(intent, 'action', {attr('name'): 'android.service.quicksettings.action.QS_TILE'})
tree.write(manifest, encoding='utf-8', xml_declaration=True)
target = android / 'app/src/main/kotlin/com/example/dayframe'
target.mkdir(parents=True, exist_ok=True)
for source in (root / 'platform/android').glob('*.kt'):
    shutil.copy2(source, target / source.name)
print('Android integration prepared. Run flutter pub get, flutter analyze, flutter test, flutter run.')
