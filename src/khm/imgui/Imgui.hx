package khm.imgui;

import kha.graphics2.Graphics;
import kha.System;
import kha.input.Mouse;
import kha.input.Keyboard;
import kha.input.KeyCode;

@:structInit
class ImguiSets {

	public var autoNotifyInput = true;
	public var redrawOnEvents = false;

}

class Imgui {

	static inline var PNUM = 10;
	final pointers:Array<Pointer> = [
		for (i in 0...PNUM) {
			id: i, startX: 0, startY: 0,
			x: 0, y: 0, moveX: 0, moveY: 0,
			type: 0, isDown: false, isActive: false
		}
	];
	public final hoverIds:Array<Int> = [for (i in 0...PNUM) 0];
	public final activeIds:Array<Int> = [for (i in 0...PNUM) 0];
	public final widgetGroups:Array<Int> = [for (i in 0...PNUM) 0];
	public var focusId(default, null) = 0;

	public var mouseWheel(default, null) = 0;
	public var keyChar(default, null) = "";
	public var keyboardFocus(default, null) = false;
	public var g(default, null):Graphics;
	public var textToPaste(default, null) = "";
	public var textToCopy = "";
	public var isCutText = false;
	public var isCopyText = false;
	final pointersDown:Array<Bool> = [for (i in 0...PNUM) false];
	final pointersUp:Array<Bool> = [for (i in 0...PNUM) false];
	final blockedKeys:Map<KeyCode, Bool> = [];
	final keys:Map<KeyCode, Bool> = [];
	var lastFrame:Array<WidgetRect> = [];
	var frame:Array<WidgetRect> = [];
	var scissorRect:WidgetRect;
	var oldG:Graphics;
	var focusItemId = 0;
	var id = 0;
	var blockKeyPress = false;
	var autoNotifyInput:Bool;
	var redrawOnEvents:Bool;

	/**
		Creates new imgui instance.
		@param autoNotifyInput set up mouse and keyboard events automatically.
	**/
	public function new(sets:ImguiSets):Void {
		this.autoNotifyInput = sets.autoNotifyInput;
		this.redrawOnEvents = sets.redrawOnEvents;
		if (autoNotifyInput) {
			if (Mouse.get() != null) {
				Mouse.get().notify(onMouseDown, onMouseUp, onMouseMove, onMouseWheel);
			}
			if (Keyboard.get() != null) {
				Keyboard.get().notify(onKeyDown, onKeyUp, onKeyPress);
			}
		}
		System.notifyOnCutCopyPaste(onCut, onCopy, onPaste);
	}

	public function unregisterListeners():Void {
		if (autoNotifyInput) {
			if (Mouse.get() != null) {
				Mouse.get().remove(onMouseDown, onMouseUp, onMouseMove, onMouseWheel);
			}
			if (Keyboard.get() != null) {
				Keyboard.get().remove(onKeyDown, onKeyUp, onKeyPress);
			}
		}
		removeCutCopyPaste();
	}

	@:access(kha.System)
	function removeCutCopyPaste():Void {
		System.cutListener = null;
		System.copyListener = null;
		System.pasteListener = null;
	}

	public function onPointerDown(p:Pointer):Bool {
		if (pointers[p.id] != p) pointers[p.id] = p;
		keyboardFocus = false;
		pointersDown[p.id] = true;
		if (redrawOnEvents) setActive(p.id, hoverIds[p.id]);
		return isPointerBlocked(p.id, p.x, p.y);
	}

	public function onPointerMove(p:Pointer):Bool {
		if (pointers[p.id] != p) pointers[p.id] = p;
		return isPointerBlocked(p.id, p.x, p.y);
	}

	public function onPointerUp(p:Pointer):Bool {
		if (pointers[p.id] != p) pointers[p.id] = p;
		pointersUp[p.id] = true;
		if (redrawOnEvents) {
			pointersDown[p.id] = false;
			pointersUp[p.id] = false;
		}
		return isPointerBlocked(p.id, p.x, p.y);
	}

	function isPointerBlocked(id:Int, x:Int, y:Int):Bool {
		if (hoverIds[id] > 0) return true;
		for (rect in lastFrame) {
			if (x >= rect.x && y >= rect.y &&
				x < rect.x + rect.w &&
				y < rect.y + rect.h) {
				return true;
			}
		}
		return false;
	}

	function onCut():Null<String> {
		isCutText = true;
		if (textToCopy == "") return null;
		return textToCopy;
	}

	function onCopy():Null<String> {
		isCopyText = true;
		if (textToCopy == "") return null;
		return textToCopy;
	}

	function onPaste(s:String):Void {
		textToPaste = s;
	}

	/**
		If `autoNotifyInput` is set to` false`, mouse functions must be called independently to send events to imgui.
		The functions return whether the mouse was used in imgui (should it be blocked for user code, for example, prevent click for elements under imgui).
	**/
	public function onMouseDown(button:Int, x:Int, y:Int):Bool {
		pointers[0].startX = x;
		pointers[0].startY = y;
		pointers[0].x = x;
		pointers[0].y = y;
		pointers[0].type = button;
		pointers[0].isDown = true;
		pointers[0].isActive = true;
		return onPointerDown(pointers[0]);
	}

	public function onMouseMove(x:Int, y:Int, mx:Int, my:Int):Bool {
		pointers[0].x = x;
		pointers[0].y = y;
		pointers[0].moveX = mx;
		pointers[0].moveY = my;
		pointers[0].isActive = true;
		return onPointerMove(pointers[0]);
	}

	public function onMouseUp(button:Int, x:Int, y:Int):Bool {
		if (!pointers[0].isActive) return false;
		pointers[0].x = x;
		pointers[0].y = y;
		pointers[0].type = button;
		pointers[0].isDown = false;
		return onPointerUp(pointers[0]);
	}

	public function onMouseWheel(delta:Int):Bool {
		mouseWheel = delta;
		return isPointerBlocked(0, pointers[0].x, pointers[0].y);
	}

	public function onTouchDown(id:Int, x:Int, y:Int):Bool {
		if (id >= PNUM - 1) return false;
		pointers[id].startX = x;
		pointers[id].startY = y;
		pointers[id].x = x;
		pointers[id].y = y;
		pointers[id].isDown = true;
		pointers[id].isActive = true;
		return onPointerDown(pointers[id]);
	}

	public function onTouchMove(id:Int, x:Int, y:Int):Bool {
		if (id >= PNUM - 1) return false;
		pointers[id].moveX = x - pointers[id].x;
		pointers[id].moveY = y - pointers[id].y;
		pointers[id].x = x;
		pointers[id].y = y;
		pointers[id].isActive = true;
		return onPointerMove(pointers[id]);
	}

	inline function onTouchUp(id:Int, x:Int, y:Int):Bool {
		if (id >= PNUM - 1) return false;
		if (!pointers[id].isActive) return false;
		pointers[id].x = x;
		pointers[id].y = y;
		pointers[id].isDown = false;
		return onPointerUp(pointers[id]);
	}

	/**
		If `autoNotifyInput` is set to` false`, keyboard functions must be called independently to send events to imgui.
		The functions return whether the current key was used in imgui.
	**/
	public function onKeyDown(key:KeyCode):Bool {
		if (somethingActive()) return true;
		keyboardFocus = true;
		// if key exists in gui checks
		if (blockedKeys[key]) {
			blockKeyPress = true;
			keys[key] = true;
		}
		return blockedKeys[key];
	}

	public function onKeyUp(key:KeyCode):Bool {
		if (somethingActive()) return true;
		keyboardFocus = true;
		if (blockedKeys[key]) keys[key] = false;
		return blockedKeys[key];
	}

	public function onKeyPress(char:String):Bool {
		this.keyChar = char;
		return focusId > 0;
	}

	/** Focus first hovered widget from last frame. **/
	public inline function focusHoveredItem():Void {
		focusNearItem(0);
	}

	/** Focus first drawn widget from last frame. **/
	public inline function focusFirstItem():Void {
		focusItem(0);
	}

	/** Focus last drawn widget from last frame. **/
	public inline function focusLastItem():Void {
		focusItem(lastFrame.length - 1);
	}

	/** Focus previous widget from last frame (or last if there is no selection). **/
	public inline function focusPrevItem():Void {
		focusNearItem(-1);
	}

	/** Focus next widget from last frame (or first if there is no selection). **/
	public inline function focusNextItem():Void {
		focusNearItem(1);
	}

	function focusNearItem(side:Int):Void {
		if (somethingActive()) return;
		if (focusId == 0) {
			for (i in hoverIds) {
				if (i > 0) {
					focusId = i;
					break;
				}
			}
		}
		if (focusId == 0) {
			if (side == -1) focusLastItem();
			else focusFirstItem();
			return;
		}
		for (i in 0...lastFrame.length) {
			final item = lastFrame[i];
			if (item.id == focusId) {
				focusItemId = i + side;
				break;
			}
		}
		if (focusItemId >= lastFrame.length) focusFirstItem();
		else if (focusItemId == -1) focusLastItem();
		else focusItem(focusItemId);
	}

	function focusItem(id:Int):Void {
		if (lastFrame.length == 0) return;
		focusItemId = id;
		setFocus(lastFrame[focusItemId].id);
		for (i in keys.keys()) keys[i] = false;
	}

	/** Simulated click for focused widget. You can catch that with `keyboardFocus` field. **/
	public inline function clickFocusedItem():Void {
		if (focusId == 0) return;
		setActive(0, focusId);
	}

	/** Must be called at the beginning of imgui rendering. **/
	public function begin(g:Graphics):Void {
		this.g = g;
		if (!keyboardFocus) focusId = 0;
		for (i in 0...hoverIds.length) {
			hoverIds[i] = 0;
			widgetGroups[i] = 0;
		}
		for (i in blockedKeys.keys()) blockedKeys[i] = false;
		if (blockKeyPress) keyChar = "";
		blockKeyPress = false;
		id = 0;
	}

	/** Must be called at the end of imgui rendering. **/
	public function end():Void {
		for (p in pointers) {
			if (!pointersDown[p.id]) activeIds[p.id] = 0;
			else if (activeIds[p.id] == 0) activeIds[p.id] = -1;

			if (pointersUp[p.id]) {
				pointersDown[p.id] = false;
				pointersUp[p.id] = false;
			}
		}
		mouseWheel = 0;
		keyChar = "";
		textToPaste = "";
		isCutText = false;
		isCopyText = false;
		lastFrame = frame;
		frame = [];
	}

	/**
		Generates widget id (previous id += 1).
		Call this function only once per widget.
	**/
	public inline function getId():Int {
		return ++id;
	}

	/** Returns the id of the previous drawn widget. **/
	public inline function prevId():Int {
		return id;
	}

	/** Add widget rect to current frame. Must be called for each widget that can be selected. **/
	public function addWidget(rect:WidgetRect):Void {
		if (scissorRect != null) {
			final s = scissorRect;
			if (rect.x < s.x) rect.x = s.x;
			if (rect.y < s.y) rect.y = s.y;
			final difX = rect.w + rect.x - s.w - s.x;
			final difY = rect.h + rect.y - s.h - s.y;
			if (difX > 0) rect.w -= difX;
			if (difY > 0) rect.h -= difY;
		}
		frame.push(rect);
	}

	/**
		Checks if any pointer is inside of the widget rect with `isInside` function.
		Then it checks that there is no active widget in the same widget group.
		Set widget hovered if that's true. Also set widget active if pointer down.
	**/
	public function checkWidgetState(rect:WidgetRect):Void {
		final p = isInside(rect.id, rect.x, rect.y, rect.w, rect.h);
		if (p == null) return;
		final id = p.id;
		if (rect.group != 0) {
			for (i in 0...widgetGroups.length) {
				if (widgetGroups[i] == rect.group) return;
			}
			widgetGroups[id] = rect.group;
		}
		setHover(id, rect.id);
		if (activeIds[id] == 0 && pointersDown[id]) setActive(id, rect.id);
	}

	/**
		Checks if any pointer is inside of the widget rect and doesn't overlap with bigger id widget.
		Returns found pointer or null.
	**/
	public function isInside(id:Int, x:Int, y:Int, w:Int, h:Int):Null<Pointer> {
		for (p in pointers) {
			if (!p.isActive) continue;
			if (p.x < x || p.y < y ||
				p.x >= x + w || p.y >= y + h) {
				continue;
			}
			// check overlapping
			for (rect in lastFrame) {
				if (rect.id <= id) continue;
				if (p.x >= rect.x && p.y >= rect.y &&
					p.x < rect.x + rect.w &&
					p.y < rect.y + rect.h) {
					return null;
				}
			}
			return p;
		}
		return null;
	}

	/** Return most priority widget state (Active > Focus > Hover > Idle). **/
	public inline function getWidgetState(id:Int):WidgetState {
		if (isActive(id)) return Active;
		if (isFocused(id)) return Focus;
		if (isHovered(id)) return Hover;
		return Idle;
	}

	public inline function isIdle(id:Int):Bool {
		return !isSelected(id) && !isActive(id);
	}

	public function isHovered(id:Int):Bool {
		for (i in hoverIds)
			if (i == id) return true;
		return false;
	}

	public inline function isFocused(id:Int):Bool {
		return focusId == id;
	}

	/** Checks if widget pressed and selected with same pointer. **/
	public function isActive(id:Int):Bool {
		for (i in 0...activeIds.length)
			if (activeIds[i] == id && (hoverIds[i] == id || focusId == id)) return true;
		return false;
	}

	/** Checks if widget hovered or focused. **/
	public inline function isSelected(id:Int):Bool {
		return isHovered(id) || isFocused(id);
	}

	public function isPressed(id:Int):Bool {
		for (i in activeIds)
			if (i == id) return true;
		return false;
	}

	public inline function setIdle(pointerId:Int, id:Int):Void {
		if (hoverIds[pointerId] == id) setHover(pointerId, 0);
		if (isFocused(id)) setFocus(0);
		if (activeIds[pointerId] == id) setActive(pointerId, 0);
	}

	public inline function setHover(pointerId:Int, id:Int):Void {
		hoverIds[pointerId] = id;
	}

	public inline function setFocus(id:Int):Void {
		keyboardFocus = id != 0;
		focusId = id;
	}

	public inline function setActive(pointerId:Int, id:Int):Void {
		activeIds[pointerId] = id;
	}

	public function somethingHovered():Bool {
		for (i in hoverIds)
			if (i > 0) return true;
		return false;
	}

	public inline function somethingFocused():Bool {
		return focusId != 0;
	}

	public function somethingActive():Bool {
		for (i in activeIds)
			if (i > 0) return true;
		return false;
	}

	/** Returns first found pointer of active/selected element id. **/
	public function getItemPointer(itemId:Int):Null<Pointer> {
		for (p in pointers) {
			if (activeIds[p.id] == itemId) return p;
		}
		for (p in pointers) {
			if (hoverIds[p.id] == itemId) return p;
			if (focusId == itemId) return p;
		}
		return null;
	}

	/** Checks if key pressed. Also add key to stack for prevention outside of gui. **/
	public inline function isKey(key:KeyCode):Bool {
		blockedKeys[key] = true;
		return keys[key];
	}

	/** Same as `isKey`, but also make key up. **/
	public function isKeyOnce(key:KeyCode):Bool {
		blockedKeys[key] = true;
		if (keys[key]) {
			keys[key] = false;
			return true;
		}
		keys[key] = false;
		return false;
	}

	/** Set widgets rect restriction. Useful for widgets with scrolling. **/
	public function scissor(x:Int, y:Int, w:Int, h:Int):Void {
		scissorRect = new WidgetRect(0, x, y, w, h);
	}

	/** Removes widgets rect restriction. **/
	public function disableScissor():Void {
		scissorRect = null;
	}

	/** Set custom graphics2 context.Useful for caching sub-widgets. **/
	public inline function setGraphics(newG:Graphics):Void {
		oldG = g;
		g = newG;
	}

	/** Restore original graphics2 context. **/
	public inline function resetGraphics():Void {
		if (oldG == null) return;
		g = oldG;
		oldG = null;
	}

	/** Checks if widget clicked (pointer released with widget be selected and active). **/
	public function isWidgetClicked(id:Int):Bool {
		for (p in pointers) {
			if (
				activeIds[p.id] == id &&
				(hoverIds[p.id] == id || isFocused(id)) &&
				!pointersDown[p.id]
			) return true;
		}
		return false;
	}

}
