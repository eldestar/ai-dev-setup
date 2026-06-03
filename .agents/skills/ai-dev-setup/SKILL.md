```markdown
# ai-dev-setup Development Patterns

> Auto-generated skill from repository analysis

## Overview
This skill teaches you the core development patterns and workflows used in the `ai-dev-setup` TypeScript repository. You'll learn about file naming, import/export styles, commit conventions, and how to synchronize the skill registry with documentation. This guide is ideal for contributors looking to maintain consistency and follow best practices in this codebase.

## Coding Conventions

### File Naming
- Use **snake_case** for all file names.
  - **Example:**  
    ```
    my_module.ts
    skill_utils.test.ts
    ```

### Import Style
- Use **relative imports** for referencing local files.
  - **Example:**
    ```typescript
    import { getSkill } from './skill_utils';
    ```

### Export Style
- Use **named exports** for all modules.
  - **Example:**
    ```typescript
    // skill_utils.ts
    export function getSkill(id: string) { ... }
    export const SKILL_TIERS = ['basic', 'advanced'];
    ```

### Commit Message Convention
- Use **Conventional Commits** with these prefixes: `feat`, `docs`, `fix`, `test`.
- Keep commit messages concise (average ~67 characters).
  - **Example:**
    ```
    feat: add skill tier validation to registry update
    docs: update VERIFIED_SKILLS_LIBRARY with new bundle
    ```

## Workflows

### update-skills-lock-and-verified-skills-doc
**Trigger:** When adding a new skill or updating skill metadata in the registry.  
**Command:** `/update-skill-registry`

1. Edit `skills-lock.json` to add or update skill entries.
   - **Example:**
     ```json
     {
       "skills": [
         {
           "id": "typescript_basics",
           "tier": "basic",
           "bundle": "core"
         }
       ]
     }
     ```
2. Update `docs/VERIFIED_SKILLS_LIBRARY.md` to reflect the changes in skills, tiers, or bundles.
   - Add new skills, update tiers, or modify bundle information as needed.
3. Commit your changes using a conventional commit message.
   - **Example:**
     ```
     feat: add typescript_basics skill to registry and docs
     ```
4. Open a pull request for review.

**Files involved:**
- `skills-lock.json`
- `docs/VERIFIED_SKILLS_LIBRARY.md`

**Frequency:** ~2x/month

## Testing Patterns

- Test files use the pattern `*.test.*` (e.g., `skill_utils.test.ts`).
- The specific testing framework is not specified, but tests are colocated with code or in the same directory.
- Follow the same coding conventions in test files.
  - **Example:**
    ```typescript
    import { getSkill } from './skill_utils';

    test('getSkill returns correct skill', () => {
      expect(getSkill('typescript_basics')).toBeDefined();
    });
    ```

## Commands

| Command                 | Purpose                                                      |
|-------------------------|--------------------------------------------------------------|
| /update-skill-registry  | Synchronize skills-lock.json with VERIFIED_SKILLS_LIBRARY.md |
```
