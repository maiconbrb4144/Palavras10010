local painelInicial
local iniciouAuditoria,erroAuditoria=xpcall(function()
local PlayersUnificado=game:GetService("Players")
local UISUnificado=game:GetService("UserInputService")
local donoLocal=PlayersUnificado.LocalPlayer
assert(donoLocal,"Execute no cliente.")
local raizGui=donoLocal:FindFirstChildOfClass("PlayerGui") or donoLocal:WaitForChild("PlayerGui",10)
assert(raizGui,"PlayerGui indisponível.")
local destinoPreferido,coreGui
pcall(function() if type(gethui)=="function" then destinoPreferido=gethui() end end)
pcall(function() coreGui=game:GetService("CoreGui") end)
local destinos,visitados={},{}
local function adicionarDestino(raiz)
if raiz and not visitados[raiz] then visitados[raiz]=true;destinos[#destinos+1]=raiz end
end
adicionarDestino(destinoPreferido);adicionarDestino(coreGui);adicionarDestino(raizGui)
for _,raiz in ipairs(destinos) do
pcall(function()
for _,nome in ipairs({"AuditoriaUnificada","DiagnosticoLocalInterfacePainel","AuditoriaRemotosPrivado"}) do
local anterior=raiz:FindFirstChild(nome)
if anterior and anterior:IsA("ScreenGui") then anterior:Destroy() end
end
end)
end
local function criarUnificado(tipo,props,pai)
local o=Instance.new(tipo);for k,v in pairs(props or {}) do o[k]=v end;o.Parent=pai;return o
end
local function arredondar(o) criarUnificado("UICorner",{CornerRadius=UDim.new(0,7)},o) end
local cinza=Color3.fromRGB
local sharedGui=criarUnificado("ScreenGui",{Name="AuditoriaUnificada",ResetOnSpawn=false,Enabled=true,DisplayOrder=999999,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},nil)
painelInicial=sharedGui
local paiAceito=false
for _,destino in ipairs(destinos) do
local ok=pcall(function() sharedGui.Parent=destino end)
if ok and sharedGui.Parent==destino then paiAceito=true;break end
end
assert(paiAceito,"Não foi possível mostrar a interface em gethui, CoreGui ou PlayerGui.")
local shell=criarUnificado("Frame",{Name="PainelUnico",Size=UDim2.new(.92,0,.86,0),Position=UDim2.new(.5,0,.5,0),AnchorPoint=Vector2.new(.5,.5),BackgroundColor3=cinza(22,28,38),BorderSizePixel=0},sharedGui);arredondar(shell)
local shellRestricao=criarUnificado("UISizeConstraint",{MinSize=Vector2.new(280,200),MaxSize=Vector2.new(760,800)},shell)
local barra=criarUnificado("TextLabel",{Name="Titulo",Position=UDim2.new(0,12,0,3),Size=UDim2.new(1,-96,0,37),BackgroundTransparency=1,Active=true,Text="☰  AUDITORIA UNIFICADA",TextXAlignment=Enum.TextXAlignment.Left,TextColor3=cinza(240,245,252),Font=Enum.Font.GothamBold,TextSize=14},shell)
local function botaoUnificado(nome,texto,pos,tam,pai)
local b=criarUnificado("TextButton",{Name=nome,Position=pos,Size=tam,Text=texto,Font=Enum.Font.GothamBold,TextSize=12,TextColor3=cinza(245,248,252),BackgroundColor3=cinza(53,67,86),BorderSizePixel=0},pai);arredondar(b);return b
end
local fecharUnificado=botaoUnificado("Fechar","×",UDim2.new(1,-40,0,6),UDim2.new(0,32,0,30),shell)
local minimoUnificado=botaoUnificado("Minimizar","−",UDim2.new(1,-78,0,6),UDim2.new(0,32,0,30),shell)
local navegacao=criarUnificado("Frame",{Name="Navegacao",Position=UDim2.new(0,8,0,43),Size=UDim2.new(1,-16,0,32),BackgroundTransparency=1},shell)
local abaPartida=botaoUnificado("Partida","PARTIDA",UDim2.new(0,0,0,0),UDim2.new(.33,-3,1,0),navegacao)
local abaRemotos=botaoUnificado("Remotos","REMOTOS",UDim2.new(.33,2,0,0),UDim2.new(.34,-4,1,0),navegacao)
local abaRelatorio=botaoUnificado("Relatorio","RELATÓRIO",UDim2.new(.67,1,0,0),UDim2.new(.33,-1,1,0),navegacao)
local acoes=criarUnificado("Frame",{Name="Acoes",Position=UDim2.new(0,8,0,79),Size=UDim2.new(1,-16,0,32),BackgroundTransparency=1},shell)
local atualizarTudo=botaoUnificado("AtualizarTudo","ATUALIZAR RELATÓRIO",UDim2.new(0,0,0,0),UDim2.new(.5,-3,1,0),acoes)
local copiarTudo=botaoUnificado("CopiarTudo","COPIAR TUDO",UDim2.new(.5,2,0,0),UDim2.new(.5,-2,1,0),acoes)
local statusGeral=criarUnificado("TextLabel",{Name="Status",Position=UDim2.new(0,10,0,113),Size=UDim2.new(1,-20,0,26),BackgroundTransparency=1,Text="Monitor ativo. Prepare o relatório quando terminar.",TextColor3=cinza(192,211,224),Font=Enum.Font.Gotham,TextSize=11,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left},shell)
local corpo=criarUnificado("ScrollingFrame",{Name="Corpo",Position=UDim2.new(0,5,0,140),Size=UDim2.new(1,-10,1,-146),BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(0,0,0,380),ScrollingDirection=Enum.ScrollingDirection.Y,ScrollBarThickness=5},shell)
local corpoPartida=criarUnificado("Frame",{Name="CorpoPartida",Size=UDim2.new(1,-6,0,380),BackgroundTransparency=1},corpo)
local corpoRemotos=criarUnificado("Frame",{Name="CorpoRemotos",Size=UDim2.new(1,-6,0,380),BackgroundTransparency=1,Visible=false},corpo)
local corpoRelatorio=criarUnificado("ScrollingFrame",{Name="CorpoRelatorio",Size=UDim2.new(1,-6,0,380),BackgroundColor3=cinza(15,20,28),BorderSizePixel=0,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y,ScrollBarThickness=6,Visible=false},corpo);arredondar(corpoRelatorio)
local function ajustarArea()
local h=corpo.AbsoluteSize and corpo.AbsoluteSize.Y or 0
local altura=math.max(380,h)
corpoPartida.Size=UDim2.new(1,-6,0,altura);corpoRemotos.Size=UDim2.new(1,-6,0,altura);corpoRelatorio.Size=UDim2.new(1,-6,0,altura)
corpo.CanvasSize=UDim2.new(0,0,0,altura)
end
corpo:GetPropertyChangedSignal("AbsoluteSize"):Connect(ajustarArea);ajustarArea()
local relatorioCompleto=criarUnificado("TextBox",{Name="TextoUnificado",Position=UDim2.new(0,6,0,6),Size=UDim2.new(1,-18,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,ClearTextOnFocus=false,MultiLine=true,TextEditable=true,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,Font=Enum.Font.Code,TextSize=12,TextColor3=cinza(226,233,241),Text="Ao terminar, toque em COPIAR TUDO. Revise o relatório antes de compartilhá-lo."},corpoRelatorio)
local exportarMonitor,exportarRemotos,refreshPartida
local abaGeral="partida";local unificadoMinimizado=false;local snapshotGerado=false
local function mudarAbaGeral(aba)
if aba~="relatorio" then snapshotGerado=false end
abaGeral=aba;corpoPartida.Visible=aba=="partida";corpoRemotos.Visible=aba=="remotos";corpoRelatorio.Visible=aba=="relatorio"
abaPartida.BackgroundColor3=aba=="partida" and cinza(48,105,129) or cinza(53,67,86)
abaRemotos.BackgroundColor3=aba=="remotos" and cinza(48,105,129) or cinza(53,67,86)
abaRelatorio.BackgroundColor3=aba=="relatorio" and cinza(48,105,129) or cinza(53,67,86)
if aba=="partida" and refreshPartida then refreshPartida() end
end
abaPartida.MouseButton1Click:Connect(function() mudarAbaGeral("partida") end)
abaRemotos.MouseButton1Click:Connect(function() mudarAbaGeral("remotos") end)
abaRelatorio.MouseButton1Click:Connect(function() mudarAbaGeral("relatorio") end)
local function prepararRelatorio()
local partes={"RELATÓRIO UNIFICADO — REVISE ANTES DE COMPARTILHAR","Captura do que já foi observado até agora; dados podem estar incompletos.","Não comprova vulnerabilidades nem acesso a arquivos exclusivos do servidor."}
local ok1,t1=pcall(function() return exportarMonitor and exportarMonitor() or "Monitor indisponível." end)
local ok2,t2=pcall(function() return exportarRemotos and exportarRemotos() or "Testador indisponível." end)
partes[#partes+1]="\n===== PARTIDA, INTERFACE E AUDITORIA =====\n"..(ok1 and tostring(t1) or "Falha ao montar seção da partida.")
partes[#partes+1]="\n===== REMOTOS E TESTES MANUAIS =====\n"..(ok2 and tostring(t2) or "Falha ao montar seção de remotos.")
relatorioCompleto.Text=table.concat(partes,"\n");snapshotGerado=true;mudarAbaGeral("relatorio")
statusGeral.Text="Relatório preparado. Revise e toque em COPIAR TUDO novamente."
end
atualizarTudo.MouseButton1Click:Connect(prepararRelatorio)
copiarTudo.MouseButton1Click:Connect(function()
if not snapshotGerado then prepararRelatorio();return end
mudarAbaGeral("relatorio")
local ok,retorno=false,nil
if type(setclipboard)=="function" then ok,retorno=pcall(setclipboard,relatorioCompleto.Text) end
if ok and retorno~=false then statusGeral.Text="Cópia solicitada. Confira ao colar e revise antes de enviar."
else relatorioCompleto:CaptureFocus();relatorioCompleto.CursorPosition=#relatorioCompleto.Text+1;relatorioCompleto.SelectionStart=1;statusGeral.Text="Cópia automática falhou. Copie o texto selecionado no aparelho." end
end)
local abertoUnificado
minimoUnificado.MouseButton1Click:Connect(function()
if not unificadoMinimizado then
abertoUnificado=shell.Size;navegacao.Visible=false;acoes.Visible=false;statusGeral.Visible=false;corpo.Visible=false
shellRestricao.MinSize=Vector2.new(200,46);shell.Size=UDim2.new(0,240,0,46);minimoUnificado.Text="+";unificadoMinimizado=true
else
shellRestricao.MinSize=Vector2.new(280,200);shell.Size=abertoUnificado;navegacao.Visible=true;acoes.Visible=true;statusGeral.Visible=true;corpo.Visible=true
minimoUnificado.Text="−";unificadoMinimizado=false;mudarAbaGeral(abaGeral)
task.spawn(function()
task.wait()
if unificadoMinimizado or not sharedGui.Parent then return end
local camera=workspace.CurrentCamera
local pos=shell.AbsolutePosition;local tam=shell.AbsoluteSize
if camera and pos and tam then
local tela=camera.ViewportSize
local x=math.clamp(pos.X,0,math.max(0,tela.X-tam.X));local y=math.clamp(pos.Y,0,math.max(0,tela.Y-tam.Y))
local atual=shell.Position
shell.Position=UDim2.new(atual.X.Scale,atual.X.Offset+x-pos.X,atual.Y.Scale,atual.Y.Offset+y-pos.Y)
end
end)
end
end)
local movendo,entradaMovimento,inicioMovimento,posInicial,absInicial=false,nil,nil,nil,nil;local mudou
barra.InputBegan:Connect(function(i)
if i.UserInputType~=Enum.UserInputType.MouseButton1 and i.UserInputType~=Enum.UserInputType.Touch then return end
movendo=true;inicioMovimento=i.Position;posInicial=shell.Position;absInicial=shell.AbsolutePosition
if mudou then mudou:Disconnect() end
mudou=i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then movendo=false;entradaMovimento=nil end end)
if i.UserInputType==Enum.UserInputType.Touch then entradaMovimento=i end
end)
barra.InputChanged:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then entradaMovimento=i end end)
local conMov=UISUnificado.InputChanged:Connect(function(i)
if not movendo or i~=entradaMovimento or not sharedGui.Parent then return end
local delta=i.Position-inicioMovimento;local dx,dy=delta.X,delta.Y;local cam=workspace.CurrentCamera
if cam and absInicial and shell.AbsoluteSize then local v=cam.ViewportSize;dx=math.clamp(absInicial.X+dx,0,math.max(0,v.X-shell.AbsoluteSize.X))-absInicial.X;dy=math.clamp(absInicial.Y+dy,0,math.max(0,v.Y-shell.AbsoluteSize.Y))-absInicial.Y end
shell.Position=UDim2.new(posInicial.X.Scale,posInicial.X.Offset+dx,posInicial.Y.Scale,posInicial.Y.Offset+dy)
end)
sharedGui.Destroying:Connect(function() conMov:Disconnect();if mudou then mudou:Disconnect() end end)
fecharUnificado.MouseButton1Click:Connect(function() sharedGui:Destroy() end)
local okMonitor,erroMonitor=pcall(function()
local Players=game:GetService("Players")
local UserInputService=game:GetService("UserInputService")
local localPlayer=Players.LocalPlayer
if not localPlayer then error("Execute no cliente: LocalPlayer não está disponível.") end
local playerGui=localPlayer:FindFirstChildOfClass("PlayerGui") or localPlayer:WaitForChild("PlayerGui",10)
if not playerGui then error("PlayerGui não ficou disponível.") end
local NOME="DiagnosticoLocalInterfacePainel"
local antigo=playerGui:FindFirstChild(NOME)
if antigo and antigo:IsA("ScreenGui") then antigo:Destroy() end
local LIMITES={visitados=12000,textos=600,visibilidade=600,iniciais=300,eventos=700,arvore=3500,texto=180,caracteres=160000}
local duracoes={60,120,180,300,600,0}
local duracaoIndice=#duracoes
local sessao,contadorSessao,ultimoRelatorio=nil,0,""
local abaAtual="registro"
local atualizarArvore,atualizarAuditoria,atualizar
local palavrasSensiveis={"chat","password","senha","token","secret","apikey","api_key","credential","private","mensagem","message"}
local function criar(classe,propriedades,pai)
local item=Instance.new(classe)
for chave,valor in pairs(propriedades or {}) do item[chave]=valor end
if pai then item.Parent=pai end
return item
end
local function canto(pai,raio)
criar("UICorner",{CornerRadius=UDim.new(0,raio or 7)},pai)
end
local gui=sharedGui
local janela=criar("Frame",{Name="Janela",Size=UDim2.new(1,0,1,0),Position=UDim2.new(0.5,0,0.5,0),AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=Color3.fromRGB(24,29,39),BorderSizePixel=0},corpoPartida)
canto(janela,12)
local restricao=criar("UISizeConstraint",{MaxSize=Vector2.new(3000,3000),MinSize=Vector2.new(0,0)},janela)
local cabecalho=criar("TextLabel",{Name="Titulo",Size=UDim2.new(1,-98,0,42),Position=UDim2.new(0,14,0,2),BackgroundTransparency=1,Active=true,Text="☰  DIAGNÓSTICO LOCAL",Font=Enum.Font.GothamBold,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left,TextColor3=Color3.fromRGB(235,241,250)},janela)
local function botao(nome,texto,x,largura,pai)
local b=criar("TextButton",{Name=nome,Size=UDim2.new(largura,-4,1,0),Position=UDim2.new(x,2,0,0),BackgroundColor3=Color3.fromRGB(53,67,86),BorderSizePixel=0,Text=texto,Font=Enum.Font.GothamBold,TextSize=13,TextColor3=Color3.fromRGB(244,248,255),AutoButtonColor=true},pai)
canto(b,6); return b
end
local fechar=criar("TextButton",{Name="Fechar",Text="×",Font=Enum.Font.GothamBold,TextSize=23,TextColor3=Color3.fromRGB(245,245,245),BackgroundColor3=Color3.fromRGB(123,63,69),BorderSizePixel=0,Size=UDim2.new(0,34,0,30),Position=UDim2.new(1,-42,0,8)},janela)
canto(fechar,6)
local minimizar=criar("TextButton",{Name="Minimizar",Text="−",Font=Enum.Font.GothamBold,TextSize=22,TextColor3=Color3.fromRGB(245,245,245),BackgroundColor3=Color3.fromRGB(53,67,86),BorderSizePixel=0,Size=UDim2.new(0,34,0,30),Position=UDim2.new(1,-82,0,8)},janela)
canto(minimizar,6)
local linha1=criar("Frame",{Name="Controles",BackgroundTransparency=1,Position=UDim2.new(0,10,0,46),Size=UDim2.new(1,-20,0,34)},janela)
local iniciar=botao("Iniciar","INICIAR",0,.34,linha1)
local parar=botao("Parar","PARAR",.34,.33,linha1)
local tempo=botao("Tempo","ATÉ PARAR",.67,.33,linha1)
local linha2=criar("Frame",{Name="Copia",BackgroundTransparency=1,Position=UDim2.new(0,10,0,85),Size=UDim2.new(1,-20,0,34)},janela)
local copiar=botao("Copiar","COPIAR",0,.34,linha2)
local selecionar=botao("Selecionar","SELECIONAR",.34,.33,linha2)
local limpar=botao("Limpar","LIMPAR PARTIDA",0,1,linha2)
copiar.Visible=false;selecionar.Visible=false
local estado=criar("TextLabel",{Name="Estado",Position=UDim2.new(0,12,0,125),Size=UDim2.new(1,-24,0,36),BackgroundTransparency=1,Text="Pronto. Inicie e jogue uma rodada.",TextColor3=Color3.fromRGB(177,210,231),Font=Enum.Font.Gotham,TextSize=12,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left},janela)
local linhaAbas=criar("Frame",{Name="Abas",BackgroundTransparency=1,Position=UDim2.new(0,10,0,163),Size=UDim2.new(1,-20,0,32)},janela)
local botaoRegistro=botao("Registro","REGISTRO",0,.34,linhaAbas)
local botaoArvore=botao("Arvore","INTERFACE",.34,.33,linhaAbas)
local botaoAuditoria=botao("Auditoria","AUDITORIA",.67,.33,linhaAbas)
local filtro=criar("TextBox",{Name="Filtro",Position=UDim2.new(0,10,0,199),Size=UDim2.new(1,-20,0,32),BackgroundColor3=Color3.fromRGB(42,52,67),BorderSizePixel=0,Text="",PlaceholderText="Filtrar árvore por nome, caminho ou classe...",PlaceholderColor3=Color3.fromRGB(160,170,183),TextColor3=Color3.fromRGB(240,244,250),Font=Enum.Font.Gotham,TextSize=13,ClearTextOnFocus=false,Visible=false},janela)
canto(filtro,6)
local rolagem=criar("ScrollingFrame",{Name="AreaRelatorio",Position=UDim2.new(0,10,0,235),Size=UDim2.new(1,-20,1,-279),BackgroundColor3=Color3.fromRGB(15,20,28),BorderSizePixel=0,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y,ScrollBarThickness=6},janela)
canto(rolagem,6)
local caixa=criar("TextBox",{Name="Relatorio",Position=UDim2.new(0,6,0,6),Size=UDim2.new(1,-18,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Text="O relatório aparecerá aqui.\n\nToque em INICIAR e jogue uma rodada.\nDepois, toque em COPIAR ou SELECIONAR.",ClearTextOnFocus=false,MultiLine=true,TextEditable=true,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,Font=Enum.Font.Code,TextSize=13,TextColor3=Color3.fromRGB(223,232,239),PlaceholderText="Relatório",TextTruncate=Enum.TextTruncate.None},rolagem)
local caixaArvore=criar("TextBox",{Name="ArvoreTexto",Position=UDim2.new(0,6,0,6),Size=UDim2.new(1,-18,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Text="Inicie uma análise para construir a árvore local.",ClearTextOnFocus=false,MultiLine=true,TextEditable=true,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,Font=Enum.Font.Code,TextSize=13,TextColor3=Color3.fromRGB(223,232,239),Visible=false},rolagem)
local caixaAuditoria=criar("TextBox",{Name="AuditoriaTexto",Position=UDim2.new(0,6,0,6),Size=UDim2.new(1,-18,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Text="Inicie para inspecionar objetos visíveis ao cliente.",ClearTextOnFocus=false,MultiLine=true,TextEditable=true,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,Font=Enum.Font.Code,TextSize=13,TextColor3=Color3.fromRGB(223,232,239),Visible=false},rolagem)
local function mudarAba(aba)
abaAtual=aba; caixa.Visible=aba=="registro"; caixaArvore.Visible=aba=="arvore"; caixaAuditoria.Visible=aba=="auditoria"; filtro.Visible=aba~="registro"
botaoRegistro.BackgroundColor3=aba=="registro" and Color3.fromRGB(48,105,129) or Color3.fromRGB(53,67,86)
botaoArvore.BackgroundColor3=aba=="arvore" and Color3.fromRGB(48,105,129) or Color3.fromRGB(53,67,86)
botaoAuditoria.BackgroundColor3=aba=="auditoria" and Color3.fromRGB(48,105,129) or Color3.fromRGB(53,67,86)
if aba=="arvore" and atualizarArvore then atualizarArvore() end
if aba=="auditoria" and atualizarAuditoria then atualizarAuditoria() end
rolagem.CanvasPosition=Vector2.new(0,0)
end
botaoRegistro.MouseButton1Click:Connect(function() mudarAba("registro") end)
botaoArvore.MouseButton1Click:Connect(function() mudarAba("arvore") end)
botaoAuditoria.MouseButton1Click:Connect(function() mudarAba("auditoria") end)
local aviso=criar("TextLabel",{Name="Aviso",Position=UDim2.new(0,12,1,-39),Size=UDim2.new(1,-24,0,31),BackgroundTransparency=1,Text="Revise dados pessoais antes de enviar. Só interface local.",TextColor3=Color3.fromRGB(189,193,200),Font=Enum.Font.Gotham,TextSize=11,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left},janela)
fechar.Visible=false;minimizar.Visible=false;cabecalho.Active=false
local recolhido=false
local function desconectar(s)
for c in pairs(s.conexoes) do pcall(function() c:Disconnect() end) end
s.conexoes={}; s.porObjeto={}; s.observados={}; s.ultimoTimer={}
if s.audit then s.audit.conexoes={};s.audit.prioridadeConexao={};s.audit.ouvindo=0;s.audit.interrompida=true;s.audit.finalizado=true;s.audit.sujo=true end
end
local function nomesJogadores()
local nomes={}
local ok,lista=pcall(function() return Players:GetPlayers() end)
if ok then
local unicos={}
for _,p in ipairs(lista) do
for _,nome in ipairs({p.Name,p.DisplayName}) do
if type(nome)=="string" and #nome >=3 and not unicos[nome] then
unicos[nome]=true; nomes[#nomes+1]=nome
end
end
end
end
table.sort(nomes,function(a,b) return #a>#b end)
return nomes
end
local function limparTexto(s,valor)
local texto=tostring(valor or ""):gsub("[%c]"," ")
for _,nome in ipairs(s.nomes) do
local escaped=nome:gsub("([^%w])","%%%1")
texto=texto:gsub(escaped,"[jogador]")
end
if #texto > LIMITES.texto then texto=texto:sub(1,LIMITES.texto).."..." end
return texto
end
local function sensivel(valor)
local texto=tostring(valor or ""):lower():gsub("%s+","")
for _,palavra in ipairs(palavrasSensiveis) do
if texto:find(palavra,1,true) then return true end
end
return false
end
local function caminho(s,objeto)
local partes,atual,profundidade={},objeto,0
while atual and atual~=playerGui and profundidade<30 do
table.insert(partes,1,limparTexto(s,atual.Name)); atual=atual.Parent; profundidade+=1
end
return "PlayerGui/"..table.concat(partes,"/")
end
local function permitido(objeto)
local atual,profundidade=objeto,0
while atual and atual~=playerGui and profundidade<30 do
if atual==gui or (atual:IsA("ScreenGui") and atual.Name=="AuditoriaRemotosPrivado") or sensivel(atual.Name) then return false end
atual=atual.Parent; profundidade+=1
end
return atual==playerGui
end
local function visivel(objeto)
local atual,profundidade=objeto,0
while atual and atual~=playerGui and profundidade<30 do
if atual:IsA("GuiObject") and not atual.Visible then return "oculto" end
if atual:IsA("LayerCollector") and not atual.Enabled then return "oculto" end
atual=atual.Parent; profundidade+=1
end
return "visível"
end
local function guardarLinha(s,resultado,inicial)
if not s.ativo then return end
local tamanho=#resultado+1
if inicial then
if s.caracteresIniciais+tamanho>35000 then s.limiteIniciais=true; return end
s.iniciais+=1; s.caracteresIniciais+=tamanho; s.caracteres+=tamanho
s.linhas[#s.linhas+1]=resultado
else
while s.eventosGuardados>0 and (s.eventosGuardados>=LIMITES.eventos or s.caracteres+tamanho>LIMITES.caracteres) do
local antigo=s.filaEventos[s.inicioFila]
s.filaEventos[s.inicioFila]=nil
s.inicioFila=s.inicioFila%LIMITES.eventos+1
s.eventosGuardados-=1; s.eventosDescartados+=1; s.caracteres-=#antigo+1
end
if s.caracteres+tamanho>LIMITES.caracteres then s.limiteCaracteres=true; return end
local pos=(s.inicioFila+s.eventosGuardados-1)%LIMITES.eventos+1
s.filaEventos[pos]=resultado; s.eventosGuardados+=1; s.eventos+=1; s.caracteres+=tamanho
end
s.sujo=true
end
local function linha(s,objeto,motivo,comTexto)
if not s.ativo then return end
if motivo=="TEXTO" and objeto:IsA("TextLabel") and objeto.Parent
and (objeto.Name:lower():find("timer",1,true) or objeto.Parent.Name:lower():find("timer",1,true)) then
local valor=tonumber(objeto.Text)
if valor then
local antes=s.ultimoTimer[objeto]
if antes and os.clock()-antes.tempo<1 and valor>0 and valor<=antes.valor+0.25 then
s.temposResumidos+=1; s.sujo=true; return
end
s.ultimoTimer[objeto]={tempo=os.clock(),valor=valor}
end
end
local inicial=motivo=="INICIAL"
if inicial and s.iniciais>=LIMITES.iniciais then s.limiteIniciais=true; return end
local ok,resultado=pcall(function()
if not permitido(objeto) then return nil end
local valor=""
if comTexto then
if objeto:IsA("TextBox") then valor=" | [conteúdo da caixa oculto]"
elseif sensivel(objeto.Text) then valor=" | [conteúdo possivelmente sensível oculto]"
else valor=" | "..limparTexto(s,objeto.Text) end
end
return string.format("+%.2fs | %s | %s | %s | %s%s",os.clock()-s.inicio,motivo,caminho(s,objeto),objeto.ClassName,visivel(objeto),valor)
end)
if ok and resultado then
guardarLinha(s,resultado,inicial)
elseif not ok then s.erros+=1 end
end
local function conectar(s,sinal,funcao,objeto)
local ok,c=pcall(function() return sinal:Connect(funcao) end)
if ok then
s.conexoes[c]=true
if objeto then
local lista=s.porObjeto[objeto] or {}; s.porObjeto[objeto]=lista; lista[#lista+1]=c
end
else s.erros+=1 end
end
local function desobservar(s,objeto)
local info=s.observados[objeto]
if not info then return end
for _,c in ipairs(s.porObjeto[objeto] or {}) do
pcall(function() c:Disconnect() end); s.conexoes[c]=nil
end
s.porObjeto[objeto]=nil; s.observados[objeto]=nil; s.ultimoTimer[objeto]=nil
s.totalObservados=math.max(0,s.totalObservados-1)
if info.texto then s.textos=math.max(0,s.textos-1) end
if info.visibilidade then s.visibilidade=math.max(0,s.visibilidade-1) end
end
local function adicionarArvore(s,objeto)
if not (objeto:IsA("GuiObject") or objeto:IsA("LayerCollector") or objeto:IsA("Folder")) then return end
local ok,valor=pcall(function() return caminho(s,objeto).."  ["..objeto.ClassName.."]" end)
if not ok then s.erros+=1; return end
if s.arvoreVistos[valor] then return end
if #s.arvore>=LIMITES.arvore then s.limiteArvore=true; return end
s.arvoreVistos[valor]=true; s.arvore[#s.arvore+1]=valor; s.arvoreSuja=true
end
atualizarArvore=function()
local s=sessao
if not s then caixaArvore.Text="Inicie uma análise para construir a árvore local."; return end
local busca=(filtro.Text or ""):lower()
local linhas={"ÁRVORE LOCAL — pastas e interface acessíveis em PlayerGui","Filtro: "..(busca~="" and busca or "[todos]"),"Exibindo nomes e classes, sem abrir scripts ou arquivos protegidos.","---"}
local contagem=0
for _,item in ipairs(s.arvore) do
if busca=="" or item:lower():find(busca,1,true) then contagem+=1; linhas[#linhas+1]=item end
end
if contagem==0 then linhas[#linhas+1]=s.varreduraFinalizada and "Nenhum item corresponde ao filtro. Limpe o filtro ou inicie outra análise." or "Ainda procurando. Aguarde a varredura ou limpe o filtro." end
linhas[#linhas+1]="--- "..contagem.." encontrados / "..#s.arvore.." itens guardados ---"
if s.limiteArvore or s.limitePercurso then linhas[#linhas+1]="AVISO: limite atingido; a árvore pode estar incompleta." end
caixaArvore.Text=table.concat(linhas,"\n"); s.arvoreSuja=false
end
filtro:GetPropertyChangedSignal("Text"):Connect(function()
if abaAtual=="arvore" then atualizarArvore() elseif abaAtual=="auditoria" and atualizarAuditoria then atualizarAuditoria() end
end)
local termosAuditoria={"admin","permission","permiss","role","rank","moder","command","comando","word","palavra","dictionary","dicionario","letter","letra","prefix","prefixo","prompt","turn","round","rodada","choice","answer","resposta","validat","random"}
local function rotaAuditoria(s,obj,raiz)
local partes={}; local atual=obj; local profundidade=0
while atual and atual~=raiz and profundidade<40 do
if sensivel(atual.Name) then return nil end
table.insert(partes,1,limparTexto(s,atual.Name)); atual=atual.Parent; profundidade+=1
end
if atual~=raiz then return nil end
return raiz.Name..(#partes>0 and "/"..table.concat(partes,"/") or "")
end
atualizarAuditoria=function()
local s=sessao
if not s then caixaAuditoria.Text="Inicie para inspecionar objetos visíveis ao cliente."; return end
local a=s.audit; local busca=(filtro.Text or ""):lower(); local exibidas=0
local linhas={"INVENTÁRIO PASSIVO — somente cópias disponíveis no cliente","Serviços: ReplicatedStorage, Workspace, Lighting e PlayerGui. NÃO inclui ServerStorage ou ServerScriptService.",
"Nomes são pistas, não provam brechas. Histórico inclui objetos que podem ter sido removidos.",
"Escuta passiva: eventos servidor->cliente após inscrição; tipos e tamanhos de texto, nunca valores. Sem enviar chamadas.",
string.format("Status: %s | Ciclos: %d | Visitas acumuladas: %d | Remotos encontrados: %d | Pistas: %d | Erros: %d | Limite: %s",(a.finalizado and (a.interrompida and "interrompido" or "aguardando próxima varredura") or "varrendo"),a.ciclos,a.vistos,a.remotos,a.pistas,a.erros,tostring(a.limites)),
string.format("Remotos com escuta ativa: %d/120 | Eventos recebidos: %d | Suprimidos: %d | Eventos antigos descartados: %d",a.ouvindo,a.eventosTotal,a.suprimidos,a.descartados),
"Filtro: "..(busca~="" and busca or "[todos]"),"--- OBJETOS / PISTAS ---"}
for _,colecao in ipairs({a.prioritarios,a.linhas}) do
for _,item in ipairs(colecao) do
if busca=="" or item:lower():find(busca,1,true) then exibidas+=1; linhas[#linhas+1]=item end
end
end
if exibidas==0 then linhas[#linhas+1]=a.finalizado and "Nenhum resultado para o filtro ou dentro dos limites." or "Aguardando a varredura." end
linhas[#linhas+1]="--- "..exibidas.." exibidos / "..(#a.linhas+#a.prioritarios).." guardados ---"
linhas[#linhas+1]="--- EVENTOS DO SERVIDOR RECEBIDOS PELO CLIENTE (somente tipos) ---"
for _,evento in ipairs(a.eventos) do if busca=="" or evento:lower():find(busca,1,true) then linhas[#linhas+1]=evento end end
caixaAuditoria.Text=table.concat(linhas,"\n"); a.sujo=false
end
local function auditarObjeto(s,obj,raiz)
local a=s.audit
local rota=rotaAuditoria(s,obj,raiz)
if not rota then return end
local classe=obj.ClassName; local nome=obj.Name:lower(); local pista=false
for _,termo in ipairs(termosAuditoria) do if nome:find(termo,1,true) then pista=true; break end end
local remoto=classe=="RemoteEvent" or classe=="RemoteFunction" or classe=="UnreliableRemoteEvent"
local chave=rota.." ["..classe.."]"
if not a.vistosSet[chave] then
local destino
if #a.linhas<6500 then destino=a.linhas
elseif (remoto or pista) and #a.prioritarios<1000 then destino=a.prioritarios;a.limites=true
else a.limites=true end
if destino then
a.vistosSet[chave]=true
if remoto then a.remotos+=1 end; if pista then a.pistas+=1 end
local marca=remoto and "[REMOTO] " or (pista and "[PISTA] " or "")
destino[#destino+1]=marca..chave; a.sujo=true
end
end
if a.conexoes[obj] and pista then a.prioridadeConexao[obj]=true end
if (classe=="RemoteEvent" or classe=="UnreliableRemoteEvent") and not a.conexoes[obj] then
if a.ouvindo>=120 and pista then
for outro,conexao in pairs(a.conexoes) do
if not a.prioridadeConexao[outro] then
pcall(function() conexao:Disconnect() end);s.conexoes[conexao]=nil
a.conexoes[outro]=nil;a.prioridadeConexao[outro]=nil;a.ouvindo-=1;a.limites=true;break
end
end
end
if a.ouvindo>=120 then a.limites=true;return end
local ok,c=pcall(function()
return obj.OnClientEvent:Connect(function(...)
if not s.ativo or sessao~=s then return end
local agora=os.clock()
if agora-a.inicioJanela>=1 then a.inicioJanela=agora;a.naJanela=0 end
if a.naJanela>=50 then a.suprimidos+=1;a.sujo=true;return end
a.naJanela+=1
local n=select("#",...);local tipos={}
for i=1,math.min(n,8) do
local valor=select(i,...);local tipo=typeof(valor)
if tipo=="string" then tipo=tipo.."(len="..#valor..")" end
tipos[#tipos+1]=tipo
end
local okCaminho,atual=pcall(rotaAuditoria,s,obj,raiz)
local caminhoEvento=okCaminho and atual and (atual.." ["..classe.."]") or "[caminho não disponível]"
local registro=string.format("+%.2fs | SERVIDOR->CLIENTE | %s | %d argumentos | tipos: %s%s",agora-s.inicio,caminhoEvento,n,table.concat(tipos,","),n>8 and ",..." or "")
if #a.eventos>=250 then table.remove(a.eventos,1);a.descartados+=1 end
a.eventos[#a.eventos+1]=registro;a.eventosTotal+=1;a.sujo=true
end)
end)
if ok then a.conexoes[obj]=c;a.prioridadeConexao[obj]=pista;a.ouvindo+=1;s.conexoes[c]=true else a.erros+=1 end
end
end
local function auditarCliente(s)
local a=s.audit;a.finalizado=false;a.sujo=true
for _,config in ipairs({{"ReplicatedStorage",6000},{"Workspace",2500},{"Lighting",1000},{"PlayerGui",4000}}) do
if not s.ativo or sessao~=s or not gui.Parent then break end
local ok,raiz=pcall(function() return config[1]=="PlayerGui" and playerGui or game:GetService(config[1]) end)
if not ok or not raiz then a.erros+=1
else
local pilha={raiz}; local n=0
while #pilha>0 and n<config[2] and s.ativo and sessao==s and gui.Parent do
local obj=table.remove(pilha); n+=1; a.vistos+=1
local proprio=obj==gui or (obj:IsA("ScreenGui") and obj.Name=="AuditoriaRemotosPrivado")
local okRota,rota=pcall(rotaAuditoria,s,obj,raiz)
if not okRota then a.erros+=1 end
if not proprio and okRota and rota then
local okItem=pcall(auditarObjeto,s,obj,raiz);if not okItem then a.erros+=1 end
local okFilhos,filhos=pcall(function() return obj:GetChildren() end)
if okFilhos then
for _,filho in ipairs(filhos) do
if n+#pilha>=config[2] then a.limites=true; break end
pilha[#pilha+1]=filho
end
else a.erros+=1 end
end
if n%100==0 then a.sujo=true; task.wait() end
end
if #pilha>0 then a.limites=true end
end
end
a.ciclos+=1;a.interrompida=not s.ativo or sessao~=s or not gui.Parent;a.finalizado=true;a.sujo=true
end
local function monitorarRodada(s)
local ativa=false;local ultimoCampo=nil;local ultimaPergunta=nil
while s.ativo and sessao==s and gui.Parent do
local ok,pergunta,campo=pcall(function()
for _,g in ipairs(playerGui:GetChildren()) do
if g:IsA("ScreenGui") and g~=gui and g.Name~="AuditoriaRemotosPrivado" then
local top=g:FindFirstChild("TopBar");local q=top and top:FindFirstChild("Question");q=q and q:FindFirstChild("QuestionLabel")
local input=top and top:FindFirstChild("AnswerInput");local keys=input and input:FindFirstChild("Keys")
if q and keys and visivel(input)=="visível" then
local texto=tostring(q.Text or "");local lower=texto:lower()
if lower:find("type a word",1,true) or lower:find("starting with",1,true) or lower:find("contains",1,true) or lower:find("palavra",1,true) then
local chars={}
for i=1,30 do
local slot=keys:FindFirstChild(tostring(i));if not slot then break end
local inner=slot:FindFirstChild("Inner");local label=(inner and inner:FindFirstChild("TextLabel")) or slot:FindFirstChild("TextLabel")
if not label or not label:IsA("TextLabel") then break end
local c=tostring(label.Text or ""):lower():gsub("%s","")
if not c:match("^[a-z]$") then break end
chars[#chars+1]=c
end
return texto,table.concat(chars)
end
end
end
end
return nil,nil
end)
if ok then
if pergunta and not ativa then
ativa=true;guardarLinha(s,string.format("+%.2fs | POSSÍVEL FASE DE PALAVRA | instrução=%s | campo observado=%s",os.clock()-s.inicio,limparTexto(s,pergunta),campo~="" and campo or "[vazio]"),false)
ultimoCampo=campo;ultimaPergunta=pergunta
elseif pergunta and (campo~=ultimoCampo or pergunta~=ultimaPergunta) then
guardarLinha(s,string.format("+%.2fs | FASE ATIVA | instrução=%s | campo observado=%s",os.clock()-s.inicio,limparTexto(s,pergunta),campo~="" and campo or "[vazio]"),false)
ultimoCampo=campo;ultimaPergunta=pergunta
elseif not pergunta and ativa then
guardarLinha(s,string.format("+%.2fs | FASE DE PALAVRA DEIXOU DE SER OBSERVADA",os.clock()-s.inicio),false)
ativa=false;ultimoCampo=nil;ultimaPergunta=nil
end
else s.erros+=1 end
task.wait(.35)
end
end
local function observar(s,objeto,novo)
if not s.ativo or not permitido(objeto) then return end
local info=s.observados[objeto]
if not info then
if s.totalObservados >=LIMITES.visitados then s.limitePercurso=true; return end
info={texto=false,visibilidade=false}; s.observados[objeto]=info; s.totalObservados+=1
adicionarArvore(s,objeto)
end
local texto=objeto:IsA("TextLabel") or objeto:IsA("TextButton") or objeto:IsA("TextBox")
if texto and not info.texto and s.textos<LIMITES.textos then
s.textos+=1; info.texto=true; linha(s,objeto,novo and "NOVO" or "INICIAL",true)
if not objeto:IsA("TextBox") then
conectar(s,objeto:GetPropertyChangedSignal("Text"),function() linha(s,objeto,"TEXTO",true) end,objeto)
end
elseif texto and not info.texto then s.limiteTextos=true end
if not info.visibilidade and s.visibilidade<LIMITES.visibilidade and (objeto:IsA("GuiObject") or objeto:IsA("LayerCollector")) then
s.visibilidade+=1; info.visibilidade=true
local prop=objeto:IsA("GuiObject") and "Visible" or "Enabled"
conectar(s,objeto:GetPropertyChangedSignal(prop),function() linha(s,objeto,"VISIBILIDADE",texto) end,objeto)
elseif not info.visibilidade and (objeto:IsA("GuiObject") or objeto:IsA("LayerCollector")) then s.limiteVisibilidade=true end
end
local function montar(s)
local notas={
"DIAGNÓSTICO LOCAL — REVISE ANTES DE COMPARTILHAR",
"Somente interface acessível no cliente. TextBox e ramificações sensíveis omitidas.",
string.format("Tempo: %.1fs / %s | Objetos visitados: %d | Textos ativos: %d | Registros iniciais: %d | Mudanças totais: %d | Na memória: %d | Descartadas: %d | Itens na árvore: %d",(s.tempoFinal or os.clock())-s.inicio,s.duracao==0 and "manual" or (s.duracao.."s"),s.visitados,s.textos,s.iniciais,s.eventos,s.eventosGuardados,s.eventosDescartados,#s.arvore),
"Limites: percurso="..tostring(s.limitePercurso)..", árvore="..tostring(s.limiteArvore)..", textos="..tostring(s.limiteTextos)..", iniciais="..tostring(s.limiteIniciais)..", visibilidade="..tostring(s.limiteVisibilidade)..", descartou antigos="..tostring(s.eventosDescartados>0)..", caracteres="..tostring(s.limiteCaracteres),
"Erros de leitura: "..s.erros.." | Tentativas de varredura: "..s.tentativas.." | Falha final: "..tostring(s.falhaVarredura).." | Leituras repetidas do cronômetro resumidas: "..s.temposResumidos,
"Monitor de fase ativo: "..tostring(s.monitorFaseAtivo).." | Reinícios após falha: "..s.reiniciosMonitor,
"Filtragem de privacidade não é garantida.",
(s.varreduraFinalizada and s.textos==0) and "AVISO: nenhum texto encontrado em PlayerGui. A interface pode ser 3D, estar oculta fora desse local ou não existir no momento; verifique a aba ÁRVORE." or "A árvore mostra apenas objetos de interface e pastas locais; não inclui conteúdo de scripts ou servidor.",
"--- REGISTRO ---"
}
local recentes={}
for i=0,s.eventosGuardados-1 do recentes[#recentes+1]=s.filaEventos[(s.inicioFila+i-1)%LIMITES.eventos+1] end
return table.concat(notas,"\n").."\n"..table.concat(s.linhas,"\n").."\n--- MUDANÇAS RECENTES ---\n"..table.concat(recentes,"\n")
end
atualizar=function(s,forcar)
if sessao~=s or not gui.Parent then return end
if not unificadoMinimizado and abaGeral=="partida" and (s.sujo or forcar) then
ultimoRelatorio=montar(s); caixa.Text=ultimoRelatorio; s.sujo=false
end
if not unificadoMinimizado and abaGeral=="partida" and abaAtual=="arvore" and s.arvoreSuja then atualizarArvore() end
if not unificadoMinimizado and abaGeral=="partida" and abaAtual=="auditoria" and s.audit.sujo then atualizarAuditoria() end
if s.ativo then
local prazo=s.duracao==0 and "manual" or (math.max(0,math.ceil(s.duracao-(os.clock()-s.inicio))).."s")
estado.Text=string.format("%s | %s | %d objetos | %d textos | %d mudanças",s.varreduraFinalizada and "Observando" or "Varrendo",prazo,s.visitados,s.textos,s.eventos)
end
end
refreshPartida=function() if sessao and atualizar then atualizar(sessao,true) end end
exportarMonitor=function()
local s=sessao
if not s then return "Monitor não iniciado ou memória limpa." end
local a=s.audit
local partes={montar(s),"\n--- ÁRVORE LOCAL (histórico, sem filtro) ---"}
for _,item in ipairs(s.arvore) do partes[#partes+1]=item end
partes[#partes+1]="\n--- INVENTÁRIO PASSIVO (histórico, sem filtro) ---"
partes[#partes+1]=string.format("Status=%s | Ciclos=%d | visitas=%d | remotos=%d | pistas=%d | erros=%d | limite=%s | escutas ativas=%d/120",a.finalizado and (a.interrompida and "interrompida" or "aguardando nova varredura") or "varredura em andamento",a.ciclos,a.vistos,a.remotos,a.pistas,a.erros,tostring(a.limites),a.ouvindo)
partes[#partes+1]="Objetos listados podem ter sido removidos. Escuta somente servidor->cliente; tipos e tamanho de texto, não valores."
for _,colecao in ipairs({a.prioritarios,a.linhas}) do for _,item in ipairs(colecao) do partes[#partes+1]=item end end
partes[#partes+1]=string.format("--- EVENTOS RECEBIDOS (registrados=%d | suprimidos=%d | descartados=%d) ---",a.eventosTotal,a.suprimidos,a.descartados)
for _,item in ipairs(a.eventos) do partes[#partes+1]=item end
return table.concat(partes,"\n")
end
local function pararSessao(motivo)
local s=sessao
if not s or not s.ativo then return end
s.ativo=false; s.tempoFinal=os.clock(); s.monitorFaseAtivo=false; desconectar(s); atualizar(s,true); cabecalho.Text="● PARTIDA · PARADO"
estado.Text=motivo.." | "..s.eventos.." mudanças. Revise antes de copiar."
end
local function iniciarSessao()
if sessao and sessao.ativo then estado.Text="Já está observando. Pare antes de reiniciar."; return end
contadorSessao+=1
local s={id=contadorSessao,ativo=true,inicio=os.clock(),duracao=duracoes[duracaoIndice],nomes=nomesJogadores(),conexoes={},porObjeto={},observados={},arvoreVistos={},arvore={},linhas={},filaEventos={},inicioFila=1,eventosGuardados=0,eventosDescartados=0,caracteresIniciais=0,audit={linhas={},prioritarios={},vistosSet={},vistos=0,remotos=0,pistas=0,erros=0,limites=false,finalizado=false,sujo=true,ciclos=0,conexoes={},prioridadeConexao={},ouvindo=0,eventos={},eventosTotal=0,suprimidos=0,descartados=0,inicioJanela=0,naJanela=0},ultimoTimer={},temposResumidos=0,totalObservados=0,visitados=0,textos=0,visibilidade=0,iniciais=0,eventos=0,caracteres=0,erros=0,sujo=true,arvoreSuja=true,varreduraFinalizada=false,tentativas=0,falhaVarredura=false,monitorFaseAtivo=false,reiniciosMonitor=0,limitePercurso=false,limiteTextos=false,limiteVisibilidade=false,limiteCaracteres=false,limiteIniciais=false,limiteEventos=false,limiteArvore=false}
cabecalho.Text="● PARTIDA · OBSERVANDO"
sessao=s; ultimoRelatorio=""; caixa.Text="Iniciando análise..."; caixaArvore.Text="Buscando objetos locais..."; caixaAuditoria.Text="Buscando objetos visíveis ao cliente..."; estado.Text="Varrendo interface. Jogue uma rodada."
conectar(s,playerGui.DescendantAdded,function(objeto)
if not s.ativo or sessao~=s then return end
local ok=pcall(observar,s,objeto,true); if not ok then s.erros+=1 end
end)
conectar(s,playerGui.DescendantRemoving,function(objeto)
if not s.ativo or sessao~=s or not s.observados[objeto] then return end
local ok=pcall(function()
if objeto:IsA("TextLabel") and permitido(objeto) then
local rota=caminho(s,objeto)
if rota:find("/AnswerInput/Keys/",1,true) then linha(s,objeto,"REMOVIDO",true) end
end
end)
if not ok then s.erros+=1 end
desobservar(s,objeto)
end)
for _,servico in ipairs({"ReplicatedStorage","Workspace","Lighting","PlayerGui"}) do
local ok,raiz=pcall(function() return servico=="PlayerGui" and playerGui or game:GetService(servico) end)
if ok and raiz then
conectar(s,raiz.DescendantAdded,function(obj)
if not s.ativo or sessao~=s then return end
if raiz==playerGui and not permitido(obj) then return end
local sucesso=pcall(auditarObjeto,s,obj,raiz);if not sucesso then s.audit.erros+=1 end
end)
conectar(s,raiz.DescendantRemoving,function(obj)
local c=s.audit.conexoes[obj]
if c then pcall(function() c:Disconnect() end);s.conexoes[c]=nil;s.audit.conexoes[obj]=nil;s.audit.prioridadeConexao[obj]=nil;s.audit.ouvindo=math.max(0,s.audit.ouvindo-1);s.audit.sujo=true end
end)
else s.audit.erros+=1 end
end
task.spawn(function()
while s.ativo and sessao==s and gui.Parent do
local ok=pcall(auditarCliente,s)
if not ok then s.audit.erros+=1; s.audit.interrompida=true; s.audit.finalizado=true; s.audit.sujo=true end
task.wait(30)
end
end)
task.spawn(function()
while s.ativo and sessao==s and gui.Parent do
s.monitorFaseAtivo=true;s.sujo=true
local ok=pcall(monitorarRodada,s)
s.monitorFaseAtivo=false;s.sujo=true
if ok or not s.ativo or sessao~=s or not gui.Parent then break end
s.erros+=1;s.reiniciosMonitor+=1
task.wait(2)
end
end)
task.spawn(function()
local function varrer()
local pilha={playerGui}; s.visitados=0
while #pilha>0 and s.ativo and sessao==s and gui.Parent and s.visitados<LIMITES.visitados and (s.duracao==0 or os.clock()-s.inicio<s.duracao) do
local objeto=table.remove(pilha); s.visitados+=1
if objeto~=gui and (objeto==playerGui or permitido(objeto)) then
local ok=pcall(observar,s,objeto); if not ok then s.erros+=1 end
local okFilhos,filhos=pcall(function() return objeto:GetChildren() end)
if okFilhos then
for _,filho in ipairs(filhos) do
if s.visitados+#pilha >=LIMITES.visitados then s.limitePercurso=true; break end
pilha[#pilha+1]=filho
end
else s.erros+=1 end
end
if s.visitados%150==0 then task.wait() end
end
if #pilha>0 then s.limitePercurso=true end
end
while s.ativo and sessao==s and gui.Parent and (s.duracao==0 or os.clock()-s.inicio<s.duracao) do
local sucesso=false
for tentativa=1,2 do
if not s.ativo or sessao~=s or not gui.Parent then break end
s.tentativas=tentativa
local ok=pcall(varrer)
if ok then sucesso=true; break end
s.erros+=1; s.sujo=true
if tentativa<2 then task.wait(.5) end
end
s.falhaVarredura=not sucesso and s.ativo and sessao==s
s.varreduraFinalizada=true; s.arvoreSuja=true
if sessao==s and s.ativo then s.sujo=true; atualizar(s,true) end
task.wait(30)
end
end)
task.spawn(function()
while s.ativo and sessao==s and gui.Parent and (s.duracao==0 or os.clock()-s.inicio<s.duracao) do
atualizar(s,false); task.wait(.5)
end
if s.ativo and sessao==s then
if gui.Parent then pararSessao("Tempo concluído") else s.ativo=false; desconectar(s) end
end
end)
end
iniciar.MouseButton1Click:Connect(iniciarSessao)
parar.MouseButton1Click:Connect(function() if sessao and sessao.ativo then pararSessao("Análise parada") else estado.Text="Nenhuma análise em andamento." end end)
tempo.MouseButton1Click:Connect(function()
if sessao and sessao.ativo then estado.Text="Pare a análise para mudar o tempo."; return end
duracaoIndice=duracaoIndice%#duracoes+1
tempo.Text=duracoes[duracaoIndice]==0 and "ATÉ PARAR" or ("TEMPO: "..duracoes[duracaoIndice].."s")
end)
copiar.MouseButton1Click:Connect(function()
if sessao and sessao.ativo then atualizar(sessao,true) end
local texto=abaAtual=="arvore" and caixaArvore.Text or (abaAtual=="auditoria" and caixaAuditoria.Text or caixa.Text)
if texto=="" then estado.Text="Não há texto para copiar."; return end
local ok,retorno=false,nil
if type(setclipboard)=="function" then ok,retorno=pcall(setclipboard,texto) end
if ok and retorno~=false then estado.Text="Comando de cópia enviado. Confira ao colar e revise."
else estado.Text="Cópia automática indisponível. Toque em SELECIONAR e copie manualmente." end
end)
selecionar.MouseButton1Click:Connect(function()
if sessao and sessao.ativo then pararSessao("Análise parada para seleção") end
local selecionada=abaAtual=="arvore" and caixaArvore or (abaAtual=="auditoria" and caixaAuditoria or caixa)
selecionada:CaptureFocus(); selecionada.CursorPosition=#selecionada.Text+1; selecionada.SelectionStart=1
estado.Text="Texto selecionado. Use copiar do teclado ou menu do aparelho."
end)
limpar.MouseButton1Click:Connect(function()
if sessao and sessao.ativo then estado.Text="Pare a análise antes de limpar."; return end
sessao=nil; ultimoRelatorio=""; caixa.Text=""; caixaArvore.Text="Inicie uma análise para construir a árvore local."; caixaAuditoria.Text="Inicie para inspecionar objetos visíveis ao cliente."; estado.Text="Relatório e árvore limpos. Pronto para iniciar."
end)
gui.Destroying:Connect(function()
if sessao and sessao.ativo then sessao.ativo=false; sessao.tempoFinal=os.clock(); desconectar(sessao) end
end)
task.spawn(iniciarSessao)
end)
if not okMonitor then statusGeral.Text="Falha ao iniciar monitor de partida; verifique o console."; warn("Auditoria: falha ao iniciar monitor de partida: "..tostring(erroMonitor)) end
local okRemotos,erroRemotos=pcall(function()
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local HttpService=game:GetService("HttpService")
local player=Players.LocalPlayer
assert(player,"Execute no cliente, com LocalPlayer disponível.")
local pg=player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui",10)
assert(pg,"PlayerGui não disponível.")
local anterior=pg:FindFirstChild("AuditoriaRemotosPrivado")
if anterior and anterior:IsA("ScreenGui") then anterior:Destroy() end
local function criar(tipo,props,pai)
local obj=Instance.new(tipo)
for k,v in pairs(props or {}) do obj[k]=v end
if pai then obj.Parent=pai end
return obj
end
local function cantos(obj) criar("UICorner",{CornerRadius=UDim.new(0,6)},obj) end
local cor=Color3.fromRGB
local gui=sharedGui
local painel=criar("Frame",{Name="Painel",Size=UDim2.new(1,0,1,0),Position=UDim2.new(.5,0,.5,0),AnchorPoint=Vector2.new(.5,.5),BackgroundColor3=cor(24,29,39),BorderSizePixel=0},corpoRemotos);cantos(painel)
local dimensao=criar("UISizeConstraint",{MinSize=Vector2.new(0,0),MaxSize=Vector2.new(3000,3000)},painel)
local titulo=criar("TextLabel",{Name="Titulo",Size=UDim2.new(1,-94,0,40),Position=UDim2.new(0,10,0,0),Active=true,BackgroundTransparency=1,Text="☰  AUDITORIA DE REMOTOS",TextColor3=cor(238,244,251),TextSize=14,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},painel)
local function botao(nome,texto,pos,tam,pai)
local b=criar("TextButton",{Name=nome,Position=pos,Size=tam,Text=texto,Font=Enum.Font.GothamBold,TextSize=12,TextColor3=cor(245,247,252),BackgroundColor3=cor(50,65,85),BorderSizePixel=0},pai);cantos(b);return b
end
local fechar=botao("Fechar","×",UDim2.new(1,-40,0,6),UDim2.new(0,32,0,30),painel)
local minimo=botao("Minimizar","−",UDim2.new(1,-78,0,6),UDim2.new(0,32,0,30),painel)
local scan=botao("Varrer","VARRER",UDim2.new(0,10,0,44),UDim2.new(.30,-5,0,32),painel)
local copiar=botao("Copiar","COPIAR LOG",UDim2.new(.30,10,0,44),UDim2.new(.35,-5,0,32),painel)
local limpar=botao("Limpar","LIMPAR LOG",UDim2.new(.5,5,0,44),UDim2.new(.5,-15,0,32),painel)
copiar.Visible=false;scan.Size=UDim2.new(.5,-15,0,32)
local busca=criar("TextBox",{Name="Busca",Position=UDim2.new(0,10,0,82),Size=UDim2.new(1,-20,0,30),BackgroundColor3=cor(42,52,67),BorderSizePixel=0,Text="",PlaceholderText="Filtrar remotos por nome, caminho ou tipo",ClearTextOnFocus=false,TextColor3=cor(245,245,245),Font=Enum.Font.Gotham,TextSize=12},painel);cantos(busca)
local lista=criar("ScrollingFrame",{Name="Lista",Position=UDim2.new(0,10,0,117),Size=UDim2.new(1,-20,.32,-70),BackgroundColor3=cor(15,20,28),BorderSizePixel=0,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y,ScrollBarThickness=6},painel);cantos(lista)
local listaLayout=criar("UIListLayout",{Padding=UDim.new(0,3),SortOrder=Enum.SortOrder.LayoutOrder},lista)
local escolhido=criar("TextLabel",{Name="Selecionado",Position=UDim2.new(0,10,.32,50),Size=UDim2.new(1,-20,0,32),BackgroundTransparency=1,Text="Selecione um remoto da lista.",TextColor3=cor(186,220,240),Font=Enum.Font.Gotham,TextSize=11,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left},painel)
local args=criar("TextBox",{Name="Argumentos",Position=UDim2.new(0,10,.32,84),Size=UDim2.new(1,-20,0,32),BackgroundColor3=cor(42,52,67),BorderSizePixel=0,Text="",PlaceholderText='Argumentos como JSON: ex. ["teste", 1]',ClearTextOnFocus=false,TextColor3=cor(245,245,245),Font=Enum.Font.Code,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left},painel);cantos(args)
local enviar=botao("Testar","PREPARAR TESTE",UDim2.new(0,10,.32,122),UDim2.new(1,-20,0,34),painel)
local estado=criar("TextLabel",{Name="Estado",Position=UDim2.new(0,10,.32,160),Size=UDim2.new(1,-20,0,30),BackgroundTransparency=1,Text="Apenas servidor privado. Nada é chamado automaticamente.",TextColor3=cor(231,199,147),Font=Enum.Font.Gotham,TextSize=11,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left},painel)
local logArea=criar("ScrollingFrame",{Name="AreaLog",Position=UDim2.new(0,10,.32,192),Size=UDim2.new(1,-20,.68,-202),BackgroundColor3=cor(15,20,28),BorderSizePixel=0,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y,ScrollBarThickness=6},painel);cantos(logArea)
local logBox=criar("TextBox",{Name="Log",Position=UDim2.new(0,6,0,6),Size=UDim2.new(1,-18,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,ClearTextOnFocus=false,MultiLine=true,TextEditable=true,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,Font=Enum.Font.Code,TextSize=12,TextColor3=cor(220,230,239),Text="Varrer não chama funções. Leia e revise o log antes de compartilhar."},logArea)
exportarRemotos=function() return logBox.Text end
local listaRemotos,selecionado,armado,ocupado={},nil,nil,false
local geracao,scanAtivo,visiveis,fechado=0,false,{},false
local numeroChamada=0
local linhas={};local nLog=0;local descartadas=0
local resumo={estado="Varredura ainda não iniciada.",servicos={},objetos=0,erros=0,limite=false,caminhosLongos=0}
local function atualizarRelatorio()
local partes={"RELATÓRIO DE AUDITORIA — REVISE ANTES DE COMPARTILHAR",
"Somente objetos visíveis no cliente. A varredura não chama remotos.",
"A existência de remoto ou uma resposta não prova vulnerabilidade ou permissão.",
"Status: "..resumo.estado,
"Chamada ainda pendente: "..tostring(ocupado),
string.format("Objetos visitados: %d | Remotos listados: %d | Erros: %d | Limite: %s | Caminhos longos não exibidos: %d",resumo.objetos,#listaRemotos,resumo.erros,tostring(resumo.limite),resumo.caminhosLongos),
"--- ORIGEM DA BUSCA ---"}
for _,linha in ipairs(resumo.servicos) do partes[#partes+1]=linha end
partes[#partes+1]="--- REMOTOS ENCONTRADOS (ID: varredura.item; nomes JSON escapados) ---"
local tamanho=0;local omitidos=0;local contagens={}
for _,item in ipairs(listaRemotos) do contagens[item.rotulo]=(contagens[item.rotulo] or 0)+1 end
for i,item in ipairs(listaRemotos) do
local ambiguo=contagens[item.rotulo]>1 and " [CAMINHO DUPLICADO: ID distingue objeto nesta execução]" or ""
local linha="[#"..item.varredura.."."..i.."] "..item.rotulo..ambiguo
if tamanho+#linha<=180000 then partes[#partes+1]=linha;tamanho+=#linha else omitidos+=1 end
end
if #listaRemotos==0 then partes[#partes+1]="Nenhum remoto listado nesta varredura." end
if omitidos>0 then partes[#partes+1]="AVISO: "..omitidos.." caminhos não incluídos por limite de tamanho." end
partes[#partes+1]="--- TESTES E EVENTOS (antigos descartados: "..descartadas..") ---"
for _,linha in ipairs(linhas) do partes[#partes+1]=linha end
logBox.Text=table.concat(partes,"\n")
end
local function registrar(texto)
nLog+=1;local t=tostring(texto)
if #t>5000 then t=t:sub(1,5000).." [registro truncado]" end
linhas[#linhas+1]=string.format("[%d] %s",nLog,t)
if #linhas>150 then table.remove(linhas,1);descartadas+=1 end
atualizarRelatorio()
end
local function caminho(obj,raiz)
local partes={};local p=obj;local n=0
while p and p~=raiz and n<40 do
local nome=tostring(p.Name);local codificado=HttpService:JSONEncode(nome)
table.insert(partes,1,"["..codificado.."]");p=p.Parent;n+=1
end
if p~=raiz then return nil end
local rota=raiz.Name..table.concat(partes,"")
if #rota>4096 then return nil,"longo" end
return rota
end
local function limparSelecao()
selecionado=nil;armado=nil;enviar.Text="PREPARAR TESTE";escolhido.Text="Selecione um remoto da lista."
end
local function atualizarLista()
for _,o in ipairs(lista:GetChildren()) do if o:IsA("TextButton") then o:Destroy() end end
if scanAtivo then return end
local termo=busca.Text:lower();local index=0
for _,item in ipairs(listaRemotos) do
if termo=="" or item.rotulo:lower():find(termo,1,true) then
index+=1
local b=botao("Remoto"..index,"[#"..item.varredura.."."..item.id.."] "..item.rotulo,UDim2.new(0,0,0,0),UDim2.new(1,-8,0,29),lista)
b.LayoutOrder=index;b.TextXAlignment=Enum.TextXAlignment.Left;b.TextSize=11;b.TextTruncate=Enum.TextTruncate.AtEnd
b.MouseButton1Click:Connect(function()
selecionado=item;armado=nil;enviar.Text="PREPARAR TESTE";escolhido.Text="ALVO #"..item.varredura.."."..item.id..": "..item.rotulo
estado.Text="Informe os argumentos JSON. Testes podem alterar dados."
end)
end
end
if index==0 then estado.Text=scanAtivo and "Varrendo..." or "Nenhum remoto no filtro ou nos limites da varredura." end
end
busca:GetPropertyChangedSignal("Text"):Connect(atualizarLista)
args:GetPropertyChangedSignal("Text"):Connect(function() if armado then armado=nil;enviar.Text="PREPARAR TESTE" end end)
scan.MouseButton1Click:Connect(function()
if scanAtivo then estado.Text="A varredura já está em andamento.";return end
geracao+=1;local minha=geracao;scanAtivo=true;limparSelecao();listaRemotos={};atualizarLista()
resumo={estado="Varredura em andamento; resultados ainda incompletos.",servicos={},objetos=0,erros=0,limite=false,caminhosLongos=0}
atualizarRelatorio()
estado.Text="Varrendo objetos locais; nenhum remoto será chamado."
task.spawn(function()
local okGlobal,erroGlobal=pcall(function()
local vistos,erros=0,0;local truncado=false
local outroPainel=pg:FindFirstChild("DiagnosticoLocalInterfacePainel")
for _,config in ipairs({{"ReplicatedStorage",8000},{"Workspace",6000},{"PlayerGui",4000}}) do
if fechado or minha~=geracao then break end
local totalAntes=#listaRemotos
local ok,raiz=pcall(function() return config[1]=="PlayerGui" and pg or game:GetService(config[1]) end)
if not ok or not raiz then erros+=1;resumo.servicos[#resumo.servicos+1]=config[1]..": indisponível"
else
local pilha={raiz};local n=0
while #pilha>0 and n<config[2] and not fechado and minha==geracao do
local obj=table.remove(pilha);n+=1;vistos+=1
if obj~=gui and not obj:IsDescendantOf(gui) and (not outroPainel or (obj~=outroPainel and not obj:IsDescendantOf(outroPainel))) then
local okItem=pcall(function()
if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("UnreliableRemoteEvent") then
if #listaRemotos<300 then
local rota,problema=caminho(obj,raiz)
if not rota and problema=="longo" then resumo.caminhosLongos+=1;rota=raiz.Name.."/[CAMINHO LONGO NÃO EXIBIDO]" end
if rota then listaRemotos[#listaRemotos+1]={obj=obj,raiz=raiz,varredura=minha,rotulo=rota.." ["..obj.ClassName.."]"} end
else truncado=true end
end
local filhos=obj:GetChildren()
for _,filho in ipairs(filhos) do
if n+#pilha>=config[2] then truncado=true;break end
pilha[#pilha+1]=filho
end
end)
if not okItem then erros+=1 end
end
if n%150==0 then task.wait() end
end
if #pilha>0 then truncado=true end
resumo.servicos[#resumo.servicos+1]=string.format("%s: %d objetos visitados (limite %d), %d remotos listados",config[1],n,config[2],#listaRemotos-totalAntes)
end
end
if fechado or minha~=geracao then return end
scanAtivo=false;table.sort(listaRemotos,function(a,b) return a.rotulo<b.rotulo end)
for i,item in ipairs(listaRemotos) do item.id=i end
resumo.estado="Varredura concluída. Revise dados pessoais antes de copiar."
resumo.objetos=vistos;resumo.erros=erros;resumo.limite=truncado
atualizarLista()
registrar(string.format("Varredura concluída: %d objetos, %d remotos, %d erros, limite=%s. Nenhum remoto chamado.",vistos,#listaRemotos,erros,tostring(truncado)))
estado.Text=ocupado and "Varredura concluída, mas há chamada pendente. Pode copiar parcial." or string.format("PRONTO PARA COPIAR: %d remotos; %d objetos. Revise o relatório.",#listaRemotos,vistos)
end)
if not okGlobal and not fechado and minha==geracao then
scanAtivo=false
table.sort(listaRemotos,function(a,b) return a.rotulo<b.rotulo end)
for i,item in ipairs(listaRemotos) do item.id=i end
resumo.estado="Varredura interrompida por erro; relatório parcial."
resumo.erros+=1;resumo.limite=true
atualizarLista();registrar("Erro na varredura; resultados parciais: "..tostring(erroGlobal))
estado.Text="Varredura interrompida. PRONTO PARA COPIAR o relatório parcial."
end
end)
end)
local function argumentosSeguros(texto)
if #texto>2000 then return nil,"JSON longo demais (máximo 2000 caracteres)." end
if not texto:match("^%s*%[") then return nil,"Use uma lista JSON, por exemplo [\"teste\", 1]." end
local emTexto,escape=false,false
for i=1,#texto do
local c=texto:sub(i,i)
if emTexto then
if escape then escape=false elseif c=="\\" then escape=true elseif c=='"' then emTexto=false end
elseif c=='"' then emTexto=true
elseif texto:sub(i,i+3)=="null" then return nil,"null não é permitido; pode perder a posição do argumento." end
end
local ok,valor=pcall(function() return HttpService:JSONDecode(texto) end)
if not ok or type(valor)~="table" then return nil,"JSON inválido: use uma lista JSON." end
if #valor>10 then return nil,"Máximo de 10 argumentos." end
for k,v in pairs(valor) do
if type(k)~="number" or k<1 or k%1~=0 or k>#valor or v==nil then return nil,"Lista esparsa ou inválida." end
end
return valor
end
local function alvoValido(item)
if not item or not item.obj or not item.raiz then return false end
local ok,rota=pcall(function()
if not item.obj:IsDescendantOf(item.raiz) then return nil end
local atual=caminho(item.obj,item.raiz)
return atual and (atual.." ["..item.obj.ClassName.."]") or nil
end)
return ok and rota~=nil and rota==item.rotulo
end
enviar.MouseButton1Click:Connect(function()
if ocupado then estado.Text="Chamada anterior ainda em andamento; não será enviada outra.";return end
local okId,id=pcall(function() return game.PrivateServerId end)
if not okId or type(id)~="string" or id=="" then estado.Text="Bloqueado: não foi possível confirmar um servidor privado/reservado.";return end
if not alvoValido(selecionado) then limparSelecao();estado.Text="O caminho mudou ou não pode ser verificado; execute VARRER novamente.";return end
local texto=args.Text;local valores,erro=argumentosSeguros(texto)
if not valores then estado.Text=erro;return end
if not armado or armado.obj~=selecionado.obj or armado.texto~=texto or os.clock()>armado.ate then
armado={obj=selecionado.obj,texto=texto,ate=os.clock()+10};enviar.Text="CONFIRMAR ENVIO"
estado.Text="Confira alvo e argumentos. Toque novamente em até 10s para enviar UMA chamada."
return
end
local alvo=selecionado;armado=nil;enviar.Text="PREPARAR TESTE";ocupado=true;numeroChamada+=1;local idChamada=numeroChamada
registrar("TESTE CONFIRMADO para remoto #"..alvo.varredura.."."..alvo.id.."; aguardando validação final.")
estado.Text="Chamada em andamento; pode alterar dados. Não repita enquanto estiver pendente."
task.spawn(function()
local ok,resultado=pcall(function()
if fechado or not gui.Parent then error("Painel fechado antes do envio.") end
if not alvoValido(alvo) then error("Caminho do remoto mudou antes do envio; atualize a varredura.") end
local permitido,idAtual=pcall(function() return game.PrivateServerId end)
if not permitido or type(idAtual)~="string" or idAtual=="" then error("Servidor privado não confirmado antes do envio.") end
registrar("ENVIO manual ao remoto #"..alvo.varredura.."."..alvo.id.." "..alvo.rotulo.." | argumentos: "..texto)
if alvo.obj:IsA("RemoteFunction") then return alvo.obj:InvokeServer(table.unpack(valores)) end
alvo.obj:FireServer(table.unpack(valores));return nil
end)
ocupado=false
if fechado or not gui.Parent then return end
if not ok then registrar("ERRO local/na chamada: "..tostring(resultado));estado.Text=scanAtivo and "Chamada retornou erro; varredura ainda em andamento." or "Chamada retornou erro. PRONTO PARA COPIAR após revisar."
elseif alvo.obj:IsA("RemoteFunction") then
local okJson,saida=pcall(function() return HttpService:JSONEncode(resultado) end)
registrar("RESPOSTA: "..(okJson and tostring(saida) or ("[tipo "..typeof(resultado).." não serializável]")))
estado.Text=scanAtivo and "Resposta registrada; varredura ainda em andamento." or "Resposta registrada. PRONTO PARA COPIAR após revisar. Não prova segurança."
else registrar("FireServer retornou localmente; RemoteEvent não informa aceitação.");estado.Text=scanAtivo and "Evento enviado; varredura ainda em andamento." or "Evento enviado; sem confirmação de aceitação. PRONTO PARA COPIAR." end
end)
task.delay(10,function()
if ocupado and numeroChamada==idChamada and not fechado and gui.Parent then estado.Text="Chamada ainda pendente. Não será repetida automaticamente." end
end)
end)
copiar.MouseButton1Click:Connect(function()
local ok,retorno=false,nil
if type(setclipboard)=="function" then ok,retorno=pcall(setclipboard,logBox.Text) end
if ok and retorno~=false then estado.Text="Comando de cópia enviado. Confira ao colar e revise o conteúdo."
else logBox:CaptureFocus();logBox.CursorPosition=#logBox.Text+1;logBox.SelectionStart=1;estado.Text="Cópia automática indisponível: copie o texto selecionado." end
end)
limpar.MouseButton1Click:Connect(function() linhas={};descartadas=0;atualizarRelatorio();estado.Text="Histórico de testes limpo; inventário preservado." end)
fechar.Visible=false;minimo.Visible=false;titulo.Active=false
gui.Destroying:Connect(function() fechado=true;geracao+=1 end)
end)
if not okRemotos then statusGeral.Text="Falha ao iniciar testador de remotos; verifique o console."; warn("Auditoria: falha ao iniciar painel de remotos: "..tostring(erroRemotos)) end
end,function(erro) return tostring(erro) end)
if not iniciouAuditoria then
if painelInicial then pcall(function() painelInicial:Destroy() end) end
pcall(function() warn("AUDITORIA: falha ao iniciar: "..tostring(erroAuditoria)) end)
pcall(function()
game:GetService("StarterGui"):SetCore("SendNotification",{Title="Auditoria não iniciou",Text="Confira o console para detalhes.",Duration=8})
end)
end
