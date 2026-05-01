# Managers

**O principal module do Server**, onde as principais execuções de cada sistema vão rodar.

Existe uma lista de métodos exclusivos e pensados para melhorar a produtividade ao codar em Managers, todos eles citados abaixo executam com base em algumas regras que são geridas pelo **Server Core** da Org.

> **💡 Dica:** Assim como os [Controllers](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Controllers.md), você pode utilizar `_` (underscore) no nome do Module, para literalmente ignorar a execução deste Manager.

---

## Índice dos métodos built-in

-   [Métodos de Execução](#métodos-de-execução)
-   [Métodos de Players](#métodos-de-players)
-   [Prioridade de execução](#prioridade-de-execução)
-   [Execução Assíncrona](#execução-assíncrona)

### Métodos de Execução

É em algum destes métodos que você vai conectar os `listeners` do [Flux](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Flux.md), configurar [Classes](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Classes.md), [Components](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Components.md) ou simplesmente configurar variáveis daquele código.

-   `Manager:Setup()` -> Executa primeiro que tudo.
-   `Manager:Start()` -> Executado após o Setup, é um método **padrão e o mais utilizado**.
-   `Manager:Awake()` -> Executado após o Setup e o Start, utilizado normalmente para definir configurações que dependam de que outros Managers ou [Controllers](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Controllers.md) tenham feito antes.

> **💡 Dica:** O método :Start() é o mais comum, a escolha ainda é sua de qual prefere utilizar, claro, considerando o seu contexto específico.

### Métodos de Players

O **Server Core** cria conexões de eventos para cada Player que entre no jogo, e então executa os Managers que tiverem "registrado" estes métodos, são eles:

-   `Manager:OnPlayerAdded(Player)` -> Executado quando um Player entra no jogo.
-   `Manager:OnPlayerRemoving(Player)` -> Executado quando um Player sai do jogo.
-   `Manager:OnCharacterAdded(Player, Character)` -> Executado quando o Character é spawnado, **ou seja: quando entrar e após cada respawn**.
-   `Manager:OnCharacterAppearenceLoaded(Player, Character)` -> Executado quando a aparência do Character é carregada.
-   `Manager:OnPlayerDied(Player, Character)` -> Executado quando um Player morre.

### Prioridade de execução

Todos os managers, por padrão, possuem prioridade `0`, ou seja, executam aleatoriamente. Caso você queira que um manager execute antes que outro, você pode alterar a sua prioridade:

```lua
--</Manager
local FasterManager = {
    Priority = 5,
}

return FasterManager
```

Também é possível alterar a prioridade de apenas um método em específico, fazendo com que mude a ordem de execução daquela fase.

```lua
--</Manager
local TestManager = {
    SetupPriority = 5,
}

function TestManager:Setup()
   -- vai executar com prioridade 5
end

return TestManager
```

### Execução assíncrona

Por padrão, toda execução de uma fase é `Síncrona`, porém caso você queira que a função seja `Assíncrona`, o framework te da a possibilidade de adicionar as key-words `Async` ou `Defer` após o nome da fase:

```lua
--</Manager
local WorldManager = {}

function WorldManager:StartAsync()
    -- geração de mundo
end

return WorldManager
```
