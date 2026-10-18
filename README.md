# Kotoba — Japonês todos os dias

Aplicativos **nativos para iPhone (iOS 17+, SwiftUI) e Android (8+, Kotlin/Jetpack Compose)**, gratuitos e sem assinaturas. Identidade, código, exemplos e traduções originais. A referência conceitual é microaprendizagem; nenhum código, tela, imagem ou logotipo de Hourly Kana foi utilizado.

**Versão Android:** disponível em [`android/`](android/README.md), com palavras, intervalos, widget, notificações, voz e revisão. [CI aprovada](https://github.com/joaocorrea-12/kotoba-japones/actions/runs/39123472848): APK/AAB gerados, lint e 21 testes aprovados, instalação e abertura confirmadas em emulador. Pode ser compilada no Windows/Linux/macOS. Ainda requer testes em aparelho real, assinatura e etapas do Google Play Console para publicar. Consulte [o registro Android](docs/ANDROID.md).

**Estado desta entrega:** implementação inicial da Fase 1 em código-fonte. O desenvolvimento local ocorreu em Windows; a [CI em macOS](https://github.com/joaocorrea-12/kotoba-japones/actions/runs/39072041301) compilou o app e a extensão, aprovou 17 testes Swift e 2 testes de persistência/snapshot no simulador. Os 15 testes JS e a validação dos dados também passaram. Esta entrega não é um IPA, não foi instalada em iPhone físico e ainda não está pronta para a App Store. Consulte [o registro de validação](docs/TESTES.md).

- [Repositório no GitHub](https://github.com/joaocorrea-12/kotoba-japones)
- [Prévia web interativa](https://raw.githack.com/joaocorrea-12/kotoba-japones/30e7a9429c7c636d27adb96544dd280048b17934/web-prototype/dist/index.html) — versão verificada do protótipo, servida do commit público pelo CDN GitHack. Se aparecer a tela de procedência, toque em **Open the page**.
- [Acompanhar a CI pelo Safari](https://github.com/joaocorrea-12/kotoba-japones/actions)

## Recursos do MVP iOS

- Tela Hoje com palavra, hiragana, significado, exemplo, pronúncia, favorito, meta e sequência.
- 121 entradas introdutórias com romaji, classe, nível estimado, exemplos e notas de uso.
- Intervalos de 10, 20, 30, 40 e 50 minutos; 1, 2, 3, 4, 6, 8, 12 e 24 horas; personalizado de 1 minuto a 7 dias, em minutos ou horas.
- Cronograma determinístico persistido, pausa, retomada, dias ativos, ordem progressiva e aleatória estável. Palavras dominadas são evitadas quando há outras elegíveis.
- Widgets pequeno, médio e grande; tela bloqueada inline, circular e retangular. Tradução e aparência configuráveis por widget, com deep links.
- App Group com snapshot JSON versionado e escrita atômica, compartilhado com a extensão.
- Notificações locais com intervalo independente, dias de estudo, silêncio e fila finita renovável.
- Pronúncia por AVSpeechSynthesizer com voz `ja-JP` do sistema, erro explícito quando indisponível.
- Favoritos, histórico real de estudo e cartões de revisão persistidos no SwiftData.
- Repetição espaçada documentada, quatro respostas e próxima data de revisão.
- Tema claro/escuro/automático, romaji e traduções opcionais, meta e velocidade de pronúncia.

Os módulos completos de curso e exercícios pertencem à Fase 2 e não são simulados como concluídos nesta entrega. N4–N1, escrita, importação, exportação e iCloud estão previstos para expansão.

## Abrir a prévia no iPhone

Abra o link da prévia no Safari. O CDN pode mostrar uma tela de procedência com **Open the page** antes de abrir o HTML do nosso repositório público. Explore Hoje, Suas palavras, Revisar e Seu ritmo. O botão **Avançar** move apenas o relógio da simulação. Favoritos e revisões ficam no armazenamento local desse navegador, separados dos dados do futuro app. O link está fixado no commit verificado para não mudar enquanto você experimenta.

A publicação pela plataforma Sites ficou bloqueada neste ambiente e não é apresentada como concluída. A alternativa por CDN foi aberta e verificada no navegador. Para hospedagem própria pelo GitHub, o repositório também inclui a entrada `index.html` e `.nojekyll`: em **Settings → Pages**, selecione **Deploy from a branch → main → /(root)**. Essa ativação depende da conta proprietária; não foi realizada nesta entrega.

O protótipo **não instala widgets iOS nem agenda notificações locais nativas**. O aviso de teste é uma mensagem visual na página; a miniatura do widget demonstra a interface. A fala depende de uma voz japonesa oferecida pelo navegador. O navegador não precisa permanecer executando para calcular qual palavra deveria ser exibida na próxima abertura.

No GitHub pelo Safari, a aba **Code** permite ler os arquivos e o README; **Actions** mostra os testes e logs. Um job verde só comprova os checks executados naquele commit. Falhas de assinatura, execução em aparelho e precisão de entrega de widgets exigem validação própria. Para baixar o projeto, use **Code → Download ZIP**.

## Estrutura

```text
Packages/KotobaCore/    Domínio Foundation, calendário, vocabulário, fila e revisão
iOS/App/               SwiftUI, serviços e persistência SwiftData
iOS/Shared/            Snapshot App Group e auxiliares usados pelos dois targets
iOS/Widgets/           WidgetKit + configuração por App Intents
iOS/Tests/             Testes de persistência SwiftData e serialização
android/               App nativo Kotlin/Compose, widget, agendamento e testes Android
project.yml            Projeto XcodeGen: app, extensão, testes, capabilities e scheme
web-prototype/         Prévia HTML/CSS/JS independente, sem dependências externas
scripts/               Geração de assets e verificações portáveis
docs/                  Arquitetura, decisões, limites do iOS e validação
.github/workflows/     CI portável, Swift e simulador em macOS
```

## Executar o app em um Mac

Requisitos: macOS compatível, Xcode 16 ou superior com SDK iOS e ferramentas de linha de comando selecionadas, Git e XcodeGen. O deployment target continua sendo iOS 17. O projeto usa Swift 5 para reduzir exigências de migração de concorrência; o pacote pede Swift 5.9+.

```bash
git clone https://github.com/joaocorrea-12/kotoba-japones.git
cd kotoba-japones
brew install xcodegen
bash scripts/bootstrap-macos.sh
open Kotoba.xcodeproj
```

`project.yml` é a fonte do projeto; o `.xcodeproj` é gerado e ignorado pelo Git. O gerador também materializa os Info.plists e entitlements em `iOS/Configuration`. Não é necessário criar targets manualmente.

1. Em ambos os targets, configure seu **Team** e identificadores de bundle exclusivos. O identificador da extensão deve ter o prefixo do app.
2. Troque `KOTOBA_APP_GROUP` em `project.yml` por um App Group registrado para sua equipe, como `group.seudominio.kotoba`. Habilite o mesmo grupo nos dois targets e gere novamente o projeto. O valor é expandido nos entitlements e no Info.plist de ambos.
3. Execute o scheme **Kotoba** no simulador. Se o container de App Group não estiver disponível na configuração utilizada, o app apresenta uma mensagem de configuração; ele não cria silenciosamente um cronograma divergente.
4. Abra o app uma vez e salve seus ajustes. Adicione os widgets pela galeria da tela inicial ou da tela bloqueada. Toque neles para conferir a página correta.
5. Em aparelho, habilite o modo de desenvolvedor e configure o provisionamento. App Groups e distribuição podem exigir participação no Apple Developer Program. Não há promessa de assinatura gratuita para todas as capabilities.

Assinatura, provisionamento, Archive, distribuição por TestFlight e envio à App Store precisam de ferramentas Apple em macOS ou de serviço de compilação compatível. Uma build de simulador da CI não é instalável no iPhone. Serviços de terceiros podem cobrar; o projeto não depende deles e não inclui segredos de assinatura.

## Testes

Verificações disponíveis em Windows/Linux/macOS, com Python 3 e Node 22+:

```bash
python scripts/validate.py
node --test web-prototype/tests/engine.test.mjs
```

Em um ambiente com Swift:

```bash
swift test --package-path Packages/KotobaCore
```

Em macOS, depois de gerar o projeto:

```bash
xcodebuild -project Kotoba.xcodeproj -scheme Kotoba \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO test
```

Escolha um simulador instalado (`xcrun simctl list devices available`). A CI escolhe dinamicamente um iPhone disponível. Os testes JS validam a simulação web e seus vetores de comportamento; **não executam o código Swift**.

Para servir a prévia localmente:

```bash
python -m http.server 4173 --bind 127.0.0.1 --directory web-prototype/dist
```

Abra `http://127.0.0.1:4173` no computador que executa o servidor. Esse endereço local não abre automaticamente no Safari de outro aparelho. Para o iPhone, use o Site publicado ou uma hospedagem estática HTTPS. Não abra `index.html` diretamente como arquivo: o navegador pode bloquear o JSON local.

## Limites essenciais

Widgets **não têm atualização visual exata garantida**. Intervalos de 10/20 minutos definem o estudo e a linha do tempo pretendida; o iOS pode atrasar a apresentação. Intervalos personalizados abaixo de 5 minutos são agrupados nas entradas do widget. O app em primeiro plano verifica o relógio; quando reabre, recalcula a palavra sem depender de um timer anterior.

A fila agenda no máximo 60 avisos para até 30 dias, respeitando pedidos pendentes de outros recursos do app. Ao abrir o Kotoba, mudar configurações, pausar ou retomar, a fila é refeita. **Depois de a fila acabar, notificações deixam de chegar até o app ser aberto novamente.** O app e os widgets continuam calculando palavras pelo cronograma, sujeitos à atualização visual do sistema. Foco, permissões, relógio e decisões do iOS podem afetar a entrega.

Não há background contínuo, servidor, conta, pagamento, analytics nem CloudKit nesta versão. A voz japonesa pode precisar de download pelo usuário antes do uso offline.

## Conteúdo e expansão

O banco é um JSON original com IDs estáveis. Para expandir, mantenha o schema e IDs, acrescente conteúdo próprio/licenciado, execute `python scripts/prepare-assets.py` e os validadores. Alterações que removam IDs do cronograma existente exigem migração planejada; não apague IDs publicados.

As etiquetas JLPT são estimativas pedagógicas: não há alegação de uma lista oficial de vocabulário por nível. A base recebeu conferência editorial nesta implementação, mas **não foi revisada por um linguista humano independente**. Antes de publicação educacional, faça essa revisão, especialmente de níveis, naturalidade e acessibilidade.

Código e identidade: [MIT](LICENSE). Vocabulário, exemplos e traduções originais: [CC0](docs/CONTEUDO.md). [Privacidade](docs/PRIVACIDADE.md) · [Arquitetura](docs/ARQUITETURA.md) · [Roteiro](docs/ROADMAP.md).
