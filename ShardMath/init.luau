--[[
    Shard math is mainly used for formatting numbers with suffixes and full names. It supports OOP and functional programming.
    ```lua
    -- // OOP:
    local ShardMath = require(script.Parent.ShardMath)
    local shardMath = ShardMath.new(1000000)
    print(shardMath:formatWithSuffix()) -- 1M
    print(shardMath:formatWithFullName()) -- 1 Million

    -- // Functional:
    print(ShardMath.formatNumberWithSuffix(1000000)) -- 1M
    print(ShardMath.formatNumberWithFullName(1000000)) -- 1 Million

    -- // With decimal places:
    print(ShardMath.formatNumberWithSuffix(1000000, 2)) -- 1.00M

    -- // BigNumber for values beyond Roblox's safe int range:
    local BigNumber = ShardMath.BigNumber
    local huge = BigNumber.pow(BigNumber.new(10), 100)        -- 1e100
    print(ShardMath.formatNumberWithSuffix(huge))             -- e.g. "10 DTG"
    local leaderboardKey = BigNumber.toOrderedKey(huge)       -- int64 for OrderedDataStore
    ```
]]

local ShardMath = {}
ShardMath.__index = ShardMath

local suffixes = require(script.Suffixes)
local fullNames = require(script.FullNames)
local BigNumber = require(script.BigNumber)

ShardMath.BigNumber = BigNumber

type NumericInput = number | BigNumber.BigNumber

type ShardMath = {
	number: NumericInput,
	decimalPlaces: number?,
	formatWithSuffix: (self: ShardMath) -> string,
	formatWithFullName: (self: ShardMath) -> string,
}

function ShardMath.new(number: NumericInput, decimalPlaces: number?): ShardMath
	local self = setmetatable({}, ShardMath)
	self.number = number
	self.decimalPlaces = decimalPlaces or 1
	return self
end

local function roundToDecimal(number, decimalPlaces)
	local factor = 10 ^ decimalPlaces
	return math.floor(number * factor) / factor
end

local function formatBigNumberWithLookup(
	value: BigNumber.BigNumber,
	decimalPlaces: number,
	lookup: { string },
	separator: string
): string
	local mantissa = value.mantissa
	if mantissa == 0 then
		return "0"
	end
	local absoluteMantissa = math.abs(mantissa)
	local totalLog = math.log10(absoluteMantissa) + value.exponent
	if totalLog < 3 then
		local plainValue = mantissa * (10 ^ value.exponent)
		return string.format("%d", plainValue)
	end
	local suffixIndex = math.floor(totalLog / 3)
	local suffix = lookup[suffixIndex] or ""
	local scaledValue = mantissa * (10 ^ (value.exponent - 3 * suffixIndex))
	local rounded = roundToDecimal(scaledValue, decimalPlaces)
	if rounded == math.floor(rounded) then
		return string.format(`%d%s%s`, rounded, separator, suffix)
	end
	return string.format(`%.{decimalPlaces}f%s%s`, rounded, separator, suffix)
end

function ShardMath.formatNumberWithSuffix(number: NumericInput?, decimalPlaces: number?): string
	local places = decimalPlaces or 0

	if BigNumber.isBigNumber(number) then
		return formatBigNumberWithLookup(number :: BigNumber.BigNumber, places, suffixes, "")
	end

	local numeric = tonumber(number)
	if not numeric then
		return "NaN"
	end

	local absoluteNumber = math.abs(numeric)

	if absoluteNumber < 1000 then
		return string.format("%d", numeric)
	end

	local suffixIndex = math.floor(math.log10(absoluteNumber) / 3)
	local suffix = suffixes[suffixIndex] or ""

	local scaledNumber = roundToDecimal(numeric / (1000 ^ suffixIndex), places)

	if scaledNumber == math.floor(scaledNumber) then
		return string.format("%d%s", scaledNumber, suffix)
	else
		return string.format(`%.{places}f%s`, scaledNumber, suffix)
	end
end

function ShardMath:formatWithSuffix(): string
	return ShardMath.formatNumberWithSuffix(self.number, self.decimalPlaces or 1)
end

function ShardMath.formatNumberWithFullName(number: NumericInput, decimalPlaces: number?): string
	local places = decimalPlaces or 1

	if BigNumber.isBigNumber(number) then
		return formatBigNumberWithLookup(number :: BigNumber.BigNumber, places, fullNames, " ")
	end

	local plainNumber = tonumber(number) or 0
	local absoluteNumber = math.abs(plainNumber)

	if absoluteNumber < 1000 then
		return string.format("%d", plainNumber)
	end

	local suffixIndex = math.floor(math.log10(absoluteNumber) / 3)
	local suffix = fullNames[suffixIndex] or ""

	local scaledNumber = roundToDecimal(plainNumber / (1000 ^ suffixIndex), places)

	if scaledNumber == math.floor(scaledNumber) then
		return string.format("%d %s", scaledNumber, suffix)
	else
		return string.format(`%.{places}f %s`, scaledNumber, suffix)
	end
end

function ShardMath:formatWithFullName(): string
	return ShardMath.formatNumberWithFullName(self.number, self.decimalPlaces or 1)
end

function ShardMath.formatRobuxCurrency(number: NumericInput): string
	local formattedNumber = ShardMath.formatNumberWithSuffix(number, 2)
	return `\u{e002} {formattedNumber}`
end

function ShardMath.formatCurrency(number: NumericInput, decimalPlaces: number?, symbol: string?): string
	local formattedNumber = ShardMath.formatNumberWithSuffix(number, decimalPlaces or 2)
	return `{symbol or "$"} {formattedNumber}`
end

return ShardMath
