import importlib.util
import pathlib
import unittest

path = pathlib.Path(__file__).resolve().parents[1]/'scripts/scan-upstream.py'
spec = importlib.util.spec_from_file_location('scan', path)
scan = importlib.util.module_from_spec(spec)
spec.loader.exec_module(scan)

class UpstreamTests(unittest.TestCase):
    firefox = '{"LATEST_FIREFOX_VERSION":"156.0.1"}'
    client = '"ubuntu12" { "version" "1234567890" "file" "ignored" }'
    launcher = ('Package: steam-launcher\nVersion: 1:1.0.0.87\nArchitecture: amd64\n'
                'Filename: pool/steam/steam-launcher_1.0.0.87_amd64.deb\nSHA256: ' + 'a'*64)

    def test_distinguishes_client_and_launcher(self):
        result = scan.parse_versions(self.firefox, self.client, self.launcher)
        self.assertEqual(result['steam_client_linux']['build'], '1234567890')
        self.assertEqual(result['steam_launcher_linux']['version'], '1:1.0.0.87')
        self.assertEqual(result['compatibility'], 'not_tested_by_this_scan')

    def test_rejects_beta_firefox(self):
        with self.assertRaises(ValueError):
            scan.parse_versions(self.firefox.replace('156.0.1', '157.0b5'), self.client, self.launcher)

    def test_rejects_missing_client_build(self):
        with self.assertRaises(ValueError):
            scan.parse_versions(self.firefox, 'error page', self.launcher)

    def test_rejects_duplicate_launcher(self):
        with self.assertRaises(ValueError):
            scan.parse_versions(self.firefox, self.client, self.launcher+'\n\n'+self.launcher)

    def test_rejects_untrusted_download_path(self):
        with self.assertRaises(ValueError):
            scan.parse_versions(self.firefox, self.client, self.launcher.replace('pool/steam/', 'pool/../'))

if __name__ == '__main__':
    unittest.main()
