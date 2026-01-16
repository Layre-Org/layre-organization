# Classes

Utilizadas para funcionalidades que precisam de um gerenciamento melhor de instâncias, com **funções exclusivas que gerenciam propriedades exclusivas**.

> **💡 Dica:** Os exemplos abaixo utilizam Herança com a lib `Super`, é necessário compreender sobre OOP e conceitos relacionados.

## Sintaxe Base para as Classes

Sofremos com algumas questões de Auto-complete ao utilizar `Metatable` no Roblox, por isso, utilizamos a seguinte técnica para contornar isso:

```lua
--@@ ++4 @@
local ExampleClass = {}
ExampleClass.__index = ExampleClass

export type IClass = typeof(setmetatable({} :: {}, ExampleClass))
```

Este `export type` consegue aplicar todos os `:Methods()` da Classe e auxilia na tipagem de códigos externos que acessam a Classe.

> **💡 Dica:** O Plugin \*ainda não atualiza automaticamente as propriedades da Classe em `export type`, por isso, sempre verifique manualmente.

## Herança com a lib Super

Na pasta `Packages/Shared/Utility` em `ReplicatedStorage` é possível encontrar um Module denominado `Super`, ele quem torna possível a herança no LuaU. Para que funcione corretamente, ela deve ser chamada na definição do self na classe filha, do seguinte modo:

```lua
local self = Super(ClassePai, ClasseFilha)
```

Caso queira inicializar os valores da **classe pai** _(se ela receber um nome durante o `.new()`, por exemplo)_, pode ser utilizado a função `.init()`:

```lua
local self = Super(ClassePai, ClasseFilha).init(param1, param2)
```

## Exemplos

### Classe Pai:

```lua
local Pet = {}
Pet.__index = Pet

function Pet.new(Name: string): IPet
    local self = setmetatable({}, Pet)
    self.Name = Name

    return self
end

function Pet.Move(self: IPet, Position: Vector3)
  -- ...
end

export type IPet = typeof(setmetatable({} :: {
    Name: string,
}, Pet))
```

### Classe Filha:

```lua
local PetClass = require(script.Parent)

local Dog = {}
Dog.__index = Dog

function Dog.new(Name: string, Race: string): IDog
    local self = Super(PetClass, Dog).init(Name)
    self.Race = Race

    return self
end

function Dog.GetRace(self: IDog)
    return self.Race
end

export type IDog = PetClass.IPet | typeof(setmetatable({} :: {
    Race: string,
}, Dog))
```

### Utilização na Prática:

```lua
local Poodle = Dog.new('Mel', 'Poodle')
Poddle:Move(Vector3.new(5, 1, 2))

print(Poodle:GetRace(), Poddle.Race)
```
