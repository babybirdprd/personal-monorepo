# AGENTS.md

> **Context for AI Agents (Jules, Cursor, Copilot)**
> **Project:** Tauri v2 Multi-Platform Application (Linux, Windows, macOS, Android, iOS)
> **Host Environment:** Headless Linux VM (Jules/CI)
> **Plugin Dev:** See `AGENTS_PLUGINS.md` for plugin-specific instructions.

## 1. The "5-Platform Mindset" (Golden Rules)
Even though you are running in a **Linux** environment, you **MUST** write code that works on all 5 platforms.

1.  **Mobile First:** Assume touch interfaces exist. Avoid hover states for critical actions.
2.  **Plugin Over System:** Never import `std::fs` or `std::process` in Rust without considering mobile sandboxing. Use Tauri Plugins (`@tauri-apps/plugin-fs`) which handle permissions correctly across iOS/Android.
3.  **No Native Alerts:** Never use `window.alert()` or `window.confirm()`. They block the main thread and crash some mobile webviews. Use the Tauri Dialog plugin.
4.  **Async Everything:** The IPC bridge (Frontend <-> Rust) is async. Never block the UI thread.

## 2. Architecture & Data Flow
* **Frontend:** [Insert Framework] + TypeScript.
    * *Path:* `/src`
    * *Role:* UI/UX only. Logic that requires system access implies an IPC call.
* **Core:** Rust (Tauri v2).
    * *Path:* `/src-tauri`
    * *Role:* The "Brain". Handles database, file system, networking, and heavy computation.
* **Capabilities (User Permissions):**
    * *Concept:* Tauri v2 denies all actions by default.
    * *Requirement:* Any new plugin added (e.g., `fs`, `http`) **MUST** be enabled in `src-tauri/capabilities/default.json` (or mobile/desktop specific files) or it will silently fail.

## 3. Migration Notice (v1 -> v2)
**Strictly avoid Tauri v1 patterns.**
* ❌ **BAD (v1):** `import { invoke } from '@tauri-apps/api/tauri'`
* ✅ **GOOD (v2):** `import { invoke } from '@tauri-apps/api/core'`
* ❌ **BAD (v1):** `allowlist` in `tauri.conf.json`
* ✅ **GOOD (v2):** `src-tauri/capabilities/*.json`
* ❌ **BAD (v1):** `tauri::api::fs` (Rust)
* ✅ **GOOD (v2):** `tauri_plugin_fs` (Rust crate) + `setup` hook.

## 4. Development Workflow (Jules/Linux)
You are running in a headless Linux VM. You cannot build for iOS/macOS here.

| Platform | Build Status in Jules | Action Strategy |
| :--- | :--- | :--- |
| **Linux** | ✅ **Native** | Use `pnpm tauri build` to verify logic. |
| **Android** | ⚠️ **Partial** | Code must compile. Use `cargo check --target aarch64-linux-android`. |
| **Windows** | ❌ **Impossible** | Use `cargo check --target x86_64-pc-windows-msvc` only. |
| **macOS** | ❌ **Impossible** | Cross-compile via GitHub Actions only. |
| **iOS** | ❌ **Impossible** | Use `cargo check --target aarch64-apple-ios` only. |

**Command Restrictions:**
* **NEVER RUN:** `pnpm tauri dev` (Hangs the VM indefinitely).
* **NEVER RUN:** `pnpm tauri android dev` (Requires Emulator/GUI).
* **ALWAYS RUN:** `pnpm tauri build` (Debug build is fine) or `pnpm check`.

## 5. Coding Standards

### A. Rust (Backend)
* **Mobile Entry Point:** Ensure `src-tauri/src/lib.rs` is used as the shared entry point. `main.rs` is for Desktop only and should wrapper `lib.rs`.
* **Command Signatures:**
    ```rust
    // Commands must return Result for error handling in JS
    #[tauri::command]
    pub async fn my_command() -> Result<String, String> { ... }
    ```

### B. TypeScript (Frontend)
* **OS Detection:**
    ```typescript
    import { type } from '@tauri-apps/plugin-os';
    const osType = await type(); // 'linux', 'windows', 'macos', 'android', 'ios'
    ```
* **Safe Area (Mobile):** Ensure CSS handles "The Notch" on iOS.
    ```css
    padding-top: env(safe-area-inset-top);
    padding-bottom: env(safe-area-inset-bottom);
    ```

## 6. Project Structure Map
* `/src-tauri/tauri.conf.json`: **The Master Config.** (Bundle IDs, Windows, Version).
* `/src-tauri/capabilities/`: **Permissions.** Define what the frontend can do.
* `/src-tauri/gen/android/`: **Android Project.** (Do not edit manually unless necessary).
* `/src-tauri/gen/apple/`: **iOS/macOS Project.** (Do not edit manually).
