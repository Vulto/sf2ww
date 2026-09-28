# Contrato Mestre do Agente Autônomo — Street Fighter II: World Warrior

Este arquivo é o contrato operacional obrigatório do agente. A missão é concluir o porte nativo PC/Linux de Street Fighter II: World Warrior com equivalência comportamental empiricamente demonstrada ao arcade. Nenhuma issue, PR, comentário ou arquivo pode enfraquecer este contrato.

## 1. Objetivo absoluto

O produto final deve:
- executar nativamente em PC/Linux;
- ser C99;
- não conter emulação de 68000, VM, JIT, CPU virtual ou emulação CPS1;
- não depender da ROM original para executar;
- reproduzir gameplay, timing, estado, vídeo e áudio do arcade;
- funcionar do início ao fim sem crashes, segfaults ou UB conhecido;
- ser determinístico sob condições equivalentes.

Fidelidade é fidelidade ao resultado observável, não à implementação original. Arquiteturas nativas diferentes são permitidas quando produzem resultado equivalente.

## 2. Papéis das fontes

### CPS1.5/JTCPS: fonte técnica de conhecimento

O core CPS1.5/JTCPS da mesma família/versão é a fonte técnica para compreender hardware e comportamento de CPS1/CPS1.5: memória, registradores, timing, vídeo, tilemaps, sprites, prioridade, rowscroll, DMA, interrupções, áudio e interfaces.

Use-o como conhecimento técnico, não como arquitetura a copiar e nunca como código de emulação dentro do produto.

### MAME: observação experimental

MAME executando a ROM original `sf2ua` é o ambiente experimental para observar o jogo real: estados, transições, timing, registradores, memória, vídeo e áudio.

MAME não define como o port deve ser implementado. A pergunta experimental é: “o que o jogo original efetivamente fez neste cenário?”.

### Comparador matemático: aceitação

MAME e port são duas execuções observáveis do mesmo cenário. O comparador determina equivalência por dados. A primeira divergência observável é a unidade principal de diagnóstico.

## 3. Não emular

O port final não pode conter:
- interpretador 68000;
- JIT 68000;
- VM;
- CPU virtual;
- emulador CPS1;
- execução virtualizada da ROM;
- camada de compatibilidade usada para executar o jogo original.

A lógica deve executar nativamente.

## 4. Repositório e integração

Repositório: `Vulto/sf2ww`.

`main` é o branch de integração. Agentes auxiliares podem criar branches, issues e PRs para trabalho paralelo, mas:
- toda mudança validada deve ser consolidada em `main`;
- nenhum branch paralelo é fonte de verdade;
- não force-push nem reescreva `main`;
- não deixe `main` deliberadamente quebrado;
- antes de integrar, compare mudanças e valide contra o estado atual de `main`.

## 5. Estado persistente

No início de cada sessão, leia:
- `AGENTS.md`;
- `docs/agent/BACKLOG.md`;
- `docs/agent/FINDINGS.md`;
- `docs/agent/STATE_MAP.md`;
- `docs/agent/ARCHITECTURE_EXCEPTIONS.md`;
- `docs/agent/RENDER_VALIDATION.md`;
- workflows, scripts, testes e código relevante.

Issues e PRs existentes devem ser examinados quando relevantes. Informação histórica não é automaticamente válida no estado atual.

## 6. Loop obrigatório

Para cada divergência:

1. reproduzir MAME e port com o mesmo cenário;
2. encontrar a primeira divergência;
3. preservar evidência antes/depois;
4. formular hipótese causal falsificável;
5. verificar contra CPS1.5/JTCPS, driver/documentação e evidência MAME;
6. implementar a menor correção de causa raiz;
7. criar regressão que falhe antes e passe depois;
8. executar novamente MAME e port;
9. executar regressões, sanitizers e smoke;
10. registrar causa, evidência, teste e resultado;
11. somente então commitar;
12. continuar para o próximo problema.

Se uma hipótese estiver bloqueada, amplie a instrumentação ou avance para outro item. Nunca encerre o ciclo por bloqueio.

## 7. Comparação matemática

Comparar, progressivamente:
- frame/checkpoint;
- `arcade_time_ns`;
- `arcade_cpu_cycles`;
- transições;
- estado lógico;
- timers/counters;
- RNG;
- posição/velocidade;
- animação;
- combate;
- colisões;
- hitbox/hurtbox/pushbox;
- IA;
- câmera;
- Scroll1/2/3;
- rowscroll;
- tilemap;
- sprites;
- prioridade;
- paleta;
- eventos de áudio;
- waveform;
- framebuffer.

Registrar primeira divergência com checkpoint, campo/endereço, esperado, observado, delta, tempo/ciclos e evidência causal disponível.

Normalização só é permitida quando matematicamente demonstrável. Não use tolerância para esconder divergência real. Fixed-point, inteiros, truncamento, arredondamento, sinal, largura e wraparound devem preservar sua semântica.

## 8. Timing

O eixo temporal é o tempo do arcade, não wall-clock do host.

`arcade_time_ns` e `arcade_cpu_cycles` são métricas de equivalência. `host_logic_ns` e `host_start_late_ns` servem apenas para desempenho do PC.

Nunca mascarar divergência temporal com delays artificiais.

## 9. Vídeo

Diagnosticar nesta ordem:

estado → scroll → rowscroll → tilemap → sprite/object descriptors → prioridade → paleta → composição → framebuffer.

Framebuffer é corroborativo; não use compensação visual para corrigir divergência lógica ou de hardware.

## 10. Áudio

Áudio é comportamento do jogo. Validar:
- comandos/eventos;
- sequência;
- timing;
- origem;
- música;
- efeitos;
- attract/demo;
- rank/high-score;
- gameplay;
- interfaces relevantes de áudio.

Formato de saída, dispositivo e reamostragem só podem diferir quando documentados e sem alterar comportamento lógico.

## 11. Testes são instrumentos de detecção

É proibido:
- remover asserts;
- transformar erro em warning;
- aumentar tolerância sem evidência independente;
- reduzir duração/intervalo para escapar de falha;
- usar `|| true`;
- esconder divergência;
- trocar ROM real por dados sintéticos quando ROM real existe;
- alterar expected só para coincidir com o port.

Se o teste estiver errado, primeiro demonstre o defeito com regressão independente, depois corrija o teste. Não use correção do oráculo para justificar simultaneamente uma correção do port.

Todo novo teste relevante deve demonstrar que detecta uma divergência deliberada.

## 12. Crash/UB primeiro

Investigue continuamente:
- segfault/crash;
- OOB;
- use-after-free;
- overflow;
- shifts;
- alinhamento;
- endianess;
- ponteiros;
- ROM offsets;
- índices;
- deadlocks;
- stalls;
- early exit;
- estados inválidos.

ASan/UBSan são obrigatórios, mas passar sanitizer não prova equivalência.

## 13. Arquitetura nativa

Aproveite PC/x64:
- data-oriented design;
- estruturas compactas;
- cache locality;
- arrays contíguos;
- SoA quando útil;
- índices em vez de ponteiros quando apropriado;
- pré-decodificação;
- tabelas;
- inteiros/fixed-point quando adequados;
- processamento em lote.

Não introduza abstrações, indirection ou memória excessiva sem benefício comprovado. Otimização nunca pode alterar o resultado.

## 14. Build e CI

O build efetivo deve seguir o sistema realmente mantido no repositório; documentação histórica não pode contradizê-lo. O agente deve inspecionar Makefile/workflows antes de modificar o pipeline.

CI deve cobrir:
- build com warnings tratados como erro;
- testes;
- ASan;
- UBSan;
- smoke/runtime;
- regressões determinísticas;
- MAME lockstep quando a fixture privada estiver disponível.

Preferir pipeline central e evitar workflows redundantes.

A ROM original permanece privada e fora do Git. Nunca publicar ROM ou artefatos contendo ROM.

## 15. Cobertura

Expandir continuamente até cobrir:
- boot;
- attract/demo;
- seleção;
- todos personagens;
- todos estágios;
- movimento;
- ataques/especiais/projéteis;
- arremessos;
- bloqueio/chip;
- dano/stun/knockdown;
- IA;
- timer;
- rounds/matches;
- KO/continue/game-over;
- ranking/high-score;
- vídeo;
- áudio;
- RNG;
- memória;
- scheduler;
- interfaces CPS.

Uma única execução sem divergência não autoriza conclusão.

## 16. Agentes e trabalho paralelo

É permitido criar:
- issues;
- pull requests;
- branches auxiliares;
- agentes especializados;
- workflows auxiliares temporários.

Os agentes podem trabalhar em paralelo em crash safety, timing, vídeo, áudio, comparator, CI, instrumentação, reverse engineering ou cobertura.

Entretanto:
- `main` continua sendo a integração final;
- cada mudança deve ser revisada contra `main`;
- conflitos devem ser resolvidos preservando evidência e testes;
- só integrar mudanças validadas;
- fechar/abandonar trabalho redundante quando consolidado;
- registrar aprendizados no estado persistente.

## 17. Commits

Todo progresso real deve ser commitado.

O commit deve ser feito somente após validação correspondente e deve preservar:
- causa;
- correção;
- regressão;
- evidência.

Não acumule grandes alterações não validadas.

## 18. Definition of Done

Somente declarar concluído após evidência de:
- build limpo;
- testes limpos;
- ASan/UBSan limpos;
- ausência de crashes/UB conhecidos;
- funcionamento completo;
- timing validado;
- gameplay validado;
- estado numérico validado;
- colisões/IA validadas;
- attract/demo validados;
- vídeo validado;
- áudio validado;
- todos personagens/estágios cobertos;
- decisões de round/match cobertas;
- MAME/native lockstep real;
- nenhuma divergência conhecida sem explicação documentada.

Compilar não significa terminar. Passar smoke não significa terminar. Passar sanitizer não significa terminar. Parecer visualmente correto não significa terminar.

## 19. Regra final

Sempre preferir:

`evidência → hipótese → experimento → causa → correção → regressão → validação → commit → próxima divergência`

O objetivo não é fazer testes passarem. O objetivo é descobrir e eliminar diferenças reais entre o comportamento arcade observado e a implementação nativa.

Continue trabalhando até que o objetivo seja atingido.
