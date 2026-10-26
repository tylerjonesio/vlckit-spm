# VLCKit SPM — 3.7.4 packaging

This is a small local continuation of
[tylerjonesio/vlckit-spm](https://github.com/tylerjonesio/vlckit-spm) at
`e932bbd488872fdb74f6654d28c2f291eae03daf`. The `VLCKitSPM` product, re-export
source, platform declarations and linker settings are preserved. Playback code
is not forked. The manifest downloads a combined XCFramework from this fork’s 3.7.4 release.

## Use with Swift Package Manager

Add `https://github.com/pulimento/vlckit-spm.git` and select the `3.7.4` tag
when available, or the `update-vlckit-3.7.4` branch. Choose the `VLCKitSPM` product.
Normal package consumers do not need Python or a local bootstrap.

## Rebuild the release artifact

Requires macOS, Xcode command-line tools and Python 3.11.8 or newer.

```sh
./generate.sh --zip
```

The script downloads official VideoLAN **3.7.4** iOS, tvOS and macOS archives,
checks their pinned SHA256 values in `sources.json`, safely extracts them and
uses `xcodebuild -create-xcframework` to preserve device/simulator slices and debug
symbols. Downloads and extraction are cached. There is no fallback to 3.6.0.
Existing official downloads can be reused with `--archive-dir /path/to/archives`.
If Xcode reports stale MobileVLCKit precompiled modules when moving from 3.6.0,
use a fresh DerivedData directory or Clean Build Folder once.

`Artifacts/`, `.cache/`, `.build/` and `.swiftpm/` are generated and ignored by Git.
Keep the manifest, sources, preparation script, provenance and LICENSE in Git.
For offline/local development, run preparation, then change the binary target
to `path: "Artifacts/VLCKit-all.xcframework"`. SwiftPM cannot run this bootstrap
automatically during package resolution.

## Prepare the upstream PR / release

```sh
./generate.sh --zip
```

This also emits a deterministic `Artifacts/VLCKit-all.xcframework.zip` and its
SHA256. When publishing a rebuilt ZIP, update the remote binary declaration to match
the actual release URL and generated checksum. For an upstream PR, the
maintainer can publish the same ZIP under the original repository. To prepare the exact
one-line declaration without uploading anything:

```sh
./generate.sh --release-url https://example.org/releases/3.7.4/VLCKit-all.xcframework.zip
```

Replace the example URL with the actual published asset URL. The result is saved
as `Artifacts/remote-binary-declaration.swift`; generation never edits the local
manifest or publishes a release. `Sources/VLCKitSPM/VLCKit.swift` is unchanged.

The official archive names identify refs `54bba6d9` and `6de05adc`. The validated
iOS runtime reports libVLC `3.0.24 Vetinari`, changeset
`3.0.24-42-g9e7d3f5fde`; archive labels are not runtime-version assertions.
Local repackaging hashes are reproducibility pins computed from the fetched
archives, not an independent upstream signature. Preserve the upstream LGPL
license and the embedded framework license material.

Run preparation checks with `python3 -B scripts/test_prepare.py`.

## Release automation

The release workflow on `update-vlckit-3.7.4` tests packaging and rebuilds from
SHA256-pinned official archives. It records the generated ZIP checksum in
`Package.swift`, commits that manifest, then creates the `3.7.4` tag and release.
A checksum identifies the exact published ZIP; compression and Xcode metadata
can vary between build environments even with identical official inputs.
An existing release tag must never be overwritten. For a subsequent release,
update the pinned inputs, release version, manifest URL and workflow trigger.
When sending this change upstream, update the manifest release URL first.
