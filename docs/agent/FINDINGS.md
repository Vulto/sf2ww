# Findings

## 2026-09-21 — Baseline runtime safety

- O CI atual possui build, testes e sanitizer ASan/UBSan.
- O smoke headless atual usa arquivos sintéticos zero-filled; isso é útil para detectar falhas nativas no caminho acessível, mas não substitui a ROM original.
- A última validação conhecida passou sem erros de ASan/UBSan e sem falha do smoke.
- Foram corrigidos anteriormente problemas reais de alinhamento em UserData de ações, aritmética de ponteiro em teste, shifts assinados, ponteiro de texto não inicializado, diagnósticos de ponteiro em x64 e inicialização de ponteiros em actions.
- Bloqueio atual: não há ROM válida nem harness MAME/port disponível no repositório. Não tratar esse bloqueio como sucesso; o backlog deve permanecer aberto.

## 2026-09-21 — CPS1 frame cadence

- O driver/MAME descreve o World Warrior/CPS1 com pixel clock de 8 MHz, 512 clocks horizontais, 262 scanlines e refresh de aproximadamente 59.6374 Hz.
- O frontend anterior executava `task_timer()` a cada 12 ms após um primeiro disparo de 40 ms, portanto não estava seguindo a cadência de um frame CPS1.
- A nova agenda usa um deadline monotônico de aproximadamente 16.768 ms por frame e evita acumular atraso quando uma chamada ultrapassa o deadline.
- Isso corrige a cadência do relógio do frontend sem alterar a semântica da lógica por tick. A equivalência funcional ainda depende do harness MAME.

## 2026-09-21 — Lockstep probe foundation

- A API Lua atual do MAME fornece `emu.register_frame_done` e acesso ao espaço de programa do `:maincpu`, permitindo coletar campos selecionados por frame sem armazenar dumps completos de RAM.
- Foi criado `scripts/mame_state_dump.lua` para registrar um vetor pequeno de estado por frame.
- Foi criado `scripts/run_mame_state.sh` para executar o MAME contra um diretório de ROM externo/privado.
- O port emite o mesmo formato de CSV quando `SF2_STATE_LOG` está definido.
- Os offsets lógicos de jogador ainda são candidatos baseados no layout documentado no repositório. Eles só podem virar mapa autoritativo após uma execução real contra a ROM e comparação frame a frame.

## 2026-09-21 — Remaining ROM alignment audit

- The initial alignment cleanup still left RH3DShort and RH2DShort using typed u16 dereferences into the byte-oriented ROM blob.
- These were replaced with memcpy-based word reads while preserving the original byte offsets and endian conversion.
- CI for the correction passed build, tests, smoke-compare, and ASan/UBSan; the full-MAME job remains conditional on the private ROM fixture.
- A secondary audit found draw_scroll2_planes could form a negative SCR2 tilemap index from its display-loop coordinates; the mapping now masks tx/ty to the CPS1 6-bit tilemap domain before indexing.

## 2026-09-21 — MAME probe headless execution

- The scheduled full-MAME job installed Xvfb but launched the MAME state probe directly with OpenGL.
- On a GitHub-hosted Linux runner there is no guaranteed graphical display, so the probe could fail before producing the state CSV even when the private ROM fixture is present.
- The regression step now runs the existing MAME probe through `xvfb-run -a`, keeping the ROM fixture external while making the comparison harness deterministic in headless CI.
- Acceptance: the full-MAME job must reach the state-dump step without requiring a physical display; actual state equivalence remains blocked until the private ROM fixture is mounted.

## 2026-09-21 — Smoke must detect premature exit

- The native smoke previously accepted both a 15/30-second timeout and a clean exit status of 0.
- A crash is normally non-zero, but an early clean exit could therefore be misclassified as a passing runtime test.
- The smoke gates now require the expected timeout status (124), proving the executable remained alive for the observation window. Any clean early exit or crash fails CI.
- This strengthens the crash/UB coverage without changing game behavior.

## 2026-09-21 — Smoke verifies forward frame progress

- A live process alone is insufficient crash/runtime coverage: a deadlocked or stalled frontend can remain alive until the timeout.
- The native smoke now enables `SF2_STATE_LOG` and requires at least 300 emitted state frames during the 15-second observation window.
- Acceptance: the process must stay alive for the full window and advance the game timer callback enough to produce the minimum frame count; premature exit, crash, or scheduler stall fails CI.

## 2026-09-21 — Preserve decoded jumper state

- `decode_params()` used compound `&=` assignments when decoding `JP_FREEPLAY` and `JP_ALLOWCONT`.
- Those assignments mutated `g.JPParam`, so the subsequent live-jumper decode no longer saw the original jumper bits. Depending on the configured jumper combination, `DemoSound`, `FreezeMachine`, `FlipDisplay`, and `Debug2` could be silently cleared.
- The decoder now uses non-mutating bit tests and preserves `g.JPParam` as the source-of-truth value read from the ROM/jumper input.
- Acceptance: decoding Free Play/Continue must not alter `g.JPParam`; subsequent live-jumper fields must reflect the original parameter word.

## 2026-09-21 — Guard task table indices

- `task_kill()` indexed `Exec.Tasks[id]` without validating the caller-provided task id, and `create_task()` accepted a signed task id without bounds checking.
- A corrupted or invalid task id could therefore turn a runtime scheduling error into an out-of-bounds write/read against the task table and potentially crash the native process.
- Both entry points now reject ids outside `0..MAX_TASKS-1` before touching the task table.
- Acceptance: invalid task ids must not access `Exec.Tasks` or invoke the pthread backend; valid task ids retain the existing behavior.

## 2026-09-26 — Reusable MAME lockstep action

- The central workflow already had the required build, smoke, and conditional full-MAME jobs, but the MAME probe, native port probe, and first-divergence comparison were duplicated as workflow steps.
- The contract requires a reusable composite action for the common MAME + port + diff logic.
- Added `.github/actions/mame-lockstep/action.yml`, which validates the private fixture, runs the MAME state probe headlessly, runs the native port probe with the same fixture, and invokes the existing first-divergence comparator.
- The scheduled/merge full-MAME job now delegates that sequence to the composite action.
- Acceptance: the single central workflow remains the only workflow, while the full-MAME job uses the reusable action and preserves the external/private ROM boundary.

## 2026-09-26 — sf2ua fixture layout validation

- The supplied `sf2ua` archive contains the canonical program filenames `sf2u_30a.11e`, `sf2u_37a.11f`, `sf2u_31a.12e`, `sf2u_38a.12f`, `sf2u_28a.9e`, `sf2u_35a.9f`, `sf2_29b.10e`, and `sf2_36b.10f`, plus the expected 12 graphics ROMs.
- The existing merge layout is correct for this fixture: byte-interleaving the four program pairs and 2-byte-interleaving the three graphics groups reproduces the documented SHA-1 values exactly: `allroms.bin=4256ec60bf9eec21f4d6bb34c38990a9401af82e` and `sf2gfx.bin=db52a6314b4c0cd4c48eb324720c83dd142c3bff`.
- `bin/mt2-merge.sh` now accepts both the historical names and the canonical MAME-set names without changing the generated layout.
- The original ROM data remains external to the repository, as required by `AGENTS.md`.
- Acceptance for this step: merge reproducibility and SHA-1 validation pass. Real MAME/native lockstep remains pending because the current execution environment does not provide the MAME executable.


## 2026-09-26 — Crash-fix branch reconciliation and GitHub MAME validation

- Existing branches were compared against `main`; branches that were only behind or whose changes were already represented in `main` were not replayed wholesale.
- The historical `ci/_crashfix-001` branch contained still-relevant x64 safety work that was not fully represented in `main`: packed CPS user-data overlays, checked ROM pointer/offset accessors, safe ROM action metadata reads, safe sprite ROM range validation, fixed-point wraparound preservation, AI ROM lookup validation, palette bounds validation, and signed-shift cleanup.
- Those root-cause fixes were integrated directly into `main` without creating a new working branch.
- GitHub Actions now installs MAME on the hosted Ubuntu runner and validates the installed MAME driver for `sf2ua`. The current CI run passed build, unit tests, ASan/UBSan, native smoke, MAME installation/driver validation, and the conditional full-MAME job.
- The real MAME/native lockstep remains blocked only by the absence of the private ROM fixture on the GitHub runner; the CI no longer treats MAME installation itself as a blocker.
- Acceptance: the integrated crash-fix changes must keep all existing CI jobs green; current validation passes.

## 2026-09-26 — Correct fighter state vector

- Cross-check against the documented WW fighter layout confirms P1 `$FF83C6` and P2 `$FF86C6`; X/Y are 32-bit fields at struct offsets `$06/$08`, while `$28` is the native action-script type and `$2A` is energy.
- The MAME probe now reads `$06/$08`, preserving the existing mode/animation/energy/move fields.
- The CSV comparator now treats the 900-frame MAME capture as the required prefix and permits the native probe to run longer under its timeout. A short native capture remains a hard failure.

## 2026-09-26 — Push-box target index correction

- `CDPushOverlap()` selected the target object's push-box using the attacker's `HB_Push` index (`a2->ActionScript->HB_Push`) instead of the target object's own `HB_Push` field.
- This can select the wrong target box and can read outside the intended target hitbox table when the two action scripts use different indices.
- Corrected the access to `a6->ActionScript->HB_Push`, preserving the original table and overlap algorithm.
- Acceptance: build, unit tests, ASan/UBSan and native smoke must remain green; real MAME lockstep is still required to confirm behavioral equivalence during push-box interactions.

## 2026-09-26 — Throw damage energy source correction

- `_EnergyDamageAdjust()` was indexing the damage-diminishing table with the attacker's energy even though the adjustment is applied to the victim's throw damage.
- Using attacker energy could select the wrong damage factor and could index the 31-entry table with an invalid value when attacker state is outside the expected range.
- Corrected the index to `ply->Opponent->Energy`, matching the victim-based adjustment used by the regular collision damage path.
- Acceptance: build, unit tests, ASan/UBSan and native smoke must remain green; real MAME lockstep must validate throw damage and KO behavior.

## 2026-09-26 — Throw damage table branch correction

- `LBGetDamage()` had the normal/special damage-table condition reversed. Normal throw indices (for example 12–15) entered the special-table branch and subtracted `0x20`, producing negative table indices; the `0x20` special damage index entered the normal table.
- Corrected the branch to match the table layout and the regular collision damage path: indices below `0x20` use `data_99324/data_99544`, while `0x20+` uses `data_99566/data_995a6` after subtracting `0x20`.
- This removes a deterministic out-of-bounds read from ordinary throw processing and restores the intended high-damage throw path.
- Acceptance: build, unit tests, ASan/UBSan and native smoke must remain green; real MAME lockstep must validate throw damage values.
