package samples;

import tyke.Traxe.GlyphTracker;
import tyke.Loop;

class TrackerLoop extends PhysicalStageLoop {
	public function new(assets:Assets) {
		super(assets);

		onInitComplete = () -> {
			var glyphrender = stage.createGlyphFramesLayer("tyktrak", assets.fontCache[0]);
			var cusorRender = stage.createEchoDebugLayer();
			if(cusorRender != null ){
				var numColumns = 64;
				glyphTracker = new GlyphTracker(glyphrender, cusorRender, numColumns, 64);

			}

			
			alwaysDraw = true;
			gum.toggleUpdate(true);

		};
	}

	override function onTick(deltaMs:Int):Bool {
		glyphTracker.onTick(deltaMs);
		return super.onTick(deltaMs);
	}

	override function onKeyDown(code:KeyCode, modifier:KeyModifier) {
		glyphTracker.onKeyDown(code, modifier);
		
	}
	var glyphTracker:GlyphTracker;
}

class TykTrak extends App {
	// var config:GlyphLoopConfig = {
	// 	numCellsWide: 40,
	// 	numCellsHigh: 40,
	// }
	override function init(window:Window, ?config:GumConfig) {
		super.init(window, {
			framesPerSecond: 30,
			drawOnlyWhenRequested: false,
			displayWidth: 800,
			displayHeight: 600,
			displayIsScaled: true
		});
		gum.changeLoop(new TrackerLoop(assets()));
	}

	function initLoop() {
		// override me
	}

	function assets() {
		return new Assets({
			fonts: ["assets/fonts/tiled/hack_ascii.json"],
			images: ["assets/images/bit-bonanza-food.png",]
		});
	}
}
/**


	class Template extends PhysicalStageLoop {
	public function new(assets:Assets) {
		super(assets);

		onInitComplete = () -> {
			glyphTracker = new GlyphTracker(10, 64, stage, assets.fontCache[0]);

			alwaysDraw = true;
			gum.toggleUpdate(true);
		};
	}

	override function onTick(deltaMs:Int):Bool {
		glyphTracker.onTick(deltaMs);
		return super.onTick(deltaMs);
	}

	var glyphTracker:GlyphTracker;
	}


**/
