# Layre Framework

O Framework da Layre consiste na padronização de código, com um amontoado de features que misturam [Atalhos](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Plugin.md#lista-de-comandos-command-bar) (Plugin), [Snippets](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Plugin.md#snipetts) (Plugin), [Padrões de Projeto](#padrões-de-projeto) e entre muitas outras funcionalidades, onde o principal objetivo é contornar o principal vilão do Roblox Studio: **A produtividade**.

Nesse readme você consegue consultar cada tópico que o **Framework** aborda, cada índice foi separado por categoria/assunto, basta clicar e ir navegando onde te interessa.

---

## 📦 Instalação

Tudo gira em torno do [Plugin](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Plugin.md), é com ele que você vai injetar e utilizar o Framework.

Você até pode usar e instalar manualmente os `.rbxm` disponibilizados, mas fica completamente por sua conta e risco, e **não é nada recomendável** que faça isso.

> ⚠️ **ATENÇÃO:**  
> A instalação do plugin deve ser feita **manualmente** por enquanto.  
> Estamos corrigindo questões no código fonte que violam as diretrizes do Roblox, portanto não conseguimos manter atualizações automáticas neste momento.

**Por isso, instale o plugin apenas da seguinte forma:**

1. Acesse o último release oficial na [Página de Releases](https://github.com/Layre-Org/layre-organization/releases/tag/release)
2. Busque pela **última release estável** -> Geralmente é a primeira da lista, e estará marcada como "nova" ou "latest".
3. Se houver instruções nesta release, é altamente recomendável a leitura.
4. Busque pelo anexo `Layre Plugin.rbxmx` e baixe-o.
5. Abra o Explorador de Arquivos, vá na barra de diretórios e cole o comando: `%LOCALAPPDATA%\Roblox\Plugins`.
6. Mova o `.rbxmx` para esta pasta e re-abra seu Roblox Studio -> Verifique na aba de Plugins.

> ✅ Seu plugin foi instalado e você já pode iniciar seu novo projeto

---

## 📖 Documentação

### Plugin

-   [Como usar o Plugin](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Plugin.md)

### Padrões de Projeto

-   [Managers](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Managers.md)
-   [Controllers](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Controllers.md)
-   [Components](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Components.md)
-   [Handlers](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Handlers.md)
-   [Classes](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Classes.md)
-   [Stores](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Stores.md)

### Ferramentas Exclusivas (diretamente integradas)

-   Flux (Fortemente baseado em [ByteNet](https://ffrostfall.github.io/ByteNet/), mantido por [@Gui97p](https://github.com/Gui97p))
-   LuaO (desenvolvido por [@Gui97p](https://github.com/Gui97p) e [@YureAnjos](https://github.com/YureAnjos))
-   Data Structures (desenvolvido por [@Gui97p](https://github.com/Gui97p))
-   [Super](https://github.com/Layre-Org/layre-organization/blob/main/Docs/Classes.md#herança-com-a-lib-super) (desenvolvido por [@Gui97p](https://github.com/Gui97p))
-   [Janitor](https://howmanysmall.github.io/Janitor/)
-   [Promise](https://eryn.io/roblox-lua-promise/) (Movido para o LuaO, com base em task)
-   [Fusion 3.0](https://elttob.uk/Fusion/0.3/)
-   .._entre muitas outras libs_

---

## 📝 Contribuição

Antes de solicitar um Issue ou PR (Pull Request) é de extrema importância entender sobre o [SemVer](https://semver.org/lang/pt-BR/) (Versionamento Semântico) e estar ciente das últimas versões publicadas em [Releases](https://github.com/Layre-Org/layre-organization/releases).

-   Veja [como contribuir com o Framework](https://github.com/Layre-Org/layre-organization/blob/main/Docs/PRsAndContribution.md)
