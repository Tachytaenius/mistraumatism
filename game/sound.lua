local game = {}

function game:loadSounds()
	local soundSources = {}
	local function loadSound(name)
		soundSources[name] = love.audio.newSource("sounds/" .. name .. ".wav", "static")
	end

	loadSound("playerDeath")

	self.soundSources = soundSources
end

function game:playSound(name)
	self.soundSources[name]:play()
end

function game:stopMusic()
	if self.music then
		self.music:stop()
	end
	self.music = nil
	self.musicName = nil
	self.musicFadeoutEnd = nil
	self.musicFadeoutTimer = nil
end

function game:setMusic(name, forceFadeoutEnd)
	if name == self.musicName then
		return
	end

	if self.musicFadeoutTimer and not forceFadeoutEnd then
		self.musicAfterFadeout = name
		return
	else
		self:stopMusic()
	end

	self.music = love.audio.newSource("music/" .. name .. ".wav", "stream")
	self.musicName = name
	self.music:setLooping(true)
	self.music:play()
end

function game:fadeMusicOut(time)
	assert(self.music, "Can't fade out music without any playing")
	self.musicFadeoutEnd = time
	self.musicFadeoutTimer = 0
end

function game:handleMusicFadeout(dt)
	if not (self.music and self.musicFadeoutTimer) then
		return
	end
	self.musicFadeoutTimer = self.musicFadeoutTimer + dt
	if self.musicFadeoutTimer >= self.musicFadeoutEnd then
		self:stopMusic()
		if self.musicAfterFadeout then
			self:setMusic(self.musicAfterFadeout)
			self.musicAfterFadeout = nil
		end
		return
	end
	self.music:setVolume(1 - self.musicFadeoutTimer / self.musicFadeoutEnd)
end

return game
