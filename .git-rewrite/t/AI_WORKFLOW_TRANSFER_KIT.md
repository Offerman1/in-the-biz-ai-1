# 🚀 AI WORKFLOW TRANSFER KIT
**Source Project:** SocialBull.ai
**Target Project:** In The Biz AI (Flutter)
**Date:** December 24, 2025

---

## 📖 HOW TO USE THIS FILE

This file contains the **entire DNA** of our high-velocity AI development workflow. It bundles our system instructions, automation scripts, testing tools, and editor configuration into one place.

**INSTRUCTIONS FOR THE USER:**
1.  **Copy this file** into the root of your new project folder (e.g., `In The Biz AI/AI_WORKFLOW_TRANSFER_KIT.md`).
2.  **Open the new project** in VS Code.
3.  **Open the Chat** (GitHub Copilot).
4.  **Paste the "ACTIVATION PROMPT"** below into the chat.

---

## 🤖 SECTION 1: THE ACTIVATION PROMPT

**PASTE THIS INTO THE CHAT TO START:**

> **System Upgrade Request: Install "SocialBull" Workflow**
>
> I have imported a master workflow file (`AI_WORKFLOW_TRANSFER_KIT.md`) from a successful project. I need you to extract the tools and configurations from this file to set up a self-correcting, high-velocity development environment for this **Flutter** project.
>
> **Your Mission:**
> 1.  **Extract & Create Files:** Read the sections below and create the corresponding files in this workspace:
>     - `.github/copilot-instructions.md` (The Brain)
>     - `auto-commit.mjs` (The Saver)
>     - `test-vision.mjs` (The Eyes)
>     - `.vscode/tasks.json` (The Controls)
>     - `.vscode/settings.json` (The Permissions)
>
> 2.  **Adapt for Flutter:**
>     - Modify `.vscode/tasks.json` to run `flutter run -d chrome --web-port=8080` instead of `npm run dev`.
>     - Ensure `test-vision.mjs` points to `http://localhost:8080`.
>     - Create a `package.json` if it doesn't exist, and install `puppeteer`, `puppeteer-extra`, `puppeteer-extra-plugin-stealth`, `dotenv`, and `@google/generative-ai` so the test script works.
>
> 3.  **Initialize:**
>     - Run the "Auto-Commit Watcher" task immediately.
>     - Tell me when you are ready to run the first "Vision Test".
>
> **Please proceed with extracting and creating the files now.**

---

## 🧠 SECTION 2: THE BRAIN (.github/copilot-instructions.md)

**File Path:** `.github/copilot-instructions.md`

```markdown
# In The Biz AI - Copilot Instructions

**Knowledge cutoff:** June 2024
**Current date:** December 24, 2025

**These instructions are automatically applied to every Copilot chat session.**

---

## 🤖 GOOGLE GEMINI AI MODELS

### Current Model Hierarchy:
| Model | Use Case |
|-------|----------|
| **Gemini 3 Pro** | Complex reasoning, image analysis, coding |
| **Gemini 3 Flash** | Fast chat, real-time interactions |
| **Gemini 2.5 Flash** | High-volume tasks, content generation |

---

## 🚨 FIRST THING - CHECK PREVIOUS CHAT FOR CONTEXT

**Before starting ANY new work, check the most recent chat session:**

```powershell
# Find the most recent chat file
$latest = Get-ChildItem ".specstory/history/*.md" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
Write-Host "Most recent chat: $($latest.Name)"
Get-Content $latest.FullName -Tail 1000
```

---

## 📚 REQUIRED READING - PROJECT DOCUMENTATION

1.  **`docs/MASTER_INDEX.md`** - The Project Bible (Create this if missing)
2.  **`AI_WORKFLOW_TRANSFER_KIT.md`** - The Source of Truth for this workflow

---

## 🛠️ RECOMMENDED EXTENSIONS & TOOLS

**VS Code Extensions (Add to .vscode/extensions.json):**
- `Dart-Code.flutter` (Flutter support)
- `Dart-Code.dart-code` (Dart language)
- `heybourn.headwind` (Tailwind-like class sorter if using styling libs)
- `supabase.vscode-supabase` (Database management)

**CLI Tools:**
- `supabase` (for backend management)
- `flutter` (obviously)

---

## 3. TESTING PROTOCOL - MANDATORY

**NEVER say "go test it" - YOU test it using Puppeteer!**

### 👁️ AI Vision Test (Enhanced)
**Run the AI Vision test for smarter testing:**
- Task: "Vision Test (AI Enhanced)" - runs `test-vision.mjs`

**Vision Test Features:**
- AI "sees" the UI and describes what it finds
- Auto-detects visual errors (red text, broken layouts)
- Can click elements by description ("the blue Submit button")
- Provides health status per page (GOOD/WARNING/CRITICAL)

**⚠️ CRITICAL: Update the test to match what you built!**
The test file `test-vision.mjs` must be **modified** to test the specific feature you just created.

---

## 4. GIT & DEPLOYMENT

**Auto-Commit is ENABLED:**
- `auto-commit.mjs` commits every 30 seconds automatically
- DO NOT manually run `git add` or `git commit`

---

## 6. TERMINAL MANAGEMENT - CRITICAL

**Use VS Code Tasks with dedicated panels:**
- **Dev Server** task → runs `flutter run -d chrome`
- **Puppeteer Test** task → runs `test-vision.mjs`

**Tasks run in separate terminals so they don't kill each other.**
```

---

## 💾 SECTION 3: THE SAVER (auto-commit.mjs)

**File Path:** `auto-commit.mjs`

```javascript
// Auto-commit watcher - runs alongside dev server
import { execSync } from 'child_process';

console.log('🔄 Auto-commit watcher started (every 30 seconds)');

setInterval(() => {
  try {
    execSync('git add -A', { stdio: 'pipe' });
    const status = execSync('git status --porcelain', { encoding: 'utf-8' });
    
    if (status.trim()) {
      // Use safe timestamp format without spaces or colons
      const timestamp = new Date().toISOString().slice(0, 19).replace('T', '_').replace(/:/g, '-');
      execSync(`git commit -m "auto-save ${timestamp}"`, { stdio: 'pipe' });
      console.log(`✅ [${timestamp}] Committed changes`);
    }
  } catch (e) {
    // Log errors so we can see what's wrong
    if (e.message && !e.message.includes('nothing to commit')) {
      console.error('❌ Auto-commit error:', e.message);
    }
  }
}, 30000);
```

---

## 👁️ SECTION 4: THE EYES (test-vision.mjs)

**File Path:** `test-vision.mjs`

```javascript
import puppeteer from 'puppeteer-extra';
import StealthPlugin from 'puppeteer-extra-plugin-stealth';
import { GoogleGenerativeAI } from '@google/generative-ai';
import dotenv from 'dotenv';
import fs from 'fs';

dotenv.config();
puppeteer.use(StealthPlugin());

// Initialize Gemini Vision
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const visionModel = genAI.getGenerativeModel({ model: "gemini-3-flash-preview" });

// CONFIGURATION
const BASE_URL = 'http://localhost:8082'; // Flutter Web Port

const errors = [];
const visionReports = [];

console.log('🧪 PUPPETEER + AI VISION TEST\n');
console.log('👁️ AI Vision: ENABLED (Gemini 3 Flash)\n');

// ============================================================
// AI VISION HELPER FUNCTIONS
// ============================================================

async function askVision(screenshotBuffer, question) {
  try {
    const base64Image = screenshotBuffer.toString('base64');
    const result = await visionModel.generateContent([
      question,
      { inlineData: { data: base64Image, mimeType: "image/png" } }
    ]);
    return result.response.text();
  } catch (error) {
    console.log(`❌ Vision Error: ${error.message}`);
    return `ERROR: ${error.message}`;
  }
}

async function visionCheck(page, question) {
  const screenshot = await page.screenshot();
  const prompt = `Look at this web application screenshot. ${question}
Answer in this exact format:
ANSWER: YES or NO
DETAILS: [Brief explanation of what you see]`;

  const response = await askVision(screenshot, prompt);
  const isYes = response.toUpperCase().includes('ANSWER: YES');
  
  visionReports.push({ question, answer: isYes ? 'YES' : 'NO', details: response });
  return { answer: isYes, details: response };
}

async function describeUI(page) {
  const screenshot = await page.screenshot();
  return await askVision(screenshot, `Describe this web application UI in 2-3 sentences.`);
}

async function checkForVisualErrors(page) {
  const screenshot = await page.screenshot();
  const prompt = `Analyze this screenshot for errors (red text, broken layouts).
Return JSON: { "hasErrors": true/false, "errors": [], "overallHealth": "GOOD/WARNING/CRITICAL" }`;

  const response = await askVision(screenshot, prompt);
  try {
    const jsonMatch = response.match(/\{[\s\S]*\}/);
    if (jsonMatch) return JSON.parse(jsonMatch[0]);
  } catch (e) {}
  return { hasErrors: false, errors: [], overallHealth: 'UNKNOWN' };
}

// ============================================================
// MAIN TEST EXECUTION
// ============================================================

(async () => {
  const browser = await puppeteer.launch({
    headless: false,
    defaultViewport: null,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--start-maximized']
  });

  const page = await browser.newPage();

  try {
    // ========== TEST START ==========
    console.log('📍 Step 1: Home Page');
    await page.goto(`${BASE_URL}`, { waitUntil: 'networkidle0' });
    
    // AI Vision Description
    const description = await describeUI(page);
    console.log(`👁️ AI sees: ${description}`);
    
    // AI Health Check
    const health = await checkForVisualErrors(page);
    console.log(`👁️ Page Health: ${health.overallHealth}`);
    if (health.hasErrors) console.log(`⚠️ Errors: ${health.errors.join(', ')}`);

    // ========== CUSTOM TEST LOGIC HERE ==========
    // Add your specific test steps here...

  } catch (e) {
    console.error('❌ TEST FAILED:', e);
  } finally {
    // await browser.close(); // Keep open for debugging if needed
    console.log('✅ Test Complete');
  }
})();
```

---

## 🎮 SECTION 5: THE CONTROLS (.vscode/tasks.json)

**File Path:** `.vscode/tasks.json`

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Auto-Commit Watcher",
      "type": "shell",
      "command": "node auto-commit.mjs",
      "isBackground": true,
      "problemMatcher": [],
      "runOptions": { "runOn": "folderOpen" },
      "presentation": { "reveal": "silent", "panel": "dedicated" }
    },
    {
      "label": "Dev Server (Flutter Web)",
      "type": "shell",
      "command": "flutter run -d chrome --web-port=8082",
      "isBackground": true,
      "problemMatcher": [],
      "presentation": { "reveal": "always", "panel": "dedicated" }
    },
    {
      "label": "Vision Test (AI Enhanced)",
      "type": "shell",
      "command": "node test-vision.mjs",
      "isBackground": false,
      "problemMatcher": [],
      "presentation": { "reveal": "always", "panel": "dedicated" }
    }
  ]
}
```

---

## 🛡️ SECTION 6: THE PERMISSIONS (.vscode/settings.json)

**File Path:** `.vscode/settings.json`

```json
{
  "files.autoSave": "afterDelay",
  "files.autoSaveDelay": 1000,
  "chat.agent.enabled": true,
  "github.copilot.chat.codeGeneration.useInstructionFiles": true,
  "chat.instructionsFilesLocations": {
    ".github/instructions": true,
    ".github": true
  },
  "chat.tools.terminal.enableAutoApprove": true,
  "chat.tools.terminal.autoApprove": {
    "npm": true,
    "node": true,
    "git": true,
    "flutter": true,
    "dart": true,
    "flutter pub get": true,
    "flutter run": true,
    "supabase": true,
    "cd": true,
    "ls": true,
    "Get-Content": true,
    "Get-ChildItem": true
  }
}
```
