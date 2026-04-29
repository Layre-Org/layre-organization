# Flux

**O módulo de networking do projeto**, baseado no [ByteNet](https://github.com/ffrostfall/ByteNet). Flux gerencia toda a comunicação entre servidor e cliente de forma tipada, validada e otimizada através de buffers binários.

> **💡 Dica:** Flux utiliza `RemoteEvent`, `UnreliableRemoteEvent` e `RemoteFunction` internamente. Você nunca deve interagir com esses remotes diretamente — use sempre a API do Flux.

---

## Índice

- [Namespaces](#namespaces)
- [Packets](#packets)
  - [Reliable](#reliable)
  - [Unreliable](#unreliable)
  - [Function](#function)
- [Settings](#settings)
- [Tipos de dados](#tipos-de-dados)

---

## Namespaces

Namespaces são os **agrupadores de packets**. Todo packet deve pertencer a um namespace, e as configurações definidas no namespace são herdadas por todos os packets dentro dele.

```lua
return Flux.defineNamespace("Combat", function()
    return {
        DealDamage = Flux.definePacket({
            value = Flux.string
        });
        RequestSkill = Flux.defineFunction({
            request = Flux.nothing,
            response = Flux.string
        }, {
            timeout = 2,
        });
    }
end, {
    rateLimit = {
            window = 1,
            maxBytes = 1024,
            maxPackets = 20,
        },
    timeout = 5,
})
```

> **💡 Dica:** As `settings` do namespace servem como padrão para todos os packets dentro dele. Um packet pode sobrescrever qualquer campo individualmente.

---

## Packets

Packets são as **unidades de comunicação** do Flux. Existem três tipos, cada um com um comportamento diferente de envio e recebimento.

### Reliable

Enviado via `RemoteEvent`. Os dados chegam **garantidamente e em ordem**. Use para ações críticas que não podem ser perdidas.

```lua
DealDamage = Flux.definePacket({
    value = Flux.struct({
        target = Flux.string,
        amount = Flux.uint16,
    }, {
        rateLimit = { maxPackets = 10, window = 1 }
    }),
})
```

**Servidor → Cliente:**
```lua
-- Para um player específico
Combat.DealDamage.sendTo(player, { target = "Enemy", amount = 50 })

-- Para todos os players
Combat.DealDamage.sendToAll({ target = "Enemy", amount = 50 })

-- Para uma lista de players
Combat.DealDamage.sendToList(players, { target = "Enemy", amount = 50 })

-- Para uma lista de players exceto uma lista em específico
Combat.DealDamage.sendToAllExcept(exception, { target = "Enemy", amount = 50 }) -- exception também aceita um array de players
```

**Cliente → Servidor:**
```lua
Combat.DealDamage.send({ target = "Enemy", amount = 50 })
```

**Ouvindo no lado oposto:**
```lua
local disconnect = Combat.DealDamage.listen(function(data, player)
    -- player só existe no servidor
    print(data.target, data.amount)
end)

-- Para desconectar:
disconnect()
```

---

### Unreliable

Enviado via `UnreliableRemoteEvent`. Os dados podem ser **perdidos ou chegar fora de ordem**. Use para dados de alta frequência onde perder um frame não importa, como posição ou rotação.

```lua
SyncPosition = Flux.definePacket({
    value = Flux.struct({
        x = Flux.float32,
        y = Flux.float32,
        z = Flux.float32,
    }),
    reliabilityType = 'unreliable'
})
```

A API de envio e escuta é **idêntica ao Reliable**.

> **⚠️ Atenção:** Nunca use unreliable para dados críticos como dano, compras ou eventos de gameplay que precisam ser processados exatamente uma vez.

---

### Function

Enviado via `RemoteFunction`. Permite uma **comunicação bidirecional com resposta**, onde quem invoca aguarda o retorno do outro lado. Retorna uma `Promise`.

```lua
RequestSkill = Flux.defineFunction({
    request = Flux.struct({
        skillId = Flux.uint8,
    }),
    response = Flux.struct({
        granted = Flux.bool,
        cooldown = Flux.float32,
    }),
}, {
    timeout = 10,
})
```

**Invocando do Servidor → Cliente:**
```lua
Combat.RequestSkill.invoke(player, { skillId = 3 })
    :andThen(function(response)
        print(response.granted, response.cooldown)
    end)
    :catch(function(err)
        warn("Timeout ou erro:", err)
    end)
```

**Invocando do Cliente → Servidor:**
```lua
Combat.RequestSkill.invoke({ skillId = 3 })
    :andThen(function(response)
        print(response.granted)
    end)
```

**Respondendo (lado oposto):**
```lua
local disconnect = Combat.RequestSkill.listen(function(data, player)
    -- retorne os dados da response
    return {
        granted = true,
        cooldown = 2.5,
    }
end)
```

> **💡 Dica:** O `timeout` do Function pode ser configurado por packet via settings (campo `timeout`). O valor padrão é `3` segundos. Após o timeout, a Promise é rejeitada automaticamente com `"Timeout limit exceeded"`.

---

## Settings

As settings podem ser definidas no **namespace** (aplicadas a todos os packets) ou em cada **packet individualmente**. Quando definidas em ambos, o packet sobrescreve o namespace.

```lua
type Settings = {
    rateLimit = {
        window: number,      -- Janela de tempo em segundos - Default: 1
        maxBytes: number,    -- Máximo de bytes por janela
        maxPackets: number,  -- Máximo de packets por janela
    }?,
    timeout: number?,        -- Segundos antes do invoke rejeitar (Function apenas) - Default: 3
}
```

### Exemplo com herança de settings

```lua
local Combat = Flux.defineNamespace("Combat", {
    settings = {
        rateLimit = { window = 1, maxPackets = 20 }, -- padrão do namespace
    },
    packets = {
        DealDamage = Flux.reliable({
            value = ...,
        }, {
            rateLimit = { maxPackets = 5 } -- sobrescreve só o maxPackets nesse packet e recebe window = 1
        }),
        SyncPosition = Flux.unreliable({
            value = ...,
            -- herda o rateLimit do namespace (window = 1, maxPackets = 20)
        }),
    }
})
```

---

## Tipos de dados

O Flux expõe um conjunto de tipos primitivos para descrever o formato dos dados de cada packet. Todos os tipos são verificados em runtime antes do envio e após o recebimento.

| Tipo | Descrição |
|---|---|
| `Flux.uint(8\|16\|32)` | Inteiro sem sinal de N bits |
| `Flux.int(8\|16\|32)` | Inteiro com sinal de N bits |
| `Flux.float(32\|64)` | Número de ponto flutuante |
| `Flux.bool` | Booleano |
| `Flux.string` | String de tamanho dinâmico |
| `Flux.struct({ ... })` | Objeto com campos tipados |
| `Flux.array(type)` | Array de um tipo específico |
| `Flux.optional(type)` | Valor que pode ser `nil` |
| `Flux.inst` | Referência a uma `Instance` do Roblox |
| `Flux.union(type1, type2)` | Valor que pode ser do tipo `type1` ou `type2` |
| `Flux.nothing` | É obrigatóriamente `nil` |
| `Flux.unknown` | Usado quando não se sabe o valor que vem, porém perdendo a compressão em buffer |
| `Flux.vec(2\|3)` | Vetores de 2 ou 3 dimensões |
| `Flux.buff` | Objetos binários (buffers) |
| `Flux.cframe` | CFrames do roblox, que possuem `posição` e `orientação` |
| `Flux.map(key, value)` | Recebe um objeto com key do tipo `key` e value do tipo `value` |

> **⚠️ Atenção:** Tipos inválidos no envio causam um erro de validação e cancelam o envio. No recebimento, dados inválidos são descartados e um aviso é emitido no output.
