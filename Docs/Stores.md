# Stores

Utilizada geralmente no `Client`, mas compátivel com o `Server`, onde possuem o propósito de armazenar `States` (ou estados) globais e fornecer uma API para operar sobre eles.

> **💡 Dica:** Stores fazem parte da UI Framework da Org, e são controladas por [UIControllers](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Controllers.md#exclusividade-de-uicontrollers) ou até mesmo [UIComponents](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Components.md#o-que-são-uicomponents).

## Sintáxe Base para Stores

Elas armazenam valores e estados do [Fusion](https://elttob.uk/Fusion/0.3/), junto de alguns métodos para realizarmos algumas alterações neles.

Entretando, aqui também sofremos com tipagem e auto-complete, por isso, em conjunto com a [Tipagem Dinâmica do Plugin](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Plugin.md#tipagem-din%C3%A2mica) conseguimos burlar os problemas, **mas é necessário um padrão**:

```lua
export type IExampleStore = {
    ExampleValue: Fusion.Value<number>
}

local ExampleStore = {} :: IExampleStore
-- ...
```

Veja que **sempre** haverá uma definição de tipos no cabeçalho de qualquer Store. Sempre que um novo valor seja adicionado para esta Store operar, **você deve especificá-lo na declaração de tipos**.

> **💡 Dica:** Ao modificar a declaração de tipos da sua Store, a mudança é detectada pelo Plugin, que também reflete para as declarações do `UIScope` (mencionado nas [Docs do Plugin](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Plugin.md#tipagem-din%C3%A2mica))

### Exemplo de Store utilizado no Ocean Diving:

```lua
export type IPlayerStore = {
    Health: Fusion.Value<number>;
    MaxHealth: Fusion.Value<number>;

    Oxygen: Fusion.Value<number>;
    MaxOxygen: Fusion.Value<number>;

    IsWithinWater: Fusion.Value<boolean>;
}

local PlayerStore = {} :: IPlayerStore

function PlayerStore:Start(Scope: UIScope.Scope)
    self.Scope = Scope

    self.Health = Scope:AttributeValue('Health')
    self.MaxHealth = Scope:AttributeValue('MaxHealth')

    self.Oxygen = Scope:AttributeValue('Oxygen')
    self.MaxOxygen = Scope:AttributeValue('MaxOxygen')

    self.IsWithinWater = Scope:AttributeValue('IsWithinWater', false)
end

return PlayerStore
```

## Utilizando uma Store na Prática

Todas as Stores são gerenciadas pelo [Client Core](https://github.com/Layre-Org/layre-organization/blob/main/Template/ReplicatedStorage/Packages/Client/Core/Main.lua) e inicializadas automaticamente pelo método `Store:Start()`.

Mais tarde, quando quiser acessar uma Store, basta acessar o `Scope.Stores` ou dar `require()` utilizando o [Plugin](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Plugin.md), segue o exemplo de um UIController:

```lua
local UIController = {}

function UIController:Start(Scope: UIScope.Scope)
    local HealthLabel = Scope.Paths.UI.HealthLabel

    local PlayerStore = Scope.Stores.UI
    PlayerStore:SetHealth(2)

    Scope:StatLabel() {
        Label = HealthLabel;
        Value = PlayerStore.Health;
        MaxValue = PlayerStore.MaxHealth;
        Suffix = 'HP';
    }
end
```
