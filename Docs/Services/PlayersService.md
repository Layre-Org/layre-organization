# PlayersService

**O serviço de gerenciamento de players**, responsável pelo sistema de saúde customizado e pelo rastreamento de amigos online. Centraliza toda a lógica relacionada ao estado do player em jogo.

> **💡 Dica:** O sistema de saúde e o sistema de amigos são **opcionais e independentes**. O sistema de saúde só funciona se `Constants.Server.CUSTOM_HEALTH_SYSTEM` estiver habilitado — chamadas aos métodos de saúde com ele desabilitado causam um erro imediato.

---

## Índice

- [Sistema de Saúde](#sistema-de-saúde)
  - [Como funciona](#como-funciona)
  - [TakeDamage](#takedamage)
  - [GetHealth](#gethealth)
  - [GetMaxHealth](#getmaxhealth)
  - [SetHealth](#sethealth)
  - [SetMaxHealth](#setmaxhealth)
- [Sistema de Amigos](#sistema-de-amigos)
  - [GetOnlineFriends](#getonlinefriends)
  - [FriendsChanged](#friendschanged)
- [Constantes relacionadas](#constantes-relacionadas)

---

## Sistema de Saúde

Quando `CUSTOM_HEALTH_SYSTEM` está habilitado, o PlayersService assume o controle da saúde do player ao invés do `Humanoid` padrão do Roblox. A saúde é armazenada como **atributos no Player** e sincronizada bidirecionalmente com o `Humanoid.Health`.

### Como funciona

Ao entrar no jogo, o player recebe os atributos de saúde com o valor de `MAX_HEALTH`:

```
Player
├── Attribute: Health = 100
└── Attribute: MaxHealth = 100
```

Ao spawnar o character, o serviço cria listeners que mantêm `Humanoid.Health` e o atributo `Health` sempre sincronizados. Isso significa que você pode alterar a saúde por qualquer lado — atributo ou Humanoid — e o outro será atualizado automaticamente.

> **💡 Dica:** Prefira sempre usar os métodos do PlayersService para alterar saúde. Alterar `Humanoid.Health` diretamente funciona, mas usar os métodos garante validação, clamp automático e consistência com o `MaxHealth`.

> **⚠️ Atenção:** Os listeners de sincronização são destruídos automaticamente quando o character morre ou é removido. Eles são recriados a cada respawn via `OnCharacterAdded`.

---

### TakeDamage

Aplica dano a um player. Aceita tanto um `Player` quanto um `Humanoid` como alvo.

```lua
PlayersService:TakeDamage(Target: Player | Humanoid, DamageAmount: number): number
```

Retorna a nova saúde do player após o dano.

```lua
-- Por Player
local newHealth = PlayersService:TakeDamage(player, 25)

-- Por Humanoid (útil dentro de scripts de arma/hitbox)
local newHealth = PlayersService:TakeDamage(humanoid, 25)
```

> **⚠️ Atenção:** `DamageAmount` deve ser um número **não-negativo**. Para curar, use `SetHealth`. Passar um Humanoid que não pertença a nenhum player causa um erro.

---

### GetHealth

Retorna a saúde atual do player.

```lua
PlayersService:GetHealth(Client: Player): number
```

```lua
local health = PlayersService:GetHealth(player)
print(`{player.DisplayName} tem {health} de vida`)
```

---

### GetMaxHealth

Retorna a saúde máxima atual do player.

```lua
PlayersService:GetMaxHealth(Client: Player): number
```

```lua
local maxHealth = PlayersService:GetMaxHealth(player)
```

---

### SetHealth

Define a saúde do player para um valor específico. O valor é automaticamente **limitado ao MaxHealth atual** — nunca ultrapassa o máximo.

```lua
PlayersService:SetHealth(Client: Player, HealthAmount: number): void
```

```lua
-- Cura o player para 80 de vida
PlayersService:SetHealth(player, 80)

-- Cura total
PlayersService:SetHealth(player, PlayersService:GetMaxHealth(player))
```

> **⚠️ Atenção:** `HealthAmount` deve ser não-negativo. Passar um valor acima do `MaxHealth` não causa erro — é silenciosamente limitado ao máximo.

---

### SetMaxHealth

Define a saúde máxima do player. Se a saúde atual for maior que o novo máximo, ela é reduzida automaticamente para o novo valor.

```lua
PlayersService:SetMaxHealth(Client: Player, HealthAmount: number): void
```

```lua
-- Aumenta o MaxHealth (ex: upgrade de vida)
PlayersService:SetMaxHealth(player, 150)

-- Reduz o MaxHealth — a saúde atual é reduzida junto se necessário
PlayersService:SetMaxHealth(player, 50)
```

---

## Sistema de Amigos

O PlayersService rastreia automaticamente quais amigos do player estão online no mesmo servidor, atualizando a lista em tempo real conforme players entram e saem.

### GetOnlineFriends

Retorna a lista de amigos online do player no servidor atual.

```lua
PlayersService:GetOnlineFriends(Client: Player): { Player }
```

```lua
local friends = PlayersService:GetOnlineFriends(player)
for _, friend in friends do
    print(friend.DisplayName, "está online")
end
```

---

### FriendsChanged

Sinal disparado quando a lista de amigos online de qualquer player muda — ou seja, quando um amigo entra ou sai do servidor.

```lua
PlayersService.FriendsChanged: Signal
```

```lua
PlayersService.FriendsChanged:Connect(function(player: Player, friends: { Player })
    -- player = o player cuja lista de amigos mudou
    -- friends = nova lista de amigos online
    print(`Lista de amigos de {player.DisplayName} atualizada:`, #friends)
end)
```

> **💡 Dica:** Use `FriendsChanged` para atualizar UIs de amigos em tempo real ao invés de fazer polling com `GetOnlineFriends`.

---

## Constantes relacionadas

As constantes do PlayersService são configuradas em `Constants.Server`:

| Constante | Tipo | Descrição |
|---|---|---|
| `CUSTOM_HEALTH_SYSTEM` | `boolean` | Habilita o sistema de saúde customizado |
| `HEALTH_ATTR` | `string` | Nome do atributo de saúde no Player |
| `MAX_HEALTH_ATTR` | `string` | Nome do atributo de saúde máxima no Player |
| `MAX_HEALTH` | `number` | Valor inicial de saúde máxima ao entrar no jogo |