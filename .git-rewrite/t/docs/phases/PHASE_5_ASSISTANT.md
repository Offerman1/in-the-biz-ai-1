# 🎙️ Phase 5: Voice Assistant

**Goal:** Enable hands-free interaction using Gemini 3 Flash.

## 📋 Checklist

- [ ] **Voice Input**
    - [ ] Add `speech_to_text` dependency.
    - [ ] Implement microphone permissions.
    - [ ] Create a "Floating Mic Button" on the dashboard.

- [ ] **Conversational AI**
    - [ ] Update `TipAgent` to handle natural language queries.
    - [ ] Implement "Tools" for the AI (allow it to query the local database).
    - [ ] Example queries to support:
        - "How much did I make last week?"
        - "Add a shift for yesterday, I made $200."
        - "Show me the BEO from last Saturday."

- [ ] **Chat UI**
    - [ ] Create `lib/screens/chat_screen.dart`.
    - [ ] Implement a chat interface (User bubble vs. AI bubble).

- [ ] **Testing**
    - [ ] Test voice recognition accuracy.
    - [ ] Test AI database query accuracy.
