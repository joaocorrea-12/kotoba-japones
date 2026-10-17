# Registro de validação — 17/10/2026

## Executado neste ambiente

Ambiente local Windows, Python 3.14 e Node.js. Swift, macOS e Xcode não estão instalados localmente. O WSL também não está instalado. **A CI remota em macOS executou a compilação e os testes Swift abaixo.** Não houve teste em iPhone físico.

- `node --check web-prototype/dist/app.mjs`: sintaxe JavaScript aprovada.
- `node --test web-prototype/tests/engine.test.mjs`: **15 testes passaram**, zero falhas.
- `python scripts/validate.py`: aprovado; 121 palavras únicas e completas, leituras, JSON, assets e referências válidos. Valida estrutura e integridade, não executa Swift.
- Ícone RGB original 1024×1024 gerado sem dependências externas; vocabulário copiado para a prévia pelo script.
- Navegador local: favorito, avanço de palavra e widget simulado, intervalo de 10 minutos persistido após recarregar, revelação e registro de revisão, layout desktop e viewport 390×844 conferidos.
- Prévia pública por GitHack: HTML, CSS, módulos e as 121 palavras carregaram; a tela Hoje foi conferida. O CDN pode apresentar uma tela de procedência antes de abrir a página.

Os testes JS cobrem intervalos predefinidos/personalizados, fronteira exata, restauração, pausa, fim de semana, retomada, alteração de intervalo, valores inválidos, independência dos avisos, revisão, hash estável e integridade das 121 palavras. São testes da implementação web, não da compilação nativa.

## Executado remotamente em ambiente Apple

No commit `30e7a9429c7c636d27adb96544dd280048b17934`, a [execução 39072041301](https://github.com/joaocorrea-12/kotoba-japones/actions/runs/39072041301) terminou com os três jobs aprovados:

| Job | Resultado verificado |
| --- | --- |
| portable | Validador e 15 testes JS aprovados |
| swift-core | 17 casos XCTest, zero falhas, executados em macOS |
| ios | XcodeGen gerou o projeto; app e extensão compilaram; 2 testes XCTest no simulador passaram; `TEST SUCCEEDED` |

`KotobaCoreTests` cobre cronograma, dias ativos, horário de verão, notificações, capacidade, silêncio, semente, conteúdo e repetição espaçada. `KotobaTests` cobre SwiftData em memória e snapshot. O artifact `testes-ios` contém o resultado XCTest. As alterações posteriores de documentação e entrada de hospedagem não mudam o Swift testado.

A workflow `Verificar Kotoba` executa verificações portáveis, testes Swift e `xcodebuild test` em um simulador disponível no macOS. Os logs incluem diagnósticos de extração App Intents/voz do simulador, apesar da conclusão bem-sucedida; a compilação não comprova que a galeria/configuração de widgets ou a voz funcionem em aparelho. Os testes de integração não exercitam a interface SwiftUI completa nem a entrega real de notificações.

## Limite da publicação Sites

O Site privado foi registrado, mas o envio ao helper interativo foi recusado pela política de aprovação do ambiente (`sandbox_approval` desabilitado). A alternativa sem terminal interativo não conseguiu conexão de saída com o Git do Site. Nenhuma publicação Sites foi concluída e o endereço reservado não deve ser usado como URL da prévia. O código continua disponível no GitHub e no ZIP; a prévia navegável verificada usa o CDN do repositório público.

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
