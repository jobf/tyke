package tyke;

import tyke.jam.Scene;
import tyke.Graphics;
import peote.view.PeoteView;
import lime.app.Application;

class App extends Application {
	public var core(default, null):AppCore;
	public var frames(default, null):TickCount;
	public var updates(default, null):TickCount;

	var config:AppConfig;
	var preloaderUi:PreloaderUi;
	var scene:Scene;

	var hasStarted:Bool;
	var isUpdating:Bool;

	public function new(config:AppConfig) {
		super();
		this.config = config;
		hasStarted = false;
		isUpdating = false;

		frames = {
			totalPassed: 0,
			totalElapsedMs: 0,
			elapsedMsSinceLast: 0,
			durationMs: Math.floor(1000 / this.config.framesPerSecond)
		}

		updates = {
			totalPassed: 0,
			totalElapsedMs: 0,
			elapsedMsSinceLast: 0,
			durationMs: Math.floor(1000 / this.config.updatesPerSecond)
		}
	}

	public function toggleUpdate(?setIsUpdatingTo:Bool) {
		if (setIsUpdatingTo != null) {
			isUpdating = setIsUpdatingTo;
		} else {
			isUpdating = !isUpdating;
		}
	}

	override function onWindowCreate() {
		// super.onWindowCreate();
		log('onWindowCreate');

		setupCore();

		preloaderUi = new PreloaderUi(core);
	}

	inline function setupCore() {
		core = {
			peoteView: new PeoteView(window),
			display: new Display(0, 0, config.screenWidth, config.screenHeight, config.backgroundColor),
			config: config,
			log: log
		};

		core.peoteView.addDisplay(core.display);
		core.peoteView.start();

		if (core.config.screenIsScaled) {
			setScreenZoom();
		}
	}

	inline function setScreenZoom() {
		// var ratio:Float = window.width / window.height;
		// var realRatio:Float = core.config.screenWidth / core.config.screenHeight;
		core.display.xZoom = Std.int(window.width / core.config.screenWidth);
		core.display.yZoom = Std.int(window.height / core.config.screenHeight);
		core.display.width = window.width;
		core.display.height = window.height;
	}

	override function update(deltaTime:Int) {
		// super.update(deltaTime);
		#if debugupdate
		log('update $deltaTime');
		#end

		if (!hasStarted)
			return;

		if (isUpdating) {
			if (tick(updates, deltaTime)) {
				scene.update(deltaTime / 1000);
			}

			if (tick(frames, deltaTime)) {
				scene.draw(deltaTime);
			}
		}
	}

	inline function tick(count:TickCount, deltaTime:Int):Bool {
		count.elapsedMsSinceLast += deltaTime;
		if (count.elapsedMsSinceLast >= count.durationMs) {
			count.elapsedMsSinceLast = 0;
			count.totalPassed++;
			return true;
		}
		return false;
	}

	public function changeScene(nextScene:Scene) {
		log('changeScene');

		if (scene != null) {
			scene.destroy();
			core.peoteView.stop();
			core.peoteView.removeDisplay(core.display);
			setupCore();
		}
		scene = nextScene;
		scene.create();
	}

	public function onPauseStart() {
		log('onPauseStart');
		if (!hasStarted)
			return;

		scene.onPauseStart();
	}

	public function onPauseEnd() {
		log('onPauseEnd');
		if (!hasStarted)
			return;

		scene.onPauseEnd();
	}

	override function onPreloadComplete() {
		// super.onPreloadComplete();
		log('onPreloadComplete');
		changeScene(core.config.initScene(this));
		hasStarted = true;
		isUpdating = true;
		log('scene initialized');
	}

	override function onPreloadProgress(loaded:Int, total:Int) {
		// super.onPreloadProgress(loaded, total);
		log('onPreloadProgress loaded $loaded $total');
		preloaderUi.onPreloadProgress(loaded, total);
	}

	override function onWindowFocusIn() {
		// super.onWindowFocusIn();
		log('onWindowFocusIn');
		if (!hasStarted)
			return;

		// resume update when has focus
		isUpdating = true;

		scene.onWindowFocusIn();
	}

	override function onWindowFocusOut() {
		// super.onWindowFocusOut();
		log('onWindowFocusOut');
		if (!hasStarted)
			return;

		// pause update when has focus
		isUpdating = false;
		scene.onWindowFocusOut();
	}

	override function onWindowLeave() {
		// super.onWindowLeave();
		log('onWindowLeave');
		if (!hasStarted)
			return;

		scene.onWindowLeave();
	}

	override function onWindowFullscreen() {
		// super.onWindowFullscreen();
		log('onWindowFullscreen');
		if (!hasStarted)
			return;

		scene.onWindowFullscreen();
	}

	override function onWindowMinimize() {
		// super.onWindowMinimize();
		log('onWindowMinimize');
		if (!hasStarted)
			return;

		scene.onWindowMinimize();
	}

	override function onWindowRestore() {
		// super.onWindowMinimize();
		log('onWindowRestore');
		if (!hasStarted)
			return;

		scene.onWindowRestore();
	}

	override function onWindowResize(width:Int, height:Int) {
		// super.onWindowMinimize();
		log('onWindowResize $width $height');
		if (!hasStarted)
			return;

		scene.onWindowResize(width, height);
	}

	override function onMouseMove(x:Float, y:Float) {
		// super.onMouseMove(x, y);
		#if debugmouse
		log('onMouseMove $x $y');
		#end

		if (!hasStarted)
			return;

		scene.onMouseMove(x, y);
	}

	override function onMouseUp(x:Float, y:Float, button:MouseButton) {
		// super.onMouseUp(x, y, button);
		#if debugmouse
		log('onMouseUp $x $y $button');
		#end

		if (!hasStarted)
			return;

		scene.onMouseUp(x, y, button);
	}

	override function onMouseDown(x:Float, y:Float, button:MouseButton) {
		// super.onMouseUp(x, y, button);
		#if debugmouse
		log('onMouseDown $x $y $button');
		#end

		if (!hasStarted)
			return;

		scene.onMouseDown(x, y, button);
	}

	override function onMouseWheel(deltaX:Float, deltaY:Float, deltaMode:MouseWheelMode) {
		// super.onMouseWheel(deltaX, deltaY, deltaMode);
		#if debugmouse
		log('onMouseDown $deltaX $deltaY $deltaMode');
		#end

		if (!hasStarted)
			return;

		scene.onMouseWheel(deltaX, deltaY, deltaMode);
	}

	inline function log(message:String) {
		trace('${timeStamp()} $message');
	}

	inline function timeStamp():String {
		return Date.now().toString();
	}
}

class PreloaderUi {
	var core:AppCore;

	public function new(core:AppCore) {
		this.core = core;
	}

	public function onPreloadProgress(loaded:Int, total:Int) {}
}

@:structInit
class AppConfig {
	public var screenWidth:Int;
	public var screenHeight:Int;
	public var screenIsScaled:Bool;
	public var backgroundColor:Color;
	public var updatesPerSecond:Int;
	public var framesPerSecond:Int;
	public var initScene:App->Scene;
}

@:structInit
class TickCount {
	public var totalPassed:Int;
	public var elapsedMsSinceLast:Int;
	public var totalElapsedMs:Int;
	public var durationMs:Int;
}

@:structInit
class AppCore {
	public var peoteView:PeoteView;
	public var config:AppConfig;
	public var display:Display;
	public var log:String->Void;

	public function getFrameBufferDisplay(x:Int, y:Int, w:Int, h:Int, isPersistentFrameBuffer:Bool):FrameBuffer {
		var display = new Display(x, y, w, h);
		peoteView.addDisplay(display);
		peoteView.renderToTexture(display, 0);
		peoteView.addFramebufferDisplay(display);
		var framebufferTexture = new Texture(w, h);
		framebufferTexture.clearOnRenderInto = !isPersistentFrameBuffer;
		display.setFramebuffer(framebufferTexture);
		peoteView.removeDisplay(display);
		return {display: display, texture: framebufferTexture};
	}
}


class PaletteExtensions {
	public static function toRGBA(rgb:Array<Int>):Array<Color> {
		return [for (c in rgb) RGBA(c)];
	}

	public static function RGBA(rgb:Int, a:Int = 0xff):Color {
		return rgb << 8 | a;
	}

	public static function extractAlpha(rgba:Int):Int {
		return rgba & 0x000000FF;
	}

	public static function changeAlpha(rgba:Int, a:Int):Int {
		var r = (rgba & 0xFF000000) >> 24;
		var g = (rgba & 0x00FF0000) >> 16;
		var b = (rgba & 0x0000FF00) >> 8;
		// trace('r: ${StringTools.hex(r)}');
		// trace('g: ${StringTools.hex(g)}');
		// trace('b: ${StringTools.hex(b)}');
		// trace('a: ${StringTools.hex(a)}');
		return r << 24 | (g << 16) | (b << 8) | a;
	}
}
