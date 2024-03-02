PulsarLib = PulsarLib or {}
PulsarLib.Functional = {}
local fn = PulsarLib.Functional

local select = select
local unpack = unpack

--- Builds a partial function, with stored arguments.
--- @param func function Input function to curry.
--- @param ... any Arguments to store.
--- @return function function Partial function.
--- See https://docs.lythium.dev/pulsar-lib/functional/partial
function fn.partial(func, ...)
	local args = {...}
	local st = #args

	return function(...)
		local m = select("#", ...)
		for i = 1, m do
			args[st + i] = select(i, ...)
		end

		return func(unpack(args, 1, st + m))
	end
end

--- Returns parameters without any changes.
--- @param ... any Input paramters.
local function null(...) return ... end

--- Returns a function where the first two inputs are flipped.
--- @param func function Input function.
--- @return function function Flipped function.
--- See https://docs.lythium.dev/pulsar-lib/functional/flip
function fn.flip(func)
	return function(a, b, ...)
		return func(b, a, ...)
	end
end

--- Reverses a set of input arguments.
--- @param ... any Input argument.
--- @return ... Flipped outputs.
--- See https://docs.lythium.dev/pulsar-lib/functional/reverse
function fn.reverse(...)
	local function reverse_h(acc, v, ...)
		if select('#', ...) == 0 then
			return v, acc()
		else
			return reverse_h(function() return v, acc() end, ...)
		end
	end

	return reverse_h(function() return end, ...)
end

--- Build a function o from f/g so that f(g(x)) == o(x)
--- @param ... function Input functions.
--- @return function function Composed function.
--- See https://docs.lythium.dev/pulsar-lib/functional/reverse
function fn.compose(...)
	local m = select("#", ...)
	if m == 0 then return null end

	local funcs = {...}
	if m == 1 then return funcs[1] end

	return function(...)
		local values = {...}

		-- Go through the functions backwards.
		for i = m, 1, -1 do
			values = {funcs[i](unpack(values))}
		end

		return unpack(values)
	end
end