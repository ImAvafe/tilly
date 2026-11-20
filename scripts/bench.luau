--!strict

local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")

local tilly = require(script.Parent) :: any
local defaultTokens = require("./tokens")
local generateTags = require("./generateTags")
local mergeTokensets = require("./util/mergeTokensets")
local resolveTag = require("./resolveTag")

export type Baseline = {
	studio: string,
	medians: { [string]: number },
	p90s: { [string]: number }?,
	calibration: number?,
}

export type Options = {
	tokens: { [string]: any }?, -- Merged over the default tokens
	reps: number?, -- Defaults to 30
	baseline: Baseline?, -- The decoded `json` of an earlier run
	-- Fraction over the baseline's median (and past its p90) that counts as a regression. Defaults to 0.25
	threshold: number?,
	only: string?, -- Only run cases whose name contains this
}

export type Result = {
	name: string,
	unit: string,
	median: number, -- Microseconds per unit
	p90: number,
	change: number?, -- Relative to the baseline, like 0.12 for 12% slower
}

export type Report = {
	results: { Result },
	regressions: { string },
	notes: { string },
	text: string,
	json: string, -- Save this and pass it back as `baseline` next time
}

type Context = {
	sheet: StyleSheet,
	addTags: (Instance, string) -> () -> (),
	destroy: () -> (),
}

type Case = {
	name: string,
	unit: string,
	reps: number?,
	setup: (() -> any)?, -- Not timed
	run: (state: any) -> number, -- Returns how many units it did
	teardown: ((state: any) -> ())?, -- Not timed
}

const DEFAULT_REPS = 30
const DEFAULT_THRESHOLD = 0.25
const CALIBRATION_TOLERANCE = 0.2
const INSTANCES = 500 -- Instances per sample in the bulk cases
const UNIQUE_TAGS = 100 -- New tags per sample in the sheet size cases
-- Short samples are mostly noise, so cheap cases repeat their work to at least about a millisecond
const MIN_RESOLVES = 1000 -- Resolves per sample in the per-prefix cases
const CACHED_CALLS = 2000 -- Calls per sample in the cached tag cases
const MAX_COMPONENT_TAGS = 12 -- Tags per composite property whose pairs are tagged
const CUSTOM_TOKENS = 1000
const PREFIX_REPS = 20
const YIELD_INTERVAL = 0.05 -- Seconds
const WARM_UP_LIMIT = 3 -- Seconds

const STRINGS = {
	button = "text-white bg-red-500 hover:bg-red-400 px-4 py-3 rounded-lg border border-gray-700",
	card = "flex flex-row items-center content-center gap-2 p-4 bg-gray-800 rounded-lg border-2 border-gray-700",
	composite = "shadow-md w-64 h-12 max-w-lg min-h-8 opacity-50 transition duration-200 hover:bg-gray-700 font-mono font-bold",
}
const STRING_NAMES = { "button", "card", "composite" }
const INVALID_TAGS = { "bg-not-a-color", "nope-4", "hover:zzz", "w-4-4-4-4" }

local root: Folder? = nil

const function newContext(tokens: { [string]: any }?): Context
	const sheet = Instance.new("StyleSheet")
	sheet.Parent = root
	const addTags, destroy = tilly(sheet, tokens)
	return {
		sheet = sheet,
		addTags = addTags,
		destroy = destroy,
	}
end

const function destroyContext(context: Context)
	context.destroy()
	context.sheet:Destroy()
end

const function newFrames(count: number): { Frame }
	const frames = table.create(count)
	for index = 1, count do
		frames[index] = Instance.new("Frame")
	end
	return frames
end

const function destroyFrames(frames: { Frame })
	for _, frame in frames do
		frame:Destroy()
	end
end

const function countTags(tags: string): number
	return #string.split(tags, " ")
end

--[[
	Up to `count` items spread evenly through `list`.
]]
const function spread<T>(list: { T }, count: number): { T }
	if #list <= count then
		return list
	end
	const picked = {}
	for index = 1, count do
		table.insert(picked, list[math.floor((index - 1) * #list / count) + 1])
	end
	return picked
end

const function buildCases(options: Options): { Case }
	const customTokens = options.tokens
	const tokens: { [string]: any } = (mergeTokensets :: any)({ defaultTokens, customTokens or {} })
	const tagSet = generateTags(tokens)
	const cases: { Case } = {}

	const allTags = {}
	const tagsByPrefix: { [string]: { string } } = {}
	const prefixes = {}
	for _, entry in tagSet.generated do
		table.insert(allTags, entry.tag)
		if tagsByPrefix[entry.prefix] == nil then
			tagsByPrefix[entry.prefix] = {}
			table.insert(prefixes, entry.prefix)
		end
		table.insert(tagsByPrefix[entry.prefix], entry.tag)
	end

	const variantTags = {}
	for _, sample in tagSet.samples do
		table.insert(variantTags, `{sample.tag}!`)
		for _, variant in tagSet.variants do
			table.insert(variantTags, `{variant}{sample.tag}`)
			table.insert(variantTags, `{variant}{sample.tag}!`)
		end
	end

	table.insert(cases, {
		name = "init",
		unit = "call",
		setup = function()
			const sheet = Instance.new("StyleSheet")
			sheet.Parent = root
			return { sheet = sheet }
		end,
		run = function(state)
			const _, destroy = tilly(state.sheet, customTokens)
			state.destroy = destroy
			return 1
		end,
		teardown = function(state)
			state.destroy()
			state.sheet:Destroy()
		end,
	})

	const manyTokens = table.clone(customTokens or {})
	for index = 1, CUSTOM_TOKENS do
		manyTokens[`color-bench-{index}`] = Color3.new(index / CUSTOM_TOKENS, 0, 0)
	end
	table.insert(cases, {
		name = `init, {CUSTOM_TOKENS} custom tokens`,
		unit = "call",
		setup = function()
			const sheet = Instance.new("StyleSheet")
			sheet.Parent = root
			return { sheet = sheet }
		end,
		run = function(state)
			const _, destroy = tilly(state.sheet, manyTokens)
			state.destroy = destroy
			return 1
		end,
		teardown = function(state)
			state.destroy()
			state.sheet:Destroy()
		end,
	})

	table.insert(cases, {
		name = "destroy, 2000 rules",
		unit = "rule",
		reps = 5,
		setup = function()
			const context = newContext(customTokens)
			const frame = Instance.new("Frame")
			for index = 1, 2000 do
				context.addTags(frame, `p-{index}`)
			end
			return {
				context = context,
				frame = frame,
				rules = #context.sheet:GetChildren(),
			}
		end,
		run = function(state)
			state.context.destroy()
			return state.rules
		end,
		teardown = function(state)
			state.context.sheet:Destroy()
			state.frame:Destroy()
		end,
	})

	table.insert(cases, {
		name = `resolveTag, all {#allTags} tags`,
		unit = "tag",
		run = function()
			for _, tag in allTags do
				resolveTag(tag, tokens)
			end
			return #allTags
		end,
	})

	table.insert(cases, {
		name = `resolveTag, {#variantTags} variant and ! tags`,
		unit = "tag",
		run = function()
			for _, tag in variantTags do
				resolveTag(tag, tokens)
			end
			return #variantTags
		end,
	})

	table.insert(cases, {
		name = "resolveTag, invalid tags",
		unit = "tag",
		reps = 3,
		run = function()
			for _, tag in INVALID_TAGS do
				resolveTag(tag, tokens)
			end
			return #INVALID_TAGS
		end,
	})

	for _, prefix in prefixes do
		const prefixTags = tagsByPrefix[prefix]
		const rounds = math.ceil(MIN_RESOLVES / #prefixTags)
		table.insert(cases, {
			name = `resolveTag prefix: {prefix}`,
			unit = "tag",
			reps = PREFIX_REPS,
			run = function()
				for _ = 1, rounds do
					for _, tag in prefixTags do
						resolveTag(tag, tokens)
					end
				end
				return rounds * #prefixTags
			end,
		})
	end

	table.insert(cases, {
		name = `addTags cold, all {#allTags} tags`,
		unit = "tag",
		reps = 3,
		setup = function()
			return {
				context = newContext(customTokens),
				frames = newFrames(#allTags),
			}
		end,
		run = function(state)
			const addTags = state.context.addTags
			for index, tag in allTags do
				addTags(state.frames[index], tag)
			end
			return #allTags
		end,
		teardown = function(state)
			destroyContext(state.context)
			destroyFrames(state.frames)
		end,
	})

	for _, name in STRING_NAMES do
		const tags = STRINGS[name]

		table.insert(cases, {
			name = `addTags cold: {name}`,
			unit = "tag",
			setup = function()
				return {
					context = newContext(customTokens),
					frame = Instance.new("Frame"),
				}
			end,
			run = function(state)
				state.context.addTags(state.frame, tags)
				return countTags(tags)
			end,
			teardown = function(state)
				destroyContext(state.context)
				state.frame:Destroy()
			end,
		})

		table.insert(cases, {
			name = `addTags cached: {name}`,
			unit = "instance",
			reps = 15,
			setup = function()
				const context = newContext(customTokens)
				const warm = Instance.new("Frame")
				context.addTags(warm, tags)
				const frames = newFrames(INSTANCES)
				table.insert(frames, warm)
				return {
					context = context,
					frames = frames,
				}
			end,
			run = function(state)
				const addTags = state.context.addTags
				for index = 1, INSTANCES do
					addTags(state.frames[index], tags)
				end
				return INSTANCES
			end,
			teardown = function(state)
				destroyContext(state.context)
				destroyFrames(state.frames)
			end,
		})

		table.insert(cases, {
			name = `cleanup: {name}`,
			unit = "instance",
			reps = 15,
			setup = function()
				const context = newContext(customTokens)
				const frames = newFrames(INSTANCES)
				const cleanups = table.create(INSTANCES)
				for index, frame in frames do
					cleanups[index] = context.addTags(frame, tags)
				end
				return {
					context = context,
					frames = frames,
					cleanups = cleanups,
				}
			end,
			run = function(state)
				for _, cleanup in state.cleanups do
					cleanup()
				end
				return INSTANCES
			end,
			teardown = function(state)
				destroyContext(state.context)
				destroyFrames(state.frames)
			end,
		})
	end

	-- Should stay flat: a cached tag shouldn't cost more on an instance that has many tags
	for _, existing in { 1, 50, 200 } do
		table.insert(cases, {
			name = `one cached tag, {existing} existing tags`,
			unit = "call",
			setup = function()
				const context = newContext(customTokens)
				const warm = Instance.new("Frame")
				context.addTags(warm, "p-1")
				const frame = Instance.new("Frame")
				for index = 1, existing do
					frame:AddTag(`existing-{index}`)
				end
				return {
					context = context,
					frames = { warm, frame },
					frame = frame,
				}
			end,
			run = function(state)
				const addTags = state.context.addTags
				for _ = 1, CACHED_CALLS do
					addTags(state.frame, "p-1")
				end
				return CACHED_CALLS
			end,
			teardown = function(state)
				destroyContext(state.context)
				destroyFrames(state.frames)
			end,
		})
	end

	-- Grows with the sheet because the engine reindexes it on each new rule
	for _, size in { 0, 1000, 2000 } do
		table.insert(cases, {
			name = `new tag, sheet of {size} rules`,
			unit = "tag",
			reps = 8,
			setup = function()
				const context = newContext(customTokens)
				const frame = Instance.new("Frame")
				for index = 1, size do
					context.addTags(frame, `p-{index}`)
				end
				const frames = newFrames(UNIQUE_TAGS)
				table.insert(frames, frame)
				return {
					context = context,
					frames = frames,
				}
			end,
			run = function(state)
				const addTags = state.context.addTags
				for index = 1, UNIQUE_TAGS do
					addTags(state.frames[index], `p-{size + index}`)
				end
				return UNIQUE_TAGS
			end,
			teardown = function(state)
				destroyContext(state.context)
				destroyFrames(state.frames)
			end,
		})
	end

	const componentGroups: { [string]: { string } } = {}
	const groupKeys = {}
	for _, tag in allTags do
		const rule = resolveTag(tag, tokens)
		const component = rule and rule.component
		if component then
			const key = component.property .. component.selectorSuffix
			if componentGroups[key] == nil then
				componentGroups[key] = {}
				table.insert(groupKeys, key)
			end
			table.insert(componentGroups[key], tag)
		end
	end
	table.sort(groupKeys)

	for _, key in groupKeys do
		const picked = spread(componentGroups[key], MAX_COMPONENT_TAGS)
		const tagPairs = {}
		for i = 1, #picked do
			for j = i + 1, #picked do
				table.insert(tagPairs, `{picked[i]} {picked[j]}`)
			end
		end
		if #tagPairs == 0 then
			continue
		end

		table.insert(cases, {
			name = `compound pairs: {if key == "*" then "transition" else key}`,
			unit = "instance",
			reps = 20,
			setup = function()
				return {
					context = newContext(customTokens),
					frames = newFrames(#tagPairs),
				}
			end,
			run = function(state)
				const addTags = state.context.addTags
				for index, tags in tagPairs do
					addTags(state.frames[index], tags)
				end
				return #tagPairs
			end,
			teardown = function(state)
				destroyContext(state.context)
				destroyFrames(state.frames)
			end,
		})
	end

	return cases
end

--[[
	Times fixed work that doesn't touch Tilly, to tell when the machine itself got slower or faster.
]]
const function calibrate(): number
	const samples = {}
	for index = 1, 7 do
		const start = os.clock()
		local total = 0
		for value = 1, 60000 do
			total += #`calibrate-{value}`
		end
		samples[index] = (os.clock() - start) * 1e6
	end
	table.sort(samples)
	return samples[4]
end

const function percentile(sorted: { number }, fraction: number): number
	return sorted[math.clamp(math.ceil(#sorted * fraction), 1, #sorted)]
end

local lastYield = 0

--[[
	Lets Studio run a frame once enough work has piled up. Never call it while a sample is timed.
]]
const function yieldIfBusy()
	if os.clock() - lastYield > YIELD_INTERVAL then
		task.wait()
		lastYield = os.clock()
	end
end

const function measure(case: Case, reps: number): (number, number)
	const samples = table.create(reps)
	-- Sample 0 is a warm-up that isn't kept, so the first case doesn't pay for cold caches
	for index = 0, reps do
		const state = if case.setup then case.setup() else nil
		debug.profilebegin(`tilly bench: {case.name}`)
		const start = os.clock()
		const units = case.run(state)
		const elapsed = os.clock() - start
		debug.profileend()
		if case.teardown then
			case.teardown(state)
		end
		if index > 0 then
			samples[index] = elapsed * 1e6 / units
		end
		yieldIfBusy()
	end
	table.sort(samples)
	return percentile(samples, 0.5), percentile(samples, 0.9)
end

const function formatChange(change: number?): string
	if change == nil then
		return ""
	end
	return string.format("%+.0f%%", change * 100)
end

--[[
	Times Tilly's synchronous cost (resolving, rule creation, tagging, cleanup) and compares it against `baseline`.
	Run it on a fresh clone, since Studio caches required modules:

	local c = game.ReplicatedStorage.tilly:Clone()
	c.Parent = game.ServerStorage
	local report = require(c.bench)({ baseline = HttpService:JSONDecode(json) })
	c:Destroy()

	Through the Studio MCP, run it once per `execute_luau` call with an `operation_id`, so a timed-out call can be
	awaited with `get_request_status` instead of started again. The "invalid tags" case's warnings are expected.
]]
const function runBench(options: Options?): Report
	const config: Options = options or {}
	const threshold = config.threshold or DEFAULT_THRESHOLD
	const baseline = config.baseline

	const folder = Instance.new("Folder")
	folder.Name = "TillyBench"
	folder.Parent = ServerStorage
	root = folder

	const report: Report = {
		results = {},
		regressions = {},
		notes = {},
		text = "",
		json = "",
	}

	if baseline ~= nil and baseline.studio ~= version() then
		table.insert(
			report.notes,
			`baseline is from Studio {baseline.studio}, this is {version()}; engine-side costs may differ`
		)
	end

	-- The CPU can start out slow and speed up under load, so keep it busy until calibration settles
	const warmUpDeadline = os.clock() + WARM_UP_LIMIT
	local calibrationBefore = calibrate()
	while os.clock() < warmUpDeadline do
		yieldIfBusy()
		const next = calibrate()
		const settled = math.abs(next / calibrationBefore - 1) < 0.05
		calibrationBefore = next
		if settled then
			break
		end
	end
	if baseline ~= nil and baseline.calibration ~= nil then
		const drift = calibrationBefore / baseline.calibration - 1
		if math.abs(drift) > CALIBRATION_TOLERANCE then
			table.insert(
				report.notes,
				`calibration time is {formatChange(drift)} against the baseline's, so changes are unreliable`
			)
		end
	end

	const medians = {}
	const p90s = {}
	for _, case in buildCases(config) do
		if config.only ~= nil and not string.find(case.name, config.only, 1, true) then
			continue
		end

		const ok, median, p90 = pcall(measure, case, case.reps or config.reps or DEFAULT_REPS)
		if not ok then
			table.insert(report.notes, `{case.name} errored: {median}`)
			continue
		end

		const previous = if baseline ~= nil then baseline.medians[case.name] else nil
		const previousP90 = if baseline ~= nil and baseline.p90s ~= nil then baseline.p90s[case.name] else nil
		const change = if previous ~= nil and previous > 0 then median / previous - 1 else nil
		if change ~= nil and change > threshold and (previousP90 == nil or median > previousP90) then
			table.insert(report.regressions, `{case.name}: {formatChange(change)}`)
		end

		medians[case.name] = median
		p90s[case.name] = p90
		table.insert(report.results, {
			name = case.name,
			unit = case.unit,
			median = median,
			p90 = p90,
			change = change,
		})
	end

	if baseline ~= nil then
		for name in baseline.medians do
			if medians[name] == nil and (config.only == nil or string.find(name, config.only, 1, true)) then
				table.insert(report.notes, `{name} is in the baseline but didn't run`)
			end
		end
	end

	task.wait()
	const calibrationAfter = calibrate()
	const drift = calibrationAfter / calibrationBefore - 1
	if math.abs(drift) > CALIBRATION_TOLERANCE then
		table.insert(
			report.notes,
			`calibration time changed by {formatChange(drift)} during the run, so results are unreliable; run again`
		)
	end

	folder:Destroy()
	root = nil

	const lines = { string.format("%-44s %10s %10s %8s", "case", "median", "p90", "change") }
	for _, result in report.results do
		table.insert(
			lines,
			string.format(
				"%-44s %7.2f us %7.2f us %8s  per %s",
				result.name,
				result.median,
				result.p90,
				formatChange(result.change),
				result.unit
			)
		)
	end
	for _, regression in report.regressions do
		table.insert(lines, `REGRESSION {regression}`)
	end
	for _, note in report.notes do
		table.insert(lines, `note: {note}`)
	end

	report.text = table.concat(lines, "\n")
	report.json = HttpService:JSONEncode({
		studio = version(),
		medians = medians,
		p90s = p90s,
		calibration = calibrationBefore,
	})
	print(`[tilly bench]\n{report.text}`)

	return report
end

return runBench
