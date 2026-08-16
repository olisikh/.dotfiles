import assert from "node:assert/strict";
import test from "node:test";
import { borderModeFor, paintBorder } from "./mode-border.ts";
import { isModeChangedEvent, subscribeToModeChanges } from "./mode-events.ts";

const snapshot = (mode, active) => ({
	version: 1,
	source: `test-${mode}`,
	mode,
	state: active ? "active" : "off",
	active,
});

test("goal takes priority over plan while both modes are active", () => {
	const modes = new Map([
		["plan", snapshot("plan", true)],
		["goal", snapshot("goal", true)],
	]);

	assert.equal(borderModeFor(modes), "goal");
});

test("inactive modes fall back to plan and then build", () => {
	const modes = new Map([["plan", snapshot("plan", true)]]);
	assert.equal(borderModeFor(modes), "plan");

	modes.set("plan", snapshot("plan", false));
	assert.equal(borderModeFor(modes), "build");
});

test("gold border painting uses the configured goal color", () => {
	assert.equal(
		paintBorder("goal", "border"),
		"\u001b[38;2;249;226;175mborder\u001b[39m",
	);
});

test("validated mode events update a fake consumer and request a render", () => {
	const handlers = [];
	const modes = new Map();
	let renders = 0;
	subscribeToModeChanges(
		{
			events: {
				on: (_channel, handler) => (handlers.push(handler), () => undefined),
			},
		},
		(event) => {
			modes.set(event.mode, event);
			renders += 1;
		},
	);

	const goal = snapshot("goal", true);
	handlers[0](goal);
	handlers[0]({ mode: "goal", active: true });

	assert.equal(isModeChangedEvent(goal), true);
	assert.equal(isModeChangedEvent({ mode: "goal", active: true }), false);
	assert.equal(renders, 1);
	assert.equal(borderModeFor(modes), "goal");
});
