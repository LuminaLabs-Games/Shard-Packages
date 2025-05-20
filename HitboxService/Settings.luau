local Settings = {
    SHOW_DEBUG_RAY_LINES = true,
    SHOW_OUTPUT_MESSAGES = true,
    DEFAULT_COLLECTION_TAG_NAME = "_HitboxServiceManaged",
    DEFAULT_DEBUGGER_RAY_COLOUR = Color3.fromRGB(255, 0, 0),
    DEFAULT_DEBUGGER_RAY_WIDTH = 4,
    DEFAULT_DEBUGGER_RAY_NAME = "_HitboxServiceDebugLine",
    DEFAULT_FAR_AWAY_CFRAME = CFrame.new(0, math.huge, 0),
    MINIMUM_SECONDS_SCHEDULER = 1 / 60,
    DEFAULT_SIMULATION_TYPE = game:GetService("RunService").Heartbeat,
    DEFAULT_ATTACHMENT_INSTANCE = "HitPoint",
    DEFAULT_GROUP_NAME_INSTANCE = "Group",
    DEFAULT_DEBUGGER_RAY_DURATION = 0.25,
    DEFAULT_DEBUG_LOGGER_PREFIX = "[ Hitbox Service ]\n",
    DEFAULT_MISSING_ATTACHMENTS = "No attachments found in object: %s. Can be safely ignored if using SetPoints.",
    DEFAULT_ATTACH_COUNT_NOTICE = "%s attachments found in object: %s.",
}

return Settings