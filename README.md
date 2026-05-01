# Layre Framework

O Framework da Layre consiste na padronização de código, com um amontoado de features que misturam [Atalhos](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Plugin.md#lista-de-comandos-command-bar) (Plugin), [Snippets](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Plugin.md#snipetts) (Plugin), [Padrões de Projeto](#padrões-de-projeto) e entre muitas outras funcionalidades, onde o principal objetivo é contornar o principal vilão do Roblox Studio: **A produtividade**.

Nesse readme você consegue consultar cada tópico que o **Framework** aborda, cada índice foi separado por categoria/assunto, basta clicar e ir navegando onde te interessa.

---

## 📦 Instalação

Tudo gira em torno do [Plugin](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Plugin.md), é com ele que você vai injetar e utilizar o Framework.

Você até pode usar e instalar manualmente os `.rbxm` disponibilizados, mas fica completamente por sua conta e risco, e **não é nada recomendável** que faça isso.

> ⚠️ **ATENÇÃO:**  
> A instalação do plugin deve ser feita **manualmente** por enquanto.

**Por isso, instale o plugin apenas da seguinte forma:**

1. Acesse o último release oficial na [Página de Releases](https://github.com/Layre-Org/layre-organization/releases/tag/release)
2. Busque pela **última release estável** -> Geralmente é a primeira da lista, e estará marcada como "nova" ou "latest".
3. Se houver instruções nesta release, é altamente recomendável a leitura.
4. Busque pelo anexo `Layre Plugin.rbxmx` e baixe-o.
5. Abra o Explorador de Arquivos, vá na barra de diretórios e cole o comando: `%LOCALAPPDATA%\Roblox\Plugins`.
6. Mova o `.rbxmx` para esta pasta e re-abra seu Roblox Studio -> Verifique na aba de Plugins.

> ✅ Seu plugin foi instalado e você já pode iniciar seu novo projeto

---

## 📖 Documentação

### Plugin

-   [Como usar o Plugin](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Plugin.md)

### Padrões de Projeto

-   [Managers](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Managers.md)
-   [Controllers](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Controllers.md)
-   [Components](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Components.md)
-   [Classes](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Classes.md)
-   [Stores](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Stores.md)

### Ferramentas Exclusivas (diretamente integradas)

-   [Flux](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Flux.md) (Fortemente baseado em [ByteNet](https://ffrostfall.github.io/ByteNet/), mantido por [@Gui97p](https://github.com/Gui97p))
-   LuaO (desenvolvido por [@Gui97p](https://github.com/Gui97p) e [@YureAnjos](https://github.com/YureAnjos))
-   Data Structures (desenvolvido por [@Gui97p](https://github.com/Gui97p))
-   [Super](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Classes.md#herança-com-a-lib-super) (desenvolvido por [@Gui97p](https://github.com/Gui97p))
-   [Janitor](https://howmanysmall.github.io/Janitor/)
-   [Promise](https://eryn.io/roblox-lua-promise/) (Movido para o LuaO, com base em task)
-   [Fusion 3.0](https://elttob.uk/Fusion/0.3/)
-   .._entre muitas outras libs_

### Services (Servidor)

Os Services são módulos do servidor que encapsulam sistemas reutilizáveis do jogo. Eles são carregados automaticamente pelo framework e integram-se com os ciclos de vida dos Managers.

-   [DataService](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Services/DataService.md) — Carregamento e persistência de dados de player via ProfileStore
-   [StatsService](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Services/StatsService.md) — Atributos, moedas e modifiers de player
-   [PlayersService](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Services/PlayersService.md) — Sistema de saúde customizado e rastreamento de amigos online
-   [MarketplaceService](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Services/MarketplaceService.md) — Gamepasses e developer products com processamento seguro de compras
-   [OrderedDataService](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Services/OrderedDataService.md) — Rankings e leaderboards via OrderedDataStore

### Configuração do Projeto

-   [Constants](#-constants) — Configurações globais do framework
-   [Template e Attributes](#-template-e-attributes) — Estrutura de dados e mapeamento de atributos dos players

---

## ⚙️ Constants

O módulo `Constants` centraliza todas as configurações do framework. Ele é dividido em sub-módulos por responsabilidade.

### Constants (raiz)

Configurações globais acessíveis em **servidor e cliente**:

```lua
-- Fases do ciclo de vida disponíveis para Managers e Controllers
Constants.LIFE_CYCLE_PHASES = {
    SETUP, START, AWAKE,
    ON_PLAYER_ADDED, ON_PLAYER_REMOVING,
    ON_CHARACTER_ADDED, ON_CHARACTER_APPEARANCE_LOADED,
    ON_PLAYER_DIED
}

-- Modos de execução das fases
Constants.LIFE_CYCLE_EXECUTION_MODES = {
    SYNC,   -- Executa em sequência, bloqueia até terminar
    ASYNC,  -- Executa em paralelo via task.spawn
    DEFER   -- Executa no próximo frame via task.defer
}

-- Namespaces do bootstrap (nomes das pastas carregadas pelo Core)
Constants.BOOTSTRAP_NAMESPACES = {
    MANAGERS, CONTROLLERS, UI_CONTROLLERS, UI_STORES
}
```

**Debug:**

| Flag | Padrão | Descrição |
|---|---|---|
| `Debug.LifeCycle.BOOT` | `false` | Loga o processo de boot do framework |
| `Debug.LifeCycle.FUNCTIONAL_WARNS` | `true` | Avisos de uso incorreto para facilitar debug |
| `Debug.LifeCycle.PHASES_CLIENT` | `false` | Loga execução de fases nos módulos cliente |
| `Debug.LifeCycle.PHASES_SERVER` | `false` | Loga execução de fases nos módulos servidor |
| `Debug.LifeCycle.PHASES_EXCLUDE` | `{}` | Lista de fases excluídas do log |

> **💡 Dica:** `FUNCTIONAL_WARNS` é o mais útil no dia a dia — mantê-lo `true` em desenvolvimento evita erros silenciosos comuns de uso incorreto da API.

---

### Constants.Server

Configurações **exclusivas do servidor**, acessíveis via `Constants.Server`:

**Player:**

| Constante | Padrão | Descrição |
|---|---|---|
| `CUSTOM_RESPAWN_SYSTEM` | `true` | O framework gerencia o respawn do character |
| `CUSTOM_HEALTH_SYSTEM` | `true` | O framework gerencia a saúde do player |
| `CHARACTER_RESPAWN_TIME` | `2` | Tempo de respawn padrão em segundos. Pode ser sobrescrito por player via atributo `RespawnTime` |
| `MAX_HEALTH` | `100` | Saúde máxima padrão ao entrar no jogo |
| `MAX_HEALTH_ATTR` | `"MaxHealth"` | Nome do atributo de saúde máxima no Player |
| `HEALTH_ATTR` | `"Health"` | Nome do atributo de saúde atual no Player |

**Atributos e moedas:**

| Constante | Padrão | Descrição |
|---|---|---|
| `CURRENCY_LIST` | `{"Cash"}` | Lista de atributos tratados como moeda pelo StatsService |
| `INFINITE_CURRENCY` | `false` | Moeda infinita para testes em Studio |
| `MOCK_GAMEPASSES` | `false` | Concede todos os gamepasses automaticamente em Studio |

**Dados:**

| Constante | Padrão | Descrição |
|---|---|---|
| `STORE_NAME` | `"_GameStore000"` | Nome do DataStore usado pelo ProfileStore |
| `PROFILE_TIMEOUT` | `10` | Segundos máximos de espera pelo perfil do player |
| `LOG_ON_DATA_LOAD` | `true` | Printa os dados carregados do player no output |
| `USE_MOCK` | `false` | Usa DataStore simulado em memória (dados não são salvos) |

---

### Constants.Gamepasses

Define os gamepasses do jogo. Cada entrada é usada pelo `MarketplaceService` para verificação, mock e hooks.

```lua
-- Constants/Gamepasses.luau
local Gamepasses = {}

Gamepasses.VipPass = {
    Id = 123,
    AttributeName = 'VipPass', -- opcional: nome do atributo criado no player (usa a chave se omitido)
    Mock = true,               -- opcional: se false, esse gamepass nunca é mockado (padrão: true)
}

return Gamepasses
```

---

### Constants.Products

Define os developer products do jogo. Cada entrada é usada pelo `MarketplaceService` para processar compras via `ProductHook`.

```lua
-- Constants/Products.luau
local Products = {}

Products.Coins100 = {
    Id = 3579789213
}

return Products
```

---

## 🗄️ Template e Attributes

### Template

O `Template` define a **estrutura padrão dos dados** de cada player no DataStore. Todo campo aqui representa um dado persistido — o valor é o padrão aplicado quando o player entra pela primeira vez ou quando um campo é resetado via `DataService:Wipe` ou `StatsService:Wipe`.

```lua
-- Core/Template/init.luau
return {
    Cash = 0,
    -- adicione novos campos aqui
}
```

**Template.Mock**

Quando `Constants.Server.USE_MOCK` está ativo, os valores do `Template.Mock` são injetados nos dados do player logo após o carregamento, sobrescrevendo os valores reais. Útil para testar com dados pré-definidos sem precisar manipular o DataStore.

```lua
-- Core/Template/Mock.luau
return {
    Cash = 5000,
}
```

> **⚠️ Atenção:** Todo campo novo que você adicionar ao `Template` deve também ser adicionado ao `Attributes` caso queira ele como atributo.

---

### Attributes

O módulo `Attributes` é uma **função de mapeamento** executada pelo `StatsService` ao carregar o player. Ela recebe os dados do perfil e define quais campos viram atributos no Player e quais aparecem no `leaderstats`.

```lua
-- Core/Attributes.luau
return function(Data, LeaderStats)
    LeaderStats:Register('Cash') -- aparece no leaderstats in-game

    return {
        Cash = Data.Cash,        -- vira Client:GetAttribute("Cash")
        -- adicione novos campos aqui
    }
end
```

**`LeaderStats:Register(attributeName, displayName?, format?)`**

Registra um atributo para aparecer no painel de `leaderstats` in-game.

| Parâmetro | Tipo | Descrição |
|---|---|---|
| `attributeName` | `string` | Nome do atributo a ser exibido |
| `displayName` | `string?` | Nome de exibição no painel (usa `attributeName` se omitido) |
| `format` | `function?` | Função de formatação do valor exibido |

> **💡 Dica:** Nem todo atributo precisa aparecer no leaderstats — chame `Register` apenas para os que fazem sentido serem visíveis ao player.

**Fluxo completo de um novo campo de dados:**

```
1. Adicione o campo ao Template        →  { Kills = 0 }
2. Adicione ao Template.Mock           →  { Kills = 99 }  (opcional)
3. Mapeie no Attributes                →  Kills = Data.Kills
4. Registre no LeaderStats se necessário →  LeaderStats:Register('Kills')
```

---

## 📝 Contribuição

Antes de solicitar um Issue ou PR (Pull Request) é de extrema importância entender sobre o [SemVer](https://semver.org/lang/pt-BR/) (Versionamento Semântico) e estar ciente das últimas versões publicadas em [Releases](https://github.com/Layre-Org/layre-organization/releases).

-   Veja [como contribuir com o Framework](https://github.com/Layre-Org/layre-organization/blob/main/Docs/PRsAndContribution.md)