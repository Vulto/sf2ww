# Findings

## 2026-09-21 — Baseline runtime safety

- O CI atual possui build, testes e sanitizer ASan/UBSan.
- O smoke headless atual usa arquivos sintéticos zero-filled; isso é útil para detectar falhas nativas no caminho acessível, mas não substitui a ROM original.
- A última validação conhecida passou sem erros de ASan/UBSan e sem falha do smoke.
- Foram corrigidos anteriormente problemas reais de alinhamento em UserData de ações, aritmética de ponteiro em teste, shifts assinados, ponteiro de texto não inicializado, diagnósticos de ponteiro em x64 e inicialização de ponteiros em actions.
- Bloqueio atual: não há ROM válida nem harness MAME/port disponível no repositório. Não tratar esse bloqueio como sucesso; o backlog deve permanecer aberto.
