package samples;

import ob.traxe.ParameterDefinitions.ParameterLaneDef;
import ob.parameters.Parameter;
import ob.traxe.Track;
import ob.parameters.ParameterType;
import ob.traxe.Track;
import tyke.Traxe.GlyphTracker;
import tyke.Loop;

class TrackerLoop extends PhysicalStageLoop {
	public function new(assets:Assets) {
		super(assets);

		onInitComplete = () -> {
			if (assets.fontCache.length == 0) {
				throw "No font no fun!";
			}

			var glyphrender = stage.createGlyphFramesLayer("tyktrak", assets.fontCache[0]);
			var cusorRender = stage.createShapeRenderLayer();
			var canvas = stage.createShapeRenderLayer();
			var circle = canvas.makeShape(stage.centerX(), stage.centerY(), 42, 42, CIRCLE, Color.WHITE);
			var numColumns = 64;
			glyphTracker = new GlyphTracker(glyphrender, cusorRender, numColumns, 64);

			var track:TrackDefinition = {
				label: "Circle",
				lanes: [{
					parameter: {
						name: "Y axis",
						id: 2,
						type: ParameterType.PERCENT,
						minimumValue: Std.int(circle.h * 0.5),
						maximumValue: Std.int(stage.height - circle.h + (circle.h * 0.5)),
						onTrigger: value -> {
							circle.y = value;
						}
					},
					laneType: Parameter
				}],
				numRows: 64
			}

			glyphTracker.addTrack(track);

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
