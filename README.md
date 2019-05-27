## khm.imgui

Imgui core for [Kha](https://github.com/Kode/Kha).

[Online demo](https://rblsb.github.io/khm.imgui/build/html5)

### Pros:
* Multitouch, singletouch groups
* Keyboard support, tab navigation
* Event blocking/skipping via gui
* Widget clipping/overlapping
* Documented API for custom widgets

### Cons:
* Only one draw cycle per imgui instance
* Caching should be done on widget side
* This is just core with independent test widgets, not something more

### Basic usage

```haxe
import kha.Assets;
import kha.Framebuffer;
import kha.System;
import khm.imgui.Imgui;
using khm.imgui.Widgets;

class ImguiDemo {
	var ui:Imgui;

	public function new():Void {
		ui = new Imgui({});
		System.notifyOnFrames(onRender);
	}

	function onRender(fbs:Array<Framebuffer>):Void {
		final g = fbs[0].g2;
		g.begin(0xFF404040);
		g.font = Assets.fonts.OpenSans_Regular;
		g.fontSize = 24;

		ui.begin(g);
		if (ui.button(50, 50, "Hello")) trace("Hello");
		ui.end();

		// call only after gui rendering
		g.end();
	}
}
```

### Integration

For actual usage I recommend to disable automatic input listeners:
```haxe
ui = new Imgui({autoNotifyInput: false});
```
And use all your listeners with imgui like that:
```haxe
function onMouseDown(button:Int, x:Int, y:Int):Void {
	// send mouseDown to imgui instance, returns true if imgui blocks event
	if (ui.onMouseDown(button, x, y)) return;
	// click stuff behind gui
}
function onTouchDown(id:Int, x:Int, y:Int):Void {
	if (ui.onMouseDown(id, x, y)) return;
	// touch stuff behind gui
}
// same for onMouseUp, onMouseMove, onMouseWheel, onTouchMove, onTouchUp
// and for onKeyDown, onKeyUp, onKeyPress
```
Also, do not create events for the mouse and for the touch together, select only one thing for current kha target.

*Commercial break*
Or use it with `khm.Screen` to get mouse/touch unification, scale support and pointer/keys state arrays.
```haxe
import khm.Screen;
class Name extends Screen { // all listeners creates after new Name().show()
	override function onMouseDown(p:Pointer):Void { // also works as onTouchDown
		if (ui.onPointerDown(p)) return;
	}
	override function onRender(canvas:kha.Canvas):Void {
		final g = canvas.g2;
		...
	}
	// you still need to override onMouseMove, onMouseWheel
	// and key events for sending it to imgui
}
```

### Widget example

Actual button code with comments:
```haxe
public static function button(ui:Imgui, x:Int, y:Int, text = ""):Bool {
	final g = ui.g; // graphics2 from imgui.begin(g)
	// generates int id (previous widget id += 1)
	final id = ui.getId();
	final w = buttonW; // static vars
	final h = buttonH;
	// WidgetRect is inlined class
	final rect = new WidgetRect(id, x, y, w, h);
	// add to current frame (for input event prevention and overlapping)
	ui.addWidget(rect);
	// set widget state idle/hovered/active based on overlapping, widget groups and pointer ids
	ui.checkWidgetState(rect);

	// every widget can have multiply states at once, like Active + Hover + Focus.
	// this can be checked with ui.isActive(id)/isHovered/isFocused/isIdle

	// If widget focused draw focus border (custom function)
	if (ui.isFocused(id)) drawFocusBorder(g, rect);

	// returns only most priority state (order is Active > Focus > Hover > Idle)
	final state = ui.getWidgetState(id);
	// set bg color (colors is static vars)
	g.color = switch (state) {
		case Idle: bgColor;
		case Hover, Focus: hoverColor;
		case Active: activeColor;
	}
	g.fillRect(x, y, w, h);

	// draw text color
	if (ui.isActive(id)) g.color = bgColor;
	else g.color = activeColor;
	// draw text
	final textW = g.font.width(g.fontSize, text);
	final textH = g.font.height(g.fontSize);
	g.drawString(text, x + w / 2 - textW / 2, y + h / 2 - textH / 2);

	// pointer (mouse/touch) released with widget be selected (focus/hover) and active
	return ui.isWidgetClicked(id);
}
```

### Widget caching

Create non-static state class with render target. Draw to render target only on widget focus/hovering, other time draw cached render target.

For widgets with subwidgets inside, like panels/windows, there is `imgui.setGraphics(g2)` and `imgui.resetGraphics()` for graphic context swap. Example:
```haxe
// if window hovered/focused:
// save windowId to window state
// set custom g2
// return true
if (imgui.beginWindow(window)) {
	// redraw button to render target
	imgui.button(...);
	// reset g2
	// you can get latest subwidget id with `imgui.prevId()`
	// and make checks on range (id => windowId && id <= prevId)
	// about hover/active subwidgets
	imgui.endWindow(window);
}
```

### Fullscreen / Pointer lock workaround

Browsers block fullscreen / pointer lock if they are not called from event handler functions. Imgui of course calls the buttons from the render function, so we need to call the renderer right after mouse down / mouse up / key down.
```haxe
ui = new Imgui({autoNotifyInput: false, redrawOnEvents: true});
...
override function onMouseUp(p:Pointer):Void {
	if (ui.onPointerUp(p)) {
		if (ui.redrawOnEvents) onRender(ui.g);
		return;
	}
}
```
For key listeners `redrawOnEvents: true` don't needed, but render call is required.

Unnecessary redrawing is not the best solution, but another is difficult to achieve. For optimization, I recommend to put the imgui rendering in a separate function and call it like `renderGUI(ui.g)`, and most importantly, create an imgui instance with `redrawOnEvents: true` only for the menu/settings screen with fullscreen / pointer lock buttons, not for everything. Or, if you do not want to recreate the imgui instance, set the `ui.redrawOnEvents = true/false` at the right moment.

### Plans
* Cache test, more examples, api stabilization
* Zui-like widget system based on current components, but with relative cords?
