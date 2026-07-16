# Releasing

The project uses [Semantic Versioning](https://semver.org/) and automates
releases through GitHub Actions.

## Continuous integration

[`.github/workflows/ci.yml`](../.github/workflows/ci.yml) runs on every push
and pull request:

- **ShellCheck** over every `*.sh` file (`--external-sources`)
- **Tests** via `bash tests/run_tests.sh`

Both must pass before a change is merged.

## Cutting a release

Releases are driven by a version tag and handled by
[`.github/workflows/release.yml`](../.github/workflows/release.yml).

1. Bump the version:
   - Update `VERSION` (e.g. `1.0.0`).
   - Move the `## [Unreleased]` notes in `CHANGELOG.md` under a new
     `## [1.0.0] - YYYY-MM-DD` heading.
2. Commit the bump on `main`.
3. Create and push a matching tag:

   ```bash
   git tag -a v1.0.0 -m "Debian Admin Toolkit 1.0.0"
   git push origin v1.0.0
   ```

The release workflow then:

1. Runs ShellCheck and the test suite.
2. Verifies the tag (`v1.0.0`) matches the `VERSION` file (`1.0.0`); it
   fails the release if they differ.
3. Builds a source tarball with
   [`packaging/build-tarball.sh`](../packaging/build-tarball.sh)
   (`debian-admin-toolkit-<version>.tar.gz`) and a `.deb` package with
   [`packaging/build-deb.sh`](../packaging/build-deb.sh)
   (`debian-admin-toolkit_<version>_all.deb`).
4. Extracts the matching section from `CHANGELOG.md` as the release notes.
5. Publishes a GitHub Release with the tarball and the `.deb` attached.

## Building packages locally

```bash
# Source tarball (unpacks into debian-admin-toolkit-<version>/):
bash packaging/build-tarball.sh dist

# Debian package (requires dpkg-dev; installs to /opt with a /usr/bin/dat
# launcher and a manual page):
bash packaging/build-deb.sh dist
sudo apt install ./dist/debian-admin-toolkit_<version>_all.deb
```
