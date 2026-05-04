# Scope

Um **Scope** é a tabela central da UI do framework. Ele expõe todos os construtores reativos do Fusion, os helpers customizados, os Stores e os componentes registrados — tudo acessível a partir de um único objeto compartilhado.

> Para entender o funcionamento interno do Scope (ciclo de vida, cleanup, rastreamento de objetos), consulte a [documentação oficial do Fusion 0.3](https://elttob.uk/Fusion/0.3/).

---

## Instância única

Existe **um único Scope** para todo o jogo. Ele é criado uma vez e passado como parâmetro para Controllers, UIControllers e Stores. Nunca é destruído.

---

## O que o Scope expõe

| Categoria                | Acesso                                  | Descrição                                   |
| ------------------------ | --------------------------------------- | ------------------------------------------- |
| Construtores Fusion      | `Scope:Value()`, `Scope:Spring()`, etc. | Ver documentação do Fusion                  |
| `Paths`                  | `Scope.Paths`                           | Rotas de navegação da UI                    |
| `Stores`                 | `Scope.Stores.NomeDoStore`              | Estado global da UI                         |
| `AttributeValue`         | `Scope:AttributeValue()`                | Reativo a atributos do LocalPlayer          |
| `InstanceAttributeValue` | `Scope:InstanceAttributeValue()`        | Reativo a atributos de qualquer Instance    |
| Componentes              | `Scope:NomeDoComponente()`              | Um por ModuleScript em `UIComponentsFolder` |

---

## Helpers customizados

### `AttributeValue(Attribute, Fallback)`

Cria um `Value` reativo vinculado a um atributo do `LocalPlayer`. Atualiza automaticamente quando o atributo muda.

```lua
local Moedas = Scope:AttributeValue("Coins", 0)
```

### `InstanceAttributeValue(Instance, Attribute, Fallback)`

Mesma lógica, mas vinculado a qualquer `Instance` específica.

```lua
local Vida = Scope:InstanceAttributeValue(Personagem, "Health", 100)
```

---

## Paths

`Scope.Paths` é um navegador lazy para instâncias dentro do `PlayerGui`. O caminho é construído encadeando índices e só é resolvido no momento em que você o chama.

### Resolução síncrona

Retorna a instância imediatamente se ela já existir, ou `nil` se não for encontrada.

```lua
local Frame = Scope.Paths.ScreenGui.MainMenu.Frame()
```

Cada segmento do caminho é um índice. O `()` no final dispara a busca e retorna a instância.

### Resolução assíncrona (await)

Aguarda a instância existir antes de retornar. Útil quando a UI ainda pode não ter sido carregada.

```lua
local Frame = Scope.Paths.ScreenGui.MainMenu.Frame.await()
```

`await` bloquia a thread atual até a instância aparecer (timeout de 20 segundos) e retorna a instância resolvida.

### Observações

- O caminho é relativo ao `PlayerGui` — não inclua `PlayerGui` no índice.
- Chamar `Paths` sem `()` não resolve nada; o proxy apenas acumula o caminho.
- Se a instância não for encontrada na resolução síncrona, `()` retorna `nil` e um `warn` é emitido no output.

---

## Chamando componentes

```lua
Scope:NomeDoComponente() {
    Propriedade = Valor,
    OutraPropriedade = Scope:Value(0),
}
```

Os componentes herdam o Scope de quem os chama — não é necessário passá-lo manualmente.

---

## Acessando Stores

```lua
Scope.Stores.ShopStore.IsOpen:set(true)
```
