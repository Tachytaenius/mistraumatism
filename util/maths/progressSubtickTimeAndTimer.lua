return function(curTime, timer, age, subticks)
	local usableTime = subticks - curTime
	local timer2 = math.max(timer - usableTime, 0) -- use usableTime to progress/increase timer, stopping at 0
	local usableTime2 = usableTime - (timer - timer2) -- get new used usable time using change in timer
	local timeUsed = usableTime - usableTime2
	local curTime2 = curTime + timeUsed
	local age2 = age + timeUsed
	return curTime2, timer2, age2
end
