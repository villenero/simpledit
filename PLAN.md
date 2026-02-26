# MDView — Plan de desarrollo

> Notepad ultraligero y nativo para macOS. Prioridad: velocidad de carga y agilidad en desktop.

---

1. Decisión tecnológica

### Comparativa resumida

| Métrica | AppKit (NSTextView) | SwiftUI | Tauri + Web | Electron |
|---|---|---|---|---|
| Arranque en frío (Apple Silicon) | **50–150 ms** | 80–200 ms | 200–500 ms | 1500–4000 ms |
| RAM en reposo | **10–30 MB** | 20–50 MB | 30–80 MB | 130–300 MB |
| Tamaño del binario | **2–8 MB** | 2–8 MB | 3–10 MB | 80–250 MB |
| Controles nativos Mac | Total | Muy alto | Web renderizado | Web renderizado |
| Corrector / Dictado / Writing Tools | Nativo | Nativo | Parcial | No |
| Auto-guardado / Versiones | NSDocument | FileDocument | Manual | Manual |
| iCloud | Integrado | Integrado | Manual | Manual |

### Elección: **Swift + AppKit (NSTextView)**

Razones clave:

1. **Arranque instantáneo** — NSTextView y todas sus dependencias viven en el *dyld shared cache* de macOS. No hay carga de frameworks desde disco.
2. **Memoria mínima** — El stack de texto (TextKit, Core Text, CoreGraphics) es código compartido del sistema. Solo paga la memoria de tu app.
3. **Integración nativa gratis** — Corrector ortográfico, autocorrección, dictado, Writing Tools (Apple Intelligence), drag-and-drop, servicios del sistema, accesibilidad VoiceOver, auto-guardado, versiones (Time Machine de documentos), iCloud.
4. **Binario diminuto** — Swift runtime viene embebido en macOS desde Monterey. El .app pesa 2-8 MB.

---

## 2. Arquitectura

```
MDView.app
├── MDViewApp.swift          # Entry point (@main, NSApplicationMain)
├── AppDelegate.swift            # Ciclo de vida, menús
├── Document.swift               # NSDocument — open/save/autosave/versions
├── DocumentWindowController.swift
├── EditorViewController.swift   # NSViewController con NSTextView
├── TextView.swift               # NSTextView subclass (personalización mínima)
├── ThemeManager.swift           # Light/Dark mode, colores del editor
├── Markdown/
│   ├── MarkdownParser.swift     # Parser .md → NSAttributedString
│   ├── MarkdownStyler.swift     # Estilos tipográficos por elemento MD
│   └── MarkdownPreviewController.swift  # Vista previa HTML renderizada
├── Preferences/
│   ├── PreferencesWindow.swift  # Ventana de preferencias
│   └── GeneralPreferences.swift # Font, tab size, word wrap
├── Extensions/
│   ├── NSTextView+LineNumbers.swift
│   └── String+Encoding.swift
└── Resources/
    ├── Assets.xcassets
    ├── MainMenu.xib             # Menú principal (o programático)
    └── Info.plist
```

### Patrón: Document-Based App (NSDocument)

- `NSDocument` gestiona el ciclo completo: abrir, guardar, auto-guardar, restaurar ventanas, versiones, iCloud.
- Cada documento tiene su propio `NSWindowController` → `NSViewController` → `NSTextView`.
- Cero código custom para file handling — Apple lo resuelve.

---

## 3. Optimizaciones de rendimiento

### 3.1 Arranque ultra-rápido

| Técnica | Impacto |
|---|---|
| **0 frameworks dinámicos externos** | Cada .dylib adicional suma 5-30 ms al arranque |
| **NSDocument lazy loading** | No carga contenido hasta que el usuario abre un archivo |
| **Diferir trabajo no visual** | Preferencias, archivos recientes, etc. se cargan en background thread DESPUÉS de mostrar la ventana |
| **Static linking** para cualquier dependencia | Evita el overhead de dynamic linking |
| **Sin storyboards pesados** | Usar XIB mínimos o UI programática |

### 3.2 Rendimiento con archivos grandes

| Técnica | Detalle |
|---|---|
| **`allowsNonContiguousLayout = true`** | Solo calcula el layout del viewport visible. Crítico para archivos de miles de líneas |
| **TextKit 1 (NSLayoutManager)** | Más estable y probado que TextKit 2 para un notepad simple |
| **Carga incremental** | Para archivos > 10 MB, cargar por chunks |
| **Line numbers bajo demanda** | Solo renderizar números de línea visibles en pantalla |

### 3.3 Memoria

- No mantener undo history ilimitado — limitar a 100 operaciones.
- Liberar recursos de documentos en background cuando la app pierde foco (opcional).
- Usar `NSTextStorage` directamente sin capas intermedias innecesarias.

---

## 4. Funcionalidades (MVP)

### Imprescindibles (v1.0)

- [ ] Crear documento nuevo (Cmd+N)
- [ ] Abrir archivo (Cmd+O) — archivos .txt y .md
- [ ] Guardar / Guardar como (Cmd+S / Cmd+Shift+S)
- [ ] Auto-guardado nativo (NSDocument)
- [ ] Versiones del documento (Browse All Versions)
- [ ] Deshacer / Rehacer ilimitado (NSUndoManager)
- [ ] Buscar y reemplazar (Cmd+F / Cmd+G)
- [ ] Word wrap toggle
- [ ] Selector de fuente y tamaño
- [ ] Soporte Light / Dark mode
- [ ] Contador de palabras y caracteres en status bar
- [ ] Detección de encoding (UTF-8, Latin-1, etc.)
- [ ] Drag & drop de archivos para abrir
- [ ] Tab size configurable (2/4/8 espacios)
- [ ] Print (Cmd+P)
- [ ] Abrir archivos recientes
- [ ] **Soporte Markdown (.md)** — edición con formato en vivo (ver sección 4.1)
- [ ] **Preview Markdown** — vista previa renderizada (Cmd+Shift+P)
- [ ] **Toolbar de formato MD** — botones para negrita, cursiva, headers, listas, links, código

### Deseables (v1.1)

- [ ] Números de línea (toggle)
- [ ] Resaltado de línea actual
- [ ] Highlight de paréntesis/brackets
- [ ] Múltiples pestañas (NSWindow tabbing nativo de macOS)
- [ ] Ir a línea (Cmd+L)
- [ ] Preferencias en ventana dedicada
- [ ] iCloud Document sync
- [ ] Soporte para Apple Intelligence Writing Tools

### Futuro (v2.0)

- [ ] Syntax highlighting para otros formatos (JSON, XML, YAML)
- [ ] Minimap lateral
- [ ] Comparar documentos (diff)
- [ ] Plugins con sistema simple

---

## 4.1 Soporte Markdown — Diseño detallado

### Estrategia: edición con formato en vivo + preview opcional

El editor trabaja siempre sobre el **texto fuente Markdown** (nunca se pierde la sintaxis), pero aplica estilos visuales en tiempo real para que el usuario vea formato mientras escribe.

### Modos de visualización

| Modo | Descripción | Atajo |
|---|---|---|
| **Source** | Texto plano sin formato (como .txt) | Cmd+1 |
| **Styled Source** | Texto fuente con formato visual en vivo (default para .md) | Cmd+2 |
| **Preview** | HTML renderizado de solo lectura (split o pantalla completa) | Cmd+Shift+P |

### Componentes

#### `MarkdownParser.swift` — Parser ligero

- **Sin dependencias externas**. Implementar un parser propio basado en regex/scanner para mantener 0 frameworks dinámicos.
- Alternativa aceptable: usar [cmark](https://github.com/commonmark/cmark) como librería C compilada estáticamente (< 200 KB, referencia CommonMark).
- Parsea el texto a un árbol de nodos: `heading`, `paragraph`, `bold`, `italic`, `code`, `codeBlock`, `link`, `image`, `list`, `blockquote`, `horizontalRule`, `table`.
- **Parsing incremental**: solo re-parsear los bloques modificados (detectar por cambio de línea), no el documento completo. Crítico para rendimiento al teclear.

#### `MarkdownStyler.swift` — Formato visual en vivo

Aplica `NSAttributedString` attributes sobre el `NSTextStorage` según los nodos parseados:

| Elemento MD | Estilo visual |
|---|---|
| `# Heading 1` | SF Pro Bold 24pt, color primario |
| `## Heading 2` | SF Pro Bold 20pt, color primario |
| `### Heading 3` | SF Pro Semibold 17pt, color primario |
| `**negrita**` | Misma fuente, weight bold |
| `*cursiva*` | Misma fuente, trait italic |
| `` `código inline` `` | SF Mono 13pt, background gris suave, corner radius |
| ```` ```bloque de código``` ```` | SF Mono 13pt, background gris, padding, borde izquierdo |
| `> blockquote` | Indent izquierdo, borde izquierdo azul, color texto secundario |
| `- lista` / `1. lista` | Indent con bullet/número, hanging indent |
| `[link](url)` | Color azul, subrayado, cursor pointer. Cmd+click abre URL |
| `![imagen](url)` | Mostrar thumbnail inline si es imagen local |
| `---` | Línea horizontal (NSAttributedString con attachment) |
| `~~tachado~~` | Strikethrough |
| `| tabla |` | Renderizado con tabs alineados o NSTextTable |

**Implementación técnica:**
- Subclass de `NSTextStorage` (`MarkdownTextStorage`) que intercepta `replaceCharacters(in:with:)` y `processEditing()`.
- En `processEditing()`, determinar el rango editado, re-parsear solo los bloques afectados, y aplicar atributos.
- Los marcadores de sintaxis (`**`, `#`, `` ` ``) se muestran en color gris tenue para que el usuario siga viendo la fuente pero no distraigan.

#### `MarkdownPreviewController.swift` — Vista previa

- Usa `WKWebView` para renderizar HTML generado desde el AST del parser.
- **Carga lazy**: WKWebView solo se instancia cuando el usuario pide preview por primera vez.
- CSS embebido que respeta Dark/Light mode del sistema (`@media (prefers-color-scheme: dark)`).
- Scroll sincronizado con el editor fuente (mapear posición de cursor a sección HTML).
- Layouts: split horizontal (editor | preview) o preview a pantalla completa.

#### Toolbar de formato Markdown

Barra opcional (toggle con Cmd+Shift+T) encima del editor con botones:

```
[ H1 ▾ ] [ B ] [ I ] [ S ] [ ‹› ] [ 🔗 ] [ 📷 ] [ — ] [ • ] [ 1. ] [ > ] [ ☐ ]
```

| Botón | Acción | Atajo |
|---|---|---|
| H1 ▾ | Dropdown: H1-H6 | Cmd+1..6 (en contexto MD) |
| **B** | Envolver selección en `**...**` | Cmd+B |
| *I* | Envolver selección en `*...*` | Cmd+I |
| ~~S~~ | Envolver selección en `~~...~~` | Cmd+Shift+X |
| `</>` | Envolver en backticks (inline o bloque) | Cmd+E |
| Link | Insertar `[texto](url)` | Cmd+K |
| Imagen | Insertar `![alt](path)` con file picker | Cmd+Shift+I |
| — | Insertar `---` | — |
| • | Toggle lista desordenada | Cmd+Shift+U |
| 1. | Toggle lista ordenada | Cmd+Shift+O |
| > | Toggle blockquote | Cmd+Shift+. |
| ☐ | Insertar checkbox `- [ ]` | — |

Cada botón opera como toggle: si el texto ya tiene el formato, lo quita.

### Detección automática de tipo de archivo

```swift
// En Document.swift
override func read(from data: Data, ofType typeName: String) throws {
    let text = String(data: data, encoding: .utf8) ?? ""
    self.text = text
    self.isMarkdown = (typeName == "net.daringfireball.markdown"
                    || fileURL?.pathExtension == "md"
                    || fileURL?.pathExtension == "markdown")
}
```

- Si el archivo es `.md` / `.markdown` → modo Styled Source por defecto.
- Si es `.txt` o cualquier otro → modo Source (texto plano).
- El usuario puede cambiar de modo manualmente en cualquier momento.

### UTI y tipos de documento (Info.plist)

```xml
<key>CFBundleDocumentTypes</key>
<array>
    <!-- Plain Text -->
    <dict>
        <key>CFBundleTypeName</key>
        <string>Plain Text</string>
        <key>LSItemContentTypes</key>
        <array>
            <string>public.plain-text</string>
        </array>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
    </dict>
    <!-- Markdown -->
    <dict>
        <key>CFBundleTypeName</key>
        <string>Markdown</string>
        <key>LSItemContentTypes</key>
        <array>
            <string>net.daringfireball.markdown</string>
        </array>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
    </dict>
</array>
```

Esto permite que Finder asocie MDView como app para abrir `.md` y `.txt`.

### Rendimiento del formato en vivo

| Aspecto | Estrategia |
|---|---|
| **Parsing incremental** | Solo re-parsear bloques modificados, no todo el documento |
| **Debounce del styler** | Aplicar estilos 50 ms después del último keystroke (evitar trabajo por cada carácter) |
| **Cache de atributos** | Cachear `NSAttributedString` attributes por tipo de nodo, no recrearlos en cada pasada |
| **WKWebView lazy** | No instanciar hasta primer uso de preview |
| **Preview throttle** | Actualizar preview máximo 2 veces/segundo mientras se escribe |
| **Archivos grandes** | Para .md > 1 MB, desactivar styled source por defecto (ofrecer activar manual) |

---

## 5. Plan de ejecución

### Fase 1 — Esqueleto (1-2 días)

1. Crear proyecto Xcode: Document-Based App, Swift, AppKit
2. Configurar `NSDocument` subclass con open/save
3. Crear `EditorViewController` con `NSTextView` en `NSScrollView`
4. Menú principal con acciones básicas (New, Open, Save, Close)
5. Verificar arranque < 200 ms con Instruments

### Fase 2 — Editor funcional (2-3 días)

6. Buscar y reemplazar (NSTextFinder — ya integrado en NSTextView)
7. Word wrap toggle
8. Status bar con contador de palabras/caracteres
9. Detección y selector de encoding
10. Selector de fuente (NSFontPanel — integrado en sistema)
11. Tab size configurable

### Fase 3 — Soporte Markdown (3-4 días)

12. `MarkdownParser` — parser de Markdown a árbol de nodos (o integrar cmark estático)
13. `MarkdownTextStorage` — NSTextStorage subclass con parsing incremental
14. `MarkdownStyler` — aplicar NSAttributedString styles por tipo de nodo
15. Detección automática .md/.txt en Document.swift + UTIs en Info.plist
16. Toolbar de formato MD con atajos (Cmd+B, Cmd+I, Cmd+K, etc.)
17. `MarkdownPreviewController` con WKWebView + CSS light/dark
18. Modos de visualización: Source / Styled Source / Preview (Cmd+1/2/Shift+P)
19. Scroll sincronizado editor ↔ preview

### Fase 4 — Pulido (2-3 días)

20. Dark/Light mode con ThemeManager
21. Drag & drop de archivos
22. Print support (NSDocument ya lo provee en gran parte)
23. Archivos recientes (NSDocumentController)
24. Icono de app y branding
25. Optimización: `allowsNonContiguousLayout`, debounce del styler, profile con Instruments

### Fase 5 — Distribución (1-2 días)

26. App Sandbox entitlements
27. Hardened Runtime
28. Notarización con Apple
29. Distribución: DMG directo o Mac App Store

---

## 6. Estructura del proyecto Xcode

```
MDView/
├── MDView.xcodeproj
├── MDView/
│   ├── App/
│   │   ├── MDViewApp.swift      # @main o AppDelegate
│   │   └── AppDelegate.swift
│   ├── Document/
│   │   ├── Document.swift           # NSDocument subclass
│   │   └── DocumentWindowController.swift
│   ├── Editor/
│   │   ├── EditorViewController.swift
│   │   └── SimpleTextView.swift     # NSTextView subclass
│   ├── Markdown/
│   │   ├── MarkdownParser.swift     # Parser MD → nodos
│   │   ├── MarkdownTextStorage.swift # NSTextStorage con styling incremental
│   │   ├── MarkdownStyler.swift     # Atributos tipográficos por nodo
│   │   ├── MarkdownPreviewController.swift  # WKWebView preview
│   │   ├── MarkdownToolbar.swift    # Barra de formato
│   │   └── Resources/
│   │       └── preview.css          # Estilos HTML para preview
│   ├── UI/
│   │   ├── StatusBarView.swift
│   │   └── ThemeManager.swift
│   ├── Preferences/
│   │   └── PreferencesWindowController.swift
│   ├── Extensions/
│   │   └── String+Encoding.swift
│   └── Resources/
│       ├── Assets.xcassets
│       ├── MainMenu.xib
│       └── Info.plist
└── MDViewTests/
    └── DocumentTests.swift
```

---

## 7. Requisitos del sistema

- **macOS mínimo**: macOS 13 Ventura (para Swift runtime embebido + TextKit maduro)
- **Xcode**: 15+
- **Lenguaje**: Swift 5.9+
- **Arquitecturas**: Universal Binary (Apple Silicon + Intel)
- **Sandbox**: Sí (requerido para Mac App Store)

---

## 8. Referencia: apps inspiración

| App | Lo que copiar | Lo que evitar |
|---|---|---|
| **TextEdit** | Simplicidad extrema, arranque instantáneo | Limitada funcionalidad |
| **CotEditor** | Syntax precompilado en build, NSDocument, modular Swift packages | Complejidad de syntax engine para MVP |
| **Sublime Text** | GPU rendering, UI mínima, foco en velocidad | Demasiado complejo para reimplementar |
| **BBEdit** | File handling robusto, encoding detection | Feature bloat |

---

## 9. Métricas objetivo

| Métrica | Objetivo |
|---|---|
| Arranque en frío | < 150 ms (Apple Silicon) |
| RAM en reposo | < 25 MB |
| Tamaño del .app | < 5 MB |
| Abrir archivo de 1 MB | < 100 ms |
| Abrir archivo de 50 MB | < 2 s |
| Responsive al teclear (.txt) | < 16 ms por keystroke (60 fps) |
| Responsive al teclear (.md styled) | < 32 ms por keystroke (30 fps mínimo) |
| Abrir preview MD | < 300 ms primera vez (WKWebView init) |
| Actualizar preview MD | < 100 ms (re-render incremental) |

---

*Última actualización: 25 febrero 2026*
