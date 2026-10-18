# Android — estado da implementação

Versão nativa adicionada ao repositório, com Kotlin/Jetpack Compose, SQLite, AppWidget/RemoteViews, WorkManager, AlarmManager e TextToSpeech. O projeto iOS e a prévia web continuam separados.

## Verificado localmente

- XMLs do manifesto, recursos e widget analisados sem erro de sintaxe.
- Vocabulário original validado pelo verificador portável: 121 entradas completas, IDs únicos, JSON válido.
- Wrapper obtido do repositório oficial Gradle, tag v8.13.0; JAR conferido por SHA-256.
- Java, SDK Android e emulador não estão instalados neste ambiente Windows. Não foi declarada compilação local nem execução em aparelho Android.

## Preparado para CI

Workflow **Android — APK e testes**: testes JUnit de calendário, intervalos, pausa, dias ativos, notificações, revisão e hash; testes Robolectric de codificação, SQLite e vocabulário; lint; geração de APK debug e AAB release sem assinatura.

O resultado observado da CI será registrado após sua execução. A existência dos arquivos de configuração não prova que o app compilou.

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
