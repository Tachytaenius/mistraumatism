local mathsies = require("lib.mathsies")
local vec3 = mathsies.vec3
local quat = mathsies.quat
local mat4 = mathsies.mat4

local cylinder = require("scene.cylinder")

local treeGenerator = {}

local forwardVector = vec3(0, 0, 1)

function treeGenerator.new(params)
	local rng = love.math.newRandomGenerator(params.seed)

	local pos = vec3()
	local orientation = quat.fromAxisAngle(vec3(-math.pi / 2, 0, 0))
	-- local orientation = quat()
	local step = 0.4
	local speed = 4
	local traversed = 0
	local angVel = vec3(0.1, 0.2, 0.3)
	local angVel = vec3()
	local steps = {}
	local vPerLen = 1.25
	for i = 1, 20 do
		orientation = quat.normalise(orientation * quat.fromAxisAngle(angVel * step))
		pos = pos + vec3.rotate(forwardVector, orientation) * step * speed
		traversed = traversed + step * speed
		table.insert(steps, {position = pos, orientation = orientation})
	end
	local tex = love.graphics.newImage("scene/treeBaseColour.png", {mipmaps = true})
	tex:setWrap("repeat", "repeat")
	return {
		baseColourTex = tex,
		mesh = cylinder({
			steps = steps,
			angleSteps = 16,
			xRadius = params.trunkRadius,
			yRadius = params.trunkRadius,
			finalV = traversed * vPerLen,
			uWrapTimes = 3
		})
	}
end

return treeGenerator
