package khm;

import kha.Framebuffer;
import kha.Canvas;
import kha.graphics2.Graphics;
import kha.math.FastMatrix3;
import kha.input.Keyboard;
import kha.input.KeyCode;
import kha.input.Surface;
import kha.input.Mouse;
import kha.Scheduler;
import kha.System;
import kha.Font;

class Pointer {

	public var id:Int;
	public var scale = 1.0;
	// initial cords of pressing
	public var startX = 0;
	public var startY = 0;
	public var x = 0;
	public var y = 0;
	// last pointer speed
	public var moveX = 0;
	public var moveY = 0;
	// button type (for mouse)
	public var type = 0;
	public var isDown = false;
	// pointer is touch surface
	public var isTouch = false;
	// pointer already used
	public var isActive = false;

	public function new(id:Int):Void {
		this.id = id;
	}

	public function toGlobalCords(scale:Float):Void {
		startX = Std.int(startX * scale);
		startY = Std.int(startY * scale);
		x = Std.int(x * scale);
		y = Std.int(y * scale);
	}

	public function toLocalCords(scale:Float):Void {
		startX = Std.int(startX / scale);
		startY = Std.int(startY / scale);
		x = Std.int(x / scale);
		y = Std.int(y / scale);
	}

}

private typedef ScreenSets = {
	?isTouch:Bool,
	?defaultScale:Float
}

/** Сlass for unifying mouse/touch events and setup events automatically **/
class Screen {

	public static var screen:Screen; // current screen
	public static var w(default, null):Int; // for resize event
	public static var h(default, null):Int;
	public static var isTouch(default, null) = false;
	public static var defaultScale(default, null) = 1.0;
	public static var frame:Canvas;
	static final fps = new FPS();
	static var taskId:Int;
	static var isInited = false;

	public var scale(default, null) = 1.0;
	public final keys:Map<KeyCode, Bool> = new Map();
	public final pointers:Map<Int, Pointer> = [
		for (i in 0...10) i => new Pointer(i)
	];

	public function new() {}

	/** Setting custom static parameters (optional). **/
	public static function init(?sets:ScreenSets):Void {
		#if kha_html5
		isTouch = untyped __js__('"ontouchstart" in window');
		#elseif (kha_android || kha_ios)
		isTouch = true;
		#end
		if (sets != null) {
			if (sets.isTouch != null) isTouch = sets.isTouch;
			if (sets.defaultScale != null) defaultScale = sets.defaultScale;
		}
		setDefaultScale(defaultScale);
		w = Std.int(System.windowWidth() / defaultScale);
		h = Std.int(System.windowHeight() / defaultScale);
		isInited = true;
	}

	public static inline function setDefaultScale(scale:Float):Void {
		defaultScale = scale;
	}

	/** Displays this screen. Automatically hides the previous. **/
	public function show():Void {
		if (!isInited) init();
		if (screen != null) screen.hide();
		screen = this;
		scale = defaultScale;

		taskId = Scheduler.addTimeTask(_onUpdate, 0, 1 / 60);
		System.notifyOnFrames(_onRender);

		if (Keyboard.get() != null) Keyboard.get().notify(_onKeyDown, _onKeyUp, onKeyPress);

		if (isTouch && Surface.get() != null) {
			Surface.get().notify(_onTouchDown, _onTouchUp, _onTouchMove);
		} else if (Mouse.get() != null) {
			Mouse.get().notify(_onMouseDown, _onMouseUp, _onMouseMove, onMouseWheel, onMouseLeave);
		}
		for (i in keys.keys()) keys[i] = false;
		for (p in pointers) {
			p.isDown = false;
			p.scale = scale;
		}
	}

	/** For hiding the current screen manually. **/
	public function hide():Void {
		Scheduler.removeTimeTask(taskId);
		System.removeFramesListener(_onRender);

		if (Keyboard.get() != null) Keyboard.get().remove(_onKeyDown, _onKeyUp, onKeyPress);

		if (isTouch && Surface.get() != null) {
			Surface.get().remove(_onTouchDown, _onTouchUp, _onTouchMove);
		} else if (Mouse.get() != null) {
			Mouse.get().remove(_onMouseDown, _onMouseUp, _onMouseMove, onMouseWheel, onMouseLeave);
		}
	}

	inline function _onUpdate():Void {
		if (Std.int(System.windowWidth() / scale) != w ||
			Std.int(System.windowHeight() / scale) != h) _onResize();
		onUpdate();
		fps.update();
	}

	inline function _onResize():Void {
		w = Std.int(System.windowWidth() / scale);
		h = Std.int(System.windowHeight() / scale);
		onResize();
	}

	inline function _onRender(framebuffers:Array<Framebuffer>):Void {
		final framebuffer = framebuffers[0];

		frame = framebuffer;
		final g = frame.g2;
		g.transformation.setFrom(FastMatrix3.scale(scale, scale));
		onRender(frame);

		#if debug
		final font = frame.g2.font;
		if (font != null) {
			final g = framebuffer.g2;
			g.begin(false);
			drawFPS(g, font);
			g.end();
		}
		#end
		fps.addFrame();
	}

	function drawFPS(g:Graphics, font:Font):Void {
		g.transformation.setFrom(FastMatrix3.identity());
		g.color = 0xFFFFFFFF;
		g.font = font;
		g.fontSize = 24;
		final w = System.windowWidth();
		final h = System.windowHeight();
		final txt = '${fps.fps} | ${w}x${h} ${scale}x';
		final x = w - g.font.width(g.fontSize, txt);
		final y = h - g.font.height(g.fontSize);
		g.drawString(txt, x, y);
	}

	inline function _onKeyDown(key:KeyCode):Void {
		keys[key] = true;
		onKeyDown(key);
	}

	inline function _onKeyUp(key:KeyCode):Void {
		keys[key] = false;
		onKeyUp(key);
	}

	inline function _onMouseDown(button:Int, x:Int, y:Int):Void {
		x = Std.int(x / scale);
		y = Std.int(y / scale);
		pointers[0].scale = scale;
		pointers[0].startX = x;
		pointers[0].startY = y;
		pointers[0].x = x;
		pointers[0].y = y;
		pointers[0].type = button;
		pointers[0].isDown = true;
		pointers[0].isActive = true;
		pointers[0].isTouch = false;
		onMouseDown(pointers[0]);
	}

	inline function _onMouseMove(x:Int, y:Int, mx:Int, my:Int):Void {
		x = Std.int(x / scale);
		y = Std.int(y / scale);
		pointers[0].scale = scale;
		pointers[0].x = x;
		pointers[0].y = y;
		pointers[0].moveX = mx;
		pointers[0].moveY = my;
		pointers[0].isActive = true;
		onMouseMove(pointers[0]);
	}

	inline function _onMouseUp(button:Int, x:Int, y:Int):Void {
		if (!pointers[0].isActive) return;
		x = Std.int(x / scale);
		y = Std.int(y / scale);
		pointers[0].scale = scale;
		pointers[0].x = x;
		pointers[0].y = y;
		pointers[0].type = button;
		pointers[0].isDown = false;
		onMouseUp(pointers[0]);
	}

	inline function _onTouchDown(id:Int, x:Int, y:Int):Void {
		if (id > 9) return;
		x = Std.int(x / scale);
		y = Std.int(y / scale);
		pointers[id].scale = scale;
		pointers[id].startX = x;
		pointers[id].startY = y;
		pointers[id].x = x;
		pointers[id].y = y;
		pointers[id].isDown = true;
		pointers[id].isActive = true;
		pointers[id].isTouch = true;
		onMouseDown(pointers[id]);
	}

	inline function _onTouchMove(id:Int, x:Int, y:Int):Void {
		if (id > 9) return;
		x = Std.int(x / scale);
		y = Std.int(y / scale);
		pointers[id].scale = scale;
		pointers[id].moveX = x - pointers[id].x;
		pointers[id].moveY = y - pointers[id].y;
		pointers[id].x = x;
		pointers[id].y = y;
		pointers[id].isDown = true;
		pointers[id].isActive = true;
		onMouseMove(pointers[id]);
	}

	inline function _onTouchUp(id:Int, x:Int, y:Int):Void {
		if (id > 9) return;
		x = Std.int(x / scale);
		y = Std.int(y / scale);
		if (!pointers[id].isActive) return;
		pointers[id].x = x;
		pointers[id].y = y;
		pointers[id].isDown = false;
		pointers[id].isActive = false;
		onMouseUp(pointers[id]);
	}

	/**
		Sets the scale of the screen and change screen size. Automatically sets this value through `g2.transformation` before `onRender`. Calls `onRescale` and then `onResize`.
	**/
	public function setScale(scale:Float):Void {
		setScaleSilent(scale);
		onRescale(scale);
		onResize();
	}

	/** Same as `setScale` but without triggering events. **/
	public function setScaleSilent(scale:Float):Void {
		for (p in pointers) {
			if (p.isActive) {
				p.toGlobalCords(this.scale);
				p.toLocalCords(scale);
				p.scale = scale;
			}
		}
		this.scale = scale;
		w = Std.int(System.windowWidth() / scale);
		h = Std.int(System.windowHeight() / scale);
	}

	/**
		Changes g2.transformation and screen size. Doesn't trigger events.
	**/
	public function setGraphicScale(g:Graphics, scale:Float):Void {
		g.transformation.setFrom(FastMatrix3.scale(scale, scale));
		w = Std.int(System.windowWidth() / scale);
		h = Std.int(System.windowHeight() / scale);
	}

	// functions for override

	function onRescale(scale:Float):Void {}
	function onResize():Void {}
	function onUpdate():Void {}
	function onRender(frame:Canvas):Void {}

	public function onKeyDown(key:KeyCode):Void {}
	public function onKeyUp(key:KeyCode):Void {}
	public function onKeyPress(char:String):Void {}

	public function onMouseDown(p:Pointer):Void {}
	public function onMouseMove(p:Pointer):Void {}
	public function onMouseUp(p:Pointer):Void {}
	public function onMouseWheel(delta:Int):Void {}
	public function onMouseLeave():Void {}

}

private class FPS {

	public var fps(default, null) = 0;
	var frames = 0;
	var time = 0.0;
	var lastTime = 0.0;

	public function new() {}

	public function update():Int {
		var deltaTime = Scheduler.realTime() - lastTime;
		lastTime = Scheduler.realTime();
		time += deltaTime;

		if (time >= 1) {
			fps = frames;
			frames = 0;
			time = 0;
		}
		return fps;
	}

	public inline function addFrame():Void frames++;

}
