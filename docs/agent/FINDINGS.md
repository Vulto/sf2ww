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
- This strengthens the crash/segfault coverage without changing game behavior.
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
