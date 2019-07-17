package demo;

import kha.graphics2.Graphics;
import kha.Canvas;
import kha.Assets;
import kha.Window;
import kha.input.Mouse;
import kha.input.KeyCode;
import khm.imgui.Imgui;
import khm.Screen;
import khm.Screen.Pointer;
import khm.imgui.Widgets.InputState;
import khm.imgui.Widgets.PanelState;
import khm.imgui.Widgets.SelectState;
using khm.imgui.Widgets;

class Gui extends Screen {

	var ui:Imgui;
	var touchDebugPointer = new Pointer(0);

	public function init():Void {
		Screen.showFps = true;
		ui = new Imgui({autoNotifyInput: false});
	}

	function secondPointer(p:Pointer):Pointer {
		final offX = 500;
		final p2 = touchDebugPointer;
		p2.id = p.id + 1;
		p2.scale = p.scale;
		p2.startX = p.startX + offX;
		p2.startY = p.startY;
		p2.x = p.x + offX;
		p2.y = p.y;
		p2.moveX = p.moveX;
		p2.moveY = p.moveY;
		p2.type = p.type;
		p2.isDown = p.isDown;
		p2.isTouch = true;
		p2.isActive = p2.isDown;
		return p2;
	}

	override function onMouseDown(p:Pointer):Void {
		if (p.id == 0) {
			final p2 = secondPointer(p);
			onMouseDown(p2);
		}
		if (ui.onPointerDown(p)) return;
	}

	override function onMouseMove(p:Pointer):Void {
		if (p.id == 0) {
			final p2 = secondPointer(p);
			onMouseMove(p2);
		}
		if (ui.onPointerMove(p)) return;
	}

	override function onMouseUp(p:Pointer):Void {
		if (p.id == 0) {
			final p2 = secondPointer(p);
			onMouseUp(p2);
		}
		if (ui.onPointerUp(p)) {
			// fullscreen / pointer lock workaround
			if (ui.redrawOnEvents) renderGUI(ui.g);
			return;
		}
	}

	override function onMouseWheel(delta:Int):Void {
		if (ui.onMouseWheel(delta)) return;
	}

	override function onKeyDown(key:KeyCode):Void {
		if (ui.onKeyDown(key)) return;
		if (ui.somethingHovered() && !ui.somethingFocused()) ui.focusHoveredItem();
		else if ((keys[Shift] && key == Tab) || key == Up) ui.focusPrevItem();
		else if (key == Tab || key == Down) ui.focusNextItem();
		else if (key == Return || key == Space) {
			ui.clickFocusedItem();
			if (ui.redrawOnEvents) renderGUI(ui.g);
		}

		if (key == 189 || key == HyphenMinus) {
			if (scale > 1) setScale(scale - 1);

		} else if (key == 187 || key == Equals) {
			if (scale < 9) setScale(scale + 1);
		}
	}

	override function onKeyUp(key:KeyCode):Void {
		if (ui.onKeyUp(key)) return;
	}

	override function onKeyPress(char:String):Void {
		if (ui.onKeyPress(char)) return;
	}

	override function onRender(canvas:Canvas):Void {
		final g = canvas.g2;
		g.begin(0xFF404040);
		g.font = Assets.fonts.OpenSans_Regular;
		g.fontSize = 24;
		renderGUI(g);

		// simulate second touch pointer
		final p = secondPointer(pointers[0]);
		g.color = 0xFFFF0000;
		g.fillRect(p.x - 1, p.y - 1, 3, 3);
		g.color = 0xFF707070;
		final charH = g.font.height(g.fontSize);
		g.drawString("Hover: " + ui.hoverIds, 5, 0);
		g.drawString("Active: " + ui.activeIds, 5, charH);
		g.drawString("Focus: " + ui.focusId, 5, charH * 2);
		g.end();
	}

	var ratio = 0.0;
	var isCheck = false;
	var clickNum = 0;
	var input = new InputState("Hello");
	var input2 = new InputState("");
	var panel = new PanelState("Panel", 450, 20, 150, 200);
	var select = new SelectState(["Select Name", "Kinc", "Kool", "Kute"]);
	var radioItem = 0;

	function renderGUI(g:Graphics):Void {
		ui.begin(g);
		if (ui.button(100, 40, "Hide")) Window.get(0).mode = Fullscreen;
		if (ui.button(200, 40, "Show")) Window.get(0).mode = Windowed;
		if (ui.button(100, 100, "Test")) clickNum--;
		ui.setButtonSize(80, 20);
		if (ui.button(200, 100, '$clickNum')) clickNum++;

		ratio = ui.slider(100, 160, ratio, 'Ratio: ${Std.int(ratio * 100) / 100}');
		final text = isCheck ? "Checked" : "Unchecked";
		isCheck = ui.checkbox(100, 200, isCheck, text);
		ui.inputLine(300, 50, input);

		for (i in 0...3) {
			if (ui.checkbox(300, 100 + i * 30, i == radioItem, 'Item $i')) radioItem = i;
		}
		final fontH = Math.ceil(g.font.height(g.fontSize));

		if (ui.panel(panel)) {
			final x = panel.mainX;
			var y = panel.mainY;
			ui.inputLine(x, y, input2);
			y += fontH + panel.offset;
			final w = 60;
			final h = 30;
			ui.setButtonSize(w - panel.offset, h - panel.offset);
			if (ui.button(x, y, "1")) input2.add("1");
			if (ui.button(x, y + h, "2")) input2.add("2");
			if (ui.button(x + w, y, "3")) input2.add("3");
			if (ui.button(x + w, y + h, "4")) input2.add("4");
			y += h * 2;
			ui.select(x, y, select);
			panel.mainH = y + select.h + panel.offset * 2 - panel.mainY;
			ui.endPanel(panel);
		}

		ui.setButtonSize(70, 40);
		if (ui.button(Screen.w - 70, 40, "-"))
			if (scale > 1) setScale(scale - 1);
		if (ui.button(Screen.w - 70, 40 * 2, "+"))
			if (scale < 9) setScale(scale + 1);
		ui.debug = ui.checkbox(0, Screen.h - fontH, ui.debug, 'debug');
		ui.redrawOnEvents = ui.checkbox(100, Screen.h - fontH, ui.redrawOnEvents, 'redrawOnEvents');
		ui.end();
	}

}
