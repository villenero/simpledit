```
                _____ ______   ________  ___      ___  ___  _______   ___       __
               |\   _ \  _   \|\   ___ \|\  \    /  /||\  \|\  ___ \ |\  \     |\  \
               \ \  \\\__\ \  \ \  \_|\ \ \  \  /  / /\ \  \ \   __/|\ \  \    \ \  \
                \ \  \\|__| \  \ \  \ \\ \ \  \/  / /  \ \  \ \  \_|/_\ \  \  __\ \  \
                 \ \  \    \ \  \ \  \_\\ \ \    / /    \ \  \ \  \_|\ \ \  \|\__\_\  \
                  \ \__\    \ \__\ \_______\ \__/ /      \ \__\ \_______\ \____________\
                   \|__|     \|__|\|_______|\|__|/        \|__|\|_______|\|____________|
```

<p align="center"><strong>The markdown viewer macOS deserves.</strong> Native. Instant. Beautiful.</p>

No Electron. No Chrome hidden inside. No 400 MB of RAM to read a text file.
MDView is a **pure AppKit** markdown viewer that launches in milliseconds and renders your docs with pixel-perfect typography.

---

## Why MDView?

| | MDView | VS Code | Typora | MacDown |
|---|---|---|---|---|
| Startup time | **~50ms** | ~3s | ~1.5s | ~800ms |
| Memory usage | **~18 MB** | ~350 MB | ~180 MB | ~90 MB |
| Dependencies | **Zero** | Electron + Node | Electron | WebKit bridge |
| Native macOS | **Yes** | No | No | Partial |
| Universal Binary | **Yes** | Yes | No | No |

---

## Features

### Instant Markdown Preview

Open any `.md`, `.markdown`, `.mkd`, or `.txt` file and get a beautifully rendered preview. Tables, code blocks, checklists, blockquotes --- everything rendered natively with WebKit.

```
# Your Document

- [x] Tables with alignment
- [x] Fenced code blocks with language hints
- [x] Task lists and checkboxes
- [x] Blockquotes and horizontal rules
- [x] Bold, italic, strikethrough
- [x] Links and images
- [ ] Your next great idea
```

### 6 Built-in Themes

Switch instantly with `Cmd+1` through `Cmd+6`:

```
Theme             Shortcut    Vibe
─────────────────────────────────────────
Light             Cmd+1       Clean & minimal
Dark              Cmd+2       Easy on the eyes
Vintage Terminal  Cmd+3       Green phosphor CRT
Elegant           Cmd+4       Georgia serif, cream paper
Nord              Cmd+5       Arctic, cool blues
Solarized         Cmd+6       Ethan Schoonover's classic
```

### Table Rendering

MDView renders markdown tables with proper alignment, alternating row colors, and clean borders:

```markdown
| Language | Typing     | Speed      | Ecosystem |
|----------|------------|------------|-----------|
| Swift    | Static     | Very Fast  | Apple     |
| Python   | Dynamic    | Moderate   | Huge      |
| Rust     | Static     | Very Fast  | Growing   |
| Go       | Static     | Fast       | Cloud     |
```

Renders as:

```
┌──────────┬────────────┬────────────┬───────────┐
│ Language │ Typing     │ Speed      │ Ecosystem │
├──────────┼────────────┼────────────┼───────────┤
│ Swift    │ Static     │ Very Fast  │ Apple     │
│ Python   │ Dynamic    │ Moderate   │ Huge      │
│ Rust     │ Static     │ Very Fast  │ Growing   │
│ Go       │ Static     │ Fast       │ Cloud     │
└──────────┴────────────┴────────────┴───────────┘
```

### Code Blocks with Syntax Hints

Fenced code blocks with language tags, styled per theme:

````markdown
```swift
let parser = MarkdownParser()
let html = parser.parse(markdown: content)
preview.loadHTML(html, theme: .nord)
```

```python
for doc in documents:
    print(f"{doc.title}: {doc.word_count} words")
```
````

### Outline Sidebar

Toggle with `Cmd+B`. MDView extracts all headings from your document and builds a navigable outline:

```
┌─────────────────┬──────────────────────────────────┐
│ OUTLINE         │                                  │
│                 │  # Project Roadmap               │
│ Project Roadmap │                                  │
│  Overview       │  ## Overview                     │
│  Architecture   │  Lorem ipsum dolor sit amet...   │
│   Frontend      │                                  │
│   Backend       │  ## Architecture                 │
│   Database      │                                  │
│  Deployment     │  ### Frontend                    │
│  FAQ            │  React + TypeScript stack with   │
│                 │  server-side rendering...        │
│                 │                                  │
└─────────────────┴──────────────────────────────────┘
```

Click any heading to jump directly to that section. The sidebar is resizable (drag the edge) and code-block-aware --- it won't pick up `#` inside fenced blocks.

### Multi-Document Tabs

Open multiple files in a single window. Each document gets its own tab with a close button:

```
┌─────────────────┬──────────────┬──────────────┬─────────────────────┐
│ ☰ │ README.md ✕ │ CHANGELOG ✕  │ API.md ✕     │  🔍 search  3/7  │
├─────────────────┴──────────────┴──────────────┴─────────────────────┤
│                                                                     │
│  # API Reference                                                    │
│                                                                     │
│  ## Authentication                                                  │
│  All requests require a Bearer token...                             │
│                                                                     │
├─────────────────────────────────────────────────────────────────────┤
│ ◆ Elegant     │ Markdown │ 142 lines │ 1,208 words │ UTF-8          │
└─────────────────────────────────────────────────────────────────────┘
```

### Search with Live Counter

`Cmd+F` opens an inline search field. Matches are highlighted in real time with a counter showing your position:

```
🔍 "authentication"                                    3/7
```

### Smart Encoding Detection

MDView auto-detects file encoding with BOM checking:

```
UTF-8 · UTF-16 LE/BE · ASCII · ISO Latin-1/2
Windows-1252 · EUC-JP · Shift JIS · Mac Roman
```

The current encoding is always visible in the status bar.

### Status Bar

Everything you need at a glance:

```
◆ Nord │ Markdown │ 847 lines │ 6,203 words │ 38,491 chars │ UTF-8
```

### Preferences

`Cmd+,` opens the preferences panel:

- **Font size**: 9pt to 24pt slider
- **Tab size**: 2, 4, or 8 spaces
- **Word wrap**: On/Off toggle

---

## Keyboard Shortcuts

| Action | Shortcut |
|---|---|
| Open file | `Cmd+O` |
| Close tab | `Cmd+W` |
| Find | `Cmd+F` |
| Toggle outline | `Cmd+B` |
| Preferences | `Cmd+,` |
| Print | `Cmd+P` |
| Light theme | `Cmd+1` |
| Dark theme | `Cmd+2` |
| Vintage Terminal | `Cmd+3` |
| Elegant | `Cmd+4` |
| Nord | `Cmd+5` |
| Solarized | `Cmd+6` |
| Quit | `Cmd+Q` |

---

## Install

### From source

```bash
git clone https://github.com/your-user/MDView.git
cd MDView
make app
cp -R dist/MDView.app /Applications/
```

### CLI usage

```bash
# Open a single file
mdview README.md

# Open multiple files in tabs
mdview README.md CHANGELOG.md docs/API.md
```

---

## Requirements

- macOS 13 (Ventura) or later
- Apple Silicon or Intel (Universal Binary)

## Tech Stack

- **Language**: Swift 5.9+
- **UI Framework**: AppKit (native)
- **Rendering**: WebKit (WKWebView)
- **Dependencies**: None
- **Build System**: Swift Package Manager

---

## License

MIT

---

*Built with Swift and AppKit. No Electron. No compromises.*
