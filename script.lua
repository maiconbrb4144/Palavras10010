-- Word System — revisão.
local iniciou, erroInicial = xpcall(function()
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local okEntrada, VirtualInputManager = pcall(function() return game:GetService("VirtualInputManager") end)
if not okEntrada then VirtualInputManager = nil end
local player = Players.LocalPlayer
local bancos = {
EN = { Set = {}, List = {} },
PT = { Set = {}, List = {} }
}
local bPR = { Set = {}, List = {} } -- 10k
local DicionarioENExtra = { Set = {}, List = {} }       -- 20k
local bEN = { Set = {}, List = {} }
local usedWords = {}
local idiomaAtivo = "PT"
local modoBusca = "PREFIXO"
local travaIdiomaManual = false
local databaseLoaded = false
local loadingStatusText = "Iniciando download..."
-- Fontes principais que chegarem tarde são indexadas separadamente e publicadas de uma vez.
local fontesRede, recuperados, revisaoBancos = {}, {}, 0
for i = 1, 4 do recuperados[i] = {Set = {}, Buckets = {}, pronto = false} end
local function baixarPrincipal(item)
item.geracao = (item.geracao or 0) + 1
local geracao = item.geracao
item.inicio, item.terminou, item.ok, item.texto = os.clock(), false, false, nil
item.thread = task.spawn(function()
local ok, texto = pcall(function() return game:HttpGet(item.url) end)
if item.geracao ~= geracao then return end
local valido = ok and type(texto) == "string" and #texto > 1000 and #texto < 10000000
if valido then
local boas, vistas = 0, 0
for linha in texto:gmatch("[^\r\n]+") do
vistas = vistas + 1
if linha:match("^[A-Za-z]+$") then boas = boas + 1 end
if boas >= 20 or vistas >= 100 then break end
end
valido = boas >= 20
end
item.ok, item.texto, item.terminou = valido, valido and texto or nil, true
end)
end
local listaNegra = {
["xoxo"] = true, ["xix"] = true, ["xuxu"] = true, ["xox"] = true, ["xx"] = true,
["xete"] = true, ["xax"] = true, ["xis"] = true, ["xai"] = true, ["xeo"] = true,
["xabao"] = true, ["xamake"] = true, ["xafarroz"] = true, ["xara"] = true, ["xabe"] = true,
["xafarraz"] = true, ["xffarraz"] = true, ["xacoco"] = true, ["xaco"] = true, ["xaca"] = true,
["xana"] = true, ["xato"] = true, ["xeva"] = true, ["xira"] = true, ["xame"] = true,
["xbox"] = true, ["xhtml"] = true, ["oxe"] = true, ["oxente"] = true,
["mano"] = true, ["vlw"] = true, ["flw"] = true, ["tmj"] = true, ["gremio"] = true
}
for w in ("omg omni omb omaha oman omar rhode rhodes nyc nyse html http https www url api cpu gpu usb pdf jpg png sms faq blog com org net iphone xbox xhtml"):gmatch("%a+") do listaNegra[w] = true end
local bancoEliteGlobal = {
"addict", "conflict", "convict", "predict", "strict", "verdict", "restrict", "afflict", "depict", "evict", "contradict",
"many", "any", "funny", "bunny", "penny", "pony", "tiny", "shiny", "irony", "colony", "felony", "harmony", "destiny", "company", "deny",
"tax", "wax", "lax", "max", "climax", "thorax", "relax", "syntax", "flax",
"taxi", "taxis", "anexo", "nexo", "fixo", "fluxo", "eixo", "box", "fox", "luxo", "detox", "xerox",
"duplex", "triplex", "latex", "cortex", "index", "codex", "telex", "apex", "silex", "inox",
"unisex", "fenix", "complexo", "perplexo", "prolixo", "exame", "exito", "exodo", "faixa", "caixa",
"graph", "paragraph", "autograph", "biography", "telegraph", "glyph", "aleph", "trophy", "myth", "path", "cloth", "triumph", "lymph", "nymph",
"zoo", "zoom", "zombie", "zodiac", "zoology", "kazoo",
"warmth", "sixth",
"night", "light", "right", "fight", "sight", "flight", "caught", "thought", "weight", "height",
"lunch", "bench", "bunch", "inch", "clinch", "trench", "branch", "punch", "health", "wealth",
"nao", "pao", "mao", "cao", "acao", "sabao", "balao", "aviao", "arroz", "veloz", "feroz", "feliz", "giz", "raiz"
}
local bancoEliteSet = {}
for _, w in ipairs(bancoEliteGlobal) do bancoEliteSet[w] = true end
local bancoEmergenciaPT = {
"agrega", "agregar", "agregado", "agregada", "agregados", "agregadas", "agregacao", "agregam", "agregando", "agregamos", "agregador", "agregadores",
"ombro", "ombros", "omitir", "omito", "omite", "omitido", "omissao", "omisso", "onibus", "onda", "ondas", "onde", "ontem", "onze", "ovelha", "ouvido", "ouvir", "olhar", "olhos", "oliva", "olimpico",
"exame", "exato", "exemplo", "excesso", "exilio", "exito", "exodo", "exotico", "expor", "existe", "externo", "extra", "extremo", "experto", "explicar", "explorar", "excluir",
"caixa", "faixa", "peixe", "baixo", "deixar", "frouxo", "enxame", "enxada", "enxergar", "enxugar", "enxuto", "enxoval", "enxofre", "proximo", "maximo", "fixo", "fixar", "fluxo", "nexo", "anexo", "reflexo", "complexo", "convexo", "perplexo", "prolixo", "ortodoxo", "saxofone",
"xale", "xarope", "xadrez", "xampu", "xicara", "xilofone", "xilogravura", "xote", "xodo", "xogum", "xerife", "xisto", "xenofobia",
"feliz", "raiz", "capaz", "veloz", "feroz", "rapaz", "matriz", "juiz", "arroz", "nariz", "luz", "vez", "voz", "arvore", "amor", "casa", "vida", "tempo", "terra", "pedra", "livro", "ponte", "festa", "corpo",
"gnomo", "gnose", "gnaisse", "psique", "psicose", "psicologia", "pneu", "pneumonia", "pneumatico", "pseudo", "czar", "czarina", "czarismo"
}
local bancoEmergenciaEN = {
"omen", "omens", "omit", "omits", "omitted", "omitting", "omega", "omelet", "omelette", "omission", "omissions", "ominous", "omnibus", "omnivore", "omnivorous",
"rhino", "rhinos", "rhythm", "rhythms", "rhyme", "rhymes", "rhyming", "rhetoric", "rhapsody",
"box", "fox", "six", "tax", "wax", "relax", "climax", "syntax", "index", "apex", "latex", "complex", "duplex", "matrix", "prefix", "suffix", "phoenix", "flex", "flux", "fix", "mix", "sixth", "sixty", "fixing", "mixing", "mixture", "fixture",
"example", "exact", "examine", "exceed", "except", "excited", "excuse", "exercise", "exhaust", "exhibit", "exist", "expand", "expect", "explain", "explore", "export", "express", "extra", "extreme",
"lyric", "lyrics", "lying", "lymph", "lynx", "nylon", "nymph", "nyala", "type", "typical", "tyrant", "typhoon", "tlingit", "gnome", "gnosis", "gnostic", "pseudo", "psychology", "pneumatic", "pneumonia", "czar", "czarina", "with", "math", "both", "where", "why", "what", "when", "which", "next", "text", "gift", "left", "walk", "talk"
}
local bancoPTCurado = {}
for _, w in ipairs(bancoEmergenciaPT) do bancoPTCurado[w] = true end
local finaisDificeis = {"ain", "cao", "orm", "ny", "om", "ft", "gn", "pt", "ia", "ux", "mn", "x"}
-- O trio é controlado somente pelo botão próprio, não por filtros individuais.
local finaisTrio = {ain = true, cao = true, orm = true}
local trioAtivo = false
-- Desligado significa apenas sem prioridade; nunca bloqueia palavras.
-- Finais removidos não bloqueiam palavras; o personalizado começa vazio.
local finaisDesligados = {}
local finalExtra, extraLigado, botaoExtra, enterExtra = "", false, nil, nil
local revisaoFiltros = 0
local botoesFinais = {}
local function finalPermitido(w, temporario)
-- Finais desligados são tratados como finais comuns, inclusive na reserva.
return true
end
local function atualizarFinaisDesligados()
-- Só invalida pesquisas que estavam ordenando com prioridades antigas.
revisaoFiltros = revisaoFiltros + 1
end
local function pintarExtra()
if not botaoExtra then return end
botaoExtra.Text = extraLigado and "✓" or "✕"
botaoExtra.BackgroundColor3 = extraLigado and Color3.fromRGB(18, 78, 65) or Color3.fromRGB(75, 30, 35)
end
local modoFinais = "TODOS"
local estrategiaAtiva = false
local modoPet = 0
local modoLongas, currentRelaxado, currentRevisao, currentRevisaoBancos = false, false, 0, 0
local progressoBusca, resgateBuscaTermo, resgatesBusca = 0, nil, 0
local bancosReserva = {EN = {Buckets = {}, Set = {}, pronto = false}, PT = {Buckets = {}, Set = {}, pronto = false}}
local reservasFinalizadas = false
local inputBox
local function extrasPermitidos(termo)
termo = (termo or ""):lower():gsub("%s", "")
return termo:sub(1, 1) ~= "x" and termo:sub(1, 2) ~= "ia"
end
local pendenteUI = false
local prefixosDificeis = {EN = {}, PT = {}}
local function categoriaFinal(w, idioma, modoEscolhido, trioEscolhido)
local modo = modoEscolhido or modoFinais
local usarTrio = trioEscolhido
if usarTrio == nil then usarTrio = trioAtivo and extrasPermitidos(inputBox and inputBox.Text) end
if modo == "NENHUM" then return 0 end
for _, fim in ipairs(finaisDificeis) do
if not finaisDesligados[fim] and #w >= #fim and w:sub(-#fim) == fim
and (prefixosDificeis.EN[fim] or prefixosDificeis.PT[fim])
and (not finaisTrio[fim] or usarTrio)
and (modo ~= "X" or fim == "x") and (modo ~= "OUTROS" or fim ~= "x") then
-- Um final que é a própria palavra de três letras continua disponível,
-- mas não recebe prioridade do trio: evita favorecer opções curtas e incertas.
if finaisTrio[fim] then return #w > #fim and 3 or 0 end
return fim == "x" and (modo == "X" and 2 or 1) or 2
end
end
if extraLigado and finalExtra ~= "" and modo ~= "X" and w:sub(-#finalExtra) == finalExtra then return 2 end
return 0
end
local CommonWordsEN = {}
local comunsPT = {}
for w in ("xale xote osso ossos mosca moscas mosquito mosquitos casa vida amor agua boca bola bolo cabo cafe cama campo capa cara caro caso cedo cena cima cidade cola como copa cora corpo dado dama dedo dias dica doce dose duro faca face fato feira festa fino foco fogo fora forma foto frio gato gelo giro guia hora ideia ilha jogo laje lago lado lama lana lata leite lima lindo lobo logo lua lupa lupa mala mapa marca mata mesa medo meio meta moda modo mola mora muda muro nada nome nota nova novo olho onda ouro pais para pato pedra pele pena pelo peso piso plano povo praia prata rede rei remo reta roda roupa rosa seco sede selo sino sopa tela tema tempo terra teto texto tipo todo tudo unha uva vale vela vida vila vinho viva vivo voz zona"):gmatch("%a+") do comunsPT[w] = true end
local function palavraCurtaConfiavel(palavra, idioma)
if #palavra ~= 4 then return true end
if idioma == "EN" then return CommonWordsEN[palavra] == true or recuperados[2].Set[palavra] == true or recuperados[3].Set[palavra] == true end
return comunsPT[palavra] == true
end
local function novosMapas()
return { EN = {Prefix1 = {}, Prefix2 = {}, Prefix3 = {}}, PT = {Prefix1 = {}, Prefix2 = {}, Prefix3 = {}} }
end
local prefixStats = novosMapas()
local prefixosUsados = novosMapas()
local function incrementarMapa(mapa, chave)
if chave and chave ~= "" then mapa[chave] = (mapa[chave] or 0) + 1 end
end
local function registrarEm(mapa, idioma, palavra)
if #palavra >= 1 then incrementarMapa(mapa[idioma].Prefix1, palavra:sub(1, 1)) end
if #palavra >= 2 then incrementarMapa(mapa[idioma].Prefix2, palavra:sub(1, 2)) end
if #palavra >= 3 then incrementarMapa(mapa[idioma].Prefix3, palavra:sub(1, 3)) end
end
local function registrarPalavraUsada(w)
for idioma, banco in pairs(bancos) do
local pertence = banco.Set[w]
if not pertence then
if idioma == "PT" then pertence = recuperados[1].Set[w]
else pertence = recuperados[2].Set[w] or recuperados[3].Set[w] or recuperados[4].Set[w] end
end
if pertence then registrarEm(prefixosUsados, idioma, w) end
end
end
local function marcarUsada(w)
if not usedWords[w] then
usedWords[w] = true
registrarPalavraUsada(w)
end
end
local function rebuildPrefixStats()
prefixStats = novosMapas()
prefixosUsados = novosMapas()
for idioma, dados in pairs(bancos) do
prefixosDificeis[idioma] = {}
for i, palavra in ipairs(dados.List) do
registrarEm(prefixStats, idioma, palavra)
for _, fim in ipairs(finaisDificeis) do
if palavra:sub(1, #fim) == fim then prefixosDificeis[idioma][fim] = true end
end
if i % 20000 == 0 then task.wait() end
end
end
for palavra in pairs(usedWords) do registrarPalavraUsada(palavra) end
end
local refazendoEstatisticas = false
local function atualizarEstatisticasRecuperadas()
if refazendoEstatisticas then return end
refazendoEstatisticas = true
task.spawn(function()
repeat
local versao = revisaoBancos
local novas = novosMapas()
local vistos = {PT = {}, EN = {}}
local n = 0
for idioma, banco in pairs(bancos) do
for _, palavra in ipairs(banco.List) do
registrarEm(novas, idioma, palavra)
n = n + 1; if n % 5000 == 0 then task.wait() end
end
end
for numero, banco in ipairs(recuperados) do
if banco.pronto then
local idioma = numero == 1 and "PT" or "EN"
for palavra in pairs(banco.Set) do
if not bancos[idioma].Set[palavra] and not vistos[idioma][palavra] then
vistos[idioma][palavra] = true; registrarEm(novas, idioma, palavra)
end
n = n + 1; if n % 5000 == 0 then task.wait() end
end
end
end
if versao == revisaoBancos then
local usadas = novosMapas()
for palavra in pairs(usedWords) do
for idioma, banco in pairs(bancos) do
if banco.Set[palavra] or vistos[idioma][palavra] then registrarEm(usadas, idioma, palavra) end
end
end
prefixStats, prefixosUsados = novas, usadas
revisaoBancos = revisaoBancos + 1
break
end
until false
refazendoEstatisticas = false
end)
end
local function contarSaidasPossiveis(idioma, sequencia)
if not sequencia or sequencia == "" then return 0 end
local n = math.min(#sequencia, 3)
local chave = sequencia:sub(1, n)
local mapa = prefixStats[idioma]["Prefix" .. n]
return mapa[chave] or 0
end
local function disponiveis(sequencia)
local n = math.min(#sequencia, 3)
local mapa = "Prefix" .. n
local total = 0
for _, idioma in ipairs({"EN", "PT"}) do
local bruto = prefixStats[idioma][mapa][sequencia] or 0
local gasto = prefixosUsados[idioma][mapa][sequencia] or 0
total = total + math.max(0, bruto - gasto)
end
return total
end
local function calcularPesoPalavra(palavra, idiomaBase, termo)
local r2 = contarSaidasPossiveis(idiomaBase, palavra:sub(-2))
local r3 = contarSaidasPossiveis(idiomaBase, palavra:sub(-3))
return (bancoEliteSet[palavra] and 20 or 0), r2, r3
end
local function estimarRespostas(palavra)
local r1 = disponiveis(palavra:sub(-1))
local r2 = disponiveis(palavra:sub(-2))
local r3 = disponiveis(palavra:sub(-3))
if r1 == 0 and r2 == 0 and r3 == 0 then return math.huge end
local base2 = r2 > 0 and r2 or (r1 > 0 and r1 or r3)
local base1 = r1 > 0 and r1 or base2
local base3 = r3 > 0 and r3 or base2
return base1 * 0.10 + base2 * 0.60 + base3 * 0.30
end
local function finalPriorizavel(palavra, idioma, modo, trioEscolhido)
local categoria = categoriaFinal(palavra, idioma, modo, trioEscolhido)
if idioma == "EN" and (#bEN.List > 0 or recuperados[4].pronto) and not bEN.Set[palavra] and not recuperados[4].Set[palavra] then return 0 end
return categoria
end
-- No modo 10+, prioriza 10–12; depois 13+; por último, palavras curtas.
local function faixaLonga(w)
if #w < 10 then return 0 end
if #w <= 12 then return 2 end
return 1
end
local function ordenarCandidatos(matches, idioma, termo)
local permitido = extrasPermitidos(termo)
local estrategiaNoMomento, finaisNoMomento, trioNoMomento, petNoMomento = estrategiaAtiva, modoFinais, trioAtivo and permitido, permitido and modoPet or 0
local longasNoMomento = modoLongas
local function sequenciaPet(w)
for i = 1, #w - (petNoMomento == 1 and 2 or 1) do
local a, b = w:byte(i, i + 1)
if a >= 97 and a < 122 and b == a + 1 then return 1 end
end
return 0
end
local notas = {}
for i, palavra in ipairs(matches) do
-- Na ordenação só se usa o primeiro valor: calcular os contadores de
-- respostas aqui seria trabalho descartado para cada candidata.
local peso = bancoEliteSet[palavra] and 20 or 0
local confianca = 1
local categoria = petNoMomento == 2 and 0 or finalPriorizavel(palavra, idioma, finaisNoMomento, trioNoMomento)
if idioma == "EN" then
local comum, confirmado = CommonWordsEN[palavra] == true or recuperados[2].Set[palavra] == true or recuperados[3].Set[palavra] == true, bEN.Set[palavra] == true or recuperados[4].Set[palavra] == true
if comum and confirmado then confianca = 3
elseif comum or (bancoEliteSet[palavra] and confirmado) then confianca = 2 end
elseif bancoPTCurado[palavra] then
confianca = 2
end
notas[palavra] = {peso, confianca, categoria, estrategiaNoMomento and estimarRespostas(palavra) or 0, petNoMomento > 0 and sequenciaPet(palavra) or 0}
if i % 3000 == 0 then progressoBusca = os.clock(); task.wait() end
end
local function antes(a, b)
local pa, pb = notas[a], notas[b]
if longasNoMomento and faixaLonga(a) ~= faixaLonga(b) then return faixaLonga(a) > faixaLonga(b) end
if petNoMomento == 1 and (pa[3] > 0) ~= (pb[3] > 0) then return pa[3] > 0 end
if petNoMomento == 1 and (pa[3] == 3) ~= (pb[3] == 3) then return pa[3] == 3 end
if petNoMomento > 0 and pa[5] ~= pb[5] then return pa[5] > pb[5] end
if (#a >= 4) ~= (#b >= 4) then return #a >= 4 end
if (pa[3] > 0) ~= (pb[3] > 0) then return pa[3] > 0 end
if (pa[3] == 3) ~= (pb[3] == 3) then return pa[3] == 3 end
local ca, cb = palavraCurtaConfiavel(a, idioma), palavraCurtaConfiavel(b, idioma)
if estrategiaNoMomento then
-- A estimativa só supera a diferença entre níveis de confiança quando ambas
-- as palavras têm evidência mínima; dados ausentes nunca significam vitória.
local seguraA, seguraB = pa[2] >= 2, pb[2] >= 2
if seguraA ~= seguraB then return seguraA end
if seguraA then
if pa[2] ~= pb[2] then return pa[2] > pb[2] end
if ca ~= cb then return ca end
if pa[4] ~= pb[4] then return pa[4] < pb[4] end
end
end
if pa[2] ~= pb[2] then return pa[2] > pb[2] end
if ca ~= cb then return ca end
if estrategiaNoMomento and pa[4] ~= pb[4] then return pa[4] < pb[4] end
if pa[3] ~= pb[3] then return pa[3] > pb[3] end
if #a ~= #b then return #a < #b end
if pa[1] ~= pb[1] then return pa[1] > pb[1] end
return a < b
end
if #matches <= 20000 then
 table.sort(matches, antes)
else
 -- Ordenar em blocos permite ceder entre etapas nas buscas muito grandes.
 local blocos = {}
 for inicio = 1, #matches, 4000 do
  local bloco = {}
  for i = inicio, math.min(inicio + 3999, #matches) do bloco[#bloco+1] = matches[i] end
  table.sort(bloco, antes); blocos[#blocos+1] = bloco
  progressoBusca = os.clock(); task.wait()
 end
 while #blocos > 1 do
  local proximos = {}
  for i = 1, #blocos, 2 do
   local a, b = blocos[i], blocos[i+1]
   if not b then proximos[#proximos+1] = a else
    local unido, x, y = {}, 1, 1
    while x <= #a and y <= #b do
     if antes(a[x], b[y]) then unido[#unido+1] = a[x]; x = x + 1 else unido[#unido+1] = b[y]; y = y + 1 end
     if #unido % 5000 == 0 then progressoBusca = os.clock(); task.wait() end
    end
    while x <= #a do unido[#unido+1] = a[x]; x = x + 1; if #unido % 5000 == 0 then progressoBusca = os.clock(); task.wait() end end
    while y <= #b do unido[#unido+1] = b[y]; y = y + 1; if #unido % 5000 == 0 then progressoBusca = os.clock(); task.wait() end end
    proximos[#proximos+1] = unido
   end
  end
  blocos = proximos
 end
 for i, w in ipairs(blocos[1]) do
  matches[i] = w
  if i % 5000 == 0 then progressoBusca = os.clock(); task.wait() end
 end
end
end
local destinoPreferido
pcall(function() if type(gethui) == "function" then destinoPreferido = gethui() end end)
for _, raiz in ipairs({destinoPreferido or CoreGui, CoreGui, player:WaitForChild("PlayerGui")}) do
pcall(function()
local antiga = raiz:FindFirstChild("WordSystemProV43")
if antiga then antiga:Destroy() end
end)
end
local gui = Instance.new("ScreenGui")
gui.Name = "WordSystemProV43"
gui.ResetOnSpawn = false
gui.Enabled = true
gui.DisplayOrder = 999999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local sucess = false
if destinoPreferido then sucess = pcall(function() gui.Parent = destinoPreferido end) end
if not sucess then sucess = pcall(function() gui.Parent = CoreGui end) end
if not sucess then gui.Parent = player:WaitForChild("PlayerGui") end
local PANEL_W = 220
local PANEL_H = 360
local PANEL_W_GRANDE = 350
local PANEL_H_GRANDE = 286
local tamanhoIndice = 2
local tamanhosPainel = {190, 220, 350}
local opcoesAbertas = true
local filtrosAbertos = false
local isMinimized = false
local painel
local main = Instance.new("Frame", gui)
main.Name = "Main"
main.Size = UDim2.new(0, PANEL_W, 0, PANEL_H)
main.Position = UDim2.new(0.5, -110, 0.5, -81)
main.BackgroundColor3 = Color3.fromRGB(10, 14, 20)
main.Active = true
local mainCorner = Instance.new("UICorner", main)
mainCorner.CornerRadius = UDim.new(0, 10)
local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color = Color3.fromRGB(0, 180, 255)
mainStroke.Thickness = 1.5
local grad = Instance.new("UIGradient", main)
grad.Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 18, 28)),
ColorSequenceKeypoint.new(1, Color3.fromRGB(4, 8, 14)),
})
grad.Rotation = 135
local titleBar = Instance.new("Frame", main)
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 32)
titleBar.BackgroundColor3 = Color3.fromRGB(12, 22, 34)
titleBar.ZIndex = 11
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)
local titleFix = Instance.new("Frame", titleBar)
titleFix.Size = UDim2.new(1, 0, 0, 10)
titleFix.Position = UDim2.new(0, 0, 1, -10)
titleFix.BackgroundColor3 = Color3.fromRGB(12, 22, 34)
titleFix.BorderSizePixel = 0
titleFix.ZIndex = 11
local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Size = UDim2.new(1, -150, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "⚡ OVERLORD"
titleLabel.TextColor3 = Color3.fromRGB(0, 220, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 11
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
local revisarBtn = Instance.new("TextButton", titleBar)
revisarBtn.Name = "Revisar"
revisarBtn.Size = UDim2.new(0, 34, 0, 18)
revisarBtn.Position = UDim2.new(1, -134, 0.5, -9)
revisarBtn.BackgroundColor3 = Color3.fromRGB(30, 60, 80)
revisarBtn.Text = "VER"
revisarBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
revisarBtn.Font = Enum.Font.GothamBold
revisarBtn.TextSize = 10
revisarBtn.ZIndex = 14
Instance.new("UICorner", revisarBtn).CornerRadius = UDim.new(0, 4)
local langBtn = Instance.new("TextButton", titleBar)
langBtn.Name = "LangToggle"
langBtn.Size = UDim2.new(0, 42, 0, 18)
langBtn.Position = UDim2.new(1, -96, 0.5, -9)
langBtn.BackgroundColor3 = Color3.fromRGB(15, 35, 55)
langBtn.Text = "PT"
langBtn.TextColor3 = Color3.fromRGB(100, 220, 255)
langBtn.Font = Enum.Font.GothamBold
langBtn.TextSize = 10
langBtn.ZIndex = 14
Instance.new("UICorner", langBtn).CornerRadius = UDim.new(0, 4)
local langStroke = Instance.new("UIStroke", langBtn)
langStroke.Color = Color3.fromRGB(0, 150, 255)
local resizeBtn = Instance.new("TextButton", titleBar)
resizeBtn.Size = UDim2.new(0, 24, 0, 20)
resizeBtn.Position = UDim2.new(1, -48, 0.5, -10)
resizeBtn.BackgroundTransparency = 1
resizeBtn.Text = "📐"
resizeBtn.TextColor3 = Color3.fromRGB(0, 180, 255)
resizeBtn.Font = Enum.Font.GothamBold
resizeBtn.TextSize = 12
resizeBtn.ZIndex = 13
local minBtn = Instance.new("TextButton", titleBar)
minBtn.Size = UDim2.new(0, 24, 0, 20)
minBtn.Position = UDim2.new(1, -24, 0.5, -10)
minBtn.BackgroundTransparency = 1
minBtn.Text = "▼"
minBtn.TextColor3 = Color3.fromRGB(0, 180, 255)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 11
minBtn.ZIndex = 13
local countLabel = Instance.new("TextLabel", main)
countLabel.Name = "Count"
countLabel.Size = UDim2.new(0, 60, 0, 14)
countLabel.Position = UDim2.new(1, -67, 0, 44)
countLabel.BackgroundTransparency = 1
countLabel.Text = "0 disp."
countLabel.TextColor3 = Color3.fromRGB(80, 120, 150)
countLabel.Font = Enum.Font.Gotham
countLabel.TextSize = 9
countLabel.TextXAlignment = Enum.TextXAlignment.Right
local inputFrame = Instance.new("Frame", main)
inputFrame.Size = UDim2.new(1, -14, 0, 28)
inputFrame.Position = UDim2.new(0, 7, 0, 37)
inputFrame.BackgroundColor3 = Color3.fromRGB(12, 18, 26)
inputFrame.ZIndex = 11
Instance.new("UICorner", inputFrame).CornerRadius = UDim.new(0, 7)
local inputStroke = Instance.new("UIStroke", inputFrame)
inputStroke.Color = Color3.fromRGB(0, 120, 200)
inputStroke.Thickness = 1
inputBox = Instance.new("TextBox", inputFrame)
inputBox.Name = "InputBox"
inputBox.Size = UDim2.new(1, -115, 1, 0)
inputBox.Position = UDim2.new(0, 10, 0, 0)
inputBox.BackgroundTransparency = 1
inputBox.PlaceholderText = "Baixando bases..."
inputBox.PlaceholderColor3 = Color3.fromRGB(60, 90, 120)
inputBox.Text = ""
inputBox.TextColor3 = Color3.fromRGB(200, 240, 255)
inputBox.Font = Enum.Font.Gotham
inputBox.TextSize = 12
inputBox.TextXAlignment = Enum.TextXAlignment.Left
inputBox.ClearTextOnFocus = false
local autoBtn = Instance.new("TextButton", inputFrame)
autoBtn.Size = UDim2.new(0, 35, 0, 22)
autoBtn.Position = UDim2.new(1, -63, 0.5, -11)
autoBtn.Text = "⚡AUTO"
autoBtn.BackgroundColor3 = Color3.fromRGB(0, 80, 120)
autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
autoBtn.Font = Enum.Font.GothamBold
autoBtn.TextSize = 9
autoBtn.ZIndex = 13
Instance.new("UICorner", autoBtn).CornerRadius = UDim.new(0, 4)
local autoStroke = Instance.new("UIStroke", autoBtn)
autoStroke.Color = Color3.fromRGB(0, 200, 255)
local clearBtn = Instance.new("TextButton", inputFrame)
clearBtn.Size = UDim2.new(0, 22, 0, 22)
clearBtn.Position = UDim2.new(1, -25, 0.5, -11)
clearBtn.Text = "✕"
clearBtn.BackgroundTransparency = 1
clearBtn.TextColor3 = Color3.fromRGB(80, 130, 180)
clearBtn.Font = Enum.Font.GothamBold
clearBtn.TextSize = 11
clearBtn.ZIndex = 13
local wordDisplay = Instance.new("Frame", main)
wordDisplay.Size = UDim2.new(1, -14, 0, 40)
wordDisplay.Position = UDim2.new(0, 7, 0, 71)
wordDisplay.BackgroundColor3 = Color3.fromRGB(8, 12, 18)
wordDisplay.ZIndex = 11
Instance.new("UICorner", wordDisplay).CornerRadius = UDim.new(0, 7)
local wordStroke = Instance.new("UIStroke", wordDisplay)
wordStroke.Color = Color3.fromRGB(0, 160, 240)
wordStroke.Thickness = 1
local wordLabel = Instance.new("TextLabel", wordDisplay)
wordLabel.Name = "WordLabel"
wordLabel.Size = UDim2.new(1, -10, 0.6, 0)
wordLabel.Position = UDim2.new(0, 5, 0.05, 0)
wordLabel.BackgroundTransparency = 1
wordLabel.Text = "CONECTANDO..."
wordLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
wordLabel.Font = Enum.Font.GothamBold
wordLabel.TextSize = 14
local infoLabel = Instance.new("TextLabel", wordDisplay)
infoLabel.Name = "IndexLabel"
infoLabel.Size = UDim2.new(1, -10, 0.35, 0)
infoLabel.Position = UDim2.new(0, 5, 0.62, 0)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "Filtro Ativo"
infoLabel.TextColor3 = Color3.fromRGB(100, 150, 180)
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 9
local function makeBtn(text, posX, posY, w, h, color)
local frame = Instance.new("Frame", main)
frame.Size = UDim2.new(0, w, 0, h)
frame.Position = UDim2.new(0, posX, 0, posY)
frame.BackgroundColor3 = color
frame.ZIndex = 11
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 7)
local btn = Instance.new("TextButton", frame)
btn.Size = UDim2.new(1, 0, 1, 0)
btn.BackgroundTransparency = 1
btn.Text = text
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 10
btn.ZIndex = 12
return btn, frame
end
local GAP = 6
local BTN_Y = 117
local BTN_H = 22
local TOTAL_W = PANEL_W - 14
local BTN_W = math.floor((TOTAL_W - GAP * 2) / 3)
local prevBtn, _ = makeBtn("◀ PREV", GAP, BTN_Y, BTN_W, BTN_H, Color3.fromRGB(20, 35, 50))
local useBtn, useBtnFrame = makeBtn("✓ USAR", GAP + BTN_W + GAP, BTN_Y, BTN_W, BTN_H, Color3.fromRGB(0, 100, 160))
local nextBtn, _ = makeBtn("NEXT ▶", GAP + (BTN_W + GAP) * 2, BTN_Y, BTN_W, BTN_H, Color3.fromRGB(20, 35, 50))
local resetBtn, _ = makeBtn("🔄 RESET", GAP, BTN_Y + BTN_H + GAP, TOTAL_W, BTN_H, Color3.fromRGB(40, 20, 30))
local opcoesBtn = makeBtn("OPÇÕES ▼", 0, BTN_Y + BTN_H + GAP, 55, BTN_H, Color3.fromRGB(20, 45, 60))
local function atualizarDimensoes()
local w = tamanhosPainel[tamanhoIndice]
local h = isMinimized and 32 or (opcoesAbertas and PANEL_H or 172)
main.Size = UDim2.new(0, w, 0, h)
local total = w - 14
local bw = math.floor((total - GAP * 2) / 3)
for _, frame in ipairs({prevBtn.Parent, useBtnFrame, nextBtn.Parent}) do frame.Size = UDim2.new(0, bw, 0, BTN_H) end
prevBtn.Parent.Position = UDim2.new(0, GAP, 0, BTN_Y)
useBtnFrame.Position = UDim2.new(0, GAP + bw + GAP, 0, BTN_Y)
nextBtn.Parent.Position = UDim2.new(0, GAP + (bw + GAP) * 2, 0, BTN_Y)
resetBtn.Parent.Position = UDim2.new(0, GAP, 0, BTN_Y + BTN_H + GAP)
resetBtn.Parent.Size = UDim2.new(0, total - 61, 0, BTN_H)
opcoesBtn.Parent.Position = UDim2.new(0, GAP + total - 55, 0, BTN_Y + BTN_H + GAP)
opcoesBtn.Text = opcoesAbertas and "OPÇÕES ▲" or "OPÇÕES ▼"
if painel then painel.Visible = opcoesAbertas and not isMinimized end
end
local function toggleSize()
tamanhoIndice = tamanhoIndice % #tamanhosPainel + 1
atualizarDimensoes()
end
opcoesBtn.MouseButton1Click:Connect(function()
opcoesAbertas = not opcoesAbertas
atualizarDimensoes()
end)
atualizarDimensoes()
resizeBtn.MouseButton1Click:Connect(toggleSize)
local function findTargetGui()
local pg = player:FindFirstChild("PlayerGui")
for _, container in ipairs({pg or CoreGui, CoreGui}) do
for _, child in ipairs(container:GetChildren()) do
local top = child:FindFirstChild("TopBar")
if child:IsA("ScreenGui") and child ~= gui and top and top:FindFirstChild("AnswerInput") then return child end
end
end
return nil
end
local ultimoTermoPesquisado = nil
local current = {}
local index = 1
local searchThread = nil
local idiomaResultados = idiomaAtivo
local function encaixaBusca(palavra, termo, modoAtual, temporario)
if termo == "" then return modoAtual == "CONTEM" and finalPermitido(palavra, temporario) end
if string.sub(palavra, 1, #termo) == termo then return finalPermitido(palavra, temporario) end
return modoAtual == "CONTEM" and string.find(palavra, termo, 1, true) ~= nil and finalPermitido(palavra, temporario)
end
-- Compactação linear evita table.remove repetido em listas grandes.
local function filtrarCandidatos(matches, temporario, prefixoFixo)
local tamanho, destino = #matches, 1
for i = 1, tamanho do
local w = matches[i]
if not usedWords[w] and finalPermitido(w, temporario)
and (not prefixoFixo or prefixoFixo == "" or w:sub(1, #prefixoFixo) == prefixoFixo) then
matches[destino] = w; destino = destino + 1
end
if i % 10000 == 0 then progressoBusca = os.clock(); task.wait() end
end
for i = destino, tamanho do
matches[i] = nil
if i % 10000 == 0 then progressoBusca = os.clock(); task.wait() end
end
end
local function inicioPrefixo(lista, termo)
local esquerda, direita = 1, #lista + 1
while esquerda < direita do
local meio = math.floor((esquerda + direita) / 2)
if lista[meio] < termo then esquerda = meio + 1 else direita = meio end
end
return esquerda
end
local function varrerDicionarioComPrioridade(idioma, termo, modoAtual, limitePrefixo, limiteContem, matches, viciadosInseridos, temporario)
if idioma ~= "EN" then return false end
local loopCounter = 0
local listas = {
{ nome = "Prioritario", lista = bPR.List },
{ nome = "Extra", lista = DicionarioENExtra.List },
{ nome = "ENABLE", lista = bEN.List }
}
for _, bloco in ipairs(listas) do
if #bloco.lista > 0 then
local primeiro = modoAtual == "PREFIXO" and termo ~= "" and inicioPrefixo(bloco.lista, termo) or 1
for i = primeiro, #bloco.lista do
local w = bloco.lista[i]
if modoAtual == "PREFIXO" and termo ~= "" and w:sub(1, #termo) ~= termo then break end
if not usedWords[w] and not listaNegra[w] and not viciadosInseridos[w] and encaixaBusca(w, termo, modoAtual, temporario) then
table.insert(matches, w)
viciadosInseridos[w] = true
rawset(viciadosInseridos, w .. "_fonte", bloco.nome)
if #matches >= limitePrefixo then return true end
end
loopCounter = loopCounter + 1
if loopCounter % 25000 == 0 then progressoBusca = os.clock(); task.wait() end
end
end
end
return false
end
local function varrerDicionarioTradicional(idioma, termo, modoAtual, limitePrefixo, limiteContem, matches, viciadosInseridos, temporario)
local loopCounter = 0
local lenTermo = #termo
local lista = bancos[idioma].List
if lenTermo > 0 then
for i = inicioPrefixo(lista, termo), #lista do
local w = lista[i]
if w:sub(1, lenTermo) ~= termo then break end
if not usedWords[w] and not listaNegra[w] and not viciadosInseridos[w] and finalPermitido(w, temporario) then
table.insert(matches, w); viciadosInseridos[w] = true
if #matches >= limitePrefixo then break end
end
loopCounter = loopCounter + 1
if loopCounter % 25000 == 0 then progressoBusca = os.clock(); task.wait() end
end
end
if lenTermo == 0 or modoAtual == "CONTEM" then
for i = 1, #lista do
local w = lista[i]
if not usedWords[w] and not listaNegra[w] and not viciadosInseridos[w] then
local isPrefix = (lenTermo > 0 and string.sub(w, 1, lenTermo) == termo)
if not isPrefix and (lenTermo == 0 or string.find(w, termo, 1, true)) and finalPermitido(w, temporario) then
table.insert(matches, w); viciadosInseridos[w] = true
if #matches >= limiteContem then break end
end
end
loopCounter = loopCounter + 1
if loopCounter % 25000 == 0 then progressoBusca = os.clock(); task.wait() end
end
end
end
-- Pesquisa ambos os idiomas respeitando a memória e o prefixo fixo.
-- Finais desligados continuam válidos, sem prioridade especial.
local function buscarAlternativas(termo, modoAtual, idiomaPreferido, prefixoFixo, temporario, somenteIdioma, semOrdenar)
prefixoFixo = prefixoFixo or ""
local curtas, idiomaCurtas, fontesCurtas
for tentativaIdioma = 1, (not somenteIdioma and termo ~= "" and 2 or 1) do
local idioma = tentativaIdioma == 1 and idiomaPreferido or (idiomaPreferido == "EN" and "PT" or "EN")
local matches, fontes = {}, {}
if #termo > 0 then
for _, w in ipairs(bancoEliteGlobal) do
if bancos[idioma].Set[w] and #w >= 3 and not usedWords[w] and not listaNegra[w]
and encaixaBusca(w, termo, modoAtual, temporario) and not fontes[w] then
matches[#matches+1] = w; fontes[w] = true; fontes[w .. "_fonte"] = "ELITE"
end
end
end
if idioma == "EN" then
varrerDicionarioComPrioridade("EN", termo, modoAtual, math.huge, math.huge, matches, fontes, temporario)
else
varrerDicionarioTradicional("PT", termo, modoAtual, math.huge, math.huge, matches, fontes, temporario)
end
for numero, recuperado in ipairs(recuperados) do
if recuperado.pronto and ((idioma == "PT" and numero == 1) or (idioma == "EN" and numero > 1)) then
local visitas = 0
local function varrerRecuperado(lista)
if not lista then return end
for _, w in ipairs(lista) do
if not usedWords[w] and not fontes[w] and not listaNegra[w] and encaixaBusca(w, termo, modoAtual, temporario) then
matches[#matches+1] = w; fontes[w] = true; fontes[w .. "_fonte"] = "PRINCIPAL RECUPERADO"
end
visitas = visitas + 1
if visitas % 10000 == 0 then progressoBusca = os.clock(); task.wait() end
end
end
if modoAtual == "PREFIXO" and #termo >= 2 then
varrerRecuperado(recuperado.Buckets[termo:sub(1, 2)])
else
for chave, lista in pairs(recuperado.Buckets) do
if modoAtual ~= "PREFIXO" or termo == "" or chave:sub(1, 1) == termo:sub(1, 1) then varrerRecuperado(lista) end
end
end
end
end
filtrarCandidatos(matches, temporario, prefixoFixo)
if #matches > 0 then
-- O seletor examina todos os candidatos com seu próprio comparador.
-- A interface e as pesquisas normais continuam recebendo a lista ordenada.
if not (somenteIdioma and semOrdenar) then ordenarCandidatos(matches, idioma, termo) end
filtrarCandidatos(matches, temporario)
if #matches > 0 then
if not modoLongas or faixaLonga(matches[1]) == 2 then return matches, idioma, fontes end
if not curtas or faixaLonga(matches[1]) > faixaLonga(curtas[1]) then curtas, idiomaCurtas, fontesCurtas = matches, idioma, fontes end
end
end
end
return curtas or {}, idiomaCurtas or idiomaPreferido, fontesCurtas or {}
end
local function buscarAlternativasEstavel(termo, modoAtual, idiomaPreferido, prefixoFixo, temporario)
local revisao, versaoBanco, matches, idioma, fontes
repeat
revisao, versaoBanco = revisaoFiltros, revisaoBancos
matches, idioma, fontes = buscarAlternativas(termo, modoAtual, idiomaPreferido, prefixoFixo, temporario)
until revisao == revisaoFiltros and versaoBanco == revisaoBancos
return matches, idioma, fontes
end
-- Os bancos extras só são consultados quando os dois bancos principais se esgotam.
local function buscarNasReservas(termo, modoAtual, idiomaPreferido, prefixoFixo, temporario, somenteIdioma, semOrdenar)
local curtas, idiomaCurtas, fontesCurtas
for tentativa = 1, (somenteIdioma and 1 or 2) do
local idioma = tentativa == 1 and idiomaPreferido or (idiomaPreferido == "EN" and "PT" or "EN")
local reserva = bancosReserva[idioma]
local matches, fontes, visitas = {}, {}, 0
local function varrer(lista)
if not lista then return end
for _, w in ipairs(lista) do
if not usedWords[w] and not fontes[w] and not listaNegra[w]
and (not prefixoFixo or prefixoFixo == "" or w:sub(1, #prefixoFixo) == prefixoFixo)
and encaixaBusca(w, termo, modoAtual, temporario) then
matches[#matches+1] = w; fontes[w] = true; fontes[w .. "_fonte"] = "RESERVA"
end
visitas = visitas + 1
if visitas % 10000 == 0 then progressoBusca = os.clock(); task.wait() end
end
end
if reserva.pronto then
if modoAtual == "PREFIXO" and #termo >= 2 then
varrer(reserva.Buckets[termo:sub(1, 2)])
else
for chave, lista in pairs(reserva.Buckets) do
if modoAtual ~= "PREFIXO" or termo == "" or chave:sub(1, 1) == termo:sub(1, 1) then varrer(lista) end
end
end
end
if #matches > 0 then
-- O seletor examina todos os candidatos com seu próprio comparador.
-- A interface e as pesquisas normais continuam recebendo a lista ordenada.
if not (somenteIdioma and semOrdenar) then ordenarCandidatos(matches, idioma, termo) end
filtrarCandidatos(matches, temporario)
if #matches > 0 then
if not modoLongas or faixaLonga(matches[1]) == 2 then return matches, idioma, fontes end
if not curtas or faixaLonga(matches[1]) > faixaLonga(curtas[1]) then curtas, idiomaCurtas, fontesCurtas = matches, idioma, fontes end
end
end
end
return curtas or {}, idiomaCurtas or idiomaPreferido, fontesCurtas or {}
end
local function buscarComExcecao(termo, modoAtual, idioma, prefixoFixo)
local revisao, versaoBanco, matches, lingua, fontes, temporario
repeat
revisao, versaoBanco = revisaoFiltros, revisaoBancos
temporario = false
matches, lingua, fontes = buscarAlternativasEstavel(termo, modoAtual, idioma, prefixoFixo)
if #matches == 0 and termo ~= "" then
matches, lingua, fontes = buscarNasReservas(termo, modoAtual, idioma, prefixoFixo, false)
end
until revisao == revisaoFiltros and versaoBanco == revisaoBancos
return matches, lingua, fontes, temporario
end
local geracaoPesquisa = 0
local function updateDisplay()
-- Uma pesquisa anterior pode continuar caso o cancelamento não funcione.
-- Apenas a geração mais recente tem permissão para publicar resultados.
geracaoPesquisa = geracaoPesquisa + 1
local minhaGeracao = geracaoPesquisa
if not databaseLoaded then
wordLabel.Text = "CARREGANDO..."
infoLabel.Text = loadingStatusText
countLabel.Text = "0"
return
end
if searchThread then pcall(task.cancel, searchThread); searchThread = nil end
local entradaAtual = (inputBox.Text or ""):lower():gsub("%s", "")
if entradaAtual == "" then
current = {}; currentRelaxado = false; index = 1; ultimoTermoPesquisado = ""
wordLabel.Text = "aguardando início"; wordLabel.TextColor3 = Color3.fromRGB(200, 240, 255)
infoLabel.Text = "Digite ou aguarde o início"; countLabel.Text = "0 disp."
wordStroke.Color = Color3.fromRGB(100, 100, 100)
return
end
ultimoTermoPesquisado = nil
progressoBusca = os.clock()
wordLabel.Text = "..."
wordStroke.Color = Color3.fromRGB(100, 100, 100)
searchThread = task.spawn(function()
local termo = entradaAtual
local idiomaPreferido = termo:sub(1, 1) == "x" and "EN" or idiomaAtivo
local matches, idiomaUtilizado, viciadosInseridos, filtrosTemporarios = buscarComExcecao(termo, modoBusca, idiomaPreferido)
if minhaGeracao ~= geracaoPesquisa or not gui.Parent or (inputBox.Text or ""):lower():gsub("%s", "") ~= termo then return end
currentRelaxado, currentRevisao, currentRevisaoBancos = filtrosTemporarios, revisaoFiltros, revisaoBancos
resgateBuscaTermo, resgatesBusca = nil, 0
current = matches
ultimoTermoPesquisado = termo
idiomaResultados = idiomaUtilizado
index = math.min(index, math.max(1, #current))
if #current == 0 then
wordLabel.Text = "sem palavras"
wordLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
infoLabel.Text = not reservasFinalizadas and "Carregando bancos extras..." or (filtrosTemporarios and "Sem palavras, mesmo com exceção" or ("Nenhum encaixe válido [" .. modoBusca .. "]"))
wordStroke.Color = Color3.fromRGB(180, 30, 30)
else
wordLabel.Text = current[index]:upper()
wordLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
local _, respostas2, respostas3 = calcularPesoPalavra(current[index], idiomaUtilizado, termo)
local langName = (idiomaUtilizado == "PT") and "Português" or "Inglês"
local fonte = rawget(viciadosInseridos, current[index] .. "_fonte") or ""
local fonteLabel = (fonte ~= "") and " [" .. fonte .. "]" or ""
local detalhe = "2L:" .. respostas2 .. " 3L:" .. respostas3
if estrategiaAtiva then
local estimativa = estimarRespostas(current[index])
detalhe = "respostas estim.: " .. (estimativa == math.huge and "?" or tostring(math.floor(estimativa)))
end
if modoFinais ~= "NENHUM" and (modoPet ~= 2 or not extrasPermitidos(termo)) then
local temFinal = false
for _, w in ipairs(current) do
if finalPriorizavel(w, idiomaUtilizado, modoFinais) > 0 then temFinal = true; break end
end
if not temFinal then detalhe = "sem final prioritário" end
end
infoLabel.Text = index .. " / " .. #current .. " (" .. langName .. fonteLabel .. ") " .. (filtrosTemporarios and "exceção temporária de filtros" or detalhe)
wordStroke.Color = Color3.fromRGB(0, 200, 255)
end
countLabel.Text = #current .. " disp."
end)
end
local function setIdioma(novoIdioma)
if idiomaAtivo == novoIdioma then return end
idiomaAtivo = novoIdioma
langBtn.Text = idiomaAtivo
langBtn.BackgroundColor3 = idiomaAtivo == "PT" and Color3.fromRGB(15, 35, 55) or Color3.fromRGB(35, 25, 45)
langBtn.TextColor3 = idiomaAtivo == "PT" and Color3.fromRGB(100, 220, 255) or Color3.fromRGB(255, 180, 255)
index = 1
updateDisplay()
end
langBtn.MouseButton1Click:Connect(function() travaIdiomaManual = true; setIdioma(idiomaAtivo == "PT" and "EN" or "PT") end)
task.spawn(function()
local urls = {
PT = "https://www.ime.usp.br/~pf/dicios/br-sem-acentos.txt",
EN = {
"https://raw.githubusercontent.com/first20hours/google-10000-english/master/google-10000-english-no-swears.txt",
"https://raw.githubusercontent.com/first20hours/google-10000-english/master/20k.txt",
"https://raw.githubusercontent.com/dolph/dictionary/master/enable1.txt",
}
}
local function verificarQualidadePalavra(clean)
if #clean < 3 or #clean > 18 then return false end
if not string.match(clean, "^[a-z]+$") then return false end
if not string.match(clean, "[aeiouy]") then return false end
if string.match(clean, "^xl[ivx]*$") or string.match(clean, "^xk[a-z]*$") then return false end
if listaNegra[clean] then return false end
return true
end
local function inserirPalavra(idioma, clean, marcarComumEN, tipo)
if idioma == "EN" then
if tipo == "prioritario" then
if not bPR.Set[clean] then
bPR.Set[clean] = true
table.insert(bPR.List, clean)
end
elseif tipo == "enable" then
if not bEN.Set[clean] then
bEN.Set[clean] = true
table.insert(bEN.List, clean)
end
elseif tipo == "extra" then
if not DicionarioENExtra.Set[clean] then
DicionarioENExtra.Set[clean] = true
table.insert(DicionarioENExtra.List, clean)
end
end
end
if not bancos[idioma].Set[clean] then
bancos[idioma].Set[clean] = true
table.insert(bancos[idioma].List, clean)
end
if idioma == "EN" and marcarComumEN then CommonWordsEN[clean] = true end
end
local function carregarTextoNoDicionario(texto, idioma, marcarComumEN, tipo, separador)
separador = separador or "\r\n"
local c = 0
for word in string.gmatch(texto, "[^" .. separador .. "]+") do
local clean = word:lower():gsub("%s", "")
if verificarQualidadePalavra(clean) then
inserirPalavra(idioma, clean, marcarComumEN, tipo)
end
c = c + 1
if c % 35000 == 0 then task.wait() end
end
end
for _, w in ipairs(bancoEmergenciaPT) do if verificarQualidadePalavra(w) then inserirPalavra("PT", w, false, nil) end end
for _, w in ipairs(bancoEmergenciaEN) do if verificarQualidadePalavra(w) then inserirPalavra("EN", w, false, "prioritario") end end
loadingStatusText = "Buscando bancos principais..."
updateDisplay()
fontesRede = {
{url = urls.PT, linguaFonte = "PT"},
{url = urls.EN[1], linguaFonte = "EN", tipo = "prioritario", comum = true},
{url = urls.EN[2], linguaFonte = "EN", tipo = "extra", comum = true},
{url = urls.EN[3], linguaFonte = "EN", tipo = "enable"}
}
for _, item in ipairs(fontesRede) do baixarPrincipal(item) end
local prazoRede = os.clock() + 2
repeat
local todas = true
for _, item in ipairs(fontesRede) do if not item.terminou then todas = false; break end end
if todas then break end
task.wait(0.05)
until os.clock() >= prazoRede
for _, item in ipairs(fontesRede) do
if item.terminou and item.ok then
carregarTextoNoDicionario(item.texto, item.linguaFonte, item.comum, item.tipo)
item.texto = nil; item.consumido = true
end
end
table.sort(bancos.PT.List)
table.sort(bancos.EN.List)
table.sort(bPR.List)
table.sort(DicionarioENExtra.List)
-- A busca binária também exige o ENABLE em ordem: não presumir que a fonte
-- externa continuará ordenada. Evita ordenar novamente quando já está em ordem.
for i = 2, #bEN.List do
if bEN.List[i] < bEN.List[i - 1] then table.sort(bEN.List); break end
if i % 30000 == 0 then task.wait() end
end
rebuildPrefixStats()
databaseLoaded = true
inputBox.PlaceholderText = "Sílaba ativa..."
updateDisplay()
task.wait(1)
local function countWordsWithPrefix(lista, prefixo)
local count = 0
for _, w in ipairs(lista) do
if string.sub(w, 1, #prefixo) == prefixo then count = count + 1 end
end
return count
end
print("🔍 DIAGNÓSTICO DE PALAVRAS COM PREFIXO 'ly':")
print("   Prioritário (10k): " .. countWordsWithPrefix(bPR.List, "ly"))
print("   Extra (20k): " .. countWordsWithPrefix(DicionarioENExtra.List, "ly"))
print("   TOTAL (incluindo emergência): " .. countWordsWithPrefix(bancos.EN.List, "ly"))
print("🔍 DIAGNÓSTICO DE PALAVRAS COM PREFIXO 'ny':")
print("   TOTAL: " .. countWordsWithPrefix(bancos.EN.List, "ny"))
print("🔍 DIAGNÓSTICO DE PALAVRAS COM PREFIXO 'ty':")
print("   TOTAL: " .. countWordsWithPrefix(bancos.EN.List, "ty"))
print("🔍 DIAGNÓSTICO DE PALAVRAS COM PREFIXO 'tl':")
print("   TOTAL: " .. countWordsWithPrefix(bancos.EN.List, "tl"))
end)
local dragging, dragStart, startPos = false, nil, nil
titleBar.InputBegan:Connect(function(i)
if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
dragging = true; dragStart = i.Position; startPos = main.Position
end
end)
titleBar.InputEnded:Connect(function(i)
if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)
UserInputService.InputChanged:Connect(function(i)
if not gui.Parent then return end
if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
local d = i.Position - dragStart
main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
end
end)
minBtn.MouseButton1Click:Connect(function()
isMinimized = not isMinimized
minBtn.Text = isMinimized and "▶" or "▼"
for _, child in ipairs(main:GetChildren()) do
if child:IsA("GuiObject") and child ~= titleBar then child.Visible = not isMinimized end
end
atualizarDimensoes()
end)
local searchToken = 0
inputBox:GetPropertyChangedSignal("Text"):Connect(function()
geracaoPesquisa = geracaoPesquisa + 1
ultimoTermoPesquisado = nil
searchToken = searchToken + 1
local currentToken = searchToken
task.wait(0.075)
if currentToken == searchToken then index = 1; updateDisplay() end
end)
prevBtn.MouseButton1Click:Connect(function()
if #current == 0 then return end
index = ((index - 2) % #current) + 1
wordLabel.Text = current[index]:upper()
infoLabel.Text = index .. " / " .. #current .. " (" .. (idiomaResultados == "PT" and "Português" or "Inglês") .. ")"
end)
nextBtn.MouseButton1Click:Connect(function()
if #current == 0 then return end
index = index % #current + 1
wordLabel.Text = current[index]:upper()
infoLabel.Text = index .. " / " .. #current .. " (" .. (idiomaResultados == "PT" and "Português" or "Inglês") .. ")"
end)
clearBtn.MouseButton1Click:Connect(function() inputBox.Text = ""; index = 1; updateDisplay() end)
local function registrarPalavraNaMemoria(palavra)
if palavra and palavra ~= "" then
local lowWord = palavra:lower()
if not usedWords[lowWord] then
marcarUsada(lowWord)
local orig = useBtnFrame.BackgroundColor3
useBtnFrame.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
task.delay(0.3, function() useBtnFrame.BackgroundColor3 = orig end)
index = 1
updateDisplay()
end
end
end
useBtn.MouseButton1Click:Connect(function() if current[index] then registrarPalavraNaMemoria(current[index]) end end)
local config = {automatico = false, enter = true, tentarProxima = true, verificar = 0.55, inicio = 0.8, tecla = 0.04, maxTentativas = 5, alternarPT = true, alternarX = true, potencia = false}
local estado = {ocupado = false, token = 0, geracao = 0, rodada = nil, inglesRejeitadas = 0, portuguesAteFim = false, errosDificeis = 0, finaisSuspensos = false, tentativasRodada = 0, recuperavel = false, recuperacoes = 0, status = "Auto desligado"}
painel = Instance.new("ScrollingFrame", main)
painel.Name = "OpcoesRolagem"
painel.Position = UDim2.new(0, 7, 0, 173)
painel.Size = UDim2.new(1, -14, 0, 180)
painel.BackgroundTransparency = 1
painel.BorderSizePixel = 0
painel.Active = true
painel.ClipsDescendants = true
painel.ScrollingEnabled = true
painel.ScrollingDirection = Enum.ScrollingDirection.Y
painel.ScrollBarThickness = 4
painel.ScrollBarImageColor3 = Color3.fromRGB(0, 170, 230)
painel.CanvasSize = UDim2.new(0, 0, 0, 180)
painel.Visible = opcoesAbertas and not isMinimized
local layout = Instance.new("UIListLayout", painel)
layout.Padding = UDim.new(0, 2)
layout.SortOrder = Enum.SortOrder.LayoutOrder
local ordemLinhas = 0
local function linha(texto, callback)
local b = Instance.new("TextButton", painel)
ordemLinhas = ordemLinhas + 1
b.LayoutOrder = ordemLinhas
b.Size = UDim2.new(1, -6, 0, 16)
b.BackgroundColor3 = Color3.fromRGB(20, 38, 54)
b.TextColor3 = Color3.fromRGB(210, 235, 250)
b.Font = Enum.Font.Gotham; b.TextSize = 10; b.Text = texto
Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
b.MouseButton1Click:Connect(function() callback(b) end)
return b
end
local status = Instance.new("TextLabel", painel)
status.Size = UDim2.new(1, -6, 0, 16); status.BackgroundTransparency = 1
status.LayoutOrder = 0
status.TextColor3 = Color3.fromRGB(120, 220, 240); status.Font = Enum.Font.Gotham
status.TextSize = 10; status.Text = "Auto desligado"
local function aviso(t) estado.status = t; status.Text = t end
local botaoAuto = linha("AUTO: DESLIGADO", function(b)
config.automatico = not config.automatico
estado.token = estado.token + 1
b.Text = config.automatico and "AUTO: LIGADO" or "AUTO: DESLIGADO"
b.BackgroundColor3 = config.automatico and Color3.fromRGB(29, 53, 48) or Color3.fromRGB(55, 34, 42)
if config.automatico then estado.rodada = nil; aviso("Aguardando sinal da rodada") else aviso("Auto desligado") end
end)
botaoAuto.BackgroundColor3 = Color3.fromRGB(55, 34, 42)
local botaoPotencia
local function atualizarPotencia()
local xAutomatico = (inputBox.Text or ""):lower():gsub("%s", ""):sub(1, 1) == "x"
botaoPotencia.BackgroundColor3 = (config.potencia or xAutomatico) and Color3.fromRGB(29, 53, 48) or Color3.fromRGB(55, 34, 42)
botaoPotencia.Text = config.potencia and "POTÊNCIA: LIGADA" or (xAutomatico and "POTÊNCIA: AUTO X" or "POTÊNCIA: DESLIGADA")
end
botaoPotencia = linha("POTÊNCIA: DESLIGADA", function()
config.potencia = not config.potencia
atualizarPotencia()
end)
inputBox:GetPropertyChangedSignal("Text"):Connect(atualizarPotencia)
atualizarPotencia()
linha("ESPERA RESPOSTA: 0.55 s", function(b)
config.verificar = config.verificar == 0.55 and 0.9 or (config.verificar == 0.9 and 1.5 or 0.55)
b.Text = string.format("ESPERA RESPOSTA: %.2f s", config.verificar)
end)
linha("ESPERA INÍCIO: 0.8 s", function(b)
config.inicio = config.inicio == 0.8 and 1.2 or (config.inicio == 1.2 and 0.5 or 0.8)
b.Text = string.format("ESPERA INÍCIO: %.1f s", config.inicio)
end)
linha("ERRO X: TROCAR FINAL: SIM", function(b)
config.alternarX = not config.alternarX
b.Text = "ERRO X: TROCAR FINAL: " .. (config.alternarX and "SIM" or "NÃO")
end)
linha("FINAIS: TODOS", function(b)
modoFinais = modoFinais == "TODOS" and "X" or (modoFinais == "X" and "OUTROS" or (modoFinais == "OUTROS" and "NENHUM" or "TODOS"))
atualizarFinaisDesligados()
b.Text = "FINAIS: " .. modoFinais
if estado.ocupado then pendenteUI = true; aviso("Finais atualizam após tentativa") else index = 1; updateDisplay() end
end)
linha("PET BOMB: DESLIGADO", function(b)
modoPet = (modoPet + 1) % 3
atualizarFinaisDesligados()
b.Text = ({"PET BOMB: DESLIGADO", "PET BOMB: COM FINAIS", "PET BOMB: SÓ SEQUÊNCIA"})[modoPet + 1]
if estado.ocupado then
pendenteUI = true
aviso("Pet atualiza após tentativa")
else
index = 1
updateDisplay()
end
end)
linha("FINAIS FORTES: DESLIGADO", function(b)
estrategiaAtiva = not estrategiaAtiva
atualizarFinaisDesligados()
b.Text = "FINAIS FORTES: " .. (estrategiaAtiva and "LIGADO" or "DESLIGADO")
if estado.ocupado then
pendenteUI = true
aviso("Estratégia atualiza após tentativa")
else
index = 1
updateDisplay()
end
end)
linha("TRIO AIN/CAO/ORM: NÃO", function(b)
trioAtivo = not trioAtivo
atualizarFinaisDesligados()
b.Text = "TRIO AIN/CAO/ORM: " .. (trioAtivo and "SIM" or "NÃO")
if estado.ocupado then
pendenteUI = true
aviso("Trio atualiza após tentativa")
else
index = 1
updateDisplay()
end
end)
local function atualizarRolagem()
-- Uma linha de status, os botões de 16px com espaçamento, e a grade opcional.
local altura = ordemLinhas * 18 + (filtrosAbertos and 82 or 0)
painel.CanvasSize = UDim2.new(0, 0, 0, altura)
end
local function atualizarFiltroUI()
if estado.ocupado then
pendenteUI = true
aviso("Filtro atualiza após tentativa")
else
geracaoPesquisa = geracaoPesquisa + 1
if searchThread then pcall(task.cancel, searchThread); searchThread = nil end
ultimoTermoPesquisado = nil
current = {}; index = 1
wordLabel.Text = "..."
local revisao = revisaoFiltros
task.delay(0.18, function()
if gui.Parent and not estado.ocupado and revisao == revisaoFiltros then
updateDisplay()
elseif gui.Parent and estado.ocupado and revisao == revisaoFiltros then
pendenteUI = true
end
end)
end
end
linha("PALAVRAS 10+: DESLIGADO", function(b)
modoLongas = not modoLongas
atualizarFinaisDesligados()
b.Text = "PALAVRAS 10+: " .. (modoLongas and "LIGADO" or "DESLIGADO")
if estado.ocupado then pendenteUI = true; aviso("Palavras grandes após tentativa")
else index = 1; updateDisplay() end
end)
local filtroBotao = linha("PRIORIDADE DE FINAIS ▼", function(b)
filtrosAbertos = not filtrosAbertos
b.Text = filtrosAbertos and "PRIORIDADE DE FINAIS ▲" or "PRIORIDADE DE FINAIS ▼"
local grade = painel:FindFirstChild("GradeFinais")
if grade then grade.Visible = filtrosAbertos end
atualizarRolagem()
atualizarDimensoes()
end)
local gradeFinais = Instance.new("Frame", painel)
gradeFinais.Name = "GradeFinais"
ordemLinhas = ordemLinhas + 1
gradeFinais.LayoutOrder = ordemLinhas
gradeFinais.Size = UDim2.new(1, -6, 0, 80)
gradeFinais.BackgroundTransparency = 1
gradeFinais.Visible = false
local numeroFiltros = 0
for _, fim in ipairs(finaisDificeis) do
if not finaisTrio[fim] then
numeroFiltros = numeroFiltros + 1
local botaoFim = Instance.new("TextButton", gradeFinais)
botaoFim.Name = "Final_" .. fim:upper()
botoesFinais[fim] = botaoFim
local coluna, linhaIndice = (numeroFiltros - 1) % 5, math.floor((numeroFiltros - 1) / 5)
if fim == "x" then coluna = 4 end
botaoFim.Size = UDim2.new(0.2, -2, 0, 18)
botaoFim.Position = UDim2.new(coluna * 0.2, 1, 0, linhaIndice * 20)
botaoFim.Text = fim:upper() .. (finaisDesligados[fim] and " ✕" or " ✓")
botaoFim.TextColor3 = Color3.fromRGB(215, 245, 235)
botaoFim.BackgroundColor3 = finaisDesligados[fim] and Color3.fromRGB(75, 30, 35) or Color3.fromRGB(18, 78, 65)
botaoFim.Font = Enum.Font.GothamBold; botaoFim.TextSize = 9
Instance.new("UICorner", botaoFim).CornerRadius = UDim.new(0, 3)
botaoFim.MouseButton1Click:Connect(function()
finaisDesligados[fim] = not finaisDesligados[fim]
atualizarFinaisDesligados()
local ligado = not finaisDesligados[fim]
botaoFim.Text = fim:upper() .. (ligado and " ✓" or " ✕")
botaoFim.BackgroundColor3 = ligado and Color3.fromRGB(18, 78, 65) or Color3.fromRGB(75, 30, 35)
atualizarFiltroUI()
end)
end
end
local campoExtra = Instance.new("TextBox", gradeFinais)
campoExtra.Name = "FinalPersonalizado"
campoExtra.Size = UDim2.new(0.2, -2, 0, 18)
campoExtra.Position = UDim2.new(0.4, 1, 0, 60)
campoExtra.BackgroundColor3 = Color3.fromRGB(20, 38, 54)
campoExtra.TextColor3 = Color3.fromRGB(215, 245, 235)
campoExtra.PlaceholderText = "FINAL"
campoExtra.Text = ""
campoExtra.ClearTextOnFocus = false
campoExtra.Font = Enum.Font.GothamBold; campoExtra.TextSize = 9; campoExtra.TextScaled = true
Instance.new("UICorner", campoExtra).CornerRadius = UDim.new(0, 3)
botaoExtra = Instance.new("TextButton", gradeFinais)
botaoExtra.Name = "FinalPersonalizadoLiga"
botaoExtra.Size = UDim2.new(0.12, -2, 0, 18)
botaoExtra.Position = UDim2.new(0.6, 1, 0, 60)
botaoExtra.TextColor3 = Color3.fromRGB(215, 245, 235)
botaoExtra.Font = Enum.Font.GothamBold; botaoExtra.TextSize = 9
Instance.new("UICorner", botaoExtra).CornerRadius = UDim.new(0, 3)
pintarExtra()
campoExtra.FocusLost:Connect(function(enter)
if enter then enterExtra = os.clock() end
if not enter then campoExtra.Text = finalExtra:upper(); return end
local novo = campoExtra.Text:lower():gsub("%s", "")
local repetido = false
for _, fim in ipairs(finaisDificeis) do if novo == fim then repetido = true; break end end
if novo ~= "" and (#novo > 18 or not novo:match("^[a-z]+$") or repetido) then
campoExtra.Text = finalExtra:upper(); aviso(repetido and "Final já existe" or "Use letras A-Z, até 18"); return
end
if novo ~= finalExtra then
finalExtra = novo; extraLigado = novo ~= ""
atualizarFinaisDesligados(); pintarExtra(); atualizarFiltroUI()
end
campoExtra.Text = finalExtra:upper()
end)
botaoExtra.MouseButton1Click:Connect(function()
if finalExtra == "" then aviso("Digite um final e aperte Enter"); return end
extraLigado = not extraLigado
atualizarFinaisDesligados(); pintarExtra(); atualizarFiltroUI()
end)
atualizarRolagem()
-- Cada fonte tardia ou com falha é retomada em segundo plano, sem alterar listas em uso.
for numero = 1, 4 do
task.spawn(function()
while gui.Parent and not databaseLoaded do task.wait(0.25) end
if not gui.Parent then return end
local item = fontesRede[numero]
if not item or item.consumido then return end
local tentativas = 1
while gui.Parent and tentativas <= 3 do
if not item.terminou and os.clock() - item.inicio >= 8 then
local cancelado = item.thread and pcall(task.cancel, item.thread)
if cancelado then
item.geracao = item.geracao + 1
item.terminou, item.ok = true, false
else
-- Se não for possível cancelar, não criar requisições duplicadas.
item.inicio = os.clock()
end
end
if item.terminou then
if item.ok and item.texto then
local novo = {Set = {}, Buckets = {}, pronto = false}
local novasSaidas = {}
local n = 0
for linha in item.texto:gmatch("[^\r\n]+") do
local w = linha:lower():gsub("%s", "")
if #w >= 3 and #w <= 18 and w:match("^[a-z]+$") and w:match("[aeiouy]")
and not w:match("^xl[ivx]*$") and not w:match("^xk[a-z]*$") and not listaNegra[w] and not novo.Set[w] then
novo.Set[w] = true
for _, fim in ipairs(finaisDificeis) do
if not novasSaidas[fim] and w:sub(1, #fim) == fim then novasSaidas[fim] = true end
end
local chave = w:sub(1, 2)
local lista = novo.Buckets[chave]
if not lista then lista = {}; novo.Buckets[chave] = lista end
lista[#lista+1] = w
end
n = n + 1
if n % 3500 == 0 then if not gui.Parent then return end; task.wait() end
end
novo.pronto = true
recuperados[numero] = novo
local lingua = numero == 1 and "PT" or "EN"
for fim in pairs(novasSaidas) do prefixosDificeis[lingua][fim] = true end
revisaoBancos = revisaoBancos + 1
atualizarEstatisticasRecuperadas()
item.texto = nil; item.consumido = true
if gui.Parent then
if estado.ocupado then pendenteUI = true
elseif inputBox.Text ~= "" then updateDisplay() end
end
return
end
if tentativas >= 3 then
warn("Word System: banco principal " .. numero .. " indisponível; nova tentativa em 15s")
task.wait(15); tentativas = 0
else
task.wait(2)
end
if not gui.Parent then return end
tentativas = tentativas + 1
baixarPrincipal(item)
end
task.wait(0.1)
end
warn("Word System: banco principal " .. numero .. " indisponível após tentativas")
end)
end
-- Reservas independentes: falhas e esperas em uma fonte não bloqueiam a outra.
local mapaAcentos = {
["á"]="a",["à"]="a",["â"]="a",["ã"]="a",["ä"]="a",["Á"]="a",["À"]="a",["Â"]="a",["Ã"]="a",["Ä"]="a",
["é"]="e",["è"]="e",["ê"]="e",["ë"]="e",["É"]="e",["È"]="e",["Ê"]="e",["Ë"]="e",
["í"]="i",["ì"]="i",["î"]="i",["ï"]="i",["Í"]="i",["Ì"]="i",["Î"]="i",["Ï"]="i",
["ó"]="o",["ò"]="o",["ô"]="o",["õ"]="o",["ö"]="o",["Ó"]="o",["Ò"]="o",["Ô"]="o",["Õ"]="o",["Ö"]="o",
["ú"]="u",["ù"]="u",["û"]="u",["ü"]="u",["Ú"]="u",["Ù"]="u",["Û"]="u",["Ü"]="u",["ç"]="c",["Ç"]="c"}
local pendentesReserva = {PT = true, EN = true}
local function concluirReserva(idioma)
pendentesReserva[idioma] = nil
if not pendentesReserva.PT and not pendentesReserva.EN then reservasFinalizadas = true end
end
for _, itemFonte in ipairs({
{"PT", "https://raw.githubusercontent.com/pythonprobr/palavras/master/palavras.txt"},
{"EN", "https://raw.githubusercontent.com/dwyl/english-words/master/words_alpha.txt"}
}) do
task.spawn(function()
while gui.Parent and not databaseLoaded do task.wait(0.25) end
if not gui.Parent then return end
local idioma = itemFonte[1]
local item = {url = itemFonte[2]}
local tentativas = 1
baixarPrincipal(item)
while gui.Parent do
if not item.terminou and os.clock() - item.inicio >= 15 then
local cancelado = item.thread and pcall(task.cancel, item.thread)
if cancelado then
item.geracao = item.geracao + 1
item.terminou, item.ok = true, false
else
-- Se não for possível cancelar, não criar requisições duplicadas.
item.inicio = os.clock()
end
end
if item.terminou then
if item.ok and item.texto then
local reserva, n = {Set = {}, Buckets = {}, pronto = false}, 0
for linha in item.texto:gmatch("[^\r\n]+") do
local w = linha:lower()
if idioma == "PT" then w = w:gsub("[\194-\244][\128-\191]*", function(c) return mapaAcentos[c] or c end) end
if #w >= 3 and #w <= 18 and w:match("^[a-z]+$") and w:match("[aeiouy]")
and not w:match("^xl[ivx]*$") and not w:match("^xk[a-z]*$") and not listaNegra[w]
and not bancos[idioma].Set[w] and not reserva.Set[w] then
reserva.Set[w] = true
local chave = w:sub(1, 2)
local lista = reserva.Buckets[chave]
if not lista then lista = {}; reserva.Buckets[chave] = lista end
lista[#lista+1] = w
end
n = n + 1
if n % 3500 == 0 then if not gui.Parent then return end; task.wait() end
end
-- O mapa foi necessário apenas para eliminar duplicadas durante a leitura.
-- Depois, os índices por prefixo guardam as palavras sem manter outra tabela grande.
reserva.Set = nil
reserva.pronto = true
bancosReserva[idioma] = reserva
revisaoBancos = revisaoBancos + 1
item.texto = nil
concluirReserva(idioma)
if gui.Parent and databaseLoaded and not estado.ocupado and #current == 0 and inputBox.Text ~= "" then updateDisplay() end
return
end
if tentativas >= 3 then
concluirReserva(idioma)
warn("Word System: banco reserva " .. idioma .. " indisponível; nova tentativa em 15s")
task.wait(15); tentativas = 0
else task.wait(2) end
if not gui.Parent then return end
tentativas = tentativas + 1
baixarPrincipal(item)
end
task.wait(0.1)
end
end)
end
local function getParts()
local target = findTargetGui()
local top = target and target:FindFirstChild("TopBar")
local question = top and top:FindFirstChild("Question")
local answer = top and top:FindFirstChild("AnswerInput")
return question and question:FindFirstChild("QuestionLabel"), answer and answer:FindFirstChild("Keys")
end
local function readSlots(keys)
if not keys or not keys.Parent then return nil end
local chars = {}
for i = 1, 30 do
local slot = keys:FindFirstChild(tostring(i))
if not slot then if i == 1 then return nil end; break end
local inner = slot:FindFirstChild("Inner")
local label = (inner and inner:FindFirstChild("TextLabel")) or slot:FindFirstChild("TextLabel")
if not label or not label:IsA("TextLabel") then if i == 1 then return nil end; break end
local c = label.Text:lower():gsub("%s", "")
if not c:match("^[a-z]$") then break end
chars[#chars+1] = c
end
return table.concat(chars)
end
local function promptText(label)
if not label or not label.Parent then return nil end
local t = label.Text:lower()
return t:match('"%s*([a-z]+)%s*"') or t:match("starting with%s+([a-z]+)")
or t:match("contains%s+([a-z]+)") or t:match("contendo%s+([a-z]+)")
or t:match("começando com%s+([a-z]+)")
or t:match("starts with%s+([a-z]+)") or t:match("comece com%s+([a-z]+)")
or t:match("comeca com%s+([a-z]+)")
end
local function detect(label, keys)
local t = label and label.Text:lower() or ""
local novoModo = (t:find("contain") or t:find("contém") or t:find("contem") or t:find("contenha")) and "CONTEM" or "PREFIXO"
if modoBusca ~= novoModo then modoBusca = novoModo; updateDisplay() end
if not travaIdiomaManual then
if t:find("type a word") or t:find("starting with") or t:find("contains") then setIdioma("EN")
elseif t:find("digite") or t:find("palavra") or t:find("contenha") then setIdioma("PT") end
end
local p = promptText(label)
if p and #p >= 1 and #p <= 18 then return p end
local slots = readSlots(keys)
if slots and #slots >= 1 and #slots <= 18 then return slots end
end
local function key(k, duracao)
if not VirtualInputManager then aviso("Entrada virtual indisponível"); return false end
estado.ultimaAtividade = os.clock()
local ok = pcall(function()
VirtualInputManager:SendKeyEvent(true, k, false, game)
task.wait(duracao or config.tecla)
VirtualInputManager:SendKeyEvent(false, k, false, game)
end)
return ok
end
local function memorizarEnvio(palavra)
if not palavra or #palavra < 2 or not palavra:match("^[a-z]+$") then return end
marcarUsada(palavra)
for i = #current, 1, -1 do
if current[i] == palavra then
table.remove(current, i)
if i < index then index = index - 1 end
end
end
index = math.min(math.max(index, 1), math.max(#current, 1))
countLabel.Text = #current .. " disp."
wordLabel.Text = current[index] and current[index]:upper() or "sem palavras"
infoLabel.Text = current[index] and (index .. " / " .. #current) or "Nenhuma sugestão disponível"
end
resetBtn.MouseButton1Click:Connect(function()
estado.token = estado.token + 1
estado.inglesRejeitadas = 0; estado.portuguesAteFim = false; estado.errosDificeis = 0; estado.finaisSuspensos = false; estado.tentativasRodada = 0; estado.recuperavel = false; estado.recuperacoes = 0; estado.candidatoRecuperacao = nil; estado.idiomaRecuperacao = nil
usedWords = {}
prefixosUsados = novosMapas()
index = 1
updateDisplay()
aviso("Memória apagada")
end)
UserInputService.InputBegan:Connect(function(input)
if not gui.Parent or estado.ocupado then return end
if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
if enterExtra and os.clock() - enterExtra < 0.3 then return end
local foco = UserInputService:GetFocusedTextBox()
if foco and foco:IsDescendantOf(gui) then return end
local _, keys = getParts()
memorizarEnvio(readSlots(keys))
end
end)
local enterAlvo, enterConexao
local function conectarEnterDoJogo()
local target = findTargetGui()
local bottom = target and target:FindFirstChild("BottomBar")
local keyboard = bottom and bottom:FindFirstChild("Keyboard")
local row = keyboard and keyboard:FindFirstChild("2")
local inner = row and row:FindFirstChild("Inner")
local botao = inner and inner:FindFirstChild("10")
if botao == enterAlvo then return end
if enterConexao then enterConexao:Disconnect(); enterConexao = nil end
enterAlvo = botao
if botao and botao:IsA("GuiObject") then
enterConexao = botao.InputBegan:Connect(function(input)
if estado.ocupado then return end
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
local _, keys = getParts()
memorizarEnvio(readSlots(keys))
end
end)
end
end
task.spawn(function()
while gui.Parent do
pcall(conectarEnterDoJogo)
task.wait(1)
end
if enterConexao then enterConexao:Disconnect() end
end)
local function escolherGrande(lista, idioma, fase, temporario)
local melhor, melhorIndice, melhorLonga, melhorPet, melhorConfianca
local termo = inputBox and inputBox.Text or ""
local pet = fase == 1 and extrasPermitidos(termo) and modoPet > 0
for i, w in ipairs(lista) do
if not usedWords[w] and finalPermitido(w, temporario) then
local longa = faixaLonga(w)
local dupla = 0
if pet then
for j = 1, #w - (modoPet == 1 and 2 or 1) do
local a, b = w:byte(j, j + 1)
if a >= 97 and a < 122 and b == a + 1 then dupla = 1; break end
end
end
local confianca = idioma == "PT" and (comunsPT[w] and 2 or bancoPTCurado[w] and 1 or 0)
or ((CommonWordsEN[w] or recuperados[2].Set[w] or recuperados[3].Set[w]) and (bEN.Set[w] or recuperados[4].Set[w]) and 2 or (CommonWordsEN[w] or recuperados[2].Set[w] or recuperados[3].Set[w]) and 1 or 0)
if not melhor or longa > melhorLonga or (longa == melhorLonga and dupla > melhorPet)
or (longa == melhorLonga and dupla == melhorPet and fase >= 2 and confianca > melhorConfianca) then
melhor, melhorIndice, melhorLonga, melhorPet, melhorConfianca = w, i, longa, dupla, confianca
end
end
end
return melhor, melhorIndice
end
local function escolherProxima(evitarX, plano)
if modoLongas then return escolherGrande(current, idiomaResultados, estado.tentativasRodada, currentRelaxado) end
local dificil = plano and estado.tentativasRodada == 2
local prefereComum = not dificil and (estado.finaisSuspensos or (plano and estado.tentativasRodada >= 3))
local fases = dificil and 3 or ((evitarX or prefereComum) and 2 or 1)
for fase = 1, fases do
for passo = 0, #current - 1 do
local i = ((index - 1 + passo) % #current) + 1
local w = current[i]
local cat = categoriaFinal(w, idiomaResultados, "TODOS")
local permite = dificil and (fase == 3 or (cat > 0 and (fase == 2 or not evitarX or w:sub(-1) ~= "x")))
or (not dificil and (fase == 2 or ((not evitarX or w:sub(-1) ~= "x") and (not prefereComum or cat == 0))))
if not usedWords[w] and finalPermitido(w, currentRelaxado) and permite then return w, i end
end
end
end
local function escolherPT(lista, plano)
if modoLongas then return escolherGrande(lista, "PT", estado.tentativasRodada, currentRelaxado) end
local dificil = plano and estado.tentativasRodada == 2
local seguro = plano and estado.tentativasRodada >= 3
if seguro then
local melhor, nota, tamanho
for _, w in ipairs(lista) do
if not usedWords[w] and finalPermitido(w, currentRelaxado) then
local n = (categoriaFinal(w, "PT", "TODOS") == 0 and 8 or 0) + (#w >= 4 and 4 or 0)
+ (comunsPT[w] and 2 or bancoPTCurado[w] and 1 or 0)
if not melhor or n > nota or (n == nota and #w < tamanho) then melhor, nota, tamanho = w, n, #w end
end
end
return melhor
end
local prefereComum = estado.finaisSuspensos and not dificil
for fase = 1, ((dificil or prefereComum) and 2 or 1) do
for _, w in ipairs(lista) do
local cat = categoriaFinal(w, "PT", "TODOS")
if not usedWords[w] and finalPermitido(w, currentRelaxado) and (fase == 2 or (not dificil or cat > 0) and (not prefereComum or cat == 0)) then
return w
end
end
end
end
local function obterCandidatasPT(termo, modoAtual, prefixoFixo)
local lista = {}
local primeira = modoAtual == "PREFIXO" and termo ~= "" and inicioPrefixo(bancos.PT.List, termo) or 1
for i = primeira, #bancos.PT.List do
local w = bancos.PT.List[i]
if modoAtual == "PREFIXO" and termo ~= "" and w:sub(1, #termo) ~= termo then break end
if not usedWords[w] and not listaNegra[w] and encaixaBusca(w, termo, modoAtual, currentRelaxado)
and (prefixoFixo == "" or w:sub(1, #prefixoFixo) == prefixoFixo) then
lista[#lista+1] = w
end
if i % 25000 == 0 then task.wait() end
end
if recuperados[1].pronto then
local ja = {}; for _, w in ipairs(lista) do ja[w] = true end
local visitas = 0
local function acrescentar(bloco)
if not bloco then return end
for _, w in ipairs(bloco) do
if not ja[w] and not usedWords[w] and not listaNegra[w] and encaixaBusca(w, termo, modoAtual, currentRelaxado)
and (prefixoFixo == "" or w:sub(1, #prefixoFixo) == prefixoFixo) then
lista[#lista+1] = w; ja[w] = true
end
visitas = visitas + 1
if visitas % 10000 == 0 then task.wait() end
end
end
if modoAtual == "PREFIXO" and #termo >= 2 then
acrescentar(recuperados[1].Buckets[termo:sub(1, 2)])
else
for chave, bloco in pairs(recuperados[1].Buckets) do
if modoAtual ~= "PREFIXO" or termo == "" or chave:sub(1, 1) == termo:sub(1, 1) then acrescentar(bloco) end
end
end
end
ordenarCandidatos(lista, "PT", termo)
return lista
end
-- Evidência adicional, não é lista oficial nem garante aceitação.
-- wordfreq 3.1.1 (Apache-2.0), https://github.com/rspeer/wordfreq
local frequenciaIndependente = {EN = {}, PT = {}}
for w in ([==[the and for that you with this was are have not but from your all his they one can will just like about out what has when more were who had their there her which time get been would she new people how some also them now other its our than good only after first him into know see two make over think any then could back these want because well said way most much very where even should may here need really did right work year years being day too going before off why made still take got many never those life say world down great through last while best such love man home long look something use same used both every come part state three around between always better find help high little old since another does own things under during game thing give house place school again next each without against end found must show big feel sure team ever family keep might please put money free second someone away left number city days lot name night play until company doing few let real called different having set thought done however getting god government group looking public top women business care start system times week already anything case nothing person today change enough everything full live making point read told yet bad four hard mean once support tell including music power seen states stop water based believe call head men national small took white came far job side though try went yes actually american later less line order party run says service country open season shit thank children everyone general trying united using area black following law makes together war whole car face five kind maybe per president story working course games health hope important least means news within able book early friends information local post thanks video young ago others social talk court fact given guys half hand level mind often single become body coming control death food guy hours office pay problem south true almost fuck history known large lost research room several started taking university win wrong along anyone else girl john matter pretty remember air bit friend hit needs nice playing probably saying understand yeah york class close comes idea international looks past possible wanted cause due happy human members months move question series wait woman ask community data late leave north saw special watch either fucking future light low million morning police short stay taken age buy deal rather reason red report soon third turn whether among check development form further heart minutes myself services yourself act although asked child fire fun living major media phone players art behind building easy gonna market near non plan political quite six talking west works according available education final former front kids list ready sometimes son street bring college current example experience heard london meet program type baby chance father march process song study word across action clear gave gets himself month outside self students words board cost cut field held instead main moment mother road seems thinking town wants department energy fight fine force hear issue played points price rest results running shows space summer term wife america beautiful date goes killed land miss project sex shot site strong account especially eyes include june parents period position record similar total above club common died film happened knew lead likely military perfect personal security share won april center county couple dead english happen hold industry inside issues online player private problems return rights sense star test view weeks break british companies event higher hour member middle needed present result sorry takes training wish answer boy design finally girls gold gone guess interest july king learn policy society added alone average bank brought certain church east hands hot longer medical movie original park performance press received role sent themselves tried worked worth areas became bill books cool director exactly giving ground meeting provide questions relationship september sound source usually value evidence follow lives official production rate reading round save stand stuff tax whatever amount blue countries david drive eat fall fast federal feeling felt green league management match model picture size step trust central changes england forward groups hey key mom page paid range review science trade upon various attention brother cannot character chief cup football hate james led looked lower natural october property quality send style vote amazing august blood china complete dog economic hell involved itself language lord november oil related serious stage terms title add article attack born damn decided decision enjoy entire french january kill met perhaps poor release situation technology turned website written choice code considered continue council cover currently door election european events financial foreign hair increase legal lose michael pick race seem seven sign simple simply staff super union walk washington bed began built career changed crazy daily daughter december die difficult figure hospital knows loss modern ones paper parts popular published safe starting systems version voice whose writing army australia earth forget goal huge internet listen okay practice rules sea sir success towards waiting ways access base below created deep followed lol mark missing offer pass professional released risk schools sleep table ten truth ball box build card cases dark district europe george india mine minister note percent piece products recent seeing straight visit wall wanna wrote allowed boys culture etc fans february gives growth included married officer pain paul places respect response river rock shall speak specific standard tonight write album century charge cold create effect eight except eye funny limited moving network peace provided recently required sales spent store student tomorrow track via watching weight addition ahead allow anti association beat brown capital chinese committee conference difference double expect gas island moved normal plans population potential pressure radio russian station text treatment western ass beginning california campaign certainly completely content credit cross described despite female focus husband ice individual interesting join kept leading loved message miles nearly particular previous quickly region reported section sort speed travel consider contact drop fair feet jesus kid link positive sale throughout tour welcome absolutely additional beyond conditions earlier extra forces immediately jobs leaving minute nature numbers quick sell significant studies unless winning agree canada clean computer construction episode favorite income justice levels manager movement photo posted safety san scene sold sounds spend statement sun teams ability announced asking calling coach collection continued costs definitely designed expected friday gun happens heavy includes knowledge particularly search subject train wide wow author centre claim dad developed fear fit generally german global goals gotta hotel interested judge lady leader letter lines material named nobody opportunity plus pre product regular secretary sister stories unit workers annual anymore bar battle brain contract degree families features finished floor france growing hurt image insurance majority meant opening opinion physical pro reach rule seriously sports stupid successful active administration approach australian biggest cancer civil dance defense direction independent master none reasons russia ship stock trump weekend wonder worst africa awesome band beach cash clearly commercial compared effort ended fan fighting imagine impact lack latest learning multiple older operation organization passed pictures protect secret senior spring sunday telling wear activities address analysis anyway bought calls choose christmas color commission competition details direct dream easily finish grand increased indian literally luck marriage names necessary patients resources rich skin speaking supposed sweet thus touch yesterday caught closed congress damage directly disease doctor doubt drink driving established facebook feels fish gay germany glad greater grow largest machine notice overall planning professor programs records reports shown sit trip associated basic captain carry cars crime effective effects explain fully highly holding japan laws male mrs parties plant reality smith spot texas winter worse advice agreement award block broken caused challenge characters christian comment equipment eventually helped holy killing lived lots nation otherwise peter prices primary purpose rates responsible shop showing sick teacher theory uses william agency avoid camera catch cell coast comments drug economy environment executive foot hall mass meaning mission nine officers operations politics pop produced ran saturday status therefore trial truly weather activity app application claims coffee complex condition division evening flight freedom google heat highest interview library located location murder obama offered putting queen seconds showed sitting standing stars walking accept actual appear attempt broke channel distance eating exchange fat fell finding glass learned losing mobile northern opened placed powerful prior protection reached receive religious ride robert royal screen serve signed slow species speech traffic tree types wearing whom wonderful agreed airport animals appears begin benefits bottom cities demand engine everybody famous ideas investment keeping lie notes partner plays raised runs sad solution songs sources southern square stopped structure thomas traditional twice wind worry americans appeared becomes brand bus cent chicago count covered critical digital forced fourth fresh lake mental mentioned missed mostly mouth owner photos previously realize remain scale score separate smart starts surface throw tom totally twitter views wedding acting actions african arms benefit budget click estate failed faith fashion feature fund generation hearing hill jack larger louis metal mid paris profile pull push returned rose seat seemed sexual target understanding village agent animal apply authority basis becoming chris draw dude employees enter follows foundation gain http individuals japanese leaders memory prime projects ring rise selling served silver soul spread supply waste weird adult apparently artist chairman edition engineering grade happening healthy institute method mike monday nations obviously option prison provides remains senate smaller somebody stone strength users wild window winner arrived bag bet camp cast christ continues correct dangerous extremely firm greatest handle improve indeed leaves movies negative prevent removed richard spirit television till trouble usa videos advantage apart aware cat customers decide dinner dollars eastern fifth function gift helping herself impossible influence items joe los marketing mary materials nor produce progress proud require shooting shut standards tells thinks van wood background birth bridge carried charles classes completed concept copy dear dogs drugs efforts garden host housing inc israel journal labor leadership length lucky neither onto patient possibly prove rare setting skills software thousands tough units alive apple balance birthday bitch boss cards changing connection dress easier fellow florida horse knowing liked magic managed map net owned request stick turns vehicle volume wake aid beauty believed billion busy buying cells concerned conversation corner criminal cultural develop driver ends existing farm file fix fly frank guide images investigation mexico operating paying presented raise responsibility roll slightly suggest surprise technical thoughts treat unique variety violence weapons yours youth appreciate bigger breaking discovered dont dry edge evil excited forever funds helps henry injury iron lovely mad magazine martin models offers ordered parliament prepared reference religion sites somewhere stated strategy teachers web wine accounts angeles arm audience bay blog closer core democratic description dropped excellent exist figures forms guard honest issued joined jones lee lies likes medicine mention mountain nuclear orders port presence reaction reduce shoot sides solid spanish sport steps stress taste tea victory afternoon assistant britain citizens classic clothes decisions electric emergency entered entirely facts failure festival flat fuel harry hello houses ill initial introduced johnson kick links mail massive matters pair picked pieces plane plenty prince proper providing quarter regional scott session shape sky teaching toward transfer upper useful valley watched willing windows zone accident advanced alternative anywhere articles awards bear boat bringing capacity cheap climate communities discussion drinking duty fantastic feelings flying governor hundred industrial joint mix museum options path plants policies promise proposed purchase rain remove signs spending steel steve supporting terrible tired treated turning vice warm afraid arts beer border canadian command crew crowd dating dick elements enemy ensure environmental filled fixed forest intelligence intended labour limit moon ocean powers profit proof republican soldiers suit wins appearance asian attorney banks behavior ben bodies brothers buildings chair creating debt domestic expensive grew historical homes honestly honor jump launch listed minimum native noted originally planned ray sets suddenly supreme survey tech trees update user writer yellow younger ancient attacks charges combined communication connected contains download email ending exercise express flow formed girlfriend hero illegal increasing joke loan methods officials performed planet relationships restaurant scotland selected shared shopping soft stuck sugar suggested supported surprised taught transport accepted adding affairs allows appeal applied appropriate artists boston confirmed device drama entry era factor feed golden grant grown heads hoping keeps lawyer legs lying measures mistake muslim organizations platform pool pulled regarding relations requires route saved schedule scientific shoes smoke squad teach testing tests values walked williams abuse angry businesses candidate comfortable concern developing discuss elections emotional everywhere facilities falling fox guns hole holiday interests internal ireland italian italy jersey laugh leg letters liberal listening loves lunch max milk pack payment perform recorded relatively sector sharing snow storm streets strike studio sub weak youtube actor advance apartment asia chain chapter committed confidence cook cute equal fake finance focused hits identity journey kitchen korea leads maintain measure numerous owners posts properties quiet revealed specifically split task taxes taylor twenty urban acts affected aircraft applications approved approximately argument arrested claimed conflict considering corporate debate determined distribution documents escape extended factors faster fault fill films flowers friendly ladies lay lights millions mixed phase properly pure reduced requirements residents revenue sam sat secure smile strange talent temperature thousand tony troops truck votes authorities basically besides bird blame bob bowl causes chicken collected context coverage determine display dying elected examples experienced falls false fired forgot funding identified iii incredible inspired launched meat ministry mode neck noticed novel obvious passing positions remaining scored shirt shots slowly stadium stores surgery trading tuesday vision whenever worried zero alex allowing begins champion charged cream crisis daniel delivered editor estimated giant iran jail jim kingdom literature mayor minor moments opposite orange ourselves pages remained selection serving signal stream struggle suicide talked theme thursday tiny typically unfortunately usual vehicles virginia voted voting walls wave alcohol assembly breakfast bright brings capable carrying chosen combination conservative customer cutting desire destroyed draft drunk essential fail familiar finds granted guilty humans hundreds improved jewish largely laughing markets medium ohio opportunities papers perfectly recommend referred relevant seek sending solo spoke stands talks ticket unable upset wing answers birds bomb creative cycle dealing directed don educational entertainment extreme facility fields goods hang holds info mainly maximum newspaper offering painting republic reserve returns row salt scared scottish shares statistics switch territory threat tickets wales adults affect appointed armed aside assistance bell blow bond boyfriend careful circumstances communications concerns controlled corporation cry danger deals delivery deserve devices dollar dreams empty enjoyed explained faces folks fucked gender instance kim kinda matches mile motion moves nick pacific prize realized reasonable receiving register resolution rural ryan saving sees singing spain tools typical universe warning wars wednesday admit attitude branch brazil conducted decades dedicated definition drawing favor flag frame guest heaven independence institutions jackson kiss load plot possibility random recovery rent replace represent reviews scenes seeking senator sentence teeth tips trained understood academic academy accurate achieve adam afford andrew assume bbc bottle bunch category chat cheese chemical clinton competitive detail diet favourite fruit harder index item lane mess navy normally occurred opposition parent permanent personally pleasure prefer programme representative scheme shift stood storage tank tend tight transportation ultimately unlike weekly yard anybody assets basketball button candidates combat constitution consumer counter creation crown crying defined depending depression describe drivers employment exclusive excuse expert frequently golf grace hopefully identify importance kevin laid latter manufacturing mining object partners pattern performing personnel perspective pregnant premier promote revolution rooms severe sleeping suppose tool tournament turkey victim victims agents amazon arrest attend ban brilliant carbon catholic chose circle concert crash declared deliver depth deputy dirty doctors earned electronic error existence experiences expression factory headed interior joy legislation maintenance manner mate matt nearby noise origin pakistan panel personality plate practices prepare relief replaced resistance retail rice roads roof shame ships somewhat staying stronger surely tip updated writers absolute advertising agencies baseball bathroom bible cable calm championship checked client constant dates degrees democrats doors driven dumb empire exciting expansion heavily hide incident irish linked manage messages michigan multi nfl politicians print quit refused reporting sight significantly sing soviet weapon wet widely worldwide ages anniversary attractive bike broad burn cake causing closely constantly contest deaths depends drawn fees francisco haha hardly hat height hidden hong invited letting loud manchester marine motor officially peak portion pounds princess protein puts raw reform regions represented respond retirement sample seats secondary solar somehow stayed suffering sydney tries ultimate unknown wilson wondering attached attacked automatically balls battery bills blind breath brief carolina chest conduct debut decade destroy differences edward engaged experts expressed external fantasy grab hollywood immediate introduction joseph license paint pilot pink presidential principal recognize recognized registered regularly representatives rising seasons shipping singer smoking steam suffered survive tall thats theatre therapy witness adopted aim campus cap chances childhood clinical clubs comedy commander comparison covers dan defeat defence democracy detailed entitled exact exposed fed fee injured jan jordan kinds lets loans lock musical nose objects opposed organized plastic protected purposes quote recording semi statements suspect swear techniques tie tim trend valuable wealth wise yards aged approval aspects attempts bread burning champions contain convention dancing document eggs employee engineer equivalent facing fairly fingers ford founded functions gang graduate greek hanging inner islands lift marked memories miller monthly mountains neighborhood operate outstanding permission porn racing recommended regulations reply republicans rid roman scientists shoulder shower solutions sons stations stephen tower tradition visited visual wheel zealand achieved admitted appointment authors barely bush cabinet celebrate challenges chocolate coal colour contemporary criticism davis dna effectively eric extensive faced filed formation fought gained gallery highway historic hunt improvement inch initially junior jury kong korean marks monster obtained olympic philosophy pride promised repeat returning riding rough santa settlement smell sought speaker studied suggests surrounding tone topic toronto universal vast visitors wanting auto consistent continuing earn exists finger grey guitar heading howard ignore involving latin lewis meal meanwhile meetings naturally necessarily offices pants partnership payments percentage pocket practical primarily proved rape regardless relative represents rescue resulting rush sarah sessions sharp simon soccer stable structures supplies symptoms temporary tested trick attended audio bone brian bullshit chamber chart circuit clothing complicated confused consequences defend divided elizabeth everyday extent fishing format gap gate gotten harm healthcare household immigration impressive jews joining killer lesson limits loving ltd managers membership miami mirror mount nights occur parking proposal province purchased recognition reputation rolling shortly situations strongly tears technique thin tied accused adventure argue assessment atmosphere awful bedroom belief bound breaks carefully cats ceo choices closing cloud colorado colors contrast courses courts donald drew egg element elsewhere establish extension files founder gear georgia hills hip hitting increases infrastructure jason locations loose machines moral offensive package pointed poverty processes processing qualified railway reaching ridiculous sensitive server shock silence soldier superior supporters thick threw tons transition violent voters wash acid actress administrative alan alongside angel anxiety babies bars bonus castle charity clients compare contained cooking covering curious directors discovery discussed duke egypt encourage enforcement featuring finals flash formal formula fort governments gray gross horses hungry informed innocent jeff losses luke mac math minds mistakes mystery networks olympics palace passes penalty pet phones photography producing protest publication rating refer respectively rome scheduled select silent spoken successfully suffer temple tracks trail uncle unusual waters woods arrival asks assault awareness badly bath captured chase components concrete dave deeply expectations explanation exposure featured fiction guarantee happiness harris hearts horrible ideal illinois injuries islamic jimmy kelly legend lieutenant mini mood muscle muslims passion picking pleased procedure producer pushing rank replacement retired roles sand savings settled shadow singles tag tape thread victoria visiting wage wings andy avenue bags beating believes blocks boring charlie checking clock commissioner commitment confident containing copies crimes custom denied desk drinks ear electricity episodes farmers fbi grounds gym helpful horror iphone iraq label liverpool locked naked opens output persons pitch pizza plain pushed raising rear reveal romantic scores sisters speaks stages strategic swimming welfare winners wire worker afterwards alright android anger architecture assist attempted behalf belt capture centers ceremony comic cops cuts dallas designer diamond disappointed dressed economics efficient electrical employed enjoying entering essentially establishment expecting explains flower ghost guests handed hockey houston https hunting industries islam jane judges kit lab languages maps min morgan moscow nervous newly odd ordinary participate philadelphia prayer principles racist rarely references sexy skill soil solve stomach struck studying suck supports trash ugly vegas virus walker whoever amounts anthony arthur aspect banned boost bureau colonel comfort controls cousin crack deck demands dies dragon dramatic dust dutch engineers evolution foods hired illness inspiration institution kings knife lately lowest memorial mexican minority mum opinions patterns presents priority promotion rail readers remote repair root saint steal stolen telephone tho titles trans ups vol whereas abandoned acquired actors alexander alliance annoying bid bro buddy buried butter cares columbia conclusion confirm congratulations contracts convinced crap crystal dean decent decline delay describes desert downtown elite enemies forgotten forth gods hire hop hopes insane installed israeli landing layer managing marry nah nowhere nurse obtain organic ownership participants pennsylvania poetry pot pray printed recall rugby sake sheet signing smooth spiritual stops string sudden sweden syria throwing thrown vacation abroad arab assigned associate assumed atlantic bench bother broadcast bye cambridge citizen cleaning compete consists consumers contributed cricket critics damaged disaster discover disney entrance equally fallen figured fitness francis friendship gary handling idiot intense keys lawyers lifetime liquid makeup medal mortgage narrative narrow nba observed occasionally pan physics posting potentially reduction reflect refuse researchers resource roger ross sciences seattle serves shell silly subsequent towns translation visible yep adds allen amendment angle arizona arrive belong berlin bishop channels clark commonly connect defensive designs efficiency enterprise experiment feb females findings firms forum gifts grass hence increasingly incredibly jay journalist kicked lessons lists maintained mill occasion oxford pace passenger pen pope possession races rapid regulation resident rocks shaped sixth spin styles subjects sucks suitable thirty valid vital whilst agriculture alleged anna atlanta bands christians collect commerce cop creek currency emotions exhibition fraud funeral genuine gordon honey honour hook hunter immigrants improving instructions introduce kansas lands legacy log matthew merely monitor nov patrick phil prisoners programming publishing ratio regret rejected remind resort resulted reverse routine scary seed settle sin spell summary survival sword tongue ward waves wayne achievement anderson argued asleep austin automatic begun behaviour cents coat comprehensive consent daddy destruction diego diseases divorce doc drove ears engage extraordinary fate frequency gaming gene glory headquarters heritage initiative interviews jean juice landscape logic meets melbourne microsoft objective organisation privacy procedures profits reducing regard representing residence roughly salary scoring script searching sections strip surrounded threatened transferred tube universities walter wisconsin writes ambassador ann apps awarded banking breast cant carter chelsea chemistry concluded consumption corruption cotton crossed detroit discount dozen engines epic exception exit expand fancy gorgeous grateful heroes holes impression inches indicate input johnny josh knock leather lips luxury lyrics manufacturers masters movements oct operated ought outcome painted poll preferred pulling ranked referring removal rep reporter rio risks rob screaming sept sequence singapore stretch tear tennis terrorist theater ties twelve versions virgin voices wishes wolf absence agricultural asshole ate athletes bears blues boxes bruce bull cameras commonwealth contribute contribution contributions couples delicious deny deserves ease extend fame flood generated genetic glasses impressed indicated instant investors involves kate kills liberty maria ministers monitoring occurs passengers photographs principle producers progressive punishment rally rapidly reader representation restaurants reveals roots samples shops sum swing tail texts twin upcoming veterans alert arena arguments aug billy boom boots brave claiming column commit compensation composition computers conservation constitutional crossing defending density difficulty dropping drops elementary ethnic expenses fleet foster fuckin fundamental gen genius greatly guidance hospitals infection instagram intention iowa jokes knee mechanical nigeria parks participation periods precious pregnancy premium preparing pretend priest prominent proven radical remembered requested residential reward rings robin russell satellite shake shore spots stats struggling substantial teen temperatures transmission trap uniform wildlife wooden ads aggressive anne answered apparent bang blast bones brands centuries communist complaint component connections courage cure del desperate diversity duties encouraged eve faculty feedback fighter frozen guards hiding humanity ian innovation instruments invest jacket justin legislative listing manual mothers murdered nursing occupied ongoing operator painful pound preparation punch purple railroad registration releases rick romance submitted sufficient survived suspended technologies tissue trailer trends trials ukraine underground versus virtual walks wounded ali amongst announcement arranged arsenal attending attracted biological bite blocked boards burned categories checks chip concerning dare database define discrimination disorder distributed districts documentary domain dynamic edited engagement explore favour fewer footage giants grave hamilton implementation indiana investigate jazz jon jonathan laboratory lawrence lincoln literary mask massachusetts midnight minnesota mouse oscar packed piano praise presentation psychology relation restrictions rocket ruin saudi sean sec secrets slave stability steady stones symbol terminal toilet treaty triple unlikely updates vietnam viewed affair agenda bat bow calendar cape collective conversations cooperation craft darkness deeper devil edit enable equity estimates failing finishing fortune gates goodbye graham hardware hillary hurts intellectual invite involvement kentucky madrid nuts oregon partly petition phrase physically protecting racial rated regime rivers rounds ruled sauce seal separated shield similarly slide stem summit talented throat tiger touched toy visits warriors wisdom accounting alien attacking awkward beast beef candy carrier celebration celebrity certificate cited clay coaching colleagues constructed dated dec default delhi derived dialogue disabled distinct drag educated eligible estimate execution existed fifty followers fool framework franchise funded furniture generations guaranteed integrated intelligent interaction jet journalists lifestyle lighting lisa loop mall overseas performances philippines polish recommendations recover regarded relax reliable rely remarkable responses ruling sacrifice sole stopping strategies succeed tables tale targets timing ton volunteers witnesses wore worship worthy acted alarm bass bloody breathing butt characteristics cnn collaboration con consideration counts creates crucial daughters dependent discussions drives dual edinburgh equipped expanded experimental feeding filter galaxy globe grades greece gulf highlights hoped intent involve judgment kennedy knight larry las lmao logo malaysia mature moore nazi netherlands odds peaceful philip photographer pin prevention printing promoting publicly pump repeated replied requests revenge satisfied seeds signals slip spaces spare specialist stocks stranger submit surprising tap thompson threats tourism turkish volunteer acceptable allies attempting auction bonds challenging chaos churches cleveland composed concentration copper corp corps counting credits dawn dispute earnings editing executed firing fits frequent gardens gathered hilarious huh ignored improvements investments isis margin mars maryland mechanism moderate murray oklahoma opera overcome parallel passage pit psychological publications quest radiation shocked sized stroke stunning tanks tokyo topics trains traveling treating tune utility vessel weed wherever acquisition addressed alabama alice angels anime announce autumn backed barry bold borders breathe cameron choosing classical classified clip coaches coins concepts conspiracy controversy convince cooper disappeared encounter equality exam examination fails federation fiscal guardian homeless instrument intervention jerry lover mainstream menu missouri mounted mutual nope occasions offense oral panic pays peoples pursue realise refugees removing requirement responded rip ruined scope segment spectrum stays ted terror venture virtually waited warren worn yea accompanied adams aids aimed alpha approaches arguing arrangement beliefs boats boundaries brick brooklyn colleges considerable conventional danny des designated dvd emperor employers enormous errors focusing forgive gains garage gathering guidelines handled hosted indians indonesia inquiry inspector jumped khan lion loaded lonely maintaining measured mercy nevertheless newspapers outer oxygen pipe pissed poem powder powered promises quotes racism ratings reads recovered refers roy rude screw seventh shelter signature sooner spider stewart strikes suggesting suits toys tracking tribute trigger vary venue wages wells wheels abc abortion accuracy albert applying artificial belongs beneath bitcoin bullet burns carl celebrated consistently conversion copyright counties democrat deposit destination dirt diverse divine emails exclusively export fastest formerly functional gather grandfather habit harvard indicates isolated jealous knocked landed laughed laura lazy mama marshall mitchell modified municipal naval neighbors nelson neutral noble oldest pat picks poland popularity professionals pussy reactions relate robot sacred securities shoe speakers springs spy steven suggestions supplied susan suspension terrorism terry toxic treasury tunnel unions upgrade warrant wider wound aaron actively afghanistan applies arrangements asset assuming backing baker barcelona blessed brazilian brush burden campbell carries casual certified charter chef civilian coalition cock complain complaints controversial denver describing differently directions discipline discussing disgusting dominant earning emma essay expense explaining furthermore graphic greg healing hiring hosts implemented instantly invasion jacob jumping laptop legendary leo maker margaret mario opponents outdoor palm parker photograph pole pub quarters queensland rangers ranks reception recipe regulatory reviewed rolls rubber secured serial settings shed snake sponsored stealing strict subsequently substance suggestion switzerland syndrome tasks trips ultra unexpected usage utah worlds accidentally affordable amateur appeals argentina baltimore batman bearing beats bin biology bobby briefly canal cancelled charlotte cheaper christopher climb com competing completion cruise custody delete demonstrated departure developers developments dig eagles employer evans explosion fever fluid folk generate gop handsome holidays hotels imagination integration integrity interpretation leaf legitimate lightning loads longest magical mills motivation nasty oliver outfit pension permit perry plates pleasant portrait productive reminds reserves ron safely shirts shorter slight socialist streaming sue targeted tension thailand theories touching transactions twist ugh unemployment unity useless viewers winds woke wtf abilities advocate aims arc backup beaten bitter blown branches campaigns chips cia clever clinic closest collections continuous converted correctly creator creatures criteria declined detective difficulties disability dish douglas duck egyptian evaluation excess farming fence fifa fighters flights forcing forming franklin fred gradually gravity habits hawaii highlight holder hood hung identical imperial investigations jose ken legally lied listened males manufacturer meters nail nasa negotiations nonsense ontario operational orleans owns phoenix playoffs poet quoted relating repeatedly robinson rolled scientist sink skip slavery snap sorts souls stole swedish swim swiss tennessee transaction transformation veteran vulnerable wealthy additionally amy attract barbara beta blowing bored bronze bug caring catching cave cheating chronic cleared communicate convicted cultures dealt delayed demonstrate departments depend developer diagnosis dismissed distinguished dose eighth experiments flesh flip forty generous germans hated implement incorporated influenced jerusalem kidding laser loyal marijuana mentally missions occupation opponent paintings patch patience pic pointing pollution precisely prisoner privilege proposals protests punk radar regards relatives resist solely stepped striking terrorists tourist transit trucks trusted vessels villa volumes websites wireless wondered wrap wright yoga adopt airlines alaska albums anytime bacteria beings beside blade boot bottles bucks bulk camps cargo census christianity coastal coin colored commentary confusion congressional corn cried customs dealer deemed destiny distant electronics emerging emotion emphasis ethics excitement exploration fights filling filming glasgow graphics helen humor insight invested jennifer lit louisiana mar marie meals mississippi nerve netflix nightmare operators overnight partially participating pie platforms populations poster practically preserve produces qualify raid ram ranging ranking receives respective restricted routes samuel sandy scenario sheep situated slaves sony spotted spreading stanley sustainable sustained taxi themes threatening tobacco trace trapped turner uncomfortable wasted weakness widespread xbox accepting accessible acknowledge advised advisory animation assignment balanced bare basement bases battles bias birmingham bits cancel carpet ceiling cherry chill classification clue codes cole collapse collecting compound conscious consecutive contents costume craig deleted devoted didnt displayed dominated earl endless escaped examine floating garbage gospel grain grid grows heating identification knees lap lions liver metro metropolitan mines mixture nominated oak parliamentary patent perception physician portland proceed proceedings pupils reserved restore rifle rival runner sadly shoulders significance sits sizes slept soap spray stored stressed structural suite tbh tropical ukrainian unnecessary verse victor vintage warned watson acres adapted adoption anonymous antonio approaching artistic attendance aviation barrel beds beloved bless boxing celebrating charging chemicals chuck cinema colonial comics compliance contrary controlling corporations couch crush dam decrease defeated diabetes dressing expanding fears fires genre gentle grammar hiv idk illustrated invented jake jam jamie jessica keith kent layers lease lens licensed loyalty madison magnetic metres monsters mysterious notion partial piss placing propaganda rat reflection reminded resolve revolutionary scandal shine simultaneously substitute surveillance tactics testimony thai treasure trophy tweet tyler underlying unfair villages von acceptance accidents affects annually apologize appreciated approached arriving ash aunt benjamin blake bubble buyers casino charts clouds connecting counsel creature deadly decides der desired determination embrace emerged exhibit flew gentleman halloween hammer hitler hosting icon imposed indigenous infinite installation inter interactions introducing iranian kicking laying legislature liability maine makers manhattan marathon marvel michelle moreover mps neil organisations ours parade paradise perceived pics planes politician preliminary premiere presidency reaches react realistic remarks retain roberts rocky russians saints satisfaction scratch shade sheets sheriff shy sometime spirits sporting strictly sunshine teens thou tier tommy travelling vancouver vocal warrior worries yield accomplished admission adventures aka appearing bacon barrier belgium believing blacks bombs burst caps casting cattle classroom collins colours compromise convenient costa criminals crop earthquake elderly eliminate embarrassing farmer finest grants harbor harvey hates incidents inform ion jeremy lesbian lovers mathematics medication minded morris norway par podcast portfolio productivity promoted protocol quietly rachel replacing responsibilities salad scholarship screening sends smiling soup southeast stake stating strain suspected swift tackle tigers timeline torture traded translated tricks twins urgent vegetables vertical violation wallet welsh workshop wrapped aboard abstract accent addiction associates awake beam beans binding blank buffalo cbs commons conservatives contacts conviction corrupt cow curve depressed deserved dining disorders duration eddie emily encouraging farms fifteen flows genes graduated grandmother harsh heights horn hurry immune inflation ingredients inspection install instruction intensity inventory investigated invitation judicial justify kyle lakes lean lecture libraries logical mason meaningful migration missile motivated muscles nancy norman northwest nurses organ patrol pearl peer pepper pig pile plug provision releasing requiring revised rod scream stairs staring statistical sticks strangers succeeded sweat switched syrian tattoo teenage thunder tours tragedy trauma vincent wrestling zoo accordance acquire activist activists addresses alike applicable arrow availability bend boundary breach cabin cage chancellor cheers circles closet combine companion comparing consciousness consultant controller corresponding courtesy cuba damages demanding disc dishes dozens eagle eaten embassy engaging fascinating financing fitted flexible gaining gentlemen goodness guilt haven helicopter homework households iconic infected keen kenya lesser liberals lip mandatory manufactured mechanics mere miracle mud murphy nathan observation operates owe permitted phenomenon pittsburgh playoff precise profession prospect protective providers publisher putin reportedly retreat rookie sandwich seeks sentences separation sexually ski skilled sterling stuart surgeon theft understands valve visa washing adjacent agreements appreciation arabia athletic authorized banner beijing blew blocking brad caribbean charm chasing climbing colony complaining cookies cruel curriculum deadline deer delta demanded dive divide easter electoral eleven entity excessive exercises feminist governing ham heal interface ios jewelry journalism juan julia jungle linear occasional oriented pete pilots prayers predicted pressed preventing prof provisions pursuit rap reflected reminder restored resume rev richmond ridge samsung scholars sealed sounded sri streams strongest tends tribe unfortunate variable victorian worrying zones ace adjusted alternate arrives artwork ashley athlete attraction babe bankruptcy canon capabilities cared catherine chains closure cognitive competitors connecticut convert cooked cups deciding defender dental diplomatic divisions drum editorial enabled entertaining est establishing eternal freeze generic grandma grip handful happily harmony hmm humble hurting hybrid intentions investing keyboard lasting locally loses mild minimal mixing molecular nearest neighbor noon nowadays openly overview pairs palestinian parish pathetic poems possibilities potato potter preference promising proportion purchases rage reflects respected restoration selfish sergeant silk stamp throne thy urge voter warner wasting witch advantages ally archives array assisted backs belly booth breakdown bridges brutal calculated cam centres chapters citizenship civilians cliff conflicts consensus cycling declaration dennis derby distinction donations dragons draws examined facial faithful fatal fig fitting genuinely hardest holland honored hunger hurricane implications import innovative ipad jurisdiction laughter lemon les lifted loading lung matching mighty monetary novels nutrition ore outcomes outta pine polls poorly portugal pose pour proteins provider publish purely ralph rental resolved rewards sang seemingly senators severely shark shocking southwest studios survivors tales technically titled traditions unlimited washed watches advise anxious appearances bee bombing cafe carlos challenged cigarettes colin consisting cult dairy dakota darling delighted delivering destroying diary disagree disappear drill earliest edges entries euro evolved exports fixing flags flies forecast governance heated hug importantly indicating indoor influential intend invisible jeans jets julie karen lasted lawsuit leak lighter lucas marcus mentions meter mice musicians olive passionate potatoes prevented receiver recommendation riot rogers roster safer sells sentenced servant setup skull slot smash statue surprisingly surrender suspicious teenager tender thoroughly todd treatments tweeted vacuum variations wont acknowledged advances agrees allegations anticipated approve architect basin beneficial bleeding breed breeding bride broadway bros bud butler careers cartoon celebrities chick coke comparable confirmation console contractor contributing diameter dubai dublin dump duo dynamics elephant enhanced essays exhausted fabric fabulous fairy fathers focuses fold freak frustrated gambling gently glorious grief harrison historically hub hughes inevitable investigating labels lacking laughs layout lined lodge lords merchant merit micro myth nintendo objectives obsessed organised overwhelming pale particles pastor penalties permanently pets pockets poison predict presenting presidents pressing prints provincial raped realised rebel repairs rotation separately shaking shaw societies solved starring struggles subtle tastes throws toll tooth torn tragic trainer transformed unbelievable underneath variation viewing viral warehouse wears widow wives adjust administrator affecting allied altogether animated answering assess assumption assured austria avoided avoiding basket beard bio blanket brains bucket burger capability charming chiefs commented computing concentrate conducting consequence continent cookie cruz curse displays drain emissions ethical excellence flame forests freely fruits grabbed graduation hint horizon hostile imagined inhabitants ink inn intel kicks legends lucy magazines matrix measuring miserable momentum monkey montreal motorcycle nationwide nest newcastle nicely ninth nomination notable obligation optical outlook penny petty phd ports preserved programmes prospects publishers quantity quantum rainbow rebels recognised reed reign responding retained rises saves scan scare sectors shorts span specialized spencer submission sunny supporter testament toe tops tremendous valued wounds accommodation achievements addressing adorable allegedly ambulance ashamed assure bailey ballot batteries blessing btw cemetery chambers cheat cheer chile cigarette compact completing consulting cooling corners deficit demo demon demonstration detected detection doll donated elaborate elder encountered expertise exploring fiber filmed fried grocery guided guinea halfway happier heels holmes hull independently indication insisted instances intensive interactive intimate laundry lbs lifting linda martial nigerian northeast observe packing panels password pokemon politically presumably pretending priorities pronounced prosecution proves pulse purchasing qualities queens rational realm reforms revenues rides ripped rope shadows shout sierra smartphone specified spectacular stan streak subscription switching technological temporarily tolerance tourists traditionally traveled treats unhappy whites yup accomplish adequate alter apology arkansas attributed beg belonging booked bout bowling brass buzz clarke comeback cos crops declare designers detect diagnosed diesel dimensions dip disturbing doesnt dot dresses dylan effectiveness eliminated ellen embarrassed exceptional filing fled foul frankly freezing graph hack hannah hatred ignorant influences interact judging knights lamp limitations majesty measurement measurements median medieval milan mobility montana murders nyc omg orientation oven owen passport penis pills planets proceeds rabbit raises ranges rats retire rhythm ruth savage servers shook shooter siblings slim someday sophisticated spam speeds stack stance static subway supportive surgical symbols tablet tent thesis tide travels wallace warfare warming weekends withdraw withdrawal youngest aging airline alternatives anyways argues audit authentic ave backwards blonde blows bolt brooks bugs bust clearing clips collar columbus comply cope counted crashed creepy cum denmark divorced donate drawings dried ebay echo editors edwards emotionally enhance experiencing extending finale flavor floors freaking gloves harper hart ignorance ignoring immigrant induced inspiring intermediate invention jesse joins joking lgbt likewise lineup logan magnificent mathematical meantime nails nevada newest nonetheless nut opposing origins orlando physicians pipeline placement planted pricing puerto questioning recreation renewed resigned shallow shanghai shitty singh sins sketch smells soda spite sponsor strengthen strings sunset taiwan thanksgiving thee thermal trades transform witnessed workplace yelling yorkshire achieving aliens amsterdam analyst arabic arctic assists bennett bristol burnt buyer calories cannabis cease championships chapel cloth conferences considers container cowboys crushed deployed differ dimensional eager elect elevated essence executives flames fork fur gps harold harvest headline hudson hype identifying impacts insist junk kenny kidney ladder lloyd lobby marc mechanisms mineral mob modest motors mph navigation nicholas orbit paragraph passive peninsula phillips pill pork portuguese profitable provinces ranch rays reasonably reject remainder schemes screens seized semester sentiment servants shipped socks suited supplement surviving thereby threshold til tin tires tribal tribes trunk uncertainty vampire varied verdict abandon accommodate accordingly aesthetic algorithm altered anchor angela apr arch associations audiences axis badge bernard bizarre bounce broadcasting bullets buses cannon carol carriers chairs cleaned complexity confusing consultation continental convenience deliberately diamonds diana dictionary dignity dimension disappointing diving doug duncan ego enthusiasm environments equation extract favorites ferry fisher flexibility flowing fridge functioning fusion gauge goat graduates gut heck helmet holders ideology idiots inclusion initiatives innings insects instructor isolation ive justified keeper lamb liar machinery mansion mega mercury namely nbc needing nerves nhl observations ordering palmer paths peers pending platinum possess praised premises probability questioned refuses resignation rider ritual ruins shelf slam stakes starter sticking subscribe superman surfaces territories tire towers transfers utterly voltage warn width workout abu activated adaptation advisor aluminum apartments attitudes attorneys bail barriers belonged bradley brandon broader buck cal caroline characterized civilization congrats contractors creativity dealers delicate den derek desires disappointment disk enters evaluate formally frames goddess gov hampshire harassment hats hugh insert joan lebanon leeds legit leonard liquor loser malcolm massage matched messed milwaukee musician nato nephew notably orchestra packages pad pakistani participated precision preservation priests privately prizes pulls qualifying reasoning relaxed reporters roses rumors sail salmon secretly seller sen seo sheer shifts simpson smallest specially stark struggled sympathy tan teenagers theoretical thumb timber transparent travis tweets upside urged visitor vitamin void voluntary wheat whip wipe wolves wrist abused acute admiral amanda arnold arrange banana behave betting blair borrow camping capitol celtic chan chin civic clerk conclusions considerably contacted cottage coup criticized crude dash decreased defended demons deposits disclosure disposal distinctive documented donation dragged drone encounters ensuring enterprises escort exams firmly flour gdp geneva hindu holdings indie indirect inspire institutional interim interviewed java jefferson jerk karl kindly kindness leaked locals lottery louise magnitude minus nhs noting nude organs outlet outlets parameters pause pledge portal prescription protesters proving publicity punished puppy recruitment screwed shades shakespeare silicon slice spelling spurs subscribers surveys survivor telegraph tits vaccine vinyl westminster wished wonders accurately adelaide affiliate alfred asylum barn bent bernie brussels cathedral centered clause cluster complained compounds consistency cracked cylinder dancer deaf debts denial digging dock entrepreneur evident expectation expedition expressing extends facilitate failures feat fossil founding freight generating goddamn guides honesty inappropriate infant initiated injection instrumental insult interference interstate julian launching liking linux luis mates mediterranean neat negotiate neo nicole obligations offset outbreak pal palestine perfection pigs pirates posters practicing praying probe prohibited projected propose quarterly recipes recruiting refusing rehabilitation reid remix resistant reynolds riders robots rockets roller sailing shapes skinny slipped sneak solving sore spark speculation steep stevens straw successor targeting triggered troubles uncertain upload vector violations weigh whatsoever wicked abraham absent acoustic adapt ancestors archive atomic bean bicycle bryan bump buttons cart circus claire cocaine cohen colleague compelling compiled complications construct cord crowded cyber dale debates defendant delays dense desperately doctrine expose financially freshman furious gameplay geography gig habitat harbour hazard hydrogen implies intact intake irrelevant jaw jin kitty lauren lawn manufacture martha medals mercedes mistaken moses nashville nebraska needle olds organize ottawa oval pity pond porter portions prey prophet raymond recalled reduces referendum refugee regulated rounded ruby rushed sanders satisfy scales seasonal segments sensible sequel shifted shifting shining slower spinning stanford stepping teammates touches township travelled twisted usb vienna wade whale writings admire amber ankle armor autism bachelor berry billions brady brisbane bulls bullying capitalism caution certification characteristic clan clash columns compatible concerts condemned configuration continuously convincing coupled curiosity delight determining entities exceptions explosive flooding fortunate fortunately foundations frontier frustrating frustration geographic glenn grande grasp handy hardcore harmful headache hers hispanic incentive inclusive infections jackie joel kissing lanes licence lungs madness mandate manga memorable merger minorities occurring organizing performs poker portable priced quebec randomly rankings realizing resign revealing rico robbery rub runners sally scattered scout searched sexuality shouting slap steak succession superintendent suspicion sweep tactical talents therapist thereafter thorough tuition tumor usd variables varying wholesale wwe administered affiliated apples architectural artillery assembled bangladesh barack beaches bees boarding bothered canvas canyon casey cheek chen cincinnati circular circulation clearance closes coincidence comedian commands commissioned concentrated conscience cooler countless curry dame deceased dedication defining detention disputes drake employ enforce explicit explicitly eyed florence flu forbidden fraction hes infantry integral investor janet judged katie kidnapped lectures lightly linking maintains marble maritime melt modes monica mumbai nominee oath offence packaging patriots pee pillow pirate polar prediction preview processed pursuing puzzle rapper rebecca reconstruction renowned revelation sara scholar sharks shoots skirt socially spa spike sprint stir stuffed substantially suburbs superb supposedly tab tendency theirs toast toes touchdown traits trek tricky triumph uber underwear unto viable waist welcomed wit wreck absurd accessories adrian advocates ambitious amid annoyed appealing appointments assumptions ballet bargain binary blend blogs brake builds businessman cab chi col collision colombia compassion consumed corrected correction cough cousins critic czech defenders denying depot distress documentation doubts dramatically drank dudes eats elegant elevator ellis exchanges excuses execute factories feast finland frederick frost goin herald hike hollow homeland imported ing internationally iraqi itunes kane kissed lame licensing lily limiting locker mainland marking meditation messenger metals missiles munich norwegian pencil philosophical pierre pipes plasma plea punish purse quarterback reagan ref relieved replies reservation rhetoric rivals rushing salvation sanctions secular sensitivity shane sigh sixteen sovereign specifications spends spouse stat supervisor synthetic teaches tense terrifying toyota tracked traders troy varieties vegan waking walmart wang wilderness admits adviser aggregate anal anatomy annie announces applicants automobile barnes breasts cement chess citing colonies composite consequently consist councils cox curtis decorated delegates dreaming dull enables fare fashioned feared float generator grind grinding grove guessing gum hobby hunters idol illusion incorrect jun junction lance leap locate locks lou lynch manages masses medicare modeling motive nazis neighbourhood networking newer newton oppose optimal overtime packs permits playstation pops postal predictions prep profound prosecutor rebellion recipient refund remembering rescued risky robust scam sci sep shareholders sided simulation sober spice squeeze storms supervision suspects swap swept terrain terrified themed threaten thrilled towel trio tubes unconscious und varies vegetable verified vibe virtue wifi wishing workforce zombie acre airports alot amen andrews arise ashes automotive battlefield begging berkeley bloom bore bundle butterfly buys casualties catches chad clown committees conjunction costly cows cries cuban cycles darker davies descent desktop dial directory disabilities discharge discusses dodge downs drilling drums elimination enjoys espn ginger governors guild halt han henderson ibm imaging implied impress inability incoming isaac jar kay leicester liam litigation mentor merchandise minerals miners monk neighborhoods noah norm obtaining occupy offended orthodox overhead pac painter perth pierce pistol printer prone raiders readily reflecting regiment remembers reunion revival sanctuary satan satisfying seas securing sensors seoul shells siege sixty sleeve sonic soundtrack speeches spine steering substances sullivan sustain tenure texture thankful translate treasurer triangle unclear upgraded venezuela venice vladimir wizard yankees absorbed admin affection airplane altitude athens attributes baked baking beautifully betty biblical bmw boo cardiff collapsed coloured competent countryside cracking crane debris delegation demographic descriptions donor easiest educate enabling enrolled enrollment essex exceed excluding expressions fierce forgetting gabriel garlic gaza gratitude hail heroin honda hooked illustration impose indicator inequality ins interpreted jamaica joey joshua journals leisure lend lengths leon lounge luckily manuscript marco marines mint molecules montgomery notification nova oakland outline pasta polite productions professors quicker randy receipt recognise reliability researcher retailers reviewing romans runway sculpture senses sensor seth sharon showcase smoked subsidiary tampa tenth theology topped trails underwater uploaded velocity venues wax wikipedia winston yay accountability aerial albeit alcoholic amazed ambition ammunition anthem architects automated bake batch borrowed carson catalog catalogue charitable christine clicking collector compliment consisted continually coordinator damaging danish def deployment drafted enjoyable exotic exterior feminine firearms fountain fury genocide glance glow hay headlines hebrew hometown humanitarian hungary idaho immunity implementing inherited killers labeled lebron liberation likelihood lone massacre meme mitch mod nationalist nationals necessity nickname nixon observer offshore optional papa parked paste pioneer plaza prescribed pressures prosperity recreational reds refuge religions renewable richardson ricky rode ronald sack settlements sheffield shortage skies smarter smiles sophie sphere sponsors stamps stare suburban sung suppliers tablets terribly territorial thirds thriller toss transgender troubled turtle verbal violated vocals wool yang accountable advocacy aftermath aggression analyzed angles arguably armies armstrong assessed attractions balloon beers bells blamed blunt boobs bosses brakes brigade bulgaria burial canceled cardinal champ champagne cheated chorus chrome clarity classics cleaner combining conclude confidential coordination cracks dancers delaware directing discretion ditch dome dope drought ducks dumped elevation entrepreneurs epa esteem eva explored finances finishes fog framed fucks gesture ghana gibson gif gilbert gosh griffin historian horizontal hospitality hostage hottest individually inevitably jeffrey kenneth lad lakers lasts leagues leslie listings literacy marriages migrants mins misleading moisture monument mortality notices obsession opt particle peanut penn persistent personalities petroleum pharmaceutical progression quinn rack rebuild recordings rejection relaxing reservoir respects riley scrap sebastian sensation shaft shepherd shuttle slope snack sounding specialists spotlight stabbed stern stiff striker sudan sued sums sworn tel terrific theres titans tomatoes tory trafficking transparency trinity unemployed unite unlock vault vet vince wagon walt withdrawn accessed adverse aiming allah alumni ana awhile aye bastard behaviors bikes biography broker browser bury cellular cocktail cod conditioning consuming contracted costumes counseling crews cubs cuz dangers designing destructive develops dislike doubled doubles economies embedded emerge excluded expects farewell feeds fist fond foolish frog fry garcia gifted hacking hawks heir highlighted holocaust homer hon hopkins imprisonment indonesian irs isnt jenny lacks landlord landmark lanka launches leaning liable memphis midst misery module mommy monroe mosque moss museums mvp nursery obamacare onion perspectives peru phrases plague plains positively powell prevents profiles pursued raids recruit resting rex rogue roosevelt salaries seated sharply showers sincerely sings solidarity specialty supernatural surprises tens thirteen tomb touring traces trademark trim umbrella utilities voyage weaker willie yields abbey accepts adjustment andrea assignments attachment baron beatles belfast blah blaming bomber bunny candle carved choir clutch coconut committing comprising confession consume corridor credibility credited critically dem distracted dolphins estates ferguson ferrari filters fools fourteen geometry ghosts gossip grandparents haul header headphones highways holly immense imports incentives interfere intersection investigators juvenile karma knocking kurt leaks leverage lil lining luther manila mankind mapping masks med metric militia naming ncaa nike node obstacles opener overwhelmed performers pointless poles preferences prompted proximity qualification qualifications ranger rendered rented reversed robbed sadness scenarios selective seniors shiny socialism sour spoon stressful stretched sucking teddy tenants terrace thief transported tribunal undoubtedly uniforms verify villain whats whistle workshops yale yearly yemen abusive alley announcing appetite backyard beth beverly bids billboard blades boris bully burke cables calculate calculations chicks conceived consult crashes crowds cunt damned dissolved distinguish dominate dynasty economist endorsed europeans examining extensively fda festivals forehead foreigners forgiveness gem glen graves gregory haunted hayes heather hiking hypothesis illegally illustrations inclined informal jew learnt lending marker marsh marshal maturity maya messy mia minneapolis molly morrison mtv muhammad neighboring neighbours ninja optimistic outlined owl parenting peaks pharmacy pools preparations problematic proceeded processor promotional pros prospective psychiatric regulate renaissance repeal reuters riots roast robertson rubbish saga salon seventeen shields sliding sodium surplus swallow systematic theaters transmitted tuned unacceptable unaware uncommon underway unified unstable upstairs vague wee woo zip abs abundance advancing ahh alberta ant antique autonomy baptist behavioral biden booking breeze brett browns canadians carnival commodity congressman containers cooperative coral correlation correspondent coupon covid crosses curtain curves defines delivers demonstrates dentist dodgers dough dug endangered envelope exhibited fade fatigue fellowship fictional fragile fringe fulfill gaps granite greens handbook hardy honors insights instinct inviting irony ivan joyce judgement judiciary jumps lads legion lethal lime lively logistics lowered lynn maid manning manuel maple mickey midfielder mindset mistress moms mon monkeys morality mortal mounting nonprofit nsa oils operative outs owed panama patches pickup portraits pouring prestigious prompt quantities radius referee relay rig risen rows sacramento scroll searches smiled snacks snakes sovereignty strips stunt subjected sucked sunlight surf symbolic sync taxpayer tempted thrust trevor trilogy url weights wheelchair whore wiped yahoo youre yourselves accompanying accusations acids administrators aired allowance andre apologies arbitrary atm autonomous averaged bait bark bets blogger bra brighton brotherhood buddhist builder cakes carriage celebrations censorship clarify climbed comp compilation composer comprises constitute correspondence cowboy defendants desirable devastating diagram dismiss editions erected explorer farther favorable feminism flaws forums freed galleries gasoline genesis geographical governed governmental grandson halls handles heavier herbert hints incomplete incorporate interrupted ivory kerry kirk lang lengthy levy manipulation merchants misses mlb mock necklace niche nina obscure para peterson popped porch portrayed possessed princeton proposition railways readings recession richards rim seals secondly sequences settling sherman spinal spiral spit splash stretching successive superhero taxpayers therapeutic threads timely tomato tub ufc undergraduate undertaken uranium utter vietnamese volleyball walsh wires yell advertisement analysts analyze atmospheric bangkok batting bitches bracket branded bryant cairo cardiac catholics commanding confirms confronted crashing crawford creep daylight dee dems devon disclose doe donna elbow encourages enthusiastic envy establishments exile exploitation felix futures gel genetics goose grill grounded hating heel heroic hut inmates instructed ira jenkins johns knives louisville malaysian margins marina mat melissa milton miranda monopoly nash nationally nobel norfolk outrage owning pains paperwork pdf pitched poets poisoning promptly que rains recovering renewal repeating rifles robbie ruler screams sellers sights sincere skating skiing slaughter smashed sox sperm spill steadily stripped supplier swamp swan switches synthesis tasty tattoos teammate testify tolerate tournaments travelers treason trustees typing urine vanilla vermont vic vii violet weighing wendy activation afghan afterward agreeing ahmed allocated appealed applause bald barrels boil borough boyd breakthrough calif charities cheering chooses churchill combinations commenting competitions cone connects convey critique crushing curved cyrus decay declining depressing dessert destinations diagnostic diane differential discourse distances dominance donors downloaded economically entertain evaluated exploit fireworks flown floyd founders freeman gandhi gateway guarantees humidity humour imagery imply indicators inherent inland inning innocence investigator isle ivy justification katherine lego licenses livestock liz llc mafia manners merry mick missionary nationalism naughty nepal newman notified notorious obey olivia organizational outfits outright overly oversight panthers persian phases photographers polling popping prisons prototype pumpkin pumps punched ramp rand reactor reef refined refreshing refusal reinforced remedies reset sage shave sickness simpler sinking slots sorted staged startup statute stems straightforward strengths suffers superstar telecommunications thieves thoughtful thru tissues toddler utilized vicious victories vikings vodka wholly zoom accidental accounted addicted adjustments apollo archbishop assassination athletics basics bats belgian bibliography bot broadly calcium calvin candles capita certainty cheeks chickens christina citation clues collectively commercials commissions compression comprised confess confined congregation consolidated coordinate coordinates cube dana declaring decoration decree definitions deliberate despair discovering dividend dragging drift dye eden educators electron endure enzyme evolutionary exhibits extensions fellows fragments fraser fuels geological globally grams guru hacked hans hatch hindi historians hormone inadequate indianapolis infinity intentionally joints kilometers labs lace libya losers louder maiden marching marketplace membrane messing metallic methodology modifications monitors murderer nap nickel niece nominations numbered offerings overlooked pardon partnerships persuade pier poured practiced predecessor premise quiz rainfall recipients reckless redemption relates relied remedy replay revision rooted scent slate spells stimulus strengthening structured sunrise surge tagged tags tapes tee testified timothy token tornado tracy tunes tunnels twilight unprecedented vagina verses vocabulary wellington whoa willingness woody worthless yacht aberdeen absorb accompany accord advancement albany algorithms alt alternatively anglo archer asap assurance barber bash battalion bidding boycott bricks bruno buddies bulgarian carpenter ceased chester coding competitor creators cuisine detained dioxide dolls doom dubbed eclipse eighteen eleanor elephants enjoyment exhaust expired flee forbes forwards fries fundraising gal glimpse hahaha hawk healthier homemade honorable infectious inferior injustice inquiries insulin interpret intro jackets jill kindle lid lindsay logs manor masterpiece melody memo mic mirrors myanmar narrator nate nets nsw obesity partisan planting pony posed possessions privileged prolonged promo protestant pumping pupil recruited reliance relies reluctant relying respiratory retention rewarded ribbon rochester rodgers roommate rotten sands schedules selecting shah shawn shotgun singers snapped sofa solomon southampton spoil spoiled stephanie submarine suburb surgeons sympathetic taxation temper undergo venus weighed acquiring additions admitting afl aligned allan altar amp arrows atlas austrian automation awe balancing banning bishops boeing broncos builders burton caesar cans carroll cavalry clara coffin collectors colorful combo communism conductor confront constraints crow davidson decisive decorative definitive disclosed displaced disturbed diy doin epidemic eternity eugene evolve explode extraction fatty filthy fletcher flush font freestyle glue grandpa hairy homicide horns inheritance introduces ironic lacked lin luggage lyon madame maggie marion mel melting messaging microwave midwest minimize modi morocco natalie ops organisms originated ounce pablo peel pensions performer picnic pins practitioners predominantly primitive providence psychic psychologist puppet reproductive requesting responds restrict retiring retrieved ribs righteous rivalry rosa royalty sandra sausage seize sim skeleton spicy sticky sting sufficiently thankfully thrones tick traced trent trusts tutorial twentieth unpleasant unrelated ussr vacant vent vicinity wan wandering wardrobe warmth weaknesses wines wired amendments analyses asses assessments assisting axe backgrounds baldwin belle bites bombers bonuses bred brexit bubbles buddha bulletin capitalist cautious clinics commitments companions comparisons constable cooperate coordinated copied counselor curb dances darren deeds destined detached devils discounts distribute dong edgar efficiently eliminating elliott encouragement enforced evan explosives faction fascist feathers fixtures flooded fuller gamble goalkeeper grandchildren guardians harmless hearings hesitate hid hips hopeful horny hungarian hygiene iceland imaginary imprisoned inconsistent int iso jared johnston judy kindergarten latino lopez loudly mechanic megan mls modify neglect northwestern offenders oppression patriotic phillip pictured pitcher playground populated poses positioned prejudice preston probable probation projection promotes pumped rails raven receptor rehab remake rendering reproduction res reservations rey rhode shrimp similarities skins slopes spelled spokesman springfield stained stall starving strap subjective surround surroundings sweeping swinging tearing traumatic trillion tucker vatican vendor watts abbott aboriginal academics adopting alignment allergic allison amended apparatus assumes avengers backpack balcony banker bliss bodily buffer calgary chapman chopped collaborative commenced compensate compromised constructive conventions cosmic crystals daisy definite demonstrations departed depths developmental disco distraction dom dorothy doses drawer drones durham ecological ecosystem elvis euros exclude exempt exposing faint fertility fines finn floods flynn foam folded foremost forge greenhouse hears hierarchy ideals identities installations invalid jade jointly jung kits lancaster lightweight lowering melted metabolism neglected negotiated negotiating negotiation newborn newport nodes notch omega onions packers paired parental parody parole participant penguin phantom photoshop pitt precedent prevalent prom promotions python qatar questionable queue quo regrets render respondents retaining romania sailor seventy shouted simmons sims slides sociology somerset soo specify splitting stab supermarket sweater tenant tensions thomson tortured traction tractor trout turnover uganda unwanted upgrades variant vegetarian vernon visibility warnings wherein whiskey worms wyoming aaa abundant africans alexandria algebra analytics antenna attribute audition bankers biting]==]):gmatch("%a+") do frequenciaIndependente.EN[w] = 2 end
for w in ([==[que para nao uma com por como mais dos mas foi voce ser seu sua tem sao das ele muito isso nos tambem quando esta meu pelo ela vai dia pela sobre bem ate mesmo pode pessoas ter tudo ainda aqui fazer minha anos todos quem sem agora entre era seus nas assim depois este onde vou brasil mundo estao esse tempo vida essa eles porque tenho casa nada the ver melhor bom foram sempre ano grande vez aos apenas coisa sou suas dois nunca todo quero mim parte outros hoje sei tao entao nem nossa faz cidade qual deus quer estou trabalho durante estado forma novo pra seja dias maior outro primeiro sera cada qualquer sim acho menos alguem antes coisas nome sendo desde diz falar sabe tinha contra dar boa estava tres alguns ficar mae pouco rio segundo alem disse noite nosso nova toda caso deve historia podem vezes estar apos duas grupo meio primeira tipo todas cara dizer paulo lado mulher outras enquanto fez ninguem outra momento vamos verdade voces foto lugar nacional pais presidente quanto saber sido volta for pelos algo conta familia gente algumas fim final parece semana acordo hora jogo num pessoa atraves governo meus pai quase tanto dentro filho fora homem vem video musica pois preciso vao agua disso fazendo horas janeiro poder dele direito mil muitos numa numero dinheiro queria seria sistema amor escola frente mesma muitas tarde local morte segunda amigos brasileiro precisa projeto regiao sair sul temos teve area dela esses lei partir problema publico site alguma and comigo embora guerra centro deixar elas essas estamos fica filme havia importante logo mal sob geral lhe programa social varios certo equipe feito neste seguranca terra estados exemplo falta favor serie twitter causa mulheres uso aquele brasileira criancas deste feira fosse isto milhoes populacao posso quatro deu ficou nossos policia processo usar ajuda cabeca cerca corpo desta fui meses problemas realmente tenha varias algum cinco desenvolvimento dessa grandes inicio livro medo passar relacao tal ajudar amigo claro deles existe pelas atencao chegar desse fotos informacoes los muita norte politica ponto possivel quais quiser rede universidade apesar comecou feliz gosto homens maneira nesse ultima dificil empresa estes fala forca internet passado rua veja base dados demais eram especial internacional manha nenhum olha pensar povo diferentes falando merda poderia pontos porem unidos atras deixa futebol mes pessoal proprio saude somos entanto maioria mao papel paz real talvez ultimo acabou aconteceu chegou encontrar fazem federal forte facil melhores minhas minutos outubro passa paises producao sociedade voltar educacao fato filhos fiz legal longo marco passou sinto uns acesso aquela campo coracao cultura estavam junho lista nenhuma pena portugal senhor viu certeza comecar consigo espaco evento filha oficial ouvir palavras perto principal setembro vivo unico alto apoio diferente entrar ideia junto levar maio nessa ontem porto propria servico unica agosto bastante jesus jovem livre lingua nesta olhos periodo portugues seis situacao serio time via acha amanha caminho carro deveria dezembro energia festa novas nivel questao respeito total vista abril acontece devido informacao ingles irmao jose novembro objetivo partido plano podemos sociais sucesso trabalhar vale viver america capital cima justica linha membros mundial nossas presente professor quarto seguir tendo teu ali acao cidades copa crianca estas grupos imagem jogos julho luz militar modo movimento novos ordem proximo tomar voz construcao espero fevereiro futuro idade maria mudar obrigado vejo visto acredito baixo chega controle direitos empresas jeito principais principalmente publica resultado sala seguinte traducao valor chamado comprar conselho daqui edicao encontro ira ler luta manter mensagem novamente obrigada organizacao palavra parar pergunta significa tentar teria tirar tua amo aqueles assunto central comum conseguir decisao devem faca houve joao maiores querem sentido sexo tecnologia texto epoca arte artigo casos comunidade criar facebook igreja longe prova sentir vontade acima atual civil colocar errado existem incluindo livros obra olhar perder pagina somente usando abaixo conhecer dizendo gosta mostrar participacao pedir posicao possui sabia servicos super areas achei continuar defesa deixou faco online original pequeno simples tive versao vitoria acontecer boca canal carlos comunicacao consegue contar feita ministerio morrer pegar pior resultados tera veio boas campanha chefe comer conhecido continua camara entender eventos mercado ministro maos resposta serao sol tornou trata ultimos busca conseguiu criacao dez mostra pequena pesquisa recursos republica santos show ambiente chama chamada diversas dizem europa finalmente ganhar http morreu passo politico portanto razao rei santa sexta simplesmente associacao blog casamento comeca data exercito hospital humanos interesse locais motivo pagar realidade rapido serem tentando tribunal uniao viagem vir alta ambos aquilo banco condicoes conteudo desses espera etc jornal mar obras pedro popular porta praia prisao responsavel revista senhora silva tais tema acabar americano ataque atualmente autor clube curso diversos forcas fundo jovens las levou liga presenca proxima radio sete tornar tras verde branco brasileiros comida especialmente experiencia fase importantes leva modelo natal nota opiniao oportunidade ouro projetos semanas sabado termos umas bairro chamar costa crime codigo diretor domingo encontra esperar estudos falou fonte gracas importa instituto john mortos noticias recebeu redes tempos tinham altura armas acoes banda companhia dando dessas dormir economia fiquei fizeram gostaria imagens jogar liberdade possa receber sabem sejam selecao superior tivesse velho atividades aumento cabelo cafe cultural desculpa dor ensino escolha faculdade fogo irma juntos pensando podia poucos primeiros profissional premio reais relacoes sorte televisao comissao diferenca digital direcao entrada estilo eua formacao globo humano indo lembra lider massa missao monte municipal medico negocio normal partes pensa quarta resto titulo visita votos you zona animais aprender cama certa conhecimento estudo filmes interior licenca linda mente mudanca municipio media medio negocios preco qualidade sai acredita aniversario celular china conversa corte delas escrever esposa franca ilha marca medida menina metade natural perfil portuguesa preso querer usuarios verao apresenta contrario esquerda ganhou incrivel menor natureza perdeu saiu sente visao abrir alunos capacidade capaz carta cedo conjunto deixe fernando fome inclusive lembrar lembro leste lugares matar meia parque proposta reuniao sonho transporte voltou achar conhece contas cor culpa dado departamento dolares eleicoes emprego escolas escreveu estrutura exatamente fico formas importancia interessante nomes operacao origem provavelmente risco santo suficiente temporada trabalhos usado beleza cabo esperando esteja lhes morto musicas necessidade oito queremos quinta seculo usa vive acaba americana americanos amiga anterior belo cinema classe comeco criado entrevista estacao historias lula material momentos mudou mexico necessario passando pedido perfeito porra pratica realizado sangue sede seguida som administracao azul carreira casas cena chao completamente cuidado escrito esteve funcao membro participar precisam pressao procura programas publicado torna totalmente ana andar contato crescimento crise ceu david direita entretanto espanha evitar guarda historico industria pro produtos professores protecao saiba segue sinal sozinho tipos traz unidade vila africa aula conversar deputado desejo diante espirito estrada festival geracao governador imprensa marido ola rosto ruim saida tiveram triste acreditar alma artistas bons caixa erro esperanca estadual familias garota igual lancamento lindo militares mudancas one pensei politicas politicos praca propriedade pre rainha rock terceiro territorio tiver vidas acontecendo antigo basta bola casal congresso estiver estranho general hotel impossivel infelizmente inteiro leve lixo longa materia memoria metros olho pediu penso post preto quis regras relatorio responsabilidade telefone tenham tom trazer troca verdadeiro onibus abertura analise argentina breve chance ciencia comentarios considerado contudo destino disponivel doenca efeito global independente investigacao iria jogador lisboa loja noticia numeros perguntas planeta planos precisamos pronto questoes tamanho tratamento vice york aberto acidente agencia aparece candidato conhecida conheco cristo dilma entrou escolher francisco frances japao lidar normalmente parabens permite peca policial publicos rapidamente reino sistemas vendo ato bonito categoria chave computador digo distancia episodio especie gerais irmaos minas new parceria passada prefeito pos realizada redor trabalhadores vermelho vindo votacao videos vitima ultimas baixa carnaval comercial constituicao contrato documentos duvida ficam fontes jogadores juiz meninas mesa mesmos naquele negro paris participantes profissionais quantidade roupa russia solucao web advogado afirma afirmou alvo banho batalha campos combate comercio contou dai destes drogas eduardo enorme entra estudantes face falei ficando fique fisica graca instituicoes particular partida podera provas regioes ruas seguro silencio teste tecnico violencia voto otimo adoro apresentar aulas auto bahia brasilia cheio comando decidiu deixando destaque entendo fazia frio ideias ligacao mata menino michael motivos nisso obter oficiais procurar proteger publicas referencia salvador serra solo tradicional valores ama artista assistir atividade bonita cargo carros danca descobrir explicar feitas horario internacionais lima medidas mestre padrao prazer prefeitura reforma representa resolver roupas tanta tiro trabalha velocidade aquelas buscar consegui deputados diretamente diario existencia explica foco geralmente google humana jardim link luiz melhorar nasceu nove opcao passagem perceber personagem principe puta regime regional responder sonhos sozinha terras torno trabalhando vim viva afinal alegre aproximadamente beber cair campeonato chegando clima completa conceito critica daniel daquele detalhes doce efeitos espanhol famoso funciona fundacao gay jornalista lancou londres medicos midia nacionais nacoes oliveira pequenos perda peso presentes rosa segundos termo usuario venha antiga anunciou apareceu artigos aumentar bebe branca chuva compra conforme criada der devia escritor fronteira funcionarios ferias garantir jorge lancado literatura madeira maximo nele padre pede pobre possibilidade proprios publicacao quente recentemente sabemos secretario taxa teatro terca universo usada album acabei aeroporto caiu calma certamente construir coragem correr criou cruz cancer dei elementos engracado expressao fortes genero haver leis lua milhares plataforma proximos queda realizar relacionamento resistencia revolucao seguintes setor sexual velha youtube agentes campeao candidatos comecaram contexto cujo dentre desafio dao eleitoral eleicao escritorio estara george identidade imediatamente louco mensagens oeste passaram pedra pele pequenas software surpresa tenta tentativa teoria terceira tocar tecnica india academia caracteristicas ciencias competicao comportamento consciencia direto entende especiais esquecer exterior fas gestao gostei inclui influencia naturais operacoes orgulho portal primeiras promocao predio temas verdadeira vergonha visitar aberta aceitar alegria animal apresentacao autoridade carne clara clique confianca corrida cuidar del distribuicao dito jamais leite levando movimentos ocorreu olhando paulista pedindo pensamento personagens policiais possuem posto religiao rico sentimentos tantas times tratar unidades veiculos world alemanha assuntos autores banheiro caras chamou contigo costas cozinha encontrado escrita feitos flores floresta gol golpe gas impacto julgamento ligar lutar mandar moral professora pes recebe reconhecimento seguindo serve terem venda volume acham alimentos capitao cartao cheia comecei cuja custo distrito decada economica enviar equipa estadio facto faixa ganha harry irao linguagem matematica meios maquina namorado ouvi palco parecer pecas prazo princesa processos ricardo sensacao vitimas otima abre aparecer assassinato assembleia bater bilhoes comuns depende devemos dominio estrelas ficaram humor iniciativa leia limites linhas maravilhoso mato museu namorada nascimento oferecer possam procurando programacao paginas sessao soldados terminar vencer agente almoco ambiental bela cadeia calor capa cenas chegada crimes curta discurso estudar homenagem live love mail mandou mantem mapa medicina merece ocorre pessoais ponte portas produto promover quantos reacao salvar sentimento tentou textos toma tornando trouxe autoridades avenida comentario concurso contem desenho divulgacao dou enfim estaria exposicao ferramentas formato fotografia gostar inicial instituicao intencao italia james marcelo milhao municipios notas organizacoes passei perguntar perigo pista potencial principio raiva sites sitio tantos top vender apartamento arma cenario clientes complexo conferencia confira deram discutir dom erros esforco europeia excelente falam faria figura folha habitantes infancia israel marcos mau naquela nela oferece peter precisar pao querido reserva respostas roberto russo san segura sinais socorro tela tira vento anti arquivos atitude baseado bateria casar chegaram cobertura completo corpos crescer criticas declaracao destas diga discussao documento dono emergencia encontram estrela experiencias extremamente fechar fundamental independencia leao localizacao minimo negra paul perdi pesquisas poderiam presidencia precos quadro quantas raio refere rica senado senador transmissao viajar all apresentou audiencia conseguem defender desempenho dizia encontrou engenharia fomos from grau inferno morta musical odeio parede perfeita posse poucas proposito registro servir toque viram vos with zero odio anda artes ataques comandante comecando culturais decisoes decreto dificuldades disponiveis disseram divisao decadas eleito entendi esporte falo fortaleza garoto guia henrique jantar leitura mora mostrou onda par perdido permitir poderes praticamente proprias publicada pudesse recente responsaveis rural senti seriam terminou treinamento aguas agricultura ameaca bar canto cheiro cliente colecao coloca condicao cores dada duvidas economico fatos ferro frase grave honra humanidade individuos inteira juro juventude legislacao lideranca localizado materiais minuto modelos novela paga parecem produzir provincia publicou rafael retorno rodrigo sabendo seres tomou tradicao utilizado visitantes washington arvores anteriormente bandeira bolsa braco bruno camisa conflito consumo corrupcao curto devo disputa dupla executivo exemplos felicidade felizes fins fossem funcoes havera infantil inves letras linguas menores miguel moda niveis parada piada pretende praticas rapaz renda representantes rapida saco status use vinho acompanhar agir andre anteriores antigos aonde arquivo brasileiras caro cidadaos controlar camera danos daqueles democracia enfrentar ensinar familiar familiares horizonte horrivel idiota imaginar inteligencia interesses justo latina levantar limite lucas lideres moradores motor oscar papa principios querida quilometros razoes segredo situacoes tio turismo alcancar amizade atos atuais atuacao ben canais cantar cartas carater ceara cerveja colocou colegio continue desculpas edificio editora fazenda feminino gabriel gols grosso lancar letra ligado louis mandato mendes mentira mesmas mostrando nacao ocidental oposicao ouvido parecia passam realizacao relacionados resolucao subir trem vinte virtual will arvore aviao brincar castro centenas colegas considerada coronel credito debate evolucao fundos gato haviam inverno janela jornais nordeste objetivos oportunidades pago paixao pensam pensamentos pereira possiveis presos saindo seguidores sequencia significado sobretudo terreno terao tecnicas unido utilizada orgaos agradecer aldeia alternativa altos aparentemente apresentado aspectos biblioteca bloco cachorro carga cheguei classico constante corrente cortar desenvolver digitais disco doente dura escala etapa execucao felipe ferramenta gelo gomes haja juntamente laboratorio line mortes maes metodo objeto ocasiao passe passos pedi pega peixe ponta portugueses privada votar virus audio alemao amar anual aprovacao assumir ausencia aviso barra bomba cantor cancao certos claramente come comerciais compartilhar comunidades considerando conto decidir declarou descricao design encontrei errada europeu filosofia frequentemente gostam gostava impedir indica lanca legais livres luis oficialmente originalmente paciente paula pegou piloto plantas populares pouca queira reducao revisao salario sequer siga surgiu tecnologias tia tido tirou volto abriu ajudou alves aproveitar bens classificacao comecam confusao conheci cria cursos definicao deseja droga estrategia estudante exceto extensao facilmente feminina flor foda fugir forum ilhas inimigos muda navio ouvindo palacio parceiro perguntou pertence peru quimica recebido secretaria solar tarefa temperatura tendencia tens terror testes topo tradicionais turma urbana usados usou vaga virar vivem acerca advogados alex atualizacao autorizacao beijo cala cantora capazes chile cientifica custa cerebro daquela deveriam dicas dona eletrica estreia festas francesa fabrica igualmente intervencao lados levado louca manda marcado meninos ora pagamento partidos pau pernas precisava representante secao tratado trocar universal utilizacao vermelha asia aceita adultos assistencia atriz bate brincadeira conquista convidados corre day entregar espacos ferreira finais impressao inglaterra inteligente iorque levaram meta medica neto oferta parana peguei perdendo pessoalmente peco piscina povos preocupacao raca residencia respondeu restaurante rodrigues roma sofrimento sub termina tivemos toca veiculo virou vivendo util alerta antonio art atingir ator acucar bancos big bolo catarina chocolate chorar civis comite conexao conhecidos conheca conosco dancar deixem doencas equipes estabelecer estejam facam frequencia gabinete game industrial inimigo juntar larga ligacoes localizada manutencao mark mistura necessidades ordens patrimonio preparar propostas regra revela rodada romance samba semelhante sentindo solucoes souza simbolo transformar usam variedade vestido alcance alexandre arthur atender atletas barulho black bracos carvalho categorias catolica causar cento chris cidadao computadores conclusao criando desafios destaca doutor entrega escreve especialistas esperava exploracao famosa fara historica irei jogou max metodos negros parlamento parou penal petroleo pop propaganda shopping shows sofrer sofreu sergio tomada transito vendas vieram orgao alimentar alias apoiar baixar bolsonaro canada certas ciclo cirurgia colega deixam descobri descobriu desenvolvido divulgar endereco enviou envolvendo estivesse estrangeiros fifa henry heroi house jack joga kim lendo marcas matou pacientes passageiros pedras peito personalidade perspectiva poesia prefiro privado recem seguiu treino agenda aplicacao baseada beira cansado centros cha colaboracao colombia combustivel conseguiram contando correndo diego drama editor egito especialista existir fechado fundador iii impostos impressionante incendio individual jogando lancada like lojas man maravilhosa moeda montanhas morre organizado oriente particularmente peixes perante produtores propriedades publicar robert saia salao tempestade treinador unidas utilizar van acaso achou agradeco ambas australia colocado coluna conflitos considera creio cumprir cura dedo dificuldade direta equipamentos faze federacao identificacao instrumento moderna morreram nesses nuclear objetos padroes paredes parem permanente pobres preta primo produzido projecto provar proximas quebrar ranking realizados relacionadas repente representacao responde rios seca sentem supremo teremos turno vantagem vazio viagens vizinhos indice abordagem alianca atacar bairros cadeira cai castelo caca chamadas coloque comprei considerar cresceu caes derrota determinado diferencas eis estarao estruturas exercicio fisico gloria home jornalistas logica marcar mel participou percebi pinto puder quao recuperar revelou seguem suporte tropas vemos vencedor verificar acabaram adolescente anuncio arquitetura biblia cabe carioca causas chamados charles chines cruzeiro dentes depressao destruicao divida empresario enviado envolvidos esforcos esqueci expectativa extra fale falha financeira gigante gostou grecia habilidades inicialmente juan machado mamae manuel montanha novidade orcamento papo pense pernambuco pescoco posicoes prima quebra ramos realizadas recife resumo richard sono series talento tensao teus tomando tornaram transferencia your oleo acusado altamente angola antigas assistente avaliacao bob brancos briga cerimonia chaves city comparacao consequencias constitucional convidado convite curitiba defende deixaram deixei documentario encontrada entidade especies estranha ficava https iguais indicado instalacao instrumentos interna jornalismo lago lembre madrugada marcou martin ministros morar mostram motorista news noites orientacao ouviu perde postos publicacoes recentes reduzir ribeiro russa taylor teriam tour usadas utilizando venezuela adolescentes almeida aparencia apresentam aprovado areia arroz aumenta basicamente capitulo cavalo chamam choque concentracao conversas corinthians coroa cunha descoberta desistir dica escolhido esqueca euros explosao ficamos financiamento fizemos fluxo formado formar frank identificar individuo international intitulado jornada lee lenda life links martins metal nariz nucleo obviamente ocupacao organizar percebe permissao pintura prata provavel recebi relativamente retirada retirar rocha santana senao tabela tiros trinta titulos universidades visual voo ambito alice altas anjo aspecto center chances colocando compromisso comprou confiar conheceu critico cao dava definitivamente dever dificeis duro entregue equipamento europeus exame expansao explicacao falamos falso fila flamengo ganhando gustavo hipotese inferior iniciou instalacoes introducao italiano lar limpa mental maxima off opcoes out participaram pastor perna piores planta pronta queijo querendo registros religiosa ritmo rotina sofre sorriso soube superficie temer trabalhou vagas vasco victor acordar amigas andando arena aventura baby bateu bebida caminhos campanhas campus chamando cientistas complicado composto conquistar diria disposicao ditadura elemento elenco esconder escuro existentes fluminense fornecer frases habilidade ideal individuais informar inspiracao invasao investimento jean judeus judicial little major marinha mega memorias miss necessaria pego positivo preparado presa realizou rota sal taxas transicao trecho velhos venceu versoes arabe absolutamente ajudando amarelo ampla aparecem aprendi assinatura aerea beneficios casado cem circulacao condenado considerados consiste continuam cooperacao copo custos celulas dedos entidades escritores especifico fiquem franco fria funcionar garotas guilherme hein incluem interpretacao juntas limpeza maneiras marina mary microsoft moderno olimpiadas organizada pedidos perguntando permanece poderoso primavera progresso regionais renato resta rir roubar rumo santiago semelhantes sombra stf sujeito tentei torre vigilancia virgem walter website william acreditam alan atores avo baixos compras conteudos continente correto demanda des desenhos especificamente esquece estima estradas estudio expectativas fantasia financeiro fotografias indigenas infraestrutura interno loucura masculino metro nessas nocao park perdao performance poderao publicidade recebendo receita red regular resgate ricos riscos seguido senso setores testemunhas this tenis urgente utilizados vieira vivemos windows alcool acontecem acontecimentos adorei ajude atingiu atitudes atua autora bill calendario chegam classes coelho composta conseguimos consequencia convencao crescente copia dedicado define duracao encontrados entendeu equilibrio excecao externa federais forem free funcionamento gama ganho lance lavar legenda leitor leitores levam maia michel morrendo moca maquinas ondas open papai paraiso pare pensou pleno podendo posteriormente receberam reunioes revolta ridiculo salto street suicidio tim trabalham vinha vizinho aceito angeles animacao anna araujo argumento bala bicicleta cabelos cade cancoes carregar companhias comunista concordo decide destruir diretora diversidade dialogo eliminar elite embaixada envolvido escolar espelho esperamos esquema estatisticas explicou fatores fazemos firme fraco gerar governos gravacao graves greve guardar hugo humanas imagine iniciar instagram integrantes inumeras joe junta lady licao matando moto nascido olhada ovos paciencia pacifico parceiros partiu positiva prato preocupar ramo reconhecer recurso roteiro sarah superar surge torcida transportes tristeza tecnicos vidro vira voltando abertos acabam alimentacao alteracoes amplamente apaixonado ativa barcelona bordo brilhante basica carteira causou chamo circunstancias composicao comunicacoes cristaos descobre dirigir distante dormindo dvd elevado ensaio escritos fizer folhas gostosa graduacao graus ido ilegal imperio informou investimentos jackson latino les levanta limpar madrid manifestacao manifestacoes mano maranhao margem mariana marketing mexer mina more morro observar ocorrido papeis pergunto pesado placa possivelmente pura recorde reis relatorios religioso revistas salas salarios steve seculos tchau tenente teto titular urbano vivos voltei zonas indios oculos adeus alberto avaliar california carinho charlie cidadania clubes coletiva coletivo combater conhecem conselhos construido contribuir criados criticos cuba determinar devera dezenas dores encontros envolve episodios estiveram estrangeiro falsa famosos foder fundamentais gastar gerente gil gravar gritar imagina investigar laura leonardo ligados marcada medalha oceano opinioes ouve palmeiras parlamentar produtor reportagem reunir riqueza saudavel sentar sentenca sindicato sugere superiores suspeito terrivel tony acontecido acusacoes adora anjos autoria avanco barbosa cartoes chico combinacao companheiro contos contribuicao controlo criatividade circulo deixo dispositivo domingos download esportes estacoes exclusivamente favorito fernandes formada fuga formula imenso incluir instrucoes interessa interessado iremos mike moro naturalmente observacao perigoso permitindo postou postura profissao poe relacionado relogio reune roda segredos star sudeste tese that thomas tirando uruguai vozes obvio achava adulto agradavel ambientais aparelho apresentando assinado avisar avioes baile barriga best bolso bunda chinesa coloquei confronto conservacao correio cameras decidi deixado demonstrar diariamente dividir encontramos entrando escapar escrevendo essencial estabelecimento estavamos evidencias falava fenomeno feriado ficara franceses fronteiras galeria geografia herois imagino incidente independentes irmas justamente lava lopes mantendo meter moveis nervoso nobre olhe paraguai planejamento preparacao prioridade privacidade promessa proprietario quadrinhos raizes recuperacao religiosos representar resultou roubo sam scott similar soares tente tiago trafego turquia universitario valeu vinda visitas absurdo acompanhado accao americanas anunciado assume atletico barco brincando basico circuito comentou companheiros compreender constantemente construida cortes culturas daria demonstra deuses direccao disney disto eletronico email escravos exige fama ficaria figuras filhas florestas frota gravida houver implementacao inclusao indicacao japones junior lindas lutas luxo lagrimas manteve manual marques mario neve ocupado oficina pacote passeio poeta prestar publicados puro ray representam reproducao rurais saudades seguros sofa sustentavel socio taca templo terapia trilha utiliza vejam whatsapp etica analisar assegurar atendimento atleta barato bombas cia confirmou cresce criador cuidados descreve emocao emocoes empresarios encontraram escolhas escrevi estarei estatuto explorar fantastico igrejas imigrantes imposto intelectual interessados ligada literalmente moscou mundiais nick objectivo onu oracao permanecer posta primeiramente profunda premios panico quaisquer queriam reconhecido repetir reservas sms siria toneladas ultimamente viveu abandonar abertas abrigo aconteca administrativa amei apresentacoes armadas arrumar ativo bebidas botafogo boy britanico cansada casais cobre comemorar criminal democratico desejar destacou diabo diminuir diversao encontradas entrei entrevistas escolheu esqueceu ficcao fiel fio fita girl goias goleiro igualdade industrias inglesa intervalo intuito janelas king kong laranja misterio municipais necessarias nelson not parto pecado perfeitamente plataformas play podiam power preocupa preocupado preservacao promete psdb recebem referencias resolveu senha sexuais sinceramente soldado some tornam transformou tuas turistas tweets venham venho abraco absoluta acampamento afastar aires aliados aponta assinar atingido auxilio bases brian cantando caralho chegamos club consideracao coracoes criminosos cristina criterios creditos demasiado denuncia descrever deserto dimensao dna doze engenheiro entraram esquerdo estaduais evidencia ficha fornece frango geracoes gostoso independentemente integracao investigacoes iraque jato juri ligo magia maluco marcha materias mentir moedas narrativa nascer necessarios negociacoes novidades painel pedaco postar preconceito prisioneiros profundo quadros recepcao salvo sara sentiu substituir tocou torcedores trabalhava treinar vais vimos vistas acusacao adam adiante agencias aluno anel are associacoes aumentou autonomia back bandas batista bispo brilho buenos candidatura cargos comendo completar contagem continuou debaixo delegacia demora demorar desconhecido desfile dieta divulgado doi emissora entretenimento espetaculo estabilidade estando eventualmente extrema faziam formal garantia guine imediato inumeros julgar kit larry leo maconha miami milagre monstro moreira minima originais parado passagens perdida pesquisadores plena poderosa porte possibilidades potencia prender preparando press prestes prof protesto pude rabo realiza reconhece reflexao relatos ronaldo russos satelite sobrevivencia suspeita transformacao uniforme usp unicos adaptacao ajudem alternativas amostra ansiedade aplicativo aprovada assassinado brown caminhao caos caracteristica cardoso casada chicago clinica cobra comenta comentar compreensao conceitos consulta contribuicoes daquelas democratica eletronica empregos encontre entenda envolver envolvimento escuta espanhola faltam febre ficado funcionario hong largo lateral lembrando maus morais musico negativo nestes oral ouvidos ouca pensava perseguicao poema populacoes procurador profundamente psicologia reformas reporter retrato rodas salva sentia simon sintomas suave suspensao tag tento torres vencedores verdadeiros verdes vistos vitorias acredite alemaes amazonia andrade android aplicacoes apresentada associado assumiu atmosfera atrair atraso atuar aumentando aco bando braga causando comemoracao contemporanea crista cujos cesar desculpe dignidade director discussoes disposto dose durou editorial emocional equivalente eric espada esperado existente extincao fator fechada fabio gratis hino hospitais indicar itens kevin libertacao limpo manaus micro mini misericordia mito montagem mudando multidao mascara nasce negar net normas odeia percebo previsto procure promovido raramente retornar ruins segurar sobreviver solta tentativas trazendo trafico utilizadas vereador vestir vindos volte vossa arabes actualmente africano amplo apagar apple arco associados augusto auxiliar avancar belas botao caridade carol componentes concessao conduta confortavel conquistou continuo curiosidade dan daquilo derrubar don edicoes eleitores eletronicos falado fortemente garcia gasolina gatos gera idioma japonesa long lutando mandei maquiagem maravilha mentiras movel musicos neves noiva obrigacao ocorrer ocupa percebeu perderam pib pobreza previsao procedimento produz proteccao rap respeitar reuniu romantico sabes saem separacao sessoes set single sinta sopa sousa supostamente thiago tocando torneio tradicoes vigor vinganca visa acessar actual afonso amado amante apaixonada aposta aprendeu assalto ativos beneficio bento bernardo bombeiros caramba chegado chegue cientifico cola comecamos criminoso cristao desastre down duplo elizabeth estupro estagio exibicao faixas fernanda fruto games garganta gravidade green historicos incriveis inscricao inter jones julia libertadores lobo mac mateus mecanismo monteiro necessariamente normais ofereceu ovo passava percurso podes polemica possamos prefere prevencao proibido reputacao restante rita sagrado semi serviu suposto tivessem tragedia valer vende vias vindas voltas acido acidentes africana amanda ameacas aranha argumentos bandidos bbc buraco cabecas celebracao colonial comunicar concorda consideradas conter correspondente costume dama defendeu definir dependendo descansar descoberto determinada edward eliminacao empregados entendem equador escutar estarem exames excelencia facilitar fechamento financeiros fingir furacao gastos gremio ingressos inicia integral iphone juridica juizes legado legislativa legislativo lembrancas lembrou min mocambique mudaram multa nave paraiba particulares perca permitem permitido pimenta plastico pouquinho produzida prometeu proprietarios protocolo raiz recusou redacao remedio revelar rose sairam senta smith suficientes tesouro todavia what wilson afirmar amazonas atinge biologia blocos calar caminhada can carbono circular comprimento comunicado conhecemos conhecia conhecidas contam contendo corta country decorrer descreveu descubra despesas doces duvido economicas educacional eixo embaixador emily espiritual esquecido estacionamento ganhei good heranca informa iniciais interacao interessantes mala manoel melo milho paisagem pan parecido parentes percepcao pesca placas popularidade prepara presidencial privadas protestos quartos quinto raro reacoes relevante resenha respectivamente roger rui sabor senhores significativa sofrendo solidariedade suica tendencias tome trabalhador unhas violacao vizinhanca abuso aceitou acontecera acorda aguentar american assassino balas brazil cabral caindo campinas chato chorando cigarro clipe conseguido conseguindo coordenador corredor crer curioso dedicada descer desespero detalhe divertido dragao eficaz ensina especifica estabelecido estrategias estavel evidente exato expor expressar falhas felizmente financas fred fumar gilberto guimaraes homicidio inscricoes intensidade internos jane japoneses last leu lisa mantido mercados motores muro ocorrem ocupar precisamente preocupada pressa profundidade raios recado record relato sensivel soubesse suspeitos tecido tentam tentaram territorios tomei tranquilo transmitir tribo vaca aborto adequado admitir afirmando age anime anuncia app asas assistindo aereo bad bebes berlim bolivia canta carolina cavalos celebrar celulares chuvas cobrir con conduzir confirmar continuidade convencer culto declaracoes definido desenvolvidos doacao edificios espacial estive exercer feio feridos filipe fiscal gays gratuito guerras imaginacao intenso jim jogada judiciario juridico juizo kelly lgbt luzes mix motivacao musicais nomeadamente obteve operacional parlamentares perguntei petrobras pizza premiacao preve produzidos prometo reclamar remedios salve seco servidor sexy sociedades sorteio tarefas teixeira tornado tratados tinhamos utilizam vendidos visivel voar voltaram veem acesse acreditamos adianta adicional afro amarela animado analises aquecimento atende belem benfica basicos caio caminhar carl chineses citado colaboradores conceicao concluiu confesso confirmado conhecimentos contacto coordenacao crescendo cuida decidiram delegado depoimento desejos determinacao diana encerramento escolhe estatal expressa fases fumaca gordo gritando group houvesse iam ignorar indicam indigena informado inocente inovacao levo liberal ligando ligou longas mapas merecem miranda music negativa ocorreram pablo passamos patrick pdf piadas promove prontos provocar regresso relacionada restaurantes resulta rodovia ryan semestre seminario servidores sofrem subiu suco servia texas vantagens vendido vereadores vicente voluntarios white academicos adicionais adversario alo ando andrew argentino atacante atracao bloqueio caixas camada camila cientista coleta comece concerto confio considerou contratos conversando crenca dara deficiencia dimensoes dividido doutorado doutrina empate envie estatistica exigencias falsas fazerem fecha ferido funcionando fisicos garante garrafa get georgia giro goncalves gravidez grito grafico guerreiro havendo imediata impede importo instante joaquim johnny justin lido longos lucro labios mandado meados medicamentos navios notar participa participando pegando permitiu pesada pesquisar promessas protagonista pessimo quebrou quinze rapazes sabedoria sementes similares sobe sobreviventes sons sport sujo telecomunicacoes teorias unir vivia way west acordado ajudam alagoas alema almas amam anunciar armada borges cadeiras campeoes captura cemiterio chefes civilizacao coincidencia colar compre computacao comedia conquistas consiga conte coreia corresponde costuma dano datas desenvolveu diretoria divulgou documentacao donos elevada entram etapas euro financeiras flash forcado fraude fundada fatima galinha hitler imensa ingresso jason justa ladrao ligadas limitado loira mama margens melhora metropolitana milhas missa monitoramento montar moura mudei observando ocupada old ouco pistas pontes preservar procuram quarenta radical religiosas residentes separar society terroristas testar tirei transparencia united usava usei viola vizinha voltado who administrativo aids alcancou andamento anne armado artistico atacado atualizado batendo batman bonitas buscando basicas centrais colocada concordar conseguia conselheiro consequentemente correntes costumes criadas debates defensor demonstracao destacar deveriamos diretores disciplina divertir dobro economicos emissao empregado emprestimo ensinou enviados esfera estresse eva experimentar extremo fracasso ganham ganharam grego haveria hollywood iniciativas integrante intencoes isabel joseph levada luto macho mecanismos mecanica magico nega negociacao nestas nomeacao norma now ocidente operar oriental partidas periodos possuir poco preocupacoes preparada procedimentos promotor propoe queima quiserem racismo radiacao rapper refletir regularmente requer restos radios selvagem senadores sentado servem sobrinho socialista south sucedido testemunha tipico viria abc acabado acessivel acompanha acordos adequada agricola aliado aplicada aproveite aproxima assassinos assista barata barcos barros batalhao cachorros classicos cobrar colo confirma corda cozinhar ceus codigos davi deitar dispositivos diaria doentes dividas eficiente eleitos entendimento enviada escritorios especificos estranhos eterna fantasma formam freitas fisicas got grana helena holanda horror ida imigracao imperador importar inacreditavel incomoda iniciado iriam ivan juliana just lesao levei listas look make masculina matt may mello midias navegacao negociar nobel ocasioes olhem olimpicos orlando participante piaui posts presidentes protege provincias predios publicadas rachel rato recusa registo registrado secreta secreto selvagens significativo state substituicao surgiram tava tendem terminal tinta tomadas ucrania vadia verdadeiramente war academico actividade actividades afeta aluguel andam anderson apelido aprendizado aprovou assinou aves baixas beijos blogs capitais carvao casou causado cometer construcoes contatos deposito desenvolvida dirigido dorme durar embaixo emenda esperam estaremos executar existia falaram ficarem filipinas first futuros gajo galera ginasio hit identificado idosos indonesia inquerito inspirado italiana jessica lama lento lindos mantenha matriz michelle mostrado merito network observa oferecendo ossos pauta pedacos perdas piano poemas preferencia preparados queimar quentes queres remover representando resolve respirar restantes restricoes residuos rogerio salvou sapatos saudade sbt segui selo sir soltar sugestoes sitios telefones tomado tortura trabalhado traduzido traicao transforma trio toquio ventos violao virtude visando voleibol vosso abrindo aceitacao acreditava afeganistao aplicar aplicativos aproximar aquisicao artistica automaticamente barba boston britanica burro cancelar carrega celso chamas cinza colocacao combina comeu compreende constitui consumidores criatura copias decidido demorou dente depender descanso desemprego destinado deusa deviam divide dolar elaboracao emocionante empregada escolhi espalhar especializada esperancas estabelece estomago excesso expressoes falsos favorita fechou fotografo fraca funcionam futura garagem governamentais hill intensa inveja investidores juntou liquido mencionado mesquita ministra modernos molho nunes ocorrencia oficinas oposto pmdb portao positivas postagem prevista pudessem queridos quimicos rebeldes recomendo referir relevantes rumores sabiam sentimos separados soma sonora suportar teclado terrorista testemunho trailer tribunais urbanos vanessa vargas vela vendendo vendeu viajando abandonado abandonou acompanhando adocao afirmacao alvos amava apoia aprendizagem apresentador assassinatos atuando barreira batata beatriz bolsas bronze bruce calca cana causada coca completou concreto considero cotidiano crencas criticar cujas culpado curtir dadas defendendo demissao descendentes deter devagar diagnostico diploma discos doido eletricidade emma encarar escolhida escravo especificas espere esquadrao estuda facilidade fechados flavio fortalecer fortuna gerou gravacoes impressoes inutil jay lacos leandro levante ligue limitada litoral livrar mando mexicano mineracao modalidade mortal muculmanos nasci nativos neles nervosa ocidentais ombro osso palestras pano parcial pasta pedimos planejado praticar prevenir pascoa queixa recebemos roubado segurando sermos sonhar temperaturas trajetoria trechos une usina vegas vestidos virada acabo acertar afasta algodao alterar alteracao amostras anuncios aprendendo ascensao aereas bacana barbara beijar book camadas cego cerebral cheios claudia coimbra colonia congo consideram contente costumava cruel culinaria curtas definida digam dirigentes dita entregou escada esclarecer esconde escondido escrevo escritora espanhois esquina exportacao feridas fizesse florestal fugiu geladeira gigantes gratuita hectares habitos ian integridade lentamente liberacao loucos lucros maracana marta massacre melhoria mestrado mineiro mobilidade modos moraes mortas mudam national nina nuvens onze pagando pagos parcela pares pedem penas perfume pergunte praga presta provoca reconstrucao registrou religioes remocao resistir reta revelacao rousseff sampaio segmento sporting suja sindrome tailandia telemovel tematica trama tranquila transmitido vital volei xix acabe achando acompanhe advogada aguenta alimento aprenda aprende atacou ave aventuras basquete bastidores besteira bolas borracha brinquedos cinquenta circo classica colocados comparado condenacao conspiracao criaram calculo dedicar desconto descrito divulgada duma elogios encher escandalo essencia exteriores farao favoritos feijao fieis gado garotos gira gozar gratuitamente guitarra happy hipoteses impactos impulso infeccao inocentes institucional jerusalem jogado judeu junte juvenil lembram libras mande maratona mediante mexe miller missoes negras olhares origens pagam palmas paradas part participam pausa per perdidos perdoar personalidades pinheiro piso placar prestacao privados project raquel referido registrar relacionamentos responsabilidades rick sacrificio sagrada serei surpreendente suecia team traduzir tratam turne unesco urgencia viana visitou young enfase exito absoluto acompanhamento administrador afirmam agressao amantes amy antigamente aparelhos apontar aposto apresentadas armados atrasado avancos azuis bacia bagunca banana barreiras buscam censo citar claudio coco colocam combinado consta continuacao criativa criei demonio dependencia desenhar divorcio encontrava engano enormes envolvida estiverem exclusivo formulario fox gravado guerreiros habito idiomas iluminacao ilusao implantacao infantis integrado inteiramente interface lenta libertar marrocos meias mochila nuno obama observacoes obstaculos olimpico partilhar party pilotos pintar porco pratos probabilidade procurou produtora puxa puxar qualificacao raul rebelde reconhecida ribeirao satisfeito seios sentidos sexualidade sugestao surgimento things traga trump two variam vence vermelhas volante unicas abandono adolescencia agricolas ambientes animada apanhar atravessar beach bico billy biodiversidade bravo bruto cavaleiro chapa cintura clark colapso colocaram coma concelho confia confirmacao conforto consenso contratar cristiano curva demandas desenvolve dinamica douglas enfrenta enganar entendendo escravidao estilos estragar estatua eterno exclusiva executado faleceu ferimentos florianopolis ford formando frutas goste hip how howard hungria imaginei impeachment informatica internas ironia johnson lewis liberado massagem mensal mostraram mude mudo magica note olhei pagou paquistao paralelo parcialmente parente passaporte pecados pequim permita pesadelo pires plus poderosos procuro punicao patio patria queiroz reality reflete renan resolvido ritual rival rosas school simpatia sofia story sucedida surgem testamento trazem tripulacao trono vazia visuais votou abencoe acabando academica acertou acessos acrescentou amada amador amamos apresentados aproximacao armando arredores artificial associada bancada beta blue brancas call calcas carla casamentos ciumes comemora concluir constantes continuem correta creme cumprimento cambio dali dean destruido dicionario digno domestica dourado educado eficiencia ensaios escolhidos essenciais estariam estrangeira favela ferida finalidade full gerenciamento goiania gritos harmonia here horarios hoteis ideais idiotas ignorancia incapaz infeliz instrucao integrar jeff jimmy joelho julgado lavagem marinho marte massas mia move mudado netflix notavel ordenou palestra pediram perdemos perigosa praias proximidade pessima quantia quieto recolher reconheceu refugiados regina registrada registrados regulamento relaxar repercussao retirado rever saga salvacao satisfacao sector seguiram sentada sigam sigla sovietica subindo surgir tags trofeu vara velhas visite voltam acompanhada acordei acre ala aldeias anunciada apropriado aproveitando ataca band bandido bloquear cantos caros carregando case certificado chamava christian coberta compositor concorrer conde conferir confiavel contratado convencional convida costumam cultivo destacando determina determinados dirige distincao divina doacoes eletrico entradas envolveu essencialmente faltando famosas favoravel franquia frutos futuras galo genetica gesto gordon gostariamos guardas hey high ideologia igor implica inauguracao indiana indiano jardins jazz lancaram lazer leal lembranca levados levantamento linux luciano logico mails malas malta morrem mortais namorados never nigeria nuvem olhou organismo orgulhosa outono oxigenio perry perspectivas pertencem pesquisador piedade potter precisao processar protegido quadrados relativa respondendo samuel saido sincero situado sobrenome solteiro solto sugeriu supervisao surpreende tigre turistico tipica topico una vietna visualizar work angulo icone indices abastecimento adotar almocar andy ansioso apareceram apelo atirar automoveis autorizado baseados boatos bocado boi bebado capturar capitulos cartaz comboio comentando concentrar concepcao conexoes coral crises camaras dave davis declarado desaparecer descobertas despertar diminuicao duarte envolvidas estabelecida exigir expandir extraordinario feia frequentes figado homicidios hop hot incentivo iniciada instalado instalar investir inacio joana jonas know lagoa lagos league levantou limao manipulacao men mencionar mentes metragem mostre navegador negativos obrigatorio olimpica over pacotes parecida pato planalto point poluicao policias positivos presas proporcao proposto provocou publicamente pular quartel quintal seccao sofrido sumiu tanque tatuagem tire tomo trabalhamos trato tropa variacao variacoes visibilidade uteis about abri action adesao adicionar africanos alegando altitude alivio anualmente aparente apontam apresentaram atlantico awards batalhas besta bibliotecas bilhao box brava caetano caneta capitalismo caribe censura cita comerciantes comparar concordou confederacao confuso consumidor contraste coreano correu criaturas declarar decoracao desaparecimento desejam designer desistiu desligar despedida desporto destruida directamente divino diarios eleita eleitorais enredo espectadores espiritos explodir expulso externo exilio focar forcar fruta gabriela graficos habitacao hall hope incentivar indicada indicacoes inscritos intelectuais inteligentes ios jair jon jonathan largar largura lata liderado light liguei master mor mover namoro noel nomeado oliver organizou pacto palhaco panama parei patrocinio pensado perfeicao produziu penis rara reabilitacao realizando receitas refeicao relata renovacao residente respeita revelado saio secundario seguidos semelhanca soja suficientemente talentos terminando transparente tristes vacina velas veneno vier violento visoes voos walker xavier zagueiro acalmar acharam adquirir adulta aeroportos andrea ante aposentadoria arranjar atracoes babaca bandeiras brinquedo business campea casaco caxias cerco chapeu classificados cocaina colher complexidade concedido confirmada consciente consideravel contratacao convidar corporal corrigir cristal curar dancando declara defeito defensores denuncias desapareceu editar efetivamente eliminado envia envio estrangeiras estudando exercicios exibido extracao folga golpes grand gratidao grafica guarani humilde incomum itunes lendas marcando medalhas mencao morena mtv negou nucleares observou ofensiva oferecem oferecido palma parcerias perguntam planejando pretendo prioridades proibicao psicologico quadra quantidades razoavel receio residencias responda revolucionario rola seriamente situada substancia surpreender simbolos tecidos terminei tomaram traducoes transar tracos termino universitaria vasta view virtuais visualizacoes vitor abra aceite acordou adorar air amaral armazenamento armario arquiteto assis atualizacoes batida candidata causados cinemas claras coberto cometeu complicada comprado concorrencia confrontos construiu consultor continuaram controla corridas criadores cupula damos dance descobriram desenvolvendo devolver discriminacao discursos discutindo disputar dividida dominar donald drive eleitor encerrar end explicacoes fachada falecido fantastica farinha fisicamente foge fresco fumo gaucho geraldo gerando grama inevitavel inflacao inspirada isolamento jennifer judiciais legendas macacos manga mansao minerais montes moradia multi mundos office oracoes parceira parques partindo pensamos pico piorar poderiamos posterior privilegio producoes profeta prol promovendo propos provenientes radicais realizaram reduzida rejeicao respiracao rindo road robin romero sandra semanal service sinopse sociologia solidao sorvete sra substancias terrenos terco transformando tratava taxi tunel university usaram vendedor vera vilas vivas vivi williams acontecimento agindo agradar agricultores albert atrasada atualidade baixe bares britanicos caderno caminhoes caracteres castigo cientificos combinar componente consulado controlada controlado couro denominado determinadas doc dormiu dra east engenheiros escura estivessem fabricacao feminista fornecimento fundadores garantiu garrafas gata girls gregos gripe historicas imoveis incluido indicando invisivel jacob jerry julio karen kids lamento let limitacoes litros localidade maluca mauricio memorial mesas mestres metas night non obrigacoes organismos pareceu passear povoado preferem previa puderam qualidades questionar racista reflexo relevancia renata respectivos resultar saibam simone simultaneamente sorrir sugerir terei tons tratando tropical valente vaticano verdadeiras villa wall when xvi xxi acompanhou acostumado acrescenta accoes afastado ampliar amem andares apertar arabia associadas azar bang bebendo bobo bondade chef combustiveis comi conclusoes condenados considere convidou coordenadas corredores coutinho cover criativo criterio curriculo dead demitido demonstrou dennis departamentos deputada destinada determinou diarias dominios dum editores ego elena encontrara entusiasmo est evangelho expresso fabricante fina fios fiscais fornecedores fundado funk fusao faceis galvao gases gatilho grossa habitual imovel infra invadir lemos lesoes liberar literaria licoes luke magalhaes manteiga mantida marie mataram medeiros moreno morgan misseis modulo negativas novinha observado perdem pinturas poeira portuguesas posicionamento pracas preferido primos procurado profundas proibida propriamente reforcar refugio reitor relatou rendimento representado repressao resume roubou santuario saudita sean selecionados servido soberania stan sujeitos suprema surpresas tende tentado terrorismo torne trabalhista tradutor transportar tributo trouxeram urbanas usamos utilidade vapor verdades vladimir abreu aconteceram admite adversarios americas aplicado apoiado apontou apostar arrecadacao asiatico assustador atenas atentado atlas atualizar automovel autorais avos balanco biografia bonitos brigar bush camiseta cbf cds chamaram chat cheias churrasco competencia complexa conferencias constituem cordas credibilidade credo cuidando danilo decidimos defeitos definitiva desce difusao diogo diretrizes dispostos doar dylan deem emissoras entendido enxergar escudo especializado estudou executiva experimento faltar femininas friends grade guedes incidentes infinito information interagir intercambio irlanda iso jordan justificar kennedy lema lembrei liderar lorena lucrativos manifestantes mate melhorias mencionou mobilizacao monstros morando observatorio obtido opera orelha orquestra page panorama pareca passados perfis permanecem pontuacao postado preocupados pretendia processamento proteinas reagir reclamacoes reduzido reforco requisitos resolvi saint saldo sapato sensibilidade seremos sky sombras stephen stop suspenso terceiros teresa tricolor turco tumulo urso varia vaz victoria voando voice voltada want xadrez asa barras bicho bilhete boletim brito bueno buracos carneiro carter cavaleiros cacar cenarios chip ciclistas cineasta cinzas climaticas colaborar cole competir concedida conclui concorrentes conectar conjunta construindo continental delicioso delta denunciar dera derrotar desconhecida diamante dificilmente dirigiu distantes distintas domestico duque eco elegante elevador empresarial emprestado encontrando engracada escuridao esquadra exposicoes family formalmente fragil fabricas gene gold gota governamental gravou guy harvard historicamente horta industriais inseguranca interferencia interpretar jersey josh lida lincoln macau manifesto marcus matheus mete mexicana microfone mira modernas mole morada movimentacao multiplas nicole novelas ocorrendo palestina partilha peitos pierre polo porcao precisou preencher passaros quilos quisesse rapariga ratos refens relaxa restricao rivais romano rondonia sargento secundaria sobrinha solteira sozinhos sucessos supermercado sustentar socios tanques tesao transformado tubo topicos ultra utilizador vegetais vilao viuva vicio acervo adaptar alexander almirante amanhecer angel apartamentos apreciar arriscar atrai atribuicao avancada avisa azevedo barragem bella bruxelas but belgica bonus calmo cantou cap claros condicionado confusa contribui coro corporacao cuide death dem desaparecido dispoe diziam domesticos dubai eddie educacionais enviadas equipas esportivo esquecam estabelecimentos exclusao externas faltava falencia farmacia formatos fracos frequente gerado gorda gostamos identificados importam incomodar incendios influencias informe institute intitulada kate lancados lancando legalmente leves localizados macaco maca money mota musculos nascida ouvimos panela pareco peticao pontas porcaria porno potenciais precisando preocupe prisoes propor protegida quebrado queiram recompensa recorrer romantica ross rapidos safada saneamento sexto steven stories take temporaria testa tiraram trans transferido tratada trigo valorizar variar vencedora veremos viaja voluntario vespera wagner xbox alvaro aguardando ajudaram alfa ancestrais aparecendo apoiando barry beto canadense capela cacadores cairam citando classificado comecado competicoes comportamentos compoem conducao controversia convidada convocado corra criam delegacao dentista desculpem desvio diamantes dirigida discute energias energetica erradas esgoto esportiva estimado estimativa estetica exigem externos extras falantes fazendas feiras feminismo filmar fixo formou freguesia funcionou funeral gentil gemeos genio hard have imaginava implementar ingleses insetos insiste instalada interessada island isolado literario livremente lutou machucar maravilhosas medir mercadorias militantes mitos morava morrido namorar obrigados orgulhoso patrao people plateia pokemon politicamente premiado primaria projectos promovida protagonistas proteja radar recebida recebidos recebo referindo reflexoes regimento regulamentacao resgatar retiro rezar romanos sandy seguidas sensores significar sindicatos sobra subida sustentabilidade system serios taiwan temporariamente tentava terminado tiverem tribos tse tutorial tyler uol utilizadores variados vermelhos vivido wayne acto adotado agradecemos aproveita arrepender articulacao assento austin baia beyonce boneca brigadeiro cameron car catolicos causam celebridades colaborador consentimento continuara copiar criminosa criticou cronica curiosa dedicacao deixamos democrata desgraca disser duelo efetiva emprestimos escreva escritas estimular explicando fofo golfo governantes governar grega helicoptero investigadores islamico jan julian lamentavel lancamentos lara law magnitude malasia maravilhas matam mendonca merdas migracao milagres monitor mascaras nativa ninho nogueira noroeste notou paineis pensao pistola pneus poetas proporcionar psd quadrilha queen racial representacoes right risos salada sofreram substituto sudoeste sugerem sus suspeitas tolerancia tradicionalmente was arbitro eramos idolo otimos abandonada abracar abu achamos again anal anthony army assinada assusta atraente avancado bacon baiano balao baseadas benjamin brad brigada brinde brother buceta bulgaria cargas catedral colheita complexos comprando configuracao conservador contemporaneo cooper correm decente deslocamento destinos detesto detido devidamente dirigindo divulgados dominante duzia economista eleger elevacao empreendimentos escolares estimacao executivos exibe favoraveis fechadas fixa florida ganhos gasto gelado guatemala generos ilegais impor invadiu justificativa ladroes lana lealdade leilao liderancas lobos mancha mare matthew mecanico moises montado museus marcio multiplos naquilo navegar noivo notificacao obrigatoria obtencao ocupados ofensa organizados organica pagamentos pandemia pararam pegue permanencia planetas poste prejudicar prejuizo previamente referida regulares reside resultando rolando salgado sebastiao selva sessenta singular sun tapete tavares ted telhado tenhamos terrestre tirado today toledo torta totalidade tratou trocas ultrapassar universitarios viajou visitante valido xuxa indio acusados advocacia africanas ajudado alcancado alckmin amores angela apocalipse apoiou apostas argelia atacando atravessa beija bienal boxe cardiaco caroline cat caverna chame chamei compensacao conectado consultado conversao cortou cross cruzamento custou declinio denise depoimentos destruiu detencao disposta distribuidos divertida empreendimento enderecos enterrado estabelecidos eternidade europeias exibir existiu expedicao experimental fino flora food forno freire ganhamos gasta gordura grant historiador hiv honesto impediu inferiores inocencia inspirou integra invencao irem irmandade juros land laser lauren levara levava liberais libia marcados maturidade mentindo mercedes misterioso miseria moram natacao necessita ninja nua oficio patente percebido persa pescadores pesos pirata planeja primario produzidas protestantes queimando read recomendacoes renuncia report ressalta restauracao retornou reunidos robo roy rss secas sertao sex sic silvio sino stone suporta suposta their toalha torcer transferir troco tubarao vegetacao violenta vip wars year acrescentar adoram afetar alfredo ameacada ansiosa aprova arbitragem assessor assisti atento audicao auge brilhantes brincadeiras caminha cancelado capacidades carregado carrinho catalogo cela charlotte chateada choro chumbo chute citacao colonizacao compartilha compromissos concedeu concluido conviver corretamente crie debater dedica deixava dependente desgracado destacam detetive dormi ensinando entendemos enviando envolvem esperto espetacular estabelecidas estudantil estadios faculdades fantasmas fatal festivais force francis ganhe generais gps grace gradualmente granada hum idades iguacu ilustracao incluiu indicados ingredientes iniciaram introduzir inventar irregularidades italianos item jaime jogaram jurisdicao laterais legislativas levaria lorde luiza maduro marvel mauro medos mentais monumento muralha muros nacionalidade nancy nicholas noturno other our ouviram penha pia pica place precioso prisioneiro proximidades puto realizam rebeliao reduz rendeu repito retorna segmentos sergipe servindo sigilo suma suprimentos tampa telefonia tomas touro trago tranquilidade trauma trens trevas tweet variaveis vestindo iris abordar acabamos aguiar alegou analisa apertado aprovar arranjo artisticas atingindo atletismo atuam autorizada balada beneficiar bretanha brooklyn calado camisas care caracter catolico caido chuveiro complementar compor comunistas concentra contava contratou contribuiu cota covid crucial custar celula circulos danny days decorrencia denominada dependem derivado destaques digamos dinamarca directo diretas disturbios divulga edson elias escadas escalada espectro executados expostos fast fauna ferrari filtro foz fugiram ginastica great hamilton han ibge imaginando influenciar injustica injusto inventou janet jin khan leituras lembrado localidades lucy magazine manhattan manobra manto medicas nasceram nathan obriga omar operacionais parker parametros permaneceu pesadas portos precise prefeitos procuradoria produzem projetado provocando quadrado quartas raros reclamacao redonda relativas residencial revelam rey roxo secretos seio sensiveis separa separado short sinonimo sobreviveu souber suicida superou surpreso temporario tiroteio tocantins treze valem vazamento vertical virao watson albuns abriga acreditando adivinha admiro admitiu adriano altar alternativo amadores amigavel andava aneis anonimo aplica armenia assentos assedio automatico baseia batom bla bobby brevemente brutal caia calcada cancelada cardiaca carona cercado charme chateado citados coligacao comunitario conceder copacabana costumo cpi cruzar dedicou demonstracoes dependentes desenvolvedores designado desigualdade detem distribuir elaborado enem enfrentam enfrentando entorno espalhados estende estranhas exigencia exista experimente expulsao fadas falhou farol filhotes fonseca forcada foundation fraternidade furia gary governante gramado gratuitos havido his homossexuais identifica joel lanche legalizacao leio liderada localizar logan logistica maldicao mandando marrom marshall mec mineral mobile modalidades monarquia nasa nelas netos neymar nobres ocupando ombros ong only operadores oxford participado plenario postal prendeu preste prever projecao protegendo proteina provou racas recusar render repete retrata rodovias roque rosario ruido say shawn simpatica sirva soa store temporadas temporal transtorno trazido turcos variadas vcs vinham viviam votado vulneravel yang adotada aguarda aguento alicia andei apaixonados apanhado apresentadora assistiu atacaram auditoria bagagem bastos batatas bianca bio boom botar brinca bullying camaroes cartola chelsea cientificas citou colina comemoracoes comunitaria conduzido confiante contei correia correios corruptos cortado custodia dark defendem delicia dengue dira disparar distintos dog efetivo eficacia encomenda entrado entregues exposto extraordinaria falem ficasse fire fixe france fraqueza funcional galaxia geografica gerador gospel grato grao hardware harris imaginario inscrever instancia interrupcao jogam justifica legitimo limita linguistica livraria lucia mera mergulho modificacoes morador motoristas monica neo odiar operador organiza pareciam passadas percorrer perfeitos perigos piratas postando prende passaro quebrada quebrando raras reclama recordar retomar reuters ricas rochas ronda ruinas schmidt see sejamos separadas soberano stress sucessao sudao sabio sintese tecnologica triunfo tatica unida usem usos veste virando visiveis von vote workshop aborda acessiveis administrativas agradecimento albuquerque amorim amoroso ampliacao analista antena arrancar arruda assumindo ativista audiencias aurora australiano away bacterias balde baleado barao berco bruna bruxa caminhando cancelamento cacador cerrado chego colocadas colunas cometido compartilhamento complicacoes conduz conhecendo continuamos correspondencia culpar curiosidades definiu demonios derivados derrotado desperdicio deva devida disponibilidade disputas doer drake elevados ellen emitiu encerrado erva esquecimento estabeleceu estimativas exata extensa fabricantes falcao faltou fbi fibra filmagem firma fogos formatura frontal fugindo fundacoes globais goncalo hipocrisia houston imobiliaria imobiliario internacionalmente jurados lapis libano lopez manifestar marilia melhorou melissa menezes militante monge mundialmente next nojento norman numerosos organizadas parecendo particulas passara pensem percebem perdoe phil poderemos porcentagem preferida privilegios procurei promoveu prosperidade protetor quimicas quimico recorrente refeicoes registra regressar relativos repertorio respira reuniram rituais rostos setenta soco solitario sorrindo sotaque spencer solida teologia toa traseira tronco valorizacao vasto vegetal verificacao vestibular viajantes vinicius voltamos vossos wallace wolf yuri aaron adicao adotou adquirido adriana after aguardar alho apaixonar apontado aproximando ativamente bay bicicletas body bond borboleta buscas cabine cabos camponeses cantores capturado chamamos cla coloco colorado condado condutor constituido crescem cristianismo cunhado curtos calculos daniela decisivo definidas definidos densidade desapareceram desconhecidos destruindo dick diminui dirigente distribuido ditado divididos dialogos dourada encarregado encerrou esferas estrategica exemplar exemplares faces factos falas fidelidade filosofo finalistas garantido garantindo governadores greg gritou gra hierarquia higiene improvavel inconsciente intimidade inedita lagoas leonard liam lourenco maldade manchete mexendo milton misteriosa monges morra mortalidade mosquito medias naval noruega obrigar obtidos okay optou patrulha pec perseguir pesados plenamente polonia postagens preliminar prepare presidenciais previdencia promocional prosseguir realista reeleicao regulacao remoto retratos robos run ruth sacerdote secar sequestro simpatico sin sincera softwares sos square sugerindo susto tapa tecnologico tel telas terriveis three torcedor tremendo vagina verem vovo valida wesley austria utero adeptos agradece alarme alimenta animados apuracao ata atuou avaliacoes banner baterias bin blusa borda bota cachoeira carmen cessar chora ciclos ciente cine citada cobranca columbia comissoes compara confundir consideravelmente continuamente convencionais conveniente corretor deitado delegados demonstram demos depositos descrita desenvolvidas desesperada desesperado disciplinas docente doida dramatica eletricos emitido encerra espionagem estadia etiopia evangelica evitando exagero explicado fechando fiscalizacao foca formados futsal golfe gostando grita guiana haiti imunidade jake joelhos julie laboratorios macedo melhorando metais misto morumbi municao niteroi nojo participe paroquia passem perceberam perigosos plantar podcast poderosas precedentes pressionar proporcoes proveniente queimado racional reconhecidos resultante reza rolar russell saraiva sebastian semanais senhoras sensual singapura solicitar solicitou son sonhei sony sophia stand sydney setimo tensoes tijuca trate under urnas vaso vendida verso veteranos viciado vii walt years aguia aceleracao agrada algarve aluminio ann aposentado assessoria assiste atraiu atrapalhar aumentam ball baratas bata caem cansei caracteriza ceo chan chegarem comparando comparecer compartilhe concertos condominio confissao constitucionais contaminacao cortada cotas craig croacia daily degradacao democratas deriva desviar diesel disponibiliza disponibilizado divisoes elogio emissoes emitir empreendedores english escape esposas ever excluir exposta fascinante fazes felix femininos fitas forro gaucha gentileza god grata guias homossexual honduras humildade impresso incrivelmente intervencoes israelense jamie juntaram jura karl ken lutam manchas mandaram mangueira mante marcante marcaram menciona mercadoria merecia mitologia mona name orleans param pas passageiro perimetro pilar plantao poderem prado precisara pretos pulso quedas raciocinio raparigas recomendacao recomecar registradas reparar representada retirou river rotas santarem saidas seda sena sexualmente she significativamente solos submarino substituido tentamos teresina timor tomam tona too transmitida trilhas triangulo trocou turisticos uau varanda variedades variavel vazias vencido vincent violentos votaram watch otimas abrangente abracos acordada aderir administradores admiracao admito allen arsenal artesanato asilo atentos ativistas atualizada ausente aviacao balanca baleia bilhetes boys cacau camargo camarao cano carreiras celebrado centimetros cesta chegara chileno cobertas coletivos collins colombiano comidas compartilhando concluida confie conscientizacao consolidacao continentes converter cordeiro correspondentes corrupto cumpriu dale dallas definicoes descendo destinados deveres distritos decimo earth emagrecer enfrentou estender estrategico estreita farei fera financiar find fundamento grammy hashtag incluidos influentes iniciando inseto integrada interino interpretacoes investigador ines irritado isolada lapa luanda lucio manobras mantidos margaret maternidade medicamento nascidos nintendo padres paguei palha participacoes pastoral pecuaria perigosas pesar poupar preferia prejuizos psicologica qui quieta raposa raymond rebecca reclamando restaurar reverter revolucionaria rob reu samsung saimos sintam socialismo sri sucessor susan suite tabaco tarifa terremoto tomara tommy trabalhei transmissoes treta tumblr tumor usavam uva vendem verbo vire vocal vossas word wordpress abrigar aceitam acerto alega aliviar amadora analistas aparecimento apontando assassinada assinaturas assine atlantica bancario bissau cancro cansaco capitalista cartel centavos chuck cirurgiao comissario compensar comprometer congregacao conselheiros contabilidade contratados contribuem contribuindo convencido conviccao copos covarde criticado cronicas cuidadosamente dedicados demonstrando depressa descobrem descobrimos descobrindo digna distinguir diametro documentarios edgar enche ensinamentos entro espalhou estudado expoe faremos fecho fenomenos flagrante forcando fosseis gangue garantias gravando graos helen honestidade impedindo incapacidade indenizacao instabilidade inteiros irregular islandia jamaica jogava latim legiao legitima libertado localizadas londrina lote lutador madame madre manchester maravilhosos marcel obstante oitenta org orkut paiva pavilhao percebemos perdidas pertencentes pesa pilha planejada pornografia pretendem provisoria psicologo reciclagem registos relatado removido representados research resumindo reunindo revelando ridicula riquezas rolo romana romances romper rapidas seguras skate sobremesa solicitacao sonhando sophie sorocaba summer sumo superficial sur surto suspensa tecnicamente telefonica terminaram titulares tomem trabalharam triplo village voa vocabulario volumes vacuo intimo acabaria aceitando acontecia ademais amazon ameacou aprendemos atingida auditorio avanca avatar bancaria banheira bell belos bolha boneco brasileirao brigas burocracia cairo calada cega celebra chanceler chata chegava christopher ciclone colecoes comandos comentarista compaixao companheira conservadores consistente cortesia criamos definitivo denominacao desenhada devendo diferentemente diminuiu dream ecologia egoista einstein enviaram epidemia escassez especialidade estrutural estagios eventual falada fantasias filtros formais franklin fresca genebra governanca grandeza guardado hamburguer heart herdeiro homenagens human impressa info interromper inedito jeans jogue joguei judas julga juntando limitar living lamina lesbica mai mede monitorar motel murphy naqueles narrador neil nerd north organizadores paes pague peninsula perdoa periferia pimentel podre portaria possuia produzindo programado prostitutas psol punho quanta recebera referem refrigerante renovar republicano respectivas sapo seattle seguia seguimos sobrevivente solucionar sonha stanley submeter socrates solido territorial trilhos trindade true utilizou vendedores verifique vingar virginia idolos abertamente abrange abrem abriram abundancia acusou adaptado adorava ago agostinho aguarde amou anuais anunciaram arizona armadura assuncao atribuido audiovisual automatica avisou aecio banca bispos boate bolsos calibre cearense ceder ceramica cinto close colorido comem completos compostos comumente confessar conjuntos conquistado contador contribuiram convem cortina cronograma culpada demonstrado descanse desprezo destroi deverao diretos disparo dragoes economias elefante elevar enfermeira enfiar escapou esqueceram existiam exportacoes faccao falhar farsa feministas ficarao figueiredo fingindo fornecem foro fortalecimento forcados frei folego gelada genes guerrero helicopteros history ilustracoes importacao impressionado injecao inspirar jeremy journal kurt lane laco ligam ligeiramente linguagens lola low maldita mandam manifesta manipular marc marfim marginal matei maya mereco mergulhar miles minoria modernizacao nadar nicolas noturna obs observe ofender olham olimpiada operadoras palcos permanentemente permitira pintor pipoca planejar plasticas precipitacao presidenta prontas pros pratico quadras qualificados queixas raimundo reclamam referentes reggae reinaldo rendimentos reportagens roberts robson ron rouba roubando sacos sarney segurancas sensacional sistematica talk terry there tirada tornaria toronto traficantes trair tratamentos treinos tragico tubos turca unanimidade uniformes verba verifica versos vigente voluntaria zumbi abordagens abusos administrar adquiriu afastou afetam afeto agitacao agressivo alcanca alegacoes alojamento ame aplausos arquipelago atacada aumentado aurelio autorizados barreto batido bike botoes brenda bruxas cadeias capas carencia casca certificacao chover circuitos colorida concursos confere confessou consertar constituida construidas convencoes conversei convocacao core couto crazy cre cuiaba cumprindo curvas deixarem deixaria deixara delicada desaparece desista destruidos detalhada disparos distancias ditador duke duras eclipse editado egipcio encaixa escolheram estreou excelentes excecoes exibida exigindo farias favoritas fianca fibras frias future gaga garanto gerada grey guardiao harold holmes horrores hunter identificou imbecil iminente imperial imprimir informal interferir interpretado investiga istambul java juridicas juiza liberada liceu luna macedonia maceio machista magoar mara martelo martha mentalidade missionario multas musa nativo naves negado negacao nisto objectivos observador ocorridos odeiam pagas patas peculiar pedia perfeitas perguntaram pertencente photo pilares piramide please porrada procurava prometido protegidos protocolos pulmao penaltis reconstruir referente reivindicacoes relativo representou resistente roman salarial satisfazer secretas semente senadora side skype soro sustenta tamanha tell tempestades transando taticas verbas vestigios veterano virei visitando viveram water wikipedia aceitavel acelerar adoravel afastamento ajuste ajustes aliancas aline ambicao amizades amorosa analisando aparecido apetite assina avancou bank barroso bebo biologica bloqueado bebada bencao calcinha camilo catarinense causadas cereais choice cinematografica citacoes college complexas compradores comunismo conheceram connosco construiram continuava control crescido criminalidade cup definem derrotas derrubou desaparecidos desliga dominicana ecologico encosta engana escutando espalhadas esperei estatais eternamente examinar excepcional executada factor fazendeiro feat filmagens florence fornecendo fragmentos francesas genial help her heroina holandes hospedagem humilhacao identidades implicacoes indicou indicios inesperado informados inspecao instalados instrutor instavel interessar inuteis isaac isolados javier jefferson joinville knight lanterna lente lentes lia licitacao lidando lidera lou made mantiveram mercosul messias moon mouse narracao nativas nora objecto objetiva obstaculo olinda paisagens palhacos permanentes portoes potencialmente pressoes prestigio presidio princesas prudente public recolha recomenda relembrar reservado respeitado roubos rubro ruptura sabrina sancoes sea semifinal significativas style submetido sabados tampouco tatuagens tecnologicas tecnologicos teriamos thor tiram trocando ufc vampiro voltados zelandia epocas abel ache act admissao alterado alugar ameacar antepassados aproveitou assistentes atendeu atingiram avisos azerbaijao bandeirantes barro blogue bndes botas brilhar cafes capacitacao capita cardeal cartazes casados chamem channel chapada cobrindo colisao comecem comemorando comuna conectados contado convenceu conversamos convivencia curiosamente dantas decepcao decidem desempenhar desfiles doses dragon dublado enterro equipado eras erik ervas escalao]==]):gmatch("%a+") do frequenciaIndependente.PT[w] = 2 end
-- Escolhe por etapas, sem afirmar que uma lista externa prova aceitação no jogo.
-- Fontes com maior evidência podem superar uma reserva ou uma principal fraca;
-- em empate, mantém a principal à frente. 10+ e PET só influenciam as duas primeiras.
local function selecionarTentativa(termo, modoAtual, prefixoFixo, numero)
local revisao, versao = revisaoFiltros, revisaoBancos
local permitidos = extrasPermitidos(termo)
local especial = numero <= 2 and permitidos
local function pet(w)
if not especial or modoPet == 0 then return 0 end
for i=1,#w-(modoPet==1 and 2 or 1) do
local a,b=w:byte(i,i+1)
if a>=97 and a<122 and b==a+1 then return 1 end
end
return 0
end
local function confianca(w, idioma)
if idioma == "EN" then
local freq = CommonWordsEN[w] or recuperados[2].Set[w] or recuperados[3].Set[w]
local dic = bEN.Set[w] or recuperados[4].Set[w]
if freq and dic then return 4 end
if freq then return 3 end
if dic then return 2 end
return 0
end
if comunsPT[w] or bancoPTCurado[w] then return 5 end
if bancos.PT.Set[w] or recuperados[1].Set[w] then return 2 end
return 0
end
local function melhorIdioma(idioma)
local principais = buscarAlternativas(termo, modoAtual, idioma, prefixoFixo, false, true, true)
local candidatos, vistos = {}, {}
local function incluir(lista,reserva)
for i,w in ipairs(lista) do
-- Ceder durante a classificação mantém a interface responsiva em listas amplas.
if i % 3000 == 0 then progressoBusca = os.clock(); task.wait() end
if not vistos[w] and not usedWords[w] and not listaNegra[w]
and encaixaBusca(w,termo,modoAtual,false)
and (prefixoFixo=="" or w:sub(1,#prefixoFixo)==prefixoFixo) then
vistos[w]=true
local categoria=(especial and modoPet == 2) and 0 or finalPriorizavel(w,idioma,modoFinais,especial and trioAtivo)
-- Na terceira, um final difícil continua difícil mesmo que a palavra não
-- tenha sido confirmada no ENABLE; confirmação só controla priorização.
if numero == 3 then categoria = categoriaFinal(w, idioma, modoFinais, false) end
local freq = frequenciaIndependente[idioma][w] or 0
candidatos[#candidatos+1]={w=w,cat=categoria,qualidade=confianca(w,idioma)+(numero==5 and 2*freq or 0),freq=freq,reserva=reserva,pet=pet(w)}
end
end
end
incluir(principais,false)
-- A reserva é consultada ao haver menos de 20 candidatas relevantes para a etapa.
local relevantes=0
for _,c in ipairs(candidatos) do
if numero==5 or (numero==3 and c.cat==0) or (numero~=3 and numero~=5 and c.cat>0) then relevantes+=1 end
end
if relevantes<20 then incluir(buscarNasReservas(termo,modoAtual,idioma,prefixoFixo,false,true,true),true) end
local function antes(a,b)
if numero <= 2 and modoLongas and faixaLonga(a.w)~=faixaLonga(b.w) then return faixaLonga(a.w)>faixaLonga(b.w) end
if especial and modoPet==1 and (a.cat>0)~=(b.cat>0) then return a.cat>0 end
-- Com PET 1, o trio ligado continua acima dos outros finais; PET 2 ignora finais.
if especial and modoPet==1 and trioAtivo and (a.cat==3)~=(b.cat==3) then return a.cat==3 end
if especial and modoPet>0 and a.pet~=b.pet then return a.pet>b.pet end
if numero<=2 or numero==4 then
if (a.cat>0)~=(b.cat>0) then return a.cat>0 end
if especial and trioAtivo and (a.cat==3)~=(b.cat==3) then return a.cat==3 end
elseif numero==3 then
if (a.cat==0)~=(b.cat==0) then return a.cat==0 end
end
-- A quinta não usa PET, final nem 10+: apenas evidência e desempates.
if a.qualidade~=b.qualidade then return a.qualidade>b.qualidade end
if estrategiaAtiva and numero<5 then
if a.respostas == nil then a.respostas=estimarRespostas(a.w) end
if b.respostas == nil then b.respostas=estimarRespostas(b.w) end
if a.respostas~=b.respostas then return a.respostas<b.respostas end
end
if a.reserva~=b.reserva then return not a.reserva end
if (#a.w>=4)~=(#b.w>=4) then return #a.w>=4 end
if #a.w~=#b.w then return #a.w<#b.w end
return a.w<b.w
end
local melhor
for _,c in ipairs(candidatos) do
if not usedWords[c.w] and (not melhor or antes(c,melhor)) then melhor=c end
end
return melhor
end
local preferido = numero == 4 and "PT" or "EN"
local primeiro = melhorIdioma(preferido)
local segundo
if numero==5 or not primeiro then segundo=melhorIdioma(preferido=="EN" and "PT" or "EN") end
local escolhido, idioma=primeiro,preferido
if segundo and (not escolhido or (numero==5 and (segundo.qualidade>escolhido.qualidade
or (segundo.qualidade==escolhido.qualidade and escolhido.reserva and not segundo.reserva)))) then
escolhido,idioma=segundo,preferido=="EN" and "PT" or "EN"
end
if revisao~=revisaoFiltros or versao~=revisaoBancos or (escolhido and usedWords[escolhido.w]) then return nil,nil,true end
return escolhido and escolhido.w or nil, idioma, false
end

local function runWord(automatico)
if estado.ocupado then return end
estado.ocupado = true
if not VirtualInputManager then
aviso("Entrada virtual indisponível"); estado.ocupado = false; return
end
if UserInputService:GetFocusedTextBox() == campoExtra then
aviso("Feche o campo de final"); estado.recuperavel = automatico; estado.ocupado = false; return
end
if estado.tentativasRodada >= config.maxTentativas then
aviso("Limite de tentativas atingido"); estado.recuperavel = false; estado.ocupado = false; return
end
local token = estado.token
local label, keys = getParts()
local termo = inputBox.Text:lower():gsub("%s", "")
local especialX = termo:sub(1, 1) == "x"
local function potenciaEfetiva() return config.potencia or especialX end
if not label or not keys or termo == "" or ultimoTermoPesquisado ~= termo or not current[index] then
aviso("Sem interface ou sugestão"); estado.recuperavel = automatico; estado.ocupado = false; return
end
local originalPrompt = promptText(label)
if originalPrompt and originalPrompt ~= termo then
aviso("Início mudou; revise antes de enviar"); estado.recuperavel = automatico; estado.ocupado = false; return
end
local inicial = readSlots(keys)
local prefixoInicial = inicial and inicial ~= "" and #inicial <= #termo
and termo:sub(1, #inicial) == inicial and inicial or ""
local tentativas = 0
local plano = not modoLongas and extrasPermitidos(termo) and (modoPet > 0 or trioAtivo)
estado.recuperavel = false
local evitarProximoX = false
local reservada, idiomaReservado = estado.candidatoRecuperacao, estado.idiomaRecuperacao
estado.candidatoRecuperacao, estado.idiomaRecuperacao = nil, nil
local candidatasPT = nil
local ultimaEnviada = nil
local function mesmaRodada()
local l, k = getParts()
return gui.Parent ~= nil and UserInputService:GetFocusedTextBox() ~= campoExtra and token == estado.token and l == label and k == keys
and (not automatico or config.automatico) and (not originalPrompt or promptText(l) == originalPrompt)
end
local function aguardarTexto(esperado, anterior, prazo)
local limite = os.clock() + prazo
repeat
if not mesmaRodada() then return false end
local visto = readSlots(keys)
if visto == esperado then return true end
if visto == nil or visto ~= anterior then return false end
task.wait(0.04)
until os.clock() >= limite
return false
end
local function confirmarLimpeza(esperado)
local ate = os.clock() + (potenciaEfetiva() and 0.25 or 0.40)
repeat
if not mesmaRodada() or readSlots(keys) ~= esperado then return false end
task.wait(0.05)
until os.clock() >= ate
return mesmaRodada() and readSlots(keys) == esperado
end
while estado.tentativasRodada < config.maxTentativas do
if not gui.Parent or token ~= estado.token or (automatico and not config.automatico) then break end
if currentRevisao ~= revisaoFiltros or currentRevisaoBancos ~= revisaoBancos then
local novas, lingua, _, temporario = buscarComExcecao(termo, modoBusca, idiomaResultados, prefixoInicial)
current, idiomaResultados, index = novas, lingua, 1
currentRelaxado, currentRevisao, currentRevisaoBancos = temporario, revisaoFiltros, revisaoBancos
reservada, idiomaReservado, candidatasPT = nil, nil, nil
end
local palavra, posicao
local idiomaTentativa = idiomaResultados
if reservada and not finalPermitido(reservada, currentRelaxado) then reservada, idiomaReservado = nil, nil end
if reservada then
palavra, idiomaTentativa = reservada, idiomaReservado
reservada, idiomaReservado = nil, nil
else
local mudou
palavra, idiomaTentativa, mudou = selecionarTentativa(termo, modoBusca, prefixoInicial, estado.tentativasRodada + 1)
if mudou then aviso("Prioridade mudou; revisando"); estado.recuperavel = automatico; break end

end
if idiomaTentativa == "EN" then evitarProximoX = false end
if not palavra then aviso("Sem mais sugestões"); break end
if usedWords[palavra] or palavra == ultimaEnviada then
aviso("Sugestão repetida bloqueada"); break
end
if not encaixaBusca(palavra, termo, modoBusca, currentRelaxado) then
aviso("Sugestão não corresponde; revisando")
estado.recuperavel = automatico
updateDisplay()
break
end
wordLabel.Text = palavra:upper()
infoLabel.Text = "Tentativa " .. idiomaTentativa .. " · " .. (#current) .. " EN/PT disponíveis"
local preenchido = readSlots(keys)
if preenchido == nil then aviso("Interface indisponível; parado"); break end
if preenchido ~= "" and palavra:sub(1, #preenchido) ~= preenchido then
aviso("Texto não corresponde; limpe manualmente"); break
end
local falha = false
for i = #preenchido + 1, #palavra do
if not mesmaRodada() or usedWords[palavra] then falha = true; break end
local anterior = palavra:sub(1, i - 1)
local esperado = palavra:sub(1, i)
if readSlots(keys) ~= anterior then falha = true; break end
local codigo = Enum.KeyCode[palavra:sub(i,i):upper()]
if not codigo or not key(codigo, potenciaEfetiva() and 0.02 or config.tecla) then falha = true; break end
if not aguardarTexto(esperado, anterior, 0.8) then falha = true; break end
local intervaloMin = potenciaEfetiva() and 12 or (tentativas > 0 and 26 or 35)
local intervaloMax = potenciaEfetiva() and 25 or (tentativas > 0 and 52 or 65)
task.wait(math.random(intervaloMin, intervaloMax) / 1000)
end
if falha then
aviso("Digitação interrompida"); estado.recuperavel = automatico
if automatico then estado.candidatoRecuperacao = palavra; estado.idiomaRecuperacao = idiomaTentativa end
break
end
task.wait(0.1)
if readSlots(keys) ~= palavra then
aviso("Digitação não confirmada; parado"); estado.recuperavel = automatico
if automatico then estado.candidatoRecuperacao = palavra; estado.idiomaRecuperacao = idiomaTentativa end
break
end
if not config.enter then aviso("Digitada; envie manualmente"); break end
-- Uma única autorização de Enter por palavra, antes de qualquer pausa.
-- A mecânica de pressionar/soltar continua igual à versão de 60 KB.
if not mesmaRodada() or usedWords[palavra] then aviso("Envio repetido ou rodada alterada; parado"); break end
marcarUsada(palavra)
if not key(Enum.KeyCode.Return) then
-- O pressionamento pode ter chegado ao jogo antes de ocorrer a falha.
-- Memorizar conservadoramente e não tentar outra palavra às cegas.
memorizarEnvio(palavra)
estado.recuperavel = false
aviso("Resposta incerta; parado")
break
end
ultimaEnviada = palavra
memorizarEnvio(palavra)
aviso("Enviada; aguardando resposta")
local tempoValidacao = config.verificar
local inicioValidacao = os.clock()
local resultado = "pendente"
while os.clock() - inicioValidacao < tempoValidacao do
task.wait(0.05)
if token ~= estado.token then resultado = "cancelado"; break end
local novaLabel, novasKeys = getParts()
if not novaLabel or not novasKeys or novasKeys ~= keys or novaLabel ~= label then
resultado = "incerto"; break
end
local agora, novoPrompt = readSlots(keys), promptText(novaLabel)
if agora == nil then resultado = "incerto"; break end
if agora == "" or (originalPrompt and novoPrompt and novoPrompt ~= originalPrompt) then
resultado = "mudou"; break
end
if agora ~= palavra then resultado = "incerto"; break end
end
if resultado == "cancelado" then break end
if resultado == "mudou" then
aviso("Campo mudou; confira aceitação")
break
end
if resultado == "incerto" then aviso("Resposta incerta; parado"); break end
tentativas = tentativas + 1
estado.tentativasRodada = estado.tentativasRodada + 1
if categoriaFinal(palavra, idiomaTentativa, "TODOS") > 0 then
estado.errosDificeis = estado.errosDificeis + 1
if estado.errosDificeis >= 2 then estado.finaisSuspensos = true end
end
if estado.tentativasRodada >= config.maxTentativas then
aviso("Limite de tentativas atingido"); estado.recuperavel = false; break
end
if plano and estado.tentativasRodada >= 3 then
estado.finaisSuspensos = true
estado.portuguesAteFim = true
end
if idiomaTentativa == "EN" then
estado.inglesRejeitadas = estado.inglesRejeitadas + 1
if modoLongas or especialX or (config.alternarPT and estado.inglesRejeitadas >= 2) then estado.portuguesAteFim = true end
evitarProximoX = palavra:sub(-1) == "x"
end
if not config.tentarProxima then aviso("Possível rejeição; parado"); break end
local proxima, proximoIdioma, mudou = selecionarTentativa(termo, modoBusca, prefixoInicial, estado.tentativasRodada + 1)
if mudou then aviso("Prioridade mudou; revisando"); estado.recuperavel = automatico; break end
if not proxima then aviso("Sem mais sugestões"); break end
if proxima == palavra or usedWords[proxima] then aviso("Sugestão repetida bloqueada"); break end
-- Só 50 ms adicionais antes de apagar; revalidar em caso de resposta tardia.
task.wait(0.05)
if not mesmaRodada() or readSlots(keys) ~= palavra then
aviso("Campo mudou; confira aceitação"); break
end
aviso("Possível rejeição; apagando")
local limpa = false
local limiteApagar = modoLongas and 18 or 14
for tentativa = 0, limiteApagar do
local l, k = getParts()
if token ~= estado.token or l ~= label or k ~= keys
or (originalPrompt and promptText(l) ~= originalPrompt) then falha = true; break end
local antes = readSlots(keys)
if antes == nil or palavra:sub(1, #antes) ~= antes then falha = true; break end
if antes == "" or (prefixoInicial ~= "" and antes == prefixoInicial
and proxima:sub(1, #antes) == antes) then limpa = true; break end
if tentativa == limiteApagar then break end
local esperado = antes:sub(1, -2)
if not key(Enum.KeyCode.Backspace, math.random(potenciaEfetiva() and 10 or 22, potenciaEfetiva() and 16 or 38) / 1000) then falha = true; break end
if not aguardarTexto(esperado, antes, 0.8) then falha = true; break end
end
if falha or not limpa then aviso("Apagar não confirmado; parado"); break end
local base = readSlots(keys)
aviso("Confirmando campo limpo")
if not confirmarLimpeza(base) then aviso("Campo mudou; parado"); break end
if usedWords[proxima] or proxima == ultimaEnviada then aviso("Sugestão repetida bloqueada"); break end
reservada, idiomaReservado = proxima, proximoIdioma
aviso("Próxima tentativa " .. (estado.tentativasRodada + 1) .. ": " .. proximoIdioma)
end
if estado.tentativasRodada >= config.maxTentativas then aviso("Limite de tentativas atingido") end
estado.ocupado = false
end
local function executarComSeguranca(automatico)
local ok, err = pcall(runWord, automatico)
if not ok then
estado.ocupado = false
aviso("Erro na automação; interrompida")
warn("Word System: erro na automação:", err)
end
if pendenteUI then
pendenteUI = false
index = 1
updateDisplay()
end
end
autoBtn.MouseButton1Click:Connect(function() task.spawn(executarComSeguranca, false) end)
local function agendarAutomatico(letra, label, keys)
local tokenAgendado = estado.token
local geracaoAgendada = estado.geracao
local atrasoInicio = config.inicio
task.spawn(function()
task.wait(atrasoInicio)
local limite = os.clock() + 60
while config.automatico and tokenAgendado == estado.token and geracaoAgendada == estado.geracao
and inputBox.Text:lower() == letra and (ultimoTermoPesquisado ~= letra or estado.ocupado)
and os.clock() < limite do task.wait(0.1) end
local atualLabel, atualKeys = getParts()
if not gui.Parent or not config.automatico or tokenAgendado ~= estado.token or geracaoAgendada ~= estado.geracao then return end
if inputBox.Text:lower() ~= letra or atualLabel ~= label or atualKeys ~= keys then return end
if ultimoTermoPesquisado ~= letra or estado.ocupado then
estado.rodada = nil
aviso("Aguardando pesquisa")
return
end
local prompt = promptText(atualLabel)
local slots = readSlots(atualKeys)
local sinal = prompt or (slots and #slots <= 18 and slots or nil)
if sinal ~= letra then
aviso("Sinal mudou; aguardando rodada")
return
end
if #current == 0 then aviso("Sem sugestões para esta rodada"); estado.recuperavel = true; return end
executarComSeguranca(true)
end)
end
local function tentarRecuperacao(letra, label, keys)
if config.automatico and estado.recuperavel and estado.recuperacoes < 2
and letra and inputBox.Text:lower() == letra and ultimoTermoPesquisado == letra then
local candidato = (estado.candidatoRecuperacao and finalPermitido(estado.candidatoRecuperacao, currentRelaxado) and estado.candidatoRecuperacao) or escolherProxima(false)
local campo = readSlots(keys)
if candidato and not usedWords[candidato] and encaixaBusca(candidato, letra, modoBusca, currentRelaxado)
and campo and candidato:sub(1, #campo) == campo then
estado.recuperavel = false
estado.rodada = letra
estado.recuperacoes = estado.recuperacoes + 1
local tokenRec = estado.token
local geracaoRec = estado.geracao
task.delay(0.6, function()
local l, k = getParts()
if gui.Parent and config.automatico and not estado.ocupado and tokenRec == estado.token
and geracaoRec == estado.geracao and l == label and k == keys
and readSlots(keys) == campo and not usedWords[candidato]
and ultimoTermoPesquisado == letra then
executarComSeguranca(true)
end
end)
end
end
end
revisarBtn.MouseButton1Click:Connect(function()
if estado.ocupado then aviso("Aguarde a tentativa atual"); return end
local label, keys = getParts()
local sinal = label and keys and detect(label, keys) or nil
local termo = sinal or (inputBox.Text or ""):lower():gsub("%s", "")
if termo == "" then aviso("Sem início para revisar"); return end
estado.geracao = estado.geracao + 1
estado.rodada = nil
estado.recuperavel = false
estado.candidatoRecuperacao = nil; estado.idiomaRecuperacao = nil
estado.ultimaAtividade = os.clock()
if inputBox.Text ~= termo then inputBox.Text = termo end
index = 1
updateDisplay()
aviso("Revisando início e palavras usadas")
end)
local function verificarInatividade(letra, label, keys)
local agora = os.clock()
local campo = readSlots(keys)
if estado.campoObservado ~= campo or estado.sinalObservado ~= letra then
estado.campoObservado = campo; estado.sinalObservado = letra
estado.ultimaAtividade = agora
return
end
local ultima = estado.ultimaAtividade or agora
if not estado.ultimaAtividade then estado.ultimaAtividade = agora end
local prazoInatividade = (ultimoTermoPesquisado ~= letra or #current == 0) and 2 or 3
-- Se uma pesquisa vazia acabou de encontrar opções, não aguardar mais três segundos.
-- A retomada ainda passa pela confirmação de campo/sinal e pela pausa de segurança.
if estado.recuperavel and #current > 0 and (estado.status == "Revisando sugestões" or estado.status == "Sem sugestões para esta rodada") then prazoInatividade = 0 end
if not config.automatico or estado.ocupado or not letra or not campo
or agora - ultima < prazoInatividade then return end
if estado.status == "Campo mudou; confira aceitação" or estado.status == "Resposta incerta; parado"
or estado.status == "Limite de tentativas atingido"
or estado.status == "Digitada; envie manualmente" then return end
if (inputBox.Text or ""):lower():gsub("%s", "") ~= letra then return end
if ultimoTermoPesquisado ~= letra then
local terminada = not searchThread
if searchThread then
local ok, situacao = pcall(coroutine.status, searchThread)
terminada = ok and situacao == "dead"
end
if databaseLoaded then
if resgateBuscaTermo ~= letra then resgateBuscaTermo, resgatesBusca = letra, 0 end
-- Duas recuperações rápidas; depois, novas tentativas espaçadas para não
-- sobrecarregar um aparelho lento nem exigir que o jogador aperte VER.
local prazoBusca = resgatesBusca < 2 and 2 or 10
local travada = not terminada and agora - progressoBusca >= prazoBusca
if travada and type(searchThread) == "thread" then
local ok = pcall(task.cancel, searchThread)
if ok then searchThread = nil; terminada = true; resgatesBusca = resgatesBusca + 1 end
end
if terminada then
estado.ultimaAtividade = agora
aviso("Refazendo pesquisa")
updateDisplay()
elseif travada then
estado.ultimaAtividade = agora
aviso("Aguardando pesquisa em andamento")
end
end
return
end
estado.ultimaAtividade = agora -- evita revisões em sequência
local candidato = (estado.candidatoRecuperacao and finalPermitido(estado.candidatoRecuperacao, currentRelaxado) and estado.candidatoRecuperacao) or escolherProxima(false)
if not candidato or usedWords[candidato] or not encaixaBusca(candidato, letra, modoBusca, currentRelaxado) then
aviso("Revisando sugestões")
updateDisplay()
return
end
if candidato:sub(1, #campo) ~= campo then
aviso("Campo incompatível; confira antes de continuar")
return
end
estado.recuperavel = true
estado.recuperacoes = 0
aviso("Inativo: conferindo para continuar")
tentarRecuperacao(letra, label, keys)
end
local function preservarSinalAnterior(letra, ultima, label)
-- Se não há texto explícito de desafio, uma palavra já enviada que ainda
-- aparece nos slots não comprova que começou outra rodada.
if not promptText(label) and ultima and letra and letra ~= ultima and usedWords[letra] then return ultima end
return letra
end
task.spawn(function()
local ultima = nil
while gui.Parent do
task.wait(0.15)
if not estado.ocupado then
local label, keys = getParts()
if label and keys then
local letra = preservarSinalAnterior(detect(label, keys), ultima, label)
local parcial = estado.candidatoRecuperacao
if estado.recuperavel and not promptText(label) and ultima and letra and parcial
and #letra > #ultima and letra:sub(1, #ultima) == ultima
and parcial:sub(1, #letra) == letra then letra = ultima end
if not letra and ultima then
ultima = nil
estado.geracao = estado.geracao + 1
estado.rodada = nil
end
if letra and letra ~= ultima then
estado.geracao = estado.geracao + 1
ultima = letra
estado.inglesRejeitadas = 0; estado.portuguesAteFim = false; estado.errosDificeis = 0; estado.finaisSuspensos = false; estado.tentativasRodada = 0; estado.recuperavel = false; estado.recuperacoes = 0; estado.candidatoRecuperacao = nil; estado.idiomaRecuperacao = nil
estado.rodada = nil
inputBox.Text = letra
end
tentarRecuperacao(letra, label, keys)
verificarInatividade(letra, label, keys)
if config.automatico and letra and estado.rodada ~= letra then
estado.rodada = letra
agendarAutomatico(letra, label, keys)
end
else
if ultima then estado.geracao = estado.geracao + 1 end
ultima = nil; estado.rodada = nil
end
end
end
end)
end, function(erro) return tostring(erro) end)
if not iniciou then
warn("Word System: falha na inicialização: " .. tostring(erroInicial))
pcall(function()
local players = game:GetService("Players")
local pg = players.LocalPlayer:WaitForChild("PlayerGui")
local aviso = Instance.new("ScreenGui")
aviso.Name = "WordSystemDiagnostico"
aviso.ResetOnSpawn = false
aviso.DisplayOrder = 1000000
local caixa = Instance.new("TextLabel")
caixa.Size = UDim2.new(0, 360, 0, 120)
caixa.Position = UDim2.new(0.5, -180, 0.3, 0)
caixa.BackgroundColor3 = Color3.fromRGB(70, 15, 15)
caixa.TextColor3 = Color3.fromRGB(255, 255, 255)
caixa.TextWrapped = true
caixa.TextSize = 14
caixa.Text = "Word System: falha ao iniciar. Envie uma foto deste erro:\n" .. tostring(erroInicial)
caixa.Parent = aviso
aviso.Parent = pg
end)
end
