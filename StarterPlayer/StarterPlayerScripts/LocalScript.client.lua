task.wait(2)

local windspeeds = 100

local toCopy = workspace.toCopy
local tornado = workspace.tornado
local hitbox = workspace.hitbox
local spinSpeed = math.clamp(5 - math.log(tornado.Size.X, 4), 0.5, 5)

local params = OverlapParams.new()
params.CollisionGroup = "destructible"
hitbox.Size = Vector3.new(150,tornado.Size.X/2, tornado.Size.X/2)

local ts = game:GetService("TweenService")

task.spawn(function()

	while true do

		local newPosition = Vector3.new(100, tornado.Position.Y, 400)
		local tween = ts:Create(tornado, TweenInfo.new((tornado.Position-newPosition).Magnitude/20), {Position = newPosition})
		tween:Play()

		repeat
			task.wait()
			tornado.CFrame *= CFrame.fromEulerAnglesXYZ(0, math.rad(spinSpeed), 0)
			hitbox.Position = Vector3.new(tornado.Position.X, 50, tornado.Position.Z)
		until false == true
	end

end)

local function absorbPart(part: BasePart)
	
	part.Anchored   = true
	part.CanCollide = false
	part.CanQuery   = false
	part.CanTouch   = false
	
	part.Parent = workspace.partsDestroyed

	for _,joint in part:GetJoints() do
		joint:Destroy()
	end

	local randomAngle = math.random(0,360)
	local adder       = math.random(-10,10)/250
	local distance    = math.random(tornado.Size.X/10, tornado.Size.X/3)
	local dAdder      = math.random(tornado.Size.X/6, tornado.Size.X*2/3)/1000

	local tornadoAttachment    = Instance.new("Attachment")
	tornadoAttachment.Position = Vector3.new(math.cos(randomAngle), (-tornado.Size.Y/2+math.random(0,10))/distance, math.sin(randomAngle))*distance
	tornadoAttachment.Parent   = tornado

	local originalPos = part.Position
	local xSide = math.random(0,1) == 0 and -1 or 1
	local ySide = math.random(0,1) == 0 and -1 or 1
	local zSide = math.random(0,1) == 0 and -1 or 1

	local mainAdder = math.random(2,8)/10
	local divisor   = math.random(50,150)
	local power     = 2

	local repeats        = (part.Position-tornado.Position).Magnitude/2 + math.random(50,150)
	local positionOffset = Vector3.new(math.random(-10,10), math.random(-5,20), math.random(-10,10))

	local endAngleChange   = repeats/divisor
	local amountOfRepeats  = math.random(repeats/4,repeats/2)
	local adderY           = math.random(tornado.Size.Y/5,tornado.Size.Y)/amountOfRepeats

	for _,child in toCopy:GetChildren() do
		local newChild = child:Clone()
		newChild.Parent = part
	end

	part.Trail.Attachment0 = part.Attachment0
	part.Trail.Attachment1 = part.Attachment1

	task.spawn(function()

		for i = 1,repeats do
			local endAngleChange = mainAdder+i/divisor
			part.Position  = originalPos:Lerp(tornadoAttachment.WorldCFrame.Position+positionOffset, math.pow(i/repeats, power))
			part.CFrame   *= CFrame.fromEulerAnglesXYZ(math.rad(endAngleChange)*xSide, math.rad(endAngleChange)*ySide, math.rad(endAngleChange)*zSide)
			task.wait()
		end

		part.Trail:Destroy()

		for i = 1,amountOfRepeats do
			randomAngle += adder
			distance    += dAdder

			tornadoAttachment.Position = Vector3.new(math.cos(randomAngle),0,math.sin(randomAngle))*distance*(0.5+(i/(amountOfRepeats+20))) + Vector3.new(0,tornadoAttachment.Position.Y+adderY,0)
			part.Position        = tornadoAttachment.WorldCFrame.Position+positionOffset
			part.CFrame         *= CFrame.fromEulerAnglesXYZ(math.rad(endAngleChange)*xSide, math.rad(endAngleChange)*ySide, math.rad(endAngleChange)*zSide)
			task.wait(0.05)
		end

		part:Destroy()
		tornadoAttachment:Destroy()

	end)

end

local function calculateAbsorptionChance(part: Part)
	
	local blockWeight    = part.Mass
	local windspeeds     = windspeeds
	local tornadoSize    = tornado.Size.X/4
	local distanceToWall = math.clamp((Vector3.new(part.Position.X, 0, part.Position.Z) - Vector3.new(tornado.Position.X, 0, tornado.Position.Z)).Magnitude - (tornadoSize+part.Size.X), 0, 250)
	
	local exponentDivider = (0.4*tornadoSize + 0.01*windspeeds + 10/(1+0.1*tornadoSize))
	local exponent        = -1 * math.pow(distanceToWall, 1.5) / exponentDivider
	local multiplier      = math.pow(windspeeds, 1+windspeeds/2000) / math.pow(blockWeight, 1+blockWeight/2000)
	local finalResult     = multiplier*math.exp(exponent) / 2
	
	return math.round(finalResult*1000)/1000
	
end

local function absorbAttempt()
	
	local parts = workspace:GetPartsInPart(hitbox, params)
	
	for i,part: Part in parts do
		
		if part.CollisionGroup ~= "destructible" then
			continue
		end
		
		local randomChance = math.random(1,20)/20
		local caca = calculateAbsorptionChance(part)
		
		if caca > randomChance then
			
			local deletionChance = math.random(1,5)
			if deletionChance ~= 5 then
				part:Destroy()
				continue
			end

			absorbPart(part)
			
		end
		
	end
end

while true do
	task.wait(0.2)
	absorbAttempt()
end