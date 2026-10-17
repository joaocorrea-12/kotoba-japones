# Privacidade — versão inicial

O app nativo Kotoba não requer conta, pagamento, assinatura, analytics ou servidor. Configurações e cronograma ficam no App Group local; histórico, favoritos e revisões ficam no SwiftData privado do app. CloudKit/iCloud não está habilitado.

A pronúncia usa AVSpeechSynthesizer e uma voz japonesa do sistema. Uma voz pode precisar ser baixada pelos ajustes do iPhone antes do uso offline. O código do Kotoba não envia textos a um serviço próprio de fala.

As notificações são locais e opcionais. O usuário pode revogar a permissão no iOS. Widgets podem mostrar palavras e traduções na tela bloqueada; traduções podem ser ocultadas nos ajustes. Eles não exibem o histórico detalhado.

O protótipo web é independente: preferências, favoritos e revisões ficam no localStorage do navegador. A hospedagem Sites pode ter autenticação e registros próprios da plataforma. A síntese de voz web depende do navegador/sistema e não tem a mesma garantia de disponibilidade offline que uma voz previamente instalada no app nativo.

O app ainda não inclui exportação/importação ou uma tela para apagar todo o progresso. Remover o app elimina seu armazenamento local conforme as regras do iOS; dados do App Group podem depender de outras extensões/apps que usem o grupo. Planejar controles de exportação e exclusão antes da publicação final.
