# Advocate

**An Agentforce for Good submission for Dreamforce 2026.**

Advocate is a dual Agentforce system that transforms workplace accommodation requests — making them faster, more dignified, and fully auditable for both employees and HR.

---

## What It Does

**Ada** — the employee-facing agent — guides employees through the accommodation process at their own pace: exploring options, drafting a professional advocacy letter, submitting a Case, and checking on its status. Accessible via a WCAG 2.1 AA-compliant LWC chat interface embedded in any Lightning page.

**HRBrief** — the HR partner agent — gives managers and HR teams the context they need to act: plain-language case briefings, implementation guidance from company policy, and status tracking — without exposing unnecessary medical detail.

---

## Architecture

```
Employee → Ada (LWC) → Agentforce Agent
                        ├── intake (router)
                        ├── accommodation_options (Knowledge search)
                        ├── letter_generation (Apex: AccommodationLetterService)
                        ├── case_submission (Apex: AccommodationCaseService)
                        └── status_check (Apex: AccommodationStatusService)

HR → HRBrief → Agentforce Agent
                 ├── hr_router (router)
                 ├── accommodation_briefing (Apex: AccommodationStatusService)
                 ├── implementation_guidance (Knowledge search)
                 └── off_topic
```

Both agents are deployed as `aiAuthoringBundle` metadata — fully version-controlled, deployable via Salesforce CLI.

---

## Stack

| Layer | Technology |
|---|---|
| Agents | Agentforce `aiAuthoringBundle` / `.agent` DSL |
| Actions | Apex `@InvocableMethod` (3 classes) |
| Knowledge | Salesforce Knowledge + Data Cloud (RAG) |
| UI | Lightning Web Components (WCAG 2.1 AA) |
| Automation | Record-Triggered Flows (2) |
| Data model | Case (5 custom fields, 1 custom Record Type) |
| Deploy | Salesforce CLI `sf` v2 |

---

## WCAG 2.1 AA Compliance (Ada LWC)

The chat interface is built to WCAG 2.1 AA from the ground up:

| Criterion | Implementation |
|---|---|
| 2.4.1 Bypass Blocks | Skip navigation link to main conversation |
| 4.1.3 Status Messages | `aria-live="polite"` region announces all responses |
| 1.4.3 Contrast | High contrast toggle (black/yellow, ≥4.5:1) |
| 1.4.4 Resize Text | Font scaling 14px–22px via A−/A+ controls |
| 2.1.1 Keyboard | Full keyboard nav; Enter to send, Shift+Enter for newline |
| 2.3.3 Animation | `prefers-reduced-motion` disables typing indicator |
| 2.4.7 Focus Visible | 3px `:focus-visible` outlines on all interactive elements |

---

## Project Structure

```
force-app/main/default/
├── aiAuthoringBundles/
│   ├── Ada/                         # Employee accommodation agent
│   └── HRBrief/                     # HR partner briefing agent
├── classes/
│   ├── AccommodationCaseService.cls      # Create Accommodation Case
│   ├── AccommodationLetterService.cls    # Generate Advocacy Letter
│   └── AccommodationStatusService.cls   # Get Accommodation Case Status
├── flows/
│   ├── AccommodationRequest_HRNotification.flow-meta.xml
│   └── AccommodationRequest_StatusUpdate.flow-meta.xml
├── lwc/
│   └── adaAccommodationChat/            # WCAG 2.1 AA chat wrapper
└── objects/Case/
    ├── fields/                          # 5 custom fields
    └── recordTypes/Accommodation_Request.recordType-meta.xml
```

---

## Deployment

### Prerequisites

1. Salesforce org with Einstein and Agentforce Agents enabled
2. Salesforce CLI `sf` v2 installed
3. Data Cloud provisioned (required for Knowledge RAG)
4. Org authenticated: `sf org login web --alias advocate-org`

> On machines with corporate SSL inspection, prefix all `sf` commands with `NODE_TLS_REJECT_UNAUTHORIZED=0`.

### Deploy metadata

```bash
cd advocate-agent

# Deploy data model + Apex + Flows + LWC
NODE_TLS_REJECT_UNAUTHORIZED=0 sf project deploy start \
  --source-dir force-app/main/default \
  --ignore-conflicts \
  --target-org advocate-org

# Deploy agents
NODE_TLS_REJECT_UNAUTHORIZED=0 sf project deploy start \
  --source-dir force-app/main/default/aiAuthoringBundles \
  --target-org advocate-org
```

### Post-deploy wiring (required)

Before the agents are fully operational, complete these steps in Setup:

1. **Create Agentforce Actions** (Setup → Agentforce → Agent Actions → New):
   - `Create Accommodation Case` → `AccommodationCaseService`
   - `Generate Advocacy Letter` → `AccommodationLetterService`
   - `Get Accommodation Case Status` → `AccommodationStatusService`

2. **Wire Knowledge Data Library** (Ada agent → Builder → Data → Data Library):
   - Connect your Salesforce Knowledge articles to the Data Library
   - Save and retrieve the bundle to capture `rag_feature_config_id`

3. **Wire HRBrief actions in Builder**:
   - Open HRBrief → Accommodation Briefing subagent
   - Add `Get Accommodation Case Status` from Action Library → Save

4. **Activate both agents** (Builder → Commit Version → Activate)

5. **Add Ada to a Lightning page** (App Builder → drag `adaAccommodationChat` component)

---

## Key Technical Notes

### Agentforce Action source naming

The `source` field in the `.agent` DSL must reference a registered Agentforce Action developer name — not the raw Apex class name. The developer name is the `@InvocableMethod` label with spaces replaced by underscores:

| @InvocableMethod label | source value |
|---|---|
| `Create Accommodation Case` | `Create_Accommodation_Case` |
| `Generate Advocacy Letter` | `Generate_Advocacy_Letter` |
| `Get Accommodation Case Status` | `Get_Accommodation_Case_Status` |

The canonical way to discover actual source names: wire actions in Builder → retrieve the bundle → read the `.agent` file.

### bundle-meta.xml

Do NOT include a `<target>` element in `AiAuthoringBundle` bundle-meta.xml files. Including it causes a "no BotVersion found" deploy error.

---

## Demo Persona

**Jordan Reyes** — engineer, 3 months in, has ADHD and chronic migraine. Has been dreading the accommodation conversation. Opens Ada from their employee portal during a quiet moment. Gets help the same day.

---

## License

MIT
