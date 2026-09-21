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
