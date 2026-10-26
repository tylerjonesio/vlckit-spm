#!/usr/bin/env python3
"""Repackage pinned VideoLAN binaries; never rebuild or modify playback code."""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import tarfile
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def digest(path: Path) -> str:
    value = hashlib.sha256()
    with path.open('rb') as stream:
        while data := stream.read(1024 * 1024):
            value.update(data)
    return value.hexdigest()


def unpack(source: dict, cache: Path, downloads: Path) -> Path:
    archive = downloads / source['file']
    downloads.mkdir(parents=True, exist_ok=True)
    if not archive.exists():
        partial = archive.with_suffix('.partial')
        print(f"Downloading {source['platformPackage']} {source['bytes']} bytes", flush=True)
        with urllib.request.urlopen(source['sourceURL'], timeout=120) as response, partial.open('wb') as output:
            shutil.copyfileobj(response, output)
        if digest(partial) != source['sha256']:
            raise RuntimeError(f"Checksum mismatch for {source['file']}; refusing extraction")
        partial.replace(archive)
    if digest(archive) != source['sha256']:
        raise RuntimeError(f"Checksum mismatch for {archive}; refusing extraction")
    extracted = cache / source['platformPackage']
    marker = extracted / '.source-sha256'
    if not marker.exists() or marker.read_text().strip() != source['sha256']:
        shutil.rmtree(extracted, ignore_errors=True)
        extracted.mkdir(parents=True)
        print(f"Extracting {archive.name}", flush=True)
        # The data filter rejects traversal and symlinks escaping the destination.
        with tarfile.open(archive) as contents:
            contents.extractall(extracted, filter='data')
        marker.write_text(source['sha256'] + '\n')
    matches = [p.parent for p in extracted.rglob('Info.plist') if p.parent.suffix == '.xcframework']
    if len(matches) != 1:
        raise RuntimeError(f"Expected one XCFramework for {source['platformPackage']}, found {matches}")
    return matches[0]


def archive_release(framework: Path, target: Path) -> None:
    # Fixed timestamps/order and Unix symlink modes give repeatable checksums.
    with zipfile.ZipFile(target, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for path in sorted(framework.rglob('*')):
            if path.is_dir() and not path.is_symlink():
                continue
            info = zipfile.ZipInfo(path.relative_to(framework.parent).as_posix(), date_time=(1980, 1, 1, 0, 0, 0))
            info.create_system = 3
            info.external_attr = path.lstat().st_mode << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            archive.writestr(info, os.readlink(path).encode() if path.is_symlink() else path.read_bytes())


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--cache-dir', type=Path, default=ROOT / '.cache')
    parser.add_argument('--archive-dir', type=Path, help='Reuse already downloaded official archives')
    parser.add_argument('--zip', action='store_true', help='Also create a deterministic upstream release ZIP and checksum')
    parser.add_argument('--release-url', help='Write a remote binary declaration for a subsequently published ZIP; does not upload')
    args = parser.parse_args()
    manifest = json.loads((ROOT / 'sources.json').read_text())
    cache = args.cache_dir.resolve()
    output = ROOT / 'Artifacts'
    framework = output / 'VLCKit-all.xcframework'
    build_info = output / 'build-info.json'
    manifest_hash = digest(ROOT / 'sources.json')
    if not (framework / 'Info.plist').exists() or not build_info.exists() or json.loads(build_info.read_text()).get('manifestSHA256') != manifest_hash:
        command = ['xcodebuild', '-create-xcframework']
        inputs = []
        for source in manifest['artifacts']:
            xcframework = unpack(source, cache, (args.archive_dir or cache / 'downloads').resolve())
            info = plistlib.loads((xcframework / 'Info.plist').read_bytes())
            for library in info['AvailableLibraries']:
                base = xcframework / library['LibraryIdentifier']
                library_path = base / library['LibraryPath']
                if library_path.suffix != '.framework':
                    raise RuntimeError(f'Unexpected library {library_path}')
                command += ['-framework', str(library_path)]
                symbols = base / library.get('DebugSymbolsPath', 'dSYMs')
                if symbols.is_dir():
                    for dsym in sorted(symbols.glob('*.dSYM')):
                        command += ['-debug-symbols', str(dsym.resolve())]
                inputs.append(library['LibraryIdentifier'])
        staging = cache / 'combined' / 'VLCKit-all.xcframework'
        shutil.rmtree(staging, ignore_errors=True)
        staging.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(command + ['-output', str(staging)], check=True)
        info = plistlib.loads((staging / 'Info.plist').read_bytes())
        libraries = info['AvailableLibraries']
        supported = {(entry['SupportedPlatform'], entry.get('SupportedPlatformVariant', 'device')) for entry in libraries}
        required = {('ios', 'device'), ('ios', 'simulator'), ('tvos', 'device'), ('tvos', 'simulator'), ('macos', 'device')}
        if supported != required:
            raise RuntimeError(f'Unexpected combined platform coverage: {supported}')
        output.mkdir(exist_ok=True)
        shutil.rmtree(framework, ignore_errors=True)
        shutil.move(str(staging), framework)
        build_info.write_text(json.dumps({'version': manifest['version'], 'manifestSHA256': manifest_hash,
                                         'libraries': libraries, 'inputs': inputs}, indent=2) + '\n')
    print(f"Prepared VLCKit {manifest['version']}: {framework}", flush=True)
    if args.zip or args.release_url:
        target = output / 'VLCKit-all.xcframework.zip'
        archive_release(framework, target)
        checksum = digest(target)
        (output / 'VLCKit-all.xcframework.zip.sha256').write_text(checksum + '\n')
        print(f'Release ZIP SHA256: {checksum}', flush=True)
        if args.release_url:
            declaration = f'let vlcBinary = Target.binaryTarget(name: "VLCKit-all", url: {json.dumps(args.release_url)}, checksum: "{checksum}")\n'
            (output / 'remote-binary-declaration.swift').write_text(declaration)


if __name__ == '__main__':
    main()
