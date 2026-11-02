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
local finaisDificeis = {"pter", "ack", "eat", "ick", "ny", "om", "ok", "gn", "pt", "ct", "ia", "gh", "ux", "ug", "mn", "ow", "xy", "x"}
local finaisTrio = {ack = true, eat = true, ick = true}
local trioAtivo = false
-- XY começa desligado; o final personalizado começa vazio.
local finaisDesligados = {xy = true}
local finaisOff = {"xy"}
local sufixosOff, tamanhosOff = {xy = true}, {2}
local finalExtra, extraLigado, botaoExtra, enterExtra = "", false, nil, nil
local revisaoFiltros = 0
local botoesFinais = {}
local function finalPermitido(w, temporario)
if temporario then return true end
for _, tamanho in ipairs(tamanhosOff) do
if #w >= tamanho and sufixosOff[w:sub(-tamanho)] then return false end
end
return true
end
local function atualizarFinaisDesligados()
revisaoFiltros = revisaoFiltros + 1
finaisOff = {}
for _, fim in ipairs(finaisDificeis) do
if finaisDesligados[fim] then finaisOff[#finaisOff+1] = fim end
end
if finalExtra ~= "" and not extraLigado then finaisOff[#finaisOff+1] = finalExtra end
local mapa, tamanhos, vistos = {}, {}, {}
for _, fim in ipairs(finaisOff) do
mapa[fim] = true
local tamanho = #fim
if not vistos[tamanho] then vistos[tamanho] = true; tamanhos[#tamanhos+1] = tamanho end
end
sufixosOff, tamanhosOff = mapa, tamanhos
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
if modo == "NENHUM" or not finalPermitido(w) then return 0 end
for _, fim in ipairs(finaisDificeis) do
if #w >= #fim and w:sub(-#fim) == fim
and (prefixosDificeis.EN[fim] or prefixosDificeis.PT[fim])
and (not finaisTrio[fim] or usarTrio)
and (modo ~= "X" or fim == "x") and (modo ~= "OUTROS" or fim ~= "x") then
if finaisTrio[fim] then return 3 end
return fim == "x" and (modo == "X" and 2 or 1) or 2
end
end
if extraLigado and finalExtra ~= "" and modo ~= "X" and w:sub(-#finalExtra) == finalExtra then return 2 end
return 0
end
local CommonWordsEN = {}
local comunsPT = {}
for w in ("xale xote casa vida amor agua boca bola bolo cabo cafe cama campo capa cara caro caso cedo cena cima cidade cola como copa cora corpo dado dama dedo dias dica doce dose duro faca face fato feira festa fino foco fogo fora forma foto frio gato gelo giro guia hora ideia ilha jogo laje lago lado lama lana lata leite lima lindo lobo logo lua lupa lupa mala mapa marca mata mesa medo meio meta moda modo mola mora muda muro nada nome nota nova novo olho onda ouro pais para pato pedra pele pena pelo peso piso plano povo praia prata rede rei remo reta roda roupa rosa seco sede selo sino sopa tela tema tempo terra teto texto tipo todo tudo unha uva vale vela vida vila vinho viva vivo voz zona"):gmatch("%a+") do comunsPT[w] = true end
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
return base1 * 0.25 + base2 * 0.50 + base3 * 0.25
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
local pterA = pa[3] > 0 and a:sub(-4) == "pter"
local pterB = pb[3] > 0 and b:sub(-4) == "pter"
if estrategiaNoMomento then
-- A estimativa só supera a diferença entre níveis de confiança quando ambas
-- as palavras têm evidência mínima; dados ausentes nunca significam vitória.
local seguraA, seguraB = pa[2] >= 2, pb[2] >= 2
if seguraA ~= seguraB then return seguraA end
if seguraA then
if ca ~= cb then return ca end
if pterA ~= pterB then return pterA end
if pa[4] ~= pb[4] then return pa[4] < pb[4] end
end
end
if pa[2] ~= pb[2] then return pa[2] > pb[2] end
if ca ~= cb then return ca end
if pterA ~= pterB then return pterA end
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
-- Pesquisa os dois idiomas antes de considerar a reativação dos filtros.
-- A memória de palavras usadas e o prefixo fixo continuam obrigatórios.
local function buscarAlternativas(termo, modoAtual, idiomaPreferido, prefixoFixo, temporario)
prefixoFixo = prefixoFixo or ""
local curtas, idiomaCurtas, fontesCurtas
for tentativaIdioma = 1, (termo ~= "" and 2 or 1) do
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
ordenarCandidatos(matches, idioma, termo)
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
local function buscarNasReservas(termo, modoAtual, idiomaPreferido, prefixoFixo, temporario)
local curtas, idiomaCurtas, fontesCurtas
for tentativa = 1, 2 do
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
ordenarCandidatos(matches, idioma, termo)
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
if #matches == 0 and termo ~= "" and #finaisOff > 0 then
temporario = true
matches, lingua, fontes = buscarAlternativasEstavel(termo, modoAtual, idioma, prefixoFixo, true)
if #matches == 0 then matches, lingua, fontes = buscarNasReservas(termo, modoAtual, idioma, prefixoFixo, true) end
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
b.Text = "FINAIS: " .. modoFinais
index = 1
updateDisplay()
end)
linha("PET BOMB: DESLIGADO", function(b)
modoPet = (modoPet + 1) % 3
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
b.Text = "FINAIS FORTES: " .. (estrategiaAtiva and "LIGADO" or "DESLIGADO")
if estado.ocupado then
pendenteUI = true
aviso("Estratégia atualiza após tentativa")
else
index = 1
updateDisplay()
end
end)
linha("TRIO ACK/EAT/ICK: NÃO", function(b)
trioAtivo = not trioAtivo
b.Text = "TRIO ACK/EAT/ICK: " .. (trioAtivo and "SIM" or "NÃO")
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
local filtroBotao = linha("FILTROS DE FINAIS ▼", function(b)
filtrosAbertos = not filtrosAbertos
b.Text = filtrosAbertos and "FILTROS DE FINAIS ▲" or "FILTROS DE FINAIS ▼"
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
for i, fim in ipairs(finaisDificeis) do
local botaoFim = Instance.new("TextButton", gradeFinais)
botaoFim.Name = "Final_" .. fim:upper()
botoesFinais[fim] = botaoFim
local coluna, linhaIndice = (i - 1) % 5, math.floor((i - 1) / 5)
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
linha("PALAVRAS 10+: DESLIGADO", function(b)
modoLongas = not modoLongas
b.Text = "PALAVRAS 10+: " .. (modoLongas and "LIGADO" or "DESLIGADO")
if estado.ocupado then pendenteUI = true; aviso("Palavras grandes após tentativa")
else index = 1; updateDisplay() end
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
if #w >= 3 and #w <= 18 and w:match("^[a-z]+$") and w:match("[aeiouy]") and not listaNegra[w]
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
and (not originalPrompt or promptText(l) == originalPrompt)
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
if (currentRelaxado and currentRevisao ~= revisaoFiltros) or currentRevisaoBancos ~= revisaoBancos then
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
if plano and estado.tentativasRodada >= 3 and idiomaResultados == "PT" then
palavra = escolherPT(current, plano)
else
palavra, posicao = escolherProxima(evitarProximoX and config.alternarX and idiomaResultados == "EN", plano)
if posicao then index = posicao end
end
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
local proxima, proximoIdioma
if (idiomaResultados == "EN" or modoLongas) and (config.alternarPT or especialX or modoLongas) and estado.portuguesAteFim then
if not candidatasPT then
aviso("Buscando alternativa PT")
candidatasPT = obterCandidatasPT(termo, modoBusca, prefixoInicial)
end
proxima = escolherPT(candidatasPT, plano)
if modoLongas and proxima and idiomaResultados == "EN" then
local longaEN = escolherProxima(false, false)
if longaEN and faixaLonga(longaEN) > faixaLonga(proxima) then proxima = longaEN; proximoIdioma = "EN" end
end
if proxima and not proximoIdioma then proximoIdioma = "PT" end
end
if not proxima then
if plano and estado.tentativasRodada >= 3 and idiomaResultados == "PT" then
proxima = escolherPT(current, plano)
else
proxima = escolherProxima(evitarProximoX and config.alternarX and idiomaResultados == "EN", plano)
end
proximoIdioma = idiomaResultados
end
if not proxima then
-- A lista mostrada pode ter se esgotado; consulte ambos os idiomas antes
-- de desbloquear finais. Nunca apague a memória nem ultrapasse o limite.
local novas, novoIdioma, _, temporario = buscarComExcecao(termo, modoBusca, idiomaResultados, prefixoInicial)
if temporario then aviso("Sem opções; exceção temporária de filtros") end
if #novas > 0 then
currentRelaxado, currentRevisao, currentRevisaoBancos = temporario, revisaoFiltros, revisaoBancos
current, idiomaResultados, index = novas, novoIdioma, 1
ultimoTermoPesquisado = termo
if plano and estado.tentativasRodada >= 3 and idiomaResultados == "PT" then
proxima = escolherPT(current, plano)
else
proxima = escolherProxima(evitarProximoX and config.alternarX and idiomaResultados == "EN", plano)
end
proximoIdioma = idiomaResultados
end
end
if modoLongas and proxima and faixaLonga(proxima) < 2 then
local melhores, linguaMelhor, _, temporarioMelhor = buscarComExcecao(termo, modoBusca, proximoIdioma or idiomaResultados, prefixoInicial)
if #melhores > 0 and faixaLonga(melhores[1]) > faixaLonga(proxima) then
current, idiomaResultados, index = melhores, linguaMelhor, 1
currentRelaxado, currentRevisao, currentRevisaoBancos = temporarioMelhor, revisaoFiltros, revisaoBancos
ultimoTermoPesquisado = termo; candidatasPT = nil
proxima = escolherGrande(current, linguaMelhor, estado.tentativasRodada, currentRelaxado)
proximoIdioma = linguaMelhor
end
end
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
aviso((plano and estado.tentativasRodada == 2 and "Final difícil: " or estado.finaisSuspensos and "Final comum: " or "Tentando próxima: ") .. proximoIdioma)
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
