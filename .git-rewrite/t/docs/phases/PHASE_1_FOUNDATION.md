# 🏗️ Phase 1: Foundation & Setup

**Goal:** Initialize the project, set up the folder structure, and install critical dependencies.

## 📋 Checklist

- [x] **Project Initialization**
    - [x] Create project folder `In The Biz AI`.
    - [x] Initialize Flutter project (Web, Android, iOS).
    - [x] Create `.gitignore`.

- [x] **Workflow Setup**
    - [x] Install `AI_WORKFLOW_TRANSFER_KIT.md`.
    - [x] Configure `.vscode/settings.json` (Auto-approval).
    - [x] Configure `.vscode/tasks.json`.
    - [x] Create `auto-commit.mjs` (The Saver).
    - [x] Create `test-vision.mjs` (The Eyes).

- [x] **Dependencies & Configuration**
    - [x] Update `pubspec.yaml` with dependencies:
        - `google_generative_ai`
        - `camera`
        - `table_calendar`
        - `provider`
        - `intl`
        - `shared_preferences`
    - [x] Create `analysis_options.yaml` for linting.
    - [ ] Run `flutter pub get` successfully.

- [x] **Core Architecture**
    - [x] Create `lib/agents/` (AI Logic).
    - [x] Create `lib/models/` (Data Structures).
    - [x] Create `lib/screens/` (UI Pages).
    - [x] Create `lib/widgets/` (Reusable Components).
    - [x] Create `lib/services/` (Backend/Data Services).

- [x] **Initial Code**
    - [x] Create `lib/main.dart` (Entry point).
    - [x] Create `lib/screens/dashboard_screen.dart` (Basic UI).
    - [x] Create `lib/models/shift.dart` (Data Model).
    - [x] Create `lib/agents/tip_agent.dart` (AI Skeleton).

## 📝 Notes
- `flutter pub get` must be run manually if the terminal hangs.
- The project is currently set up for local development.
