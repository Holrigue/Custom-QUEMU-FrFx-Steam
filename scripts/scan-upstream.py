"""Read official upstream metadata; never download or execute installers."""
import argparse
import json
import re
import urllib.request
from pathlib import Path

FIREFOX = 'https://product-details.mozilla.org/1.0/firefox_versions.json'
STEAM_CLIENT = 'https://client-update.akamai.steamstatic.com/steam_client_ubuntu12'
STEAM_LAUNCHER = 'https://repo.steampowered.com/steam/dists/stable/steam/binary-amd64/Packages'

def fetch(url):
    request = urllib.request.Request(url, headers={'User-Agent': 'steam-usb-version-check/1.0'})
    with urllib.request.urlopen(request, timeout=30) as response:
        if not response.geturl().startswith('https://'):
            raise ValueError('HTTPS required')
        data = response.read(2_000_001)
    if len(data) > 2_000_000:
        raise ValueError('Metadata exceeds size limit')
    return data.decode('utf-8')

def parse_versions(firefox_text, client_text, launcher_text):
    version = json.loads(firefox_text)['LATEST_FIREFOX_VERSION']
    if not isinstance(version, str) or not re.fullmatch(r'\d+\.\d+(?:\.\d+)?', version):
        raise ValueError('Unexpected stable Firefox version')
    build = re.search(r'^\s*"ubuntu12"\s*\{\s*"version"\s*"(\d+)"', client_text)
    if not build:
        raise ValueError('Steam client manifest format changed')
    packages = []
    for paragraph in launcher_text.strip().split('\n\n'):
        fields = dict(line.split(': ', 1) for line in paragraph.splitlines()
                      if line and not line[0].isspace() and ': ' in line)
        if fields.get('Package') == 'steam-launcher' and fields.get('Architecture') == 'amd64':
            packages.append(fields)
    if len(packages) != 1:
        raise ValueError('Expected exactly one stable Steam launcher')
    package = packages[0]
    if not re.fullmatch(r'[0-9a-f]{64}', package['SHA256']):
        raise ValueError('Invalid launcher digest')
    if not re.fullmatch(r'[0-9A-Za-z.+:~_-]+', package['Version']):
        raise ValueError('Invalid launcher version')
    filename = package['Filename']
    if not filename.startswith('pool/') or '..' in filename or not re.fullmatch(r'[A-Za-z0-9_./+~-]+', filename):
        raise ValueError('Unexpected launcher path')
    return {
        'schema': 1,
        'firefox': {'channel': 'stable', 'version': version, 'source': FIREFOX},
        'steam_client_linux': {'channel': 'stable', 'build': build.group(1),
                               'source': STEAM_CLIENT},
        'steam_launcher_linux': {'version': package['Version'],
                                 'sha256': package['SHA256'], 'source': STEAM_LAUNCHER,
                                 'download': 'https://repo.steampowered.com/steam/' + filename},
        'compatibility': 'not_tested_by_this_scan'
    }

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, default=Path(__file__).resolve().parents[1]/'versions/upstream.json')
    args = parser.parse_args()
    # Fetch and validate everything before replacing any previously valid record.
    result = parse_versions(fetch(FIREFOX), fetch(STEAM_CLIENT), fetch(STEAM_LAUNCHER))
    encoded = json.dumps(result, indent=2, ensure_ascii=False) + '\n'
    if args.output.exists() and args.output.read_text(encoding='utf-8') == encoded:
        print('No upstream version changes.')
        return
    args.output.parent.mkdir(parents=True, exist_ok=True)
    temporary = args.output.with_suffix('.tmp')
    temporary.write_text(encoded, encoding='utf-8')
    temporary.replace(args.output)
    print('Updated upstream version metadata. VM compatibility remains untested.')

if __name__ == '__main__':
    main()
