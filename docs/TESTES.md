# Registro de validação — 17/10/2026

## Executado neste ambiente

Ambiente Windows, Python 3.14 e Node.js. Swift, macOS e Xcode não estão instalados. O WSL também não está instalado. Não houve teste em iPhone físico.

- `node --check web-prototype/dist/app.mjs`: sintaxe JavaScript aprovada.
- `node --test web-prototype/tests/engine.test.mjs`: **15 testes passaram**, zero falhas.
- `python scripts/validate.py`: aprovado; 121 palavras únicas e completas, leituras, JSON, assets e referências válidos. Valida estrutura e integridade, não executa Swift.
- Ícone RGB original 1024×1024 gerado sem dependências externas; vocabulário copiado para a prévia pelo script.

Os testes JS cobrem intervalos predefinidos/personalizados, fronteira exata, restauração, pausa, fim de semana, retomada, alteração de intervalo, valores inválidos, independência dos avisos, revisão, hash estável e integridade das 121 palavras. São testes da implementação web, não da compilação nativa.

## Preparado para execução em ambiente Apple

`KotobaCoreTests`: 17 casos XCTest cobrindo cronograma, dias ativos, horário de verão, notificações, capacidade, silêncio, semente, conteúdo e repetição espaçada. `KotobaTests`: 2 casos de SwiftData em memória e snapshot. Esses testes **ainda não foram executados localmente**.

A workflow `Verificar Kotoba` executa verificações portáveis, testes Swift e `xcodebuild test` em um simulador disponível no macOS. O resultado real deve ser lido em GitHub Actions no commit da entrega; a existência do YAML não significa que os jobs passaram. Logs e `Tests.xcresult` são evidência da execução quando disponíveis.

## Checklist manual necessário no iOS

1. Gerar o projeto, configurar Team/bundles/App Group e rodar iOS 17 e uma versão atual do iOS.
2. Confirmar app e extensão lendo a mesma palavra antes/depois de uma fronteira de 10 minutos, após encerrar/reabrir o app e após reiniciar o aparelho.
3. Conferir os seis formatos de widget, tema, tradução oculta, texto longo, semântica de VoiceOver e deep link para uma palavra anterior.
4. Aceitar/negar/revogar notificações; alterar intervalo independente; testar silêncio diurno e noturno e dias inativos; confirmar a fila pendente e renovação.
5. Pausar, encerrar o app, retomar e observar a preservação do restante do intervalo. Confirmar ausência de avisos durante pausa.
6. Verificar a mensagem de limite de fila, abrir após sua expiração e conferir reagendamento. Não prometer notificações sem abertura indefinidamente.
7. Testar voz japonesa baixada com modo avião, ausência da voz, fones e interrupção de áudio.
8. Favoritar, estudar, revisar, encerrar/reabrir e conferir persistência, erros de gravação e datas das revisões.
9. Validar meta, sequência, dias sem atividade, alteração de fuso e transição de horário de verão.
10. Conferir texto ampliado, contraste claro/escuro, reduzir movimento e teclados em todos os formulários.

Medição de consumo de bateria, entrega real de notificações e atraso visual de widgets exigem execução prolongada em aparelho. Compilar no simulador não prova esses comportamentos.
