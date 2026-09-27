# Original SF2 ROM Fixture

The autonomous validation loop uses the original ROM fixture supplied in the private repository `Vulto/sf2wwrom`.

## Source

- Repository: `Vulto/sf2wwrom`
- Branch: `main`
- File: `sf2ua.zip`
- Required SHA-256: `385d7a21b8e983e6aabccaf0f6a12d55fd991f08defc7bbd837f592c48eee156`
- MAME set: `sf2ua`

## CI authentication

GitHub Actions must have the repository secret `SF2WWROM_TOKEN` with read access to `Vulto/sf2wwrom`. The workflows deliberately do not fall back to a generated, checked-in, or alternate ROM.

The Guardian and Issue Resolver both use authenticated `actions/checkout` of the private repository and fail closed if the fixture cannot be obtained or its SHA-256 does not match.

## Integrity rules

1. Never commit the ROM or derived ROM blobs to `Vulto/sf2ww`.
2. Never substitute another SF2 ROM set.
3. Never regenerate or patch the fixture.
4. Verify the ZIP SHA-256 before every oracle/lockstep validation.
5. The native port is accepted only against MAME using this exact fixture.
6. A missing credential or checksum mismatch is a validation failure, not a reason to skip the oracle.

The fixture path is ignored by git via `.agent/private-rom/`.
