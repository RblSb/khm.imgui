package;

import kha.System;
import kha.Window;
import kha.CompilerDefines;
import kha.Assets;
#if kha_html5
import js.html.CanvasElement;
import js.Browser.document;
import js.Browser.window;
#end

class Main {

	static function main():Void {
		setFullWindowCanvas();
		System.start({title: "Empty", width: 800, height: 600}, function(window:Window) {
			Assets.loadEverything(init);
		});
	}

	static function init():Void {
		var demo = new demo.Gui();
		demo.show();
		demo.init();
	}

	static function setFullWindowCanvas():Void {
		#if kha_html5
		// make html5 canvas resizable
		document.documentElement.style.padding = "0";
		document.documentElement.style.margin = "0";
		document.body.style.padding = "0";
		document.body.style.margin = "0";
		var canvas:CanvasElement = cast document.getElementById(CompilerDefines.canvas_id);
		canvas.style.display = "block";

		var resize = function() {
			canvas.width = Std.int(window.innerWidth * window.devicePixelRatio);
			canvas.height = Std.int(window.innerHeight * window.devicePixelRatio);
			canvas.style.width = document.documentElement.clientWidth + "px";
			canvas.style.height = document.documentElement.clientHeight + "px";
		}
		window.onresize = resize;
		resize();
		#end
	}

}
