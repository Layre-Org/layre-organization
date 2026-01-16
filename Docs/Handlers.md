# Handlers

Um módulo de funções úteis, principalmente utilizado para centralizar **Funções Utilitárias** e reduzir o tamanho de um [Manager](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Managers.md) ou [Controller](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Controllers.md).

Caso as funções precisem ser utilizadas em mais partes de um mesmo sistema, é possível colocar este `Handler` em uma pasta denominada `/Handlers`, no mesmo nível de hierarquia que outras pastas do sistema.

**Exemplo:**

```lua
local TestHandler = {}

function TestHandler.DoSomething(param)
  print('faz algo mano')
  return string.sub(param, 2) -- É só um exemplo, não é obrigatório isso aqui
end

return TestHandler
```
