# Original SF2 ROM Fixture

The autonomous validation loop uses the original ROM fixture supplied in the private repository `Vulto/sf2wwrom`.

## Source

- Repository: `Vulto/sf2wwrom`
- Branch: `main`
- File: `sf2ua.zip`
- Required SHA-256: `385d7a21b8e983e6aabccaf0f6a12d55fd991f08defc7bbd837f592c48eee156`
- MAME set: `sf2ua`

## CI authentication

The repository history already established the working mechanism: GitHub Actions checks out `Vulto/sf2wwrom` with the workflow's existing `github.token` authorization. The autonomous loop must reuse that mechanism; it must not introduce a new ROM credential or secret name.

The Guardian, Issue Resolver, and legacy validation workflow fail closed if the fixture cannot be obtained or its SHA-256 does not match.

## Integrity rules

1. Never commit the ROM or derived ROM blobs to `Vulto/sf2ww`.
2. Never substitute another SF2 ROM set.
3. Never regenerate or patch the fixture.
4. Verify the ZIP SHA-256 before oracle/lockstep validation.
5. The native port is accepted only against MAME using this exact fixture.
6. A missing fixture or checksum mismatch is a validation failure, not a reason to skip the oracle.

The historical CI implementation that established the private checkout is commit `7dc01741230695dd6c9de3c18d5b9fb1fcd0ced4`, which uses `actions/checkout@v4` with `token: ${{ github.token }}`.
