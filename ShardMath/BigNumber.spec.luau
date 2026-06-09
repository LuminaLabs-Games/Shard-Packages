--[[
	Self-running spec for BigNumber. Require this from a Script in Studio:
		require(game.ReplicatedStorage.Packages.ShardMath.BigNumber.spec)
	Prints one line per passing assertion and errors on the first failure.
]]

local ShardMath = require(script.Parent)
local BigNumber = ShardMath.BigNumber

local HttpService = game:GetService("HttpService")

local passCount = 0

local function assertEqual<T>(actual: T, expected: T, label: string)
	if actual ~= expected then
		error(`{label}: expected {tostring(expected)}, got {tostring(actual)}`, 2)
	end
	passCount += 1
end

local function assertNear(actual: number, expected: number, label: string, tolerance: number?)
	local epsilon = tolerance or 1e-10
	if math.abs(actual - expected) > epsilon * math.max(1, math.abs(expected)) then
		error(`{label}: expected ~{expected}, got {actual}`, 2)
	end
	passCount += 1
end

local function assertTrue(value: boolean, label: string)
	if not value then
		error(`{label}: expected true`, 2)
	end
	passCount += 1
end

local function assertFalse(value: boolean, label: string)
	if value then
		error(`{label}: expected false`, 2)
	end
	passCount += 1
end

-- Construction & normalization
do
	local twelveK = BigNumber.new(12345)
	assertNear(twelveK.mantissa, 1.2345, "new(12345) mantissa")
	assertEqual(twelveK.exponent, 4, "new(12345) exponent")

	local zero = BigNumber.new(0)
	assertEqual(zero.mantissa, 0, "new(0) mantissa")
	assertEqual(zero.exponent, 0, "new(0) exponent")

	local negative = BigNumber.new(-500)
	assertNear(negative.mantissa, -5, "new(-500) mantissa")
	assertEqual(negative.exponent, 2, "new(-500) exponent")

	local fractional = BigNumber.new(0.05)
	assertNear(fractional.mantissa, 5, "new(0.05) mantissa")
	assertEqual(fractional.exponent, -2, "new(0.05) exponent")

	local fromString = BigNumber.new("1.5e100")
	assertNear(fromString.mantissa, 1.5, "new('1.5e100') mantissa")
	assertEqual(fromString.exponent, 100, "new('1.5e100') exponent")
end

-- toNumber round-trip
do
	assertNear(BigNumber.toNumber(BigNumber.new(1.5e15)), 1.5e15, "toNumber(new(1.5e15))")
	assertEqual(BigNumber.toNumber(BigNumber.new(0)), 0, "toNumber(new(0))")
	assertEqual(BigNumber.toNumber(BigNumber.fromComponents(1, 500)), math.huge, "toNumber(1e500) is inf")
end

-- Arithmetic identities
do
	local sample = BigNumber.new(3.7e12)
	local sum = BigNumber.add(sample, BigNumber.zero())
	assertTrue(BigNumber.eq(sum, sample), "add identity: a + 0 == a")

	local product = BigNumber.mul(sample, BigNumber.one())
	assertTrue(BigNumber.eq(product, sample), "mul identity: a * 1 == a")

	local difference = BigNumber.sub(sample, sample)
	assertTrue(BigNumber.eq(difference, BigNumber.zero()), "sub identity: a - a == 0")
end

-- Vanishing-term short-circuit
do
	local huge = BigNumber.fromComponents(1, 100)
	local tiny = BigNumber.new(1)
	local sum = BigNumber.add(huge, tiny)
	assertEqual(sum.exponent, 100, "vanishing add: 1e100 + 1 keeps e=100")
	assertEqual(sum.mantissa, 1, "vanishing add: 1e100 + 1 keeps m=1")
end

-- Multiplication scaling
do
	local twoBillion = BigNumber.new(2e9)
	local threeQuintillion = BigNumber.new(3e18)
	local product = BigNumber.mul(twoBillion, threeQuintillion)
	assertNear(product.mantissa, 6, "2e9 * 3e18 mantissa")
	assertEqual(product.exponent, 27, "2e9 * 3e18 exponent")
end

-- Division
do
	local six = BigNumber.fromComponents(6, 25)
	local three = BigNumber.fromComponents(3, 15)
	local quotient = BigNumber.div(six, three)
	assertNear(quotient.mantissa, 2, "6e25 / 3e15 mantissa")
	assertEqual(quotient.exponent, 10, "6e25 / 3e15 exponent")
end

-- Power
do
	local powerOfTen = BigNumber.pow(BigNumber.new(10), 100)
	assertNear(powerOfTen.mantissa, 1, "pow(10, 100) mantissa", 1e-9)
	assertEqual(powerOfTen.exponent, 100, "pow(10, 100) exponent")

	local twoTo10 = BigNumber.pow(BigNumber.new(2), 10)
	assertNear(BigNumber.toNumber(twoTo10), 1024, "pow(2, 10) toNumber")

	local huge = BigNumber.pow(BigNumber.new(10), 500)
	assertEqual(huge.exponent, 500, "pow(10, 500) exceeds double range cleanly")
end

-- log10
do
	assertNear(BigNumber.log10(BigNumber.new(1e50)), 50, "log10(1e50)")
	assertNear(BigNumber.log10(BigNumber.new(2)), math.log10(2), "log10(2)")
end

-- Comparison
do
	local small = BigNumber.new(5)
	local big = BigNumber.fromComponents(1, 100)
	assertTrue(BigNumber.lt(small, big), "5 < 1e100")
	assertFalse(BigNumber.lt(big, small), "not 1e100 < 5")
	assertTrue(BigNumber.eq(BigNumber.new(42), BigNumber.new(42)), "42 == 42")
	assertTrue(BigNumber.gt(big, small), "1e100 > 5")
	assertTrue(BigNumber.le(small, small), "5 <= 5")
	assertTrue(BigNumber.ge(big, big), "1e100 >= 1e100")

	local negative = BigNumber.new(-1)
	local positive = BigNumber.new(1)
	assertTrue(BigNumber.lt(negative, positive), "-1 < 1")
	assertTrue(BigNumber.lt(BigNumber.new(-10), BigNumber.new(-1)), "-10 < -1")
end

-- Ordered key monotonicity
do
	local previous = -math.huge
	local samples = { BigNumber.new(1e10), BigNumber.new(1e50), BigNumber.new(1e200), BigNumber.fromComponents(1, 1000) }
	for index, value in samples do
		local key = BigNumber.toOrderedKey(value)
		assertTrue(key > previous, `ordered key strictly increasing at index {index}`)
		assertTrue(key < 2 ^ 53, `ordered key fits in safe int range at index {index}`)
		previous = key
	end
end

-- Formatter dispatch -- BigNumber input
do
	local oneAndAHalfBillion = BigNumber.new(1.5e9)
	local formatted = ShardMath.formatNumberWithSuffix(oneAndAHalfBillion, 1)
	assertEqual(formatted, "1.5B", "formatNumberWithSuffix BigNumber(1.5e9) -> 1.5B")

	local enormous = BigNumber.pow(BigNumber.new(10), 50)
	local enormousFormatted = ShardMath.formatNumberWithSuffix(enormous, 0)
	assertTrue(string.len(enormousFormatted) > 0, "formatNumberWithSuffix BigNumber(1e50) returns non-empty")

	local tiny = BigNumber.new(42)
	assertEqual(ShardMath.formatNumberWithSuffix(tiny), "42", "formatNumberWithSuffix BigNumber(42) -> 42")
end

-- Formatter regression: plain number input still works
do
	assertEqual(ShardMath.formatNumberWithSuffix(1500000, 1), "1.5M", "plain 1.5M unchanged")
	assertEqual(ShardMath.formatNumberWithFullName(1000, 0), "1 Thousand", "plain Thousand unchanged")
end

-- Metatable wrapper ergonomics
do
	local left = BigNumber.wrap(BigNumber.new(2e10))
	local right = BigNumber.wrap(BigNumber.new(3e10))
	local sum = left + right
	assertNear(sum.mantissa, 5, "wrapped + wrapped mantissa")
	assertEqual(sum.exponent, 10, "wrapped + wrapped exponent")

	local doubled = left * 2
	assertNear(doubled.mantissa, 4, "wrapped * plain number mantissa")
	assertEqual(doubled.exponent, 10, "wrapped * plain number exponent")

	assertTrue(left < right, "wrapped lt via metamethod")
end

-- ProfileStore / Replica metatable-strip survival
do
	local original = BigNumber.wrap(BigNumber.new(7.3e25))
	local encoded = HttpService:JSONEncode(original)
	local decoded = HttpService:JSONDecode(encoded)
	assertTrue(BigNumber.isBigNumber(decoded), "decoded table is recognized as BigNumber")
	assertEqual(getmetatable(decoded), nil, "decoded table has no metatable (Replica/ProfileStore parity)")

	local incremented = BigNumber.add(decoded, BigNumber.new(1e25))
	assertNear(incremented.mantissa, 8.3, "functional API works on metatable-stripped table")
	assertEqual(incremented.exponent, 25, "functional API exponent correct after strip")
end

print(`[BigNumber.spec] all {passCount} assertions passed`)
