# 👁️ Phase 3: AI Vision & Camera

**Goal:** Implement the "Killer Feature" - taking photos of BEOs, receipts, and paychecks to auto-fill data.

## 📋 Checklist

- [ ] **Camera Integration**
    - [ ] Configure Android/iOS permissions for Camera.
    - [ ] Create `lib/screens/camera_screen.dart`.
    - [ ] Implement "Take Picture" functionality.
    - [ ] Implement "Pick from Gallery" functionality.

- [ ] **AI "Tip Agent" Implementation**
    - [ ] Update `lib/agents/tip_agent.dart` with real Gemini Pro logic.
    - [ ] Create prompt templates for:
        - **Receipts:** "Extract total, date, and location."
        - **BEOs:** "Extract event name, guest count, total cost, and gratuity."
        - **Paychecks:** "Extract hours worked, hourly rate, and overtime."

- [ ] **Integration**
    - [ ] Connect Camera output to `TipAgent`.
    - [ ] Create a "Review Screen" where users verify AI data before saving.
    - [ ] Save the image path to the `Shift` object in the database.

- [ ] **Testing**
    - [ ] Test with sample BEO images.
    - [ ] Test with sample Receipt images.
    - [ ] Verify AI accuracy and error handling.
