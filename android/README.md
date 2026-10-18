# Kotoba para Android

Implementação nativa em **Kotlin + Jetpack Compose**, no mesmo repositório do aplicativo iOS. Funciona a partir do Android 8 (API 26), com `compileSdk` e `targetSdk` 36. Não é um WebView da prévia e não exige Mac. Código em `app/src/main/java/org/kotoba/android/`.

## Recursos

- Mesmas 121 palavras originais do projeto: o Gradle inclui diretamente o JSON de `Packages/KotobaCore/Sources/KotobaCore/Resources`, sem uma segunda cópia divergente.
- Palavra vigente calculada por âncora e tempo de estudo ativo, com pausa, dias de descanso, fuso, intervalos predefinidos e personalizado de 1 minuto a 7 dias.
- Ordem progressiva/aleatória estável, escolha de nível, preferências de leitura, meta, sequência e tema.
- Favoritos, histórico de aberturas e histórico reconstruído do cronograma, com significados diferentes para a contagem de estudo.
- Revisão espaçada com Novamente/Difícil/Bom/Fácil, datas, sucessos e lapsos.
- Widget nativo redimensionável de tela inicial: pequeno/médio mostram palavra e leitura; ao aumentar a altura, mostra também o exemplo. Toque abre a palavra apresentada.
- Notificações locais com cadência independente, permissão no Android 13+, silêncio e dias ativos.
- Voz japonesa via TextToSpeech, usando uma voz offline instalada. Se não existir, o app orienta o usuário a configurá-la.
- SQLite local com estado versionado e transação atômica. Não usa conta, anúncios, assinatura ou servidor próprio; o manifesto do app não pede Internet.

Widgets da tela bloqueada não são universais no Android e dependem da versão/fabricante/launcher. Esta entrega declara um widget de **tela inicial**. Não se promete um equivalente universal aos widgets de bloqueio do iPhone.

## Compilar no Windows, Linux ou macOS

Instale Android Studio, SDK Android 36 e JDK 17. Abra a pasta `android` no Android Studio. O wrapper oficial do Gradle 8.13 está incluído e baixa a distribuição na primeira execução. O projeto fixa AGP 8.13.2, Kotlin/Compose compiler 2.1.20 e dependências explícitas; não usa versões `+`.

No terminal, dentro de `android`:

```powershell
.\gradlew.bat testDebugUnitTest lintDebug assembleDebug bundleRelease
```

No Linux/macOS:

```bash
./gradlew testDebugUnitTest lintDebug assembleDebug bundleRelease
```

Se o SDK não for encontrado, configure-o no Android Studio ou em `local.properties` (arquivo ignorado pelo Git). Em uma instalação nova, o SDK pode solicitar aceitação de licenças; o usuário deve lê-las e aceitá-las pelas ferramentas oficiais.

Saídas:

- `app/build/outputs/apk/debug/app-debug.apk`: instalável em Android, assinado com chave de depuração. Não instala em iPhone.
- `app/build/outputs/bundle/release/app-release.aab`: pacote de distribuição **não assinado**, a menos que uma assinatura tenha sido configurada. Não é instalável diretamente nem pode ser enviado assim à Play Store.
- `app/build/reports/tests/testDebugUnitTest/`: resultados dos testes JVM/Robolectric.
- `app/build/reports/lint-results-debug.html`: análise estática Android.

## Acompanhar pelo iPhone

Abra [GitHub Actions](https://github.com/joaocorrea-12/kotoba-japones/actions) no Safari e selecione **Android — APK e testes**. Uma execução aprovada fornece os artifacts `kotoba-android-apk`, `kotoba-android-aab-nao-assinado` e `relatorios-android`. Pode ser necessário entrar no GitHub para baixar os artifacts; eles têm prazo de retenção da plataforma.

O iPhone permite acompanhar código e testes e usar a prévia web. Para instalar e validar o APK, é necessário um aparelho Android ou um emulador. Chaves de depuração da CI podem mudar entre execuções, impedindo atualizar uma instalação anterior; antes de distribuir versões de teste persistentes, adote uma chave de teste estável e guarde-a com segurança. Desinstalar a versão anterior apaga seu progresso local, já que backup/sincronização não estão ativos.

## Agendamento e limites do Android

O domínio usa `java.time` com fuso persistido e dias ISO (segunda=1; domingo=7). Ao alterar fuso na abertura ou receber o broadcast de mudança de fuso, o cronograma é reancorado, preservando a palavra atual quando elegível. Ordem aleatória usa FNV-1a estável; palavras dominadas são evitadas enquanto há outras elegíveis.

O app verifica o relógio em primeiro plano. O widget lê o mesmo estado local e pede atualizações pelo WorkManager, com período mínimo de 15 minutos. **Uma troca configurada para 10 minutos não significa que o widget atualizará a cada 10 minutos.** Doze/bateria, restrições do fabricante e disponibilidade do launcher podem atrasar atualizações.

Notificações usam **um alarme inexato** por vez com `setAndAllowWhileIdle`, sem solicitar `SCHEDULE_EXACT_ALARM` ou `USE_EXACT_ALARM`. Quando o alarme é entregue, o receptor verifica as preferências atuais, os dias e o silêncio, escolhe a palavra vigente naquele instante e renova o próximo aviso. Avisos perdidos não são enviados em lote. Depois de reiniciar/atualizar o app ou ajustar o relógio, o receptor refaz o agendamento. Não usa serviço contínuo em primeiro plano.

Se o usuário forçar a parada do app, revogar notificações ou o fabricante bloquear atividades em segundo plano, o sistema pode impedir avisos até uma nova abertura. Não há garantia de precisão ao minuto. O conteúdo Android pode diferir de uma notificação iOS atrasada: Android seleciona a palavra na entrega; iOS usa conteúdo previamente agendado.

## Testes e publicação

A workflow compila APK debug e AAB release, executa testes de domínio/SQLite e lint. Build aprovada não comprova entregas reais, comportamento em Doze, voz, interface ou launcher. Confira [o registro Android](../docs/ANDROID.md) para o resultado observado e as pendências.

Para publicar, veja o roteiro abaixo. Nenhuma conta, pagamento, aceitação de contrato ou envio à loja é feito automaticamente.

1. Escolher um `applicationId` definitivo e exclusivo, antes da primeira publicação.
2. Criar/verificar a conta Google Play Console. A taxa atual é **única, US$ 25**, cobrada pelo Google do desenvolvedor; o Kotoba pode continuar gratuito. [Fonte oficial](https://support.google.com/googleplay/android-developer/answer/6112435?hl=pt-BR).
3. Para novas contas pessoais abrangidas pela regra, realizar teste fechado com **pelo menos 12 testadores inscritos por 14 dias consecutivos** e solicitar acesso à produção. Também há verificação de dispositivo para novas contas pessoais. [Teste fechado](https://support.google.com/googleplay/android-developer/answer/14151465?hl=pt-BR).
4. Configurar uma chave de upload, guardar cópia de recuperação fora do repositório e gerar **AAB assinado** pelo Android Studio (Build → Generate Signed App Bundle) ou por uma CI com secrets próprios. Não publicar APK debug nem colocar senhas, `.jks` ou chaves no GitHub.
5. Preencher página da loja, classificação, público-alvo, segurança de dados, política de privacidade pública e contatos do responsável. O texto de privacidade do repositório é um rascunho técnico e precisa identificar o responsável real.
6. Conferir o nível alvo exigido na data de submissão. Nesta entrega usamos API 36, conforme a exigência publicada para novos apps em 2026. [Política oficial](https://support.google.com/googleplay/android-developer/answer/11926878?hl=pt-BR).
7. Testar em aparelhos reais, revisar conteúdo com professor de japonês e enviar à análise da Google Play. Compilar não equivale a aprovação da loja.

A build release aceita assinatura opcional pelas variáveis `KOTOBA_KEYSTORE_PATH`, `KOTOBA_STORE_PASSWORD`, `KOTOBA_KEY_ALIAS` e `KOTOBA_KEY_PASSWORD`. Configure-as somente no ambiente seguro de compilação/secrets da CI. Sem essas variáveis, o AAB continua não assinado. Nunca escreva os valores no README, em comandos compartilhados ou no código-fonte.

As condições de publicação são da plataforma e podem mudar. Não é necessário tornar o aplicativo pago para cobrir a taxa de cadastro.

## Licenças

Código Kotoba e símbolo original: MIT, na raiz do repositório. Vocabulário: CC0, conforme `docs/CONTEUDO.md`. Gradle wrapper: arquivos oficiais do tag `gradle/gradle v8.13.0`, sob Apache 2.0, com licença em `gradle/LICENSE`. SHA-256 do JAR incluído: `81a82aaea5abcc8ff68b3dfcb58b3c3c429378efd98e7433460610fecd7ae45f`.

Referências: [atualizações de widgets](https://developer.android.com/develop/ui/compose/glance/glance-app-widget), [alarmes inexatos](https://developer.android.com/develop/background-work/services/alarms), [compatibilidade AGP 8.13](https://developer.android.com/build/releases/agp-8-13-0-release-notes).
