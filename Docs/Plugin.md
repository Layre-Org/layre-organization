# Layre Plugin

Para utilizar A Org, você precisa obrigatoriamente usar o plugin. É ele que interpreta os Snippets, Auto-complete e até a tipagem dinâmica para os UIControllers. Ele mantém nosso código organizado, padronizado e legível graças o Auto-import de Services e Packages.

> **💡 Dica:** Você pode customizar alguns atalhos do Studio para combinar com o Plugin, por exemplo: Auto-focar na Command Bar.

# Índice das funcionalidades

-   [Funções Principais](#setup-e-update-org)
-   [Atalhos com a Command Bar](#lista-de-comandos-command-bar)
-   [Snipetts e Auto-Complete](#snipetts)
-   [Tipagem Dinâmica](#tipagem-dinâmica)

## Setup e Update Org

Ambas as funcionalidades aparecem na aba de Plugins do Roblox Studio

-   **Setup Org:** Inicializa a estrutura de pastas mais recente da org
-   **Update Org:** Atualiza a estrutura atual para a nova mais recente

> ⚠️ **ATENÇÃO:** **Update Org** não foi 100% testado e pode estar instável, para se proteger é recomendado criar uma cópia da org atual e mover para o ServerStorage.

## Lista de Comandos (Command Bar)

### Para criar um ModuleScript e posicioná-lo no local adequado da Org, digite:

```lua
NomeDesejado@+Tipo
```

Ao der Enter, um ModuleScript será criado dentro da pasta equivalente ao `Tipo` e será renomeado com base no `NomeDesejado`.

-   Para especificar o campo `Tipo`, use como base os **Padrões de Projeto**, são eles: UIController, Handler, Manager, Packet.. entre outros.

### Para abrir um ModuleScript automaticamente, digite um `@` seguido do `Nome`:

```lua
@NomeDoModule
```

O plugin faz uma busca rápida em `ServerScriptService` e `ReplicatedStorage`, se este ModuleScript existir ele então foca automaticamente no mesmo.

> **💡 Dica:** O plugin precisa do `@` na maioria dos comandos, é assim que decide se é um comando dele ou não.

## Snipetts

### Auto-GetService

O Plugin importa automaticamente qualquer serviço padrão do Roblox, **basta digitar o `Nome` que o Auto-complete mostrará a sugestão**:

```diff
+--</Services
+local Players = game:GetService('Players')

local Handler = {}

function Handler.Test()
+   local OnlinePlayers = Players:GetPlayers() -- auto-complete criou a seção "Services" e deu GetService('Players')
end
```

### Auto Packages Import

Podemos dar `require()` automaticamente em qualquer `Package` de dentro da Org. funciona do mesmo jeito da [Importação de Serviços Automática](#auto-getservice) com a única adição do `@` antes do nome:

```diff
+--</Packages
+local Fusion = require(path.to.fusion)

local Handler = {}

function Handler.Test()
    -- digitou @Fusion -> Auto-complete encontrou o Package do Fusion
+   local Scope = Fusion.scoped()
end
```

## Tipagem Dinâmica

Esta função se refere à geração automática de tipos para as interfaces do game, usado em `Scopes` (Fusion) e o `Paths`.

Tudo fica armazenado na pasta `__generated` em `ReplicatedStorage/Packages/Shared/Types/`, e dentro dela é comum existir:

-   **UIPaths:** Contém uma "descrição" completa de todo o StarterGui
-   **UIScope:** Gera toda a tipagem necessária para os Scopes do Fusion (que são modificados pelo [Client Core](https://github.com/Layre-Org/layre-organization/blob/main/Template/ReplicatedStorage/Packages/Client/Core/Main.lua))
