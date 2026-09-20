import AppKit
import ApplicationServices
import Darwin
import Foundation

private let fifoPath = (ProcessInfo.processInfo.environment["HOME"] ?? NSHomeDirectory())
  + "/.config/karabiner/scripts/tile-window.fifo"
private let untrustedFlag = "/tmp/tile-window.untrusted"

private func log(_ message: String) {
  let line = message + "\n"
  guard let data = line.data(using: .utf8) else {
    return
  }
  let url = URL(fileURLWithPath: "/tmp/tile-window.log")
  if let handle = try? FileHandle(forWritingTo: url) {
    defer { try? handle.close() }
    handle.seekToEndOfFile()
    handle.write(data)
  } else {
    try? data.write(to: url)
  }
}

private func primaryHeight() -> CGFloat {
  let primary = NSScreen.screens.first(where: { $0.frame.origin == .zero }) ?? NSScreen.main
  return primary?.frame.maxY ?? 0
}

private func axRect(for screen: NSScreen) -> CGRect {
  let f = screen.visibleFrame
  return CGRect(
    x: f.origin.x,
    y: primaryHeight() - f.origin.y - f.height,
    width: f.width,
    height: f.height
  )
}

private func screen(forAXPoint point: CGPoint) -> NSScreen? {
  let top = primaryHeight()
  for screen in NSScreen.screens {
    let f = screen.frame
    let ax = CGRect(
      x: f.origin.x,
      y: top - f.origin.y - f.height,
      width: f.width,
      height: f.height
    )
    if ax.insetBy(dx: -2, dy: -2).contains(point) {
      return screen
    }
  }
  return NSScreen.screens.first { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) }
    ?? NSScreen.main
}

private func focusedWindow() -> AXUIElement? {
  guard let app = NSWorkspace.shared.frontmostApplication else {
    return nil
  }
  let appEl = AXUIElementCreateApplication(app.processIdentifier)
  var win: CFTypeRef?
  if AXUIElementCopyAttributeValue(appEl, kAXFocusedWindowAttribute as CFString, &win) == .success,
    let win
  {
    return (win as! AXUIElement)
  }
  var windows: CFTypeRef?
  if AXUIElementCopyAttributeValue(appEl, kAXWindowsAttribute as CFString, &windows) == .success,
    let list = windows as? [AXUIElement],
    let first = list.first
  {
    return first
  }
  return nil
}

private func axPoint(_ element: AXUIElement) -> CGPoint? {
  var ref: CFTypeRef?
  guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &ref) == .success,
    let value = ref
  else {
    return nil
  }
  var point = CGPoint.zero
  AXValueGetValue(value as! AXValue, .cgPoint, &point)
  return point
}

private func axSize(_ element: AXUIElement) -> CGSize? {
  var ref: CFTypeRef?
  guard AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &ref) == .success,
    let value = ref
  else {
    return nil
  }
  var size = CGSize.zero
  AXValueGetValue(value as! AXValue, .cgSize, &size)
  return size
}

private func setFrame(_ element: AXUIElement, _ rect: CGRect) {
  var origin = rect.origin
  var size = rect.size
  let pos = AXValueCreate(.cgPoint, &origin)!
  let sz = AXValueCreate(.cgSize, &size)!
  AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, pos)
  AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, sz)
  AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, pos)
}

private func tile(_ mode: String) {
  let trusted = AXIsProcessTrusted()
  if !trusted {
    try? "1".write(toFile: untrustedFlag, atomically: true, encoding: .utf8)
    log("tile \(mode) untrusted")
    return
  }
  try? FileManager.default.removeItem(atPath: untrustedFlag)

  guard let win = focusedWindow() else {
    log("tile \(mode) no window")
    return
  }
  let pos = axPoint(win)
  let size = axSize(win)
  let target: NSScreen?
  if let pos, let size {
    target = screen(forAXPoint: CGPoint(x: pos.x + size.width / 2, y: pos.y + size.height / 2))
  } else {
    target = NSScreen.screens.first { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) }
      ?? NSScreen.main
  }
  guard let target else {
    return
  }
  var rect = axRect(for: target)
  if mode == "left" {
    rect.size.width = floor(rect.width / 2)
  } else if mode == "right" {
    let width = floor(rect.width / 2)
    rect.origin.x = rect.maxX - width
    rect.size.width = width
  }
  setFrame(win, rect)
  log("tile \(mode) \(rect)")
}

private func runDaemon() {
  unlink(fifoPath)
  guard mkfifo(fifoPath, 0o600) == 0 else {
    exit(1)
  }
  while true {
    guard let handle = FileHandle(forReadingAtPath: fifoPath) else {
      sleep(1)
      continue
    }
    let data = handle.readDataToEndOfFile()
    try? handle.close()
    let mode = String(data: data, encoding: .utf8)?
      .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if mode == "fill" || mode == "left" || mode == "right" {
      DispatchQueue.main.sync {
        tile(mode)
      }
    }
  }
}

autoreleasepool {
  let _ = NSApplication.shared
  if !AXIsProcessTrusted() {
    let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
    AXIsProcessTrustedWithOptions(opts)
  }
  log("daemon start trusted=\(AXIsProcessTrusted())")
  DispatchQueue.global(qos: .userInteractive).async {
    runDaemon()
  }
  RunLoop.main.run()
}
