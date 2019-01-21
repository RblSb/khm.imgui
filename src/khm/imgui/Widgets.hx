package khm.imgui;

import kha.graphics2.Graphics;
import kha.input.KeyCode;
import kha.Image;
import khm.imgui.widgets.Input;
import khm.imgui.widgets.Panel;
import khm.imgui.widgets.Select in Sel;

typedef InputState = khm.imgui.widgets.Input.InputState;
typedef PanelState = khm.imgui.widgets.Panel.PanelState;
typedef SelectState = khm.imgui.widgets.Select.SelectState;

class Widgets {

	public static var bgColor = 0xFF141419;
	public static var hoverColor = 0xFF555555;
	public static var activeColor = 0xFFEA8220;
	public static var focusColor = 0x802082EA;
	public static var textColor = 0xFFFFFFFF;

	public static function setColors(ui:Imgui, bg:Int, hover:Int, active:Int, focus:Int, text:Int):Void {
		bgColor = bg;
		hoverColor = hover;
		activeColor = active;
		focusColor = focus;
		textColor = text;
	}

	public static var buttonW = 70;
	public static var buttonH = 40;

	public static inline function setButtonSize(ui:Imgui, w:Int, h:Int):Void {
		buttonW = w;
		buttonH = h;
	}

	public static function button(ui:Imgui, x:Int, y:Int, text = ""):Bool {
		final g = ui.g;
		final id = ui.getId();
		final w = buttonW;
		final h = buttonH;
		final rect = new WidgetRect(id, x, y, w, h);
		ui.addWidget(rect);
		ui.checkWidgetState(rect);

		if (ui.isFocused(id)) drawFocusBorder(g, rect);

		final state = ui.getWidgetState(id);
		g.color = switch (state) {
			case Idle: bgColor;
			case Hover, Focus: hoverColor;
			case Active: activeColor;
		}
		g.fillRect(x, y, w, h);

		if (ui.isActive(id)) g.color = bgColor;
		else g.color = activeColor;
		final textW = g.font.width(g.fontSize, text);
		final textH = g.font.height(g.fontSize);
		g.drawString(text, x + w / 2 - textW / 2, y + h / 2 - textH / 2);

		return ui.isWidgetClicked(id);
	}

	public static function imageButton(ui:Imgui, x:Int, y:Int, img:Image):Bool {
		final g = ui.g;
		final id = ui.getId();
		final w = buttonW;
		final h = buttonH;
		final rect = new WidgetRect(id, x, y, w, h);
		ui.addWidget(rect);
		ui.checkWidgetState(rect);

		if (ui.isFocused(id)) drawFocusBorder(g, rect);

		final state = ui.getWidgetState(id);
		g.color = switch (state) {
			case Idle: bgColor;
			case Hover, Focus: hoverColor;
			case Active: activeColor;
		}
		g.fillRect(x, y, w, h);

		g.color = 0xFFFFFFFF;
		final imgW = img.width > w ? w : img.width;
		final imgH = img.height > h ? h : img.height;
		g.drawScaledImage(img,
			x + w / 2 - imgW / 2,
			y + h / 2 - imgH / 2,
			imgW, imgH
		);

		return ui.isWidgetClicked(id);
	}

	public static var checkboxW = 20;
	public static var checkboxH = 20;

	public static inline function setCheckboxSize(ui:Imgui, w:Int, h:Int):Void {
		checkboxW = w;
		checkboxH = h;
	}

	public static function checkbox(ui:Imgui, x:Int, y:Int, checked:Bool, text:String):Bool {
		final g = ui.g;
		final id = ui.getId();
		final w = checkboxW;
		final h = checkboxH;
		final textW = Std.int(g.font.width(g.fontSize, text));
		final rect = new WidgetRect(id, x, y, w * 2 + textW, h);
		ui.addWidget(rect);

		if (ui.isFocused(id)) drawFocusBorder(g, rect);

		ui.checkWidgetState(rect);
		final state:WidgetState = ui.getWidgetState(id);
		if (ui.isWidgetClicked(id)) checked = !checked;

		g.color = switch (state) {
			case Idle: bgColor;
			default: hoverColor;
		}
		g.fillRect(x, y, w, h);
		if (checked) {
			g.color = activeColor;
			final s = Std.int(w / 5);
			g.fillRect(x + s, y + s, w - s * 2, h - s * 2);
		}
		g.color = bgColor;
		final offY = Std.int(h / 2 - g.font.height(g.fontSize) / 2);
		g.drawString(text, x + w * 1.5, y + offY);

		return checked;
	}

	public static var sliderSizeW = 100;
	public static var sliderSizeH = 20;

	public static inline function setSliderSize(ui:Imgui, w:Int, h:Int):Void {
		sliderSizeW = w;
		sliderSizeH = h;
	}

	public static function slider(ui:Imgui, x:Int, y:Int, ratio:Float, text:String):Float {
		final w = sliderSizeW;
		final h = sliderSizeH;
		final lineH = Std.int(h / 4);
		final sliderW = h / 2;
		final sliderH = h;
		final g = ui.g;
		final id = ui.getId();
		final rect = new WidgetRect(id, x, y, w, h);
		ui.addWidget(rect);

		if (ui.isFocused(id)) drawFocusBorder(g, rect);

		ui.checkWidgetState(rect);
		var state:WidgetState = ui.getWidgetState(id);
		if (ui.isPressed(id)) state = Active;
		switch (state) {
			case Idle:
			case Hover:
				ratio -= ui.mouseWheel / 20;
			case Focus:
				if (ui.isKey(Left)) ratio -= 1 / 20;
				if (ui.isKey(Right)) ratio += 1 / 20;
			case Active:
				if (ui.keyboardFocus) {
					if (ratio == 0) ratio = 1;
					else ratio = 0;
				} else {
					final p:Pointer = ui.getItemPointer(id);
					if (p != null) {
						ratio = (p.x - x - sliderW / 2) / (w - sliderW);
					}
				}
		}
		if (ratio < 0) ratio = 0;
		if (ratio > 1) ratio = 1;

		g.color = bgColor;
		g.fillRect(x, y + h / 2 - Std.int(lineH / 2), w, lineH);
		g.color = switch (state) {
			case Idle: bgColor;
			case Hover, Focus: hoverColor;
			case Active: activeColor;
		}
		g.fillRect(x + (w - sliderW) * ratio, y, sliderW, sliderH);
		g.color = bgColor;
		final offY = Std.int(h / 2 - g.font.height(g.fontSize) / 2);
		g.drawString(text, x + w + sliderW, y + offY);
		return ratio;
	}

	public static function select(ui:Imgui, x:Int, y:Int, select:SelectState):Int {
		return Sel.select(ui, x, y, select);
	}

	public static inline function inputLine(ui:Imgui, x:Int, y:Int, input:InputState):Void {
		Input.inputLine(ui, x, y, input);
	}

	public static inline function panel(ui:Imgui, panel:PanelState):Bool {
		return Panel.panel(ui, panel);
	}

	public static inline function endPanel(ui:Imgui, panel:PanelState):Void {
		Panel.endPanel(ui, panel);
	}

	static inline function drawFocusBorder(g:Graphics, rect:WidgetRect):Void {
		g.color = focusColor;
		final s = 2;
		g.drawRect(rect.x - s / 2, rect.y - s / 2, rect.w + s, rect.h + s, s);
	}

	static final scissors:Array<WidgetRect> = [];
	static final origScissors:Array<WidgetRect> = [];

	// scissor with stack, overlapping and matrix transformation
	static function scissor(ui:Imgui, x:Int, y:Int, w:Int, h:Int):Void {
		final g = ui.g;
		final pos = g.transformation.multvec({x: x, y: y});
		final size = g.transformation.multvec({x: w, y: h});
		for (s in scissors) {
			final difX = s.x - pos.x;
			final difY = s.y - pos.y;
			if (difX > 0) {pos.x += difX; size.x -= difX;}
			if (difY > 0) {pos.y += difY; size.y -= difY;}

			final difX = size.x + pos.x - s.w - s.x;
			final difY = size.y + pos.y - s.h - s.y;
			if (difX > 0) size.x -= difX;
			if (difY > 0) size.y -= difY;
		}
		if (size.x < 0) size.x = 0;
		if (size.y < 0) size.y = 0;
		ui.scissor(x, y, w, h);
		origScissors.push(new WidgetRect(0, x, y, w, h));
		g.scissor(
			Std.int(pos.x), Std.int(pos.y),
			Std.int(size.x), Std.int(size.y)
		);
		scissors.push(new WidgetRect(0,
			Std.int(pos.x), Std.int(pos.y),
			Std.int(size.x), Std.int(size.y)
		));
	}

	static function disableScissor(ui:Imgui):Void {
		final g = ui.g;
		scissors.pop();
		origScissors.pop();
		if (scissors.length > 0) {
			final s = scissors[scissors.length - 1];
			g.scissor(s.x, s.y, s.w, s.h);
			final s = origScissors[scissors.length - 1];
			ui.scissor(s.x, s.y, s.w, s.h);
		} else {
			g.disableScissor();
			ui.disableScissor();
		}
	}

}
