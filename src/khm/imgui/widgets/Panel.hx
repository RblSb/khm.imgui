package khm.imgui.widgets;

import kha.graphics2.Graphics;
import khm.imgui.Widgets.bgColor;
import khm.imgui.Widgets.hoverColor;
import khm.imgui.Widgets.textColor;

@:access(khm.imgui.Widgets)
class Panel {

	static var panelBgColor = 0xFF242429;

	public static function panel(ui:Imgui, panel:PanelState):Bool {
		final g = ui.g;
		final titleH = Math.ceil(g.font.height(g.fontSize));
		final x = panel.x;
		final y = panel.y;
		final w = panel.w;
		final h = panel.isOpen ? panel.h : titleH;
		final id = ui.getId();
		panel.id = id;
		final rect = new WidgetRect(id, x, y, w, h);
		ui.addWidget(rect);

		if (ui.isFocused(id)) Widgets.drawFocusBorder(g, rect);
		ui.checkWidgetState(rect);
		var state:WidgetState = ui.getWidgetState(id);
		if (ui.isPressed(id)) state = Active;
		panel.titleH = titleH;
		panel.updateViewRect();
		final th = Std.int(titleH - panel.offset * 2);

		if (state == Active && ui.keyboardFocus) {
			panel.isOpen = !panel.isOpen;

		} else if (state == Active) {
			final p:Pointer = ui.getItemPointer(id);
			if (p != null) {
				final isHold = panel.isMoving || panel.isResize;
				final hideX = x + w - th - panel.offset;
				if (!isHold && p.y < panel.viewY && p.x > hideX) {
					panel.isOpen = !panel.isOpen;
					ui.setIdle(p.id, id);
				}
				final resizeX = x + w - th;
				final resizeY = y + h - th;
				if (panel.isResize || p.x > resizeX && p.y > resizeY) resizePanel(panel, p);
				if (panel.isMoving || p.y < panel.viewY) movePanel(panel, p);
				final isHold = panel.isMoving || panel.isResize;
				if (!isHold && p.y > panel.viewY) ui.setIdle(p.id, id);
			}
		} else {
			panel.isMoving = false;
			panel.isResize = false;
		}

		final x = panel.x;
		final y = panel.y;
		final w = panel.w;
		final h = panel.h;
		panel.updateViewRect();
		panel.mainX = x + panel.offset;
		panel.mainY = panel.viewY + panel.offset + panel.camY;

		g.color = bgColor;
		g.fillRect(x, y, w, titleH);
		g.color = textColor;
		final titleW = Math.ceil(g.font.width(g.fontSize, panel.title));
		if (titleW + panel.offset < w) g.drawString(panel.title, x + panel.offset, y);
		if (panel.isOpen) {
			g.color = panelBgColor;
			g.fillRect(x, panel.viewY, w, panel.viewH);
			final tx = x + w - th - panel.offset;
			final ty = y + panel.offset + th / 4;
			g.color = hoverColor;
			g.fillTriangle(
				tx, ty,
				tx + th, ty,
				tx + th / 2, ty + th / 2
			);
			final tx = x + w - 1;
			final ty = y + h - 1;
			g.fillTriangle(
				tx, ty,
				tx - th / 2, ty,
				tx, ty - th / 2
			);
			Widgets.scissor(ui, x, panel.viewY, w, panel.viewH);
		} else {
			g.color = hoverColor;
			final x = x + w - th - panel.offset;
			final y = y + panel.offset;
			g.fillTriangle(
				x + th, y,
				x + th / 2, y + th / 2,
				x + th, y + th
			);
		}

		return panel.isOpen;
	}

	static function movePanel(panel:PanelState, p:Pointer):Void {
		if (panel.isResize) return;
		if (!panel.isMoving) {
			panel.isMoving = true;
			panel.holdPos.x = panel.x;
			panel.holdPos.y = panel.y;
		}
		panel.x = panel.holdPos.x + (p.x - p.startX);
		panel.y = panel.holdPos.y + (p.y - p.startY);
	}

	static function resizePanel(panel:PanelState, p:Pointer):Void {
		if (panel.isMoving) return;
		if (!panel.isResize) {
			panel.isResize = true;
			panel.holdPos.x = panel.w;
			panel.holdPos.y = panel.h;
		}
		panel.w = panel.holdPos.x + (p.x - p.startX);
		panel.h = panel.holdPos.y + (p.y - p.startY);
		final min = panel.titleH + 5;
		if (panel.w < min) panel.w = min;
		if (panel.h < min) panel.h = min;
	}

	public static function endPanel(ui:Imgui, panel:PanelState):Void {
		final id = panel.id;
		final scrollSpeed = 3;
		final isHover = hoverInRange(ui, id, ui.prevId());
		if (isHover) panel.camY -= ui.mouseWheel * scrollSpeed;
		if (ui.focusId >= id && ui.focusId <= ui.prevId()) {
			if (ui.isKey(Right)) panel.camY -= scrollSpeed;
			if (ui.isKey(Left)) panel.camY += scrollSpeed;
		}
		if (panel.camY > 0) panel.camY = 0;
		else if (panel.mainH < panel.viewH) panel.camY = 0;
		else if (panel.camY < -(panel.mainH - panel.viewH)) {
			panel.camY = -(panel.mainH - panel.viewH);
		}
		if (panel.isOpen) Widgets.disableScissor(ui);
		drawScrollbar(ui, panel);
	}

	static function hoverInRange(ui:Imgui, panelId:Int, lastId:Int):Bool {
		for (i in ui.hoverIds) {
			if (i >= panelId && i <= lastId) return true;
			break;
		}
		return false;
	}

	static function drawScrollbar(ui:Imgui, panel:PanelState):Void {
		final g = ui.g;
		final mainH = panel.mainH;
		final viewH = panel.viewH;
		if (mainH > viewH) {
			final ratio = viewH / mainH;
			final scrollH = ratio * viewH;

			final viewY = panel.viewY;
			final ratio = (panel.mainY - panel.camY * 2 - viewY - panel.offset) / (mainH - viewH);
			final scrollY = viewY + (viewH - scrollH) * ratio;
			g.color = hoverColor;
			g.fillRect(panel.x + panel.w - 2, scrollY, 2, scrollH);
		}
	}

}

class PanelState {

	public var title:String;
	public var x:Int;
	public var y:Int;
	public var w:Int;
	public var h:Int;
	public var titleH:Int;
	public var offset = 5;
	public var id:Int;
	public var lastWidgetId = -1;
	public var mainX = 0;
	public var mainY = 0;
	public var mainW = 0;
	public var mainH = 0;
	public var viewX:Int;
	public var viewY:Int;
	public var viewW:Int;
	public var viewH:Int;
	public var camY = 0;
	public var isOpen = true;
	public var isMoving = false;
	public var isResize = false;
	public final holdPos = {x: 0, y: 0};

	public function new(title = "", x:Int, y:Int, w:Int, h:Int) {
		this.title = title;
		this.x = x;
		this.y = y;
		this.w = w;
		this.h = h;
	}

	public function updateViewRect():Void {
		viewX = x;
		viewY = y + titleH;
		viewW = w;
		viewH = h - titleH;
	}

}
