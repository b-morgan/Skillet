--[[

Skillet: A tradeskill window replacement.
Copyright (c) 2007 Robert Clark <nogudnik@gmail.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

]]--

local L = LibStub("AceLocale-3.0"):NewLocale("Skillet", "ptBR")
if not L then return end

L["About"] = "Sobre"
L["ABOUTDESC"] = "Sobre o Skillet"
L["alts"] = true
L["Appearance"] = "Aparência"
L["APPEARANCEDESC"] = "Opções de visualização do Skillet"
L["bank"] = "banco"
L["Blizzard"] = true
L["buyable"] = "comprável"
L["Buy Reagents"] = "Comprar Reagentes"
L["By Difficulty"] = "Por Dificuldade"
L["By Item Level"] = "Por Nível do Item"
L["By Level"] = "Por Nível"
L["By Name"] = "Por Nome"
L["By Quality"] = "Por Qualidade"
L["By Skill Level"] = "Por Habilidade"
L["can be created from reagents in your inventory"] = "Pode ser criado com reagentes do seu inventario"
L["can be created from reagents in your inventory and bank"] = "Pode ser criado com reagentes do seu inventario e banco"
L["can be created from reagents on all characters"] = "Pode ser criado com reagentes de todos seus personagens"
L["Clear"] = "Limpar"
L["click here to add a note"] = "clique aqui para adicionar uma nota"
L["Collapse all groups"] = "Contrair todos os grupos"
L["Config"] = "Configuração"
L["CONFIGDESC"] = "Abre a tela de configuração do Skillet"
L["Could not find bag space for"] = "Não há espaço na mochila"
L["craftable"] = "Produzivel"
L["Crafted By"] = "Feito Por"
L["Create"] = "Criar"
L["Create All"] = "Criar Todos"
L[" days"] = "dias"
L["Delete"] = "Apagar"
L["DISPLAYREQUIREDLEVELDESC"] = "Se o item requer um nível minimo para ser usado, este nível será mostrado com a receita"
L["DISPLAYREQUIREDLEVELNAME"] = "Mostrar nivel necessario"
L["DISPLAYSGOPPINGLISTATAUCTIONDESC"] = "Mostrar uma lista de compras de itens necessarios para fabricação das receitas que você não tem na sua bolsa"
L["DISPLAYSGOPPINGLISTATAUCTIONNAME"] = "Mostra a lista de compras no leilão"
L["DISPLAYSHOPPINGLISTATBANKDESC"] = "Mostrar uma lista de compras de itens necessarios para fabricação das receitas que você não tem na sua bolsa"
L["DISPLAYSHOPPINGLISTATBANKNAME"] = "Mostrar lista de itens no banco"
L["DISPLAYSHOPPINGLISTATGUILDBANKDESC"] = "Mostrar uma lista de compras de itens necessarios para fabricação das receitas que você não tem na sua bolsa"
L["DISPLAYSHOPPINGLISTATGUILDBANKNAME"] = "Mostrar lista e itens no banco do clã"
L["Enabled"] = "Hablitado"
L["Enchant"] = "Encantamento"
L["ENHANCHEDRECIPEDISPLAYDESC"] = "Quando habilitado, aparecera um ou mais caractere '+' ao lado da receita pra indicar a dificuldade"
L["ENHANCHEDRECIPEDISPLAYNAME"] = "Mostrar dificuldade da receita como um texto"
L["Expand all groups"] = "Expandir todos os grupos"
L["Features"] = "Caracteristicas"
L["FEATURESDESC"] = "Habilita ou deshabilita Caracteristicas extras"
L["Filter"] = "Filtro"
L["Glyph "] = "Glifos"
L["Gold earned"] = "Ouro ganho"
L["Grouping"] = "Agrupando"
L["have"] = "possui"
L["Hide trivial"] = "Esconder triviais"
L["Hide uncraftable"] = "Esconde não produziveis"
L["Include alts"] = "Incluir alts"
L["Include guild"] = "Include guild"
L["Inventory"] = "Inventorio"
L["INVENTORYDESC"] = "Informações o inventario"
L["is now disabled"] = [=[esta desabilitado
modo de espera - Skillet está desabilitado]=]
L["is now enabled"] = [=[esta habilitado
modo de espera - Skillet está habilitado]=]
L["Library"] = "Biblioteca"
L["LINKCRAFTABLEREAGENTSDESC"] = "Torna os reagentes clicaveis"
L["LINKCRAFTABLEREAGENTSNAME"] = "Fazer reagentes ser clicavel"
L["Load"] = "Carregar"
L["Merge items"] = "Merge items"
L["Move Down"] = [=[Mover abaixo
reordenando a fila]=]
L["Move to Bottom"] = [=[Mover para o final
reordenando a fila]=]
L["Move to Top"] = [=[Mover para o topo
reordenando a fila]=]
L["Move Up"] = [=[Mover acima
reordenando a fila]=]
L["need"] = "necessário"
L["No Data"] = "Sem informação"
L["None"] = "Nenhum"
L["No such queue saved"] = "Nenhuma fila salva"
L["Notes"] = "Notas"
L["not yet cached"] = "ainda não armazenados em cache"
L["Number of items to queue/create"] = "Número de itens para fila/criar"
L["Options"] = "Opções"
L["Order by item"] = "Order by item"
L["Pause"] = "Pausa"
L["Process"] = "Processo"
L["Purchased"] = "Comprados"
L["Queue"] = "Fila"
L["Queue All"] = "Todos na Fila"
L["QUEUECRAFTABLEREAGENTSDESC"] = "Se você pode criar um item necessario para receita, e você não tem, então o reagente sera colocado na fila"
L["QUEUECRAFTABLEREAGENTSNAME"] = "Colocar na fila reagentes fabricaveis"
L["QUEUEGLYPHREAGENTSDESC"] = "Se você pode criar um item necessario para receita, e você não tem, então o reagente sera colocado na fila"
L["QUEUEGLYPHREAGENTSNAME"] = "Colocar na fila reagente para Glifos"
L["Queue is empty"] = "A fila está vazia"
L["Queue is not empty. Overwrite?"] = "A fila não está vazia. Sobrescrever?"
L["Queues"] = "Filas"
L["Queue with this name already exsists. Overwrite?"] = "Fila com este nome ja existe, sobreescrever?"
L["Reagents"] = "Novo valor para botão comerciante em MoP"
L["reagents in inventory"] = "Reagentes no inventario"
L["Really delete this queue?"] = "Você realmente quer apagar esta fila?"
L["Rescan"] = "Rescanear"
L["Reset"] = "Redefinir comando de posição"
L["RESETDESC"] = "Redefinir posição do Skillet"
L["Retrieve"] = "Recuperar"
L["Save"] = "Salvar"
L["Scale"] = "Escala"
L["SCALEDESC"] = "Escala da janela principal"
L["Scan completed"] = "Verificação concluida"
L["Scanning tradeskill"] = "Verificando as receitas"
L["Selected Addon"] = "Addon Selecionado"
L["Select skill difficulty threshold"] = ""
L["Sells for "] = "Vender por"
L["Shopping List"] = "Lista de Compras"
L["SHOPPINGLISTDESC"] = "Mostra a lista de compras"
L["SHOWBANKALTCOUNTSDESC"] = "Quando calcular os itens possiveis de fabricação usa os itens do banco de de personagens alternativos"
L["SHOWBANKALTCOUNTSNAME"] = "Incluir itens no banco e em personagens alternativos"
L["SHOWCRAFTCOUNTSDESC"] = "Mostra o numero possivel de itens para fabricação, não o total de itens produzidos"
L["SHOWCRAFTCOUNTSNAME"] = "Mostrar a contagem de itens fabricaveis"
L["SHOWCRAFTERSTOOLTIPDESC"] = "Mostrar o nome do personagem alternativo que pode criar este item nas informações do item."
L["SHOWCRAFTERSTOOLTIPNAME"] = "Mostrar criador nas informações"
L["SHOWDETAILEDRECIPETOOLTIPDESC"] = "Mostrar toda a informação do item a ser criado. Se você desligar vera apenas uma informação parcial(Segure ctrl para a descrição completa)"
L["SHOWDETAILEDRECIPETOOLTIPNAME"] = "Mostrar dicas para as receitas"
L["SHOWFULLTOOLTIPDESC"] = "Mostrar toda a informação de um item a ser fabricado. Se você desligar, apenas vera uma pequena informação (Segure Ctrl para uma descrição completa)"
L["SHOWFULLTOOLTIPNAME"] = "Usar caixa de informação padrão"
L["SHOWITEMNOTESTOOLTIPDESC"] = "Adiciona as notas que você forneceu para um item nas informações desse item"
L["SHOWITEMNOTESTOOLTIPNAME"] = "Adicionar notas do usuários as informações do item"
L["SHOWITEMTOOLTIPDESC"] = "Mostrar informações do item a ser fabricado, em vez das informações da receita."
L["SHOWITEMTOOLTIPNAME"] = "Mostra informações quando possível"
L["Skillet Trade Skills"] = "Skillet - Habilidades de Comercio"
L["Skipping"] = "Pulando"
L["Sold amount"] = "Total vendido"
L["SORTASC"] = "Organiza a lista do maior (topo) para o menor (abaixo)"
L["SORTDESC"] = "Organiza a lista do menor (topo) para o maior (abaixo)"
L["Sorting"] = "Ordenando"
L["Source:"] = [=[Origem:
origem da receita do item]=]
L["STANDBYDESC"] = "Habilita e desabilita o modo de espera"
L["STANDBYNAME"] = "Aguardar"
L["Start"] = "Iniciar"
L["Supported Addons"] = "Addons Suportados"
L["SUPPORTEDADDONSDESC"] = "Addons suportados que são usados para escanear seu inventario"
L["This merchant sells reagents you need!"] = "Este vendedor tem itens que você precisa!"
L["Total Cost:"] = "Custo Total:"
L["Total spent"] = "Total gasto"
L["Trained"] = [=[Aprendida
receita obtida no instrutor]=]
L["TRANSPARAENCYDESC"] = "Transparência da janela principal"
L["Transparency"] = "Transparência"
L["Unknown"] = [=[Desconhecido
origem da receita desconhecida]=]
L["VENDORAUTOBUYDESC"] = "Se você tiver itens"
L["VENDORAUTOBUYNAME"] = "Comprar reagentes automaticamente"
L["VENDORBUYBUTTONDESC"] = "Mostra o botão de compra de reagentes nos vendedores"
L["VENDORBUYBUTTONNAME"] = "Mostrar botão de compra nos vendedores"
L["View Crafters"] = "Ver artesões"

