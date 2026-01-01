# 💾 Phase 2: Core Data & Input

**Goal:** Enable the user to manually enter shift data and store it persistently on the device.

## 📋 Checklist

- [ ] **Local Database Setup**
    - [ ] Choose database (Isar or Hive recommended for Flutter).
    - [ ] Add database dependencies to `pubspec.yaml`.
    - [ ] Create `lib/services/database_service.dart`.
    - [ ] Implement CRUD operations (Create, Read, Update, Delete) for `Shift` objects.

- [ ] **Manual Entry UI**
    - [ ] Create `lib/screens/add_shift_screen.dart`.
    - [ ] Build form fields for:
        - Date & Time (Start/End).
        - Hourly Rate.
        - Cash Tips.
        - Credit Tips.
        - Notes.
        - **Photo Attachments** (Multiple images per shift).
        - **Event Metadata** (Party name, hostess, guest count - optional).
    - [ ] Implement validation (ensure numbers are positive).
    - [ ] Image picker (Camera + Gallery).

- [ ] **State Management**
    - [ ] Set up `Provider` or `Riverpod` to manage app state.
    - [ ] Connect `DashboardScreen` to the database (Real-time updates).
    - [ ] Display real data on the Dashboard Summary Card.

- [ ] **Testing**
    - [ ] Verify data persists after closing the app.
    - [ ] Verify "Total Income" calculations are correct.
