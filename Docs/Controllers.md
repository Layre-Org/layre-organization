# Controllers

É com Controllers e UIControllers que o Client funciona, acompanhando métodos parecidos com os [Métodos Built-in de Managers](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Managers.md#índice-dos-métodos-built-in).

Existe uma lista de métodos, funcionalidades e padrões exclusivos para `Controllers` e outra para `UIControllers`, todos eles citados abaixo executam com base em algumas regras que são geridas pelo **Client Core** do Framework.

> **💡 Dica:** Assim como os [Managers](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Managers.md), você pode utilizar `_` (underscore) no nome do Module, para literalmente ignorar a execução deste Controller/UIController.

---

## Índice das Principais Diferenças

> ⚠️ **ATENÇÃO AQUI:**  
> **Controllers** são e possuem propósitos diferentes de **UIControllers**.
> Fique atento também das diferenças entre os **Managers**, são métodos com o mesmo propósito mas que mudam de contexto entre Server/Client.

- [Funcionalidades em comum](#funcionalidades-em-comum-controllers-e-uicontrollers) (Utilizado em `Controllers` ou `UIControllers`)
- [Exclusividade de Controllers](#exclusividade-de-controllers) (Utilizado **somente** em `Controllers`)
- [Exclusividade de UIControllers](#exclusividade-de-uicontrollers) (Utilizado **somente** em `UIControllers`)

## Funcionalidades em Comum (Controllers e UIControllers)

- [Métodos do LocalPlayer](#métodos-do-localplayer)
- [Prioridade de execução](#prioridade-de-execução)
- [Execução Assíncrona](#execução-assíncrona)

## Exclusividade de Controllers

Nenhuma destas funcionalidades se aplicam ou se misturam com as de [UIControllers](#exclusividade-de-uicontrollers).

### Métodos de Execução

É em algum destes métodos que você vai conectar os `listeners` do [Flux](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Flux.md), configurar [Classes](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Classes.md), [Components](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Components.md) ou simplesmente configurar variáveis daquele código.

- `Controller:Setup()` -> Executa primeiro que tudo.
- `Controller:Start()` -> Executado após o Setup, e após o Server do LocalPlayer carregar (isso é, após o método OnPlayerAdded ser chamado nos Services e Managers do server). É um método **padrão e o mais utilizado**.
- `Controller:Awake()` -> Executado após o Setup e o Start, utilizado normalmente para definir configurações que dependam de que outros Controllers tenham feito antes.

> **💡 Dica:** O método :Start() é o mais comum, a escolha ainda é sua de qual prefere utilizar, claro, considerando o seu contexto específico.

### Onde e como utilizar

`Controllers` no Client, possuem seu principal papel de **gerenciar lógica do Client em sí**, diferente da lógica de UI.

**Exemplos comuns de utilização dos Controllers:**

- Sistema de NPC (Prompt, Quests, Movimentação)
- Sistema de Combate (VFX, Animações, Lógica de Combos, HP)
- Sistema de Chat (Comandos, TextChannels, Tags)

## Exclusividade de UIControllers

Nenhuma destas funcionalidades se aplicam ou se misturam com as de [Controllers](#exclusividade-de-controllers).

> **💡 Dica:** `UIControllers` fazem parte da UI Framework, utilizando como base o [Fusion 3.0](https://elttob.uk/Fusion/0.3/), juntando-se com conceitos de React.js e sua Componentização.

### UIControllers focam somente em lógica de UI

São eles que gerenciam `Scopes`, `UIComponents` (veja mais em [Components](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Components.md)), [Stores](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Stores.md), UI reativa e muito mais.

**Seu principal e único Método de Execução é o `:Start()`:**

- `UIController:Start(Scope: UIScope)` -> Sendo `Scope` o parâmetro que o **Client Core** inicializa com `Paths`, [Stores](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Stores.md), [Components](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Components.md) e muito mais. Veja [Scopes](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Scopes.md) para entender mais.

> **💡 Dica:** O método `Start` é executado somente após o Start dos `Controllers` e das `UIStores`.

## Métodos de Player

O **Client Core** cria conexões de eventos para os Players e para o `LocalPlayer` assim que o Client carrega, e então executa os `Controllers` e `UIControllers` que tiverem "registrado" estes métodos, são eles:

- `Controller:OnPlayerAdded(Player)` -> Executado quando um Player entra no jogo.
- `Controller:OnPlayerRemoving(Player)` -> Executado quando um Player sai do jogo.
- `Controller:OnCharacterAdded(Player, Character)` -> Executado quando o `LocalCharacter` é spawnado, **ou seja: quando entrar e após cada respawn**.
- `Controller:OnCharacterAppearenceLoaded(Player, Character)` -> Executado quando a aparência do `LocalCharacter` é carregada.
- `Controller:OnPlayerDied(Player)` -> Executado quando o `LocalCharacter` morre.

### Prioridade de execução

Todos os controllers, por padrão, possuem prioridade `0`, ou seja, executam aleatoriamente. Caso você queira que um controller execute antes que outro, você pode alterar a sua prioridade:

```lua
--</Controller
local FasterController = {
    Priority = 5,
}

return FasterController
```

Também é possível alterar a prioridade de apenas um método em específico, fazendo com que mude a ordem de execução daquela fase.

```lua
--</Controller
local TestController = {
    SetupPriority = 5,
}

function TestController:Setup()
   -- vai executar com prioridade 5
end

return TestController
```

### Execução assíncrona

Por padrão, toda execução de uma fase é `Síncrona`, porém caso você queira que a função seja `Assíncrona`, o framework te da a possibilidade de adicionar as key-words `Async` ou `Defer` após o nome da fase:

```lua
--</Controller
local WorldController = {}

function WorldController:StartAsync()
    -- geração de mundo
end

return WorldController
```
