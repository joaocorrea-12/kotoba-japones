# Android — estado da implementação

Versão nativa adicionada ao repositório, com Kotlin/Jetpack Compose, SQLite, AppWidget/RemoteViews, WorkManager, AlarmManager e TextToSpeech. O projeto iOS e a prévia web continuam separados.

## Verificado localmente

- XMLs do manifesto, recursos e widget analisados sem erro de sintaxe.
- Vocabulário original validado pelo verificador portável: 121 entradas completas, IDs únicos, JSON válido.
- Wrapper obtido do repositório oficial Gradle, tag v8.13.0; JAR conferido por SHA-256.
- Java, SDK Android e emulador não estão instalados neste ambiente Windows. Não foi declarada compilação local nem execução em aparelho Android.

## Executado na CI — 18/10/2026

No commit `dfb3fce23250178a059856b56ffdbc83742421bd`, a [execução 39123472848](https://github.com/joaocorrea-12/kotoba-japones/actions/runs/39123472848) da workflow **Android — APK e testes** foi aprovada nos dois jobs.

| Verificação | Resultado observado |
| --- | --- |
| Compilação Kotlin/Compose e recursos | Aprovada |
| JUnit de domínio | 16 testes, zero falhas/erros |
| Robolectric: snapshot, SQLite e vocabulário | 5 testes, zero falhas/erros |
| Lint Android | Aprovado, sem erros bloqueantes; há avisos não bloqueantes de versões/recursos/configurações a revisar antes da publicação |
| APK debug | Gerado, baixado e validado como ZIP íntegro, com as 121 palavras incluídas |
| AAB release | Gerado e validado; sem chave de publicação configurada, permanece não assinado |
| Emulador Android API 35 / Pixel 6 | APK instalado; Activity aberta; hierarquia confirmou a tela Hoje e a palavra do momento; screenshot real salvo |

A checagem em emulador comprova instalação e abertura da tela inicial. Não exerceu todos os controles, widgets, notificações reais nem pronúncia. Esses itens continuam na validação manual abaixo. Alterações posteriores somente na documentação não mudam o código testado.

Artifacts da execução: `kotoba-android-apk`, `kotoba-android-aab-nao-assinado`, `relatorios-android` e `evidencia-emulador-android`. O APK usa chave de depuração da CI. Não é uma versão de publicação nem foi enviado à Google Play.

SHA-256 dos binários extraídos e entregues:

- APK: `6d348485e5b57e1d52bf392c569dfe5d5a39cca35b805aff114ec172f867a955`.
- AAB não assinado: `5f4503a237fc54e76556c29f7e4762c5b789d6fbb5546515563e97f7b77decca`.

O primeiro pipeline foi corrigido por um pacote SDK obsoleto na preparação do ambiente. O seguinte revelou uma leitura de `StateFlow.value` durante composição, corrigida passando o estado de pausa já observado pela tela. A execução acima valida essas correções.

## Validação manual pendente

- Instalar em Android real, conferir arranque, telas, texto ampliado e TalkBack.
- Favoritar/revisar, encerrar processo e reabrir, garantindo persistência e datas.
- Adicionar/redimensionar widget, mudar preferências e tocar em uma palavra que já mudou no app.
- Aceitar/negar/revogar notificações no Android 13+, testar canal silenciado e pausas.
- Testar Doze, economia de bateria, reinício, mudança de fuso e relógio; medir atrasos sem prometer precisão.
- Baixar voz japonesa offline e conferir fala em modo avião, ausência de voz e interrupções de áudio.
- Rever contraste claro/escuro e os formulários de intervalos personalizados.
- Fazer revisão linguística humana independente e preparar assinatura/requisitos da Google Play.

O app não está publicado na Play Store. APK de teste e AAB não assinado são entregáveis diferentes de um lançamento na loja. Veja [as instruções Android](../android/README.md).
