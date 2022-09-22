local testServer = {}

function testServer.OnMinigameLoaded(minigameAPI, players)
	warn("Server minigame started")
	
	wait(3)
	
	for _, player in pairs(game.Players:GetChildren()) do
		minigameAPI.AwardPointsAndCoins(player, 23, 23)
	end
end

function testServer.OnMinigameEnded(minigameEndType)
	warn("Server minigame ended", minigameEndType)
end

function testServer.OnPlayerJoinedMinigame(player)
	warn("Server new player joined the fun", player)
end

function testServer.OnPlayerLeavingMinigame(player)
	warn("Server player left the fun", player)
end

return testServer
