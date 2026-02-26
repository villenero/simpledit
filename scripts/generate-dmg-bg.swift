#!/usr/bin/env swift
//
// Generates the DMG background image with arrow chevrons and install instructions.
// Usage: swift generate-dmg-bg.swift <output.png> [width] [height]
//

import CoreGraphics
import CoreText
import ImageIO
import Foundation

let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "dmg-bg.png"
let width  = CommandLine.arguments.count > 2 ? Int(CommandLine.arguments[2]) ?? 540 : 540
let height = CommandLine.arguments.count > 3 ? Int(CommandLine.arguments[3]) ?? 400 : 400

let W = CGFloat(width)
let H = CGFloat(height)

// --- Create bitmap context ---
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(
    data: nil, width: width, height: height,
    bitsPerComponent: 8, bytesPerRow: 4 * width,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fputs("error: failed to create CGContext\n", stderr); exit(1)
}

// --- 1. Background gradient (dark, subtle) ---
let gradColors = [
    CGColor(srgbRed: 0.10, green: 0.10, blue: 0.13, alpha: 1),
    CGColor(srgbRed: 0.16, green: 0.16, blue: 0.20, alpha: 1)
] as CFArray
guard let gradient = CGGradient(colorsSpace: colorSpace, colors: gradColors, locations: [0, 1]) else { exit(1) }
ctx.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: H), options: [])

// --- 2. Subtle dashed guide line between icon positions ---
// Icon centers (Finder coords: top-left origin) → CG coords (bottom-left)
let iconFinderY: CGFloat = 185          // y in Finder coords
let lineY = H - iconFinderY             // convert to CG
let leftIconX:  CGFloat = 135
let rightIconX: CGFloat = 405

ctx.saveGState()
ctx.setStrokeColor(CGColor(srgbRed: 0.45, green: 0.47, blue: 0.52, alpha: 0.25))
ctx.setLineWidth(1.5)
ctx.setLineDash(phase: 0, lengths: [8, 5])
ctx.beginPath()
ctx.move(to: CGPoint(x: leftIconX + 70, y: lineY))
ctx.addLine(to: CGPoint(x: rightIconX - 70, y: lineY))
ctx.strokePath()
ctx.restoreGState()

// --- 3. Three chevron arrows (>>> progressively brighter) ---
let chevronH: CGFloat = 24
let chevronW: CGFloat = 14
let arrowCenterX = (leftIconX + rightIconX) / 2
let startX = arrowCenterX - 40
let spacing: CGFloat = 32

for i in 0..<3 {
    let cx = startX + CGFloat(i) * spacing
    let alpha: CGFloat = 0.20 + CGFloat(i) * 0.28   // 0.20 → 0.48 → 0.76

    ctx.setStrokeColor(CGColor(srgbRed: 0.60, green: 0.67, blue: 0.80, alpha: alpha))
    ctx.setLineWidth(2.8)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)

    ctx.beginPath()
    ctx.move(to:    CGPoint(x: cx,            y: lineY + chevronH))
    ctx.addLine(to: CGPoint(x: cx + chevronW, y: lineY))
    ctx.addLine(to: CGPoint(x: cx,            y: lineY - chevronH))
    ctx.strokePath()
}

// --- 4. Instruction text ---
func drawCenteredText(_ string: String, y: CGFloat, size: CGFloat, alpha: CGFloat) {
    let font = CTFontCreateWithName("Helvetica Neue" as CFString, size, nil)
    let color = CGColor(srgbRed: 0.55, green: 0.58, blue: 0.64, alpha: alpha)
    let attrs = [kCTFontAttributeName: font, kCTForegroundColorAttributeName: color] as CFDictionary
    let attrStr = CFAttributedStringCreate(nil, string as CFString, attrs)!
    let line = CTLineCreateWithAttributedString(attrStr)
    var ascent: CGFloat = 0, descent: CGFloat = 0, leading: CGFloat = 0
    let textW = CTLineGetTypographicBounds(line, &ascent, &descent, &leading)
    ctx.textPosition = CGPoint(x: (W - textW) / 2, y: y)
    CTLineDraw(line, ctx)
}

drawCenteredText("Drag MDView to Applications to install", y: 68, size: 14, alpha: 0.85)
drawCenteredText(".md  .markdown  .txt", y: 45, size: 11, alpha: 0.45)

// --- 5. Save PNG ---
guard let image = ctx.makeImage() else { fputs("error: makeImage failed\n", stderr); exit(1) }
let url = URL(fileURLWithPath: outputPath)
guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else { exit(1) }
CGImageDestinationAddImage(dest, image, nil)
guard CGImageDestinationFinalize(dest) else { fputs("error: PNG write failed\n", stderr); exit(1) }

print("Generated \(width)x\(height) → \(outputPath)")
