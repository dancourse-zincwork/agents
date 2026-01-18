# Async Course Templates

Templates for the `async-course-designer` agent. Use these when creating self-paced professional learning courses for Notion delivery.

## Templates Included

| Template | Purpose | Use When |
|----------|---------|----------|
| `course-brief.md` | Define course scope and objectives | Starting a new course |
| `lesson-template.md` | Structure individual lessons | Creating lesson content |
| `module-quiz-template.md` | Create module assessments | Building quizzes |
| `job-aid-template.md` | Quick reference materials | Creating job aids |
| `support-agent-prompt.md` | AI helper for learners | Setting up course support |
| `interactive-spec-template.md` | Spec Railway-hosted interactives | Building chat agents, scenarios |
| `welcome-page.md` | Course landing page | Starting course dist/ folder |
| `completion-page.md` | Course completion celebration | Finishing course dist/ folder |
| `VERSION-template.md` | Track course changes | Managing versions |

## Folder Structure

When creating a new course, initialise with this structure:

```
course-name/
├── src/                          # All research & design material
│   ├── research/
│   │   ├── topic-research.md
│   │   └── sources.md
│   ├── design/
│   │   ├── course-brief.md       ← Start here
│   │   ├── module-outlines.md
│   │   └── support-agent-prompt.md
│   ├── content/
│   │   ├── video-scripts/
│   │   ├── quiz-questions/
│   │   └── practice-scenarios/
│   └── assets/
│       └── diagrams/
│
├── dist/                         # Final polished output
│   ├── notion/
│   │   ├── 00-welcome.md         ← Use welcome-page.md
│   │   ├── 01-module-name/
│   │   │   ├── lesson-01.md      ← Use lesson-template.md
│   │   │   └── quiz.md           ← Use module-quiz-template.md
│   │   ├── resources/
│   │   │   └── job-aids/         ← Use job-aid-template.md
│   │   └── completion.md         ← Use completion-page.md
│   ├── videos/
│   └── interactives/             ← Use interactive-spec-template.md
│
├── VERSION.md                    ← Use VERSION-template.md
└── README.md
```

## Quick Start

1. **Create folder**: `mkdir -p course-name/{src/{research,design,content/{video-scripts,quiz-questions,practice-scenarios},assets/diagrams},dist/{notion/{resources/job-aids},videos,interactives}}`

2. **Start with brief**: Copy `course-brief.md` to `src/design/`

3. **Fill in brief**: Define objectives, audience, modules

4. **Build content**: Use templates for each content type

5. **Compile to dist**: Final content goes in `dist/notion/`

## Template Usage Notes

### course-brief.md
- Fill this out FIRST before any content creation
- Get Dan's approval before proceeding
- Update as scope changes

### lesson-template.md
- One file per lesson
- Videos should be 3-5 minutes max
- Include knowledge checks every 2-3 minutes of content
- Always end with application task

### module-quiz-template.md
- 5-7 questions per module
- Mix recall and application questions
- Include detailed explanations for all answers
- Link back to relevant lessons

### job-aid-template.md
- One page maximum
- For use DURING work, not for learning
- Checklists and decision trees work well
- Make it printable

### support-agent-prompt.md
- Customise for each course
- Add all course content to the "What You Know" section
- Test before deploying

### interactive-spec-template.md
- Use for anything beyond Notion's capabilities
- Be specific about success criteria
- Include sample content

## Related Agents

- `learning-designer.md` - For live session design principles
- `video-script-writer.md` - For converting content to video scripts
- `async-course-designer.md` - The main agent that uses these templates
