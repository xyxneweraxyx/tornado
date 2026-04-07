--/ SERVICES
local ss = game:GetService("ServerStorage")
local ts = game:GetService("TweenService")

--/ INGAME USAGE
local tornadoFolder   = ss.tornado
local disastersFolder = workspace.disasters

local toCopy  = tornadoFolder.toCopy
local cloud   = tornadoFolder.cloud

--/ SCRIPT USAGE
local absorptionParams = OverlapParams.new()
absorptionParams.CollisionGroup = "destructible"

local flyingParams = OverlapParams.new()
flyingParams.CollisionGroup = "flying"

--/ VARIABLES
local tornadoHeight = 200

--/ FUNCTIONS

--// MATH FUNCTIONS

local function calculateAbsorptionChance(part: Part, tornado: MeshPart, windspeeds: number)

	local blockWeight    = part.Mass*math.random(80,120)/100
	local tornadoSize    = tornado.Size.X/4
	local distanceToWall = math.clamp((Vector3.new(part.Position.X, 0, part.Position.Z) - Vector3.new(tornado.Position.X, 0, tornado.Position.Z)).Magnitude - (tornadoSize+part.Size.X), 0, 250)

	local exponentDivider = (0.7*tornadoSize + 0.01*windspeeds + 20/(1+0.1*tornadoSize))
	local exponent        = -1 * math.pow(distanceToWall, 1.5) / exponentDivider
	local multiplier      = math.pow(windspeeds, 1+windspeeds/2000) / math.pow(blockWeight, 1+blockWeight/2000)
	local finalResult     = multiplier*math.exp(exponent) / 2

	return math.round(finalResult*1000)/(1000*math.random(7,15)/10)

end

local function calculateFireChance(part: Part, tornado: MeshPart, fireSpread: number)
	
	local tornadoSize = tornado.Size.X/4
	local distanceToWall = math.clamp((Vector3.new(part.Position.X, 0, part.Position.Z) - Vector3.new(tornado.Position.X, 0, tornado.Position.Z)).Magnitude - (tornadoSize+part.Size.X), 0, 250)
	
	local exponentDivisor = 3*fireSpread + tornadoSize + 50
	local exponent        = math.pow(distanceToWall, 1.5) / exponentDivisor * -1
	local finalResult     = math.exp(exponent) * (10*fireSpread+10)/1000
	return math.round(finalResult*1000)/(1000*math.random(7,13)/10)	
	
end





--// SIDE FUNCTIONS

local function generateCloudCircle(originPoint: Vector3, radius: number, amount: number, folder: Folder): Model
	
	local scale    = Instance.new("NumberValue")
	local rotation = Instance.new("NumberPose")
	local cloudSizeMultiplier = radius/100
	local tween  = ts:Create(scale, TweenInfo.new(2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Value = 1})
	local tween2 = ts:Create(rotation, TweenInfo.new(2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Value = 0})
	
	scale.Value    = 0.01
	rotation.Value = 10

	local model = Instance.new("Model")
	model:PivotTo(CFrame.new(originPoint))

	for i = 1,amount do

		local angle = math.rad(math.random(0,360))
		local x = originPoint.X + math.random(1,radius) * math.cos(angle)
		local z = originPoint.Z + math.random(1,radius) * math.sin(angle)
		local y = originPoint.Y + math.random(-5,5) + cloudSizeMultiplier*30-20
		
		local distanceToOrigin = (Vector3.new(x,y,z) - originPoint).Magnitude
		local color = math.clamp(distanceToOrigin/3, 40, 100)

		local newPart: MeshPart = cloud:Clone()
		newPart.Size    = newPart.Size*cloudSizeMultiplier
		newPart.Color   = Color3.fromRGB(color, color, color)
		newPart.CFrame  = CFrame.lookAt(Vector3.new(x,y,z), Vector3.new(originPoint.X, y, originPoint.Z))
		newPart.CFrame *= CFrame.fromEulerAnglesXYZ(0,math.rad(90),0)
		newPart.Parent  = model

	end

	model:ScaleTo(0.01)
	model.Parent = folder
	
	tween:Play()
	tween2:Play()
	
	task.spawn(function()
		
		repeat
			task.wait()
			model:ScaleTo(scale.Value)
			model:PivotTo(model:GetPivot() * CFrame.fromEulerAnglesXYZ(0,math.rad(rotation.Value),0))
		until tween.PlaybackState == Enum.PlaybackState.Completed
		
		task.wait(0.1)
		
		scale:Destroy()
		rotation:Destroy()
		
	end)

	return model

end

local function setFire(part: Part, windspeeds: number)

	local fire = Instance.new("Fire")
	fire.Size = part.Size.X*3
	fire.Parent = part

	task.spawn(function()

		local cFrame, size, color = part.CFrame, part.Size, part.Color
		local destructionChance   = math.random(1,10)/10
		local spreadChance        = math.random(1,4)
		local amountOfParts       = math.random(1,2)

		task.wait(math.random(5,20)/10)
		for i = 1,math.random(4,10) do
			task.wait(0.1)
			part.Color = part.Color:Lerp(color, i/10)
		end
		part.Color = Color3.fromRGB(0,0,0)
		task.wait(math.random(5,20)/10)

		part:Destroy()

		if spreadChance ~= 1 then return nil end

		local nearParts = workspace:GetPartBoundsInBox(cFrame, size + Vector3.new(4,4,4), absorptionParams)
		for i = 1,math.clamp(#nearParts, 0, amountOfParts) do setFire(nearParts[i]) end

	end)

end

local function destroyPart(part: Part, frames: number)

	part.Anchored   = true
	part.CastShadow = false
	part.CanCollide = false
	part.CanQuery   = false
	part.CanTouch   = false

	task.spawn(function()
		for i = 1,frames do part.Transparency = i/frames task.wait() end
		part:Destroy()
	end)

end

local function fireballSkill(amount: number, power: number, tornado: MeshPart)
	
	-- To be added! No need to analyze this part!
	
end



--// MAIN FUNCTIONS

-- On va potentiellement mettre cette fonction sur le client, pour uniquement absorber si la tornade
-- est assez proche, et que les options graphiques sont activées
local function absorbPart(part: BasePart, tornado: MeshPart, tornadoType: string)

	for _,joint in part:GetJoints() do joint:Destroy() end
	part.CollisionGroup = "flying"

	local beginningAngle    = math.random(0,360)
	local angleAdder        = math.random(-10,10)/250
	local beginningDistance = math.random(tornado.Size.X/10, tornado.Size.X/3)
	local distanceAdder     = math.random(tornado.Size.X/6, tornado.Size.X)/1000

	local tornadoAttachment    = Instance.new("Attachment")
	tornadoAttachment.Position = Vector3.new(math.cos(beginningAngle)*beginningDistance, part.Position.Y-tornado.Size.Y/2, math.sin(beginningAngle)*beginningDistance)
	tornadoAttachment.Parent   = tornado

	local originalPos = part.Position
	local xSide = math.random(0,1) == 0 and -1 or 1
	local ySide = math.random(0,1) == 0 and -1 or 1
	local zSide = math.random(0,1) == 0 and -1 or 1

	local beginningPartRotation = math.random(2,8)/10
	local partRotationDivisor   = math.random(50,150)
	local absorptionPowerCurve  = 2

	local firstLerpRepeats   = (part.Position-tornado.Position).Magnitude/2 + 50
	local partPositionOffset = Vector3.new(math.random(-10,10), math.random(-5,5), math.random(-10,10))

	local maxAngleChange    = beginningPartRotation+firstLerpRepeats/partRotationDivisor
	local secondLerpRepeats = math.random(firstLerpRepeats/4,firstLerpRepeats/2)
	local adderY            = math.random(tornado.Size.Y/2-originalPos.Y/2,tornado.Size.Y-originalPos.Y/2)/secondLerpRepeats

	for _,child in toCopy:GetChildren() do
		local newChild = child:Clone()
		newChild.Parent = part
	end

	part.Trail.Attachment0 = part.Attachment0
	part.Trail.Attachment1 = part.Attachment1
	
	if tornadoType == "fire" then
		part.Color = Color3.fromRGB(0,0,0)
		part.Material = Enum.Material.CrackedLava
	end

	task.spawn(function()

		for i = 1,firstLerpRepeats do
			local angleChange = beginningPartRotation+i/partRotationDivisor
			part.Position  = originalPos:Lerp(tornadoAttachment.WorldCFrame.Position+partPositionOffset, math.pow(i/firstLerpRepeats, absorptionPowerCurve))
			part.CFrame   *= CFrame.fromEulerAnglesXYZ(math.rad(angleChange)*xSide, math.rad(angleChange)*ySide, math.rad(angleChange)*zSide)
			task.wait()
		end

		if not part:FindFirstChild("Trail") then
			return
		end
		part.Trail:Destroy()

		for i = 1,secondLerpRepeats do
			beginningAngle += angleAdder
			beginningDistance    += distanceAdder

			tornadoAttachment.Position = Vector3.new(math.cos(beginningAngle),0,math.sin(beginningAngle))*beginningDistance*(0.5+(i/(secondLerpRepeats+20))) + Vector3.new(0,tornadoAttachment.Position.Y+adderY,0)
			part.Position        = tornadoAttachment.WorldCFrame.Position+partPositionOffset
			part.CFrame         *= CFrame.fromEulerAnglesXYZ(math.rad(maxAngleChange)*xSide, math.rad(maxAngleChange)*ySide, math.rad(maxAngleChange)*zSide)
			task.wait(0.05)
		end

		part:Destroy()
		tornadoAttachment:Destroy()

	end)

end

local function absorbAttempt(tornado: MeshPart, hitboxSize: Vector3, hitboxPosition: CFrame, windspeeds: number, tornadoType)

	local parts = workspace:GetPartBoundsInBox(hitboxPosition, hitboxSize, absorptionParams)
	local totalAbsorbedParts = 0
	print(#parts)

	for i,part: Part in parts do
		
		if i % 100 == 0 then task.wait() end
		part.CollisionGroup = "Default"
		
		local absorptionChance = math.random(1,20)/20
		if calculateAbsorptionChance(part, tornado, windspeeds) > absorptionChance then
			
			local deletionChance = math.random(1,5)
			if deletionChance ~= 5 or totalAbsorbedParts >= 50 then destroyPart(part, 10) continue end
			absorbPart(part, tornado, tornadoType)
			totalAbsorbedParts += 1
			continue
			
		end
		
		-- A MODIFIER
		local firespread = 50
		local fireChance = math.random(1,1000)/1000
		if tornadoType == "fire" and calculateFireChance(part, tornado, firespread) > fireChance then setFire(part, windspeeds) end
		
		task.delay(math.random(20,30)/10, function() part.CollisionGroup = "destructible" end)

	end
end

local function spawnTornado(playerSpawning: Player, windspeeds, width, movementSpeed, tornadoType: "normal" | "fire")
	
	local folder = Instance.new("Folder")
	folder.Name  = playerSpawning and playerSpawning.Name or "test" -- a completer avec le nb de la catastrophe en question
	folder.Parent = disastersFolder
	math.randomseed(os.time())

	local lastAbsorb = os.clock()
	local realSize   = width*4
	local hitboxSize = Vector3.new(realSize+50, tornadoHeight, realSize+50)

	local newTornado: MeshPart
	local spinSpeed  = math.clamp(5 - math.log(realSize, 4), 0.5, 5)

	if tornadoType == "normal" then
		newTornado = tornadoFolder.tornadoNormal:Clone()
	end
	if tornadoType == "fire" then
		newTornado = tornadoFolder.tornadoFire:Clone()
	end

	newTornado.Position = Vector3.new(80,400,-400) -- To replace with the actual coordinates
	newTornado.Size     = Vector3.new(10, tornadoHeight, 10)

	-- Detect the zone the tornado spawns in
	local zone = workspace.zone -- replace

	-- Fire a remote "tornadoSpawn" with the spawning position, data, and movementlist
	-- to add

	-- Animate the clouds + tornado coming down
	local cloudModel = generateCloudCircle(Vector3.new(newTornado.Position.X, tornadoHeight-40, newTornado.Position.Z), width*2+30, width, folder)
	local tween = ts:Create(newTornado, TweenInfo.new(2, Enum.EasingStyle.Linear), {Position = Vector3.new(newTornado.Position.X, tornadoHeight/2 - 5, newTornado.Position.Z)})
	local fakeHitbox = Vector3.new(0,tornadoHeight,0)
	local originalY = newTornado.Position.Y

	task.wait(1)
	newTornado.Parent = folder
	tween:Play()

	repeat
		task.wait()
		newTornado.CFrame *= CFrame.fromEulerAnglesXYZ(0, math.rad(spinSpeed), 0)
	until tween.PlaybackState == Enum.PlaybackState.Completed

	local tween2 = ts:Create(newTornado, TweenInfo.new(2, Enum.EasingStyle.Linear), {Size = Vector3.new(realSize, tornadoHeight, realSize)})
	tween2:Play()

	-- Reduce the strain on the first spatial query by splitting it
	repeat

		task.wait()

		local ratio = newTornado.Size.X/realSize
		newTornado.CFrame *= CFrame.fromEulerAnglesXYZ(0, math.rad(spinSpeed), 0)
		cloudModel:PivotTo(cloudModel:GetPivot() * CFrame.fromEulerAnglesXYZ(0,math.rad(ratio*0.25),0))

		if os.clock()-lastAbsorb > 0.2 then
			fakeHitbox = Vector3.new((realSize+50)*ratio, tornadoHeight, (realSize+50)*ratio)
			absorbAttempt(newTornado, fakeHitbox, CFrame.new(newTornado.Position.X, tornadoHeight/2 - 5, newTornado.Position.Z), windspeeds, tornadoType)
			lastAbsorb = os.clock()
		end

	until tween2.PlaybackState == Enum.PlaybackState.Completed

	newTornado.Size = Vector3.new(realSize, tornadoHeight, realSize) 

	-- Rotation, movement and absorption
	local spawnTime = os.clock()
	local lifeTime  = math.random(10,16)

	while true do

		local randomX = math.random(zone.Position.X-zone.Size.X/2, zone.Position.X+zone.Size.X/2)
		local randomZ = math.random(zone.Position.Z-zone.Size.Z/2, zone.Position.Z+zone.Size.Z/2)

		local newPosition  = Vector3.new(randomX, newTornado.Position.Y, randomZ)
		local movementTime = (newTornado.Position-newPosition).Magnitude/movementSpeed

		local tween = ts:Create(newTornado, TweenInfo.new(movementTime, Enum.EasingStyle.Linear), {Position = newPosition})
		tween:Play()

		repeat

			task.wait()
			newTornado.CFrame *= CFrame.fromEulerAnglesXYZ(0, math.rad(spinSpeed), 0)
			cloudModel:PivotTo(CFrame.new(newTornado.Position.X, tornadoHeight-40, newTornado.Position.Z) * cloudModel:GetPivot().Rotation * CFrame.fromEulerAnglesXYZ(0,math.rad(0.25),0))

			if os.clock()-lastAbsorb > 0.2 then
				absorbAttempt(newTornado, hitboxSize, newTornado.CFrame, windspeeds, tornadoType)
				lastAbsorb = os.clock()
			end

			if os.clock()-spawnTime >= lifeTime then break end

		until tween.PlaybackState == Enum.PlaybackState.Completed

		if os.clock()-spawnTime < lifeTime then
			continue
		end
		
		local tween1 = ts:Create(newTornado, TweenInfo.new(1, Enum.EasingStyle.Linear), {Size = Vector3.new(0.1, tornadoHeight, 0.1)})
		tween1:Play()

		local scale    = Instance.new("NumberValue")
		local rotation = Instance.new("NumberPose")
		local tween2  = ts:Create(scale, TweenInfo.new(2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Value = 0.001})
		local tween3 = ts:Create(rotation, TweenInfo.new(2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Value = 10})

		scale.Value    = 1
		rotation.Value = 1

		tween2:Play()
		tween3:Play()

		task.spawn(function()

			repeat
				task.wait()
				cloudModel:ScaleTo(scale.Value)
				cloudModel:PivotTo(CFrame.new(newTornado.Position.X, tornadoHeight-40, newTornado.Position.Z) * cloudModel:GetPivot().Rotation * CFrame.fromEulerAnglesXYZ(0,math.rad(1),0))
			until tween2.PlaybackState == Enum.PlaybackState.Completed

			task.wait(0.1)

			scale:Destroy()
			rotation:Destroy()

		end)

		tween1.Completed:Wait()
		newTornado:Destroy()
		tween2.Completed:Wait()

		local flyingParts = workspace:GetPartBoundsInBox(newTornado.CFrame, hitboxSize*2, flyingParams)
		folder:Destroy()
		for _,part: Part in flyingParts do destroyPart(part, 10) end
		break


	end
	
end

--// TEST
game.ReplicatedStorage.Event.Event:Connect(function(wind, size, speed, tornado)
	spawnTornado(nil, wind, size, speed, tornado)
end)