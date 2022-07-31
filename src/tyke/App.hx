package tyke;

import tyke.jam.Scene;
import peote.view.PeoteView;
import lime.app.Application;


class PreloaderUi {
	var appCore:AppCore;

	public function new(appCore:AppCore) {
		this.appCore = appCore;
	}

	public function onPreloadProgress(loaded:Int, total:Int) {}
}

@:structInit
class AppConfig {
	public var screenWidth:Int;
	public var screenHeight:Int;
	public var backgroundColor:Color;
	public var initScene:Tyke->Scene;
}

@:structInit
class AppCore {
	public var peoteView:PeoteView;
	public var config:AppConfig;
	public var display:Display;
	public var log:String->Void;
}

class Tyke extends Application {
	public var appCore(default, null):AppCore;
	var config:AppConfig;
	var preloaderUi:PreloaderUi;
	var scene:Scene;

	public function new(config:AppConfig) {
		super();
		this.config = config;
	}

	override function onWindowCreate() {
		// super.onWindowCreate();
		log('onWindowCreate');

		appCore = {
			peoteView: new PeoteView(window),
			display: new Display(0, 0, config.screenWidth, config.screenHeight, config.backgroundColor),
			config: config,
			log: log
		};

		preloaderUi = new PreloaderUi(appCore);
	}

	override function onPreloadComplete() {
		// super.onPreloadComplete();
		log('onPreloadComplete');
		scene = appCore.config.initScene(this);
	}

	override function onPreloadProgress(loaded:Int, total:Int) {
		// super.onPreloadProgress(loaded, total);
		log('onPreloadProgress loaded $loaded $total');
		preloaderUi.onPreloadProgress(loaded, total);
	}

	override function onWindowFocusIn() {
		// super.onWindowFocusIn();
		log('onWindowFocusIn');
		scene.onWindowFocusIn();
	}

	override function onWindowFocusOut() {
		// super.onWindowFocusOut();
		log('onWindowFocusOut');
		scene.onWindowFocusOut();
	}

	override function onWindowLeave() {
		// super.onWindowLeave();
		log('onWindowLeave');
		scene.onWindowLeave();
	}

	override function onWindowFullscreen() {
		// super.onWindowFullscreen();
		log('onWindowFullscreen');
		scene.onWindowFullscreen();
	}

	override function onWindowMinimize() {
		// super.onWindowMinimize();
		log('onWindowMinimize');
		scene.onWindowMinimize();
	}

	override function onWindowRestore() {
		// super.onWindowMinimize();
		log('onWindowRestore');
		scene.onWindowRestore();
	}

	override function onWindowResize(width:Int, height:Int) {
		// super.onWindowMinimize();
		log('onWindowResize $width $height');
		scene.onWindowResize(width, height);
	}

	override function onMouseMove(x:Float, y:Float) {
		// super.onMouseMove(x, y);
		log('onWindowResize $x $y');
		scene.onMouseMove(x, y);
	}

	override function onMouseUp(x:Float, y:Float, button:MouseButton) {
		// super.onMouseUp(x, y, button);
		log('onMouseUp $x $y $button');
		scene.onMouseUp(x, y, button);
	}

	override function onMouseDown(x:Float, y:Float, button:MouseButton) {
		// super.onMouseUp(x, y, button);
		log('onMouseDown $x $y $button');
		scene.onMouseDown(x, y, button);
	}

	override function onMouseWheel(deltaX:Float, deltaY:Float, deltaMode:MouseWheelMode) {
		// super.onMouseWheel(deltaX, deltaY, deltaMode);
		log('onMouseDown $deltaX $deltaY $deltaMode');
		scene.onMouseWheel(deltaX, deltaY, deltaMode);
	}

	inline function log(message:String) {
		trace('${timeStamp()} $message');
	}

	inline function timeStamp():String {
		return Date.now().toString();
	}

	public function changeScene(nextScene:Scene) {
		log('changeScene');
		scene.destroy();
		scene = nextScene;
		scene.create();
	}
}
