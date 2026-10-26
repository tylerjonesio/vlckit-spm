import io
from pathlib import Path
import stat
import tarfile
import tempfile
import unittest
import zipfile
from prepare import archive_release, digest, unpack


class PreparationTests(unittest.TestCase):
    def test_checksum_mismatch_fails_closed(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / 'source.tar.xz').write_bytes(b'tampered')
            source = {'file': 'source.tar.xz', 'sha256': '0' * 64, 'platformPackage': 'Fixture'}
            with self.assertRaisesRegex(RuntimeError, 'Checksum mismatch'):
                unpack(source, root / 'cache', root)

    def test_unsafe_archive_cannot_escape_extraction(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            archive = root / 'source.tar.xz'
            with tarfile.open(archive, 'w:xz') as contents:
                item = tarfile.TarInfo('../../escape')
                item.size = 3
                contents.addfile(item, io.BytesIO(b'bad'))
            source = {'file': archive.name, 'sha256': digest(archive), 'platformPackage': 'Fixture'}
            with self.assertRaises(tarfile.FilterError):
                unpack(source, root / 'cache', root)
            self.assertFalse((root / 'escape').exists())

    def test_release_zip_is_repeatable_and_preserves_framework_symlinks(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            framework = root / 'Fixture.xcframework'
            (framework / 'Versions/A').mkdir(parents=True)
            (framework / 'Versions/A/binary').write_bytes(b'fixture')
            (framework / 'Versions/Current').symlink_to('A')
            first, second = root / 'first.zip', root / 'second.zip'
            archive_release(framework, first)
            archive_release(framework, second)
            self.assertEqual(digest(first), digest(second))
            with zipfile.ZipFile(first) as archive:
                info = archive.getinfo('Fixture.xcframework/Versions/Current')
                self.assertTrue(stat.S_ISLNK(info.external_attr >> 16))
                self.assertEqual(archive.read(info), b'A')


if __name__ == '__main__':
    unittest.main()
