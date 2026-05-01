# DataService

**O serviço de dados do servidor**, responsável por carregar, salvar e manipular os dados de cada player usando [ProfileStore](https://github.com/MadStudioRoblox/ProfileStore). Todos os dados são persistidos automaticamente — você nunca precisa salvar manualmente.

> **⚠️ Atenção:** O DataService é **exclusivo do servidor**. Nunca acesse ou exija dados diretamente no cliente — crie um packet no Flux para expor apenas o necessário.

---

## Índice

- [Perfis](#perfis)
- [Métodos](#métodos)
  - [GetProfile](#getprofile)
  - [Get](#get)
  - [Set](#set)
  - [Update](#update)
  - [Wipe](#wipe)
- [Mock](#mock)
- [Constantes relacionadas](#constantes-relacionadas)

---

## Perfis

O DataService mantém uma tabela pública `DataService.Profiles` que mapeia cada `Player` ao seu perfil ativo. O perfil é carregado automaticamente no `OnPlayerAdded` e encerrado no `OnPlayerRemoving`.

```lua
-- Estrutura interna (não acesse diretamente)
DataService.Profiles = {} :: { [Player]: IProfile }
```

> **💡 Dica:** Prefira sempre usar os métodos `Get`, `Set` e `Update` ao invés de acessar `Profiles` diretamente. Eles incluem a espera pelo carregamento do perfil automaticamente.

---

## Métodos

### GetProfile

Retorna o perfil de um player. Se o perfil ainda não foi carregado, **aguarda até ele estar disponível** ou até o timeout definido em `Constants.Server.PROFILE_TIMEOUT`.

```lua
DataService:GetProfile(Client: Player): IProfile?
```

```lua
local profile = DataService:GetProfile(player)
if profile then
    print(profile.Data)
end
```

> **💡 Dica:** Você raramente precisará chamar `GetProfile` diretamente. Os métodos `Get`, `Set`, `Update` e `Wipe` já o chamam internamente.

---

### Get

Retorna o valor de um campo específico dos dados do player.

```lua
DataService:Get(Client: Player, Key: string): any?
```

```lua
local cash = DataService:Get(player, "Cash")
print(cash) --> 100
```

---

### Set

Define o valor de um campo e retorna o novo valor.

```lua
DataService:Set(Client: Player, Key: string, Value: any): any?
```

```lua
DataService:Set(player, "Cash", 500)
```

---

### Update

Atualiza um campo com base no valor atual através de um callback. Retorna o novo valor.

```lua
DataService:Update(Client: Player, Key: string, Callback: (any) -> any): any?
```

```lua
-- Adiciona 50 moedas ao valor atual
DataService:Update(player, "Cash", function(current)
    return current + 50
end)
```

> **💡 Dica:** Prefira `Update` ao invés de `Get` + `Set` para evitar race conditions em operações que dependem do valor atual.

---

### Wipe

Reseta campos dos dados do player para os valores padrão definidos no `Template`. Se nenhum campo for passado, **reseta todos os dados**.

```lua
DataService:Wipe(Client: Player, Fields: (string | { string })?): void
```

```lua
-- Reseta um campo específico
DataService:Wipe(player, "Cash")

-- Reseta múltiplos campos
DataService:Wipe(player, { "Cash", "Inventory" })

-- Reseta tudo
DataService:Wipe(player)
```

> **⚠️ Atenção:** `Wipe` sem argumentos reseta **todos os dados do player** para o Template padrão. Use com cuidado.

---

## Mock

Quando `Constants.Server.USE_MOCK` está habilitado, o DataService utiliza um DataStore simulado em memória — os dados **não são salvos** no Roblox. Isso é útil para testes em Studio.

Além disso, os campos definidos no módulo `Mock` são injetados nos dados do player logo após o carregamento:

```lua
-- Core/Template/Mock.luau
return {
    Cash = 9999,
    Level = 50,
}
```

Um aviso é exibido no output sempre que o Mock está ativo:

```
[DATA SERVICE] - Mock DataStore Enabled
```

---

## Constantes relacionadas

As constantes do DataService são configuradas em `Constants.Server`:

| Constante | Tipo | Descrição |
|---|---|---|
| `STORE_NAME` | `string` | Nome do DataStore usado pelo ProfileStore |
| `USE_MOCK` | `boolean` | Ativa o DataStore simulado em memória |
| `PROFILE_TIMEOUT` | `number` | Segundos máximos de espera pelo perfil em `GetProfile` |
| `LOG_ON_DATA_LOAD` | `boolean` | Printa os dados carregados do player no output |