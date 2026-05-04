# Components

Cada tipo de componente possui seu papel principal dentro do framework, **Components** são parecidos com as [Classes](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Classes.md), mas com alguns fatores específicos, já os **UIComponents** fazem parte da UI Framework com maneiras de uso completamente diferentes.

Entretanto, componentes possuem um papel claro: criar blocos de código reutilizáveis e personalizáveis.

## Índice

- [Quando utilizar Componentes](#quando-utilizar-componentes)
- [Como é um Component](#game-components)
- [Como é o UIComponent](#o-que-são-uicomponents)

## Quando utilizar Componentes?

Em qualquer projeto (principalmente jogos completos) precisamos criar diversos NPCs, Interações pelo Mapa, Áreas de Spawn de inimigos, Hitbox e assim vai.. Percebe-se que cada um dos itens citados precisam estar presentes em cada canto do jogo (claro, dependendo do mesmo).

Por isso existem os Componentes, pois criando um componente para uma Hitbox por exemplo, você consegue criar várias Hitboxes para diversos lugares do jogo, com apenas um comando no código: `HitboxComponent:Construct()`.

> **💡 Dica:** A mesma lógica se aplica aos `UIComponents`, entretanto, se referindo à questões de interface do game.

## Game Components

Uma [Classe](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Classes.md) cria instâncias com base em `.new()` -> São **Funções Construtoras** definidas pelo próprio programador. `Components`, por sua vez, constrói instâncias com base em **Tags**. Deste modo, cada instância do roblox que tiver uma tag X adicionada a sí, o component executará.

**Lembre-se que `Components` focam em Instâncias do jogo, como Models, ProximityPrompt.. Diferente dos `UIComponents` que focam exclusivamente em Interfaces.**

### Sintaxe Base dos Components

Esta é a base para Components, veja que utilizamos a lib [Component](https://sleitnick.github.io/RbxUtil/api/Component/)

```lua
--</Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')

--</Packages
local Component = require(ReplicatedStorage.Shared.Utility.Component)

local ExampleComponent = Component.new({
	Tag = 'Example'
})

function ExampleComponent:Construct()

end

return ExampleComponent
```

Com esta base, conseguimos especificar na função `.new()` qual a Tag que pretendemos usá-la neste Component, e então, quando uma Instância receber a Tag, o component executará a função `:Construct()`.

### Exemplo de Utilização

O código à seguir gerencia um `ProximityPrompt` dentro de uma **BillboardGui** quando a Tag `PickupPrompt` é adicionada à ela. O método `:Construct()` é chamado quando a tag for adicionada, e é possível acessar a própria **BillboardGui** com `self.Instance`:

```lua
local PickupPrompt = Component.new({
    Tag = 'PickupPrompt'
})

function PickupPrompt:Construct()
    local Prompt: ProximityPrompt = self.Instance

    if Client.Gamepass:GetAttribute('Magnet') then
        Prompt.MaxActivationDistance *= 1.5
    end

    Prompt.PromptShown:Connect(function()
        self.Instance.Enabled = true
    end)
    Prompt.PromptHidden:Connect(function()
        self.Instance.Enabled = false
    end)
end
```

## O que são UIComponents

> ⚠️ **IMPORTANTE:** Temos previsão para modificar algumas funcionalidades de UIComponents, é importante estar ciente das novas mudanças que podem ocorrer neste tópico.

São blocos de código reutilizáveis para as interfaces de seu jogo, eles fazem parte da UI Framework e possuem uma sintaxe específica, gerida pelo **Client Core** junto de **Conceitos de Componentização** _(comumente conhecidos em React.js)_ e das principais funcionalidades do [Fusion 3.0](https://elttob.uk/Fusion/0.3/)

- Veja a [documentação do Fusion sobre UIComponents](https://elttob.uk/Fusion/0.3/tutorials/best-practices/components)

### O Framework gerencia UIComponents de uma forma específica..

Assim como o resto da UI Framework, os `UIComponents` ficam localizados no diretório `Client/UI/Components/` dentro de `ReplicatedStorage`.

Quando o Client inicializa, o **Client Core** gera um [Scope](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Scopes.md) com todos os UIComponents listados de uma forma fácil para acessá-los. Este [Scope](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Scopes.md) então é o mesmo enviado à todos os [UIControllers](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Controllers.md#exclusividade-de-uicontrollers), onde para criar qualquer Component, basta seguir o exemplo:

```lua
local ExampleController = {}

function ExampleController:Start(Scope: UIScope.Scope)
	local CanvasGroup = Scope.Paths.to.CanvasGroup
	local CanvasEnabled = Scope:Value(false)

	Scope:Canvas() {
		Canvas = CanvasGroup,
		Enabled = CanvasEnabled,
		SpringSpeed = 25
	}
end

return ExampleController
```

### Sintaxe Base para UIComponents

Para uma boa leitura e manutenção de código, existe um padrão de sintáxe para criar UIComponents, e isso envolve:

1. Criar e retornar uma `function(Scope, Props)` -> Sendo `Scope` o único parâmetro que é passado **Automaticamente** e `Props` uma `PropertyTable` com as configurações que deseja para aquele component.
2. Especificar as tipagens `IProps` e `IReturn`, utilizando `Fusion.Value<any>`.
3. (opcional) Utilizar `table.destruct()` do `LuaO/table` para separar certas propriedades daquele component/interface.

**Veja o exemplo na prática:**

```lua
export type IProps = {
	Label: TextLabel;
	Text: Fusion.Value<string>;
	Format: ((Current: string) -> string)?;
}

export type IReturn = TextLabel;

return function(Scope: UIScope.IScope, Props: IProps): IReturn
	local Label, Text, Format = table.destruct(Props, { 'Label', 'Text', 'Format' })

	assert(Label, 'Missing prop "Label"')
	assert(Text, 'Missing prop "Text"')

	local FinalText = Scope:Computed(function(use)
		local Current = use(Text)

		if Format then
			return Format(Current)
		end

		return tostring(Current)
	end)

	Props.Text = Props.Text or FinalText

	Scope:Hydrate(Label)(Props)

	return Label
end
```

### UIComponents built-in

> **💡 Dica:** Nenhum destes UIComponents foram estritamente testados e portanto, caso encontre um bug, é importante nos notificar. Caso tenha uma ideia de componente novo, fale conosco para analisarmos a ideia.

Percebe-se que há uma outra pasta chamada **UI** dentro de `/Components`. Dentro dela você encontra os **UIComponents built-in** do Framework, que são componentes genéricos e os mais utilizados nos jogos.

- **Temos uma lista considerável de UIComponents que já estão prontos para uso**

Um dos UIComponents e o mais utilizado é o **Canvas Component** (gerencia CanvasGroup's), veja um trecho de código:

```lua
export type IProps = {
	Canvas: CanvasGroup;
	Enabled: Fusion.Value<boolean>;
	DisableSpring: boolean?; --> Optional<false>
	SpringSpeed: number?; --> Optional<10>
	SpringDamper: number?; --> Optional<1>
}

export type IReturn = CanvasGroup

return function(Scope: UIScope.IScope, Props: IProps): IReturn
	assert(Props.Canvas, 'Missing prop "Canvas"')
	assert(Props.Enabled, 'Missing prop "Enabled"')

	local Canvas, Enabled, DisableSpring, SpringSpeed, SpringDamper = table.destruct(Props, {
		'Canvas', 'Enabled', 'DisableSpring', 'SpringSpeed', 'SpringDamper'
	})

	local Transparency = Scope:Computed(function(use) return use(Enabled) and 0 or 1 end)
	local FinalTransparency = not DisableSpring and Scope:Spring(Transparency, SpringSpeed, SpringDamper) or Transparency
	local Visible = Scope:Computed(function(use) return use(FinalTransparency) < .99 end)

	Props.Visible = Props.Visible or Visible;
	Props.GroupTransparency = Props.GroupTransparency or FinalTransparency

	Scope:Hydrate(Canvas)(Props)

	return Canvas, {
		Transparency = FinalTransparency;
		Visible = Visible;
	}
end

```
