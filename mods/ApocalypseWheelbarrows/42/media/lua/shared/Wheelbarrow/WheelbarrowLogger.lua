WheelbarrowLogger = WheelbarrowLogger or {}

WheelbarrowLogger.LEVELS = {
    ERROR = 1,
    WARN = 2,
    INFO = 3,
    DEBUG = 4,
}

WheelbarrowLogger.LOG_LEVEL = WheelbarrowLogger.LOG_LEVEL or WheelbarrowLogger.LEVELS.INFO
WheelbarrowLogger.PREFIX = "[ApocalypseWheelbarrows]"

local function shouldLog(level)
    return level <= WheelbarrowLogger.LOG_LEVEL
end

local function emit(levelName, levelValue, message)
    if not shouldLog(levelValue) then
        return
    end

    print(string.format("%s [%s] %s", WheelbarrowLogger.PREFIX, levelName, tostring(message)))
end

function WheelbarrowLogger.error(message)
    emit("ERROR", WheelbarrowLogger.LEVELS.ERROR, message)
end

function WheelbarrowLogger.warn(message)
    emit("WARN", WheelbarrowLogger.LEVELS.WARN, message)
end

function WheelbarrowLogger.info(message)
    emit("INFO", WheelbarrowLogger.LEVELS.INFO, message)
end

function WheelbarrowLogger.debug(message)
    emit("DEBUG", WheelbarrowLogger.LEVELS.DEBUG, message)
end
