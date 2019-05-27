package khm.imgui.widgets;

import kha.graphics2.Graphics;
import kha.math.FastMatrix3;
import khm.imgui.Widgets.bgColor;
import khm.imgui.Widgets.hoverColor;
import khm.imgui.Widgets.activeColor;
import khm.imgui.Widgets.textColor;
import khm.Screen.Pointer;

@:access(khm.imgui.Widgets)
class Select {

	static var selectBgColor = 0xFF242429;

	public static function select(ui:Imgui, x:Int, y:Int, select:SelectState):Int {
		final g = ui.g;
		final w = select.getWidth(g);
		final h = select.getHeight(g);
		final id = ui.getId();
		final rect = new WidgetRect(id, x, y, w, h);
		ui.addWidget(rect);

		if (ui.isFocused(id)) Widgets.drawFocusBorder(g, x, y, w, h);

		ui.checkWidgetState(rect);
		var state:WidgetState = ui.getWidgetState(id);
		if (!ui.isSelected(id)) state = Idle;
		var isClicked = ui.isWidgetClicked(id);

		final itemH = Math.ceil(g.font.height(g.fontSize));
		final offY = Std.int(itemH / 2 - g.font.height(g.fontSize) / 2);
		if (!select.isOpen) {
			g.color = stateColor(state);
			g.fillRect(x, y, w, itemH);
			g.color = textColor;
			final text = select.current();
			g.drawString(text, x + select.offX, y + offY);

		} else {
			if (state == Focus) {
				if (ui.isKeyOnce(Up)) select.prev();
				if (ui.isKeyOnce(Down)) select.next();
				if (ui.isKeyOnce(Space) || ui.isKeyOnce(Select)) isClicked = true;
			}
			var p:Pointer = ui.getItemPointer(id);
			if (ui.keyboardFocus) p = null;

			for (i in 0...select.options.length) {
				if (p != null && select.isInside(g, i, p.y - y)) {
					g.color = stateColor(state);
					if (isClicked) select.id = i;
				} else g.color = bgColor;
				if (i == select.id) g.color = hoverColor;
				g.fillRect(x, y + itemH * i, w, itemH);
				g.color = textColor;
				final text = select.options[i];
				g.drawString(text, x + select.offX, y + offY + itemH * i);
			}
		}
		if (isClicked) select.isOpen = !select.isOpen;

		return select.id;
	}

	static inline function stateColor(state:WidgetState):Int {
		return switch (state) {
			case Idle: bgColor;
			case Hover, Focus: hoverColor;
			case Active: activeColor;
		}
	}

}

class SelectState {

	public var options:Array<String>;
	public var id:Int;
	public var isOpen = false;
	public var offX = 10;
	public var w = 0;
	public var h = 0;

	public function new(options:Array<String>, id = 0) {
		this.options = options;
		this.id = id;
	}

	public inline function current():String {
		return options[id];
	}

	public inline function next():Void {
		id++;
		if (id > options.length - 1) id = 0;
	}

	public inline function prev():Void {
		id--;
		if (id < 0) id = options.length - 1;
	}

	public function getWidth(g:Graphics):Int {
		w = 0;
		for (option in options) {
			final itemW = Std.int(g.font.width(g.fontSize, option));
			if (itemW > w) w = itemW;
		}
		return w + offX * 2;
	}

	public function getHeight(g:Graphics):Int {
		final itemH = Math.ceil(g.font.height(g.fontSize));
		h = isOpen ? itemH * options.length : itemH;
		return h;
	}

	public function isInside(g:Graphics, i:Int, y:Int):Bool {
		final itemH = Math.ceil(g.font.height(g.fontSize));
		return y > itemH * i && y <= itemH * (i + 1);
	}

}
