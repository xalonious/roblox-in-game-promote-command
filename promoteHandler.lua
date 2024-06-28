-- Dependencies
local messagemodule = require(game:GetService("ReplicatedStorage").MessageModule) -- The message module holds the SendMessage function, which is used to show notifications to the player, this takes in 3 arguments, the player, the message, and the type of message. you can replace this with your own or don't use it at all
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- Constants
local GroupId = 123456 -- Replace this with your group id
local CommandPrefix = "!promote" -- You can change this if you want
local ServerURL = "https://example.com/promote" -- Replace this with your server URL
local AuthorizationKey = script:GetAttribute("key") -- Make sure you have a key attribute in the script set to the api key

-- Utility Functions
local function canPromote(player)
    return player:GetRankInGroup(GroupId) >= 160 -- Change this to the minimum rank required to promote
end

local function sendMessage(player, message, messageType)
    messagemodule.SendMessage(player, message, messageType)
end

local function findTargetPlayer(name)
    return Players:FindFirstChild(name)
end

local function sendPromotionRequest(requestData)
    local success, response = pcall(function()
        return HttpService:RequestAsync({
            Url = ServerURL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Authorization"] = AuthorizationKey
            },
            Body = HttpService:JSONEncode(requestData)
        })
    end)
    return success, response
end

local function handlePromotionResponse(player, response)
    if response.Success then
        local successDecode, responseTable = pcall(function()
            return HttpService:JSONDecode(response.Body)
        end)

        if successDecode then
            sendMessage(player, responseTable.message, responseTable.success and "success" or "error")
        else
            sendMessage(player, "Failed to parse server response", "error")
            print("Failed to parse server response:", response.Body)
        end
    else
        local responseTable = HttpService:JSONDecode(response.Body)
        sendMessage(player, responseTable.message, "error")
        print("Request failed:", response.StatusCode, response.StatusMessage)
    end
end

local function handleCommand(player, args)
    if #args < 2 then
        return sendMessage(player, "Specify the person to promote", "error")
    end

    if not canPromote(player) then
        return sendMessage(player, "Only high ranks can use this", "error")
    end

    local targetPlayer = findTargetPlayer(args[2])
    if not targetPlayer then
        return sendMessage(player, "That person is not in the game", "error")
    end

    local targetRank = targetPlayer:GetRankInGroup(GroupId)
    local runnerRank = player:GetRankInGroup(GroupId)

    if targetRank == 0 then
        return sendMessage(player, "User is not in the group", "error")
    end

    if targetRank >= runnerRank then
        return sendMessage(player, "You cannot promote someone with an equal or higher rank than you", "error")
    end

    if targetRank >= 254 then -- Change this to the maximum rank that can be promoted (your bot accounts rank -1) 
        return sendMessage(player, "User's rank is too high", "error")
    end

    local requestData = {
        username = args[2],
        runner = player.Name,
    }

    local success, response = sendPromotionRequest(requestData)
    if success then
        handlePromotionResponse(player, response)
    else
        sendMessage(player, "Failed to send request, try again later", "error")
        print("Failed to send request:", response)
    end
end

-- Event Listeners
Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(message)
        if string.sub(string.lower(message), 1, #CommandPrefix) == CommandPrefix then
            handleCommand(player, string.split(string.sub(message, #CommandPrefix + 1), " "))
        end
    end)
end)