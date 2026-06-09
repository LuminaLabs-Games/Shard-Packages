--!strict
--[[
	BigNumber: scientific-notation big number for shardmath.

	Representation: { mantissa: number, exponent: number }
	Invariants after normalization:
		mantissa == 0  AND  exponent == 0          (canonical zero)
		OR  1 <= abs(mantissa) < 10                 (scientific form)

	Two API layers:
		1. Functional (primary, fast, no metatable lookups): BigNumber.add(a, b), etc.
		   Plain {mantissa, exponent} tables in and out -- survives ProfileStore /
		   Replica round-trips, which strip metatables.
		2. Ergonomic wrapper (optional): BigNumber.wrap(value) attaches a metatable
		   so callers can write `a + b * c`. Strip with unwrap() before serializing.

	Usage:
		local BigNumber = require(script.Parent.BigNumber)
		local power = BigNumber.new(0)
		power = BigNumber.add(power, BigNumber.new(1.5e100))
		print(BigNumber.toString(power))                  --> "1.5e100"
		print(ShardMath.formatNumberWithSuffix(power))    --> "15 NQQD" (or similar)
]]

local BigNumber = {}

export type BigNumber = { mantissa: number, exponent: number }

local MAX_EXPONENT_DIFF_FOR_ADD = 16
local mt = {}

local function normalizeInPlace(value: BigNumber): BigNumber
	if value.mantissa == 0 then
		value.exponent = 0
		return value
	end
	local absoluteMantissa = math.abs(value.mantissa)
	if absoluteMantissa >= 10 or absoluteMantissa < 1 then
		local shift = math.floor(math.log10(absoluteMantissa))
		value.mantissa = value.mantissa / (10 ^ shift)
		value.exponent = value.exponent + shift
	end
	return value
end

function BigNumber.zero(): BigNumber
	return { mantissa = 0, exponent = 0 }
end

function BigNumber.one(): BigNumber
	return { mantissa = 1, exponent = 0 }
end

function BigNumber.fromComponents(mantissa: number, exponent: number): BigNumber
	return normalizeInPlace({ mantissa = mantissa, exponent = exponent })
end

function BigNumber.isBigNumber(value: any): boolean
	return typeof(value) == "table"
		and typeof(value.mantissa) == "number"
		and typeof(value.exponent) == "number"
end

function BigNumber.new(value: number | string | BigNumber): BigNumber
	if typeof(value) == "number" then
		if value == 0 then
			return { mantissa = 0, exponent = 0 }
		end
		local exponent = math.floor(math.log10(math.abs(value)))
		return { mantissa = value / (10 ^ exponent), exponent = exponent }
	elseif typeof(value) == "string" then
		local parsed = tonumber(value)
		if parsed ~= nil then
			return BigNumber.new(parsed)
		end
		local mantissaStr, exponentStr = string.match(value, "^(-?%d+%.?%d*)[eE]([+-]?%d+)$")
		if mantissaStr and exponentStr then
			local parsedMantissa = tonumber(mantissaStr)
			local parsedExponent = tonumber(exponentStr)
			if parsedMantissa and parsedExponent then
				return BigNumber.fromComponents(parsedMantissa, parsedExponent)
			end
		end
		error(`BigNumber.new: cannot parse string "{value}"`, 2)
	elseif BigNumber.isBigNumber(value) then
		return { mantissa = (value :: BigNumber).mantissa, exponent = (value :: BigNumber).exponent }
	end
	error(`BigNumber.new: unsupported type {typeof(value)}`, 2)
end

local function coerce(value: any): BigNumber
	if BigNumber.isBigNumber(value) then
		return value
	end
	return BigNumber.new(value)
end

function BigNumber.neg(value: BigNumber): BigNumber
	return { mantissa = -value.mantissa, exponent = value.exponent }
end

function BigNumber.add(left: BigNumber, right: BigNumber): BigNumber
	if left.mantissa == 0 then
		return { mantissa = right.mantissa, exponent = right.exponent }
	end
	if right.mantissa == 0 then
		return { mantissa = left.mantissa, exponent = left.exponent }
	end
	local exponentDiff = left.exponent - right.exponent
	if exponentDiff > MAX_EXPONENT_DIFF_FOR_ADD then
		return { mantissa = left.mantissa, exponent = left.exponent }
	end
	if exponentDiff < -MAX_EXPONENT_DIFF_FOR_ADD then
		return { mantissa = right.mantissa, exponent = right.exponent }
	end
	local resultMantissa: number
	local resultExponent: number
	if exponentDiff >= 0 then
		resultMantissa = left.mantissa + right.mantissa / (10 ^ exponentDiff)
		resultExponent = left.exponent
	else
		resultMantissa = right.mantissa + left.mantissa / (10 ^ -exponentDiff)
		resultExponent = right.exponent
	end
	if resultMantissa == 0 then
		return { mantissa = 0, exponent = 0 }
	end
	local absoluteMantissa = math.abs(resultMantissa)
	if absoluteMantissa >= 10 or absoluteMantissa < 1 then
		local shift = math.floor(math.log10(absoluteMantissa))
		return { mantissa = resultMantissa / (10 ^ shift), exponent = resultExponent + shift }
	end
	return { mantissa = resultMantissa, exponent = resultExponent }
end

function BigNumber.sub(left: BigNumber, right: BigNumber): BigNumber
	return BigNumber.add(left, { mantissa = -right.mantissa, exponent = right.exponent })
end

function BigNumber.mul(left: BigNumber, right: BigNumber): BigNumber
	if left.mantissa == 0 or right.mantissa == 0 then
		return { mantissa = 0, exponent = 0 }
	end
	local resultMantissa = left.mantissa * right.mantissa
	local resultExponent = left.exponent + right.exponent
	local absoluteMantissa = math.abs(resultMantissa)
	if absoluteMantissa >= 10 or absoluteMantissa < 1 then
		local shift = math.floor(math.log10(absoluteMantissa))
		return { mantissa = resultMantissa / (10 ^ shift), exponent = resultExponent + shift }
	end
	return { mantissa = resultMantissa, exponent = resultExponent }
end

function BigNumber.div(left: BigNumber, right: BigNumber): BigNumber
	if right.mantissa == 0 then
		error("BigNumber.div: division by zero", 2)
	end
	if left.mantissa == 0 then
		return { mantissa = 0, exponent = 0 }
	end
	local resultMantissa = left.mantissa / right.mantissa
	local resultExponent = left.exponent - right.exponent
	local absoluteMantissa = math.abs(resultMantissa)
	if absoluteMantissa >= 10 or absoluteMantissa < 1 then
		local shift = math.floor(math.log10(absoluteMantissa))
		return { mantissa = resultMantissa / (10 ^ shift), exponent = resultExponent + shift }
	end
	return { mantissa = resultMantissa, exponent = resultExponent }
end

function BigNumber.pow(base: BigNumber, exponent: number): BigNumber
	if exponent == 0 then
		return { mantissa = 1, exponent = 0 }
	end
	if base.mantissa == 0 then
		return { mantissa = 0, exponent = 0 }
	end
	if base.mantissa < 0 then
		if exponent ~= math.floor(exponent) then
			error("BigNumber.pow: non-integer exponent on negative base", 2)
		end
		local positiveResult = BigNumber.pow(
			{ mantissa = -base.mantissa, exponent = base.exponent },
			exponent
		)
		if exponent % 2 == 0 then
			return positiveResult
		end
		return { mantissa = -positiveResult.mantissa, exponent = positiveResult.exponent }
	end
	local logBase = math.log10(base.mantissa) + base.exponent
	local logResult = logBase * exponent
	local resultExponent = math.floor(logResult)
	return { mantissa = 10 ^ (logResult - resultExponent), exponent = resultExponent }
end

function BigNumber.log10(value: BigNumber): number
	if value.mantissa <= 0 then
		error("BigNumber.log10: non-positive argument", 2)
	end
	return math.log10(value.mantissa) + value.exponent
end

function BigNumber.eq(left: BigNumber, right: BigNumber): boolean
	return left.mantissa == right.mantissa and left.exponent == right.exponent
end

function BigNumber.lt(left: BigNumber, right: BigNumber): boolean
	local leftSign = if left.mantissa > 0 then 1 elseif left.mantissa < 0 then -1 else 0
	local rightSign = if right.mantissa > 0 then 1 elseif right.mantissa < 0 then -1 else 0
	if leftSign ~= rightSign then
		return leftSign < rightSign
	end
	if leftSign == 0 then
		return false
	end
	if leftSign > 0 then
		if left.exponent ~= right.exponent then
			return left.exponent < right.exponent
		end
		return left.mantissa < right.mantissa
	end
	if left.exponent ~= right.exponent then
		return left.exponent > right.exponent
	end
	return left.mantissa < right.mantissa
end

function BigNumber.le(left: BigNumber, right: BigNumber): boolean
	return BigNumber.eq(left, right) or BigNumber.lt(left, right)
end

function BigNumber.gt(left: BigNumber, right: BigNumber): boolean
	return BigNumber.lt(right, left)
end

function BigNumber.ge(left: BigNumber, right: BigNumber): boolean
	return BigNumber.eq(left, right) or BigNumber.lt(right, left)
end

function BigNumber.max(left: BigNumber, right: BigNumber): BigNumber
	if BigNumber.lt(left, right) then
		return { mantissa = right.mantissa, exponent = right.exponent }
	end
	return { mantissa = left.mantissa, exponent = left.exponent }
end

function BigNumber.min(left: BigNumber, right: BigNumber): BigNumber
	if BigNumber.lt(left, right) then
		return { mantissa = left.mantissa, exponent = left.exponent }
	end
	return { mantissa = right.mantissa, exponent = right.exponent }
end

function BigNumber.floor(value: BigNumber): BigNumber
	if value.exponent < 0 then
		if value.mantissa >= 0 then
			return { mantissa = 0, exponent = 0 }
		end
		return { mantissa = -1, exponent = 0 }
	end
	if value.exponent >= 15 then
		return { mantissa = value.mantissa, exponent = value.exponent }
	end
	local scale = 10 ^ value.exponent
	local fullValue = math.floor(value.mantissa * scale)
	if fullValue == 0 then
		return { mantissa = 0, exponent = 0 }
	end
	return BigNumber.new(fullValue)
end

function BigNumber.toNumber(value: BigNumber): number
	if value.exponent > 308 then
		return if value.mantissa >= 0 then math.huge else -math.huge
	end
	return value.mantissa * (10 ^ value.exponent)
end

function BigNumber.toString(value: BigNumber): string
	if value.mantissa == 0 then
		return "0"
	end
	return string.format("%.6ge%d", value.mantissa, value.exponent)
end

function BigNumber.toOrderedKey(value: BigNumber): number
	-- OrderedDataStore key: monotonic int64 derived from log10(value), preserving 9
	-- decimal digits of magnitude. Negative / zero values clamp to 0.
	if value.mantissa <= 0 then
		return 0
	end
	local logValue = math.log10(value.mantissa) + value.exponent
	return math.floor(logValue * 1e9)
end

function BigNumber.wrap(value: BigNumber): BigNumber
	return setmetatable({ mantissa = value.mantissa, exponent = value.exponent }, mt) :: any
end

function BigNumber.unwrap(value: BigNumber): BigNumber
	return { mantissa = value.mantissa, exponent = value.exponent }
end

mt.__add = function(left: any, right: any): any
	return BigNumber.wrap(BigNumber.add(coerce(left), coerce(right)))
end
mt.__sub = function(left: any, right: any): any
	return BigNumber.wrap(BigNumber.sub(coerce(left), coerce(right)))
end
mt.__mul = function(left: any, right: any): any
	return BigNumber.wrap(BigNumber.mul(coerce(left), coerce(right)))
end
mt.__div = function(left: any, right: any): any
	return BigNumber.wrap(BigNumber.div(coerce(left), coerce(right)))
end
mt.__pow = function(base: any, exponent: any): any
	return BigNumber.wrap(BigNumber.pow(coerce(base), exponent))
end
mt.__unm = function(value: any): any
	return BigNumber.wrap(BigNumber.neg(value))
end
mt.__eq = function(left: any, right: any): boolean
	return BigNumber.eq(left, right)
end
mt.__lt = function(left: any, right: any): boolean
	return BigNumber.lt(left, right)
end
mt.__le = function(left: any, right: any): boolean
	return BigNumber.le(left, right)
end
mt.__tostring = function(value: any): string
	return BigNumber.toString(value)
end

return BigNumber
