--[[
  GachaUIBuilder (ModuleScript)
  »Ì±â Ã¢ UI¸¦ »ý¼ºÇÕ´Ï´Ù.
]]
local GachaUIBuilder = {}

function GachaUIBuilder.Build(mainGui, backgroundFrame, framesFolder, GuiUtils)
	print("GachaUIBuilder: »Ì±â Ã¢ UI »ý¼º ½ÃÀÛ...")

	local cornerRadius = UDim.new(0, 8)

	local gachaFrame = Instance.new("Frame")
	gachaFrame.Name = "GachaFrame"
	gachaFrame.Parent = backgroundFrame -- BackgroundFrame ¾Æ·¡¿¡ ¹èÄ¡ (ÆË¾÷ ÇüÅÂ)
	gachaFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	gachaFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	gachaFrame.Size = UDim2.new(0.5, 0, 0.6, 0)
	gachaFrame.BackgroundColor3 = Color3.fromRGB(80, 60, 80)
	gachaFrame.BorderColor3 = Color3.fromRGB(210, 190, 210)
	gachaFrame.BorderSizePixel = 2
	gachaFrame.Visible = false
	gachaFrame.ZIndex = 5
	Instance.new("UICorner", gachaFrame).CornerRadius = cornerRadius
	print("GachaUIBuilder: GachaFrame »ý¼ºµÊ")

	GuiUtils.CreateTextLabel(gachaFrame, "TitleLabel", UDim2.new(0.5, 0, 0.05, 0), UDim2.new(0.9, 0, 0.1, 0), "¾ÆÀÌÅÛ »Ì±â", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 20)
	GuiUtils.CreateTextLabel(gachaFrame, "PlayerCurrencyLabel", UDim2.new(0.95, 0, 0.05, 0), UDim2.new(0.4, 0, 0.1, 0), "º¸À¯ °ñµå: ???", Vector2.new(1, 0), Enum.TextXAlignment.Right, Enum.TextYAlignment.Center, 16)

	local pullOptionsFrame = Instance.new("Frame")
	pullOptionsFrame.Name = "PullOptionsFrame"
	pullOptionsFrame.Size = UDim2.new(0.9, 0, 0.2, 0)
	pullOptionsFrame.Position = UDim2.new(0.5, 0, 0.2, 0)
	pullOptionsFrame.AnchorPoint = Vector2.new(0.5, 0)
	pullOptionsFrame.BackgroundTransparency = 1
	pullOptionsFrame.Parent = gachaFrame
	local pullOptionsLayout = Instance.new("UIListLayout")
	pullOptionsLayout.FillDirection = Enum.FillDirection.Horizontal
	pullOptionsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	pullOptionsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	pullOptionsLayout.Padding = UDim.new(0, 15)
	pullOptionsLayout.Parent = pullOptionsFrame
	print("GachaUIBuilder: Gacha PullOptionsFrame »ý¼ºµÊ")

	local pullNormal1Button = Instance.new("TextButton")
	pullNormal1Button.Name = "PullNormal1Button"
	pullNormal1Button.Size = UDim2.new(0, 150, 0, 40)
	pullNormal1Button.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
	pullNormal1Button.TextColor3 = Color3.fromRGB(255, 255, 255)
	pullNormal1Button.Text = "ÀÏ¹Ý »Ì±â (100 G)"
	pullNormal1Button.Font = Enum.Font.SourceSansBold
	pullNormal1Button.TextSize = 14
	pullNormal1Button.Parent = pullOptionsFrame
	Instance.new("UICorner", pullNormal1Button).CornerRadius = cornerRadius
	print("GachaUIBuilder: Gacha PullNormal1Button »ý¼ºµÊ")

	local resultDisplayFrame = Instance.new("Frame")
	resultDisplayFrame.Name = "ResultDisplayFrame"
	resultDisplayFrame.Size = UDim2.new(0.8, 0, 0.4, 0)
	resultDisplayFrame.Position = UDim2.new(0.5, 0, 0.45, 0)
	resultDisplayFrame.AnchorPoint = Vector2.new(0.5, 0)
	resultDisplayFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
	resultDisplayFrame.BorderSizePixel = 1
	resultDisplayFrame.Parent = gachaFrame
	Instance.new("UICorner", resultDisplayFrame).CornerRadius = cornerRadius
	print("GachaUIBuilder: Gacha ResultDisplayFrame »ý¼ºµÊ")

	local resultItemImage = Instance.new("ImageLabel")
	resultItemImage.Name = "ResultItemImage"
	resultItemImage.Size = UDim2.new(0, 80, 0, 80)
	resultItemImage.Position = UDim2.new(0.5, 0, 0.3, 0)
	resultItemImage.AnchorPoint = Vector2.new(0.5, 0.5)
	resultItemImage.BackgroundTransparency = 1
	resultItemImage.ScaleType = Enum.ScaleType.Fit
	resultItemImage.Visible = false
	resultItemImage.Parent = resultDisplayFrame
	Instance.new("UICorner", resultItemImage).CornerRadius = cornerRadius

	local resultItemName = GuiUtils.CreateTextLabel(resultDisplayFrame, "ResultItemName", UDim2.new(0.5, 0, 0.7, 0), UDim2.new(0.9, 0, 0.2, 0), "", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 18)
	resultItemName.Visible = false

	local closeGachaButton = Instance.new("TextButton")
	closeGachaButton.Name = "CloseButton"
	closeGachaButton.Parent = gachaFrame
	closeGachaButton.AnchorPoint = Vector2.new(1, 1)
	closeGachaButton.Position = UDim2.new(0.95, 0, 0.95, 0)
	closeGachaButton.Size = UDim2.new(0.2, 0, 0.1, 0)
	closeGachaButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
	closeGachaButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeGachaButton.TextScaled = true
	closeGachaButton.Font = Enum.Font.SourceSansBold
	closeGachaButton.Text = "´Ý±â"
	closeGachaButton.BorderSizePixel = 0
	closeGachaButton.ZIndex = 6
	Instance.new("UICorner", closeGachaButton).CornerRadius = cornerRadius
	print("GachaUIBuilder: GachaFrame CloseButton »ý¼ºµÊ")

	print("GachaUIBuilder: »Ì±â Ã¢ UI »ý¼º ¿Ï·á.")
end

return GachaUIBuilder
