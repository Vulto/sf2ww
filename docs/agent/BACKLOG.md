# Backlog

Prioridade 0 — segurança/runtime
- [ ] Substituir o smoke com ROMs zeradas por execução com ROM válida externa ao repositório.
- [ ] Construir harness MAME/port em lockstep e registrar o primeiro frame divergente.
- [ ] Mapear o vetor de estado lógico no MAME e no port.
- [ ] Cobrir crashes/segfaults e UB em todos os caminhos de jogo acessíveis.

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
- [ ] Connect the probes with the external/private ROM fixture and produce the first real lockstep report.
