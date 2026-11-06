-- Word System — revisão.
-- As conexões nos serviços globais precisam ser removidas ao fechar ou falhar.
local conexoesGlobais = {}
local downloadsAtivos = {}
local guiInicializando
local function cancelarDownloads()
for item in pairs(downloadsAtivos) do
item.geracao = (item.geracao or 0) + 1
if item.thread then pcall(task.cancel, item.thread) end
downloadsAtivos[item] = nil
end
end
local function desconectarGlobais()
for _, conexao in ipairs(conexoesGlobais) do pcall(function() conexao:Disconnect() end) end
table.clear(conexoesGlobais)
end
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
downloadsAtivos[item] = true
item.thread = task.spawn(function()
local ok, texto = pcall(function() return game:HttpGet(item.url) end)
if item.geracao ~= geracao then return end
downloadsAtivos[item] = nil
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
local prioridade = 0
for _, fim in ipairs(finaisDificeis) do
if not finaisDesligados[fim] and #w >= #fim and w:sub(-#fim) == fim
and (prefixosDificeis.EN[fim] or prefixosDificeis.PT[fim])
and (not finaisTrio[fim] or usarTrio)
and (modo ~= "X" or fim == "x") and (modo ~= "OUTROS" or fim ~= "x") then
-- A palavra idêntica ao trio não recebe prioridade do trio, mas pode
-- receber a de outro final ligado que também coincida com ela.
if finaisTrio[fim] then
if #w > #fim then return 3 end
elseif fim == "x" and modo ~= "X" then
prioridade = math.max(prioridade, 1)
else
prioridade = 2
end
end
end
if extraLigado and finalExtra ~= "" and modo ~= "X" and w:sub(-#finalExtra) == finalExtra then prioridade = math.max(prioridade, 2) end
return prioridade
end
local CommonWordsEN = {}
local comunsPT = {iate = true, iates = true}
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
-- Construa fora dos mapas publicados: uma palavra pode ser marcada enquanto
-- o carregamento cede processamento, e deve ser contada exatamente uma vez.
local novasEstatisticas = novosMapas()
local novosDificeis = {EN = {}, PT = {}}
for idioma, dados in pairs(bancos) do
for i, palavra in ipairs(dados.List) do
registrarEm(novasEstatisticas, idioma, palavra)
for _, fim in ipairs(finaisDificeis) do
if palavra:sub(1, #fim) == fim then novosDificeis[idioma][fim] = true end
end
if i % 20000 == 0 then task.wait() end
end
end
prefixStats, prefixosDificeis = novasEstatisticas, novosDificeis
prefixosUsados = novosMapas()
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
guiInicializando = gui
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
local sugestaoExibida = nil
local selecaoManual = false
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
local selecionarTentativa, estado, getParts, readSlots, promptText
local geracaoPesquisa = 0
local function updateDisplay()
sugestaoExibida = nil
selecaoManual = false
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
sugestaoExibida = current[index]
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
-- A lista visual histórica e o plano de cinco etapas têm ordenações
-- diferentes. Mostre qual seria a próxima do plano, sem substituir current.
if index == 1 and selecionarTentativa and estado and not estado.ocupado then
local rodada, tentativa = estado.token, estado.tentativasRodada + 1
local prevista, linguaPrevista, mudou
local prefixoPrevisto = modoBusca == "PREFIXO" and termo or ""
local teclasPrevistas, campoPrevisto
-- A prévia respeita parte da resposta que já esteja no campo.
if getParts and readSlots then
local labelPrevista
labelPrevista, teclasPrevistas = getParts()
campoPrevisto = teclasPrevistas and readSlots(teclasPrevistas)
if campoPrevisto and campoPrevisto ~= "" then
if modoBusca == "PREFIXO" and #campoPrevisto > #termo and campoPrevisto:sub(1, #termo) == termo then prefixoPrevisto = campoPrevisto
elseif modoBusca == "CONTEM" and promptText and promptText(labelPrevista) == termo then prefixoPrevisto = campoPrevisto end
end
end
local recuperada = estado.candidatoRecuperacao
if recuperada and not usedWords[recuperada] and recuperada:sub(1, #prefixoPrevisto) == prefixoPrevisto
and encaixaBusca(recuperada, termo, modoBusca, false) then
prevista, linguaPrevista, mudou = recuperada, estado.idiomaRecuperacao or idiomaUtilizado, false
else
local primeiraFonte = rawget(viciadosInseridos, current[1] .. "_fonte")
local cache = {idioma = idiomaUtilizado, lista = primeiraFonte == "RESERVA" and {} or current,
revisao = currentRevisao, bancos = currentRevisaoBancos, termo = termo, modo = modoBusca}
prevista, linguaPrevista, mudou = selecionarTentativa(termo, modoBusca, prefixoPrevisto, tentativa, false, cache)
end
if minhaGeracao ~= geracaoPesquisa or not gui.Parent or (inputBox.Text or ""):lower():gsub("%s", "") ~= termo then return end
if teclasPrevistas then
local _, teclasAtuais = getParts()
if teclasAtuais ~= teclasPrevistas or readSlots(teclasAtuais) ~= campoPrevisto then return end
end
if not mudou and not estado.ocupado and not selecaoManual and index == 1
and estado.token == rodada and estado.tentativasRodada + 1 == tentativa then
if prevista and not usedWords[prevista] then
sugestaoExibida = prevista
wordLabel.Text = prevista:upper()
infoLabel.Text = "Próxima " .. linguaPrevista .. " · tentativa " .. tentativa .. " | " .. #current .. " na lista"
elseif not prevista then
sugestaoExibida = nil
wordLabel.Text = "sem palavra compatível"
infoLabel.Text = "Confira o texto já preenchido"
end
end
end
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
if not gui.Parent then return end
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
if c % 35000 == 0 then task.wait(); if not gui.Parent then return end end
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
if not gui.Parent then return end
for _, item in ipairs(fontesRede) do
if item.terminou and item.ok then
carregarTextoNoDicionario(item.texto, item.linguaFonte, item.comum, item.tipo)
item.texto = nil; item.consumido = true
if not gui.Parent then return end
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
if i % 30000 == 0 then task.wait(); if not gui.Parent then return end end
end
rebuildPrefixStats()
if not gui.Parent then return end
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
conexoesGlobais[#conexoesGlobais + 1] = UserInputService.InputChanged:Connect(function(i)
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
-- A palavra exibida deve continuar sendo a que está sendo digitada.
if estado and estado.ocupado then return end
if #current == 0 then return end
index = ((index - 2) % #current) + 1
sugestaoExibida = current[index]
selecaoManual = true
wordLabel.Text = current[index]:upper()
infoLabel.Text = index .. " / " .. #current .. " (" .. (idiomaResultados == "PT" and "Português" or "Inglês") .. ")"
end)
nextBtn.MouseButton1Click:Connect(function()
-- A palavra exibida deve continuar sendo a que está sendo digitada.
if estado and estado.ocupado then return end
if #current == 0 then return end
index = index % #current + 1
sugestaoExibida = current[index]
selecaoManual = true
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
useBtn.MouseButton1Click:Connect(function()
local termo = (inputBox.Text or ""):lower():gsub("%s", "")
if sugestaoExibida and ultimoTermoPesquisado == termo then registrarPalavraNaMemoria(sugestaoExibida) end
end)
local config = {automatico = false, enter = true, tentarProxima = true, verificar = 0.55, inicio = 0.8, tecla = 0.04, maxTentativas = 5, alternarPT = true, alternarX = true, potencia = false}
estado = {ocupado = false, token = 0, geracao = 0, rodada = nil, inglesRejeitadas = 0, portuguesAteFim = false, errosDificeis = 0, finaisSuspensos = false, tentativasRodada = 0, recuperavel = false, recuperacoes = 0, status = "Auto desligado"}
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
local bloqueiosSeguranca = {
["Campo mudou; confira aceitação"] = true, ["Resposta incerta; parado"] = true,
["Limite de tentativas atingido"] = true, ["Digitada; envie manualmente"] = true,
["Apagar não confirmado; parado"] = true, ["Campo mudou; parado"] = true,
["Texto não corresponde; limpe manualmente"] = true, ["Envio repetido ou rodada alterada; parado"] = true,
["Interface indisponível; parado"] = true, ["Erro na automação; interrompida"] = true,
["Sinal incerto; confira rodada"] = true
}
local function liberarConferencia()
estado.bloqueioSeguranca = nil
estado.envioComFalha = false
estado.status = ""
end
local function aviso(t)
-- Avisos normais de botões ou pesquisas não liberam paradas de segurança.
if bloqueiosSeguranca[estado.status] then estado.bloqueioSeguranca = estado.bloqueioSeguranca or estado.status end
if bloqueiosSeguranca[t] then estado.bloqueioSeguranca = t end
estado.status = estado.bloqueioSeguranca or t
status.Text = estado.status
end
local botaoAuto = linha("AUTO: DESLIGADO", function(b)
config.automatico = not config.automatico
estado.token = estado.token + 1
b.Text = config.automatico and "AUTO: LIGADO" or "AUTO: DESLIGADO"
b.BackgroundColor3 = config.automatico and Color3.fromRGB(29, 53, 48) or Color3.fromRGB(55, 34, 42)
if config.automatico then
if not estado.ocupado then liberarConferencia() end
estado.rodada = nil; aviso("Aguardando sinal da rodada")
else aviso("Auto desligado") end
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
downloadsAtivos[item] = nil
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
elseif inputBox.Text ~= "" and not selecaoManual then updateDisplay() end
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
downloadsAtivos[item] = nil
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
if gui.Parent and databaseLoaded and inputBox.Text ~= "" then
if estado.ocupado then pendenteUI = true
elseif not selecaoManual then updateDisplay() end
end
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
getParts = function()
local target = findTargetGui()
local top = target and target:FindFirstChild("TopBar")
local question = top and top:FindFirstChild("Question")
local answer = top and top:FindFirstChild("AnswerInput")
return question and question:FindFirstChild("QuestionLabel"), answer and answer:FindFirstChild("Keys")
end
readSlots = function(keys)
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
local function normalizarTextoDesafio(texto)
-- string.lower em Luau não normaliza letras acentuadas UTF-8.
return (texto or ""):lower():gsub("Ç", "ç"):gsub("É", "é")
end
promptText = function(label)
if not label or not label.Parent then return nil end
local t = normalizarTextoDesafio(label.Text)
return t:match('"%s*([a-z]+)%s*"') or t:match("starting with%s+([a-z]+)")
or t:match("contains%s+([a-z]+)") or t:match("contendo%s+([a-z]+)")
or t:match("contém%s+([a-z]+)") or t:match("contem%s+([a-z]+)") or t:match("contenha%s+([a-z]+)")
or t:match("começando com%s+([a-z]+)")
or t:match("starts with%s+([a-z]+)") or t:match("comece com%s+([a-z]+)")
or t:match("comeca com%s+([a-z]+)")
end
local function detect(label, keys)
local t = normalizarTextoDesafio(label and label.Text)
local novoModo = (t:find("contain") or t:find("contém") or t:find("contem") or t:find("contenha") or t:find("contendo")) and "CONTEM" or "PREFIXO"
if modoBusca ~= novoModo then modoBusca = novoModo; updateDisplay() end
if not travaIdiomaManual then
if t:find("type a word") or t:find("starting with") or t:find("starts with") or t:find("contains") then setIdioma("EN")
elseif t:find("digite") or t:find("palavra") or t:find("contenha") or t:find("contendo")
or t:find("contém") or t:find("contem") or t:find("começando com")
or t:find("comece com") or t:find("comeca com") then setIdioma("PT") end
end
local p = promptText(label)
if p and #p >= 1 and #p <= 18 then return p end
local slots = readSlots(keys)
if slots and #slots >= 1 and #slots <= 18 then return slots end
end
local function key(k, duracao)
if not VirtualInputManager then aviso("Entrada virtual indisponível"); return false end
estado.ultimaAtividade = os.clock()
local precisaSoltar = true
local ok = pcall(function()
VirtualInputManager:SendKeyEvent(true, k, false, game)
task.wait(duracao or config.tecla)
VirtualInputManager:SendKeyEvent(false, k, false, game)
precisaSoltar = false
end)
if precisaSoltar then pcall(function() VirtualInputManager:SendKeyEvent(false, k, false, game) end) end
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
-- Durante a tentativa, mantenha visível a palavra que acabou de ser enviada.
-- A lista será atualizada quando a operação terminar.
if estado.ocupado then pendenteUI = true; return end
sugestaoExibida = current[index]
wordLabel.Text = current[index] and current[index]:upper() or "sem palavras"
infoLabel.Text = current[index] and (index .. " / " .. #current) or "Nenhuma sugestão disponível"
end
local function interromperPorEnterManual()
estado.envioComFalha = true
-- Bloqueie antes de consultar a interface: mesmo uma falha nessa leitura
-- não pode autorizar a continuação após um Enter possivelmente recebido.
estado.token = estado.token + 1
estado.recuperavel = false
estado.tentativasRodada = math.min(config.maxTentativas, estado.tentativasRodada + 1)
aviso("Resposta incerta; parado")
local ok, texto = pcall(function()
local _, teclas = getParts()
return readSlots(teclas)
end)
if not ok then warn("Word System: falha ao conferir Enter manual:", texto); return end
if texto and texto ~= "" then
local salvo, erro = pcall(memorizarEnvio, texto)
if not salvo then warn("Word System: falha ao memorizar Enter manual:", erro) end
end
end
local function registrarEnterManual()
local ok, texto = pcall(function()
local _, teclas = getParts()
return readSlots(teclas)
end)
if ok and texto == "" then return end
-- Slots ausentes não provam que o campo estava vazio.
if ok and texto == nil then ok, texto = false, "slots indisponíveis" end
-- Mesmo se a interface falhar, o Enter pode ter chegado ao jogo.
estado.tentativasRodada = math.min(config.maxTentativas, estado.tentativasRodada + 1)
if not ok then
estado.envioComFalha = true
aviso("Resposta incerta; parado")
warn("Word System: falha ao conferir Enter manual:", texto)
return
end
local salvo, erro = pcall(memorizarEnvio, texto)
if not salvo then
estado.envioComFalha = true
aviso("Resposta incerta; parado")
warn("Word System: falha ao memorizar Enter manual:", erro)
return
end
if estado.tentativasRodada >= config.maxTentativas then aviso("Limite de tentativas atingido") end
end
resetBtn.MouseButton1Click:Connect(function()
if estado.ocupado then aviso("Aguarde a tentativa atual para resetar"); return end
liberarConferencia()
estado.token = estado.token + 1
estado.inglesRejeitadas = 0; estado.portuguesAteFim = false; estado.errosDificeis = 0; estado.finaisSuspensos = false; estado.tentativasRodada = 0; estado.recuperavel = false; estado.recuperacoes = 0; estado.candidatoRecuperacao = nil; estado.idiomaRecuperacao = nil
usedWords = {}
prefixosUsados = novosMapas()
index = 1
updateDisplay()
aviso("Memória apagada")
end)
-- Não enviar teclas ao chat, aos campos do painel ou a outra interface.
local function focoPermiteJogo(foco)
if not foco then return true end
if foco:IsDescendantOf(gui) then return false end
local alvo = findTargetGui()
local top = alvo and alvo:FindFirstChild("TopBar")
local resposta = top and top:FindFirstChild("AnswerInput")
return resposta ~= nil and (foco == resposta or foco:IsDescendantOf(resposta))
end

conexoesGlobais[#conexoesGlobais + 1] = UserInputService.InputBegan:Connect(function(input)
if not gui.Parent then return end
if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
if enterExtra and os.clock() - enterExtra < 0.3 then return end
-- O evento do Enter virtual pode chegar ao InputBegan com atraso.
if estado.ultimoEnterVirtual and os.clock() - estado.ultimoEnterVirtual < 0.3 then return end
local focoOk, foco = pcall(function() return focoPermiteJogo(UserInputService:GetFocusedTextBox()) end)
if not focoOk then
if estado.ocupado then interromperPorEnterManual()
else
estado.token = estado.token + 1
estado.tentativasRodada = math.min(config.maxTentativas, estado.tentativasRodada + 1)
estado.recuperavel = false
estado.envioComFalha = true
aviso("Resposta incerta; parado")
end
warn("Word System: falha ao conferir foco:", foco)
return
end
if not foco then return end
if estado.ocupado then interromperPorEnterManual(); return end
registrarEnterManual()
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
if not gui.Parent then return end
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
if estado.ocupado then interromperPorEnterManual(); return end
registrarEnterManual()
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
cancelarDownloads()
desconectarGlobais()
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
-- Lista compactada por prefixo comum, sem perder nenhuma palavra.
local function carregarFrequencias(idioma, dados)
local anterior=""
for n, final in dados:gmatch("(%d+)([a-z]+)") do
 anterior=anterior:sub(1,tonumber(n))..final
 frequenciaIndependente[idioma][anterior]=2
end
end
carregarFrequencias("EN", [==[0aaa2ron1bandon7ed2bey3ott2c2erdeen2ilities6y2le2oard3riginal4tion3ut3ve2raham3oad2s3ence5t3olute8ly4rb6ed3tract3urd2u3ndance7t3se5d4ive1cademic8s6y2cent4pt6able7nce6ed6ing6s4ss6ed6ible6ories3ident8al10ly8s3ommodate10ion5panied8y9ing6lish10ed4rd6ance6ing9ly4unt7ability9le7ed7ing7s3uracy6te8ly4sations5ed2e2hieve7d7ment11s6ing2id4s2knowledge11d2oustic2quire7d6ing5sition2re4s3oss2t3ed3ing4on6s4vated7ion5e6ly5ist8s6ties7y3or5s3ress3s3ual6ly2ute1dam4s3pt5ation5ed2d3ed3icted6ion4ng4tion8al10ly8s3ress7ed8s7ing3s2elaide3quate2jacent3ust6ed6ment10s2min5istered8ration12ve11or13s4ral5e4ssion4t5s5ted6ing2opt5ed5ing6on3rable2rian2s2ult5s2vance7d7ment7s6ing5tage9s3enture9s4rse5tisement8ing3ice4se6d6r5or7y3ocacy6te8s1erial2sthetic1ffair6s3ect6ed6ing7on6s3iliate9d3ord6able2ghan6istan2l2raid3ica6n7s2ter5math5noon5ward9s1gain5st2e3d3ncies5y4da4t5s3s2gregate5ssion8ve2ing2o2ree5d5ing5ment9s5s3icultural10e1head2h2med1id3s2m3ed3ing3s2r3craft3ed3line7s3plane4ort7s1ka1labama3n3rm3ska2bany3eit4rt6a3um5s2cohol7ic2ert3x4ander7ria2fred2gebra3orithm9s2i3ce3en5s3gned5ment3ke3ve2l3ah4n3egations5ed7ly4n4rgic4y3iance4ed5s4son3ocated4w5ance5ed5ing5s3y2most2one4g5side3t2pha2ready3ight2so2t3ar3er5ed5nate8ive11ly11s3hough3itude3ogether2uminum4ni2ways1manda3teur3zed4ing4on2bassador3er3ition7us3ulance2en4ded5ment9s3rica7n8s2id2munition2ong5st3unt6s2p2sterdam2y1na3l4yses6is6t7s5tics5ze7d3tomy2cestors3hor3ient2d3erson3re5a5w6s4oid3y2gel5a5es5s4r3le5s4o3ry2imal6s5ted6ion4e2kle2n3a3e3ie4versary3ounce8d8ment8s7ing4yed5ing3ual6ly2onymous3ther2swer6ed6ing6s2t3enna3hem4ony3i4cipated4que3onio2xiety4ous2y3body3more3one3thing4ime3way6s4here1part5ment9s2ollo4ogies7ze6y2p3aratus5ent8ly3eal6ed6ing6s5r6ance10s6ed6ing6s4tite3lause4e5s4icable7nts7tion11s5ed6s4y5ing3ointed7ment11s3reciate10d9ion4oach8ed9s8ing5priate5val6e7d5ximately3s2r3il1rab4ia5c2bitrary2c3h4bishop4er4itect9s9ural11e5ve7s3tic2e3a4s3na2gentina3uably4e5d5s4ing4ment8s2ise3zona2kansas2m3ed3ies3or3s4trong3y2nold2ound2range7d7ment11s4y3est6ed3ival5e6d6s5ing3ow5s2senal2t3hur3icle7s4ficial4llery4st6ic6s3s3work1sap2h3amed3es3ley2ia4n3de2k3ed3ing3s2leep2pect6s2s3assination4ult3embled7y4s5s6ed6ment10s4t5s3hole3igned6ment10s4st6ance8t6ed6ing6s3ociate9d9s8ion11s3ume6d6s5ing5ption10s4rance5e6d2ylum1te2hens3lete7s6ic8s2lanta6ic4s2m3osphere9ic2omic2tached6ment5k6ed6ing6s3empt7ed7ing7s4nd6ance6ed6ing5tion3itude8s3orney8s3ract7ed7ion10s8ve4ibute9d9s1uction2dience8s4o4t5ion2g3ust2nt2stin4ralia9n5ia7n2thentic4or6ities8y7zed6s3ism3o4mated7ic9ally8on5obile6tive4nomous7y3umn1vailability7le2e3ngers4ue3rage7d2iation2oid5ed5ing1wake3rd5ed5s4e5ness3y2e3some2ful2hile2kward1xe2is1ye0babe3ies3y2chelor3k4ed4ground10s4ing4pack4s4up4wards4yard3on3teria2d3ge3ly2g3s2il4ey3t2ke4d4r3ing2lance7d6ing3cony3d4win3l4et4oon5t4s3timore2n3ana3d4s3g4kok4ladesh3k4er6s4ing4ruptcy4s3ned5r4ing2ptist2r3ack3bara4er3celona3e4ly3gain3k3n4es3on3rel6s4ier7s4y3s2se4ball4d4ment4s3h3ic5ally5s4n4s3ket6ball3s3tard2t3ch3h4room3man3s3talion4eries6y4ing4le6field6s2y1bc1each5es3m3n4s3r4d4ing4s3st3t4en4ing4les4s3utiful9ly5y2came4use3ome6s5ing2d3room3s2e3f3n3r4s3s2fore2g3an3ging3in5ning5s3un2half4ve5ior8al8s7ur3ind2ijing3ng5s2lfast3gian5um3ief6s5ve7d7s6ing3l4e4s4y3ong6ed6ing6s4ved4w3t2n3ch3d3eath4ficial6t7s3jamin3nett3t2rkeley3lin3nard4ie3ry2side6s3t2t3a3h3s3ter4ing4y3ween2verly2yond1ias2ble4ical5ography2cycle2d3ding3en3s2g3ger5st2ke4s2ll4board4ion7s4s4y2n3ary3ding2o3graphy3logical6y2rd4s3mingham3th5day2shop6s2t3ch5es4oin3e4s3ing3s3ter2zarre1lack5s3de5s3h3ir3ke3me5d4ing3nk5et3st2eeding3nd3ss5ed5ing3w2ind3ss2ock5ed5ing5s3g4ger4s3nde3od5y4m3w4ing4n4s2ue4s3nt1mw1oard5ing5s3t4s2b3by2dies4ly3y2eing2il2ld3t2mb4er6s4ing4s2nd4s3e4s3us5es2o3bs3k4ed4ing4s3m3st3t4h4s2rder6s3e4d3ing4s3n3ough3row6ed2ss4es3ton2t3h4er6ed3tle6s4om2ught3nce4d5aries7y3t2w3l4ing2x3es3ing2y3cott3d3friend3s1ra3cket3d4ley4y3in5s3ke5s3nch6es4d5ed5on5s3ss3ve3zil6ian2each4d4k5down5fast5ing5s5through4st6s4th6e6ing3d3ed5ing4ze3tt3xit2ian3ck5s3de4ge6s3ef5ly3gade4ht6on3lliant3ng5ing5s3sbane4tol3tain4ish2o3ad5cast9ing5er5ly5way3ke5n5r3ncos4ze3oklyn5s3s3ther7hood7s3ught3wn5s4ser2uce3no3sh4sels3tal2yan5t1tw1ubble6s2ck4et4s2d3dha5ist4ies4y3get2ffalo4er2g3s2ild5er7s5ing8s5s4t2lgaria8n3k3l4et6in6s4s5hit4y5ing2mp2nch3dle3ny2rden3eau3ger3ial4ed3ke3n4ed4ing4s4t3st3ton3y2s3es3h3iness8es8man3t3y2t3ler3t4er6fly4on6s2y3er5s3ing3s2zz1ye0cab3in5et3le5s2esar2fe2ge2iro2ke4s2l3cium4ulate9d8ions3endar3gary3if5ornia3l4ed4ing4s3m3ories3vin2m3bridge3e4ra6s5on3p4aign8s4bell4ing4s4us2n3ada5ian8s4l3cel6ed6led5r3didate9s4le6s4y3nabis4on5t3on3s3t3vas3yon2p3abilities9y5le4city3e3ita6l7ism9t5ol3s3tain4ure7d2r3bon3d4iac5ff5nal4s3e4d4er6s4ful7ly4s3go3ibbean4ng3l4os3nival3ol5ina7e3penter5t3riage5ed6r7s6s4oll4y5ing3s4on3t4er4oon3ved2se4s4y3h3ino3t4ing4le3ual6ties2t3alog7ue3ch5es5ing3egories7y3hedral5rine4olic8s3s3tle2ught3se5d5s4ing3tion6us2valry3e1bs1ease5d2iling2lebrate9d8ing9on11s6ities8y3l4s4ular3tic2ment4tery2nsorship4us3t4er6ed6s4ral5e6s4s4uries6y2o2remony3tain7ly7ty4ificate10ion7ed1had3in5s4r5man5s3llenge9d9s8ing3mber7s4p5agne5ion8s9hip12s3n4ce6llor6s4ge6d6s5ing4nel7s3os3pel4man4ter7s3racter9istic14s10zed9s4ge6d6s5ing4itable6ies6y4les5ie5otte4m5ing4t5er5s3se4ing3t2eap5er4t5ed5ing3ck5ed5ing5s3ek5s4r5ing5s4se3f3lsea3mical8s5stry3n3rry3ss4t5er2i3cago4k5en7s5s3ef5s3ld5hood5ren4e4l3n4a4ese3p4s2ocolate3ice6s4r3ose6s5ing3pped3rus3se5n2ris5t6ian9ity9s7na8e6mas6opher3ome4nic2uck3rch6es6ill1ia2garette9s2ncinnati3ema2rcle6s4uit5lar7tion5mstances5s2tation3ed3ies4ng4zen7s8hip3y2vic4l5ian8s6zation1laim5ed5ing5s4re3n3ra4ify5ty4k5e3sh4s5es5ic7al7s6fication8ed5room3use3y2ean5ed6r5ing4r5ance5ed5ing5ly3rk3veland5r2ick5ing3ent6s3ff3mate4b5ed5ing3nic6al6s4ton3p4s2ock3se5d5ly5r5s6t5t4ing4ure3th5es5ing3ud5s3wn2ub4s3e4s3ster3tch1nn1oach5es5ing3l4ition3st5al3t2caine3k4tail3onut2d3e4s3ing2ffee4in2gnitive2hen2in4cidence4s2ke2l3d3e3in3laboration11ve5pse8d5r4eague9s5ct7ed7ing8on10s8ve10ly7or9s5ge7s4ins5sion3ombia4nel5ial6es5y4r5ado5ed5ful5s4ur6ed6s3umbia6us5n6s2m3bat4ination11s6e7d6ing4o3e4back4dian5y4s3fort7able3ic5s4ng3mand7er7ing7s4enced6t7ary7ed7ing7s5rce7ial10s4ission10ed11r10s5t6ment10s6ted8e9s7ing4odity5n6ly6s6wealth4unicate10ion13s7sm8t7ties8y3p4act5nies7on9s6y5rable6e7d6ing7son10s5ssion5tible4elling5nsate9ion5te7nt6ing7tion11s9ve8or10s4ilation6ed4lain8ed8ing8t9s5ete8d8ly7ing8on6x7ity5iance6cated9ions6ment5y4onent9s5sed7r6ite8ion5und8s4rehensive6ssion5ised8s7ing5omise10d4uter8s6ing2n3ceived5ntrate11d10ion5pt7s5rn7ed7ing7s6t7s4lude8d6sion10s4rete3demned4ition9ing9s4uct7ed7ing7or3e3ference10s5ss7ion4idence8t9ial5guration5ned5rm7ation7ed7s4lict8s4ront8ed4used6ing7on3grats7ulations5egation6ss8ional8man3junction3nect7ed7icut8ng8on10s7s3science6ous9ness4ecutive5nsus6t5quence11s9tly5rvation10ve12s4ider8able11y9tion8ed8ing8s5st7ed8ncy9t10ly7ing7s4ole6idated4piracy4table6nt8ly5itute9ion12al5raints6uct9ed9ion10ve4ult7ant8tion7ing5me7d7r8s6ing6ption3tact7ed7s5in7ed8r9s7ing7s4emporary5nt7s5st5xt4inent9al6ually7e8d8s7ing7ous10ly4ract8ed8or10s8s6ry6st5ibute10d9ing10on12s5ol7led9r8ing7s6versial10y3venience9t6tion10al10s5rsation12s7ion6t7ed5y4icted7ion5nce8d7ing2ok4ed4ie6s5ng3l4er4ing3per6ate8ion9ve3rdinate10d10s9ion9or2p3e3ied5s3per3s3y4right2ral3d3e3n4er6s3p4orate8ion11s4s3rect7ed7ion7ly5lation5spondence12t10ing4idor4upt7ion2s3mic3t4a4ly4s4ume7s2ttage4on2uch3gh3ld3ncil7s4sel7ing7or4t5ed6r5ies6ng5less5ries6y7side5s5y3p4le6d6s4on3rage4se6s4t5esy5s3sin6s2ver5age5ed5ing5s3id2w3boy6s3s2x1rack5ed5ing5s3ft3ig3ne3p3sh5ed6s5ing3wford3zy2eam4te6d6s5ing6on6ve7ity5or7s5ure8s3dibility5t6ed6s3ek4p5y3w4s2icket3ed4s3me5s4inal8s3sis3teria4ic6al8ly6ism7zed6s5que2op4s3ss5ed6s5ing3w4d5ed5s4n2ucial3de3el3ise3sh5ed5ing3z2y3ing3stal7s1uba4n3e3s2isine2lt4ural6e7s2m2nt2p3s2rb3e3iosity5us3rency6t7ly4iculum4y3se3tain4is3ve5d5s2stody5m6er8s6s2t3e3s3ting2z1yber2cle5s4ing2linder2rus1zech0dad3dy2ily3ry3sy2kota2le3las2m3age6d6s5ing3e3n4ed2n3a3ce5r6s5s4ing3ger6ous6s3iel4sh3ny2re3k4er4ness3ling3ren2sh2ta4base3e4d4s3ing2ughter8s2ve3id5son4es4s2wn2y3light3s1ead4line5y3f3l4er6s4ing4s4t3n3r3th5s2bate6s3ris3t4s3ut2c3ade6s4y3eased4mber4nt3ide6d6s5ing4sion8s6ve3k3laration6e7d6ing4ine7d6ing3orated7ion8ve3rease8d5e2dicated7ion2e3ds3med3p4er4ly3r2f3ault3eat6ed4nce5d6ant9s6ed7r8s6ing5se6ive3icit4ne6d6s5ing6te8ly7ion10s8ve2gree6s2l3aware4y5ed5s3egates7ion4te6d3hi3iberate10ly4cate5ious4ght7ed4ver7ed7ing7s7y3ta2m3and6ed6ing6s3o4cracy7t8ic8s4graphic4n5s6trate11d11s10ion13s3s2n3ial4ed3mark3nis3se4ity3tal4ist3ver3y4ing2parted6ment10s6ure3end6ent6ing6s3loyed6ment3osit7s4t3ressed7ing8on3th5s3uty2r3by3ek3ived2s3cent4ribe8d8s7ing6ption11s3ert5ve7d7s3ign6ated6ed7r8s6ing6s4rable5e6d6s3k4top3pair4erate9ly4ite3sert3tination11s6ed6y4roy7ed7ing5uction9ve2tached4il6ed6s5ned3ect6ed6ion7ve4ntion4rmination8e9d8ing3roit2vastating3elop7ed8r9s7ing7ment11al11s7s3ice6s4l5s3on4ted1iabetes3gnosed7is7tic4ram3l4ogue3meter4ond7s3na4e3ry2ck3tionary2d3nt2e3d3go3s4el3t2ffer6ence10s8t9ial9ly4icult9ies9y2g3ging3ital3nity2mension9al9s2ning3ner2oxide2p3lomatic2rect6ed6ing7on9s6ly6or8s8y3t4y2sabilities9y5led4gree4ppear9ed6ointed10ing10ment4ster3c4harge4ipline4lose8d7ure4o5unt8s6rse5ver8ed8ing8y4retion5imination4uss7ed8s7ing8on10s3ease7s3gusting3h4es3k3like3miss7ed3ney3order8s3placed6y7ed7s4osal4ute7s3solved3tance8s6t4inct8ion9ve6guish11ed4racted8ion5ess5ibute10d9ion6ct8s4urbed7ing2tch2ve4rse6ity3ide6d6nd4ne5g4sion8s3orce7d2y1na1oc3k3tor6s4rine3ument8ary9tion8ed8s2dge5rs2e3s4nt2g3s2in4g2ll4ar6s4s3phins2m3ain3e4stic3inance7t6te8d2n3ald4te6d5ion8s3e3g3na3or5s3t2om3r4s2pe2rothy2se4s2t2uble6d6s4t5s3g4h4las2wn4load8ed4s4town2zen5s1raft5ed3g4ged5ing4on6s3in3ke3ma5tic8ally3nk3w4er4ing7s4n4s2eam5ing5s3ss5ed6s5ing3w2ied3ft3ll5ing3nk5ing5s3ve5n5r6s5s4ing2one5s3p4ped5ing4s3ught3ve2ug4s3m4s3nk2y1ual2bai3bed3lin2ck4s2de4s2e2g2ke2ll2mb3p4ed2ncan2o2ration3ham3ing2st2tch3ies3y1vd1ye2ing2lan2namic7s4sty0each2ger3le5s2r3l4ier6st4y3n4ed4ing7s3s3th5quake2se3ier5st4ly3t4er6n3y2t3en3ing3s1bay1cho2lipse2ological3nomic8ally8s7es7st6y3system1ddie2en2gar3e4s2inburgh3t4ed4ing5on7s4or6ial6s2ucate7d6ion9al6ors2ward6s1ffect6ive9ly9ness6s3iciency8t9ly3ort6s1gg3s2o2ypt5ian1ight5een5h2ther1laborate2bow2der5ly2eanor3ct5ed5ion8s5oral5ric8al8ity6on8ic10s3gant3ment7ary7s3phant8s3vated6ion6or4en2igible3minate9d8ing9on3te3zabeth2len3iott4s2se4where2vis1mail5s2barrassed9ing4ssy3edded3race2erge6d6ncy5ing2ily3ssions2ma2otion7al9ly7s2peror3hasis3ire3loy6ed7e8s7r8s6ment3ty1nable6d6s5ing2counter9ed9s5rage9d9ment9s8ing2d3angered3ed3ing3less3orsed3s3ure2emies4y3rgy2force7d7ment2gage6d6ment5ing3ine6er8ing8s6s3land4ish2hance7d2joy5able5ed5ing5ment5s2ormous3ugh2rolled6ment2sure5ing2ter5ed5ing5prise10s5s5tain9ing9ment3husiasm9tic3ire6ly4ties5led5y3rance4epreneur12s4ies4y2velope3ironment11al11s3y2zyme1pa2ic3demic3sode7s1qual5ity5ly4tion3ipment5ped4ty4valent1ra2ected2ic2ror5s1scape6d3ort2pecially3n2say5s3ence5tial9ly4x2t3ablish9ed9ing9ment13s4te6s3eem3imate8d8s1tc2ernal5ity2hical5s3nic1ugene2ro4pe6an8s4s1va3luate8d7ion3n4s2e3n4ing4t5s5ually3r4y5body5day5one5thing5where2idence6t3l2olution9ary4ve6d1xact5ly3m4ination6e7d6ing4ple7s4s2ceed4llence8t4pt6ion9al9s4ss6ive3hange8s3ited6ment5ing3lude7d6ing5sive9ly3use6s2ecute7d6ion7ve9s3mpt3rcise8s2haust7ed3ibit7ed7ion7s2ile3st5ed6nce5ing5s3t2otic2pand6ed6ing5sion3ect6ation11s6ed6ing6s4dition4nse7s6ive4rience10d10s9ing6ment10al10s5t6ise6s3ired3lain7ed7ing7s5nation4icit8ly4ode5it7ation5ration6e7d7r6ing5sion7ve9s3ort6s4se6d5ing5ure3ress7ed7ing8on10s2tend6ed6ing6s5sion9s7ve9ly5t4rior5nal3ra5ct7ion5ordinary4eme7ly1ye3d3s0fabric3ulous2ce4book4d4s3ial4litate7ies7y4ng3t4ion4or6ies6s6y4s3ulty2de2il4ed4ing4s4ure7s3nt3r4ly4y3th5ful2ke2ll4en4ing4s3se2me3iliar6es5y3ous2n3cy3s3tastic6y2r3e4well3m4er6s4ing4s3ther2scinating5st3hion7ed3t4er5st2t3al3e3her6s3igue3ty2ult2vor5able5ite8s4ur6ite1bi1da1ear4ed4s3st3t4hers4ure7d7s6ing2b3ruary2d3eral6tion2e3d4back4ing4s3l4ing7s4s3s3t2lix3l4ow6s7hip3t2male6s3inine6sm7t2nce2rguson3rari4y3tility2stival8s2ver2w3er1iber2ction7al2eld5s3rce2fa3teen4h4y2g3ht5er7s5ing5s3ure6d6s2le4d4s3ing3l4ed4ing3m4ed4ing4s3ter6s4hy2nal5e5ly5s4nce7s6ial9ly7ng3d4ing7s4s3e4s5t3ger6s3ish6ed7s6ing3land3n2re4arms4d4s4works3ing3m4ly4s3st2scal3h4er4ing3t2t3ness3s3ted4ing2ve2x3ed3ing3tures1lag4s3me5s3sh3t3vor3ws2ed3e4t3sh3tcher3w3xibility6le2ies3ght6s3p2oat5ing3od5ed5ing5s4r5s3rence4ida3ur3w4er6s4ing4n4s3yd2u3id3sh2y3ing3nn1oam2cus5ed6s5ing2g2ld4ed3k4s3low6ed7rs6ing6s2nd3t2od4s3l4ish4s3t4age4ball2r3bes4idden3ce5d5s4ing3d3ecast4head4ign7ers4most4st6s4ver3ge5t6ting4ive7ness4ot6ten3k3m4al6ly5t6ion4ed5r6ly4ing4s4ula3t4h4unate9ly6e4y3um5s3ward7s2ssil3ter2ught3l3nd5ation10s5ed6r7s5ing4tain3r4teen5h2x1raction3gile4ments3me5d5s5work3nce5hise5is7co4k5lin6y3ser3ud2eak5ing3d4erick3e4d5om4ly4man4style4ze5ing3ight3nch3quency7t8ly3sh5man2iday4ge3ed4nd6ly6s7hip4s3nge2og3m3nt5ier3st3zen2uit5s3strated8ing9on2y1uck4ed4in6g4s2el4s2lfill3l4er4y2n3ction8al8ing8s3d4amental4ed4ing4raising4s3eral3ny2r3ious3niture3ther7more3y2sion2ture6s0gabriel2in4ed4ing4s2l3axy3leries6y2mble5ing3e4play4s3ing2ndhi3g2p3s2rage3bage3cia3den6s3lic3y2s3oline2te4s4way3her6ed6ing2uge2ve2y2za1dp1ear2l2m2n3der3e4ral7ly6te8d7ing8on10s7or5ic5ous4s5is4tic7s4va3ius3ocide3re3tle6man7en5y3uine7ly2ographic10al8y3logical3metry3rge5ia2rman6s6y2sture2t3s3ting1hana2ost5s1iant5s2bson2f3t4ed4s2g2lbert2nger2rl4friend4s2ve4n4s3ing1lad3nce3sgow4s5es2en4n2impse2obal6ly4e3rious4y3ves3w2ue1oal4keeper4s3t2d3damn4ess3s2es2in4g2ld4en3f2ne3na2od4bye4ness4s3gle3se2p2rdon3geous2sh3pel3sip2t3ta4en2v3ernance6ed6ing6ment10al10s6or8s1ps1rab4bed3ce3de5s4ually6te8d8s7ion3ham3in3mmar4s3nd5children5e5father5ma6other5pa7rents5son4ite4t5ed5s3ph5ic7s3sp4s3teful4itude3ve5s4ity3y2eat5er6st5ly3ece4k4n5house5s3g4ory3w3y2id3ef3ffin3ll3nd5ing3p2ocery3ss3und6ed6s4p5s3ve3w4ing4n4s4th1uarantee9d9s4d5ian8s5s2ess5ing4t5s2idance4e5d5lines5s3ld4t5y3nea3tar2lf2m2n3s2ru2t2y3s1ym0habit5at5s2ck4ed4ing2d2ha4ha2il3r4y2lf4way3l4oween4s3t2m3ilton3mer3pshire2n3d4book4ed4ful4le6d6s5ing4s5ome4y3g4ing3nah3s2ppen6ed6ing6s4ier5ly5ness4y2rassment3bor5ur3d4core4er5st4ly4ware4y3m4ful4less4ony3old3per3ris6on4y3sh3t3vard4est5y2s2t3ch3e4d4s3ing3red3s2ul3nted2ve4n3ing2waii3k4s2y3es2zard1ead4ache4ed5r4ing4line8s4phones4quarters4s3l4ing4th6care6ier6y3r4d4ing7s4s4t5s3t4ed4her4ing3ven4ier5ly4y2brew2ck2el4s2ight6s3r2ld3en3icopter3l4o3met3p4ed4ful4ing4s2nce3derson3ry2r3ald3bert3e3itage3o4es4ic5n3s4elf2s3itate2y1id3den3e3ing2erarchy2gh4er5st4light9ed9s5y4way7s2ke3ing2larious3l4ary4s2m3self2ndi4u3t4s2p3s2re4d3ing2s3panic3torian9s7c8al10ly6y2t3ler3s3ting2v1mm1obby2ckey2ld4er6s4ing7s4s3e4s3iday7s3land4ow4y5wood3mes3ocaust3y2me4land5ess4made4r4s4town4work3icide2n3da3est6ly6y4y3g3or5able5ed5s4ur2od3k4ed2p3e4d4ful7ly4s3ing3kins2rizon7tal3mone3n4s4y3rible4or3se5s2spital8ity8s3t4age4ed4ile5ng4s2t3el5s3test2ur4s3se5hold9s5s4ing4ton2w3ard3ever1ttp4s1ub2dson2g3e3h4es2h2ll2man5itarian7y5s3ble3idity3or4ur2ndred7s3g4arian6y4er4ry3t4er6s4ing2rricane4y3t4ing4s2sband2t1ybrid2drogen2giene2pe3othesis0ian1bm1ce3land2on4ic1daho2ea4l5s4s3ntical6fication8ed7y8ing6ties7y3ology2iot5s2k2ol1gnorance7t5e6d5ing1ii1ll3egal7ly3inois3ness3usion5trated9ion12s1mage5ry5s4inary7tion6e7d6g2mediate9ly4nse3igrant9s7tion3une5ity2pact6s3erial3lement9ation9ed9ing4ications5ed6s4y3ort6ance8t9ly6ed6s4se6d5sible3ress7ed7ion8ve4isoned8ment4ove7d7ment11s6ing1nability3dequate3ppropriate2c3entive9s3h4es3ident8s3lined4ude7d7s6ing5sion7ve3ome5ing5plete4nsistent4rporate11d5rect3rease8d8s7ing10ly5dible9y2deed4pendence10t11ly4x3ia5n6a7polis6s4cate8d8s7ing8on7or9s4e4genous4rect4vidual10ly10s3onesia9n4or3uced4strial8es7y2equality3vitable9y2fant6ry3ected6ion9s8us4rior3inite7y3lation4uence9d9s7tial3o4rm6al7tion6ed3rastructure2g3redients2habitants3erent5itance7ed2itial7ly6ted7ive10s2jection3ured5ies5y4stice2k2land2mates2n3er3ing6s3ocence7t4vation8ve2put2quiries6y2s3ane3ects4rt3ide4ght7s4st6ed3pection7or4iration6e7d6ing3tagram5ll7ation12s7ed5nce8s6t7ly4ead4inct5tute8ion11al11s4ructed8ion11s8or6ment10al10s3ulin5t4rance2t3act4ke3egral7ted8ion6ity4l5lectual6igence10t4nd6ed5se6ity7ve5t6ion9ally9s4r5act8ion11s9ve5est8ed8ing8s5face6ere9nce5im6or5mediate5nal7tional13ly6et5pret9ation9ed5rupted5section6tate5vention6iew9ed9s3imate3o3ro5duce9d9s8ing8tion2valid4sion3ented6ion6ory4st6ed6igate11d10ing11on13s10or12s7ng6ment10s6or8s3isible4tation5e6d5ing3olve7d7ment7s6ing1on2s2wa1pad2hone1ra3n4ian3q4i2eland2ish2on4ic4y2relevant2s1saac2is2lam5ic4nd6s3e2nt2o3lated6ion2rael6i2sue5d5s1talian4y2em4s2s3elf2unes1van2e2ory2y0jack4et6s4ie4son3ob2de2il2ke2m3aica3es3ie2n3e4t3uary2pan5ese2r3ed2son2va2w2y2zz1ealous3n4s2ff4erson4rey2nkins3nifer4y2remy3k3ry3sey3usalem2sse4ica3us2t3s2w3elry3ish3s1ill2m3my2n1oan2b3s2e3l3y2hn4ny4s5on5ton2in4ed4ing4s4t5ly5s2ke4s3ing2n3athan3es2rdan2se4ph3h4ua2urnal7ism9t10s7s5ey2y3ce1uan2dge5d5ment5s4ing4ment3icial7ry3y2ice2lia5n4e3y2mp4ed4ing4s2n3ction3e3g4le3ior3k2risdiction3y2st4ice5fication7ed6y5n2venile0kane3sas2ren3l3ma2te3herine3ie2y1een3p4er4ing4s2ith2lly2n3nedy5th4y3t4ucky3ya2pt2rry2vin2y3board3s1han1ick4ed4ing4s2d3ding3napped4ey3s2ll4ed5r6s4ing4s3ometers2m2nd4a4ergarten4le5y4ness4s3g4dom4s2rk2ss4ed4ing2t3chen3s3ty1nee4s3w2ife3ght6s3ves2ock5ed5ing3w4ing4ledge4n4s1ong2rea5n1urt1yle0lab3el5ed5s3or5atory4ur3s2ce3k4ed4ing4s2d3der3ies3s3y2id2ke4rs4s2mb3e3p2ncaster4e3d4ed4ing4lord4mark4s5cape3e4s3g4uage8s3ka2p3top2rge5ly5r5st3ry2s3er3t4ed4ing4s2te4ly4r4st3in5o3ter2ugh5ed5ing5s5ter3nch6ed7s6ing4dry3ra4en2w3n3rence3s4uit3yer6s2y3er5s3ing3out2zy1bs1ead4er6s7hip4ing4s3f3gue6s3k4ed4s3n4ing3p3rn5ed5ing5t3se4t3ther3ve5s4ing2banon3ron2cture7s2d2e3ds2ft2g3acy4l5ly3end6ary6s3ion4slation9ve8ure4t5imate3o3s2icester3sure2mon2nd4ing3gth6s6y3s2o3n4ard2s3bian3lie3s4er4on6s2t3hal3s3ter6s4ing2vel5s4rage3y2wis1gbt1iability4le3m3r2beral7s6tion5ty3raries6y3ya2cence5se7d7s6ing2d2e3d3s3utenant2fe4style4time3t4ed4ing2ght5er5ing5ly5ning5s5weight2ke4d4lihood5y4s4wise3ing2l3y2me3it5ations5ed5ing5s2n3coln3da4say3e4ar4d4s4up3ing3k4ed4ing4s3ux2on4s2p3s2quid4or2sa3t4ed5n6ed6ing4ing7s4s2t3eracy6lly6ry6ture3igation3tle2ve4d4ly4r5pool4s5tock3ing2z1lc2oyd1mao1oad4ed4ing4s3n4s2bby2cal5ly5s4te6d5ion8s3k4ed5r4s2dge2g3an3ic5al4stics3o3s2l2ndon3e4ly3g4er5st2ok4ed4ing4s3p3se2pez2rd4s2s3e4r5s4s3ing3s4es3t2t3s3tery2u3d4er4ly3is5e5iana5ville3nge2ve4d4ly4r5s4s3ing2w3er5ed5ing4st2yal5ty1td1ucas3k4ily4y3y2ggage2is2ke2nch3g4s2ther2xury1ying2nch3n2on2rics0mac3hine7ry7s2d3ame3e3ison3ness3rid2fia2gazine8s3gie3ic5al3netic4ificent5tude2id4en3l3n4e4land5y4stream4tain8ed8ing8s5enance2jesty3or5ity2ke4r5s4s4up3ing2laysia8n3colm3e4s3l2ma2n3age6d6ment6r7s6s5ing3chester3date6ory3ga3hattan3ila4pulation3kind3ner6s4ing3or3sion3ual4el4facture11d11r12s10ing4script3y2p3le3ping3s2r3athon3ble3c4h5ing4o4us3garet4in6s3ia4e4juana4na5e6s4o5n4time3k4ed5r5t6ing6place6s4ing4s3riage8s5ed4y3s4h5al7l3tha4ial5n3vel3y4land2sk4s3on3s4achusetts6re5ge4es4ive3ter6piece6s2t3ch5ed6s5ing3e4rial8s4s3h4ematical10s3rix3t4er6s4hew3ure5ity2x3imum2y3a3be3or1eal4s3n4ing7ful4s4t5ime4while3sure7d7ment11s7s6ing3t2chanic8al8s7sm9s2d3al5s3ia5n4cal6re6tion5ine4eval4tation5erranean4um2et4ing7s4s2ga4n2l3bourne3issa3ody3t4ed4ing2mber6s7hip4rane3e3o4rable5ial6es5y3phis2n3tal6ly4ion7ed7s4or3u2rcedes4handise7t8s4ury4y3e4ly3ger3it3ry2ss4age7s6ing4ed5nger4ing4y2t3abolism4l5lic5s3er5s3hod6ology6s3res4ic4o5politan2xican5o1ia3mi2c3e3hael4elle4igan3k4ey3ro5soft5wave2d3dle3fielder3night3st3west2ght5y3rants5tion2ke2lan3d3e4s3itary5ia3k3l4er4ion7s4s3ton3waukee2n3d4ed4s5et3e4ral7s5s4s3i4mal5ize5um4ng4ster8s6ry3neapolis5sota3or5ities7y3s3t3us4te6s2racle4nda3ror6s2serable5y3leading3s4ed5s4ile7s5ng5on7ary7s5ssippi4ouri3take7n7s4ress2tch5ell2x3ed3ing3ture1lb2s1ob3ile5ity2ck2d3e4l5ing5s4rate5n4s5t3i4fications6ed5y3ule2isture2lecular7es3ly2m3ent6s6um3my3s2n3day3etary4y3ica4tor7ing7s3k4ey6s3opoly3roe3ster7s3tana4gomery4h5ly5s4real3ument2od3n3re2ral5ity3e4over3gan3ning3occo3ris6on3tal6ity4gage2scow3es3que3s3t4ly2ther6s3ion4vated7ion5e3or5cycle5s2unt5ain8s5ed5ing3se3th2ve4d4ment8s4s3ie5s4ng1ph2s1rs1tv1uch2d2hammad2lti5ple2m3bai2nich5ipal2rder6ed7r6s3phy3ray2scle6s3eum6s3ic5al5ian8s3lim6s3t2tual1vp1yanmar2self3terious6y2th0nah2il4s2ked2me4d4ly4s3ing2ncy2p2rrative6or4ow2sa3h4ville3ty2talie3e3han3ion6al8ism10t8ly8s6s6wide4ve3o3ural7ly5e2ughty2val3igation3y2zi4s1ba2c1caa1ear4by4est4ly3t2braska2cessarily8y6ity3k4lace2ed4ed4ing4le4s2gative3lect7ed3otiate9d8ing9on11s2ighbor8hood12s8ing8s7urhood9s3l3ther2lson2o2pal3hew2rve5s4ous2st2t3flix3herlands3s3work7ing7s2utral2vada3er5theless2w3born3castle3er4st3ly3man3port3s4paper9s3ton2xt1fl1hl2s1ice4ly3he4olas3k4el4name3ole2ece2geria7n3ht5mare5s2ke2na3e3ja3tendo4h2xon1oah2bel3le3ody2de4s2ise2minated7ion10s5ee2n3e4theless3profit3sense2on2pe2r3folk3m4al6ly5n3th5east6rn5west9ern3way4egian2se2t3able6y3ch3e4d4s3hing3ice6d6s4fication6ed4ng4on3orious2v3a3el5s4mber2w3adays3here1sa2w1uclear2de2mber6ed6s3erous2rse5ry5s4ing2t3rition3s1yc0oak3land2th1bama5care2esity3y2ject6ive9s6s2ligation10s2scure3ervation11s6e7d7r4ssed6ion3tacles2tain6ed6ing2vious7ly1ccasion8al10ly8s3upation5ied5y4r5red6ing5s2ean2t3ober1dd3s1ff3ence5ded7rs5se6ive4r5ed5ing8s5s3ice6r7s6s5ial8ly8s3set4hore2ten1hio1il3s1kay2lahoma1ld3er4st3s2ive5r4ia2ympic7s1mega2g1nce2e3s2going2ion5s2line3y2tario3o1pen4ed5r4ing4ly4s3ra5te7d7s6ing7on9al9s7ve6or8s2inion7s2ponent8s4rtunities10y4se6d5ing6te7ion3ression2s2t3ical4mal5istic4on6al6s1ral3nge2bit2chestra2der5ed5ing5s3inary2e3gon2gan5ic6sation12s7ed7ms6zation12al12s7e8d7ing5s2ientation6ed3gin6al8ly7ted6s2lando3eans2thodox1scar1ther5s5wise2tawa1ught2nce2r3s4elves2t3break3come7s3door3er3fit6s3let6s4ine7d4ook3put3rage4ight3s4ide4tanding3ta1val2en3r4all4come4head4looked5y4night4seas5ight4time4view4whelmed9ing1we3d3n2l2n3ed4r5s6hip3ing3s1xford2ygen0pablo2c3e3ific3k4age7s6ing4ed5rs4ing4s2d2ge4s2id3n4ful4s4t5ed6r5ing8s3r4ed4s2kistan8i2l3ace3e4stine8ian3m4er2n3ama3el5s3ic3thers4s2pa3er5s5work2r3a4de5ise4graph4llel4meters3don3ent6al6ing6s3is5h3k4ed5r4ing4s3liament10ary3ody4le3t4ial7ly5cipant11s9te11d10ing11on6le8s6ular10ly5es5san4ly4ner7s8hip11s4s4y2ss4age4ed5nger9s5s4ing5on7ate5ve4port4word3t4a4e4or2t3ch5es3ent3h4etic4s3ience6t7s3rick5otic7s4ol3tern7s2ul3se2y3ing3ment7s3s1df1eace5ful3k4s3nut3rl2e3l3r4s2n3alties6y3cil3ding3guin3insula4s3n4sylvania4y3sion7s2ople6s2pper2r3ceived5nt7age5ption3fect7ion7ly4orm7ance11s7ed8r9s7ing7s3haps3iod6s3manent9ly4ission5t6s6ted3ry3sian5stent4on6al8ities10y8ly6nel6s4pective11s4uade3th3u2t3e4r5son3ition3roleum3s3ty1hantom3rmaceutical7y3se5s2d2enomenon2il4adelphia4ip6pines4lip7s4osophical9y2oenix3ne5s3to5graph10er12s10s10y5s6hop2rase6s2ysical8ly6ian9s6s1iano2c3k4ed4ing4s4up3nic3s3ture7d7s2e3ce5s3r4ce4re2g3s2le3l4ow4s3ot5s2n3e3k3s2oneer2pe4line4s2rate6s2ss4ed3tol2t3ch5ed6r3t4sburgh3y2zza1lace5d5ment5s4ing3gue3in5s3n4e5s5t6s4ned5ing4s4t5ed5ing5s3sma4tic3te5s4form8s4inum3y4ed5r6s4ground4ing4off7s4s5tation3za2ea4sant5e6d5ure3dge3nty2ot2ug3s1ocket6s2dcast2em4s3t4ry4s2int5ed5ing5less5s3son6ing2kemon4r2land4r3e4s3ice5ies5y4sh4te5ical9ly7ian10s7s3l4ing4s4ution2nd3y2ol4s3r4ly2p3e3ped4ing3s3ular7ity6ted7ion10s2rch3k3n3t4able5l4er4folio4ion7s4land4rait8s6yed4s4ugal6uese2se4d4s3ition8ed8s6ve8ly3sess7ed7ion10s4ibilities10y6le7y3t4al4ed5r6s4ing4s2t3ato6es3ential9ly3ter2und5s3r4ed4ing2verty2wder3ell4r5ed5ful5s1ractical9ly7e8d8s7ing6tioners3ise6d3y4er6s4ing2e3cedent4ious5se7ly6ion3decessor4ict7ed7ion10s4ominantly3fer6ence10s6red3gnancy7t3judice3liminary3mier7e5se7s5um3p4aration11s6e7d6ing3scribed7ption4ence6t7ation7ed7ing7s5rvation7e8d4idency8t9ial9s4s5ed5ing5ure8s4tigious5on4umably3tend7ing4ty3valent4ent7ed7ing8on7s4iew5ous8ly3y2ice5d5s4ing3de3est6s3marily6y4e4itive3nce6ss6ton5ipal7le9s4t5ed6r5ing5s3or5ities7y3son6er8s6s3vacy5te7ly4ilege9d3ze5s2o3bability6le7y5tion4e4lem7atic7s3cedure9s5ed7ed7ings7s5ss7ed8s7ing7or3duce7d7r8s7s6ing6t7ion10s8ve9ity7s3f4ession10al12s7or9s4ile7s5t6able6s4ound3gram7me9s8ing7s5ess8ion9ve3hibited3ject7ed7ion7s3longed3m4inent5se7d7s6ing4o5te7d7s6ing7on9al9s4pt6ed6ly3ne4ounced3of3paganda4er6ly6ties7y4het4ortion5sal8s6e7d6ition3s4ecution8or4pect8ive8s6rity3tect7ed7ing8on8ve5in7s5st7ant7ers7s4ocol5type3ud3ve5d5n5s4ide7d7nce7r8s7s6ing5nce8s7ial6g5sion9s3ximity1sychiatric6c5ological10st9y1ub3lic6ation11s6ity6ly5sh7ed8r9s7ing2erto2ll4ed4ing4s3se2mp4ed4ing4kin4s2nch5ed3ish6ed6ment3k2pil5s3pet4y2rchase8d8s7ing3e4ly3ple4ose7s3se4ue6d5ing6t2sh4ed4ing3sy2t3in3s3ting2zzle1ython0qatar1ualification13s7ed6y7ing5ties6y3ntities7y5um3rter7back7ly7s2e3bec3en5s6land3st5ion8able8ed8ing8s3ue2ick5er5ly3et5ly3nn3t4e3z2o3te5d5s0rabbit2ce4s3hel3ial4ng4sm5t3k2dar3iation4cal4o4us2ge2id4ers4s3l4road4s4way7s3n4bow4fall4s3se5d5s4ing2lly3ph2m3p2n3ch3d4om6ly4y3ge5r6s5s4ing3k4ed4ing7s4s2p3e4d3id5ly3per2re4ly2t3e4d4s3her3ing6s4o5nal3s2ven2w2y3mond3s1each5ed6s5ing4t5ion8s5or3d4er6s4ily5ng7s4s4y3gan3l4ise7d6tic5ty5ze7d6ing4ly4m3r3son6able9y6ing6s2becca4l5lion5s3uild2call6ed3eipt5ve7d7r7s6ing4nt6ly4ption6or4ssion3ipe6s5ient9s3kless3ognise9d7tion7ze9d4mmend9ation14s9ed4nstruction4rd6ed6ing9s6s4ver7ed7ing7y3reation10al4uit7ed7ing7ment2d3emption3s3uce6d6s5ing5tion2ed3f2f3er5ee6nce9s7dum5red6ing5s3ined3lect7ed7ing8on7s3orm6s3reshing3uge6e7s4nd4sal5e6d6s5ing2gard6ed6ing6less6s3ime6nt4on6al6s4ster8ed6ration3ret6s3ular7ly6te8d7ion10s7ory2hab5ilitation2id3gn3nforced2ject6ed6ion2late6d6s5ing6on8s9hip12s6ve8ly8s4x5ed5ing4y3ease7d7s6ing4vant3iability6le5nce4ed5f5s5ved4gion8s7us3uctant3y4ing2main6der6ed6ing6s4ke4rkable6s3edies5y4mber8ed8ing8s3ind6ed7r6s4x3ote4val5e6d5ing2naissance3der6ed6ing3ewable6l5ed3owned3t4al4ed2p3air6s3eal5t6ed8ly6ing3lace7d7ment6ing5y4ied6s4y3ort6ed8ly7r8s6ing6s3resent9ation12ve14s9ed9ing9s4oduction10ve3ublic8an10s4tation2quest7ed7ing7s4ire7d7ment11s7s6ing2s3cue6d3earch8er10s4rvation11s6e7d7s6oir4t3idence7t8ial8s4gn6ation6ed4st6ance8t3olution5ve7d4rt4urce8s3pect7ed7ive10ly7s4iratory4ond7ed8nts7ing7s6se8s7ibilities13y9le3t4aurant10s4ing4oration6e7d4rict8ed8ions3ult6ed6ing6s4me2tail6ers5n6ed6ing3ention3ire6d6ment5ing3reat4ieved3urn6ed6ing6s2union3ters2v3eal6ed6ing6s4lation4nge5ue7s4rse7d3iew6ed6ing6s4sed5ion4val3olution10ary2ward6ed6s2x2y3nolds1hetoric2ode2ythm1ibbon3s2ce3h4ard7s8on4mond3k4y3o2d3e4r5s4s3ge3iculous4ng2fle5s2g3ht5eous5s2ley2m2ng4s2o3t4s2p3ped2se4n4s3ing3k4s4y2tual2val5ry5s3er5s1oad4s3st2b3bed5ry4ie3ert6s7on3in5son3ot5s3ust2chester3k4et6s4s4y2d3e3gers2ger5s3ue2le4s3l4ed5r4ing4s2man5ce5ia5s5tic3e2n3ald2of3kie3m4mate4s3sevelt3t4ed4s2pe2sa3e4s3s3ter2tation3ten2ugh5ly3nd5ed5s3te5s4ine2w3s2y3al5ty1ub3ber4ish3y2de2gby2in4ed4s2le4d4r4s3ing2mors2n3ner6s4ing3s3way2ral2sh4ed4ing3sell4ia6n7s2th1yan0sack3ramento4ed4ifice2d3ly3ness2fe4ly4r4ty2ga3e2id3l4ing4or3nt5s2ke2lad4ries5y3e4s3ly3mon3on3t3vation2m3e3ple6s3sung3uel2n3ctions5uary3d4ers4ra4s4wich4y3g3ta2ra4h2t3an3ellite3isfaction6ied6y7ing3urday2uce3di3sage2vage3e4d4s3ing6s2w2y3ing3s1cale5s3m3n4dal3re5d4y3ttered2enario8s4e5s4t2hedule8d8s4me6s3olar7s8hip4ol6s2i3ence7s5tific7st9s2ope3re5d5s4ing3tland4t5ish3ut2rap4tch3eam6ing6s4en6ing6s4w5ed3ipt3oll2ulpture1ea3l4ed4s3n3rch6ed7s6ing3s4on6al6s3t4ed4s4tle2bastian2c3ond6ary6ly6s3ret6ary6ly6s3tion7s4or6s3ular4re6d5ing6ties7y2e3d4s3ing3k4ing4s3m4ed4ingly4s3n3s2gment7s2ize5d2lect6ed6ing7on7ve3f4ish3l4er6s4ing4s2mester3i2n3ate5or7s3d4ing4s3ior6s3sation4e5s4ible5tive8ity4or6s3t4ence8d8s4iment2o3ul2p3arate8d8ly7ion3t4ember2quel5nce8s2rgeant3ial4es4ous7ly3vant7s4e5d5r6s5s4ice7s5ng2ssion7s2t3h3s3ting7s4le6d6ment10s5ing3up2ven5teen6h6y4ral5e6ly2x3ual6ity6ly3y1hade5s4ow6s3ft3h3ke5speare4ing3ll5ow3me3ne4ghai3pe5d5s3re5d5holders5s4ing4k5s4on4p5ly3ve3w4n2e3d3ep4r4t5s3ffield3lf4l5s4ter3pherd3riff4man2ield6s3ft5ed5ing5s3ne4ing4y3p4ped5ing4s3rt5s3t4ty2ock5ed5ing3e4s3ok4t5er5ing5s3p4ping4s3re4t5age5er5ly5s3t4gun4s3uld6er8s4t5ed5ing3w4case4ed5r6s4ing4n4s2rimp2ut4tle2y1iblings2ck4ness2de4d4s2ege3rra2gh4t5s3n4al6s5ture4ed4ificance10t11ly5ng4s2lence5t3icon3k3ly3ver2m3ilar7ities7ly3mons3on3ple6r5y4son3s3ulation5taneously2n3ce5re7ly3g4apore4er6s4h4ing4le6s4s3k4ing3s2r2ster6s2t3e4s3s3ting3uated6ion9s2x3teen4h4y2ze4d4s1kating2eleton3tch2i3es3ing3ll5ed5s3n4ny4s3p3rt2ull2y1lam3p3te3ughter3ve5ry5s2eep5ing4ve3pt2ice3de5s4ing3ght6ly3m3p4ped2ope5s3t4s3w4er4ly1mall5er6st3rt5er5phone3sh5ed2ell5s2ile5d5s4ing3th2oke5d4ing3oth1nack5s3ke5s3p4ped2eak2ow1oap2ber2ccer3ial6ism8t6ly4eties6y4ology3ks2da3ium2fa3t4ware2il2lar3d4ier7s3e4ly3id5arity3o4mon3ution8s3ve5d4ing2me4body4day4how4one4rset4thing5ime8s4what6ere2n3g4s3ic3s3y2o3n4er2phie5sticated2re3ry3t4ed4s2ught3l4s3nd5ed5ing5s5track3p3r4ce6s3th5ampton5east6rn5west2vereign9ty3iet2x1pa3ce5s3in3m3n4ish3re4k2eak5er7s5ing5s3cial7ist10s8zed7ly7ty5es5fic8ally9tions7ed6y4tacular5rum4ulation3ech6es4d5s3ll5ed5ing5s3ncer4d5ing5s4t3rm2here2ice4y3der3ke3ll3n4al4e4ning3ral4it6s6ual3t4e2lash3it5ting2oil5ed3ke5n5sman3nsor7ed7s3on3rt5ing5s3t4light4s4ted3use2ray3ead6ing3ing6field6s5t2urs2y1quad4re3eeze1ri1tab4bed4ility4le3ck3dium3ff3ge5d5s3ined4rs3ke5s3ll3mp5s3n4ce4d5ard8s5ing5s4ford4ley3r4e4ing4k4ring4s4t5ed6r5ing5s5up4ving3t4e5d5ment9s5s4ic5ng5on7s5stical9s4s4ue5s5te3y4ed4ing4s2eadily5y4k4l5ing4m3el4p4ring3m4s3p4hanie5en4ped5ing4s3rling4n3ve5n6s3wart2ick5ing5s5y3ff3ll3mulus3ng3r2ock5s3le5n3mach3ne5s3od3p4ped5ing4s3rage4e5d5s4ies4m5s4y2raight8forward5n4nge7r8s4p4tegic8es7y4w3eak5m6ing6s4et6s4ngth8en10ing8s4ss6ed6ful4tch7ed7ing3ict6ly4ke6r6s5ing4ng6s4p5ped5s3oke4ng6er7st6ly3uck5tural8e9d9s4ggle8d8s7ing2uart3ck3dent7s4ied6s5o6s4y5ing3ff5ed3nning4t3pid2yle5s1ub3ject7ed7ive7s3marine4ission5t6ted3scribe9rs7ption4equent10ly4idiary4tance9s7tial11ly5itute3tle3urb6an6s3way2cceed7ed5ss7ful10ly7ion8ve7or3h3k4ed4ing4s2dan3den6ly2e3d2ffer6ed6ing6s4icient10ly2gar3gest7ed7ing8on10s7s2icide3t4able4e5d4s2llivan2m3mary4er4it3s2n3day3g3light3ny3rise3set4hine2per5b5hero5intendent6or5man7rket5natural5star5vision8or3plement5ied7r8s7s5y4ort7ed8r9s7ing8ve7s5se7d8ly3reme2re4ly3f4ace7s3ge5on7s5ry4ical3plus4rise8d8s7ing10ly3render4ound8ed8ing11s3veillance5y6s4ival6e7d6ing6or8s2san3pect7ed7s5nded6sion4icion8us3tain7able7ed1wallow3mp3n3p2ear4t5er3den4ish3ep5ing4t3pt2ift3m4ming3ng5ing3ss3tch6ed7s6ing4zerland2ord4n1ydney2mbol6ic6s3pathetic7y4toms2nc3drome3thesis6tic2ria5n2stem6atic6s0tab3le5s5t6s2ckle3tical6s2g3ged3s2il3wan2ke4n4s3ing2le4nt6ed6s4s3k4ed4ing4s3l2mpa2n3k4s2p3e4s2rget6ed6ing6s2sk4s3te5s4y2ttoo6s2ught2x3ation3es3i3payer8s2ylor1bh1ea3ch5er7s6s5ing3m4mate8s4s3r4ing4s2ch4nical9ly6que9s5ological10es9y2d3dy2e3n4age7r8s4s3th2l3ecommunications4graph4phone4vision3l4ing4s2mper6ature11s4le4orarily8y4ted2n3ant6s3d4ency5r4s3nessee4is3s4e4ion7s3t4h3ure2rm4inal4s3race5in4ible7y5fic7ed6ying5torial9es8y4or6ism8t9s4y2st4ament4ed4ified6y5mony5ng4s2xas3t4s4ure1hai4land3n4k5ful8ly5s6giving3t4s2e3ater7s5re3e3ft3ir5s3m4e5d5s4selves3n3ology4retical5ies5y3rapeutic6ist6y4e5after5by5fore5s4mal3se4is3y2ick3ef4ves3n4g5s4k5ing5s3rd5s4teen5y3s2o3mas4pson4son3rough8ly3se3u4gh6t7ful7s4sand8s2read6s5t6en8ed8ing6s4e4shold4w3illed7r3oat4ne6s4ugh7out4w5ing5n5s3u4st2umb3nder3rsday3s2y1ick4et6s2de2e3d3r3s2ger5s3ht2l3l2m3ber3e4line5y4s3ing3othy2n3y2p3s2re4d4s2ssue6s2tans3le5d5s3s1oast2bacco2day3d4ler2e3s2gether2ilet2ken3yo2ld3erance6te3l2m3ato6es3b3my3orrow2n3e3gue3ight3s3y2o3k3l4s3th2p3ic5s3ped3s2rn4ado3onto3ture7d3y2ss2tal5ly2uch5down5ed6s5ing3gh3r4ing5sm6t7s4nament10s4s2ward6s3el4r5s3n4s5hip2xic2y3ota3s1race5d5s4k5ed5ing5s4tion5or4y3de5d5mark5rs5s4ing5tion9al11ly9s3ffic7king3gedy4ic3il5er5s4n5ed6r5ing5s4ts3ns5action11s5fer8red8s6orm9ation9ed5gender5it7ion5late9d8ion5mission7tted5parency10t6ort9ation9ed3p4ped3sh3uma6tic3vel6ed7rs6ing6led7ing6s4is2eason5ure8r7y4t5ed5ing5ment9s5s5y3e4s3k3mendous3nd5s4t3vor2ial5s4ngle3bal4e5s4unal5te3ck5s5y3ed4s3gger7ed3llion4ogy3m3nity3o3p4le4s3umph2oops3phy4ical3uble7d7s4t3y2uck5s3e3ly3mp3nk3st5ed6es5s3th2y3ing1ub3e4s2cker2esday2ition2mor2ne4d4s3nel6s2rkey4ish3n4ed5r4ing4over4s3tle2torial1weet5ed5s3lve3ntieth5y2ice3light3n4s3st5ed3tter2o1yler2pe4s3ical7ly4ng0uber1fc1ganda2h2ly1kraine6ian1ltimate8ly3ra1mbrella1nable3cceptable3ware2believable2certain9ty3le5ar3omfortable5mon4nscious2d3er5go6raduate7ound5lying5neath5stand10ing10s7ood5taken5water7y6ear3oubtedly2employed8ment3xpected2fair3ortunate11ly2happy2ified4orm7s3on5s3que3t4e5d4s4y3versal7e7ities9y2known2less3ike6ly4mited3ock2necessary2pleasant3recedented2related2stable2til3o2usual2wanted1pcoming2date6d6s2grade7d7s2load6ed2on2per2s3et3ide3tairs1ranium2ban2ge4d4nt2ine2l1sa3ge2b2d2e3d3ful3less3r4s3s2ing2sr2ual5ly1tah2ilities6y5zed2ter5ly0vacant4tion3cine3uum2gina3ue2lid3ley3uable4e5d5s3ve2mpire2n3couver3illa2riable8s5nt5tion9s4ed5s5ties6y4ous3y4ing2st2tican2ult1ector2gan4s3etable9s6rian2hicle7s2locity2ndor3ezuela3ice3t4ure3ue5s4s2rbal3dict3ified5y3mont3non3se5s4ion7s4us3tical3y2ssel6s2t3eran7s1ia3ble2be2c3e3inity4ous3tim6s4or6ia8n7es6y2deo5s2enna3tnam7ese3w4ed5rs4ing4s2i2kings2lla5ge7s5in2nce5nt3tage3yl2olated6ion9s4ence6t5t2ral3gin6ia3tual7ly5e3us2sa3ibility5le4on4t5ed5ing5or7s5s3ual2tal4min1ladimir1ocabulary4l5s2dka2ice5s3d2l3leyball3tage3ume6s4ntary6eer9s2n2te4d4r5s4s3ing2yage1ulnerable0wade2ge4s3on2ist3t4ed4ing2ke3ing2les3k4ed5r4ing4s3l4ace4et4s3mart3sh3t4er2n3dering3g3na3t4ed4ing4s2r3d4robe3ehouse3fare3m4ing4th3n4ed5r4ing7s3rant4en4ior7s3s2s3h4ed4ing7ton3te5d4ing2tch5ed6s5ing3er5s3son3ts2ve4s2x2y3ne3s1eak4er4ness8es3lth6y3pon6s3r4ing4s3ther2b3site7s2dding3nesday2e3d3k4end7s4ly4s2igh5ed5ing5t6s3rd2lcome7d3fare3l4ington4s3sh2ndy3t2re2st4ern4minster2t1hale3t4ever4s5oever2eat3el5chair5s3n4ever3re5as5in5ver3ther2ich3le4st3p3skey4tle3te5s2o3a3ever3le5sale4ly3m3re3se2y1icked2de4ly4r4spread3ow3th2fe3i2kipedia2ld4erness4life3l4iam7s5e5ng7ness3son2n3d4ow6s4s3e4s3g4s3ner6s4ing3s4ton3ter2pe4d2re4d4less4s2sconsin3dom3e3h4ed5s4ing2t3ch3h4draw8al8n4in4out3ness7ed8s2ves2zard1oke2lf3ves2man3en2n3der6ed6ful6ing6s3t2o3d4en4s4y3l2rd4s3e3k4ed5r6s4force4ing4out4place4s5hop8s3ld5s5wide3ms3n3ried6s4y5ing3se4hip4t3th5less5y2uld3nd5ed5s2w1rap4ped2eck3stling2ight3st3te5r6s5s4ing7s4ten2ong3te1tf1we1yoming0xbox0yacht2hoo2le2ng3kees2rd4s2y1ea3h3r4ly4s2ll4ing4ow2men2p2s3terday2t1ield5s1oga2rk4shire2u3ng5er6st3r4e4s5elf7ves3th4ube1up0zealand2ro1ip1ombie2ne4s2o3m]==])
carregarFrequencias("PT", [==[0aaron1baixo3ndonada9o8r7o8u3stecimento2c2el3ncoe3rta6mente6s5o6s5ura2orda6gem8ns6r4to3ut2ra4car5o6s4nge7nte3e4m4u3i4ga6r5o4l4ndo4r5am4u2soluta8mente7o3urdo2u3ndancia3so5s1caba5do5m6os5ndo5r6am6ia4e5i4o5u3demia7ca8o9s3lmar3mpamento3o3so2cao3oes2eita6cao6m6ndo6r6vel5e5o6u3leracao7r3rca4tar5o6u4vo3ssar5e5iveis8l5o6s2ha4m5os4ndo4r5am4va3e4i3o4u2idente8s4o3ma2o3es3mpanha9da10o9mento9ndo9r8e8ou3nteca7e8m8ndo8r9a10m8u7ia8do8mento13s3rda6da7o6r5ei5o6s6u3stumado2re4dita8m9os8ndo8r8va7e7o4scenta10r9ou2t3ion4vidade10s3o3ual6mente2ucar3sacao6oes5do7s4ou1dam3ptacao6do6r2emais3ptos3quada7o3rir3sao3us2ianta6e3cao4ionais8l8r3vinha2ministracao10dor13es10r10tiva14s13o4racao5o4ssao4te5ir6u5o2ocao3lescencia9te11s3ra5m5r5va6el4ei4o3tada6o5r4ou2quirido7r7u2riana6o2ulta5o6s2versario10s3ocacia4gada7o8s1ecio2rea5s4o3oporto9s1fasta6do6mento6r5ou2eganistao3ta5m5r4o2inal3rma6cao6m6ndo6r5ou2onso2rica6na8s7o8s3o2ter1gain2e3ncia7s4da4te6s2indo3r3tacao2o3ra3stinho5o2rada6r6vel5ece8mos8r7imento7o3essao6ivo3icola8s5ultores8ura2ua4rda7ndo7r6e4s3enta7r6o3ia5r1ids2nda2r3es1juda5do5m5ndo5r6am4e5m4ou3ste6s1la3goas3n3rme2bert6o3um4ns4querque2canca7do7r6e6ou3kmin3ool2deia6s2ega5coes5ndo4ou4re5ia3m4a5es5nha5o3rta3x4ander7re2fa3redo2garve3o4dao3uem4m5a6s4ns2ho2i3ado6s4nca7s4s3ce4ia3menta8cao8r7o8s3ne3viar5o2l3en2ma4s3eida3irante3ocar5o2o3jamento2ta4mente4r4s3eracao7oes6do6r5nativa11s10o3itude3o4s3ura2ugar4uel3minio3no5s2varo3es3o4s1ma3da4o5r6a6es3m4os3nda4ha5ecer4te6s3r4al4ela6o3va3zon6as6ia2bas3icao4entais8l7e8s4to3os2e3aca6da6r6s5ou3i3m3rica7n8a9s8o9s7s2iga5s5vel4o5s3zade7s2o3r4es4im4osa6o3stra7s3u2pla5mente4iacao6r4o2y1na3l4isa7ndo7r6e7s6ta8s2cestrais2d3a4m5ento4ndo4r5es4va3ei4rson3o3rade4e5a5w4oid3y2eis3l2gel5a5es3ola3ulo2imacao5da6o7s5is5l4e3versario2jo4s2n3a3e2o3nimo3s2siedade4osa6o2te4na4passados4rior8es8mente4s3hony3i4ga6mente6s5o6s3onio2uais4l5mente3ncia7da8o7r8am6o7s7u1onde2s1pagar3ixonada9o10s8r3nhado6r3rece7m7ndo7r8am7u6ido7mento5lho8s5ncia6te8mente4tamento11s2elido4o3nas3rtado6r3sar3tite2lausos3ica6cao7oes6da7o6r6tivo10s2ocalipse3ia5do5ndo5r4o5u3nta6do6m6ndo6r5ou3s4entado10ria4ta6r6s5o2p3le2reciar4nda6e7mos7ndo7r7u6i7zado9gem4senta9cao10oes9da11s10o11r12a11s9m9ndo9r10am8ou3opriado4va6cao6da7o6r5eita9ndo9r8e8ou5ou4xima8cao8damente8ndo8r2uracao1quecimento4la6s5e6s3i4lo4sicao1rabe5s4ia3nha3ujo2bitragem6o2co2e3a4s3ia3na2gelia4ntina8o3umento9s2izona2ma4da6s5o6s5ura4ndo4rio4s4zenamento3enia3y2quipelago5teto8ura5vo7s2rancar5jar6o3ecadacao4dores4pender3iscar3oz3uda4mar2senal2t3e4s5anato3hur3iculacao4ficial4go6s4sta7s6ica9s8o2vore6s1sa3s2censao2ia4tico3lo2pecto7s2salto4ssinada10o9to11s8o9s3edio4gurar4mbleia4nto7s4ssor8ia3im4na6da7o6r6tura10s5e5ou4s5ta6e7ncia8te10s6i7ndo7r7u3ociacao8oes7da9s8o9s3ume5indo6r6u4ncao5to7s4sta7dor1ta3ca5da6o5ndo6te5r6am4ou3que6s2e3nas4cao4de6r6u5imento4tado5o6s2inge5ida7o6ndo6r7am6u3rar3tude7s3va5mente4idade9s5sta8s4o5s2lantica8o4s3eta6s5ico6smo2mosfera2o3r4es3s2racao5oes4ente4i5r5u4palhar4s5ada7o5o4ves7sa9r3ibuicao7do4z2ua4cao4is4l5idade6zacao9oes8da9o8r5mente4m4ndo4r3ou1udicao4encia9s4o5visual4toria8o2ge3usto2la4s2menta7do7m7ndo7r6o7u2relio3ora2sencia5te3tin4ralia9no5ia2to4matica10mente9o5oveis8l4nomia4r5a6is5es5ia6dade10s6zacao8da9o10s2xiliar6o1valiacao7oes6r3nca6da7o6r5o6s6u3tar2e3nida4tura8s3s2iacao4o3oes3sa5r4o5s5u2o3s1wards3y1zar2erbaijao3vedo2uis3l0babaca3y2cana3ia3k3on3terias2d2gagem3unca2hia2ia4no3le3rro6s3xa5r5s4e4o5s2la4da4nca6o4o4s3de3eado4ia3l2nana3ca5da5ria7o4o5s3d4a5s4eira8ntes8s4ido7s4o3g3heira7o4o3k3ner2r3ao4ta6s5o3ba5ra4osa3celona4o5s3es3ra5gem5s4eira8s5to4iga4o5s6o4y3ulho2se4ada7s6o7s4ia4s3ica6mente6s5o6s3quete3ta5nte4idores4os2ta4lha7o7s4ta6s3e4ndo4r5ia7s4u3ida5o4sta3man3om2y1bc1each3triz2bada5o3e4ndo4r4s3ida6s3o2ija5r4o5s3ra2la4s3em4za3gica3l4a3o4s2m2n3cao3eficiar8o9s3fica3jamin3s3to2rco3lim3nardo2st4a4eira2ta3o2yonce1ianca2blia5oteca10s2cho3icleta9s3o2enal2g2ke2lhao4ete7s4oes3l4y2n2o3diversidade3grafia3logia7ca2spo5s3sau1la3ck2oco5s3g4s4ue3queado7r6io2ue3sa1ndes1oa3s3te4os2b3by3o2ca4do2dy2i2la4s3etim3ha3ivia3o3sa5s4o5naro5s2m3ba5s4eiros2nd4ade3eca5o3ita6s5o6s3s3us2ok3m2rboleta3da4o3ges3racha2ston2ta4fogo4o4r4s3oes2x3e2y3s1raco5s3d3ga3nca6s5o6s3sil6eira10o10s9o10s6ia3va4o3zil2enda3tanha3ve5mente2ian3ga5da6eiro5r5s3lhante9s6r5o3nca6deira11s6ndo6r4de4quedo9s3tanica8o9s4o2onze3oklyn3ther3wn2uce3na4o3tal4o3xa5s4elas1uceta2eno5s2lgaria3lying2nda2raco6s3ocracia3ro2sca5m5ndo5r5s3h3iness2t0cabe4ca6s4lo6s3ine3o4s3ral2ca4dor7es4r4u3hoeira5rro8s2da3e4ia6s5ra7s4rno2em3s3tano2fe4s2i3a3do3ndo3o3r4am4o3u3xa5s2la4da5o4r3ca5da5s4inha4ulo7s3endario3ibre4fornia3l3ma4o3or2ma4da6s4ra6o6s5go5oes3bio3era6s5on3ila5o4nha7da7ndo7o7r6o7es7s4sa6s5eta3panha8s4ea6o5oes6nato4inas4o5neses5s4us2n3a4da5ense4is4l3cao4elada8o7mento7r5r4oes4ro3didata8o9s8ura3eta3o3saco5da6o4ei3ta5ndo5r4o5r6a6es5s5u2o3s2p3a4cidade10s6tacao4s4z5es3ela3ita6is6l7ismo9ta6o5ulo8s3tura7do7r2r3a4cter8es8istica14s9za4lho4mba4s4ter3bono3deal4iaca7o4oso3e4ncia3ga5s4o5s3ibe4dade4nho4oca3l4a4os3men3naval4e5iro3o4l5ina7e4na4s3rega7do7ndo7r5ira8s4inho4o5s3ta5o5s5z6es4eira5l5r4oes5la3valho5o2sa4co4da5o6s4is4l4mento9s4r4s3ca3e3o4s4u3telo4igo4ro2t3alogo4rina7ense3edral4goria9s3olica7o8s2usa5da7s6o7s5m5ndo5r5s4ou2valeiro9s5o6s3erna2xias1bf1ds1eara4ense2der3o2ga3o2la3ebra7cao7do7r6idades3so3ula6r7es6s2m3iterio2na4rio7s4s3so4ura3tavos4enas5r4imetros4o4rais6l5o6s2o2ramica3ca5do4o3eais4bral6o3imonia3rado3ta5mente5s4eza4ificacao9do4o5s3veja2sar3sar3ta2u3s1ha3ma5da7s6o7s5m6os5ndo5r6am5s5va4e5i5m4o5u3n4ce6ler6s4nel3o3pa5da4eu3rles5ie5otte4me3t4a4eada7o4o3ve5s2ef4e5s3ga5da6o5m6os5ndo5r6a7m6em5va4o5u4ue6i3ia5s4o5s4ro3lsea2icago4o3le5no3na4es6a6es3p2ocolate3ice3que3ra5ndo5r4o3ver2ris5tian6opher2uck3mbo3rrasco3te3va5s4eiro1ia2clistas4o5ne5s2dadania6o7s5e6s2encia7s4te5ifica10s9o10s6sta9s2garro2ma2nco3e4asta4ma6s6tografica3quenta3to4ura3za5s2rco4uito8s5lacao7r6o7s5nstancias3urgia8o2ta4cao5oes4da5o6s4ndo4r3ou3y2umes2vil5izacao4s1la3ra5mente5s4k4o5s3sse6s5ica7o8s6ficacao10do12s3udia6o2iente7s3ma5ticas3nica3pe3que2ose2ub4e5s1oberta7s6o6ura3ra5nca5r4e4indo5r2ca4ina3o2digo6s2elho2imbra3ncidencia3sa5s2la4boracao8dor11es8r4pso4r3e4cao5oes4ga6s5io4ta5iva7o8s3heita5r3igacao4na4sao3lege4ins3o4ca6cao6da8s7o8s6m6ndo6r7am5o6u4mbia8no4nia7l6zacao4que7i4rado5ida7o3umbia4na6s2m3a4ndante6o7s3bate7r4ina7cao7do7r4oio4ustiveis10l3e4ca6do6m7os6ndo6r7am5e6i6m5o6u4dia4m5ora8cao9oes8ndo8r4ndo5ta7ndo7r8io10s9sta6ou4r5ciais8l8ntes7o4ter6u5ido4u3i4da6s4go4ssao7rio6oes4te3o3paixao5nheira10o11s7ia9s5ra7cao7do7ndo7r6ecer6tilha11mento11ndo11r10e4ensacao8r5tencia6icao8oes7r4lementar6ta8mente8r7o8s8u6xa8s7idade7o8s5icacoes8da9o4oem5nente10s5r6tamento13s5sicao7tor6ta7o8s4ra6do8res6ndo6r6s5e6ende10r8sao6i5imento5ometer7isso11s6u4utacao7dor10es3um5ente4na5icacao9oes8do8r6dade10s6smo7ta9s6taria10o5s2n3ceder7u6ida8o5icao6to8s5lho5ntra9cao9r5pcao5rto8s5ssao4lui7da8o7r7u6sao7oes4orda8r7o8u6rencia9tes8r4reto4urso8s3dado4e5nacao7do9s4icao6ionado6oes4ominio4ucao5ta6or5z6ido7r3ectado9s7r4xao5oes3federacao5re7ncia11s6ir5ssar7o8u4ia6nca7te6r6vel5e5guracao5o5ra6ma8cao8da9o8r7ou5ssao4lito8s4orme6tavel7o4ronto9s4undir5sa7o6o3go4regacao6sso3heca6e7m8os7ndo7r8am7u6i7a7da9s8o9s7mento12s6o3junta7o8s3nosco3osco3quista9do9r9s8ou3sciencia8te9izacao4egue8m7i8a8do8mos8ndo8r9am8u5lheiro11s7o8s5nso6timento5quencia12s9temente5rtar6vacao8dor11es4idera9cao9da11s10o11s9m9ndo9r9vel12mente8e8o9u5ga6o5ste8nte4olidacao4piracao4ta6nte9mente9s5itucionais13l8em8i9cao9da10o5rucao8oes7ida10s9o8ndo8r9am8u4ulado6ta8do7or5midor10es6o3ta5bilidade5cto5do7r5gem5m6inacao5ndo5r5s5to7s5va4e5i5m6poranea12o5ndo6te5r5udo8s5xto4igo5nental9e10s6ua8cao8m9ente9os8r9a10m8va7e8m7idade7o8u4o5s5u4ra6rio6ste6tacao8do10s8r7o8s8u5ibuem8i9cao10oes9ndo9r10am9u5ol7a8da9o8r7e7o6versia4udo3vem5ncao7er8u7ido8onais11l7oes6iente5rsa8mos8ndo8o8r8s7ei6ter4iccao5da7da8o9s7r6ou5te5vencia7r4ocacao7do2oper6acao3rdenacao8das9or2pa4cabana3ia5r5s3o4s2r3acao5oes4gem4l3da5s4eiro3e4ano4ia4s3inthians3o4a4nel3po5racao7l5s3ra4e5dor8es5ia6o7s5m5ndo6te8s5r5sponde11ncia12te14s5ta7mente6o7r5u4ida7s5gir4upcao6to8s3ta5da6o5r4e5s6ia4ina4ou2sta5s4uma7m7va6e7s6o2ta4s3idiano2untry3ro3tinho4o2varde3er3id2zinha7r1pi1raig3zy2e3dibilidade5to7s4o3io3me3nca6s3r3sce6m6ndo7te6r6u5ido6mento2ia4cao4da6s5o6r7es6s4m5os4nca7s5do4r5am4tiva7idade7o5ura8s3e4i3me5s4inal8idade6osa8o9s3ou3se5s4ta6l6o7s5ianismo8o6na5o3terio8s4ica7do7r7s6o7s7u2oacia3nica7s4ograma3ss2ucial3el3z4amento5r4eiro1uba2iaba3da5do7s8amente5ndo5r4e2ja4s3o4s2linaria3pa5da6o5r3tivo4o4ura7is7l7s2mprimento6ndo6r6u2nha5do2p3ula2ra4r3iosa7mente6idade11s6o4tiba3riculo3so5s3ta5s4ir4o5s3va5s2sta5r4o5dia5s5u0dada4s3o4s2i3ly2le3i3las2ma3os2n3ca5ndo5r4e3do3iel6a4lo3ny3o4s3tas2o2quela7s6e7s4i5lo2r3a3ia3k2s2ta4s2va3e3i4d4s2y3s1ead3n3th2baixo4te6r6s2cada6s3ente4pcao3ide6m5i6do6mos6r7am6u4mo4sao5ivo5oes3lara7cao8oes7do7r6ou4inio3oracao5rencia7r3reto2dica6cao6da7o8s6r5ou3o4s2em2feito7s4nde7m7ndo7r7u5sor8es4sa3iciencia4ne6m5icao7oes6da8s7o8s6r6tiva10mente9o6u2gradacao2i3tado5r3xa5do5m6os5ndo5r6a7m6em6ia5va4e5i5m4o5u2l3a4s3e4gacao7ia6do8s4s3icada5ia6oso3ta2m3ais4nda7s4siado3issao4tido3ocracia7ta9s8ica10o4nio7s5stra9cao10oes9do9m9ndo9r8ou4ra6r5ou4s2ngue3ise3nis3ominacao8da9o3sidade3te5s4ista4re5o3uncia8r8s2partamento12s3ende7m7ncia8do8te10s7r3oimento10s5s4sito8s3ressa8o3utada7o8s2r3a4m3iva6do8s3rota7do7r7s4ubar6ou2s3afio7s4parece10r11am10u9ido12s10mento4stre3cansar7e7o4e5ndentes7o5r4oberta10s9o6re8m7i8mos8ndo8r9am8u5nhecida11o12s6to4reve8r8u5icao6ta7o4ubra5lpa8s7e8m3de3eja6m6r5o6s4mpenhar9o6rego4nhada7r6o7s5volve10dores10ndo10r10u9ida12s11o12s10mento4rto4sperada10o8o3file7s3graca8do3ign6ado6er5ualdade4sta6ir7u3liga7r4ocamento3pedida5rdicio6tar5sas4orto4rezo3sa5s4e5s3ta5ca7m7ndo7r6ou5que8s5s4e5s4inada8o9s6o7s4roi5uicao7da8o9s7ndo7r7u3viar5o2talhada6e7s3em4ncao4r5mina9cao9da11s10o11s9r8ou4sto4tive3ido2u3s4a4es2va4gar3e4m5os4ndo4r5a6o5es5ia7m8os3ia5m4da6mente5o3o4lver2z3embro4nas1ia3bo3gnostico3logo7s3mante8s4etro3na4te3ria6mente6s5o6s3s2ca4s3ionario3k2ego3sel3ta2ferenca9s7te9mente9s3iceis5il7mente5uldade11s3usao2ga4m5os3itais6l3na4idade4o3o2lma2mensao6oes3inui7cao7r7u2namarca5ica3heiro2ogo2ploma2ra3ecao5cao5tamente6o7r4ita6o7s4ta6mente6s5o6r7a7es7ia6s5rizes3ia4ge6nte9s5ida7o6ndo6r6u2sciplina10s4o5s4riminacao4urso8s5ssao7oes5te6indo7r3ney3parar6o7s4oe5nibilidade11za13do7veis9l5sicao7tivo11s6ta7o8s4uta7r7s3se5r6am4o3tancia9s6te8s4incao6guir6tas7os4o4ribuicao9do11s9r6to8s4urbios2ta4do6r5ura3o2versao7s6idade6os5tida8o7r3ida6s5e5ida7o8s6r4na5o4sao5oes3orcio3ulga7cao7da8o9s7r6ou2z3em4ndo4r3ia5m1na1oacao4oes3r2bro2c3e4nte4s3umentacao9rio12s8o9s2enca6s4te6s3r2g2i3da4o3s2lar5es2m3estica8o9s3inante6r5go7s5icana6o7s2n3a4ld3o4s2r3es3me4i5ndo5r5u2s3e4s2u3glas3rada6o3tor6ado4rina2wn4load2ze1ra3gao4oes5n3ke3ma5tica2eam2ive2oga5s1uarte3s2bai3lado2elo2ke2m3a2pla4o2que2ra4cao4nte4r4s3o4u2vida6s5o2zia1vd1ylan0earth2st1clipse2o3logia7co3nomia8s7ca9s8o9s7sta1ddie2gar2icao4oes3ficio8s3tado5r4or6a6es6ial2son2uardo3cacao6ionais10l5do2ward1feito6s3tiva7mente6o2icacia5z4iencia7te1gipcio3to2o3ista1instein2s2xo1la3boracao7do3s2e3fante3gante4er3icao5oes4ta5o6r7ais8l7es6s3mento8s3na4co3s3trica7idade7o8s5onica9o10s3vacao5da6o7r7s5r2ias3minacao7do7r3te3zabeth2len2ogio6s1magrecer3il2baixada8or6o3ora2enda3rgencia2ily3ssao5oes6ra8s3tido5r5u2ma2ocao4ional8nte4oes2pate3reendedores8imento14s5gada8o9s6o7s5sa7rial9o10s7s6tado7imo10s1ncaixa4rar5regado3erra7do7mento7r6ou3he5r3omenda4ntra8da10s9o10s8m9os8ndo8r9a10m8va7e8i7o8s8u4sta2d3ereco8s2em3rgetica5ia7s2fase3ermeira3iar4m3renta8m8ndo8r7ou2gana6r5o3enharia6eiro10s3lish3racada8o2orme6s2quanto2redo2saio6s3ina6mentos6ndo6r5o6u2tanto4o3enda6e7m8os7ndo7r7u6i7do7mento6o4rrado6o3idade8s3orno3ra5da7s6o5m5ndo5r6am4e5ga7r6ou6ue8s5i5tanto6enimento5vista10s4o5u3usiasmo2via5da7s6o7s5ndo5r6am4e4o5u3olve7m7ndo7r7u6ida9s8o9s7mento2xergar1pidemia3sodio8s2oca5s1quador3ilibrio4pa6do6mento11s6s5e6s4valente1ra3m4os3s2ic3k2rada6s5o3o4s2va4s1scada6s4la6da6o4ndalo4par5e5ou4ssez3larecer3ola6r7es6s5ha7s6e7r8am7u6i7da8o9s4nde7r6ido3ravidao6o7s4eva6e7ndo7r7u6i6o4ita7s6o7r8a8es8io10s7s3udo4ra5idao5o4ta6ndo6r2fera6s3orco7s2goto2pacial5o6s4da4lhadas8os7r6ou4nha6ois7l8a3eciais7l8idade9sta12s9zada12o8mente6e7s6fica10mente10s9o10s5tadores6ro4lho4ra6do6m7os6nca9s7do6r6va5e6i5o5to4tacular9o3ionagem4rito8s7ual3orte7s6iva8o4sa6s2quadra8o4eca7m6e7r8am7u6i7do7mento5ma5rda7o4ina2sa4s3e4ncia8is8l9mente4s2t3a4belece10r10u9ida12s11o12s10mento15s5ilidade4cao5ionamento5oes4dia6o7s5o6s5uais7l4gio7s4mos4ndo4o4r5a6o5ei6m7os5ia7m4s4tais6l5istica11s5ua6to4va6m7os5el3e4ja6m4nde7r4s4tica4ve3ilo6s4ma6cao6do6tiva10s5ular4ve6r7am7em6sse9m3omago4u3rada7s5gar5ngeira11s10o11s6ha8s7o8s5tegia10s9ca10o4eia6ta5la7s5ou5sse4utura9l9s3uda6do6ndo7te9s8il6r5io5o6s6u4pro1tapa5s2c2erna6mente5idade5o2ica3opia1ua2ro4pa5eia8s6u7s4s1va3ngelho7ica2ento6s5ual8mente3r2idencia9s6te3tando5r2olucao1xagero3me5s4inar3ta5mente4o2cecao5oes4lencia7te9s4pcional4sso4to3luir5sao6iva9mente8o2ecucao5tada8o9s7r6iva8o9s3mplar8es6o7s3rcer5icio9s6to2ibe4icao5da6o5r3ge5m5ncia9s4indo5r3lio3sta5e6m6ncia7te9s5ia7m6r6u3to2pandir5sao3ectativa11s4dicao4riencia11s6mental11r10e10o3lica7cao8oes7do7ndo7r6ou4odir5racao7r5sao3oe4r5tacao8oes4sicao7oes5ta6o7s3ressa8o8r7o8es3ulsao6o2tensa7o4rior8es5na7s6o7s3incao3ra5cao5ordinaria13o5s4ema7mente6o0fabio3rica7cao7nte10s7s2ca4m3cao3e4book4is4s3hada3il5idade6tar5mente3o3to5r5s3uldade9s2das2ixa5s2la4da5o4m5os4ndo5tes4r5am4s4va3cao3e4ceu5ido4i4m4ncia3ha5r5s4ou3o4u3sa5s4o5s3ta5m5ndo5r5va4ou2ma3ilia7r8es7s5y3osa6s5o6s2ntasia8s6ma8s6tica9o2ra4o3ei4mos3ia5s4nha3macia3ol3sa2s3cinante3e4s3t2tal3ima3o4r5es4s2una2vela3or5aveis8l5ita8s7o8s2z3e4m5os4nda7s6eiro6o4r5em4s3ia5m1bi1eat2bre2cha5da7s6o7s5mento5ndo5r4o5u2deracao6is6l2ia3jao3o3ra5s3ta5s4o5s2licidade4pe4x4z5es5mente2minina8s7o8s6smo7ta9s2nomeno8s2ra3iado5s4da6s5o6s4mentos3nanda7es7o3ramenta10s5ri4eira4o2sta5s4ivais7l2vereiro2z1ianca2bra5s2ca4do4m5os4ndo4r5a6m6o5em5ia4sse4va3cao3ha3o4u2delidade2eis3l2fa2gado3ueiredo4ra6s2la3ha5s4o5s5tes3ipe5inas3magem7ns5r4e5s3osofia7o3tro6s2m2na4is4l5idade6stas5mente4ncas6eira10s9o10s6iamento8r3d3gindo5r3o3s2o3s2que5i5m2re3ma4e3st2scais5l6izacao3ica6mente6s5o6s2ta4s2xa3e3o2z3emos4r5am4sse1lagrante3mengo3sh3vio2or4a4ence5s6ta8l8s4ianopolis5da2uminense3xo1oca4r3o2da3er2fo2ge3o4s2i2lego3ga3ha5s2me3os2nseca3te5s2od2r3a4m3ca5da6o7s5ndo5r5s4e3d3em3ma5cao5da6o7s5is5l6mente5m5ndo5r5s5to7s6ura4ou4ula7rio3nece7dores7m7ndo7r6imento4o3o3ro3talecer8imento7za4e5mente5s4una3um2sse5is5m2to4grafia10s8o4s2undation2x2z1raca5sso4o5s3gil4mentos3nca5e6s7a8s7es5is7co5o4go4k5lin4quia3queza3se5s3ternidade3ude2ed3e3guesia3i4re4tas3nte3quencia7te9mente9s3sca5o2ia4s3ends3o2om3ntal5eira9s3ta2uta5s4o5s1uga3indo4r5am4u2i2ll2maca4r3o2ncao4iona8l8m9ento8ndo8r9io11s7ou4oes3dacao6oes5da6o7r8es5mentais10l9o4o5s3eral3k2racao3ia2sao2tebol3sal3ura6s5e5o6s0gabinete3riel7a2do2ga2jo2laxia3era5ia3inha3o3vao2ma3e4s2ngue3ha5m6os5ndo5r6am4e5i4o5s5u2ragem4nte6ia8s7do7ndo7r7u6o3cia3ganta3ota6s5o6s3rafa7s3y2s3es3olina3ta5r4o5s2ta3ilho3o4s2ucha5o2y3s1elada5eira5o3o2meos2ne4bra4rais6l5o6s4s4tica3ial4o3te4il6eza2ografia8ca3rge5ia2ra4cao5oes4da5o6r4is4l5do5mente4ndo4r3enciamento5te3ou2stao4o2t1igante7s2l3berto2nasio5tica2ra3l4s3o1lobais5l4o3ria1od2iania4s2l3d3eiro3fe4o3pe5s3s2mes2ncalo6ves2od3gle2rda4o5n4ura2spel3ta5m6os5ndo5r6ia8mos5va4e5i4o5sa6o5u2t3a2vernador10es7mentais12l7nca8te10s7r6o7s2zar1ps1ra3ca5s4e3de4uacao6lmente3fica6o7s3ma5do4my3na5da4d5e6s6za4t3o4s3ta4idao5s4o4uita8mente7o8s3u4s3vacao6oes5do5ndo5r4e5s4ida7de6ez4ou2eat3cia3en3g4a4o5s3mio3ve3y2ipe3ta5ndo5r4o5s5u2ossa5o3up2upo5s1uarani4da6do6r6s5iao3temala2edes3rra6s5eiro9s6ro2ia4na4s3lherme3maraes3ne3tarra2stavo2y0habilidade10s4tacao6ntes5o6s5ual2iti2ja2ll2mburguer3ilton2n2ppy2rd4ware3monia3old3ris4y3vard2shtag2ve4ndo4r5a5ia3ia5m4do1eart2ctares2in2len5a3icoptero11s3p2nrique4y2r3anca3deiro3e3oi5na5s2y1ierarquia2gh3iene2ll2no2p3ocrisia4tese8s2s3toria8dor8s7ca9mente9s8o9s6y2t3ler2v1oje2landa6es3lywood3mes2me4m4nagem8ns5s3icidio9s3ossexuais10l2nduras3estidade6o3g3ra2p3e2ra4rio7s4s3izonte3rivel4or6es3ta2spedagem4itais7l2t3eis4l2use4ton3ve5r5sse2w3ard1ttp4s1ugo2m3an5a6s5idade5o6s3ildade6e5hacao3or2ngria3ter0iam2n1bge1cone1da3de5s2eais4l3ia5s3ntidade10s6fica10cao10do12s10r9ou3ologia2ioma6s4ta6s2o3lo5s3sos1gnorancia6r2or2reja6s2uacu4is4l5dade5mente1ii1legais5l2ha4s2uminacao3sao4tracao8oes1magem5ns4ina7cao7ndo7r8io7va6e7i6o2becil2ediata8mente7o3nsa5o2igracao6ntes3nente2obiliaria10o3veis5l2pacto7s3eachment4de5indo6r6u4rador5ial6o3lantacao4ementacao10r4ica7coes3or5ta7cao7m7ncia8te10s7r6o4ssivel5to7s3rensa5ssa8o7ionado11nte7o8es4imir4ovavel3ulso2unidade1nacio4reditavel3uguracao2capacidade6z3endio8s5tivar8o3idente9s3luem5i6do8s6ndo6r6u5sao6ive3omoda8r5um4nsciente3riveis7l8mente2denizacao4pendencia10te12mente12s3ia5na6o4ca6cao7oes6da7o8s6m6ndo6r5e6s5ios5ou4gena8s4o5s4viduais9l8o9s3o4nesia3ustria9is9l9s2edita6o3s4perado3vitavel2fancia5til7s3eccao4liz7mente4rior8es5no3inito3lacao4uencia10r10s7tes3o4rma7cao8oes7do9s7l7r7tica9on6e6ou3ra5estrutura2glaterra4es6a6es3redientes5sso8s2icia6da7o6is6l7mente6ndo6r7am6tiva10s5o6u3migo7s2jecao3ustica6o2ocencia6te8s3vacao2querito2screver5icao7oes6tos3eguranca4to6s3iste3pecao4iracao7da8o7r6ou3tabilidade5gram5lacao8oes7da8o9s7r5ncia6te5vel4itucional7icao9oes7te8o4rucao7oes6mento11s6tor2tegra7cao7da8o7l7nte10s7r6idade4ira7mente6o7s4lectuais10l5igencia9te11s4ncao6oes5sa6idade6o4r5acao6gir5cambio5essa9da10o11s9nte12s9r8e9s5face6erencia8ir5ino6or5na7cionais12l13mente7s7tional6et6o7s5pretacao11oes10do10r5romper6upcao5valo6encao9oes3imidade5o4tulada9o3roducao7zir3uito2umeras6os3teis4il2vadir6u4sao3eja4ncao5tar6ou4rno4s5tidores7ga9cao10oes9dor12es9r7mento12s7r3isivel1orque2s1phone1ra3o3que2ei3m4os2ia4m3s2landa2ma4ndade4o5s4s2onia2regular9idades3itado1saac3bel2lamico4nd6ia2o3lada6o7s5mento2rael6ense2so2tambul3o1talia6na7o8s2em3ns2unes1van0jack4son3ob2ime3r2ke2maica5s3es3ie2n3e4iro4la6s4t3tar2pao3ones7a7es2rdim5ns2son2to2va3ier2y2zz1ean4s2ff4erson2ito2nnifer2remy3ry3sey3usalem2ssica3us1im3my2n1oana3o3quim2e3l4ho6s2ga4da5o6r7es4m4ndo4r5am4va3o4s4u3ue5i2hn4ny4son2inville2n3as4than3es2rdan3ge3nada5is5l6ismo8ta10s2se4ph3h2urnal2vem4ns1uan2das3eu5s3iciais7l7rio2iz4a4es4o2lga5do5mento5r3ho3ia5n6a4e4o2nho3ior3ta5mente5ndo5r6am5s4e4o5s5u2ra4dos3i4dica8s7o4sdicao3o4s2st4a5mente4ica5fica9r9tiva5n4o2venil5tude0karen3l2te1elly2n3nedy2vin1han1ids2m2ng2t1night2ow1ong1urt0labios3oratorio11s2co4s2do4s3rao4oes3y2go4a5s4s3rimas2ma3entavel6o3ina2na3ca5da6o7s5mento10s5ndo5r6am4e4he4ou3d3e3terna2pa3is2r3a4nja3ga5r4o4ura3ry2s3er3t2ta3erais6l3im4na5o2ura4en2va4gem4r2w2zer1eague3l4dade3ndro3o2e2gado4is4l5izacao5mente3enda7s3iao4slacao7tiva11s10o4tima7o2i3a3lao3o3s3te4or6es4ura7s2ma3bra6do6m6nca9s7do6r5e6i5o6u3os2nda5s4o3ta5mente4e5s4o2o3nard7o2r2s3ao3bica3oes3te2t3ra5s2u2va4da5o6s4m4ndo5ta7mento7r6e6ou4r5a6m5ia4va3e4i4s3o4u2wis1gbt1he3s1ia3m2bano3eracao6da7o6is6l6r5dade5tacao7do9res7r3ia3ras2cao3enca4u3itacao3oes2da4ndo4r3er5a6da7o6nca9s6r5es3o2fe2ga4cao5oes4da6s5o6s4m4ndo4r3eiramente3ht3o4u3ue5i2ke2ma4o3ita6coes6da7o6r5e6s3pa5r4eza4o2ncoln3da5s4o5s3e3gua6gem8ns6s5istica3ha5s3k4s3ux2quido2sa3boa3ta5s2teralmente6ria8o6tura3oral3ros3tle2ve3ing3rar6ia4e5mente5s4o5s2xo1obo4s2cais4l5idade10s6zacao8da10s9o10s8r2gan3ica5o4stica3o2ira2ja4s2la2ndres5ina3g4a5s4e4o5s2ok2pes4z2rde3ena2s2te2u3ca4o5s4ura3is3renco2ve2w1ua3nda2cas3ia5no4o3rativos4o5s3y2gar5es2is3z4a2ke2la2na2ta4dor4m4ndo4r4s3o4u2xo2z3es0mac3a4co6s4u3edo6nia4io3hado4ista4o4ucar3onha2dame3e4ira3re4id4ugada3uro2e3s2galhaes4zine3ia4ca5o3nitude3oar2i3a3l4s3o4r5es5ia3s2jor2ke2l3a4s5ia3dade4icao5ta3ta3uca5o2ma4e2n3aus3cha6s5ester6te3da5do5m5ndo5r6am5to4e5i4o5u3eira7s3ga4ueira3ha5ttan3ifesta9cao10oes9ntes9r8o4pulacao8r3o4bra7s4el3sao3te5iga5m5ndo6ha5r5ve4ida6o7s5veram4o3ual4el4tencao2o3s2pa4s2quiagem5na7s2r3a4cana4nhao4tona4vilha9s8osa11s10o11s3c4a5da6o7s5ndo6te5r6am5s4el6o4ha4io4o5s5u4us3e3fim3garet4em5ns4inal3ia5na4do4e4lia4na5ha6o4o3k4eting3ques3rocos5m3shall3ta4e5lo4ha4in6s3vel3y2s3cara7s4ulina8o3sa5cre5gem5s3ter2ta4m4ndo4r5am3e4i4matica4ria7is7l7s5nidade4us3heus3o4u3riz3t4hew3uridade2u3ricio4o3s2x3ima5o2y3a1eados2c3anica7o6smo9s2dalha7s3e4iros3ia5nte5s4ca6mento11s6s5ina5o6s4da6s4o4r3o4s2ga2ia4s3o4s2l3hor6a7ndo7r6es6ia8s6ou3issa3lo3o2mbro6s3oria7l7s2n3cao4iona8do8r7ou3des4onca3ezes3ina6s5o6s3or5es4s3sagem7ns5l3tais5l6idade4e5s4indo5r6a7s2ra3cado7ria10s7s4edes4osul3da5s3ece6m5ia5o3gulhar7o3ito2s3a4s3es3ma5s4o5s3quita3sias3trado5e6s2ta4de4is4l4s3e4r3odo6s3ragem4o5politana5s2u3s2xe4ndo4r3icana7o5o1ia3mi2chael4el6le3ro5fone5soft2dia5s2gracao3uel2ke2l3agre7s3es3hao5res5s4o5es3itante9s6r7es3ler3ton2m2n3a4s3eiro4racao6is6l3ha5s3i4ma5o4sterio6ra7o8s3oria3uto6s2ra4nda2seria6cordia3s4a5o4eis4ionario4oes3terio8sa9o4o4ura2to4logia4s2x1obile5idade6zacao2ca4mbique3hila2da4lidade10s3elo6s4rna7s6izacao6o7s3ificacoes3o4s3ulo2eda5s2ises2le3ho2mento7s2na4rquia3ey3ge5s3ica4tor7amento8r3stro7s3tado5gem5nha8s5r4e5iro5s3umento2on2r3a4da5ia5or7es4es4is4l4m4ndo4r4va3e4ira4na5o3gan3o3ra4e5m5ndo5r6am5u4ido4o3ta5is5l6idade5s4e5s4o5s3umbi2scou3quito3tra6do6m6ndo6r7am5e5ou2ta3el3ivacao5o6s3o4r5es5ista9s2ura3se2ve4is4l4r3imentacao8o9s1tv1uculmanos2da4do4m4nca7s5do4r5am3e4i3o4u2ita5s4o5s2lher6es3ta5s4i5dao5plas7os2ndiais6l7mente4o5s3icao5ipais8l7io9s2ralha3o4s3phy2sa3culos3eu5s3ic5a6is6l6s5o6s0nacao3ionais7l8idade3oes2da4r2me3orada7o8s6r5o2ncy2o2quela6e7s4ilo2riz3racao5dor5tiva2s3a3ce5r6am5u4i5da6o7s5mento2tacao4l3han3ional4va6s5o6s3urais6l7mente5eza2val3e4gacao6dor6r4s3io5s1ecessaria10mente10s9o10s6idade11s7ta2ga4cao4do4r4tiva8s7o8s3ociacao8oes7r6o7s4u3ra5s4o5s2il2la4s3e4s3son2m2nhum6a2o2rd3vosa6o2ssa5s4e5s3ta5s4e5s2t3flix3o4s3work2ve4r4s2w3s2xt2ymar1icholas3k3olas5e2geria3ht2na3guem3ho3ja3tendo2sso3to2teroi2veis4l1obel3re5s2cao2el2gueira2ite5s3va4o2jento3o2me4acao5damente6o4s2n2ra3deste3ma5is5l6mente5n5s3oeste3te4h3uega2s3sa5s4o5s2t3a4r4s4vel3e3icia7s4ficacao3ou3urna6o2va4mente4s3e4la6s4mbro3idade8s4nha3o4s2w1ua2clear7es5o2m3a3ero6s7os2nca3es3o2vem4ns0obama2jectivo9s6o4tiva7o8s5o6s2ra4s3iga6cao7oes6da7o8s6r6toria10o2s3erva7cao8oes7do9r7ndo7r7torio6e6ou3taculo9s5nte2tencao4r4ve3ido6s2viamente4o1casiao5oes2eano2identais8l7e2orre6m6ncia7do6r7am6u5ido8s2ulos3pa5cao5da6o7s5ndo5r1deia5m4o2iar3o1este1fender4sa5iva3rece7m7ndo7r7u6ido4ta2f3ice2iciais6l7mente5na7s5o1itenta3o1kay1la2d2eo2ha4da4m4ndo4r5es3e4i4m3o4s4u2impiada9s6ca7o8s3nda3veira5r1mar2bro5s1nda4s3e2e2g2ibus2line3y2tem2u2ze1pcao3oes2en3ra5cao6ionais10l6oes5dor8as8es5r2iniao5oes2ortunidade12s3sicao4to2tou1ra3cao4oes3l2camento2dem4nou5s2elha2g3anica6smo9s6za8cao9oes8da10s9o10res10s8r7ou4o5s3ulho7sa8o2ientacao7l6e3gem5ns4inais7l8mente2kut2lando3eans2questra1scar2so4s1ther2ima5s4o5s1uca3o2r3o2t3ono3ra5s4o5s3ubro2ve3i4do6s4mos4ndo4r5am4u1ver2o3s1xford2igenio0pablo2ciencia6te8s4fico3ote6s3to2drao4e5s4oes2es2ga4m5ento9s4ndo4r4s3e3ina6s3o4s4u3ue5i2i3neis5l3s4agem7ns4es3va3xao2lacio4vra7s3co5s3estina6ra8s3ha5co7s3ma5s4eiras2n3ama3demia3ela3ico3o4rama2o2pa4i3eis4l3o2quistao2r3a4bens4da6s5o4guai4iba5so4lelo4m5etros4na4r5am3ceira7o8s5la5ria8s4ial7mente3e4ca5e6m6ndo6r6u5ia7m6da7o5o4de6s4i4m4nte7s4s3is3k4er3lamentar11es9o3oquia4u3que6s3t4e5s4icipa9cao10oes9do9m9ndo10te12s9r10am8e8ou6ular10es10mente9s5da7s6o7s5lha8r5ndo5r5u4o4y2s3coa3sa5da7s6o7s5geiro10s7m7ns5m6os5ndo5porte5r6a7m6o7s5va4e5ar5i6o5m4o5s5u3ta4or6al2tas3ente3io3o3rao4ia5ck5monio4ocinio4ulha2u3l4a4ista4o3sa3ta2vilhao2z1df1ec3a4do6s4s3o3uaria4liar2daco6s3e4m3i4a4do6s4mos4ndo4r5am4u3ra5s4o2ga4ndo4r3o4u3ue5i2ito5s3xe5s2la4s3e3o4s2na4l5tis4s3ha3insula4s3sa5do5m6ento10s6os5ndo5o5r5va4e5i5m4o5u2ople2quena7s6o7s4im2r3ante3ca4ebe7m8os7r8am7u6i7do6o5pcao4orrer4urso3da5o5s4e5m6os5ndo5r6am5u4i5da7s6o7s4oa6r5e3eira3feicao6ta8mente8s7o8s4il5s4ormance4ume3gunta8m8ndo8r9am8s7e8i7o8u3iferia4go6s7a8s7o8s4metro4odo7s3manece9m9r9u7ncia8te10mente10s4issao5ta6e7m6ido7ndo7r8a7u3na5mbuco5s3ry3sa4eguicao8r4onagem9ns7lidade13s4pectiva11s3tence8m8nte11s4o3u2s3a4da6s5elo5o6s4r3ca5dores4oco3o4s3quisa8dor11es8r8s3sima6o4oa6is6l7mente6s2ter3icao3robras5leo1hil2oto1ia3da5s3no3ui2b2ca3o2edade3rre2lar5es3ha3oto6s2menta6el2nheiro3tar4o5r4ura7s2or4ar4es2poca2ramide4ta6s3es2scina3o3ta5s4ola2zza1laca5r5s4e3nalto4eja7da8o7mento7ndo7r5ta7s4o5s4ta6o6r6s3sticas7o3taforma10s4eia3y2ease3na5mente5rio4o2us1mdb1neus1obre5s5za2co2dcast3e4m5os4ndo4r5a6o5em7os6s5ia7m8os5osa8s7o8s4s3ia5m3re2e3ira3ma5s3sia3ta5s2int3s2kemon2lemica3icia7is7l7s4tica8mente8s7o8s3o4nia3uicao2nta5s4e5s4o5s4uacao2p3ulacao7oes6r7es7idade2r3cao5ria4entagem4o3em3no5grafia3que3ra5da3ta5l5nto5o5ria5s4e4o5es5s4ugal6ues9a10s9es2s3icao5ionamento5oes4tiva8s7o8s3sa5m6os4e4ibilidade13s5veis7l8mente4o4uem5i6a6r3t4a5do5gem7ns5l5ndo5r4e5rior9mente4o5s5u4s4ura2tencia8is8l9mente3ter2uca5s4o5s3par3quinho2vo4ado4s2wer1ra3ca5s3do3ga3ia5s3ta4ica7mente7r7s6o4o5s3zer4o2e3cedentes4ioso5pitacao5sa7m8ente8os7ndo7o7r8a7va6e6o7u4o5nceito5s3dio6s3encher3feito8s7ura5re7m7ncia6ia7da8o4iro3judicar5izo8s3liminar3miacao6do5o6s3nde6r6u3ocupa8cao9oes8da9o10s8r7e3para7cao7da8o9s7ndo7r6e3sa5s4enca6te8s5rvacao8r4idencia11is11l8ta9e10s6io4o5s4s5a6o5ionar5oes4ta6cao6r5e6s5igio3ta4ende8m7ia7o4o5s3ve5ncao6ir5r4ia6mente5dencia5sao6ta7o2ima5ria7o5vera4eira8mente8s7o8s4o5s3ncesa8s5ipais8l9mente7e7io9s3oridade10s3sao4ioneiro11s4oes3vacidade5da7s6o7s4ilegio10s2o3babilidade4lema8s3cedimento12s5ssamento8r7o8s4ura7do9r10ia7m7ndo7r7va6e7i6o7u3ducao6oes5to7r8a8es7s5z6em6ida9s8o9s7ndo7r7u3f4essor9a9es5ta4issao7ionais11l4unda8mente8s7idade7o3grama8cao8do8s5esso3ibicao6da7o3jecao6t7o8s5tado6o7s3l3messa8s5te7u6ido6o4ocao6ional5tor5ve7ndo7r7u6ida8o3nta6s5o6s3paganda4oe5r6cao7ionar7oes5s6ito6ta8s7o4ria7mente7s6edade11s7tario12s6o7s3s4peridade4seguir4titutas3tagonista12s4ecao6cao5ge7ndo7r6ida8o9s5ina8s5ja5stantes7o8s5tor4ocolo9s3va5r5s5vel8mente4eniente11s4incia9s5soria4oca7ndo7r6ou5u3xima7s6idade11s6o7s2udente1sd3b2icologia9ca10o8o2ol1ublic6a7cao8oes7da9s8o9s7mente7r7s6idade6o7s7u2de4r5am4sse7m2lar3mao3so2nho3icao2ra3o2ta3o2xa4r0quadra6do8s6s5ilha6nhos5o6s3is5quer3l4idade9s5ficacao9dos4quer3ndo4ta6s5ia6dade10s5o6s3o3renta4ta6s5el5o6s3se3tro2e3bra6da7o6ndo6r5ou3da5s3en3ijo4ma6do6ndo6r4ra6m5oz4xa6s3m3nte6s3r4em6os5ndo5r5s4ia6m5da6o7s4o3stao5ionar5oes2i3eta5o3lometros5s3mica7s6o7s3nta6l5o4ze3s4er6em5sse0rabo2ca4s3hel3ial4ocinio5nal4smo5ta2dar3iacao4cais6l4o5s2fael2imundo3nha3o4s3va3z4es2mo4s2nking2p3ariga8s4z5es3ida6mente6s5o6s3osa3per2quel2ra4mente4s3o4s2to4s2ul2y3mond2zao3oavel4es1eabilitacao3cao4oes3d3gir3is3l4idade5sta5ty5za7cao7da9s8o9s7m7ndo7r8am6ou4mente2becca4lde7s5iao2cado3ebe6m7os6ndo6r7a8m6u5i6da7o8s5o4io5ta7s4m4nte7mente7s4pcao3iclagem4fe3lama7cao8oes7m7ndo7r3olha6er4mecar6nda9cao10oes8o5pensa4nhece9r9u8ida10o11s9mento5strucao9ir4rd6ar6e5rente7r3uperacao8r4rso7s4sa6r5ou2d3acao3e4s3onda4r3ucao4z5ida7o6r2eleicao2feicao6oes4ns4re6m6ncia10s7te9s5ida7o6ndo6r3lete6ir5xao6o7es3orcar6o5ma7s3rigerante3ugiados6o2ggae3iao4me6nto4na4oes5nais7l4sto7s6ra8da10s9o10s8r7o8s8u3ra5s4essar7o3ulacao6mentacao10o6r7es7mente2i3naldo4o3s3tor3vindicacoes2jeicao2lacao5ionada11s10o11s9mento14s5oes4ta6do5iva8mente8s7o8s5o6rio9s6s6u4xa6r3embrar4vancia7te9s3igiao6oes7sa9s8o9s3ogio2medio7s3ocao4to4ver5ido2nan4ta5o3da4er5u4imento10s3ovacao6r3uncia2parar3ente4rcussao5torio4te5ir3ito3ort6agem9ns6er3resenta10cao11oes10da11o12s10m10ndo11te13s10r9ou6sao4oducao3ublica9no4tacao2quer4isitos2search4nha4rva7do7s3gatar6e3ide6ncia10l10s7te9s5uos4stencia8te6ir3olucao5ve7r7u6i7do3pectivamente10s9os5ita8do8r7o4ira7cao7r4onda7e8ndo8r8u6sabilidade16s8veis10l5sta8s3salta3ta5nte8s5uracao8nte11s8r4o5s4ricao7oes3ulta7do9s7ndo8te7r6ou4me5indo5o2ta3irada7o6r5o6u3omar4rna7r6o7u3rata6o7s2u3ne4iao5dos5ndo5oes5r6am5u3ters2vela6cao6do6m6ndo6r5ou4r5ter3isao5ta7s3olta5ucao7ionaria13o2y2za4r1ibeirao6o2ca4rdo4s3hard3k3o4s2dicula7o2ght2ndo2o3s2queza7s2r2sco5s3os2ta3mo3uais5l2vais4l3er1oad2b3ert6o6s3in3o4s3son2cha5s3k2da4da4s3ovia7s3rigo6ues2ger5io2la4ndo4r3o2ma4n5a5ce7s5o6s5tica8o3ero3per2n3aldo3da4onia2que2sa4rio4s3e3s3to5s2ta4s3eiro3ina2uba5do5ndo5r4o5s5u3pa5s3sseff2xo2y1ss1ua3s2bro2i3do3m3nas4s2mo4res2n2ptura2rais4l2ssa4ell4ia4o5s2th1yan0sabado6s3e4doria4m5os4ndo4r4s3ia5m4o3or3rina2cerdote3o4s3rificio2em2fada2ga3rada6o2i3a3ba5m3da5s4o3mos3ndo4t3o3r4am3u2l3a4da4o4rial6o7s4s3do3gado3to3va5cao5dor5r4e4o5u2m3ba3paio3sung3uel2n3coes3dra4y3eamento3gue3ta5na5rem4iago4o5s4uario2o2pato6s3o2ra4h4iva3gento3ney2telite3isfacao7zer6eito2udade7s5vel4e4ita2y1bt1chmidt3ool2ott1ea3n3ttle2bastian8o2ca4o4r4s3cao3o3reta7ria9o7s6o7s3tor3ulo6s4ndaria9o2da3e2e2gmento8s3redo7s3ue5m4i5a5da7s6o7res7s5mos5ndo6te8s5r6am5u4nda6o7s4ra6nca9s7do6r6s5o6s2i3o4s3s2ja4m5os2lecao5ionados3o3va5gem7ns2m3ana6is6l6s3elhanca8te10s4nte7s4stre3i4final4nario3pre2na4do6r7a7es4o3do3ha4or6a7s6es3sacao6ional4ibilidade5veis7l4o5res4ual3ta5da6o5r4e5m5nca4i5a5do7s5mento10s6os5ndo5r5u2para6cao6das7o8s6r2quencia5r5stro2r3a4o3ei4m5os4s3gio5pe3ia5m6ente4e5s4o5s3mos3ra3tao3ve5m4ia5ce6o7s5do7r8es5ndo5r5u2ssao4enta4oes2t3e4mbro4nta3imo3or5es2u3s2x3o3ta4o3uais5l6idade6mente3y1hawn2e2opping3rt3w4s1ic2de3o2ga4m3ilo3la3nifica9do9r9tiva13mente13s12o2lencio3va4io2m3bolo7s3ilar7es3on5e3patia7ca8o4les7mente3ultaneamente2n3ais4l3cera7mente6o3dicato9s4rome3gapura4le4ular3o4nimo4pse3ta5m4ese4o5mas2r3ia3va2stema7s7tica2te4s3io5s3uacao6oes5da6o1kate2y3pe1mith2s1oa3res2b3e4rania7o3ra4e5mesa5nome5tudo5vivencia10te12s9r9u4inha7o2ciais5l6ismo8ta4edade9s5ty4o5logia5s3o4rro3rates2fa3ia3re5m5ndo5r6am5u4ido5mento3tware8s2ja2l3ar3dado7s3icitacao8r7ou4da6o6riedade5o4tario3o4s3ta5r4eira7o4o3ucao5ionar5oes2m3a3bra6s3e4nte3os2n3ha5ndo5r4ei4o5s3o4ra3s3y2pa3hia5e2ro4caba3rindo5r5so3te5io3vete2s2taque2u3be5r5sse3sa3th3za2vietica2zinha6o7s1pencer2ort5ing1quare1ra2i1tan4d4ley3r3te4us2ephen3ve5n2f2one3p3re4ies4y2reet4ss2yle1ua3s3ve2b3ida4ndo4r4u3marino4eter6ido3stancia10s5ituicao9do9r8to2cedida7o4ssao6o7r7s3o2dao3este3oeste2ecia2ficiente10mente10s2gere6m5indo6r6u4stao6oes2ica4ida6io3te2ja3eito7s3o2l2ma3iu3mer3o2n2per5ar5ficial9e5ior8es5mercado5ou5visao3orta7r6e4sta7mente6o3rema6o4imentos2r3ge5m4imento5r6am5u3preende10nte10r6sa8s7o3to2s3an3peita8s7o8s5nsa8o7o3tenta8bilidade8r8vel4o1ydney2stem0tabaco3ela2ca2g3s2ilandia3s3wan2ke2l3ento7s3k3vez2manha6o3bem3pa4ouco2nque6s3ta5s4o5s2o2pa3ete2rde3efa6s3ifa2tica6s3uagem7ns2va4res2xa4s3i2ylor1chau1eam3tro2cido6s3lado3nica7mente7s6o7s4ologia10s9ca11s10o11s2d2ixeira2l3a4s3ecomunicacoes4fone8s7ia8ca4movel4visao3hado3l2m3a4s4tica3er3os3peratura11s5stade10s4lo4o5rada9s7l7ria10mente9o5s2nde5m5ncia9s4o3ente3ha5m6os4o3is3s4ao4oes3ta5do5m6os5ndo5r6am5tiva9s5va4e5i4o5u2ologia3ria6s2r3a4o4pia3ca4eira7o8s4o3ei4m5os4sa5ina3ia5m6os3mina7do7l7ndo7r8am6ei6o7u4o5s3ra5s4emoto5no7s5stre4itorial9o10s5veis7l4or6ismo8ta10s4y2sao3e3ouro3ta5mento5r4e5munha10s9o5s2to2u3s2ve2xas3to5s1hat2e3ir3re2iago3ngs3s2omas3r2ree1ia3go2do2gre2juca2m3e4s3or2nha5m6os3ta2o2pica5o3o4s2ra4da5o4m4ndo4r5am3e4i3o4s4teio4u2tular7es5o6s2ve4mos4r5am5em4sse7m1oa3lha2ca4ndo5tins4r3ou2da4s4via4y3o4s2ledo4rancia2m3a4da6s5o4m4ndo4r5a6m4s3e4i4m3my3o4u2na3eladas3s3y2o2p3ico6s3o2que4io2rcedor8es5r4ida3na5do5m5ndo5r6am6ia4e5io4o5u3onto3re5s3ta4ura2tal5idade5mente2ur4o1rabalha8do10r11es8m9os8ndo8r9am8va7ei7ista7o8s8u3cos3dicao6ionais10l11mente6oes4ucao6oes5tor5zido7r3fego4icantes6o3ga4edia4ico4o3icao4ler4r3jetoria3ma3nquila8idade8o4s5ando6r5ferencia8ido9r6orma10cao10do10ndo10r9ou5icao6to5missao9oes7tida10o9r5parencia10te6ortar9e10s5torno3s4eira3ta5da6o7s5m6ento10s5ndo5r5va4e4o5u3uma3z4em5ndo5r4ido2echo6s3inador6mento6r5o6s3m4endo3ns3s3ta3vas3ze2iangulo3bo5s4unais7l5to3color3go3lha6s5os3ndade4ta3o3plo4ulacao3ste6s6za3unfo2oca5ndo5r5s4o5u3feu3nco4o3pa5s4ical3uxe6ram2ue3mp1se1ua3s2barao3o4s2do2mblr3or3ulo2nel2rca4o5s3ismo5tas6ico9s3ma3ne4o3quia2torial1weet5s2itter2o1yler0uau1crania1fc1ltima6mente6s5o6s3ra5passar1ma3s1na3nimidade2der2e3sco2has2iao3ca5s4o5s3da5de7s5s4o5s3forme8s3r3ted3versal7idade12s8taria12o13s9y7o2s1ol1rbana6s5o6s2gencia5te2nas2so2uguai1sa3da5s4o5s3m4os3ndo3r4am3va5m2e3i3m2ina2o3s3u2p2uario7s1teis3ro2il4idade5za7cao7da9s8o9r10es9s7m7ndo7r6ou1va0vaca3ina3uo2dia2ga4s3ina2i3s2le4m4nte4r4u3ida5o3or5es5izacao8r2mos3piro2n3essa3tagem7ns2o2por2ra4nda3gas3ia5cao6oes5das6os5m5r5s5veis7l4edade9s4os2sco3o3ta4o2ticano2z3amento3ia5s4o1cs1eem2gas3etacao6is6l2iculo7s3o2ja4m3o2la4s3ha5s4o5s3ocidade2m3os2nce5dor8a8es5r5u4ido3da5s4e5dor8es5m5ndo5r5u4ida6o7s4o3eno4zuela3ha5m4o3to5s2r3a4o3ba5s4o3dade7ira10mente10s9o10s7s4e5s3eador8es4m5os3gonha3ifica8cao8r6que3melha8s7o8s3sao4o5es5s3tical2spera3te4ibular5do7s5gios5ndo5r2terano8s2z3es1ia3gem5ns3ja5ndo6tes5r4ou3na3s2ce4nte3iado4o3tor6ia2da4s3eo5s3ro2eira3r4am3tna3w2gente3ilancia3or2i2la4o4s3la5ge2m3os2ncent3da5s4o5s3ganca5r3ha5m4o3icius3te2ola5cao5o4encia6ta7o8s2p2r3a4da4m4ndo4o4r3e4i3gem4inia3ia3ou3tuais6l5de3us2sa4ndo4o3ibilidade4ta6ndo7te9s6r6s5e5ou4veis6l3oes3ta5s4o5s3uais5l6izacoes9r2tal3ima6s3or5ia7s2u3va2va4s3e4m5os4ndo4r5am4u3i4a5m4do3o4s2zinha7nca6o7s1ladimir1oa3ndo3r2cabulario4l3e4s2ice2lante3ei5bol3ta5da6o7s5m6os5ndo5r6am5s4e5i4o5u3ume6s4ntaria9o10s2n3tade2o3s2s3sa5s4o5s2tacao4do4r5am3e3o4s4u2u2vo2z3es1ulneravel0wagner2lker3l4ace3t4er2nt2r3s2s3hington2tch3er3son2y3ne1eb3site2sley3t1hat4sapp2en2ite2o1ikipedia2ll4iam7s3son2ndows2th1olf2rd4press3k4shop3ld0xadrez2vier1box1ix1uxa1vi1xi0yang1ear4s1ork2u3ng3r3tube1uri0zagueiro1elandia2ro1ona4s1umbi]==])
-- Escolhe por etapas, sem afirmar que uma lista externa prova aceitação no jogo.
-- Fontes com maior evidência podem superar uma reserva ou uma principal fraca;
-- em empate, mantém a principal à frente. 10+ e PET só influenciam as duas primeiras.
selecionarTentativa = function(termo, modoAtual, prefixoFixo, numero, evitarX, cache)
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
if dic then return 2 end
-- Listas de frequência incluem nomes e abreviações. Se o ENABLE estiver
-- disponível, um item só dessas listas tem menos evidência que um verbete.
if freq then return (#bEN.List > 0 or recuperados[4].pronto) and 1 or 3 end
return 0
end
if comunsPT[w] or bancoPTCurado[w] then return 4 end
if bancos.PT.Set[w] or recuperados[1].Set[w] then return 2 end
return 0
end
local function melhorIdioma(idioma)
local principais
if cache and cache.idioma == idioma and cache.revisao == revisao and cache.bancos == versao
and cache.termo == termo and cache.modo == modoAtual then
principais = cache.lista
else
principais = buscarAlternativas(termo, modoAtual, idioma, prefixoFixo, false, true, true)
end
local candidatos, vistos = {}, {}
local function incluir(lista,reserva)
for i,w in ipairs(lista) do
-- Ceder durante a classificação mantém a interface responsiva em listas amplas.
if i % 3000 == 0 then progressoBusca = os.clock(); task.wait() end
if not vistos[w] and not usedWords[w] and not listaNegra[w]
and encaixaBusca(w,termo,modoAtual,false)
and (prefixoFixo=="" or w:sub(1,#prefixoFixo)==prefixoFixo) then
vistos[w]=true
local categoria=((especial and modoPet == 2) or (not permitidos and numero ~= 3 and numero ~= 5)) and 0 or finalPriorizavel(w,idioma,modoFinais,especial and trioAtivo)
-- Na terceira, um final difícil continua difícil mesmo que a palavra não
-- tenha sido confirmada no ENABLE; confirmação só controla priorização.
if numero == 3 then categoria = categoriaFinal(w, idioma, modoFinais, trioAtivo and permitidos) end
local freq = frequenciaIndependente[idioma][w] or 0
candidatos[#candidatos+1]={w=w,cat=categoria,qualidade=confianca(w,idioma),freq=freq,reserva=reserva,pet=pet(w)}
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
-- Ao rejeitar um X em inglês, procure outro final inglês; se não houver,
-- continua permitido usar X. A regra respeita o grupo 10+ configurado.
if numero < 5 and idioma == "EN" and evitarX and (a.w:sub(-1)=="x")~=(b.w:sub(-1)=="x") then return a.w:sub(-1)~="x" end
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
-- A frequência independente desempata candidatos do mesmo nível em TODAS
-- as fases, sem passar à frente dos finais, PET ou tamanho configurados.
if (#a.w>=4)~=(#b.w>=4) then return #a.w>=4 end
if a.freq~=b.freq then return a.freq>b.freq end
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
or (segundo.qualidade==escolhido.qualidade and segundo.freq>escolhido.freq)
or (segundo.qualidade==escolhido.qualidade and segundo.freq==escolhido.freq and escolhido.reserva and not segundo.reserva)))) then
escolhido,idioma=segundo,preferido=="EN" and "PT" or "EN"
end
-- X e IA (inclusive extensões) dispensam PET/trio: não enviar um possível
-- nome EN só para preservar a preferência de idioma quando há PT mais seguro.
if numero<=2 and not permitidos and preferido=="EN" then
local pt=melhorIdioma("PT")
if pt then
local nivelEN=not primeiro and -1 or (primeiro.qualidade>=4 and 3 or primeiro.qualidade>=2 and 2 or primeiro.qualidade>=1 and 1 or 0)
local nivelPT=pt.qualidade>=4 and 3 or pt.qualidade>=2 and 2 or 0
if nivelPT>nivelEN then escolhido,idioma=pt,"PT" end
end
end
if revisao~=revisaoFiltros or versao~=revisaoBancos or (escolhido and usedWords[escolhido.w]) then return nil,nil,true end
return escolhido and escolhido.w or nil, idioma, false
end

local function runWord(automatico)
if estado.ocupado then return end
-- Se o jogador navegou, comece pela palavra exibida também no automático;
-- as tentativas seguintes continuam seguindo o plano de cinco fases.
local escolhaManual = selecaoManual and sugestaoExibida or nil
local idiomaManual, revManual, bancosManual = idiomaResultados, revisaoFiltros, revisaoBancos
local geracaoManual, buscaManual = geracaoPesquisa, modoBusca
selecaoManual = false
estado.ocupado = true
if not VirtualInputManager then
aviso("Entrada virtual indisponível"); estado.ocupado = false; return
end
local focoInicial = UserInputService:GetFocusedTextBox()
if not focoPermiteJogo(focoInicial) then
aviso(focoInicial == campoExtra and "Feche o campo de final" or "Outro campo em foco; aguardando")
estado.recuperavel = automatico; estado.ocupado = false; return
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
local modoRodada = modoBusca
local originalPrompt = promptText(label)
if originalPrompt and originalPrompt ~= termo then
aviso("Início mudou; revise antes de enviar"); estado.recuperavel = automatico; estado.ocupado = false; return
end
local inicial = readSlots(keys)
local prefixoInicial = ""
if inicial and inicial ~= "" then
-- Em CONTÉM, a sequência pedida pode estar no meio; não é possível inferir
-- dela quantas letras do campo são protegidas. Preserve o campo inicial.
if modoRodada == "CONTEM" then prefixoInicial = inicial
elseif #inicial <= #termo and termo:sub(1, #inicial) == inicial then prefixoInicial = inicial
elseif #inicial > #termo and inicial:sub(1, #termo) == termo then prefixoInicial = termo end
end
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
return gui.Parent ~= nil and focoPermiteJogo(UserInputService:GetFocusedTextBox()) and token == estado.token and l == label and k == keys
and modoBusca == modoRodada and (inputBox.Text or ""):lower():gsub("%s", "") == termo
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
if escolhaManual and revManual == revisaoFiltros and bancosManual == revisaoBancos
and geracaoManual == geracaoPesquisa and buscaManual == modoBusca
and ultimoTermoPesquisado == termo and not usedWords[escolhaManual]
and escolhaManual:sub(1, #prefixoInicial) == prefixoInicial
and encaixaBusca(escolhaManual, termo, modoBusca, currentRelaxado) then
palavra, idiomaTentativa = escolhaManual, idiomaManual
reservada, idiomaReservado = nil, nil
elseif reservada then
palavra, idiomaTentativa = reservada, idiomaReservado
reservada, idiomaReservado = nil, nil
else
local mudou
-- Um campo já parcialmente preenchido restringe só a primeira escolha.
-- Após uma rejeição, voltar ao prefixo protegido da rodada.
local prefixoBusca = prefixoInicial
local textoInicial = tentativas == 0 and readSlots(keys) or nil
if textoInicial and #textoInicial > #prefixoBusca and textoInicial:sub(1, #prefixoBusca) == prefixoBusca then prefixoBusca = textoInicial end
palavra, idiomaTentativa, mudou = selecionarTentativa(termo, modoBusca, prefixoBusca, estado.tentativasRodada + 1, config.alternarX and evitarProximoX)
if mudou then aviso("Prioridade mudou; revisando"); estado.recuperavel = automatico; break end

end
escolhaManual = nil
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
sugestaoExibida = palavra
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
-- Cada Enter autorizado conta para o limite, inclusive se houver cancelamento
-- ou falha depois de o jogo poder ter recebido a tecla.
estado.tentativasRodada = estado.tentativasRodada + 1
estado.ultimoEnterVirtual = os.clock()
if not key(Enum.KeyCode.Return) then
-- O pressionamento pode ter chegado ao jogo antes de ocorrer a falha.
-- Memorizar conservadoramente e não tentar outra palavra às cegas.
memorizarEnvio(palavra)
estado.recuperavel = false
estado.envioComFalha = true
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
if resultado == "cancelado" then
aviso("Resposta incerta; parado")
estado.recuperavel = false
break
end
if resultado == "mudou" then
aviso("Campo mudou; confira aceitação")
break
end
if resultado == "incerto" then aviso("Resposta incerta; parado"); break end
tentativas = tentativas + 1
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
local proxima, proximoIdioma, mudou = selecionarTentativa(termo, modoBusca, prefixoInicial, estado.tentativasRodada + 1, config.alternarX and evitarProximoX)
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
autoBtn.MouseButton1Click:Connect(function()
if not estado.ocupado then liberarConferencia() end
task.spawn(executarComSeguranca, false)
end)
-- Estados de aceitação/apagamento incertos exigem ação explícita, não watchdog.
local function exigeConferencia()
return estado.bloqueioSeguranca ~= nil or bloqueiosSeguranca[estado.status] == true
or estado.tentativasRodada >= config.maxTentativas
end
local function agendarAutomatico(letra, label, keys)
if exigeConferencia() then return end
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
if not gui.Parent or not config.automatico or exigeConferencia() or tokenAgendado ~= estado.token or geracaoAgendada ~= estado.geracao then return end
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
local function candidatoParaRecuperacao(letra, campo)
if not campo then return nil end
local guardada = estado.candidatoRecuperacao
if guardada and not usedWords[guardada] and finalPermitido(guardada, currentRelaxado)
and encaixaBusca(guardada, letra, modoBusca, currentRelaxado) and guardada:sub(1, #campo) == campo then return guardada, estado.idiomaRecuperacao end
local candidato, idioma, mudou = selecionarTentativa(letra, modoBusca, campo, estado.tentativasRodada + 1, false)
if not mudou then return candidato, idioma end
return nil
end
local function tentarRecuperacao(letra, label, keys)
if config.automatico and estado.recuperavel and estado.recuperacoes < 2 and not exigeConferencia()
and letra and inputBox.Text:lower() == letra and ultimoTermoPesquisado == letra then
local tokenAntes, geracaoAntes, modoAntes = estado.token, estado.geracao, modoBusca
local campo = readSlots(keys)
local candidato, idiomaCandidato = candidatoParaRecuperacao(letra, campo)
if tokenAntes ~= estado.token or geracaoAntes ~= estado.geracao or modoAntes ~= modoBusca
or not config.automatico or not estado.recuperavel or estado.ocupado or exigeConferencia() or ultimoTermoPesquisado ~= letra
or inputBox.Text:lower() ~= letra or readSlots(keys) ~= campo then return end
if candidato and not usedWords[candidato] and encaixaBusca(candidato, letra, modoBusca, currentRelaxado)
and campo and candidato:sub(1, #campo) == campo then
estado.candidatoRecuperacao, estado.idiomaRecuperacao = candidato, idiomaCandidato
estado.recuperavel = false
estado.rodada = letra
estado.recuperacoes = estado.recuperacoes + 1
local tokenRec = estado.token
local geracaoRec = estado.geracao
task.delay(0.6, function()
local l, k = getParts()
if gui.Parent and config.automatico and not estado.ocupado and not exigeConferencia() and tokenRec == estado.token
and geracaoRec == estado.geracao and l == label and k == keys
and readSlots(keys) == campo and not usedWords[candidato]
and ultimoTermoPesquisado == letra then
executarComSeguranca(true)
end
end)
end
end
end
-- Compartilhado com o monitor para que VER confirme também sinais sem prompt.
local ultimaSinalMonitor = nil
revisarBtn.MouseButton1Click:Connect(function()
if estado.ocupado then aviso("Aguarde a tentativa atual"); return end
local label, keys = getParts()
local sinal = label and keys and detect(label, keys) or nil
local termo = sinal or (inputBox.Text or ""):lower():gsub("%s", "")
if termo == "" then aviso("Sem início para revisar"); return end
-- Não atualizar o sinal do monitor aqui: ele ainda precisa reconhecer uma
-- rodada diferente e ajustar a contagem, inclusive sem prompt explícito.
liberarConferencia()
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
if exigeConferencia() then return end
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
local tokenAntes, geracaoAntes, modoAntes = estado.token, estado.geracao, modoBusca
local candidato = candidatoParaRecuperacao(letra, campo)
if tokenAntes ~= estado.token or geracaoAntes ~= estado.geracao or modoAntes ~= modoBusca
or not config.automatico or estado.ocupado or exigeConferencia() or ultimoTermoPesquisado ~= letra
or inputBox.Text:lower() ~= letra or readSlots(keys) ~= campo then return end
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
-- Detecção de sinais da Bomb original: só ignora palavra já enviada que
-- ainda esteja visível nos slots; não bloqueia toda mudança sem prompt.
local function preservarSinalAnterior(letra, ultima, label)
if not promptText(label) and ultima then
-- Só preserve o sinal na situação específica de apagamento não confirmado:
-- os slots podem conter uma palavra parcialmente apagada, não um desafio.
local bloqueio = estado.bloqueioSeguranca or estado.status
if estado.envioComFalha or bloqueio == "Apagar não confirmado; parado" or bloqueio == "Campo mudou; parado" then return ultima end
if letra and letra ~= ultima and usedWords[letra] then return ultima end
end
return letra
end
local sinalAntesDaAusencia = nil
local function monitorarRodada()
local label, keys = getParts()
if label and keys then
local letra = preservarSinalAnterior(detect(label, keys), ultimaSinalMonitor, label)
local parcial = estado.candidatoRecuperacao
if estado.recuperavel and not promptText(label) and ultimaSinalMonitor and letra and parcial
and #letra > #ultimaSinalMonitor and letra:sub(1, #ultimaSinalMonitor) == ultimaSinalMonitor
and parcial:sub(1, #letra) == letra then letra = ultimaSinalMonitor end
if not letra and ultimaSinalMonitor then
sinalAntesDaAusencia = ultimaSinalMonitor
ultimaSinalMonitor = nil
estado.geracao = estado.geracao + 1
estado.rodada = nil
end
if letra and letra ~= ultimaSinalMonitor then
-- Publique o sinal antes de concluir a transição; se escrever no painel
-- falhar, o monitor tenta novamente sem dar o sinal como já processado.
if inputBox.Text ~= letra then inputBox.Text = letra end
-- Como na Bomb, um sinal diferente nos slots é tratado como outra rodada.
-- Após ausência temporária, o mesmo sinal não prova uma rodada nova.
local novaComprovada = ultimaSinalMonitor ~= nil
or (sinalAntesDaAusencia ~= nil and sinalAntesDaAusencia ~= letra)
if novaComprovada and exigeConferencia() then liberarConferencia(); aviso("Nova rodada detectada") end
estado.geracao = estado.geracao + 1
ultimaSinalMonitor = letra
sinalAntesDaAusencia = nil
if novaComprovada or estado.tentativasRodada == 0 then
estado.inglesRejeitadas = 0; estado.portuguesAteFim = false; estado.errosDificeis = 0; estado.finaisSuspensos = false; estado.tentativasRodada = 0; estado.recuperavel = false; estado.recuperacoes = 0; estado.candidatoRecuperacao = nil; estado.idiomaRecuperacao = nil
end
estado.rodada = nil
end
tentarRecuperacao(letra, label, keys)
verificarInatividade(letra, label, keys)
if config.automatico and letra and estado.rodada ~= letra then
estado.rodada = letra
agendarAutomatico(letra, label, keys)
end
else
if ultimaSinalMonitor then
sinalAntesDaAusencia = ultimaSinalMonitor
estado.geracao = estado.geracao + 1
end
ultimaSinalMonitor = nil; estado.rodada = nil
end
end
task.spawn(function()
while gui.Parent do
task.wait(0.15)
if not estado.ocupado then
local ok, erro = pcall(monitorarRodada)
if not ok then
-- Erros transitórios não podem matar o monitor permanentemente.
estado.token = estado.token + 1
estado.rodada = nil
aviso("Monitor aguardando interface")
warn("Word System: erro no monitor; tentando novamente:", erro)
task.wait(0.85)
elseif estado.status == "Monitor aguardando interface" then
aviso("Monitor recuperado")
end
end
end
end)
end, function(erro) return tostring(erro) end)
if not iniciou then
-- Não deixar tarefas ou um painel parcialmente montado ativos após erro.
pcall(function() if guiInicializando then guiInicializando:Destroy() end end)
cancelarDownloads()
desconectarGlobais()
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
