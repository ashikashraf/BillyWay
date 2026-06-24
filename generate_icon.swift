import Cocoa

let size = CGSize(width: 1024, height: 1024)
let bounds = CGRect(origin: .zero, size: size)

let img = NSImage(size: size)
img.lockFocus()

// Fill background with primary color 0xFF6366F1
let color = NSColor(red: 99/255.0, green: 102/255.0, blue: 241/255.0, alpha: 1.0)
color.setFill()
bounds.fill()

// Draw the white rounded rectangle in the center
let rectSize = CGSize(width: 700, height: 700)
let rectOrigin = CGPoint(x: (size.width - rectSize.width) / 2, y: (size.height - rectSize.height) / 2)
let rect = CGRect(origin: rectOrigin, size: rectSize)
let path = NSBezierPath(roundedRect: rect, xRadius: 150, yRadius: 150)
NSColor.white.setFill()
path.fill()

// Draw the "BW" text
let text = "BW"
let font = NSFont.systemFont(ofSize: 350, weight: .bold)
let paragraphStyle = NSMutableParagraphStyle()
paragraphStyle.alignment = .center

let attributes: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: NSColor(red: 99/255.0, green: 102/255.0, blue: 241/255.0, alpha: 1.0),
    .paragraphStyle: paragraphStyle
]

let stringSize = text.size(withAttributes: attributes)
let textRect = CGRect(
    x: rectOrigin.x,
    y: rectOrigin.y + (rectSize.height - stringSize.height) / 2 - 30, // offset slightly for baseline
    width: rectSize.width,
    height: stringSize.height
)

text.draw(in: textRect, withAttributes: attributes)

img.unlockFocus()

if let tiff = img.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff), let pngData = bitmap.representation(using: .png, properties: [:]) {
    try? pngData.write(to: URL(fileURLWithPath: "assets/icon/app_icon.png"))
}
