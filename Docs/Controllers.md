# Controllers

É com Controllers e UIControllers que o Client funciona, acompanhando métodos parecidos com os [Métodos Built-in de Managers](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Managers.md#índice-dos-métodos-built-in).

Existe uma lista de métodos, funcionalidades e padrões exclusivos para `Controllers` e outra para `UIControllers`, todos eles citados abaixo executam com base em algumas regras que são geridas pelo [Client Core](https://github.com/Layre-Org/layre-organization/blob/main/Template/ReplicatedStorage/Packages/Client/Core/Main.lua) da Org.

-   Veja como é o [código fonte do Core](https://github.com/Layre-Org/layre-organization/blob/main/Template/ReplicatedStorage/Packages/Client/Core/Main.lua)

> **💡 Dica:** Assim como os [Managers](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Managers.md), você pode utilizar `_` (underscore) no nome do Module, para literalmente ignorar a execução deste Controller/UIController.

---

## Índice das Principais Diferenças

> ⚠️ **ATENÇÃO AQUI:**  
> **Controllers** são e possuem propósitos diferentes de **UIControllers**.
> Fique atento também das diferenças entre os **Managers**, são métodos com o mesmo propósito mas que mudam de contexto entre Server/Client.

-   [Funcionalidades em comum](#funcionalidades-em-comum-controllers-e-uicontrollers) (Utilizado em `Controllers` ou `UIControllers`)
-   [Exclusividade de Controllers](#exclusividade-de-controllers) (Utilizado **somente** em `Controllers`)
-   [Exclusividade de UIControllers](#exclusividade-de-uicontrollers) (Utilizado **somente** em `UIControllers`)

## Funcionalidades em Comum (Controllers e UIControllers)

-   [Métodos do LocalPlayer](#métodos-do-localplayer)
-   [Métodos de Loop](#métodos-de-loop)
-   [Integração nativa com Janitor](#integração-nativa-com-janitor)

## Exclusividade de Controllers

Nenhuma destas funcionalidades se aplicam ou se misturam com as de [UIControllers](#exclusividade-de-uicontrollers).

### Métodos de Execução

É em algum destes métodos que você vai conectar os `listeners` do [ByteNet](https://ffrostfall.github.io/ByteNet/), configurar [Classes](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Classes.md), [Components](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Components.md) ou simplesmente configurar variáveis daquele código.

-   `Controller:Setup()` -> Executa primeiro que tudo.
-   `Controller:Start()` -> Executado após o Setup, é um método **padrão e o mais utilizado**.
-   `Controller:Awake()` -> Executado após o Setup e o Start, utilizado normalmente para definir configurações que dependam de que outros Controllers tenham feito antes.

> **💡 Dica:** O método :Start() é o mais comum, a escolha ainda é sua de qual prefere utilizar, claro, considerando o seu contexto específico.

### Onde e como utilizar

`Controllers` no Client, possuem seu principal papel de **gerenciar lógica do Client em sí**, diferente da lógica de UI.

**Exemplos comuns de utilização dos Controllers:**

-   Sistema de NPC (Prompt, Quests, Movimentação)
-   Sistema de Combate (VFX, Animações, Lógica de Combos, HP)
-   Sistema de Chat (Comandos, TextChannels, Tags)

## Exclusividade de UIControllers

Nenhuma destas funcionalidades se aplicam ou se misturam com as de [Controllers](#exclusividade-de-controllers).

> **💡 Dica:** `UIControllers` fazem parte da UI Framework da Org, utilizando como base o [Fusion 3.0](https://elttob.uk/Fusion/0.3/) e juntando com conceitos de React.js e sua Componentização.

### UIControllers focam somente em lógica de UI

São eles que gerenciam `Scopes`, `UIComponents` (veja mais em [Components](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Components.md)), [Stores](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Stores.md), UI reativa e muito mais.

**Seu principal e único Método de Execução é o `:Start()`:**

-   `UIController:Start(Scope: UIScope)` -> Sendo `Scope` o parâmetro que o [Client Core](https://github.com/Layre-Org/layre-organization/blob/main/Template/ReplicatedStorage/Packages/Client/Core/Main.lua) inicializa com `Paths`, [Stores](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Stores.md), [Components](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Components.md) e muito mais.

## Métodos do LocalPlayer

O [Client Core](https://github.com/Layre-Org/layre-organization/blob/main/Template/ReplicatedStorage/Packages/Client/Core/Main.lua) cria conexões de eventos para o `LocalPlayer` assim que o Client carrega, e então executa os `Controllers` e `UIControllers` que tiverem "registrado" estes métodos, são eles:

-   `Controller:OnPlayerAdded()` -> Executado quando o Client entra no jogo.
-   `Controller:OnPlayerRemoving()` -> Executado quando o Client estiver saindo do jogo.
-   `Controller:OnPlayerSpawn(Character)` -> Executado quando o `LocalCharacter` é spawnado, **ou seja: quando entrar e após cada respawn**.
-   `Controller:OnPlayerDied(Character)` -> Executado quando o Client morre.

## Métodos de Loop

-   `Controller:Update(DeltaTime)` -> Um loop de RunService executado a cada frame, **sofrendo variações de framerate**.
-   `Controller:FixedUpdate(DeltaTime)` -> Um loop de RunService executado uma quantidade definida de vezes por segundo, **sem sofrer variações**.

## Integração nativa com Janitor

Colocando `Janitor = true` como no exemplo abaixo, integra as principais funções do [Janitor](https://howmanysmall.github.io/Janitor/), como `:Add()` e `:CleanUp()` no próprio `self`.

**Exemplo:**

```lua
local ExampleController = {}
ExampleController.Janitor = true

function ExampleController:Start()
    self:Add('ExampleConnection')
    self:CleanUp()
end
```
