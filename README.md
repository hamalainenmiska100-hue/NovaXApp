# NovaX App (Prototype)

**NovaX** is a prototype iOS application written in SwiftUI that demonstrates how a host app can leverage Google’s Gemini API to generate Swift code for mini‑applications.  The app adopts Apple’s new **Liquid Glass** design language introduced in iOS 26 so navigation and chrome layers use the `glassEffect` modifier.  Users can add up to five API keys, select the Gemini model they wish to call, provide a plain‑language description of the app they want, and let NovaX generate multiple source files.  Generated mini‑apps are stored locally and can be exported as a zipped project for further compilation outside the host app.  Each mini‑app may consist of several Swift source files.  You can open and read these files in the app or copy their contents to the clipboard for use elsewhere.  This prototype does not compile or run generated Swift code in‑app—mini‑apps are displayed as plain text.

## Features

* **Liquid Glass design** – Toolbars and controls use the new `glassEffect` view modifier introduced in iOS 26 to create translucent, dynamic chrome.  On earlier iOS releases the app falls back to the built‑in ultra‑thin material【951004573568146†L25-L63】.  The reusable `LiquidGlassModifier` encapsulates this behavior so you can apply it to any view.
* **Multiple API keys** – Store up to five Gemini API keys.  NovaX automatically falls back to the next key if a request fails due to authorization or rate limits.
* **Model selection** – Enter any supported model name.  Suggested defaults include `gemini‑3.1‑flash‑lite‑preview`, `gemini‑3‑flash‑preview` and `gemini‑3.1‑pro‑preview`.  Older models like the 2.0 Flash and Flash‑Lite families are retired after June 1 2026【15730787711370†L494-L499】.
* **Prompt‑driven generation** – Provide a description of the app you want; NovaX uses the Gemini API to ask for a JSON payload containing multiple files.  Each file has a name and Swift source code.  A system prompt instructs the model to include Liquid Glass APIs when asked.
* **Mini‑app management** – Generated apps are listed on the home screen.  Tap a row to open its detail view.  Long‑press a row to duplicate or delete an app or export it as a zip archive.  (Generating a WebClip configuration profile for Home Screen shortcuts is left as an exercise.)
* **Export** – Mini‑apps can be zipped via `ZIPFoundation` and shared.  The zip contains the generated Swift files ready for Xcode.

* **File viewer** – Within a mini‑app you can navigate through each generated file, read its contents in a monospaced font and copy code to the clipboard using the copy button.  This makes it easy to inspect what the model produced and reuse code in your own projects.

## Limitations

This is a proof‑of‑concept meant for private use and is **not intended for App Store distribution**.  Apple’s App Store Review Guidelines prohibit apps that download and execute arbitrary code (Guideline 2.5.2) and those that act as alternate home screen environments (Guideline 2.5.8).  Because NovaX only displays generated Swift code rather than executing it, it stays within safe bounds for personal testing.  If you plan to distribute this app publicly, consult Apple’s guidelines carefully.

## Requirements

* Xcode 15.3 or later
* iOS 26 SDK (to use `glassEffect`)
* Swift 5.9 or later
* Swift package dependency: [ZIPFoundation](https://github.com/weichsel/ZIPFoundation) for zipping mini‑apps

## Setup Instructions

1. **Clone or unzip this repository** and open `NovaXApp.xcodeproj` in Xcode.  If you prefer to create your own project, add all Swift files under the `NovaXApp` directory and set `NovaXAppApp` as the main entry point.
2. **Add ZIPFoundation**:  In Xcode, open **File › Add Packages…**, search for `github.com/weichsel/ZIPFoundation` and add the package.  The `MiniAppManager` uses it to create zip archives.
3. **Configure the URL scheme**:  NovaX defines the custom scheme `novax` for deep‑linking to mini‑apps.  In your project settings, add this URL type with identifier `com.example.NovaX` and URL scheme `novax`.
4. **Run on an iOS 26 device or simulator**.  On earlier versions, the glass effect falls back gracefully.
5. **Obtain Gemini API keys**:  Create up to five keys from [Google AI Studio](https://aistudio.google.com).  Note that Gemini 2.0 Flash and Flash‑Lite models will be retired on June 1 2026【15730787711370†L494-L499】.  Supported models include `gemini‑3.1‑flash‑lite‑preview`, `gemini‑3‑flash‑preview`, `gemini‑3.1‑pro‑preview`, `gemini‑2.5‑pro` and `gemini‑2.5‑flash`【15730787711370†L528-L579】.
6. **Configure App Transport Security (ATS)**:  Gemini API endpoints use HTTPS and require ATS exceptions if you plan to call unencrypted endpoints.  No ATS exceptions are necessary when calling `https://generativelanguage.googleapis.com`.

## How it works

1. **API key storage** – `APIKeyManager` holds an array of API keys and persists them using `UserDefaults` for simplicity.  You can replace the implementation with a proper Keychain wrapper.  During a request, `GeminiClient` tries each key in order until it receives a successful response.
2. **Model selection** – `AppConfig` stores the current model name.  The default is `gemini‑3.1‑flash‑lite‑preview`.  The config view allows the user to enter a different model.
3. **Prompt and generation** – In `NewMiniAppView` the user writes a prompt and selects whether to request a Liquid Glass app.  NovaX constructs a system prompt instructing Gemini to return a JSON object with an array of files.  It then calls the REST API using `URLSession`.  Example REST call format: a POST to `https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent` with a JSON body containing the prompt【641523176856277†L283-L433】.
4. **Parsing output** – `GeminiClient` decodes the response and attempts to parse the returned text as JSON.  Each entry in the `files` array becomes a `MiniFile` with a name and content.  The mini‑app is saved to the Documents directory.
5. **Liquid Glass** – The `LiquidGlassModifier` applies the `glassEffect` modifier (with the `.regular.interactive()` variant) on iOS 26 and falls back to a semi‑transparent ultra‑thin material on earlier OS versions【951004573568146†L25-L63】.  This modifier is used for toolbar backgrounds and cards throughout the app.
6. **Exporting** – `MiniAppManager` uses ZIPFoundation to archive a mini‑app’s folder into a `.zip` file stored in the temporary directory.  The exported file can be shared via the standard iOS share sheet.

## Prompt guidelines for Gemini

To get good results from the Gemini API, supply a clear description of your app and specify that the response should be JSON with a `files` array.  For example:

```text
You are NovaX AI.  Generate an iOS 26 SwiftUI mini‑app that displays a to‑do list.  Use Liquid Glass for the navigation bar and toolbar.  Return a JSON object with a `files` array.  Each item must include a `name` and `content` key.  The primary app entry point file should be named `TodoApp.swift`.
```

## License

This project is provided for educational purposes only and is not an official Apple or Google product.