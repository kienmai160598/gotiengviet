// Renders the template menu-bar icon: swift Tools/make-mac-icon.swift <output.tiff>
import AppKit

func render(scale: CGFloat) -> NSBitmapImageRep {
    let size = NSSize(width: 22, height: 16)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(size.width * scale), pixelsHigh: Int(size.height * scale),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = size
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
        .foregroundColor: NSColor.black,
    ]
    let label = NSAttributedString(string: "Vi", attributes: attributes)
    let bounds = label.size()
    label.draw(at: NSPoint(x: (size.width - bounds.width) / 2, y: (size.height - bounds.height) / 2))
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let output = CommandLine.arguments.dropFirst().first ?? "VietKey.tiff"
let image = NSImage(size: NSSize(width: 22, height: 16))
[1, 2].forEach { image.addRepresentation(render(scale: CGFloat($0))) }
guard let tiff = image.tiffRepresentation else { fatalError("TIFF encoding failed") }
try tiff.write(to: URL(fileURLWithPath: output))
