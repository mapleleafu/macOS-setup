ObjC.import("AppKit");

function primaryHeight() {
  var screens = $.NSScreen.screens;
  var n = Number(screens.count);
  for (var i = 0; i < n; i++) {
    var frame = screens.objectAtIndex(i).frame;
    if (frame.origin.x === 0 && frame.origin.y === 0) {
      return frame.origin.y + frame.size.height;
    }
  }
  return $.NSScreen.mainScreen.frame.size.height;
}

function targetScreen() {
  var mouse = $.NSEvent.mouseLocation;
  var screens = $.NSScreen.screens;
  var n = Number(screens.count);
  for (var i = 0; i < n; i++) {
    var screen = screens.objectAtIndex(i);
    if ($.NSMouseInRect(mouse, screen.frame, false)) {
      return screen;
    }
  }
  return $.NSScreen.mainScreen;
}

function tile(mode) {
  var f = targetScreen().visibleFrame;
  var x = f.origin.x;
  var w = f.size.width;
  var h = f.size.height;
  var y = primaryHeight() - f.origin.y - h;
  if (mode === "left") {
    w = Math.floor(w / 2);
  } else if (mode === "right") {
    w = Math.floor(w / 2);
    x = f.origin.x + f.size.width - w;
  }
  x = Math.round(x);
  y = Math.round(y);
  w = Math.round(w);
  h = Math.round(h);
  var se = Application("System Events");
  var proc = se.applicationProcesses.whose({ frontmost: true })[0];
  if (proc.windows.length === 0) {
    return;
  }
  var win = proc.windows[0];
  win.position = [x, y];
  win.size = [w, h];
  win.position = [x, y];
}

function run(argv) {
  tile(argv[0] || "fill");
}
