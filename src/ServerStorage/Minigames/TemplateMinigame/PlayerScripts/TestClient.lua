local testClient = {}

function testClient.OnMinigameLoaded(minigameAPI, players)
	warn("Client minigame started")
end

function testClient.OnMinigameEnded(minigameEndType)
	warn("Client minigame ended", minigameEndType)
end

function testClient.OnPlayerJoinedMinigame(player)
	warn("Client new player joined the fun", player)
end

function testClient.OnPlayerLeavingMinigame(player)
	warn("Client player left the fun", player)
end

return testClient
