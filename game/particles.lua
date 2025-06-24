local game = {}

function game:newParticle(params, additionalParams)
	local newParticle = {}
	for k, v in pairs(params) do
		newParticle[k] = v
	end
	for k, v in pairs(additionalParams) do
		newParticle[k] = v
	end
	newParticle.timeExisted = 0
	self:initProjectileTrajectory(newParticle, newParticle.startX, newParticle.startY, newParticle.targetX, newParticle.targetY)
	self.state.particles[#self.state.particles+1] = newParticle
end

function game:tickParticles()
	local state = self.state
	local particlesToRemove = {}
	local fakeParticlesToRemove = {} -- Unused table to avoid removing particles that hit walls
	for _, particle in ipairs(state.particles) do
		particle.timeExisted = particle.timeExisted + 1
		if particle.timeExisted >= particle.lifetime then
			particlesToRemove[particle] = true
		else
			self:moveObjectAsProjectile(particle, nil, nil, fakeParticlesToRemove)
		end
	end
	local i = 1
	while i <= #state.particles do
		local particle = state.particles[i]
		if particlesToRemove[particle] then
			table.remove(state.particles, i)
		else
			i = i + 1
		end
	end
end

return game
