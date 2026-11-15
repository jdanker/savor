// render.swift: frames raw simulator screenshots as App Store promo panels.
//
// Run from the repo root:
//   swift tools/promo/render.swift [release-dir]      (default: screenshots/app-store-1.3)
//
// Reads  <release-dir>/raw-6.9/*.png, <release-dir>/closed/*.png, <release-dir>/open/*.png
// Writes <release-dir>/promo/{iphone-6.9,iphone-6.3,duo-outer,duo-inner}/*.png
//
// Why SwiftUI + ImageRenderer instead of fastlane frameit (the usual tool): no
// Ruby/fastlane dependency, the same system serif (New York) the app uses for its
// titles, and frameit ships no frames for current hardware (iPhone Duo, 18 Pro Max).
// The bezel here is drawn, generic, and unbranded on purpose: no Apple logo or
// product name, so nothing implies Apple endorsement (App Review 5.2.4).

import AppKit
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Content

/// One promo panel: which raw screenshot it frames and what it says.
/// Copy rule (App Review 2.3.3 / 2.3.7): describe what the screenshot actually
/// shows. No prices, rankings, or unverifiable claims.
struct Panel {
    let source: String      // path relative to the release dir
    let output: String      // output filename
    let headline: String
    let subhead: String
    var dark = false        // dark backdrop for dark-mode screenshots
}

/// An App Store screenshot slot: exact pixel size Apple accepts, plus panels.
struct Slot {
    let folder: String
    let size: CGSize
    let panels: [Panel]
}

let iPhonePanels = [
    Panel(source: "raw-6.9/01-spots.png", output: "01-spots.png",
          headline: "Every spot worth\nremembering.",
          subhead: "Save the places you love and the ones you want to try."),
    Panel(source: "raw-6.9/02-detail.png", output: "02-detail.png",
          headline: "The good stuff,\nat a glance.",
          subhead: "Rating, price, and what makes each place stand out."),
    Panel(source: "raw-6.9/03-lists.png", output: "03-lists.png",
          headline: "Smart Sort does\nthe filing.",
          subhead: "One tap files your spots into Breakfast, Lunch, Dinner, and more."),
    Panel(source: "raw-6.9/04-sort.png", output: "04-sort.png",
          headline: "Sort it\nyour way.",
          subhead: "By price, rating, or distance from you."),
    Panel(source: "raw-6.9/05-dark.png", output: "05-dark.png",
          headline: "Easy on the eyes\nafter dark.",
          subhead: "A full dark mode that follows your settings.",
          dark: true),
]

let slots = [
    // 6.9" (large Dynamic Island): optional, highest resolution
    Slot(folder: "iphone-6.9", size: CGSize(width: 1320, height: 2868), panels: iPhonePanels),
    // 6.3" (medium Dynamic Island): the size App Store Connect requires. Same
    // UI at a near-identical aspect ratio, so the 6.9" captures are reused.
    Slot(folder: "iphone-6.3", size: CGSize(width: 1206, height: 2622), panels: iPhonePanels),
    // iPhone Duo outer display (folded), portrait
    Slot(folder: "duo-outer", size: CGSize(width: 1398, height: 2034), panels: [
        Panel(source: "closed/01-spots.png", output: "01-spots.png",
              headline: "Every spot worth\nremembering.",
              subhead: "Save the places you love and the ones you want to try."),
        Panel(source: "closed/02-detail-sheet.png", output: "02-detail.png",
              headline: "The good stuff,\nat a glance.",
              subhead: "Rating, price, and what makes each place stand out."),
        Panel(source: "closed/03-lists.png", output: "03-lists.png",
              headline: "A list for\nevery craving.",
              subhead: "Date night, quick lunch, coffee runs, all in one place."),
    ]),
    // iPhone Duo inner display (unfolded), landscape
    Slot(folder: "duo-inner", size: CGSize(width: 2853, height: 2007), panels: [
        Panel(source: "open/01-spots-split.png", output: "01-split.png",
              headline: "Unfold for more.",
              subhead: "Your spots and the details, side by side."),
        Panel(source: "open/02-list-detail.png", output: "02-list-detail.png",
              headline: "Browse a list, see every detail.",
              subhead: "Pick a spot and it opens right beside the list."),
        Panel(source: "open/03-search.png", output: "03-search.png",
              headline: "Find the one you're craving.",
              subhead: "Search everything you've saved."),
    ]),
]

// MARK: - Palette (mirrors Savor/Theme/SavorTheme.swift; that file imports UIKit, so it can't be shared with a macOS script)

enum Promo {
    static let lightTop = Color(red: 0.93, green: 0.93, blue: 0.91)
    static let lightBottom = Color(red: 0.80, green: 0.85, blue: 0.91)   // background tinted toward accentSoft
    static let darkTop = Color(red: 0.16, green: 0.17, blue: 0.19)
    static let darkBottom = Color(red: 0.08, green: 0.08, blue: 0.08)
    static let inkLight = Color(red: 0.15, green: 0.16, blue: 0.17)
    static let inkDark = Color(red: 0.93, green: 0.93, blue: 0.91)
    static let mutedLight = Color(red: 0.36, green: 0.37, blue: 0.39)
    static let mutedDark = Color(red: 0.66, green: 0.67, blue: 0.69)
}

// MARK: - Layout

/// Headline + subhead on top, the framed screenshot below, running off the bottom
/// edge. The bleed is the standard App Store look, and it buys a larger screenshot
/// than fitting the whole device would.
/// Every dimension derives from the canvas width (or the shorter side for
/// landscape), so one layout serves all four slot sizes.
struct PromoPanel: View {
    let panel: Panel
    let screenshot: NSImage
    let size: CGSize

    private var isLandscape: Bool { size.width > size.height }
    private var unit: CGFloat { min(size.width, size.height) }

    var body: some View {
        // Flow layout (text, gap, device) rather than pinning the device at a
        // fixed fraction of the height: canvases differ in aspect (Duo outer is
        // much squatter than 6.9"), and a pinned device overlapped the subhead
        // there. Flowing guarantees the device starts below whatever the copy needs.
        VStack(spacing: unit * 0.065) {
            VStack(spacing: unit * 0.028) {
                Text(panel.headline)
                    .font(.system(size: unit * (isLandscape ? 0.072 : 0.088), weight: .bold, design: .serif))
                    .foregroundStyle(panel.dark ? Promo.inkDark : Promo.inkLight)
                    .lineSpacing(unit * 0.004)

                Text(panel.subhead)
                    .font(.system(size: unit * (isLandscape ? 0.032 : 0.040), weight: .medium))
                    .foregroundStyle(panel.dark ? Promo.mutedDark : Promo.mutedLight)
                    .frame(maxWidth: size.width * 0.82)
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)

            device
        }
        .padding(.top, size.height * (isLandscape ? 0.065 : 0.06))
        .frame(width: size.width, height: size.height, alignment: .top)
        .background(
            LinearGradient(
                colors: panel.dark ? [Promo.darkTop, Promo.darkBottom] : [Promo.lightTop, Promo.lightBottom],
                startPoint: .top, endPoint: .bottom
            )
        )
        .clipped()
    }

    /// Generic device: black bezel, thin graphite rim, screen corners matching
    /// modern iPhone proportions (~12.5% of the screen's short side).
    private var device: some View {
        let screenWidth = size.width * (isLandscape ? 0.74 : 0.80)
        let aspect = screenshot.size.height / screenshot.size.width
        let screenSize = CGSize(width: screenWidth, height: screenWidth * aspect)
        let screenRadius = min(screenSize.width, screenSize.height) * 0.125
        let bezel = unit * 0.018

        return Image(nsImage: screenshot)
            .resizable()
            .frame(width: screenSize.width, height: screenSize.height)
            .clipShape(RoundedRectangle(cornerRadius: screenRadius, style: .continuous))
            .padding(bezel)
            .background(
                RoundedRectangle(cornerRadius: screenRadius + bezel, style: .continuous)
                    .fill(Color.black)
            )
            .overlay(
                RoundedRectangle(cornerRadius: screenRadius + bezel, style: .continuous)
                    .stroke(Color(white: 0.42), lineWidth: unit * 0.004)
            )
            .shadow(color: .black.opacity(panel.dark ? 0.5 : 0.22), radius: unit * 0.04, y: unit * 0.02)
    }
}

// MARK: - Rendering

enum RenderError: Error, CustomStringConvertible {
    case missingSource(String), renderFailed(String), writeFailed(String)
    var description: String {
        switch self {
        case .missingSource(let p): "missing source screenshot: \(p)"
        case .renderFailed(let p): "ImageRenderer produced no image for \(p)"
        case .writeFailed(let p): "couldn't write \(p)"
        }
    }
}

/// App Store Connect rejects screenshots with an alpha channel, and ImageRenderer
/// always produces one. Redrawing into an opaque (noneSkipLast) sRGB context
/// flattens it, rather than relying on every exporter to strip alpha.
func flattened(_ image: CGImage, size: CGSize) -> CGImage? {
    guard let context = CGContext(
        data: nil, width: Int(size.width), height: Int(size.height),
        bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    ) else { return nil }
    context.draw(image, in: CGRect(origin: .zero, size: size))
    return context.makeImage()
}

func writePNG(_ image: CGImage, to url: URL) throws {
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
    else { throw RenderError.writeFailed(url.path) }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else { throw RenderError.writeFailed(url.path) }
}

@MainActor
func render(releaseDir: URL) throws {
    for slot in slots {
        let outDir = releaseDir.appending(path: "promo/\(slot.folder)")
        try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

        for panel in slot.panels {
            let sourcePath = releaseDir.appending(path: panel.source).path
            guard let screenshot = NSImage(contentsOfFile: sourcePath) else {
                throw RenderError.missingSource(sourcePath)
            }

            // scale 1 at a frame of N points = exactly N pixels, the slot size
            let renderer = ImageRenderer(content: PromoPanel(panel: panel, screenshot: screenshot, size: slot.size))
            renderer.scale = 1
            guard let raw = renderer.cgImage, let opaque = flattened(raw, size: slot.size) else {
                throw RenderError.renderFailed(panel.output)
            }

            let outURL = outDir.appending(path: panel.output)
            try writePNG(opaque, to: outURL)
            print("wrote \(slot.folder)/\(panel.output)  \(opaque.width)×\(opaque.height)")
        }
    }
}

let releasePath = CommandLine.arguments.dropFirst().first ?? "screenshots/app-store-1.3"
let releaseDir = URL(filePath: releasePath, relativeTo: URL(filePath: FileManager.default.currentDirectoryPath + "/"))

do {
    try MainActor.assumeIsolated { try render(releaseDir: releaseDir) }
} catch {
    FileHandle.standardError.write(Data("error: \(error)\n".utf8))
    exit(1)
}
