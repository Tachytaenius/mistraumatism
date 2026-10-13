local mathsies = require("lib.mathsies")
local vec3 = mathsies.vec3
local quat = mathsies.quat
local mat4 = mathsies.mat4

local consts = require("consts")

-- Mathsies does not have mat3 support
local function multiplyMat3WithVec3(mat3, v)
	return vec3(
		vec3.dot(v, vec3(mat3[1], mat3[2], mat3[3])),
		vec3.dot(v, vec3(mat3[4], mat3[5], mat3[6])),
		vec3.dot(v, vec3(mat3[8], mat3[7], mat3[9]))
	)
end

-- Used to transform normals
local function normalMatrix(modelToWorld)
	local m = mat4.transpose(mat4.inverse(modelToWorld))
	return
		m._00, m._01, m._02,
		m._10, m._11, m._12,
		m._20, m._21, m._22
end

local function cylinder(params)
	local joins = {}
	local vertices = {}
	for stepI, step in ipairs(params.steps) do
		local join = {}
		joins[stepI] = join
		for angleI = 0, params.angleSteps do
			local progress = angleI / params.angleSteps
			local angle = math.pi * 2 * progress
			local u = angleI / params.angleSteps * params.uWrapTimes
			local posJoinSpace = vec3(
				math.cos(angle) * params.xRadius,
				math.sin(angle) * params.yRadius,
				0
			)
			local posWorldSpace = step.position + vec3.rotate(posJoinSpace, step.orientation)
			local v = stepI / #params.steps * params.finalV
			local normalSliceSpace = -vec3.normalise(posJoinSpace)
			local sliceToWorld = mat4.transform(step.position, step.orientation)
			local normalWorldSpace = multiplyMat3WithVec3({normalMatrix(sliceToWorld)}, normalSliceSpace)
			join[angleI] = {
				posWorldSpace.x, posWorldSpace.y, posWorldSpace.z,
				u, v,
				normalWorldSpace.x, normalWorldSpace.y, normalWorldSpace.z
			}
		end
		if stepI > 1 then
			local prevJoin = joins[stepI - 1]
			for angleI = 0, params.angleSteps - 1 do
				-- Form quads bridging slices with matching vertices
				-- Triangle 1
				vertices[#vertices + 1] = prevJoin[angleI]
				vertices[#vertices + 1] = join[angleI]
				vertices[#vertices + 1] = prevJoin[angleI + 1]
				-- Triangle 2
				vertices[#vertices + 1] = join[angleI]
				vertices[#vertices + 1] = join[angleI + 1]
				vertices[#vertices + 1] = prevJoin[angleI + 1]
			end
		end
	end
	return love.graphics.newMesh(consts.vertexFormat, vertices, "triangles", "static")
end

return cylinder
