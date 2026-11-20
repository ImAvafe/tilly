--!strict
-- Runs Tilly through as many tag combinations as it can on Frames and reports what fails. It checks that:
-- - every tag the patterns and tokens allow resolves to values of the right type, without erroring
-- - every rule lands in the StyleSheet with a valid selector, and Frames pick up the styled values
-- - variants (`hover:`, `*:`, `!`, ...) build the right selectors and priorities
-- - every pair of tags that set components of the same property (`w-4 h-8`) gets a compound rule
-- - hand-written cases (importance, child combinators, transitions, cleanup, destroy) behave
--
-- Run it from Studio's command bar (edit mode or a play test client):
-- require(game.ReplicatedStorage.Avalog.Packages.avalog.src.vendor.tilly.test)()

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local tilly = require(script.Parent) :: any
local defaultTokens = require("./tokens")
local generateTags = require("./generateTags")
local mergeTokensets = require("./util/mergeTokensets")
local resolveTag = require("./resolveTag")
local sanitizeTag = require("./util/sanitizeTag")
local types = require("./types")
local withComponents = require("./util/withComponents")

export type Options = {
	tokens: { [string]: any }?, -- Merged over the default tokens, like `style/tag` does
	parent: Instance?, -- Where the test ScreenGui goes. Defaults to PlayerGui, or StarterGui in edit mode
	keep: boolean?, -- Keep the test ScreenGui for inspection
	maxPrinted: number?, -- How many failures to print
}

export type Report = {
	passed: number,
	failed: number,
	skipped: number,
	failures: { string },
	warnings: { string },
}

type Pending = {
	case: string,
	frame: Frame,
	check: () -> (),
}

const EPSILON = 1e-3
const FLUSH_TIMEOUT = 30 -- Seconds a batch of deferred checks gets to settle
-- Instances that properties without a pseudo-instance are looked up on
const PROBE_CLASSES = { "Frame", "TextLabel", "ImageLabel", "ScrollingFrame" }

const function show(value: any): string
	const kind = typeof(value)
	if kind == "Font" then
		return `Font({value.Family}, {value.Weight.Name}, {value.Style.Name})`
	elseif kind == "TweenInfo" then
		return `TweenInfo({value.Time}, {value.EasingStyle.Name}, {value.EasingDirection.Name}, delay {value.DelayTime})`
	elseif kind == "string" then
		return `"{value}"`
	end
	return `{kind}({tostring(value)})`
end

const function approxEqual(a: any, b: any): boolean
	const kind = typeof(a)
	if kind ~= typeof(b) then
		return false
	elseif kind == "number" then
		return a == b or math.abs(a - b) <= EPSILON
	elseif kind == "Color3" then
		return approxEqual(a.R, b.R) and approxEqual(a.G, b.G) and approxEqual(a.B, b.B)
	elseif kind == "UDim" then
		return approxEqual(a.Scale, b.Scale) and approxEqual(a.Offset, b.Offset)
	elseif kind == "UDim2" or kind == "Vector2" then
		return approxEqual(a.X, b.X) and approxEqual(a.Y, b.Y)
	elseif kind == "Font" then
		return a.Family == b.Family and a.Weight == b.Weight and a.Style == b.Style
	elseif kind == "TweenInfo" then
		return approxEqual(a.Time, b.Time)
			and a.EasingStyle == b.EasingStyle
			and a.EasingDirection == b.EasingDirection
			and a.RepeatCount == b.RepeatCount
			and a.Reverses == b.Reverses
			and approxEqual(a.DelayTime, b.DelayTime)
	end
	return a == b
end

const function readProperty(instance: Instance, property: string): (boolean, any)
	return pcall(function()
		return (instance :: any)[property]
	end)
end

const function readStyled(instance: Instance, property: string): (boolean, any)
	return pcall(function()
		return instance:GetStyled(property)
	end)
end

const function readRuleProperty(rule: StyleRule, property: string): any
	if property == "*" then
		return rule:GetPropertyTransitions()["*"]
	end
	return rule:GetProperty(property)
end

-- The selector Tilly should give a compound rule, built independently of `addCompositeRules`
const function compoundSelector(tags: { string }, selectorSuffix: string): string
	const sanitized = {}
	for _, tag in tags do
		table.insert(sanitized, sanitizeTag(tag))
	end
	table.sort(sanitized, function(a, b)
		return string.lower(a) < string.lower(b)
	end)
	return `.{table.concat(sanitized, ".")}{selectorSuffix}`
end

const function runTests(options: Options?): Report
	const config: Options = options or {}
	const tokens: { [string]: any } = (mergeTokensets :: any)({ defaultTokens, config.tokens or {} })
	const spacing = tokens["spacing"]

	const report: Report = {
		passed = 0,
		failed = 0,
		skipped = 0,
		failures = {},
		warnings = {},
	}

	const function pass()
		report.passed += 1
	end

	const function fail(case: string, message: string)
		report.failed += 1
		table.insert(report.failures, `[{case}] {message}`)
	end

	const function skip()
		report.skipped += 1
	end

	const function note(case: string, message: string)
		table.insert(report.warnings, `[{case}] {message}`)
	end

	const function expect(case: string, condition: boolean, message: string)
		if condition then
			pass()
		else
			fail(case, message)
		end
	end

	-- Setup

	const parent = config.parent
		or (Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui"))
		or StarterGui

	const root = Instance.new("ScreenGui")
	root.Name = "TillyTest"
	root.ResetOnSpawn = false

	const styleSheet = Instance.new("StyleSheet")
	styleSheet.Name = "TillyTestStyleSheet"
	styleSheet.Parent = root

	const styleLink = Instance.new("StyleLink")
	styleLink.StyleSheet = styleSheet
	styleLink.Parent = root

	root.Parent = parent

	const addTags, destroy = tilly(styleSheet, config.tokens)

	local pending: { Pending } = {}
	local frameCount = 0

	const function newFrame(case: string, frameParent: Instance?): Frame
		frameCount += 1
		const frame = Instance.new("Frame")
		frame.Name = `{frameCount} {case}`
		frame.Parent = frameParent or root
		return frame
	end

	const function tryAddTags(case: string, frame: Frame, tags: string): boolean
		const ok, err = pcall(addTags, frame, tags)
		if not ok then
			fail(case, `addTags("{tags}") errored: {err}`)
		end
		return ok
	end

	const function defer(case: string, frame: Frame, check: () -> ())
		table.insert(pending, {
			case = case,
			frame = frame,
			check = check,
		})
	end

	-- Styles resolve asynchronously, so checks that read styled values run in batches after a few frames
	-- Runs a check, and if it fails and `final` is false, undoes what it recorded so it can be retried later
	const function runCheck(item: Pending, final: boolean): boolean
		const passed, failed, skipped, failureCount = report.passed, report.failed, report.skipped, #report.failures
		const ok, err = pcall(item.check)
		if ok and report.failed == failed then
			return true
		end
		if final then
			if not ok then
				fail(item.case, `check errored: {err}`)
			end
			return false
		end
		report.passed, report.failed, report.skipped = passed, failed, skipped
		for index = #report.failures, failureCount + 1, -1 do
			report.failures[index] = nil
		end
		return false
	end

	-- Styles resolve asynchronously and slowly for big batches, so a check that fails is retried each frame until it
	-- passes or `FLUSH_TIMEOUT` runs out
	const function flush()
		task.wait()
		task.wait()
		const deadline = os.clock() + FLUSH_TIMEOUT
		local remaining = pending
		pending = {}
		while #remaining > 0 and os.clock() < deadline do
			const failing = {}
			for _, item in remaining do
				if not runCheck(item, false) then
					table.insert(failing, item)
				end
			end
			remaining = failing
			if #remaining > 0 then
				task.wait()
			end
		end
		for _, item in remaining do
			runCheck(item, true)
		end
	end

	local ruleIndex: { [string]: StyleRule } = {}
	const function indexRules()
		ruleIndex = {}
		for _, child in styleSheet:GetChildren() do
			if child:IsA("StyleRule") then
				ruleIndex[child.Name] = child
			end
		end
	end

	const function expectStyled(case: string, frame: Frame, property: string, expected: any)
		const ok, actual = readStyled(frame, property)
		if not ok then
			fail(case, `GetStyled("{property}") errored: {actual}`)
		else
			expect(case, approxEqual(actual, expected), `{property} is {show(actual)}, expected {show(expected)}`)
		end
	end

	const function expectRule(case: string, selector: string, property: string, expected: any)
		const rule = ruleIndex[selector]
		if rule == nil then
			fail(case, `no StyleRule for "{selector}"`)
			return
		end
		const ok, actual = pcall(readRuleProperty, rule, property)
		if not ok then
			fail(case, `reading {property} from "{selector}" errored: {actual}`)
		else
			expect(
				case,
				approxEqual(actual, expected),
				`"{selector}" sets {property} to {show(actual)}, expected {show(expected)}`
			)
		end
	end

	-- Property types

	const probes: { [string]: Instance | false } = {}
	const function getProbe(className: string): Instance?
		if probes[className] == nil then
			const ok, instance = pcall(function()
				return Instance.new(className :: any)
			end)
			probes[className] = if ok then instance else false
		end
		return probes[className] or nil
	end

	-- Checks that each value a rule sets has the type of the property it sets
	const function checkTypes(case: string, rule: types.Rule, pseudoInstance: string?)
		for property, value in rule.properties do
			if property == "*" then
				expect(case, typeof(value) == "TweenInfo", `transition is {show(value)}, expected a TweenInfo`)
				continue
			end

			local found = false
			local missingProbe = false
			for _, className in if pseudoInstance then { pseudoInstance } else PROBE_CLASSES do
				const probe = getProbe(className)
				if probe == nil then
					missingProbe = true
					continue
				end

				const ok, current = readProperty(probe, property)
				if not ok then
					continue
				end

				found = true
				local sameType = typeof(value) == typeof(current)
				if sameType and typeof(value) == "EnumItem" then
					sameType = value.EnumType == current.EnumType
				end
				expect(case, sameType, `{className}.{property} is a {typeof(current)}, but the tag sets {show(value)}`)
				break
			end

			if not found then
				if missingProbe then
					note(case, `can't create {pseudoInstance} to check {property}`)
					skip()
				else
					fail(case, `no {pseudoInstance or "GuiObject"} has a {property} property`)
				end
			end
		end
	end

	-- Tag generation

	const tagSet = generateTags(tokens)
	const generated = tagSet.generated
	const samples = tagSet.samples

	-- 1. Every tag on its own

	const resolved: { [string]: types.Rule } = {}

	for _, entry in generated do
		const case = entry.tag
		const rule = resolveTag(entry.tag, tokens)
		if rule == nil then
			fail(case, "didn't resolve")
			continue
		end
		resolved[entry.tag] = rule

		const pseudoInstance = entry.pattern.pseudoInstance
		checkTypes(case, rule, pseudoInstance)

		-- A tag that resolves through an earlier pattern of its prefix sets other properties than it was made for
		const ownProperties: { [string]: boolean } = {}
		for _, property in entry.pattern.properties do
			ownProperties[property] = true
		end
		for property in entry.pattern.manualProperties or {} do
			ownProperties[property] = true
		end
		for _, property in entry.pattern.subtokens or {} do
			ownProperties[property] = true
		end
		for property in rule.properties do
			if not ownProperties[property] then
				note(case, `made from the {entry.pattern.namespace} namespace, but resolved to {property}`)
				break
			end
		end

		const frame = newFrame(case)
		if not tryAddTags(case, frame, entry.tag) then
			continue
		end
		pass()

		defer(case, frame, function()
			if ruleIndex[rule.selector] == nil then
				fail(case, `no StyleRule for "{rule.selector}"`)
				return
			end
			pass()

			if pseudoInstance ~= nil then
				return
			end
			for property, value in rule.properties do
				if property ~= "*" and readProperty(frame, property) then
					expectStyled(case, frame, property, value)
				end
			end
		end)
	end

	indexRules()
	flush()

	-- 2. Variants and importance

	for _, sample in samples do
		const baseRule = resolved[sample.tag]
		if baseRule == nil then
			continue
		end

		const forms = { `{sample.tag}!` }
		for _, variant in tagSet.variants do
			table.insert(forms, `{variant}{sample.tag}`)
			table.insert(forms, `{variant}{sample.tag}!`)
		end

		for _, tag in forms do
			const case = tag
			const rule = resolveTag(tag, tokens)
			if rule == nil then
				fail(case, "didn't resolve")
				continue
			end

			const variantCount = #string.split(tag, ":") - 1
			const important = string.sub(tag, -1) == "!"
			const expectedPriority = (baseRule.priority or 0) + variantCount * 10 + (if important then 100 else 0)
			expect(case, rule.priority == expectedPriority, `priority is {rule.priority}, expected {expectedPriority}`)
			expect(
				case,
				string.sub(rule.selector, 1, #sanitizeTag(tag) + 1) == `.{sanitizeTag(tag)}`,
				`selector "{rule.selector}" doesn't start with ".{sanitizeTag(tag)}"`
			)

			const frame = newFrame(case)
			if tryAddTags(case, frame, tag) then
				pass()
				defer(case, frame, function()
					expect(case, ruleIndex[rule.selector] ~= nil, `no StyleRule for "{rule.selector}"`)
				end)
			end
		end
	end

	indexRules()
	flush()

	-- 3. Every pair of tags that set components of the same property

	const groups: { [string]: { string } } = {}
	for _, entry in generated do
		const rule = resolved[entry.tag]
		const component = rule and rule.component
		if component then
			const key = component.property .. component.selectorSuffix
			groups[key] = groups[key] or {}
			table.insert(groups[key], entry.tag)
		end
	end

	local pairIndex = 0
	for _, tags in groups do
		for i = 1, #tags do
			for j = i + 1, #tags do
				const a, b = tags[i], tags[j]
				const ruleA, ruleB = resolved[a], resolved[b]
				const componentA, componentB = assert(ruleA.component), assert(ruleB.component)
				const priorityA, priorityB = ruleA.priority or 0, ruleB.priority or 0
				const case = `{a} {b}`

				-- Two tags that set the same component with the same priority have no defined winner
				local ambiguous = false
				for name, value in componentA.components do
					const other = componentB.components[name]
					if other ~= nil and priorityA == priorityB and not approxEqual(value, other) then
						ambiguous = true
						break
					end
				end
				if ambiguous then
					skip()
					continue
				end

				-- The higher priority tag's components win
				const merged = {}
				const ordered = if priorityA <= priorityB
					then { componentA, componentB }
					else { componentB, componentA }
				for _, component in ordered do
					for name, value in component.components do
						merged[name] = value
					end
				end

				const property = componentA.property
				const expected = withComponents(ruleA.properties[property], merged)
				const selector = compoundSelector({ a, b }, componentA.selectorSuffix)
				const isPseudo = componentA.selectorSuffix ~= ""

				-- Alternate between one call and two calls in reverse order, which builds the compound rule later
				pairIndex += 1
				const frame = newFrame(case)
				local ok
				if pairIndex % 2 == 0 then
					ok = tryAddTags(case, frame, `{a} {b}`)
				else
					ok = tryAddTags(case, frame, b) and tryAddTags(case, frame, a)
				end
				if not ok then
					continue
				end

				defer(case, frame, function()
					expectRule(case, selector, property, expected)
					if ruleIndex[selector] and ruleIndex[selector].Priority ~= math.max(priorityA, priorityB) + 1 then
						fail(
							case,
							`"{selector}" has priority {ruleIndex[selector].Priority}, expected it above both tags`
						)
					end
					if not isPseudo and property ~= "*" and readProperty(frame, property) then
						expectStyled(case, frame, property, expected)
					end
				end)
			end
		end
	end

	indexRules()
	flush()

	-- 4. Hand-written cases with expected values worked out from the tokens

	const function size(x: number, y: number): UDim2
		return UDim2.fromOffset(x * spacing, y * spacing)
	end

	const sansFamily = tokens["font-sans"]
	const defaultTransition =
		TweenInfo.new(tokens["duration-default"], tokens["ease-default"], tokens["ease-default--direction"])

	type StyledCase = {
		calls: { string }, -- One addTags call each
		styled: { [string]: any }?, -- Values the Frame should end up with
		rules: { { selector: string, property: string, value: any } }?, -- Values the StyleSheet's rules should set
	}

	const STYLED_CASES: { StyledCase } = {
		{
			calls = { "bg-red-500" },
			styled = {
				BackgroundColor3 = tokens["color-red-500"],
				BackgroundTransparency = 0,
			},
		},
		{
			calls = { "w-4" },
			styled = { Size = size(4, 0) },
		},
		{
			calls = { "w-4 h-8" },
			styled = { Size = size(4, 8) },
		},
		{
			calls = { "h-8 w-4" },
			styled = { Size = size(4, 8) },
		},
		{
			calls = { "h-8", "w-4" },
			styled = { Size = size(4, 8) },
		},
		{
			calls = { "w-px h-0.5" },
			styled = { Size = UDim2.fromOffset(1, spacing * 0.5) },
		},
		{
			calls = { "w-sm h-96" },
			styled = { Size = UDim2.fromOffset(tokens["container-sm"], spacing * 96) },
		},
		{
			calls = { "size-10" },
			styled = { Size = size(10, 10) },
		},
		{
			calls = { "w-full h-8" },
			styled = { Size = UDim2.new(1, 0, 0, spacing * 8) },
		},
		{
			calls = { "w-full h-full" },
			styled = { Size = UDim2.fromScale(1, 1) },
		},
		{
			calls = { "size-full" },
			styled = { Size = UDim2.fromScale(1, 1) },
		},
		{
			calls = { "w-4", "bg-red-500", "h-8" },
			styled = { Size = size(4, 8) },
		},
		{
			calls = { "inset-x-2 inset-y-3" },
			styled = { Position = size(2, 3) },
		},
		{
			calls = { "left-1 top-2" },
			styled = { Position = size(1, 2) },
		},
		{
			calls = { "translate-x-1 translate-y-2" },
			styled = { Position = size(1, 2) },
		},
		{
			calls = { "w-4! h-8 w-16" },
			styled = { Size = size(4, 8) },
		},
		{
			calls = { "w-4 hover:h-8" },
			styled = { Size = size(4, 0) },
		},
		{
			calls = { "bg-red-500! bg-blue-500" },
			styled = { BackgroundColor3 = tokens["color-red-500"] },
		},
		{
			calls = { "bg-red-500 hover:bg-blue-500" },
			styled = { BackgroundColor3 = tokens["color-red-500"] },
		},
		{
			calls = { "opacity-50" },
			styled = { Transparency = 0.5 },
		},
		{
			calls = { "rotate-45" },
			styled = { Rotation = 45 },
		},
		{
			calls = { "z-10" },
			styled = { ZIndex = 10 },
		},
		{
			calls = { "order-first" },
			styled = { LayoutOrder = tokens["order-first"] },
		},
		{
			calls = { "hidden" },
			styled = { Visible = false },
		},
		{
			calls = { "overflow-hidden" },
			styled = { ClipsDescendants = true },
		},
		{
			calls = { "auto-none" },
			styled = { AutomaticSize = Enum.AutomaticSize.None },
		},
		{
			calls = { "pointer-events-none" },
			styled = { Interactable = false },
		},
		-- Extra whitespace between or around tags
		{
			calls = { "w-4  h-8" },
			styled = { Size = size(4, 8) },
		},
		{
			calls = { " w-4 " },
			styled = { Size = size(4, 0) },
		},
		{
			calls = { "" },
		},
		-- Invalid tags shouldn't error or create rules
		{
			calls = { "bg-not-a-color w-" },
		},
		{
			calls = { "-w-4 hover: nonexistent-4" },
		},
		-- Composite properties on pseudo-instances and transitions, checked on the rules
		{
			calls = { "font-bold" },
			rules = {
				{
					selector = ".font-bold",
					property = "FontFace",
					value = Font.new(sansFamily, tokens["font-weight-bold"]),
				},
			},
		},
		{
			calls = { "font-mono font-bold" },
			rules = {
				{
					selector = ".font-bold.font-mono",
					property = "FontFace",
					value = Font.new(tokens["font-mono"], tokens["font-weight-bold"]),
				},
			},
		},
		{
			calls = { "max-w-lg" },
			rules = {
				{
					selector = ".max-w-lg::UISizeConstraint",
					property = "MaxSize",
					value = Vector2.new(tokens["container-lg"], math.huge),
				},
			},
		},
		{
			calls = { "max-w-lg max-h-4" },
			rules = {
				{
					selector = ".max-h-4.max-w-lg::UISizeConstraint",
					property = "MaxSize",
					value = Vector2.new(tokens["container-lg"], spacing * 4),
				},
			},
		},
		{
			calls = { "min-w-4 min-h-8" },
			rules = {
				{
					selector = ".min-h-8.min-w-4::UISizeConstraint",
					property = "MinSize",
					value = Vector2.new(spacing * 4, spacing * 8),
				},
			},
		},
		{
			calls = { "hover:w-4 hover:h-8" },
			rules = {
				{
					selector = ".hover_h-8.hover_w-4:Hover",
					property = "Size",
					value = size(4, 8),
				},
			},
		},
		{
			calls = { "transition" },
			rules = {
				{
					selector = ".transition",
					property = "*",
					value = defaultTransition,
				},
			},
		},
		{
			calls = { "transition duration-300" },
			rules = {
				{
					selector = ".duration-300.transition",
					property = "*",
					value = TweenInfo.new(0.3, tokens["ease-default"], tokens["ease-default--direction"]),
				},
			},
		},
		{
			calls = { "transition ease-out" },
			rules = {
				{
					selector = ".ease-out.transition",
					property = "*",
					value = TweenInfo.new(
						tokens["duration-default"],
						tokens["ease-out"],
						tokens["ease-out--direction"]
					),
				},
			},
		},
		{
			calls = { "duration-300 ease-in delay-100" },
			rules = {
				{
					selector = ".delay-100.duration-300.ease-in",
					property = "*",
					value = TweenInfo.new(0.3, tokens["ease-in"], tokens["ease-in--direction"], 0, false, 0.1),
				},
			},
		},
		{
			calls = { "transition duration-none" },
			rules = {
				{
					selector = ".duration-none.transition",
					property = "*",
					value = TweenInfo.new(0, tokens["ease-default"], tokens["ease-default--direction"]),
				},
			},
		},
		-- Everything at once
		{
			calls = {
				"flex flex-row items-center content-center gap-2 p-4 bg-gray-800 rounded-lg border-2 border-gray-700 "
					.. "shadow-md w-64 h-12 max-w-lg min-h-8 opacity-50 transition duration-200 hover:bg-gray-700 "
					.. "active:bg-gray-900 *:text-white font-semibold text-sm",
			},
			styled = {
				Size = size(64, 12),
				BackgroundColor3 = tokens["color-gray-800"],
			},
		},
	}

	for _, styledCase in STYLED_CASES do
		const case = table.concat(styledCase.calls, " | ")
		const frame = newFrame(case)
		local ok = true
		for _, tags in styledCase.calls do
			ok = ok and tryAddTags(case, frame, tags)
		end
		if not ok then
			continue
		end
		pass()

		defer(case, frame, function()
			for property, expected in styledCase.styled or {} do
				expectStyled(case, frame, property, expected)
			end
			for _, ruleCase in styledCase.rules or {} do
				expectRule(case, ruleCase.selector, ruleCase.property, ruleCase.value)
			end
		end)
	end

	-- Child combinators: `*:` styles children, `**:` every descendant
	do
		const red = tokens["color-red-500"]

		const childParent = newFrame("*:bg-red-500")
		const child = newFrame("child", childParent)
		const grandchild = newFrame("grandchild", child)
		if tryAddTags("*:bg-red-500", childParent, "*:bg-red-500") then
			defer("*:bg-red-500", childParent, function()
				expectStyled("*:bg-red-500 parent", childParent, "BackgroundTransparency", 1)
				expectStyled("*:bg-red-500 child", child, "BackgroundColor3", red)
				expectStyled("*:bg-red-500 child", child, "BackgroundTransparency", 0)
				expectStyled("*:bg-red-500 grandchild", grandchild, "BackgroundTransparency", 1)
			end)
		end

		const descendantParent = newFrame("**:bg-red-500")
		const descendant = newFrame("grandchild", newFrame("child", descendantParent))
		if tryAddTags("**:bg-red-500", descendantParent, "**:bg-red-500") then
			defer("**:bg-red-500", descendantParent, function()
				expectStyled("**:bg-red-500 parent", descendantParent, "BackgroundTransparency", 1)
				expectStyled("**:bg-red-500 grandchild", descendant, "BackgroundColor3", red)
			end)
		end

		const sizeParent = newFrame("*:w-4 *:h-8")
		const sizeChild = newFrame("child", sizeParent)
		if tryAddTags("*:w-4 *:h-8", sizeParent, "*:w-4 *:h-8") then
			defer("*:w-4 *:h-8", sizeParent, function()
				expectStyled("*:w-4 *:h-8 child", sizeChild, "Size", size(4, 8))
			end)
		end
	end

	-- Removing tags, like `style/tag` does when reactive tags change
	do
		const case = "cleanup"
		const frame = newFrame(case)
		const ok, removeTags = pcall(addTags, frame, "w-4 h-8 bg-red-500")
		if not ok then
			fail(case, `addTags errored: {removeTags}`)
		else
			const removed, err = pcall(removeTags)
			expect(case, removed, `removing tags errored: {err}`)
			expect(case, #frame:GetTags() == 0, `tags left after removing: {table.concat(frame:GetTags(), " ")}`)
			if tryAddTags(case, frame, "w-8") then
				defer(case, frame, function()
					expectStyled(case, frame, "Size", size(8, 0))
					expectStyled(case, frame, "BackgroundTransparency", 1)
				end)
			end
		end
	end

	indexRules()
	flush()

	-- 5. The whole StyleSheet

	do
		const names: { [string]: boolean } = {}
		for _, rule in styleSheet:GetChildren() do
			if not rule:IsA("StyleRule") then
				continue
			end
			expect(rule.Name, rule.SelectorError == "", `invalid selector "{rule.Selector}": {rule.SelectorError}`)
			expect(rule.Name, not names[rule.Name], "duplicate StyleRule")
			names[rule.Name] = true
		end
	end

	-- `destroy` should remove every rule it made, on a StyleSheet of its own
	do
		const case = "destroy"
		const otherSheet = Instance.new("StyleSheet")
		const otherAddTags, otherDestroy = tilly(otherSheet, config.tokens)
		otherAddTags(Instance.new("Frame"), "w-4 h-8 bg-red-500 hover:bg-blue-500 font-bold font-mono")
		otherDestroy()
		const left = {}
		for _, child in otherSheet:GetChildren() do
			table.insert(left, child.Name)
		end
		expect(case, #left == 0, `{#left} rules left after destroy: {table.concat(left, ", ")}`)
		otherSheet:Destroy()
	end

	-- Teardown

	destroy()
	if config.keep then
		print(`[tilly test] kept {root:GetFullName()}`)
	else
		root:Destroy()
	end
	for _, probe in probes do
		if probe then
			probe:Destroy()
		end
	end

	const maxPrinted = config.maxPrinted or 50
	print(
		`[tilly test] {report.passed} passed, {report.failed} failed, {report.skipped} skipped, `
			.. `{#report.warnings} warnings ({#generated} tags, {frameCount} frames)`
	)
	for index, failure in report.failures do
		if index > maxPrinted then
			print(`[tilly test] ... {#report.failures - maxPrinted} more failures in the returned report`)
			break
		end
		warn(`[tilly test] FAIL {failure}`)
	end
	for index, warning in report.warnings do
		if index > maxPrinted then
			print(`[tilly test] ... {#report.warnings - maxPrinted} more warnings in the returned report`)
			break
		end
		print(`[tilly test] note {warning}`)
	end

	return report
end

return runTests
