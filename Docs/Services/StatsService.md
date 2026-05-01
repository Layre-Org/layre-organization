# StatsService

**O serviço de atributos e moedas do servidor**, responsável por ler, modificar e salvar os stats de cada player. Ele opera em cima de **atributos do Roblox** — os dados ficam acessíveis no cliente em tempo real sem precisar de remotes — e se integra com o `DataService` para persistência.

> **💡 Dica:** Todo método de escrita do StatsService retorna um objeto com `.save()` e `.get()`. O atributo é atualizado **imediatamente**, mas os dados **só são persistidos quando `.save()` é chamado**. Isso é intencional — permite aplicar múltiplas operações antes de salvar.

---

## Índice

- [Como funciona](#como-funciona)
- [Moedas](#moedas)
  - [AddCurrency](#addcurrency)
  - [SetCurrency](#setcurrency)
  - [GetCurrency](#getcurrency)
  - [HasEnoughCurrency](#hasenoughcurrency)
- [Atributos](#atributos)
  - [Add](#add)
  - [Set](#set)
  - [Get](#get)
  - [Wipe](#wipe)
- [Modifiers](#modifiers)
  - [AddModifier](#addmodifier)
  - [RemoveModifier](#removemodifier)
  - [GetModifiers](#getmodifiers)
  - [ignoreModifiers](#ignoremodifiers)
- [Infinite Currency](#infinite-currency)
- [Constantes relacionadas](#constantes-relacionadas)

---

## Como funciona

Ao entrar no jogo, o StatsService carrega o perfil do player via `DataService` e mapeia cada campo definido pelo module **Attributes** no **Server Core** (Também é possível registrar uma **leaderstat** para um atributo que atualiza automaticamente quando o atributo muda a partir do leaderstats builder). Isso significa que o cliente pode ler qualquer stat diretamente via `player:GetAttribute("Cash")` sem precisar de um remote.

Modificar um atributo via StatsService não salva automaticamente — você controla quando persistir:

```lua
-- Atualiza o atributo imediatamente, salva depois
StatsService:Add(player, "Kills", 1).save()

-- Atualiza sem salvar (útil para stats temporários como vida)
StatsService:Set(player, "Health", 80)
```

---

## Moedas

Os métodos de moeda são um wrapper sobre os métodos de atributo com validações extras: moedas **nunca ficam negativas** e são **salvas automaticamente** a cada operação.

> **💡 Dica:** Prefira sempre os métodos de moeda ao invés de `Add`/`Set` direto para currencies — eles garantem que o valor nunca fique abaixo de zero e fazem o save automaticamente.

### AddCurrency

Adiciona (ou subtrai) uma quantidade de moeda ao player. O valor nunca fica abaixo de zero.

```lua
StatsService:AddCurrency(Client: Player, Currency: Types.Currency, Amount: number): { get: () -> number }
```

```lua
-- Adiciona 100 moedas
StatsService:AddCurrency(player, "Cash", 100)

-- Subtrai 50 moedas (nunca fica negativo)
local result = StatsService:AddCurrency(player, "Cash", -50)
print(result.get()) --> valor atual após operação
```

---

### SetCurrency

Define a moeda do player para um valor específico. Valores negativos são automaticamente convertidos para `0`.

```lua
StatsService:SetCurrency(Client: Player, Currency: Types.Currency, Amount: number): { get: () -> number }
```

```lua
StatsService:SetCurrency(player, "Cash", 500)
```

---

### GetCurrency

Retorna o valor atual de uma moeda.

```lua
StatsService:GetCurrency(Client: Player, Currency: Types.Currency): number
```

```lua
local cash = StatsService:GetCurrency(player, "Cash")
```

---

### HasEnoughCurrency

Verifica se o player tem pelo menos uma certa quantidade de moeda.

```lua
StatsService:HasEnoughCurrency(Client: Player, Currency: Types.Currency, Value: number): boolean
```

```lua
if StatsService:HasEnoughCurrency(player, "Cash", 100) then
    StatsService:AddCurrency(player, "Cash", -100)
    -- concede item
end
```

---

## Atributos

Métodos genéricos para qualquer atributo — não apenas moedas.

### Add

Incrementa um atributo pelo valor informado. Modifiers registrados para esse atributo são aplicados automaticamente sobre o `Amount` antes da operação.

```lua
StatsService:Add(Client: Player, Attribute: string, Amount: T): { save: () -> (), get: () -> any, ignoreModifiers: (...string) -> self }
```

```lua
-- Adiciona 1 kill e salva
StatsService:Add(player, "Kills", 1).save()

-- Adiciona XP sem aplicar o modifier "VipBonus"
StatsService:Add(player, "XP", 100)
    .ignoreModifiers("VipBonus")
    .save()
```

> **💡 Dica:** O atributo é atualizado via `task.defer` — ou seja, a mudança acontece no próximo frame. O `.save()` persiste o valor calculado com os modifiers aplicados.

---

### Set

Define um atributo para um valor exato.

```lua
StatsService:Set(Client: Player, Attribute: string, Value: any): { save: () -> (), get: () -> any }
```

```lua
-- Define e salva no Profile
StatsService:Set(player, "Level", 10).save()

-- Define sem salvar
StatsService:Set(player, "IsInCombat", true)
```

---

### Get

Retorna o valor atual de um atributo.

```lua
StatsService:Get(Client: Player, Attribute: string): any
```

```lua
local level = StatsService:Get(player, "Level")
```

---

### Wipe

Reseta um ou mais atributos para os valores padrão do `Template`. Retorna um objeto com `.save()` para persistir o reset.

```lua
StatsService:Wipe(Client: Player, Fields: string | { string }): { save: () -> () }
```

```lua
-- Reseta um campo
StatsService:Wipe(player, "Kills").save()

-- Reseta múltiplos campos
StatsService:Wipe(player, { "Kills", "Deaths" }).save()
```

---

## Modifiers

Modifiers são **funções de transformação** aplicadas automaticamente sobre o `Amount` em chamadas de `Add`. Servem para implementar multiplicadores de XP, bônus de VIP, buffs temporários e similares de forma desacoplada.

### AddModifier

Registra um modifier para um atributo específico.

```lua
StatsService:AddModifier(Name: string, Attribute: string, Modifier: (player: Player, value: any) -> any): void
```

```lua
-- Dobra o XP ganho
StatsService:AddModifier("VipBonus", "XP", function(Client, amount)
    return amount * 2
end)

-- Adiciona 10% de moedas extras
StatsService:AddModifier("EventBonus", "Cash", function(Client, amount)
    return amount * 1.1
end)
```

Múltiplos modifiers podem ser registrados para o mesmo atributo — todos são aplicados em sequência na ordem de registro.

### RemoveModifier

Remove um modifier de um atributo específico.

```lua
StatsService:RemoveModifier(Name: string, Attribute: string): void
```

```lua
StatsService:RemoveModifier("VipBonus", "XP")

StatsService:RemoveModifier("EventBonus", "Cash")
```

---

### GetModifiers

Retorna um array com objetos que possuem nome e função de execução dos modifiers

```lua
StatsService:GetModifiers(Attribute: string): {{Name: string, Execute: () -> ()}}
```

```lua
local modifiers = StatsService:GetModifiers("XP")
```

---

### ignoreModifiers

Disponível no objeto retornado por `Add`. Permite excluir modifiers específicos da operação atual pelo nome.

```lua
object.ignoreModifiers(...modifierNames: string): self
```

```lua
-- Ignora todos os modifiers
StatsService:Add(player, "XP", 100)
    .ignoreModifiers()
    .save()

-- Aplica todos os modifiers exceto o "VipBonus"
StatsService:Add(player, "XP", 100)
    .ignoreModifiers("VipBonus")
    .save()

-- Ignora múltiplos modifiers
StatsService:Add(player, "XP", 100)
    .ignoreModifiers("VipBonus", "EventBonus")
    .save()
```

---

## Infinite Currency

Quando `Constants.Server.INFINITE_CURRENCY` está habilitado, todos os campos listados em `Constants.Server.CURRENCY_LIST` são definidos como `math.huge` ao carregar o player. Operações de `SetCurrency` também ignoram o valor passado e sempre definem `math.huge`.

Um aviso é exibido no output quando ativo:

```
[STATS SERVICE] - Infinite Currency Enabled
```

---

## Constantes relacionadas

| Constante | Tipo | Descrição |
|---|---|---|
| `Constants.Server.INFINITE_CURRENCY` | `boolean` | Habilita moeda infinita para testes |
| `Constants.Server.CURRENCY_LIST` | `{ string }` | Lista de atributos tratados como moeda |