package khm.imgui;

/**
	Interactive widgets should be added with `imgui.addWidget(widgetRect)` every frame.
	@param id current widget id, should be unique (see `imgui.getId()`).
	@param x/y/w/h widget position/size rectangle.
	@param group (optional) widget group for multitouch restriction (0 by default). Each group (except 0) can have only one active widget.
**/
abstract WidgetRect(Array<Int>) {

	public var id(get, set):Int;
	inline function get_id():Int return this[0];
	inline function set_id(v:Int):Int return this[0] = v;
	public var x(get, set):Int;
	inline function get_x():Int return this[1];
	inline function set_x(v:Int):Int return this[1] = v;
	public var y(get, set):Int;
	inline function get_y():Int return this[2];
	inline function set_y(v:Int):Int return this[2] = v;
	public var w(get, set):Int;
	inline function get_w():Int return this[3];
	inline function set_w(v:Int):Int return this[3] = v;
	public var h(get, set):Int;
	inline function get_h():Int return this[4];
	inline function set_h(v:Int):Int return this[4] = v;
	public var group(get, set):Int;
	inline function get_group():Int return this[5];
	inline function set_group(v:Int):Int return this[5] = v;

	public inline function new(id:Int, x:Int, y:Int, w:Int, h:Int, group = 0):Void {
		this = [id, x, y, w, h, group];
	}

	public inline function copy():WidgetRect {
		return new WidgetRect(id, x, y, w, h, group);
	}

	public static inline function fromArray(a:Array<Int>):WidgetRect {
		return new WidgetRect(a[0], a[1], a[2], a[3], a[4], a[5]);
	}

}
