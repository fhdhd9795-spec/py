local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local playerGui   = localPlayer:WaitForChild("PlayerGui")

-- ============================
-- 🔐 GitHub 비번 URL
-- ============================
local PW_URL = "https://raw.githubusercontent.com/fhdhd9795-spec/py/refs/heads/main/password.txt"

-- GitHub에서 비번 가져오기
-- (익스플로잇 환경의 request() 사용)
local PASSWORD = nil   -- 나중에 채워짐

local function fetchPassword()
	local ok, result = pcall(function()
		-- 대부분 익스플로잇 지원
		local res = request({ Url = PW_URL, Method = "GET" })
		return res.Body
	end)
	if ok and result then
		-- 공백·줄바꿈 제거
		PASSWORD = result:match("^%s*(.-)%s*$")
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
-- ScreenGui
-- ============================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MineralMasterUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 999
screenGui.Parent = playerGui

-- ============================
-- 유틸 (암호 화면에서도 사용)
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
-- 동그란 로고 버튼
-- ============================
local LOGO_SIZE = 62
local logoPosX  = 20
local logoPosY  = 0   -- Y 오프셋 (0.5 Scale 기준)

local logoDrag, logoDragS, logoDragP
local isDragged = false

-- 메인 로고 원
local logoBg = Instance.new("Frame", screenGui)
logoBg.AnchorPoint = Vector2.new(0, 0.5)
logoBg.Size = UDim2.new(0, LOGO_SIZE, 0, LOGO_SIZE)
logoBg.Position = UDim2.new(0, logoPosX, 0.5, -LOGO_SIZE/2 + logoPosY)
logoBg.BackgroundColor3 = Color3.fromRGB(10, 16, 28)
logoBg.BorderSizePixel = 0
rndHalf(logoBg)
makeStroke(logoBg, Color3.fromRGB(0, 210, 185), 2)
makeGrad(logoBg, Color3.fromRGB(16, 26, 44), Color3.fromRGB(8, 12, 22), 135)

-- 로고 텍스트 (이모지 대신 안전한 문자 사용)
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
logoSub.TextScaled = false
logoSub.TextSize = 8
logoSub.TextColor3 = Color3.fromRGB(0, 170, 150)
logoSub.BackgroundTransparency = 1
logoSub.TextXAlignment = Enum.TextXAlignment.Center

-- 클릭 버튼 (투명, 맨 위)
local logoBtn = Instance.new("TextButton", logoBg)
logoBtn.Size = UDim2.new(1, 0, 1, 0)
logoBtn.BackgroundTransparency = 1
logoBtn.Text = ""
logoBtn.ZIndex = 5

-- 드래그
local function setLogoPos(x, y)
	logoBg.Position = UDim2.new(0, x, 0.5, -LOGO_SIZE/2 + y)
end

logoBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		logoDrag  = true
		isDragged = false
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
			panel.Position = UDim2.new(0, nx + LOGO_SIZE + 12, 0, 0)
			panel.AnchorPoint = Vector2.new(0, 0.5)
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

-- 상단 헤더 바
local hdr = Instance.new("Frame", panel)
hdr.Size = UDim2.new(1, 0, 0, 50)
hdr.BackgroundColor3 = Color3.fromRGB(0, 155, 135)
hdr.BorderSizePixel = 0
rnd(hdr, 14)
makeGrad(hdr, Color3.fromRGB(0, 200, 175), Color3.fromRGB(0, 110, 95), 90)

-- 헤더 하단 사각 처리
local hdrFix = Instance.new("Frame", hdr)
hdrFix.Size = UDim2.new(1, 0, 0.5, 0)
hdrFix.Position = UDim2.new(0, 0, 0.5, 0)
hdrFix.BackgroundColor3 = Color3.fromRGB(0, 110, 95)
hdrFix.BorderSizePixel = 0

-- 헤더 타이틀
local hdrTitle = Instance.new("TextLabel", hdr)
hdrTitle.Size = UDim2.new(1, -90, 1, 0)
hdrTitle.Position = UDim2.new(0, 14, 0, 0)
hdrTitle.Text = "MINERAL MASTER"
hdrTitle.Font = Enum.Font.GothamBlack
hdrTitle.TextSize = 14
hdrTitle.TextColor3 = Color3.new(1, 1, 1)  -- 순백색
hdrTitle.BackgroundTransparency = 1
hdrTitle.TextXAlignment = Enum.TextXAlignment.Left

-- 아이템 카운트 뱃지
local badge = Instance.new("Frame", hdr)
badge.Size = UDim2.new(0, 58, 0, 32)
badge.Position = UDim2.new(1, -66, 0.5, -16)
badge.BackgroundColor3 = Color3.fromRGB(0, 70, 62)
badge.BorderSizePixel = 0
rnd(badge, 8)
makeStroke(badge, Color3.fromRGB(0, 190, 170), 1)

local countNum = Instance.new("TextLabel", badge)
countNum.Size = UDim2.new(1, 0, 0, 18)
countNum.Position = UDim2.new(0, 0, 0, 3)
countNum.Text = "0"
countNum.Font = Enum.Font.GothamBlack
countNum.TextSize = 16
countNum.TextColor3 = Color3.fromRGB(0, 255, 220)  -- 밝은 민트
countNum.BackgroundTransparency = 1
countNum.TextXAlignment = Enum.TextXAlignment.Center

local countWord = Instance.new("TextLabel", badge)
countWord.Size = UDim2.new(1, 0, 0, 10)
countWord.Position = UDim2.new(0, 0, 0, 21)
countWord.Text = "items"
countWord.Font = Enum.Font.Gotham
countWord.TextSize = 9
countWord.TextColor3 = Color3.fromRGB(0, 190, 170)
countWord.BackgroundTransparency = 1
countWord.TextXAlignment = Enum.TextXAlignment.Center

-- 설명
local descL = Instance.new("TextLabel", panel)
descL.Size = UDim2.new(1, -16, 0, 14)
descL.Position = UDim2.new(0, 8, 0, 54)
descL.Text = "Mineral Teleport & ESP affected by Radars"
descL.Font = Enum.Font.Gotham
descL.TextSize = 10
descL.TextColor3 = Color3.fromRGB(100, 160, 150)  -- 보이는 색
descL.BackgroundTransparency = 1
descL.TextXAlignment = Enum.TextXAlignment.Center

-- 구분선
local div = Instance.new("Frame", panel)
div.Size = UDim2.new(1, -20, 0, 1)
div.Position = UDim2.new(0, 10, 0, 70)
div.BackgroundColor3 = Color3.fromRGB(0, 90, 80)
div.BorderSizePixel = 0

-- ============================
-- 버튼 생성
-- ============================
local function makeBtn(parent, yPos, labelText, bgColor, bgColor2, dotColor)
	local row = Instance.new("Frame", parent)
	row.Size = UDim2.new(1, -16, 0, 38)
	row.Position = UDim2.new(0, 8, 0, yPos)
	row.BackgroundColor3 = bgColor
	row.BorderSizePixel = 0
	rnd(row, 10)
	makeGrad(row, bgColor, bgColor2, 90)
	makeStroke(row, Color3.fromRGB(0, 130, 115), 1)

	-- 왼쪽 상태 도트
	local dot = Instance.new("Frame", row)
	dot.Size = UDim2.new(0, 10, 0, 10)
	dot.Position = UDim2.new(0, 12, 0.5, -5)
	dot.BackgroundColor3 = dotColor
	dot.BorderSizePixel = 0
	rndHalf(dot)

	-- 버튼 라벨 (밝은 흰색으로)
	local label = Instance.new("TextLabel", row)
	label.Size = UDim2.new(1, -36, 1, 0)
	label.Position = UDim2.new(0, 30, 0, 0)
	label.Text = labelText
	label.Font = Enum.Font.GothamBold
	label.TextSize = 13
	label.TextColor3 = Color3.new(1, 1, 1)  -- 순백
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left

	-- 투명 클릭 버튼
	local btn = Instance.new("TextButton", row)
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.BackgroundTransparency = 1
	btn.Text = ""

	return btn, dot, label, row
end

-- OVERLAP 버튼
local overlapBtn, overlapDot, overlapLabel, overlapRow = makeBtn(panel, 78,
	"OVERLAP  ·  OFF",
	Color3.fromRGB(55, 18, 18),
	Color3.fromRGB(38, 10, 10),
	Color3.fromRGB(230, 70, 70)
)

overlapBtn.MouseButton1Click:Connect(function()
	isTracking = not isTracking
	overlapLabel.Text = isTracking and "OVERLAP  ·  ON" or "OVERLAP  ·  OFF"
	TweenService:Create(overlapDot, TweenInfo.new(0.2), {
		BackgroundColor3 = isTracking
			and Color3.fromRGB(60, 230, 140)
			or  Color3.fromRGB(230, 70, 70)
	}):Play()
	makeGrad(overlapRow,
		isTracking and Color3.fromRGB(18, 55, 35) or Color3.fromRGB(55, 18, 18),
		isTracking and Color3.fromRGB(10, 38, 22) or Color3.fromRGB(38, 10, 10),
		90
	)
end)

-- ESP 버튼
local espBtn, espDot, espLabel, espRow = makeBtn(panel, 122,
	"ESP          ·  ON",
	Color3.fromRGB(18, 42, 55),
	Color3.fromRGB(10, 28, 40),
	Color3.fromRGB(60, 230, 140)
)

espBtn.MouseButton1Click:Connect(function()
	ESP_ENABLED = not ESP_ENABLED
	espLabel.Text = ESP_ENABLED and "ESP          ·  ON" or "ESP          ·  OFF"
	TweenService:Create(espDot, TweenInfo.new(0.2), {
		BackgroundColor3 = ESP_ENABLED
			and Color3.fromRGB(60, 230, 140)
			or  Color3.fromRGB(230, 70, 70)
	}):Play()
	makeGrad(espRow,
		ESP_ENABLED and Color3.fromRGB(18, 42, 55) or Color3.fromRGB(55, 18, 18),
		ESP_ENABLED and Color3.fromRGB(10, 28, 40) or Color3.fromRGB(38, 10, 10),
		90
	)
end)

-- 닫기
local closeBtn = Instance.new("TextButton", panel)
closeBtn.Size = UDim2.new(1, -16, 0, 28)
closeBtn.Position = UDim2.new(0, 8, 0, 174)
closeBtn.Text = "▼  패널 닫기"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 12
closeBtn.TextColor3 = Color3.fromRGB(0, 210, 185)  -- 잘 보이는 민트색
closeBtn.BackgroundColor3 = Color3.fromRGB(10, 22, 20)
closeBtn.BorderSizePixel = 0
rnd(closeBtn, 8)
makeStroke(closeBtn, Color3.fromRGB(0, 130, 115), 1)

-- ============================
-- 패널 열기 / 닫기
-- ============================
local function openPanel()
	panelOpen = true
	panel.Visible = true
	panel.Size = UDim2.new(0, 0, 0, 0)
	panel.AnchorPoint = Vector2.new(0, 0.5)
	panel.Position = UDim2.new(
		0, logoBg.Position.X.Offset + LOGO_SIZE + 12,
		0.5, logoBg.Position.Y.Offset + LOGO_SIZE/2
	)
	TweenService:Create(panel, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, PANEL_W, 0, PANEL_H)
	}):Play()
	logoText.Text = "X"
	logoText.TextColor3 = Color3.fromRGB(255, 100, 100)
	logoSub.Text = "close"
end

local function closePanel()
	panelOpen = false
	logoText.Text = "M"
	logoText.TextColor3 = Color3.fromRGB(0, 230, 200)
	logoSub.Text = "◆◆◆"
	TweenService:Create(panel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 0, 0, 0)
	}):Play()
	task.delay(0.15, function()
		if not panelOpen then panel.Visible = false end
	end)
end

logoBtn.MouseButton1Up:Connect(function()
	if isDragged then return end
	if panelOpen then closePanel() else openPanel() end
end)

closeBtn.MouseButton1Click:Connect(closePanel)

-- ============================
-- ESP
-- ============================
local function applyESP(obj)
	if not obj:FindFirstChild("MineralHighlight") then
		local h = Instance.new("Highlight")
		h.Name = "MineralHighlight"
		h.Adornee = obj
		h.FillColor = Color3.fromRGB(0, 220, 200)
		h.FillTransparency = 0.5
		h.OutlineColor = Color3.fromRGB(0, 255, 230)
		h.OutlineTransparency = 0
		h.Parent = obj
	end
end

-- ============================
-- 🔐 암호 입력 화면
-- ============================
local pwReady = false   -- 암호 통과 여부

-- ============================
-- 🔐 암호 입력 화면
-- ============================
local pwReady = false

-- 처음엔 로고·패널 숨김
logoBg.Visible = false

-- 전체 화면 어두운 오버레이
local pwOverlay = Instance.new("Frame", screenGui)
pwOverlay.Size = UDim2.new(1, 0, 1, 0)
pwOverlay.BackgroundTransparency = 1
pwOverlay.BorderSizePixel = 0
pwOverlay.ZIndex = 50

-- 중앙 카드
local pwCard = Instance.new("Frame", pwOverlay)
pwCard.Size = UDim2.new(0, 280, 0, 268)
pwCard.AnchorPoint = Vector2.new(0.5, 0.5)
pwCard.Position = UDim2.new(0.5, 0, 0.5, 0)
pwCard.BackgroundColor3 = Color3.fromRGB(10, 14, 24)
pwCard.BorderSizePixel = 0
pwCard.ZIndex = 51
rnd(pwCard, 16)
makeStroke(pwCard, Color3.fromRGB(0, 200, 175), 1.8)
makeGrad(pwCard, Color3.fromRGB(14, 20, 36), Color3.fromRGB(6, 10, 18), 150)

-- 자물쇠 아이콘 원
local lockCircle = Instance.new("Frame", pwCard)
lockCircle.Size = UDim2.new(0, 56, 0, 56)
lockCircle.AnchorPoint = Vector2.new(0.5, 0)
lockCircle.Position = UDim2.new(0.5, 0, 0, 18)
lockCircle.BackgroundColor3 = Color3.fromRGB(0, 130, 115)
lockCircle.BorderSizePixel = 0
lockCircle.ZIndex = 52
rndHalf(lockCircle)
makeGrad(lockCircle, Color3.fromRGB(0, 180, 160), Color3.fromRGB(0, 90, 80), 135)
makeStroke(lockCircle, Color3.fromRGB(0, 220, 195), 1.5)

local lockIcon = Instance.new("TextLabel", lockCircle)
lockIcon.Size = UDim2.new(1, 0, 1, 0)
lockIcon.Text = "M"
lockIcon.Font = Enum.Font.GothamBlack
lockIcon.TextScaled = true
lockIcon.TextColor3 = Color3.new(1, 1, 1)
lockIcon.BackgroundTransparency = 1
lockIcon.ZIndex = 53

-- 타이틀
local pwTitle = Instance.new("TextLabel", pwCard)
pwTitle.Size = UDim2.new(1, -20, 0, 20)
pwTitle.Position = UDim2.new(0, 10, 0, 84)
pwTitle.Text = "MINERAL MASTER"
pwTitle.Font = Enum.Font.GothamBlack
pwTitle.TextSize = 15
pwTitle.TextColor3 = Color3.fromRGB(0, 230, 205)
pwTitle.BackgroundTransparency = 1
pwTitle.TextXAlignment = Enum.TextXAlignment.Center
pwTitle.ZIndex = 52

-- 서브타이틀 (로딩 상태 표시에도 사용)
local pwSubtitle = Instance.new("TextLabel", pwCard)
pwSubtitle.Size = UDim2.new(1, -20, 0, 14)
pwSubtitle.Position = UDim2.new(0, 10, 0, 106)
pwSubtitle.Text = "🔄 비번 불러오는 중..."
pwSubtitle.Font = Enum.Font.Gotham
pwSubtitle.TextSize = 11
pwSubtitle.TextColor3 = Color3.fromRGB(0, 200, 175)
pwSubtitle.BackgroundTransparency = 1
pwSubtitle.TextXAlignment = Enum.TextXAlignment.Center
pwSubtitle.ZIndex = 52

-- 입력창 (처음엔 숨김)
local pwBox = Instance.new("TextBox", pwCard)
pwBox.Size = UDim2.new(1, -24, 0, 36)
pwBox.Position = UDim2.new(0, 12, 0, 126)
pwBox.BackgroundColor3 = Color3.fromRGB(6, 10, 20)
pwBox.BorderSizePixel = 0
pwBox.Text = ""
pwBox.PlaceholderText = "암호 입력..."
pwBox.PlaceholderColor3 = Color3.fromRGB(70, 90, 85)
pwBox.Font = Enum.Font.GothamBold
pwBox.TextSize = 14
pwBox.TextColor3 = Color3.new(1, 1, 1)
pwBox.ClearTextOnFocus = true
pwBox.TextEditable = true
pwBox.Visible = false
pwBox.ZIndex = 52
rnd(pwBox, 10)
makeStroke(pwBox, Color3.fromRGB(0, 160, 140), 1.2)

-- 마스킹
local realInput = ""
pwBox:GetPropertyChangedSignal("Text"):Connect(function()
	local raw = pwBox.Text
	if #raw < #realInput then
		realInput = realInput:sub(1, #raw)
	else
		realInput = realInput .. raw:sub(#realInput + 1)
	end
	pwBox.Text = string.rep("*", #realInput)
	pwBox.CursorPosition = #pwBox.Text + 1
end)

-- 오류 라벨
local pwError = Instance.new("TextLabel", pwCard)
pwError.Size = UDim2.new(1, -20, 0, 14)
pwError.Position = UDim2.new(0, 10, 0, 166)
pwError.Text = ""
pwError.Font = Enum.Font.GothamBold
pwError.TextSize = 11
pwError.TextColor3 = Color3.fromRGB(255, 80, 80)
pwError.BackgroundTransparency = 1
pwError.TextXAlignment = Enum.TextXAlignment.Center
pwError.Visible = false
pwError.ZIndex = 52

-- 확인 버튼 (처음엔 숨김)
local pwBtn = Instance.new("TextButton", pwCard)
pwBtn.Size = UDim2.new(1, -24, 0, 34)
pwBtn.Position = UDim2.new(0, 12, 0, 182)
pwBtn.Text = "확인"
pwBtn.Font = Enum.Font.GothamBold
pwBtn.TextSize = 14
pwBtn.TextColor3 = Color3.new(1, 1, 1)
pwBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 130)
pwBtn.BorderSizePixel = 0
pwBtn.Visible = false
pwBtn.ZIndex = 52
rnd(pwBtn, 10)
makeGrad(pwBtn, Color3.fromRGB(0, 200, 175), Color3.fromRGB(0, 100, 88), 90)

-- 비번 찾기 버튼 (처음엔 숨김)
local findBtn = Instance.new("TextButton", pwCard)
findBtn.Size = UDim2.new(1, -24, 0, 28)
findBtn.Position = UDim2.new(0, 12, 0, 222)
findBtn.Text = "🔗  비번 찾기 (주소 복사)"
findBtn.Font = Enum.Font.GothamBold
findBtn.TextSize = 12
findBtn.TextColor3 = Color3.fromRGB(0, 200, 175)
findBtn.BackgroundColor3 = Color3.fromRGB(8, 20, 20)
findBtn.BorderSizePixel = 0
findBtn.Visible = false
findBtn.ZIndex = 52
rnd(findBtn, 8)
makeStroke(findBtn, Color3.fromRGB(0, 130, 115), 1)

-- 복사됨 알림 토스트
local toastFrame = Instance.new("Frame", screenGui)
toastFrame.Size = UDim2.new(0, 200, 0, 36)
toastFrame.AnchorPoint = Vector2.new(0.5, 1)
toastFrame.Position = UDim2.new(0.5, 0, 1, 20)   -- 처음엔 화면 아래 숨김
toastFrame.BackgroundColor3 = Color3.fromRGB(0, 160, 140)
toastFrame.BorderSizePixel = 0
toastFrame.ZIndex = 100
rnd(toastFrame, 10)
makeGrad(toastFrame, Color3.fromRGB(0, 200, 175), Color3.fromRGB(0, 110, 100), 90)

local toastLabel = Instance.new("TextLabel", toastFrame)
toastLabel.Size = UDim2.new(1, 0, 1, 0)
toastLabel.Text = "✅ 주소가 복사됐습니다!"
toastLabel.Font = Enum.Font.GothamBold
toastLabel.TextSize = 13
toastLabel.TextColor3 = Color3.new(1, 1, 1)
toastLabel.BackgroundTransparency = 1
toastLabel.TextXAlignment = Enum.TextXAlignment.Center
toastLabel.ZIndex = 101

-- 토스트 표시 함수
local toastActive = false
local function showToast()
	if toastActive then return end
	toastActive = true
	-- 위로 슬라이드
	TweenService:Create(toastFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 1, -20)
	}):Play()
	task.delay(2, function()
		-- 아래로 사라짐
		TweenService:Create(toastFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, 1, 20)
		}):Play()
		task.delay(0.25, function()
			toastActive = false
		end)
	end)
end

-- 비번 찾기 클릭 → URL 복사 + 토스트
findBtn.MouseButton1Click:Connect(function()
	pcall(function()
		setclipboard(PW_URL)
	end)
	showToast()
end)

-- ✅ GitHub에서 비번 불러오고 입력창 열기
task.spawn(function()
	local success = fetchPassword()
	if success and PASSWORD then
		-- 불러오기 성공 → 입력창 표시
		pwSubtitle.Text = "암호를 입력하세요"
		pwSubtitle.TextColor3 = Color3.fromRGB(100, 160, 150)
		pwBox.Visible    = true
		pwError.Visible  = true
		pwBtn.Visible    = true
		findBtn.Visible  = true
	else
		-- 불러오기 실패
		pwSubtitle.Text = "⚠ 비번 불러오기 실패\n인터넷 연결 확인 후 재실행하세요"
		pwSubtitle.TextColor3 = Color3.fromRGB(255, 100, 80)
		pwSubtitle.TextWrapped = true
		lockIcon.Text = "!"
		lockIcon.TextColor3 = Color3.fromRGB(255, 80, 80)
	end
end)

-- 흔들기 애니메이션 (틀렸을 때)
local function shakeCard()
	local orig = pwCard.Position
	local offsets = {10, -10, 8, -8, 5, -5, 0}
	for _, ox in ipairs(offsets) do
		pwCard.Position = UDim2.new(orig.X.Scale, orig.X.Offset + ox, orig.Y.Scale, orig.Y.Offset)
		task.wait(0.04)
	end
	pwCard.Position = orig
end

-- 암호 확인 함수
local function checkPassword()
	if realInput == PASSWORD then
		-- ✅ 성공
		pwError.Text = "✓ 확인됨"
		pwError.TextColor3 = Color3.fromRGB(60, 230, 140)
		pwBtn.Text = "✓"
		task.delay(0.3, function()
			pwOverlay:Destroy()
			logoBg.Visible = true
			pwReady = true
		end)
	else
		-- ❌ 실패
		realInput = ""
		pwBox.Text = ""
		pwError.Text = "⚠ 암호가 틀렸습니다"
		pwError.TextColor3 = Color3.fromRGB(255, 80, 80)
		TweenService:Create(makeStroke(pwBox, Color3.fromRGB(255, 60, 60), 1.8),
			TweenInfo.new(1), {}):Play()
		task.spawn(shakeCard)
		task.delay(1.5, function()
			pwError.Text = ""
		end)
	end
end

pwBtn.MouseButton1Click:Connect(checkPassword)

-- Enter 키로도 제출
pwBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then checkPassword() end
end)

-- ============================
-- 메인 루프 (암호 통과 후에만 작동)
-- ============================
RunService.Heartbeat:Connect(function()
	if not pwReady then return end   -- 🔐 암호 통과 전엔 아무것도 안 함
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
					if obj:FindFirstChild("MineralHighlight") then
						obj.MineralHighlight.Enabled = true
					end
				else
					if obj:FindFirstChild("MineralHighlight") then
						obj.MineralHighlight.Enabled = false
					end
				end
				if isTracking and hrp then
					obj.Anchored   = false
					obj.CanCollide = false
					obj.CFrame     = hrp.CFrame
					obj.Velocity   = Vector3.zero
				end
			end
		end
		if count ~= itemCount then
			itemCount = count
			countNum.Text = tostring(count)
		end
	end
end)
