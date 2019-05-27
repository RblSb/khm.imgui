package khm.imgui;

import kha.graphics2.Graphics;
import kha.System;
import kha.input.Mouse;
import kha.input.Keyboard;
import kha.input.KeyCode;
import kha.math.FastMatrix3;
import khm.Screen.Pointer;

class Frame {

	final arr:Array<Int> = [];
	public var length(get, never):Int;
	inline function get_length():Int {
		return Std.int(arr.length / WidgetRect.LENGTH);
	}

	public function new() {}

	public inline function get(i:Int):WidgetRect {
		i *= WidgetRect.LENGTH;
		final rect = new WidgetRect(
			arr[i], arr[i + 1],
			arr[i + 2], arr[i + 3],
			arr[i + 4], arr[i + 5]
		);
		return rect;
	}

	public inline function push(rect:WidgetRect):Void {
		arr.push(rect.id);
		arr.push(rect.x);
		arr.push(rect.y);
		arr.push(rect.w);
		arr.push(rect.h);
		arr.push(rect.group);
	}

	public inline function copyFrom(frame:Frame):Void {
		arr.resize(frame.arr.length);
		for (i in 0...frame.arr.length) {
			arr[i] = frame.arr[i];
		}
	}

	public inline function clear():Void {
		arr.resize(0);
	}

	public inline function iterator():FrameIterator {
		return new FrameIterator(arr);
	}

}

private class FrameIterator {

	final arr:Array<Int>;
	var i = 0;

	public inline function new(arr:Array<Int>) {
		this.arr = arr;
	}

	public inline function hasNext() {
		return i < arr.length;
	}

	public inline function next() {
		final rect = new WidgetRect(
			arr[i], arr[i + 1], arr[i + 2],
			arr[i + 3], arr[i + 4], arr[i + 5]
		);
		i += WidgetRect.LENGTH;
		return rect;
	}

}
