# Conteúdo e licenças

O arquivo `Packages/KotobaCore/Sources/KotobaCore/Resources/words.json` contém **121 entradas**. As palavras japonesas são vocabulário comum; a seleção, ordem, exemplos, traduções brasileiras e notas foram produzidos para este projeto. Não houve importação de bancos externos nem extração de conteúdo de Hourly Kana.

O conteúdo autoral desse JSON é dedicado ao domínio público sob [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/legalcode.pt). Não há atribuições obrigatórias de datasets de terceiros. Código, layout e símbolo gráfico original usam a licença MIT na raiz.

## Convenções

- IDs `k001`…`k121` são estáveis. Não reutilize IDs para outros conceitos.
- `japanese`: grafia de apresentação; `kana`: leitura em hiragana (inclusive para palavras normalmente escritas em katakana, como パン).
- `romaji`: romanização didática com mácrons em vogais longas, próxima ao Hepburn.
- `jlpt`: estimativa introdutória; a base atual usa N5. O projeto não afirma ser uma lista oficial do exame.
- `partOfSpeech`: classe gramatical com distinção de verbos e adjetivos em い/な.
- `example`: frase original, normalmente em registro educado; `exampleMeaning`: tradução natural em português brasileiro.
- `note`: observações relevantes de uso, leituras ou formas irregulares.

Nomes próprios de exemplos não representam pessoas reais. Algumas traduções são naturais, e não palavra por palavra: `海に行く` pode ser traduzido como ir à praia; a nota explica o sentido literal.

## Revisão realizada e pendente

Foram conferidos campos obrigatórios, IDs únicos, grafia da leitura em hiragana, presença de exemplos/traduções, contrastes como 暑い/熱い e ある/いる, uso de は em saudações e conjugações nas frases. Os validadores verificam estrutura, não a naturalidade da língua.

Esta conferência editorial foi feita durante a implementação por IA. **Não equivale a uma revisão humana independente.** Antes de distribuir, um professor ou linguista de japonês com português brasileiro deve revisar cada entrada, estimativas JLPT e a pronúncia emitida pelo sintetizador. Não se alega perfeição linguística nem revisão por especialista externo.

Para acrescentar palavras: preserve o schema, forneça todos os campos, documente autoria/licença, execute `python scripts/prepare-assets.py`, `python scripts/validate.py` e os testes Swift/JS. Não remova IDs publicados sem migrar cronogramas e registros existentes.
