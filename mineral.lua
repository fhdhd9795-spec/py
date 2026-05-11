local Players    = game:GetService("Players")
local UIS        = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui    = game:GetService("CoreGui")

local player = Players.LocalPlayer

local old = CoreGui:FindFirstChild("TpUI")
if old then old:Destroy() end

-- ============================
-- 목적지 목록
-- ============================
local DESTINATIONS = {
	{
		label = "🌤 Sky Island [44]",
		path  = 'workspace["Sky Island"]:GetChildren()[44]',
		getter = function() return workspace["Sky Island"]:GetChildren()[44] end,
	},
	{
		label = "🏝 Base detail [38]",
		path  = "workspace.Base.detail:GetChildren()[38]",
		getter = function() return workspace.Base.detail:GetChildren()[38] end,
	},
}

-- ============================
-- 순간이동 함수 (공용)
-- ============================
local function resolveCF(obj)
	if obj:IsA("BasePart") then
		return obj.CFrame * CFrame.new(0, obj.Size.Y / 2 + 3, 0)
	elseif obj:IsA("Model") then
		local ok, cf = pcall(function() return obj:GetPivot() end)
		return ok and (cf * CFrame.new(0, 4, 0)) or nil
	else
		local part = obj:FindFirstChildWhichIsA("BasePart", true)
		return part and (part.CFrame * CFrame.new(0, part.Size.Y / 2 + 3, 0)) or nil
	end
end

local function teleportTo(dest, onDone, onFail)
	local char = player.Character
	if not char then onFail("캐릭터 없음"); return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then onFail("HumanoidRootPart 없음"); return end

	local ok, obj = pcall(dest.getter)
	if not ok or not obj then onFail("경로를 찾을 수 없음"); return end

	local cf = resolveCF(obj)
	if not cf then onFail("이동 위치 없음"); return end

	hrp.CFrame = cf
	onDone()
end

-- ============================
-- 유틸
-- ============================
local function corner(p,r) local c=Instance.new("UICorner",p);c.CornerRadius=UDim.new(0,r or 8) end
local function stroke(p,col,t) local s=Instance.new("UIStroke",p);s.Color=col or Color3.fromRGB(55,55,65);s.Thickness=t or 1 end
local function grad(p,c0,c1,rot) local g=Instance.new("UIGradient",p);g.Color=ColorSequence.new(c0,c1);g.Rotation=rot or 90 end

-- ============================
-- GUI
-- ============================
local gui = Instance.new("ScreenGui", CoreGui)
gui.Name="TpUI"; gui.ResetOnSpawn=false
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; gui.DisplayOrder=993

-- 버튼 수에 맞게 높이 계산
local BTN_H   = 42
local PADDING = 8
local totalH  = 42 + PADDING + #DESTINATIONS * (BTN_H + 6) + 26 + PADDING

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 240, 0, totalH)
main.Position = UDim2.new(0.5, -120, 1, -(totalH + 20))
main.BackgroundColor3 = Color3.fromRGB(10,10,16); main.BorderSizePixel=0
corner(main,12); stroke(main, Color3.fromRGB(100,160,255), 1.2)
grad(main, Color3.fromRGB(10,12,20), Color3.fromRGB(8,8,15), 145)

-- 헤더
local hdr=Instance.new("Frame",main)
hdr.Size=UDim2.new(1,0,0,38); hdr.BackgroundColor3=Color3.fromRGB(40,80,200)
hdr.BorderSizePixel=0; corner(hdr,12)
grad(hdr, Color3.fromRGB(70,120,255), Color3.fromRGB(30,60,180), 90)
local hfix=Instance.new("Frame",hdr); hfix.Size=UDim2.new(1,0,0.5,0); hfix.Position=UDim2.new(0,0,0.5,0)
hfix.BackgroundColor3=Color3.fromRGB(30,60,180); hfix.BorderSizePixel=0

local titleL=Instance.new("TextLabel",hdr)
titleL.Size=UDim2.new(1,-38,1,0); titleL.Position=UDim2.new(0,12,0,0)
titleL.Text="✈  순간이동"; titleL.Font=Enum.Font.GothamBold; titleL.TextSize=14
titleL.TextColor3=Color3.new(1,1,1); titleL.BackgroundTransparency=1
titleL.TextXAlignment=Enum.TextXAlignment.Left

local closeX=Instance.new("TextButton",hdr)
closeX.Size=UDim2.new(0,26,0,26); closeX.Position=UDim2.new(1,-32,0.5,-13)
closeX.Text="✕"; closeX.Font=Enum.Font.GothamBold; closeX.TextSize=12
closeX.TextColor3=Color3.new(1,1,1); closeX.BackgroundColor3=Color3.fromRGB(200,50,50)
closeX.BorderSizePixel=0; corner(closeX,6)
closeX.MouseButton1Click:Connect(function() gui:Destroy() end)

-- 드래그
local drag,dragS,dragP
hdr.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true;dragS=i.Position;dragP=main.Position end end)
UIS.InputChanged:Connect(function(i)
	if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
		local d=i.Position-dragS
		main.Position=UDim2.new(dragP.X.Scale,dragP.X.Offset+d.X,dragP.Y.Scale,dragP.Y.Offset+d.Y)
	end
end)
hdr.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)

-- 상태 라벨
local statusL=Instance.new("TextLabel",main)
statusL.Size=UDim2.new(1,-16,0,18); statusL.Position=UDim2.new(0,8,0,42)
statusL.Text="목적지를 선택해주세요"; statusL.Font=Enum.Font.Gotham; statusL.TextSize=11
statusL.TextColor3=Color3.fromRGB(140,150,175); statusL.BackgroundTransparency=1
statusL.TextXAlignment=Enum.TextXAlignment.Center

-- 목적지 버튼 생성
local COLORS = {
	{ Color3.fromRGB(60,110,255), Color3.fromRGB(30,70,200) },   -- 파랑
	{ Color3.fromRGB(40,160,80),  Color3.fromRGB(20,110,45) },   -- 초록
	{ Color3.fromRGB(180,80,220), Color3.fromRGB(130,40,180) },  -- 보라
	{ Color3.fromRGB(220,130,20), Color3.fromRGB(160,90,10) },   -- 주황
}

for i, dest in ipairs(DESTINATIONS) do
	local yPos = 38 + PADDING + (i-1) * (BTN_H + 6)
	local col = COLORS[((i-1) % #COLORS) + 1]

	-- 경로 표시
	local pathLbl=Instance.new("TextLabel",main)
	pathLbl.Size=UDim2.new(1,-16,0,12); pathLbl.Position=UDim2.new(0,8,0,yPos+2)
	pathLbl.Text="📂 "..dest.path; pathLbl.Font=Enum.Font.Gotham; pathLbl.TextSize=9
	pathLbl.TextColor3=Color3.fromRGB(100,120,200); pathLbl.BackgroundTransparency=1
	pathLbl.TextXAlignment=Enum.TextXAlignment.Left; pathLbl.TextTruncate=Enum.TextTruncate.AtEnd

	-- 이동 버튼
	local btn=Instance.new("TextButton",main)
	btn.Size=UDim2.new(1,-16,0,BTN_H-16); btn.Position=UDim2.new(0,8,0,yPos+14)
	btn.Text=dest.label; btn.Font=Enum.Font.GothamBold; btn.TextSize=13
	btn.TextColor3=Color3.new(1,1,1); btn.BorderSizePixel=0; corner(btn,8)
	grad(btn, col[1], col[2], 90)

	btn.MouseButton1Click:Connect(function()
		btn.Text="⏳..."; btn.Active=false

		teleportTo(dest,
			function()
				btn.Text="✅ "..dest.label; btn.Active=true
				statusL.Text="✅ 도착: "..dest.label
				statusL.TextColor3=Color3.fromRGB(80,220,100)
				task.delay(1.5, function()
					if btn and btn.Parent then
						btn.Text=dest.label
						statusL.Text="목적지를 선택해주세요"
						statusL.TextColor3=Color3.fromRGB(140,150,175)
					end
				end)
			end,
			function(msg)
				btn.Text=dest.label; btn.Active=true
				statusL.Text="⚠ "..msg
				statusL.TextColor3=Color3.fromRGB(255,100,100)
			end
		)
	end)
end
