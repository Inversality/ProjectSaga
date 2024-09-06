local Matter = require(game.ReplicatedStorage.Packages.matter)
local Plasma = require(game.ReplicatedStorage.Packages.plasma)
local debugger = Matter.Debugger.new(Plasma) -- Pass Plasma into the debugger!

game.UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F4 then
        debugger:toggle()
    end
end)