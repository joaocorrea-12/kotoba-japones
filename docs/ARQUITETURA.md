# Arquitetura e decisões

## Um cronograma, vários leitores

`KotobaCore` é um pacote Swift independente de SwiftUI/WidgetKit. `WordSchedule` contém âncora absoluta, IDs ordenados, semente, configurações, fuso, pausa e segundos de estudo descontados. O app é o único escritor de `schedule-v1.json`; app e extensão leem o mesmo formato versionado. A troca de arquivo é atômica. O banco SwiftData é privado do app: widgets não precisam abrir SQLite.

Em um dia ativo:

```text
tempo = segundos dos dias ativos entre âncora e agora − segundos ativos pausados
índice = piso(tempo / intervaloEmSegundos)
palavra = IDsOrdenados[índice % quantidade]
```

Os limites de dias vêm de um Calendar gregoriano com fuso persistido, e não de blocos fixos de 86400 segundos. Dias de 23/25 horas são tratados pelo calendário. Se uma fronteira cair exatamente no começo de um dia inativo, a palavra anterior permanece até o próximo dia ativo. O restante do intervalo é preservado na pausa. O silêncio afeta somente notificações.

A ordem editorial é progressiva. A opção aleatória ordena IDs por FNV-1a de semente + ID e desempata pelo próprio ID; não usa `hashValue`, `shuffled()` ou um estado aleatório diferente por processo. A ordem inteira fica no snapshot, garantindo a mesma palavra entre os leitores. Sementes são locais e não são identificadores de usuário.

Trocar intervalo, nível, dias, modo aleatório ou fuso inicia uma nova âncora, mantendo a palavra atual quando ainda elegível e reiniciando a contagem do intervalo. Alterar só aparência, leituras, tradução ou frequência de avisos preserva o cronograma das palavras. Retomar conserva o tempo restante; avisos seguem sua cadência independente e não geram uma enxurrada de avisos perdidos.

`Vocabulary.deck` inclui a base do nível escolhido e anteriores (N5 é a base de N4 etc.). Domínio requer cinco sucessos e intervalo de pelo menos 21 dias. Quando todos os itens elegíveis estiverem dominados, o baralho volta a incluí-los para manutenção, evitando um cronograma vazio.

Ao voltar ao primeiro plano, o app atualiza o fuso se a região mudou e renova a fila. Antes dessa abertura, widget e avisos continuam usando o fuso persistido. Mudanças manuais no relógio podem retroceder a palavra; isso é consequência explícita de um cronograma baseado no relógio do aparelho.

## WidgetKit

`AppIntentConfiguration` permite escolher Papel/Jardim e mostrar tradução por instância. Ocultar traduções no app prevalece sobre a opção do widget. Uma timeline inclui o instante atual e até 35 instantes futuros calculados do cronograma, com horizonte de sete dias. Datas menores que cinco minutos são agrupadas; não se promete exibição de todas as palavras no widget nesses intervalos.

O provider retorna uma política `.after`, e o app solicita `reloadAllTimelines()` após mudanças. São pedidos ao sistema, não garantias de execução. Sem snapshot ou antes do primeiro desbloqueio após reiniciar, o widget apresenta uma orientação para abrir o app e tenta novamente. A palavra exibida inclui seu ID no URL `kotoba://word/ID`; abrir um widget atrasado leva ao item mostrado, mesmo que a palavra vigente já seja outra.

Proteção do arquivo: `completeUntilFirstUserAuthentication`. O conteúdo compartilhado é vocabulário e configurações de estudo, permitindo leitura na tela bloqueada depois do primeiro desbloqueio. Progresso detalhado e favoritos ficam no armazenamento privado do app.

## Notificações locais

`NotificationPlanner` calcula datas numa cadência independente. Cada conteúdo é associado à palavra que estará vigente na data prevista, com preferências de leitura e tradução respeitadas. Datas de silêncio/dias inativos são puladas, sem recuperação em lote. Os triggers usam componentes de calendário em UTC para representar os instantes sem ambiguidade de horário de verão.

`NotificationService` verifica autorização, remove apenas pedidos do namespace `kotoba.word.`, considera outros pedidos pendentes e limita o total conservador a 60. Escritas na fila são serializadas para que mudanças rápidas terminem com a configuração mais recente. Erros são apresentados ao usuário; mudanças no snapshot não são desfeitas silenciosamente quando o iOS recusa um pedido.

Renovação: abertura/retorno ao primeiro plano, alteração de ajustes, pausa/retomada e mudança de domínio que altera o baralho. Há até 60 pedidos e horizonte máximo de 30 dias. Não há renovação garantida se o usuário não abrir o app. Um lembrete genérico repetitivo poderia sobreviver mais tempo, mas não conteria a palavra correta sem execução; ele não é usado.

## Persistência e aprendizagem

`LearningRecord` é único por ID; guarda favorito, primeira/última abertura, intervalo, facilidade, sucessos, lapsos e próxima revisão. `StudyActivity` registra leituras (uma por palavra/dia) e revisões. A meta conta IDs distintos abertos ou revisados naquele dia. Widgets e notificações não contam automaticamente como estudo.

O histórico Vistas contém aberturas reais, e Anteriores reconstrói os últimos itens da programação atual. As aberturas reais sobrevivem a mudanças de cronograma. A sequência conta dias corridos; um dia sem atividade interrompe a sequência, mesmo que seja um dia de descanso nas preferências. Uma sequência de ontem continua visível até o fim do dia de hoje.

SwiftData está local e CloudKit está explicitamente desativado. Não há migração destrutiva automática nem fallback silencioso quando o App Group ou o JSON não estão disponíveis. Uma futura alteração de schema requer migração versionada e cobertura de restauração.

## Revisão: algoritmo simples inspirado em SM-2

Estado inicial: intervalo zero, facilidade 2,5, sucessos/lapsos zero, revisão disponível agora. O verso exige recuperação ativa antes de o usuário avaliar. Fórmulas usam dias de 86400 segundos, como duração de revisão, não dias de calendário de estudo.

| Resposta | Regra |
| --- | --- |
| Novamente | lapso +1, sucessos zerados, facilidade −0,2 (mín. 1,3), voltar em 10 min |
| Difícil | facilidade −0,15 (mín. 1,3), intervalo ×1,2, mínimo 1 dia; não conta novo acerto |
| Bom | acerto +1; primeiro 1 dia, segundo 3 dias, depois intervalo × facilidade |
| Fácil | acerto +1; facilidade +0,15 (máx. 3), primeiro 4 dias, depois intervalo × facilidade ×1,3 |

Intervalo máximo: 365 dias. Trata-se de uma heurística pequena e auditável, sem alegação de FSRS ou de otimização clínica. A próxima data, sucessos e dificuldades são persistidos. Revisões não são suprimidas pelo horário de silêncio.

## Fontes técnicas

- [Apple: manter um widget atualizado](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date).
- [Apple: AppIntentTimelineProvider](https://developer.apple.com/documentation/widgetkit/appintenttimelineprovider).
- [Apple: notificações locais](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app).
- [Apple: limite histórico de 64 pedidos locais](https://developer.apple.com/documentation/uikit/uilocalnotification) — API antiga; usamos UserNotifications e uma margem conservadora de 60.
- [Apple: dados compartilhados](https://developer.apple.com/documentation/technologyoverviews/shared-data).

As garantias de atualização e entrega dependem da versão do iOS e devem ser verificadas no aparelho antes da distribuição.
