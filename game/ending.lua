local mathsies = require("lib.mathsies")
local vec3 = mathsies.vec3
local quat = mathsies.quat
local mat4 = mathsies.mat4

local consts = require("consts")
local commands = require("commands")
local settings = require("settings")
local util = require("util")

local game = {}

function game:setReachedSafety()
	self:setIcon("icons/safe.png")
	self.state.reachedSafety = true
	local player = self.state.player
	if player then
		player.roseRage = false
	end
end

function game:doesPlayerHaveSecretLevelKey()
	local player = self.state.player
	if not player then
		return
	end
	local has = false
	self:tickItems(function(item, x, y, locationType, locationEntity)
		if
			locationEntity == player and
			(locationType == "worn" or locationType == "inventory")
		then
			-- This is an item on the player
			if item.isSecretLevelKey then
				has = true
			end
		end
	end)
	return has
end

function game:toCredits()
	self:setMusic("the-long-view", true)
	self.mode = "text"
	self.textInfo = {
		path = "text/credits-shown.txt",
		timer = 0,
		releaseTime = 5,
		getColour = function(x, y)
			return "white", "black"
		end,
		updateFunction = function(self, dt)
			if commands.checkCommand("confirm") and self.textInfo.timer >= self.textInfo.releaseTime then
				love.event.quit()
				-- TODO: Quick fadeout (visually and audially)
				self.quitting = true
				return true -- As in game/init.lua
			end
			self.textInfo.timer = self.textInfo.timer + dt
		end
	}
end

function game:checkForGameFinished()
	local player = self.state.player
	if not player or player.dead then
		return
	end
	local tile = self:getTile(player.x, player.y)
	if not tile then
		return
	end
	if tile.isGameFinishTrigger then
		self:finishGame()
	end
end

function game:finishGame()
	if self.state.gameFinishTriggerTripped then
		return
	end
	self.state.gameFinishTriggerTripped = true
	self:setCursor()
	if self:doesPlayerHaveSecretLevelKey() then
		self:allowLevelAccess(consts.secretLevelName)
		self:announce("It feels like you can now know that you're loved.\nYou have done well ♥", "green")
		self.afterEndingSequence = "secret" -- In this case you view credits when going back to bed in the secret sanctuary
	else
		self.afterEndingSequence = "credits"
	end
	-- In either case, quit game when credits are done.

	self:setReachedSafety()

	self.state.playerEscaping = true
	self.state.playerEscapingCallbacks = {}
	self.state.playerEscapingCallbacks[53] = function()
		-- Set music has been moved to ending sequence graphics stage 2
	end
	self.state.playerEscapingCallbacks[60] = function()
		self:setUpEndingSequenceGraphics()
	end
end

function game:setUpEndingSequenceGraphics()
	self.endingSequenceGraphics = {
		startY = self.state.player and self.state.player.y or self.state.lastPlayerY,
		endY = 30,
		stage = 1,
		show = function()
			return not self.menuInfo
		end,
		fade = 0,
		realtimeUpdate = function(dt)
			if self.endingSequenceGraphics.stage == 2 then
				self:updateEndScene(dt)
			end
		end,
		update = function()
			if self.endingSequenceGraphics.stage == 1 then
				local y = self.state.player and self.state.player.y or self.state.lastPlayerY
				self.endingSequenceGraphics.fade = math.max(0, math.min(1, 1 - (y - self.endingSequenceGraphics.endY) / (self.endingSequenceGraphics.startY - self.endingSequenceGraphics.endY)))
				if self.endingSequenceGraphics.fade >= 1 then
					self.endingSequenceGraphics.stage = 2
					self.state.playerEscapeSteps = nil

					self:endStage2()
				end
			elseif self.endingSequenceGraphics.stage == 2 then

			end
		end,
		draw = function()
			local g = self.endingSequenceGraphics
			if g.stage == 2 then
				self:drawEndScene()
				return
			end
			love.graphics.setCanvas(g.canvas)
			love.graphics.clear(1, 1, 1, 1) -- Because this canvas would be remade if font was changed during gameplay, don't rely on this not being cleared if this line isn't here
			love.graphics.setCanvas()
		end
	}
	self:refreshEndGraphicsCanvasses()
end

function game:endStage2()
	self.state.playerEscaping = nil
	self.state.playerEscapingCallbacks = nil
	self.mode = "ending"
	self:setMusic("mercious", true, true)
	self.endingSequenceGraphics.fade = 1
	self:initEndScene()
end

function game:jumpToEndingScene()
	self.endingSequenceGraphics.stage = 2
end

function game:finishEnding()
	self.endingSequenceGraphics = nil
	if self.state.player and self.state.player.bleedingAmount then
		self.state.player.bleedingAmount = 0
	end
	self:fadeMusicOut(3)
	if self.afterEndingSequence == "secret" then
		self.mode = "gameplay"
		self:changeLevel(consts.secretLevelName)
	elseif self.afterEndingSequence == "credits" then
		self:toCredits()
	else
		error("afterEndingSequence isn't set to a correct value: \"" .. tostring(self.afterEndingSequence) .. "\"")
	end
	self.forceRepeatUpdate = true
end

function game:advanceEscape()
	local state = self.state
	local player = state.player
	if not player or player.dead then
		return
	end

	if #player.actions > 0 then
		return
	end

	self.state.playerEscapeSteps = self.state.playerEscapeSteps or 0

	local dir = "up"
	local offsetX, offsetY = self:getDirectionOffset(dir)

	if not self:getWalkable(player.x + offsetX, player.y + offsetY, false, false) then
		if self.state.playerEscapingCallbacks.finished then
			self.state.playerEscapingCallbacks.finished()
		end
		return
	end

	local newAction = self.state.actionTypes.move.construct(self, player, dir)
	if newAction then
		self.state.playerEscapeSteps = self.state.playerEscapeSteps + 1
		if self.state.playerEscapingCallbacks[self.state.playerEscapeSteps] then
			self.state.playerEscapingCallbacks[self.state.playerEscapeSteps]()
		end
		player.actions[#player.actions+1] = newAction
		return -- No further actions
	end
end

function game:initEndScene()
	local g = self.endingSequenceGraphics
	g.fadeTimer2 = 0
	g.time = 0

	g.models = {}
	local function model(name)
		local new = {}
		local dir = "scene/models/" .. name .. "/"
		new.mesh = util.loadObj(dir .. "mesh.obj")
		new.baseColourTex = love.graphics.newImage(dir .. "baseColour.png", {
			mipmaps = "auto"
		})
		g.models[name] = new
	end

	local groundHeight, trunkRadius = 0.2, 0.5
	g.models.treeb = require("scene.tree").new({seed = 0, trunkRadius = trunkRadius})
	local generator = love.math.newRandomGenerator(0)
	local groundVerts = {}
	local ratio = 10
	local resX = 24
	local resY = resX * ratio
	local sizeX = 60
	local sizeY = sizeX * ratio
	for x = 0, resX - 1 do
		groundVerts[x] = {}
		for y = 0, resY - 1 do
			groundVerts[x][y] = {
				x / resX * sizeX,
				generator:random() * groundHeight,
				y / resY * sizeY
			}
		end
	end
	local verts = {}
	local function v(x, y, u, v, nx, ny, nz)
		local vert = groundVerts[x][y]
		return {
			vert[1], vert[2], vert[3],
			u, v,
			nx, ny, nz
		}
	end
	for x = 0, resX - 2 do
		for y = 0, resY - 2 do
			local a = groundVerts[x][y]
			local b = groundVerts[x + 1][y]
			local c = groundVerts[x][y + 1]
			local d = groundVerts[x + 1][y + 1]
			local nx, ny, nz = vec3.components(vec3.normalise(
				(
					vec3.normalise(vec3.cross(
						vec3(unpack(b)) - vec3(unpack(a)),
						vec3(unpack(c)) - vec3(unpack(a))
					)) --+
					-- vec3.normalise(vec3.cross(
					-- 	vec3(unpack(b)) - vec3(unpack(d)),
					-- 	vec3(unpack(c)) - vec3(unpack(d))
					-- ))
				) --/ 2
			))
			local nx1, ny1, nz1 = vec3.components(vec3.normalise(-vec3.cross(
				vec3(unpack(b)) - vec3(unpack(a)),
				vec3(unpack(c)) - vec3(unpack(a))
			)))
			local nx2, ny2, nz2 = vec3.components(vec3.normalise(-vec3.cross(
				vec3(unpack(d)) - vec3(unpack(c)),
				vec3(unpack(d)) - vec3(unpack(a))
			)))
			table.insert(verts, v(x, y, 0, 0, nx1, ny1, nz1))
			table.insert(verts, v(x + 1, y, 1, 0, nx1, ny1, nz1))
			table.insert(verts, v(x, y + 1, 0, 1, nx1, ny1, nz1))
			table.insert(verts, v(x + 1, y, 1, 0, nx2, ny2, nz2))
			table.insert(verts, v(x + 1, y + 1, 1, 1, nx2, ny2, nz2))
			table.insert(verts, v(x, y + 1, 0, 1, nx2, ny2, nz2))
		end
	end
	g.models.ground = {
		mesh = love.graphics.newMesh(consts.vertexFormat, require("util.graphics.setTangentsAndBitangents")(verts), "triangles"),
		baseColourTex = love.graphics.newImage("scene/models/ground/baseColour.png", {
			mipmaps = "auto"
		})
	}

	g.objects = {}
	table.insert(g.objects, {
		model = g.models.ground,
		position = vec3(-sizeX / 2, 1, 0),
		orientation = quat()
	})
	for _=1, 500 do
		local x = (love.math.random() - 0.5) * sizeX
		local z = (love.math.random() - 0.5) * sizeY
		table.insert(g.objects, {
			model = g.models.treeb,
			position = vec3(x, -(groundHeight + trunkRadius), z),
			-- position = vec3(),
			orientation = quat()
		})
	end

	g.camera = {
		position = vec3(0.4, 1.6, 0),
		-- position = vec3(1.4, 0, 3),
		-- orientation = quat.fromAxisAngle(vec3(0, -math.pi / 2, 0)),
		orientation = quat(),
		verticalFOV = math.rad(80)
	}

	g.shaders = {}
	g.shaders.object = love.graphics.newShader("shaders/object.glsl")

	g.skyColour = {0.8, 0.84, 1}

	local normImgData = love.image.newImageData(1, 1)
	normImgData:setPixel(0, 0, 0.5, 0.5, 1, 1)

	g.sunlightDir = vec3.normalise(vec3(1, 2, 3))
end

function game:updateEndScene(dt)
	local g = self.endingSequenceGraphics
	g.fadeTimer2 = math.min(1, g.fadeTimer2 + dt * 0.25)

	g.camera.position.z = g.time * 0.2

	-- g.camera.position.y = g.camera.position.y + dt * 0.2

	-- g.sunlightDir = vec3.rotate(g.sunlightDir, quat.fromAxisAngle(vec3(0, 0, 0.1 * dt)))

	-- for _, object in ipairs(g.objects) do
	-- 	object.orientation = quat.normalise(object.orientation * quat.fromAxisAngle(vec3(0, 0.5, 0) * dt))
	-- end

	g.time = g.time + dt
end

function game:drawEndScene()
	local g = self.endingSequenceGraphics
	love.graphics.setCanvas(g.canvas)
	love.graphics.setCanvas({g.canvas, depthstencil = g.depthBuffer})
	love.graphics.clear(g.skyColour, false, true)

	love.graphics.setFrontFaceWinding("cw")
	love.graphics.setMeshCullMode("back")
	love.graphics.setDepthMode("lequal", true)

	local near, far = 0.01, 1000
	local cameraToClip = mat4.perspectiveLeftHanded(g.canvas:getWidth() / g.canvas:getHeight(), g.camera.verticalFOV, far, near)
	local worldToCamera = mat4.camera(g.camera.position, g.camera.orientation)
	local worldToClip = cameraToClip * worldToCamera

	local objectShader = g.shaders.object
	love.graphics.setShader(objectShader)
	objectShader:send("cameraPos", {vec3.components(g.camera.position)})
	objectShader:send("sunlight", {3, 3, 3})
	objectShader:send("sunlightDir", {vec3.components(g.sunlightDir)})
	-- objectShader:send("lightPos", {vec3.components(g.camera.position + vec3(math.cos(g.time), 0 or math.sin(g.time), 0))})
	objectShader:sendColor("skyColour", g.skyColour)
	for _, object in ipairs(g.objects) do
		local modelToWorld = mat4.transform(object.position, object.orientation)
		local modelToClip = worldToClip * modelToWorld
		objectShader:send("modelToWorld", {mat4.components(modelToWorld)})
		objectShader:send("modelToClip", {mat4.components(modelToClip)})
		objectShader:send("baseColourTex", object.model.baseColourTex)
		love.graphics.draw(object.model.mesh)
	end
	love.graphics.setShader()

	love.graphics.setDepthMode("always", false)

	love.graphics.setColor(1, 1, 1, 1 - g.fadeTimer2)
	love.graphics.rectangle("fill", 0, 0, g.canvas:getDimensions())
	love.graphics.setColor(1, 1, 1)

	love.graphics.setCanvas()
end

function game:refreshEndGraphicsCanvasses()
	local g = self.endingSequenceGraphics
	local w, h = self:getCanvasSize()
	w = w * settings.graphics.canvasScale
	h = h * settings.graphics.canvasScale
	g.canvas = love.graphics.newCanvas(w, h)
	g.depthBuffer = love.graphics.newCanvas(w, h, {format = "depth32f", readable = true})
end

return game
