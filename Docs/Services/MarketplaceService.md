# MarketplaceService

**O serviço de monetização do servidor**, responsável por gerenciar gamepasses e developer products. Ele integra com o `MarketplaceService` nativo do Roblox e com o `DataService` para garantir que compras de produtos sejam processadas **exatamente uma vez**, mesmo em caso de falhas de rede ou servidor.

> **⚠️ Atenção:** O MarketplaceService é **exclusivo do servidor**. Toda lógica de compra, validação e concessão de itens acontece aqui — nunca no cliente.

---

## Índice

- [Gamepasses](#gamepasses)
  - [HasGamepass](#hasgamepass)
  - [GamepassHook](#gamepasshook)
- [Developer Products](#developer-products)
  - [ProductHook](#producthook)
- [Mock](#mock)
- [Constantes relacionadas](#constantes-relacionadas)

---

## Gamepasses

Ao entrar no jogo, o MarketplaceService verifica automaticamente quais gamepasses o player possui e cria uma `Folder` chamada `Gamepass` dentro do player. Cada gamepass possuído é marcado como um atributo nessa pasta.

```
Player
└── Gamepass (Folder)
    ├── VipPass = true
    └── DoubleCoins = true
```

O nome do atributo é definido por `AttributeName` nas constantes — se não definido, usa o nome da chave em `Constants.Gamepasses`.

Para executar lógica customizada quando um player possui ou compra um gamepass, use `GamepassHook`.

### HasGamepass

Retorna `true` se o player possuir a gamepass com o id especificado

```lua
MarketplaceService:HasGamepass(Client: Player, PassId: number): boolean
```

```lua
local has = MarketplaceService:HasGamepass(Player, Constants.Gamepasses.VipPass.Id)
print(has) -- true / false
```

### GamepassHook

Registra uma função que será executada quando o player **entrar no jogo com o gamepass** ou **comprar o gamepass durante a sessão**.

```lua
MarketplaceService:GamepassHook(PassId: number, Action: (Player) -> ()): { Disconnect: () -> () }
```

```lua
MarketplaceService:GamepassHook(Constants.Gamepasses.VipPass.Id, function(player)
    -- concede benefícios do VIP
    DataService:Update(player, "XpMultiplier", function(current)
        return current * 2
    end)
end)
```

O retorno é um objeto com um método `Disconnect` para remover o hook:

```lua
local hook = MarketplaceService:GamepassHook(passId, action)

-- Para remover:
hook:Disconnect()
```

> **⚠️ Atenção:** Registrar dois hooks para o mesmo `PassId` causa um erro. Faça `Disconnect` no hook anterior antes de registrar um novo.

> **⚠️ Atenção:** O `PassId` deve estar definido em `Constants.Gamepasses`. IDs não registrados nas constantes causam um erro.

---

## Developer Products

Diferente dos gamepasses, developer products podem ser comprados múltiplas vezes. O MarketplaceService garante que cada compra seja processada **exatamente uma vez** através de um cache de `PurchaseId` salvo no perfil do player.

O fluxo interno funciona assim:

1. Roblox chama `ProcessReceipt` após uma compra.
2. O serviço verifica se o `PurchaseId` já foi processado no cache do perfil.
3. Se não foi, executa o hook registrado para aquele `ProductId`.
4. Força um save do perfil e aguarda a confirmação antes de retornar `PurchaseGranted`.

> **💡 Dica:** O cache de `PurchaseId` mantém os últimos **300** IDs. Compras mais antigas que esse limite podem ser reprocessadas — projete suas actions para serem idempotentes quando possível.

### ProductHook

Registra uma função que será executada quando um developer product for comprado com sucesso.

```lua
MarketplaceService:ProductHook(ProductId: number, Action: (Player) -> ()): { Disconnect: () -> () }
```

```lua
MarketplaceService:ProductHook(Constants.Products.Cash100.Id, function(player)
    StatsService:AddCurrency(player, 'Cash', 100)
end)
```

Assim como o `GamepassHook`, retorna um objeto com `Disconnect`:

```lua
local hook = MarketplaceService:ProductHook(productId, action)

hook:Disconnect()
```

> **⚠️ Atenção:** Se um `ProductId` receber uma compra sem ter um hook registrado, a compra **não é processada** e retorna `NotProcessedYet` — o Roblox tentará novamente depois. Um aviso é emitido no output nesse caso.

> **⚠️ Atenção:** O `ProductId` deve estar definido em `Constants.Products`. IDs não registrados causam um erro.

---

## Mock

Quando `Constants.Server.MOCK_GAMEPASSES` está habilitado, todos os gamepasses são concedidos automaticamente a todos os players sem verificar o Roblox — útil para testar benefícios de gamepass em Studio.

É possível excluir um gamepass específico do mock definindo `Mock = false` nas constantes:

```lua
-- Constants.luau
Gamepasses = {
    VipPass = { Id = 123, AttributeName = "VipPass" },
    SpecialPass = { Id = 456, Mock = false }, -- nunca é mockado
}
```

Um aviso é exibido no output para cada gamepass mockado:

```
[MARKETPLACE SERVICE] Mocking Gamepass VipPass for Player
```

> **💡 Dica:** Developer products não têm mock automático — teste-os diretamente pelo Studio usando os Atributos na folder marketplace no Player, transformá-los em true te dão o prompt para comprar sem necessidade de preparar código.

---

## Constantes relacionadas

As constantes do MarketplaceService são configuradas em `Constants`:

| Constante | Tipo | Descrição |
|---|---|---|
| `Constants.Gamepasses` | `{ [string]: { Id: number, AttributeName: string?, Mock: boolean? } }` | Gamepasses registrados no jogo |
| `Constants.Products` | `{ [string]: { Id: number } }` | Developer products registrados no jogo |
| `Constants.Server.MOCK_GAMEPASSES` | `boolean` | Concede todos os gamepasses automaticamente em Studio |