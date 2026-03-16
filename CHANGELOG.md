# Changelog

## [Unreleased] - 2026-03-15

### Documentation Improvements (from PR #6)

#### README
- **Enhanced clarity**: Added "What this repo is (and is not)" section with clear ✅/❌ lists
- **Better workflow**: Added explicit "Workflow model" and "Happy path" sections with concrete commands
- **Improved structure**: Reorganized content to be more operator-friendly
- **Enhanced principles**: Added comprehensive "Design principles" section
- **Better artifact description**: Improved "Output artifacts" and "Templates and skill" sections

#### ADR Template (`templates/ai-enablement-adr-template.md`)
- **Enhanced guidance**: More concrete section headers and descriptive guidance
- **Better maturity interpretation**: Improved "8-Layer Maturity Interpretation" with practical descriptions
- **Explicit constraints**: More detailed "Governance / Constraints" section with examples
- **Clearer success metrics**: Better guidance on defining practical metrics and experiments
- **Improved structure**: Better formatting and more actionable section descriptions

#### Synthesis Skill (`skills/compose-ai-enablement-adr.md`)
- **Explicit synthesis steps**: Added numbered synthesis phases with clear guidance
- **Enhanced anti-patterns**: More concrete examples of what to avoid
- **Better input specification**: Clearer list of required inputs and their purposes
- **Improved quality bar**: More specific quality criteria and expectations

#### New Templates
- **Added Kimi K2.5 template** (`templates/kimi-k2_5-adr-synthesis-template.md`): Kimi-optimized synthesis prompt with specific phrasing and guardrails
- **Enhanced strong-model templates**: Improved existing templates with better operator-friendly descriptions

### Preserved Enterprise Features
- **All safety hardening**: Repo boundary guard, argv-based execution, failure robustness maintained
- **Comprehensive collection**: Probes, generations, diagnostics, metadata capture unchanged
- **Testing infrastructure**: Smoke tests and fake agentrc shim preserved
- **Collection pipeline**: Core architecture and functionality maintained
- **Review prompt**: Adversarial approach kept intact

### Key Operator Improvements
- **Clearer value proposition**: Better explanation of what the tool does and doesn't do
- **Concrete workflows**: Step-by-step instructions with actual commands
- **Better artifact descriptions**: Clear explanation of what each output contains
- **Enhanced templates**: More actionable and specific guidance for ADR creation
- **Kimi optimization**: Specific template for Kimi K2.5 with appropriate phrasing

## Technical Details
- **No breaking changes**: All existing functionality preserved
- **Backward compatible**: Existing scripts and workflows continue to work
- **Enhanced templates**: Added new template options without removing existing ones
- **Improved documentation**: Better operator experience without changing core functionality
