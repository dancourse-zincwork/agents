# Interactive Element Spec: [Name]

> **Type**: [Chat Agent / Branching Scenario / Simulation / Quiz Game]
> **Module**: [Where this fits in the course]
> **Host**: Railway (or specify other)

---

## Purpose

**What learners will practice**: [Specific skill]

**Why interactive**: [Why this needs to be more than a video or text]

**Success looks like**: [What a learner who "wins" demonstrates]

---

## User Flow

```
1. Learner clicks "Start [Activity Name]"
    │
    ▼
2. [Intro screen / context setting]
    │
    ▼
3. [Main interaction - describe the loop]
    │
    ▼
4. [Feedback / outcome]
    │
    ▼
5. [Return to Notion with completion status]
```

---

## For Chat Agents

### Persona

**Name**: [Character name]
**Role**: [Their job/relationship to learner]
**Personality**: [Key traits - 3-5 words]
**Situation**: [What's happening when the conversation starts]

### Persona Prompt

```
You are [Name], a [Role] at [Company]. You are [personality traits].

Current situation: [What's happening]

Your goals in this conversation:
- [Goal 1 - what you want from the learner]
- [Goal 2]

Your constraints:
- [Constraint 1 - e.g., you're busy, you're skeptical]
- [Constraint 2]

Respond naturally as this character. Don't break character. If the learner does something that would work on this persona, acknowledge it. If they do something that wouldn't work, respond as the persona realistically would.
```

### Success Criteria

The learner "succeeds" when:
- [ ] [Behaviour 1 - e.g., "Uses the RTCF framework in their message"]
- [ ] [Behaviour 2 - e.g., "Acknowledges the persona's concern before pitching"]
- [ ] [Behaviour 3 - e.g., "Asks a clarifying question"]

### Feedback

**On success**: "[Positive feedback message that reinforces what they did well]"

**On partial success**: "[Encouraging message with specific improvement suggestion]"

**On failure**: "[Non-judgmental message explaining what to try differently]"

---

## For Branching Scenarios

### Opening Scenario

[Set the scene - 2-3 paragraphs describing the situation]

### Decision Points

**Decision 1**: [What choice the learner faces]

| Choice | Leads To | Why |
|--------|----------|-----|
| A: [Option] | [Outcome/next decision] | [Learning point] |
| B: [Option] | [Outcome/next decision] | [Learning point] |
| C: [Option] | [Outcome/next decision] | [Learning point] |

**Decision 2**: [If branched here]

| Choice | Leads To | Why |
|--------|----------|-----|
| A: [Option] | [Outcome] | [Learning point] |
| B: [Option] | [Outcome] | [Learning point] |

### Endings

**Best outcome**: [What happens if they make optimal choices]
**Good outcome**: [Acceptable but not ideal]
**Poor outcome**: [What happens if they make common mistakes]

### Debrief

After any ending, show:
- What path they took
- What the "best" path would have been
- Key learning point

---

## For Simulations

### What They're Simulating

**Real tool**: [What real tool/process this mimics]
**Simplified how**: [What's removed to focus on learning]

### Interface Elements

| Element | Purpose | Behaviour |
|---------|---------|-----------|
| [Element 1] | [What it's for] | [What happens when used] |
| [Element 2] | [What it's for] | [What happens when used] |
| [Element 3] | [What it's for] | [What happens when used] |

### Task Flow

1. [Step 1 - what they need to do]
2. [Step 2]
3. [Step 3]
4. [Completion state]

### Feedback Mechanisms

- **Immediate**: [What feedback they get in the moment]
- **On completion**: [Summary of how they did]
- **Hints**: [How hints work if they're stuck]

---

## Technical Notes

**Framework**: [React / vanilla JS / etc.]
**State management**: [How progress is tracked]
**Integration with Notion**: [How completion status returns]
**Data to capture**: [What we want to know about usage]

---

## Sample Content

[Include any sample scenarios, dialogue, or content needed to build this]

### Sample Dialogue (for chat agents)

**Learner**: [Example opening message]
**Persona**: [Example response]
**Learner**: [Example follow-up]
**Persona**: [Example response]

### Sample Scenarios (for branching)

**Scenario 1**: [Brief description]
**Scenario 2**: [Brief description]

---

## Acceptance Criteria

Before this goes live:
- [ ] Works on mobile
- [ ] Clear instructions at the start
- [ ] Feedback is specific and helpful
- [ ] Can retry without losing progress context
- [ ] Completion syncs back to course progress (if possible)
- [ ] Tested with 2+ real users

---

*Spec version: 1.0*
*Last updated: [Date]*
