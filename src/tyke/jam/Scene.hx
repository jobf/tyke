package tyke.jam;

import tyke.App;

class Scene {
	var app:App;
	var width:Int;
	var height:Int;

	public var backgroundColor(default, null):Color;

	public function new(app:App, backgroundColor:Color = 0x000000ff, width:Int = 0, height:Int = 0) {
		this.app = app;
		this.backgroundColor = backgroundColor;
		app.core.display.color = backgroundColor;
		this.width = width;
		this.height = height;
		// if (width > 0) {
		// 	app.core.config.screenWidth = width;
		// 	// app.core.display.width = width;
		// }
		// if (height > 0) {
		// 	app.core.config.screenHeight = height;
		// 	// app.core.display.height = height;
		// }
	}

	public function create() {
		app.core.log('Scene.create');
	}

	public function destroy() {
		app.core.log('Scene.destroy');
	}

	public function update(elapsedSeconds:Float) {
		#if debugupdate
		app.core.log('Scene.update $elapsedSeconds');
		#end
	}

	public function draw(deltaTime:Int) {
		#if debugupdate
		app.core.log('Scene.draw $deltaTime');
		#end
	}

	public function onPauseStart() {}

	public function onPauseEnd() {}

	public function onMouseMove(x:Float, y:Float) {}

	public function onMouseDown(x:Float, y:Float, button:MouseButton) {}

	public function onMouseUp(x:Float, y:Float, button:MouseButton) {}

	public function onMouseScroll(deltaX:Float, deltaY:Float, wheelMode:MouseWheelMode) {}

	public function onWindowFocusIn() {}

	public function onWindowFocusOut() {}

	public function onWindowLeave() {}

	public function onWindowFullscreen() {}

	public function onWindowMinimize() {}

	public function onWindowRestore() {}

	public function onWindowResize(width:Int, height:Int) {}

	public function onMouseWheel(deltaX:Float, deltaY:Float, deltaMode:MouseWheelMode) {}
}
