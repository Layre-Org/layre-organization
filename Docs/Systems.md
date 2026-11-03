# Systems

A aba **Systems** do [Plugin](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Plugin.md) injeta sistemas prontos (como o UI Template) em um jogo que já segue o Framework. Cada sistema é um Model publicado no Creator Store e listado no catálogo [`systems.json`](https://github.com/Layre-Org/layre-organization/blob/main/systems.json).

# Índice

- [Injetando um sistema](#injetando-um-sistema)
- [Regras da injeção](#regras-da-injeção)
- [Publicando um sistema](#publicando-um-sistema)
- [Estrutura do Model (manifesto)](#estrutura-do-model-manifesto)
- [Chaves de dados, produtos e gamepasses](#chaves-de-dados-produtos-e-gamepasses)

## Injetando um sistema

1. Rode o **Setup** antes, para o jogo ter a estrutura do Framework.
2. Abra a aba **Systems** e escolha o sistema no catálogo.
3. Ligue as features que o jogo vai ter. A **Base** sempre entra; as dependências de uma feature (`Requires`) são incluídas sozinhas.
4. Confira o resumo: itens novos, conflitos, chaves e pendências.
5. Clique em **Injetar** e confirme a lista do que muda.
6. Resolva as **pendências** que aparecem na aba Logs (IDs de produtos, grupo, ajustes de Settings...).
7. Gere o UIScope de novo (aba Recursos), já que o sistema traz Stores e Components novos.

> **💡 Dica:** Ctrl+Z desfaz a injeção das instâncias. As chaves acrescentadas em módulos do jogo são desfeitas pelo editor de scripts.

## Regras da injeção

- **Nada é executado:** o plugin só lê pastas e atributos do Model. Nenhum código do pacote roda para montar a lista.
- **Mesclagem:** containers `Folder`, `ScreenGui` e `Configuration` que já existem no jogo com a mesma classe são mesclados. As categorias do StarterGui (`Hud`, `Tabs`, `Utils`...) são ScreenGuis, porque o StarterGui recria Folders a cada respawn.
- **Conflitos:** qualquer outro item com o mesmo nome é mantido como está, a menos que você escolha **Substituir conflitos**.
- **Prévia fiel:** Base e features são calculadas em sequência. Por exemplo, a `StarterGui/Tabs/GearShop` de uma feature entra na `Tabs` trazida pela Base.
- **Módulos do jogo nunca são substituídos:** `Core/Template`, `Core/Attributes` e `Framework/Constants/{Products, Gamepasses}` só recebem novas chaves (veja [abaixo](#chaves-de-dados-produtos-e-gamepasses)).

## Publicando um sistema

1. Monte o Model seguindo a [estrutura do manifesto](#estrutura-do-model-manifesto).
2. Publique-o no Creator Store. Ele precisa ser público, ou pertencer a você ou ao grupo, para o `LoadAsset` funcionar no Studio.
3. Adicione (ou atualize) a entrada no [`systems.json`](https://github.com/Layre-Org/layre-organization/blob/main/systems.json):

```json
[
    {
        "id": "ui-template",
        "name": "UI Template",
        "description": "HUD, Loja, Prompt e features opcionais",
        "version": "1.0",
        "assetId": 105880943006715
    }
]
```

Os injetados são **cópias**, não Packages vinculados. Para lançar uma versão nova, publique o Model de novo e suba o `version` no catálogo.

## Estrutura do Model (manifesto)

```
UI Template (Model)
│  DisplayName = "UI Template"         (string)
│  Description = "Studs UI Template 2026"
│  Version = "1.0"
│  LayreVersion = "2.0.0"              versão mínima do plugin (bloqueia a injeção se for maior)
│  RequiresFramework = true            avisa se a estrutura do Framework estiver incompleta
├── Base (Folder)                      sempre injetada
│   │  Description = "HUD, Loja, Prompt, componentes"
│   ├── ReplicatedStorage/Client/UI/Controllers/HudController ...
│   ├── StarterGui/Hud (ScreenGui)
│   ├── Pending (Configuration)        opcional
│   │   └── ShopProducts (StringValue)  Value = "Defina os IDs dos produtos em Constants.Products"
│   ├── Data (Configuration)           opcional; chaves de dados do jogador
│   │   └── Cash (StringValue)          Value = "0" (expressão Luau); atributo Publish = true
│   └── Products / Gamepasses (Configuration)   opcionais; entradas das Constants
│       └── Vip (StringValue)           Value = "{ Id = 0 }"
└── Features (Folder)
    ├── DailyRewards (Folder)          o nome da pasta é o id da feature
    │   │  DisplayName = "Daily Rewards"
    │   │  Description = "Recompensa diária com streak de 7 dias"
    │   │  Default = true              já vem ligada
    │   │  Order = 1                   ordem na lista
    │   ├── ReplicatedStorage/...
    │   ├── ServerScriptService/Managers/...
    │   └── Pending (Configuration)
    ├── Inventory (Folder)
    └── GearShop (Folder)
        Requires = "Inventory"         ids separados por vírgula; incluídos automaticamente
```

- Dentro da Base e de cada feature, as pastas com nome de serviço espelham os caminhos finais no jogo.
- As pendências aparecem como badge na feature, no resumo do rodapé e, depois da injeção, como avisos na aba Logs.
- Um Model sem as pastas `Base`/`Features` é tratado como pacote simples: todo o conteúdo vira a base.

## Chaves de dados, produtos e gamepasses

Alguns módulos pertencem ao jogo e já existem nele. Em vez de substituí-los, cada parte (Base ou feature) declara o que precisa e o plugin **acrescenta** as linhas, sob um comentário com o nome da feature:

| Configuration | Cada StringValue | Vai para |
|---|---|---|
| `Data` | Nome = chave, Value = valor inicial em Luau (`"0"`, `"{}"`, `"'Sword'"`) | fim da tabela de `ServerScriptService.Core.Template` |
| `Data` com atributo `Publish = true` | — | também `Chave = Data.Chave` em `Core.Attributes` |
| `Products` | Nome = chave, Value = `"{ Id = 0 }"` | `Products.Chave = ...` antes do `return` de `Framework.Constants.Products` |
| `Gamepasses` | Nome = chave, Value = `"{ Id = 0 }"` | `Gamepasses.Chave = ...` antes do `return` de `Framework.Constants.Gamepasses` |

- Chaves que já existem são mantidas e listadas na aba Logs.
- A busca por chave existente olha o arquivo inteiro: uma chave com o mesmo nome de um campo interno (ex.: `Round` dentro de `Merchant`) é tratada como existente.
