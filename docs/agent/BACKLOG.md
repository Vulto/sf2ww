# Backlog

Prioridade 0 — segurança/runtime
- [ ] Substituir o smoke com ROMs zeradas por execução com ROM válida externa ao repositório.
- [ ] Construir harness MAME/port em lockstep e registrar o primeiro frame divergente.
- [ ] Mapear o vetor de estado lógico no MAME e no port.
- [ ] Cobrir crashes/segfaults e UB em todos os caminhos de jogo acessíveis.
- [ ] Auditar índices de tilemap e acesso a ROM em todos os caminhos gráficos, incluindo rotinas atualmente desativadas.

Prioridade 1 — cobertura funcional
- [ ] Attract/demo determinístico.
- [ ] Todos os personagens e estágios.
- [ ] Movimento, golpes, especiais, projéteis, arremessos, bloqueio/chip, dano, stun/knockdown.
- [ ] IA da CPU, timer, round/match decisions e câmera.

Prioridade 2 — validação audiovisual
- [ ] Captura de frame do port e do MAME em resolução interna comum.
- [ ] Diff de frames normalizados contra MAME.
- [ ] Validação de eventos de áudio por frame.
- [ ] Definir e documentar limiar de similaridade.

## Progress since initialization

- [x] Confirmed CPS1 timing from MAME and changed the native frontend scheduler to approximately 59.6374 Hz.
- [x] Added a per-frame port state CSV probe.
- [x] Added a current-MAME Lua frame probe for the original machine state.
- [x] Added a launcher that keeps MAME ROMs outside the repository.
- [x] Encapsulated the MAME + native port + first-divergence comparison in a reusable composite action.
- [ ] Connect the probes with the external/private ROM fixture and produce the first real lockstep report.
- [ ] Mount the private ROM fixture on a trusted runner and turn the scheduled full-MAME job from blocked to active.
- [ ] Resolve the first real state divergence reported by the comparator.

### Harness acceptance notes

- [x] Full-MAME CI invokes the existing MAME state probe through Xvfb so the scheduled regression does not depend on a physical display.
- [x] The full-MAME job delegates MAME/port/diff execution to `.github/actions/mame-lockstep`.
- [ ] Mount the private/original ROM fixture on a trusted runner and execute the first real MAME/port lockstep comparison.
- [x] Smoke gates reject premature clean exits and crashes by requiring the expected timeout status.
- [x] Smoke verifies forward frame progress in addition to process liveness.


### CI MAME runtime

- [x] GitHub Actions installs MAME from the Ubuntu runner package.
- [x] CI validates the installed MAME version and the `sf2ua` driver.
- [ ] Mount the private `sf2ua` ROM fixture on a trusted runner and execute the real MAME/native lockstep.

## 2026-09-26 — Lockstep vector correction

- Corrected the MAME fighter position probe to read the documented fighter struct X/Y fields at offsets `$06/$08` from P1 `$FF83C6` and P2 `$FF86C6`. The previous probe incorrectly sampled `$28/$2C`, which are action-script/energy fields in the native struct model.
- Updated the comparator to compare the complete fixed MAME prefix while allowing the native process to emit additional frames before timeout; fewer native frames still fail.

- [ ] Validate player/object push-box interactions against MAME after the real ROM fixture is mounted.
