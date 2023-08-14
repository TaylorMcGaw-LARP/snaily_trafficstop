--[[
    Sonoran Plugins

    Plugin Configuration

    Put all needed configuration in this file.
]]
config = {
    enabled = true,
    pluginName = "trafficstop", -- name your plugin here
    pluginAuthor = "SonoranCAD", -- author
    configVersion = "1.0",

    -- put your configuration options below
    situationcodeid = '5cefb926-4948-4b42-ae0b-4171a7e8d28d',
}

if config.enabled then
    Config.RegisterPluginConfig(config.pluginName, config)
end