# OrderedDataService

**O serviço de rankings do servidor**, responsável por gerenciar `OrderedDataStore`s do Roblox. Usado para armazenar e consultar valores numéricos ordenados por player — ideal para **leaderboards, rankings de XP, kills, tempo de jogo** e qualquer dado que precise ser listado em ordem.

> **💡 Dica:** O OrderedDataService é **independente do DataService**. Ele usa `OrderedDataStore`s separados, então os dados aqui **não fazem parte do perfil do player** e não são salvos pelo ProfileStore.

---

## Índice

- [Stores](#stores)
- [Métodos](#métodos)
  - [GetTop](#gettop)
  - [GetPlayer](#getplayer)
  - [Set](#set)
  - [Add](#add)
  - [Remove](#remove)

---

## Stores

Cada store é identificado por um `StoreName` — uma string que mapeia para um `OrderedDataStore` no Roblox. Os stores são criados automaticamente na primeira vez que são usados e ficam em cache para evitar requisições repetidas.

Você pode ter quantos stores quiser, cada um representando um ranking diferente:

```lua
-- Rankings independentes
OrderedDataService:Set("Kills", player, 42)
OrderedDataService:Set("TimePlayed", player, 3600)
OrderedDataService:Set("WaveRecord", player, 15)
```

> **⚠️ Atenção:** Todos os valores são armazenados como **inteiros não-negativos**. Valores negativos são bloqueados por assert e valores decimais são arredondados com `math.floor`.

---

## Métodos

### GetTop

Retorna os **N melhores players** de um store, em ordem crescente ou decrescente.

```lua
OrderedDataService:GetTop(
    StoreName: string,
    Amount: number?,   -- padrão: 10, máximo: 100
    Ascending: boolean? -- padrão: false (maior → menor)
): { { key: string, value: number } }?
```

```lua
local top10 = OrderedDataService:GetTop("Kills", 10)

for position, entry in top10 do
    print(position, entry.key, entry.value)
    -- 1   "1234567"   150
    -- 2   "8901234"   98
end
```

O campo `key` retornado é o `UserId` do player como string. Para obter o nome, use `Players:GetNameFromUserIdAsync`.

```lua
local top = OrderedDataService:GetTop("Kills", 10)
for rank, entry in top do
    local name = Players:GetNameFromUserIdAsync(tonumber(entry.key))
    print(`#{rank} {name}: {entry.value}`)
end
```

Retorna `nil` em caso de falha — trate esse caso antes de iterar.

---

### GetPlayer

Retorna o valor atual de um player específico em um store.

```lua
OrderedDataService:GetPlayer(StoreName: string, Client: Player): number?
```

```lua
local kills = OrderedDataService:GetPlayer("Kills", player)
if kills then
    print(`{player.DisplayName} tem {kills} kills`)
end
```

Retorna `nil` se o player ainda não tiver um valor registrado ou em caso de falha.

---

### Set

Define o valor de um player diretamente. Útil para sincronizar o ranking com dados do perfil ao entrar no jogo.

```lua
OrderedDataService:Set(StoreName: string, Client: Player, Value: number): void
```

```lua
-- Sincroniza o ranking com o dado do perfil ao entrar
local kills = DataService:Get(player, "Kills")
OrderedDataService:Set("Kills", player, kills)
```

> **⚠️ Atenção:** O valor deve ser um número **não-negativo**. Passar um valor negativo ou não-numérico causa um erro imediato.

---

### Add

Incrementa (ou decrementa) o valor de um player atomicamente. Retorna o novo valor.

```lua
OrderedDataService:Add(StoreName: string, Client: Player, Delta: number): number?
```

```lua
-- Adiciona 1 kill
local newKills = OrderedDataService:Add("Kills", player, 1)

-- Remove 5 pontos (nunca vai abaixo de 0)
OrderedDataService:Add("Points", player, -5)
```

> **💡 Dica:** Prefira `Add` ao invés de `GetPlayer` + `Set` para evitar race conditions. A operação é atômica via `UpdateAsync`.

> **💡 Dica:** O valor nunca fica negativo — o mínimo é sempre `0`, independente do delta passado.

Retorna `nil` em caso de falha.

---

### Remove

Remove completamente o registro de um player em um store. Útil para limpar dados ao banir ou resetar um player.

```lua
OrderedDataService:Remove(StoreName: string, Client: Player): void
```

```lua
OrderedDataService:Remove("Kills", player)
```

> **⚠️ Atenção:** Após `Remove`, `GetPlayer` retornará `nil` para esse player até que um novo valor seja definido com `Set` ou `Add`.