# Adversarial Installer Review Prompt

Review this installer change for failure modes before it ships.

Focus on:

- OS and shell detection gaps
- unsafe overwrite behavior
- dry-run paths that still mutate state
- missing verification commands
- package manager assumptions
- broken quoting or path handling
- unclear manual fallback steps

Return blockers first, then medium-risk issues, then suggested follow-ups.
