package khm.imgui;

/**
	Interactive widgets should be added with `imgui.addWidget(widgetRect)` every frame.
	@param id current widget id, should be unique (see `imgui.getId()`).
	@param x/y/w/h widget position/size rectangle.
	@param group (optional) widget group for multitouch restriction (0 by default). Each group (except 0) can have only one active widget.
**/
class WidgetRect {

	public static inline var LENGTH = 6;
	public var id:Int;
	public var x:Int;
	public var y:Int;
	public var w:Int;
	public var h:Int;
	public var group:Int;

	public inline function new(id:Int, x:Int, y:Int, w:Int, h:Int, group = 0):Void {
		this.id = id;
		this.x = x;
		this.y = y;
		this.w = w;
		this.h = h;
		this.group = group;
	}

	public inline function setFrom(rect:WidgetRect):Void {
		this.id = rect.id;
		this.x = rect.x;
		this.y = rect.y;
		this.w = rect.w;
		this.h = rect.h;
		this.group = rect.group;
	}

	public inline function copy():WidgetRect {
		return new WidgetRect(id, x, y, w, h, group);
	}

}
