-- ============================================================================
-- Garbuliya - Prompt Construction
-- ============================================================================

local M = {}

-- ============================================================================
-- Prompt Building
-- ============================================================================

--- Build the prompt for code implementation
-- @param filetype language/filetype of the code
-- @param code the original code to improve
-- @return formatted prompt string
function M.build_implementation_prompt(filetype, code)
	return table.concat({
		("Language: %s"):format(filetype ~= "" and filetype or "unknown"),
		[[
Task: Replace the code in the region below with a correct and optimal implementation.

Hard constraints:
- Preserve the existing function signature and surrounding structure.
- Output ONLY the final code. No markdown, no comments, no explanations.
- Do not introduce global state, logging, or side effects.
- Do not allocate unnecessary data structures.
- Prefer the best asymptotic time complexity known for this task.
- Among equally fast solutions, minimize auxiliary space and allocations.
- Prefer iterative solutions over recursion unless recursion is required for optimal asymptotics.
- Handle edge cases and invalid inputs correctly and minimally.
- Do NOT run any tools/commands. Output only code.

Quality gate (do not output):
- Sanity-check correctness on edge cases.
- Verify time and auxiliary space complexity.
]],
		"=== REGION START ===",
		code,
		"=== REGION END ===",
	}, "\n")
end

return M
