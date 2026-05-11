local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local playerGui   = localPlayer:WaitForChild("PlayerGui")

-- ============================
-- 🔐 설정
-- ============================
local PW_URL     = "https://raw.githubusercontent.com/fhdhd9795-spec/py/refs/heads/main/py"
local SECRET_KEY = "M1n3r@lK3y"   -- index.html 과 동일하게 유지

-- ============================
-- 🔐 복호화 (Base64 → XOR → Base64 → 역치환)
-- ============================
local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function b64decode(data)
	data = data:gsub("[^" .. b64chars .. "=]", "")
	local bits, result = 0, 0
	local output = {}
	for i = 1, #data do
		local c = data:sub(i, i)
		if c == "=" then break end
		local v = b64chars:find(c) - 1
		bits   = bits + 6
		result = result * 64 + v
		if bits >= 8 then
			bits = bits - 8
			table.insert(output, string.char(math.floor(result / 2^bits) % 256))
			result = result % 2^bits
		end
	end
	return table.concat(output)
end

local function xorStr(text, key)
	local out = {}
	for i = 1, #text do
		local t = string.byte(text, i)
		local k = string.byte(key, ((i - 1) % #key) + 1)
		table.insert(out, string.char(bit32.bxor(t, k)))
	end
	return table.concat(out)
end

local NUM_TO_SYM = {["0"]="!",["1"]="@",["2"]="#",["3"]="$",["4"]="%",["5"]="^",["6"]="&",["7"]="*",["8"]="(",["9"]=")"}
local SYM_TO_NUM = {["!"]="0",["@"]="1",["#"]="2",["$"]="3",["%"]="4",["^"]="5",["&"]="6",["*"]="7",["("]="8",[")"]="9"}

local function reverseCipher(text)
	local rev = string.reverse(text)
	local out = {}
	for i = 1, #rev do
		local c = rev:sub(i, i)
		local b = string.byte(c)
		if b >= 97 and b <= 122 then
			table.insert(out, string.upper(c))
		elseif b >= 65 and b <= 90 then
			table.insert(out, string.lower(c))
		elseif NUM_TO_SYM[c] then
			table.insert(out, NUM_TO_SYM[c])
		elseif SYM_TO_NUM[c] then
			table.insert(out, SYM_TO_NUM[c])
		else
			table.insert(out, c)
		end
	end
	return table.concat(out)
end

local function decrypt(enc)
	local ok, result = pcall(function()
		local trimmed = enc:match("^%s*(.-)%s*$")
		local s1 = b64decode(trimmed)
		local s2 = xorStr(s1, SECRET_KEY)
		local s3 = b64decode(s2)
		return reverseCipher(s3)
	end)
	if ok and result and #result > 0 then
		return result
	end
	return enc  -- 복호화 실패 시 원문 반환
end

-- ============================
-- GitHub에서 비번 가져오기
-- ============================
local PASSWORD = nil

local function fetchPassword()
	local ok, result = pcall(function()
		local res = request({ Url = PW_URL, Method = "GET" })
		return res.Body
	end)
	if ok and result then
		local raw = result:match("^%s*(.-)%s*$")
		PASSWORD = decrypt(raw)
		return true
	end
	return false
end

-- ============================
-- 상태
-- ============================
local isTracking  = false
local ESP_ENABLED = true
local panelOpen   = false
local itemCount   = 0

-- ============================
-- 유틸
-- ============================
local function rnd(p, radius)
	local c = Instance.new("UICorner", p)
	c.CornerRadius = UDim.new(0, radius or 8)
end
local function rndHalf(p)
	local c = Instance.new("UICorner", p)
	c.CornerRadius = UDim.new(0.5, 0)
end
local function makeStroke(p, col, thick)
	local s = Instance.new("UIStroke", p)
	s.Color = col or Color3.fromRGB(0, 200, 180)
	s.Thickness = thick or 1.5
	return s
end
local function makeGrad(p, c0, c1, rot)
	local g = Instance.new("UIGradient", p)
	g.Color = ColorSequence.new(c0, c1)
	g.Rotation = rot or 90
end

-- ============================
-- ScreenGui
-- ============================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MineralMasterUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 999
screenGui.Parent = playerGui

-- ============================
-- 로고 버튼
-- ============================
local LOGO_SIZE = 62
local logoPosX  = 20
local logoPosY  = 0

local logoDrag, logoDragS, logoDragP
local isDragged = false

local logoBg = Instance.new("Frame", screenGui)
logoBg.AnchorPoint = Vector2.new(0, 0.5)
logoBg.Size = UDim2.new(0, LOGO_SIZE, 0, LOGO_SIZE)
logoBg.Position = UDim2.new(0, logoPosX, 0.5, -LOGO_SIZE/2 + logoPosY)
logoBg.BackgroundColor3 = Color3.fromRGB(10, 16, 28)
logoBg.BorderSizePixel = 0
rndHalf(logoBg)
makeStroke(logoBg, Color3.fromRGB(0, 210, 185), 2)
makeGrad(logoBg, Color3.fromRGB(16, 26, 44), Color3.fromRGB(8, 12, 22), 135)
logoBg.Visible = false

local innerCircle = Instance.new("Frame", logoBg)
innerCircle.Size = UDim2.new(0, LOGO_SIZE - 16, 0, LOGO_SIZE - 16)
innerCircle.Position = UDim2.new(0, 8, 0, 8)
innerCircle.BackgroundTransparency = 1
innerCircle.BorderSizePixel = 0
rndHalf(innerCircle)
makeStroke(innerCircle, Color3.fromRGB(0, 140, 130), 0.6)

local logoText = Instance.new("TextLabel", logoBg)
logoText.Size = UDim2.new(1, 0, 0.55, 0)
logoText.Position = UDim2.new(0, 0, 0, 6)
logoText.Text = "M"
logoText.Font = Enum.Font.GothamBlack
logoText.TextScaled = true
logoText.TextColor3 = Color3.fromRGB(0, 230, 200)
logoText.BackgroundTransparency = 1

local logoSub = Instance.new("TextLabel", logoBg)
logoSub.Size = UDim2.new(1, 0, 0, 14)
logoSub.Position = UDim2.new(0, 0, 1, -16)
logoSub.Text = "◆◆◆"
logoSub.Font = Enum.Font.GothamBold
logoSub.TextSize = 8
logoSub.TextColor3 = Color3.fromRGB(0, 170, 150)
logoSub.BackgroundTransparency = 1
logoSub.TextXAlignment = Enum.TextXAlignment.Center

local logoBtn = Instance.new("TextButton", logoBg)
logoBtn.Size = UDim2.new(1, 0, 1, 0)
logoBtn.BackgroundTransparency = 1
logoBtn.Text = ""
logoBtn.ZIndex = 5

local function setLogoPos(x, y)
	logoBg.Position = UDim2.new(0, x, 0.5, -LOGO_SIZE/2 + y)
end

logoBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		logoDrag  = true; isDragged = false
		logoDragS = input.Position
		logoDragP = { x = logoBg.Position.X.Offset, y = logoBg.Position.Y.Offset + LOGO_SIZE/2 }
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if logoDrag and input.UserInputType == Enum.UserInputType.MouseMovement then
		local d = input.Position - logoDragS
		if d.Magnitude > 5 then isDragged = true end
		local nx = logoDragP.x + d.X
		local ny = logoDragP.y + d.Y - LOGO_SIZE/2
		setLogoPos(nx, ny + LOGO_SIZE/2)
		if panelOpen and panel then
			panel.Position = UDim2.new(0, nx + LOGO_SIZE + 12, 0.5, ny)
		end
	end
end)
logoBtn.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		logoDrag = false
	end
end)

-- ============================
-- 메인 패널
-- ============================
local PANEL_W = 244
local PANEL_H = 214

local panel = Instance.new("Frame", screenGui)
panel.AnchorPoint = Vector2.new(0, 0.5)
panel.Size = UDim2.new(0, PANEL_W, 0, PANEL_H)
panel.Position = UDim2.new(0, logoPosX + LOGO_SIZE + 12, 0.5, -PANEL_H/2 + logoPosY)
panel.BackgroundColor3 = Color3.fromRGB(10, 13, 22)
panel.BorderSizePixel = 0
panel.Visible = false
panel.ClipsDescendants = true
rnd(panel, 14)
makeStroke(panel, Color3.fromRGB(0, 200, 175), 1.5)
makeGrad(panel, Color3.fromRGB(14, 18, 30), Color3.fromRGB(8, 10, 18), 150)

local hdr = Instance.new("Frame", panel)
hdr.Size = UDim2.new(1, 0, 0, 50)
hdr.BackgroundColor3 = Color3.fromRGB(0, 155, 135)
hdr.BorderSizePixel = 0
rnd(hdr, 14)
makeGrad(hdr, Color3.fromRGB(0, 200, 175), Color3.fromRGB(0, 110, 95), 90)
local hdrFix = Instance.new("Frame", hdr)
hdrFix.Size = UDim2.new(1, 0, 0.5, 0); hdrFix.Position = UDim2.new(0, 0, 0.5, 0)
hdrFix.BackgroundColor3 = Color3.fromRGB(0, 110, 95); hdrFix.BorderSizePixel = 0

local hdrTitle = Instance.new("TextLabel", hdr)
hdrTitle.Size = UDim2.new(1, -90, 1, 0); hdrTitle.Position = UDim2.new(0, 14, 0, 0)
hdrTitle.Text = "MINERAL MASTER"; hdrTitle.Font = Enum.Font.GothamBlack; hdrTitle.TextSize = 14
hdrTitle.TextColor3 = Color3.new(1, 1, 1); hdrTitle.BackgroundTransparency = 1
hdrTitle.TextXAlignment = Enum.TextXAlignment.Left

local badge = Instance.new("Frame", hdr)
badge.Size = UDim2.new(0, 58, 0, 32); badge.Position = UDim2.new(1, -66, 0.5, -16)
badge.BackgroundColor3 = Color3.fromRGB(0, 70, 62); badge.BorderSizePixel = 0
rnd(badge, 8); makeStroke(badge, Color3.fromRGB(0, 190, 170), 1)

local countNum = Instance.new("TextLabel", badge)
countNum.Size = UDim2.new(1, 0, 0, 18); countNum.Position = UDim2.new(0, 0, 0, 3)
countNum.Text = "0"; countNum.Font = Enum.Font.GothamBlack; countNum.TextSize = 16
countNum.TextColor3 = Color3.fromRGB(0, 255, 220); countNum.BackgroundTransparency = 1
countNum.TextXAlignment = Enum.TextXAlignment.Center

local countWord = Instance.new("TextLabel", badge)
countWord.Size = UDim2.new(1, 0, 0, 10); countWord.Position = UDim2.new(0, 0, 0, 21)
countWord.Text = "items"; countWord.Font = Enum.Font.Gotham; countWord.TextSize = 9
countWord.TextColor3 = Color3.fromRGB(0, 190, 170); countWord.BackgroundTransparency = 1
countWord.TextXAlignment = Enum.TextXAlignment.Center

local descL = Instance.new("TextLabel", panel)
descL.Size = UDim2.new(1, -16, 0, 14); descL.Position = UDim2.new(0, 8, 0, 54)
descL.Text = "Mineral Teleport & ESP affected by Radars"
descL.Font = Enum.Font.Gotham; descL.TextSize = 10
descL.TextColor3 = Color3.fromRGB(100, 160, 150); descL.BackgroundTransparency = 1
descL.TextXAlignment = Enum.TextXAlignment.Center

local div = Instance.new("Frame", panel)
div.Size = UDim2.new(1, -20, 0, 1); div.Position = UDim2.new(0, 10, 0, 70)
div.BackgroundColor3 = Color3.fromRGB(0, 90, 80); div.BorderSizePixel = 0

local function makeBtn(parent, yPos, labelText, bgColor, bgColor2, dotColor)
	local row = Instance.new("Frame", parent)
	row.Size = UDim2.new(1, -16, 0, 38); row.Position = UDim2.new(0, 8, 0, yPos)
	row.BackgroundColor3 = bgColor; row.BorderSizePixel = 0
	rnd(row, 10); makeGrad(row, bgColor, bgColor2, 90)
	makeStroke(row, Color3.fromRGB(0, 130, 115), 1)
	local dot = Instance.new("Frame", row)
	dot.Size = UDim2.new(0, 10, 0, 10); dot.Position = UDim2.new(0, 12, 0.5, -5)
	dot.BackgroundColor3 = dotColor; dot.BorderSizePixel = 0; rndHalf(dot)
	local label = Instance.new("TextLabel", row)
	label.Size = UDim2.new(1, -36, 1, 0); label.Position = UDim2.new(0, 30, 0, 0)
	label.Text = labelText; label.Font = Enum.Font.GothamBold; label.TextSize = 13
	label.TextColor3 = Color3.new(1, 1, 1); label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	local btn = Instance.new("TextButton", row)
	btn.Size = UDim2.new(1, 0, 1, 0); btn.BackgroundTransparency = 1; btn.Text = ""
	return btn, dot, label, row
end

local overlapBtn, overlapDot, overlapLabel, overlapRow = makeBtn(panel, 78,
	"OVERLAP  ·  OFF", Color3.fromRGB(55, 18, 18), Color3.fromRGB(38, 10, 10), Color3.fromRGB(230, 70, 70))
overlapBtn.MouseButton1Click:Connect(function()
	isTracking = not isTracking
	overlapLabel.Text = isTracking and "OVERLAP  ·  ON" or "OVERLAP  ·  OFF"
	TweenService:Create(overlapDot, TweenInfo.new(0.2), {
		BackgroundColor3 = isTracking and Color3.fromRGB(60, 230, 140) or Color3.fromRGB(230, 70, 70)
	}):Play()
	makeGrad(overlapRow,
		isTracking and Color3.fromRGB(18, 55, 35) or Color3.fromRGB(55, 18, 18),
		isTracking and Color3.fromRGB(10, 38, 22) or Color3.fromRGB(38, 10, 10), 90)
end)

local espBtn, espDot, espLabel, espRow = makeBtn(panel, 122,
	"ESP          ·  ON", Color3.fromRGB(18, 42, 55), Color3.fromRGB(10, 28, 40), Color3.fromRGB(60, 230, 140))
espDot.BackgroundColor3 = Color3.fromRGB(60, 230, 140)
espBtn.MouseButton1Click:Connect(function()
	ESP_ENABLED = not ESP_ENABLED
	espLabel.Text = ESP_ENABLED and "ESP          ·  ON" or "ESP          ·  OFF"
	TweenService:Create(espDot, TweenInfo.new(0.2), {
		BackgroundColor3 = ESP_ENABLED and Color3.fromRGB(60, 230, 140) or Color3.fromRGB(230, 70, 70)
	}):Play()
	makeGrad(espRow,
		ESP_ENABLED and Color3.fromRGB(18, 42, 55) or Color3.fromRGB(55, 18, 18),
		ESP_ENABLED and Color3.fromRGB(10, 28, 40) or Color3.fromRGB(38, 10, 10), 90)
end)

local closeBtn = Instance.new("TextButton", panel)
closeBtn.Size = UDim2.new(1, -16, 0, 28); closeBtn.Position = UDim2.new(0, 8, 0, 174)
closeBtn.Text = "▼  패널 닫기"; closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 12
closeBtn.TextColor3 = Color3.fromRGB(0, 210, 185); closeBtn.BackgroundColor3 = Color3.fromRGB(10, 22, 20)
closeBtn.BorderSizePixel = 0; rnd(closeBtn, 8); makeStroke(closeBtn, Color3.fromRGB(0, 130, 115), 1)

-- ============================
-- 패널 열기/닫기
-- ============================
local function openPanel()
	panelOpen = true
	panel.Visible = true
	panel.Size = UDim2.new(0, 0, 0, 0)
	panel.AnchorPoint = Vector2.new(0, 0.5)
	panel.Position = UDim2.new(0, logoBg.Position.X.Offset + LOGO_SIZE + 12, 0.5, logoBg.Position.Y.Offset + LOGO_SIZE/2)
	TweenService:Create(panel, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, PANEL_W, 0, PANEL_H)
	}):Play()
	logoText.Text = "X"; logoText.TextColor3 = Color3.fromRGB(255, 100, 100); logoSub.Text = "close"
end

local function closePanel()
	panelOpen = false
	logoText.Text = "M"; logoText.TextColor3 = Color3.fromRGB(0, 230, 200); logoSub.Text = "◆◆◆"
	TweenService:Create(panel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 0, 0, 0)
	}):Play()
	task.delay(0.15, function() if not panelOpen then panel.Visible = false end end)
end

logoBtn.MouseButton1Up:Connect(function()
	if isDragged then return end
	if panelOpen then closePanel() else openPanel() end
end)
closeBtn.MouseButton1Click:Connect(closePanel)

-- ============================
-- 암호 화면
-- ============================
local pwReady = false
logoBg.Visible = false

local pwOverlay = Instance.new("Frame", screenGui)
pwOverlay.Size = UDim2.new(1, 0, 1, 0)
pwOverlay.BackgroundTransparency = 1
pwOverlay.BorderSizePixel = 0
pwOverlay.ZIndex = 50

local pwCard = Instance.new("Frame", pwOverlay)
pwCard.Size = UDim2.new(0, 280, 0, 268)
pwCard.AnchorPoint = Vector2.new(0.5, 0.5)
pwCard.Position = UDim2.new(0.5, 0, 0.5, 0)
pwCard.BackgroundColor3 = Color3.fromRGB(10, 14, 24)
pwCard.BorderSizePixel = 0; pwCard.ZIndex = 51
rnd(pwCard, 16); makeStroke(pwCard, Color3.fromRGB(0, 200, 175), 1.8)
makeGrad(pwCard, Color3.fromRGB(14, 20, 36), Color3.fromRGB(6, 10, 18), 150)

local lockCircle = Instance.new("Frame", pwCard)
lockCircle.Size = UDim2.new(0, 56, 0, 56); lockCircle.AnchorPoint = Vector2.new(0.5, 0)
lockCircle.Position = UDim2.new(0.5, 0, 0, 18)
lockCircle.BackgroundColor3 = Color3.fromRGB(0, 130, 115); lockCircle.BorderSizePixel = 0; lockCircle.ZIndex = 52
rndHalf(lockCircle); makeGrad(lockCircle, Color3.fromRGB(0, 180, 160), Color3.fromRGB(0, 90, 80), 135)
makeStroke(lockCircle, Color3.fromRGB(0, 220, 195), 1.5)

local lockIcon = Instance.new("TextLabel", lockCircle)
lockIcon.Size = UDim2.new(1, 0, 1, 0); lockIcon.Text = "M"
lockIcon.Font = Enum.Font.GothamBlack; lockIcon.TextScaled = true
lockIcon.TextColor3 = Color3.new(1, 1, 1); lockIcon.BackgroundTransparency = 1; lockIcon.ZIndex = 53

local pwTitle = Instance.new("TextLabel", pwCard)
pwTitle.Size = UDim2.new(1, -20, 0, 20); pwTitle.Position = UDim2.new(0, 10, 0, 84)
pwTitle.Text = "MINERAL MASTER"; pwTitle.Font = Enum.Font.GothamBlack; pwTitle.TextSize = 15
pwTitle.TextColor3 = Color3.fromRGB(0, 230, 205); pwTitle.BackgroundTransparency = 1
pwTitle.TextXAlignment = Enum.TextXAlignment.Center; pwTitle.ZIndex = 52

local pwSubtitle = Instance.new("TextLabel", pwCard)
pwSubtitle.Size = UDim2.new(1, -20, 0, 14); pwSubtitle.Position = UDim2.new(0, 10, 0, 106)
pwSubtitle.Text = "🔄 비번 불러오는 중..."; pwSubtitle.Font = Enum.Font.Gotham; pwSubtitle.TextSize = 11
pwSubtitle.TextColor3 = Color3.fromRGB(0, 200, 175); pwSubtitle.BackgroundTransparency = 1
pwSubtitle.TextXAlignment = Enum.TextXAlignment.Center; pwSubtitle.ZIndex = 52

local pwBox = Instance.new("TextBox", pwCard)
pwBox.Size = UDim2.new(1, -24, 0, 36); pwBox.Position = UDim2.new(0, 12, 0, 126)
pwBox.BackgroundColor3 = Color3.fromRGB(6, 10, 20); pwBox.BorderSizePixel = 0
pwBox.Text = ""; pwBox.PlaceholderText = "암호 입력..."
pwBox.PlaceholderColor3 = Color3.fromRGB(70, 90, 85)
pwBox.Font = Enum.Font.GothamBold; pwBox.TextSize = 14; pwBox.TextColor3 = Color3.new(1, 1, 1)
pwBox.ClearTextOnFocus = true; pwBox.TextEditable = true; pwBox.Visible = false; pwBox.ZIndex = 52
rnd(pwBox, 10); makeStroke(pwBox, Color3.fromRGB(0, 160, 140), 1.2)

local realInput = ""
pwBox:GetPropertyChangedSignal("Text"):Connect(function()
	local raw = pwBox.Text
	if #raw < #realInput then realInput = realInput:sub(1, #raw)
	else realInput = realInput .. raw:sub(#realInput + 1) end
	pwBox.Text = string.rep("*", #realInput)
	pwBox.CursorPosition = #pwBox.Text + 1
end)

local pwError = Instance.new("TextLabel", pwCard)
pwError.Size = UDim2.new(1, -20, 0, 14); pwError.Position = UDim2.new(0, 10, 0, 166)
pwError.Text = ""; pwError.Font = Enum.Font.GothamBold; pwError.TextSize = 11
pwError.TextColor3 = Color3.fromRGB(255, 80, 80); pwError.BackgroundTransparency = 1
pwError.TextXAlignment = Enum.TextXAlignment.Center; pwError.Visible = false; pwError.ZIndex = 52

local pwBtn = Instance.new("TextButton", pwCard)
pwBtn.Size = UDim2.new(1, -24, 0, 34); pwBtn.Position = UDim2.new(0, 12, 0, 182)
pwBtn.Text = "확인"; pwBtn.Font = Enum.Font.GothamBold; pwBtn.TextSize = 14
pwBtn.TextColor3 = Color3.new(1, 1, 1); pwBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 130)
pwBtn.BorderSizePixel = 0; pwBtn.Visible = false; pwBtn.ZIndex = 52
rnd(pwBtn, 10); makeGrad(pwBtn, Color3.fromRGB(0, 200, 175), Color3.fromRGB(0, 100, 88), 90)

local findBtn = Instance.new("TextButton", pwCard)
findBtn.Size = UDim2.new(1, -24, 0, 28); findBtn.Position = UDim2.new(0, 12, 0, 222)
findBtn.Text = "🔗  비번 찾기 (주소 복사)"; findBtn.Font = Enum.Font.GothamBold; findBtn.TextSize = 12
findBtn.TextColor3 = Color3.fromRGB(0, 200, 175); findBtn.BackgroundColor3 = Color3.fromRGB(8, 20, 20)
findBtn.BorderSizePixel = 0; findBtn.Visible = false; findBtn.ZIndex = 52
rnd(findBtn, 8); makeStroke(findBtn, Color3.fromRGB(0, 130, 115), 1)

findBtn.MouseButton1Click:Connect(function()
	pcall(function() setclipboard(PW_URL) end)
end)

-- GitHub 비번 불러오기
task.spawn(function()
	local success = fetchPassword()
	if success and PASSWORD then
		pwSubtitle.Text = "암호를 입력하세요"
		pwSubtitle.TextColor3 = Color3.fromRGB(100, 160, 150)
		pwBox.Visible    = true
		pwError.Visible  = true
		pwBtn.Visible    = true
		findBtn.Visible  = true
	else
		pwSubtitle.Text = "⚠ 비번 불러오기 실패\n재실행해 주세요"
		pwSubtitle.TextColor3 = Color3.fromRGB(255, 100, 80)
		pwSubtitle.TextWrapped = true
		lockIcon.Text = "!"; lockIcon.TextColor3 = Color3.fromRGB(255, 80, 80)
	end
end)

local function shakeCard()
	local orig = pwCard.Position
	for _, ox in ipairs({10,-10,8,-8,5,-5,0}) do
		pwCard.Position = UDim2.new(orig.X.Scale, orig.X.Offset + ox, orig.Y.Scale, orig.Y.Offset)
		task.wait(0.04)
	end
	pwCard.Position = orig
end

local function checkPassword()
	if realInput == PASSWORD then
		pwError.Text = "✓ 확인됨"; pwError.TextColor3 = Color3.fromRGB(60, 230, 140); pwBtn.Text = "✓"
		task.delay(0.3, function()
			pwOverlay:Destroy()
			logoBg.Visible = true
			pwReady = true
		end)
	else
		realInput = ""; pwBox.Text = ""
		pwError.Text = "⚠ 암호가 틀렸습니다"; pwError.TextColor3 = Color3.fromRGB(255, 80, 80)
		task.spawn(shakeCard)
		task.delay(1.5, function() pwError.Text = "" end)
	end
end

pwBtn.MouseButton1Click:Connect(checkPassword)
pwBox.FocusLost:Connect(function(entered) if entered then checkPassword() end end)

-- ============================
-- ESP
-- ============================
local function applyESP(obj)
	if not obj:FindFirstChild("MineralHighlight") then
		local h = Instance.new("Highlight")
		h.Name = "MineralHighlight"; h.Adornee = obj
		h.FillColor = Color3.fromRGB(0, 220, 200); h.FillTransparency = 0.5
		h.OutlineColor = Color3.fromRGB(0, 255, 230); h.OutlineTransparency = 0
		h.Parent = obj
	end
end

-- ============================
-- 메인 루프
-- ============================
RunService.Heartbeat:Connect(function()
	if not pwReady then return end
	local itemsFolder = workspace:FindFirstChild("Items", true)
	local char = localPlayer.Character
	local hrp  = char and char:FindFirstChild("HumanoidRootPart")
	if itemsFolder then
		local count = 0
		for _, obj in ipairs(itemsFolder:GetDescendants()) do
			if obj:IsA("BasePart") then
				count += 1
				if ESP_ENABLED then
					applyESP(obj)
					if obj:FindFirstChild("MineralHighlight") then obj.MineralHighlight.Enabled = true end
				else
					if obj:FindFirstChild("MineralHighlight") then obj.MineralHighlight.Enabled = false end
				end
				if isTracking and hrp then
					obj.Anchored = false; obj.CanCollide = false
					obj.CFrame = hrp.CFrame; obj.Velocity = Vector3.zero
				end
			end
		end
		if count ~= itemCount then
			itemCount = count; countNum.Text = tostring(count)
		end
	end
end)
