package khm.imgui.widgets;

import kha.graphics2.Graphics;
import kha.math.FastMatrix3;
import khm.imgui.Widgets.bgColor;
import khm.imgui.Widgets.hoverColor;
import khm.imgui.Widgets.activeColor;
import khm.imgui.Widgets.focusColor;
import khm.imgui.Widgets.textColor;
import khm.Screen.Pointer;

@:access(khm.imgui.Widgets)
class Input {

	public static var inputLineW = 120;
	public static var inputLineOffX = 3;
	public static var inputLineOffY = 2;
	static var inputCaretDelay = 30;
	static var inputCaretFrame = 0;
	static var initialPos = 0;

	public static function inputLine(ui:Imgui, x:Int, y:Int, input:InputState):Void {
		final g = ui.g;
		final id = ui.getId();
		final charH = Math.ceil(g.font.height(g.fontSize));
		final w = inputLineW;
		final h = charH;
		final rect = new WidgetRect(id, x, y, w, h);
		ui.addWidget(rect);
		final textX = x + inputLineOffX;

		ui.checkWidgetState(rect);
		var state:WidgetState = ui.getWidgetState(id);
		if (ui.isFocused(id)) state = Active;

		switch (state) {
			case Active:
				final p:Pointer = ui.getItemPointer(id);
				if (!ui.isFocused(id)) {
					ui.setFocus(id);
					initialPos = input.getCursorPosition(ui, p.x - textX, p.y - y);
					input.cursor = initialPos;
					input.resetSelection();
					inputCaretFrame = 0;
				}
				if (p != null && p.isDown) {
					input.cursor = input.getCursorPosition(ui, p.x - textX, p.y - y);
					input.setSelection(initialPos, input.cursor);
				}
				inputCaretFrame++;
				if (inputCaretFrame > inputCaretDelay * 2) inputCaretFrame = 0;
				final oldCursor = input.cursor;

				if (ui.textToPaste != "") input.clipboard = ui.textToPaste;
				ui.textToCopy = input.selectedText();

				if (ui.isKey(Meta) || ui.isKey(Control)) {
					if (ui.isKeyOnce(A)) {
						input.cursor = 0;
						input.setSelection(0, input.text.length);
					}
					if (ui.isKeyOnce(X)) input.cut();
					if (ui.isKeyOnce(C)) input.copy();
					if (ui.isKeyOnce(V)) input.paste();
				}
				if (ui.isKeyOnce(Escape)) ui.setFocus(0);
				if (ui.isKeyOnce(Backspace)) input.remove();
				if (ui.isKey(Shift)) {
					if (ui.isKeyOnce(Left)) input.prevSelection();
					if (ui.isKeyOnce(Right)) input.nextSelection();
				}
				if (ui.isKeyOnce(Left)) input.prevChar();
				if (ui.isKeyOnce(Right)) input.nextChar();
				if (ui.keyChar != "") input.add(ui.keyChar);
				if (oldCursor != input.cursor) inputCaretFrame = 0;
				input.updateCamera(g);
			default:
		}

		g.color = bgColor;
		g.fillRect(x, y, w, h);
		g.color = switch (state) {
			case Idle: bgColor;
			case Hover, Focus: hoverColor;
			case Active: activeColor;
		}
		g.drawRect(x + 0.5, y + 0.5, w - 1, h - 1);
		Widgets.scissor(ui, x + 1, y, w - 2, h);
		final cx = input.camera.x;
		final cy = input.camera.y;
		g.pushTransformation(g.transformation.multmat(FastMatrix3.translation(cx, cy)));
		if (state == Active) {
			if (input.hasSelection()) {
				final string = input.text.substr(0, input.selection.start);
				final x = g.font.width(g.fontSize, string);
				final string = input.text.substr(0, input.selection.end);
				final lineW = g.font.width(g.fontSize, string) - x;
				final offY = inputLineOffY;
				g.color = focusColor;
				g.fillRect(textX + x, y + offY, lineW, h - offY * 2 + 1);

			} else if (inputCaretFrame < inputCaretDelay) {
				final string = input.text.substr(0, input.cursor);
				final offX = g.font.width(g.fontSize, string) + 1;
				final offY = inputLineOffY;
				g.drawLine(textX + offX, y + offY, textX + offX, y + h - offY * 2 + 2);
			}
		}
		final offY = Std.int(h / 2 - g.font.height(g.fontSize) / 2);
		if (input.text.length == 0) {
			g.color = hoverColor;
			g.drawString(input.placeholder, textX, y + offY);
		} else {
			g.color = textColor;
			g.drawString(input.text, textX, y + offY);
		}
		g.popTransformation();
		Widgets.disableScissor(ui);
	}

}

class InputState {

	public final camera = {x: 0.0, y: 0.0};
	public final selection = {start: 0, end: 0};
	public var placeholder = "Input";
	public var text:String;
	public var cursor:Int;
	public var clipboard = "";

	public function new(text = "") {
		this.text = text;
		cursor = text.length;
	}

	public function prevChar():Void {
		if (hasSelection()) {
			cursor = selection.start;
			resetSelection();
			return;
		}
		if (cursor > 0) cursor--;
	}

	public function nextChar():Void {
		if (hasSelection()) {
			cursor = selection.end;
			resetSelection();
			return;
		}
		if (cursor < text.length) cursor++;
	}

	public inline function setSelection(start:Int, end:Int):Void {
		selection.start = start < end ? start : end;
		selection.end = start < end ? end : start;
	}

	public inline function resetSelection():Void {
		setSelection(0, 0);
	}

	public inline function hasSelection():Bool {
		return selection.end - selection.start > 0;
	}

	public inline function add(char:String):Void {
		if (hasSelection()) remove();
		addString(cursor, char);
		cursor++;
	}

	public inline function addString(pos:Int, s:String):Void {
		text = text.substr(0, pos) + s + text.substr(pos, text.length);
	}

	public function remove():Void {
		if (hasSelection()) {
			final p = selection;
			text = text.substr(0, p.start) + text.substr(p.end, text.length);
			if (cursor != p.start) cursor += p.start - p.end;
			resetSelection();

		} else if (cursor > 0) {
			removeChar(cursor);
			cursor--;
		}
	}

	public inline function removeChar(pos:Int):Void {
		text = text.substr(0, pos - 1) + text.substr(pos, text.length);
	}

	public function cut():Void {
		if (!hasSelection()) return;
		clipboard = selectedText();
		remove();
	}

	public function copy():Void {
		final text = selectedText();
		clipboard = text;
	}

	public inline function selectedText():String {
		if (!hasSelection()) return "";
		return text.substring(selection.start, selection.end);
	}

	public function paste():Void {
		if (hasSelection()) remove();
		addString(cursor, clipboard);
		cursor += clipboard.length;
	}

	public function prevSelection():Void {
		if (cursor <= 0) return;
		final old = cursor;
		cursor--;
		cursorSelection(old);
	}

	public function nextSelection():Void {
		if (cursor >= text.length) return;
		final old = cursor;
		cursor++;
		cursorSelection(old);
	}

	function cursorSelection(old:Int):Void {
		if (!hasSelection()) setSelection(cursor, old);
		else {
			if (old == selection.start) {
				setSelection(cursor, selection.end);
			} else if (old == selection.end) {
				setSelection(selection.start, cursor);
			}
		}
	}

	public function getCursorPosition(ui:Imgui, x:Float, y:Float):Int {
		final g = ui.g;
		final x = x - camera.x;
		final y = y - camera.y;
		var pos = 0;
		var width = 0.0;
		for (i in 0...text.length) {
			final char = text.charAt(i);
			width += g.font.width(g.fontSize, char);
			if (width < x) pos++;
			else {
				final charW = g.font.width(g.fontSize, char);
				if (width - charW / 2 < x) pos++;
				break;
			}
		}
		return pos;
	}

	public function updateCamera(g:Graphics):Void {
		final w = Input.inputLineW - Input.inputLineOffX * 2 - 1;
		final textW = g.font.width(g.fontSize, text);
		final cursorW = g.font.width(g.fontSize, text.substr(0, cursor));
		var newX = camera.x;
		if (cursorW + camera.x > w) newX = w - cursorW;
		else if (cursorW + camera.x < 0) newX = -cursorW;
		if (hasSelection()) newX += (camera.x - newX) * 0.8;
		camera.x = newX;

		if (camera.x > 0 || textW < w) camera.x = 0;
		else if (textW + camera.x < w) camera.x = -(textW - w);
	}

}
