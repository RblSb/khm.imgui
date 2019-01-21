package khm.imgui;

typedef Pointer = {
	// pointer id (0 - 9)
	id:Int,
	// initial cords of pressing
	startX:Int,
	startY:Int,
	x:Int,
	y:Int,
	// last pointer speed
	moveX:Int,
	moveY:Int,
	// button type (for mouse)
	type:Int,
	isDown:Bool,
	// pointer is touch surface
	isTouch:Bool,
	// pointer already used
	isActive:Bool
}
