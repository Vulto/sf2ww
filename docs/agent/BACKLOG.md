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
- [ ] Diff de frames normalizados contra MAME.
- [ ] Validação de eventos de áudio por frame.
- [ ] Definir e documentar limiar de similaridade.
