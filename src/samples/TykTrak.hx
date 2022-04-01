package samples;

import ob.traxe.Tracker;
import tyke.Traxe;
import ob.seq.Metronome;
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

			var headsRender = stage.createShapeRenderLayer();
			var glyphrender = stage.createGlyphFramesLayer("tyktrak", assets.fontCache[0]);
			var cusorRender = stage.createShapeRenderLayer();
			var canvas = stage.createShapeRenderLayer();
			var circle = canvas.makeShape(stage.centerX(), stage.centerY(), 42, 42, CIRCLE, Color.WHITE);
			
			var numGridColumns = 64;
			timeContext = new DeltaTimeContext();
			audioContext = new NullAudioContext();
			tracker = new Tracker(timeContext, audioContext);

			glyphTracker = new GlyphTracker(glyphrender, cusorRender, headsRender, numGridColumns, 64, tracker);

			var track:TrackDefinition = {
				label: "Circle",
				lanes: [{
					parameter: {
						name: "Y axis",
						id: 1,
						type: ParameterType.PERCENT,
						minimumValue: Std.int(circle.h * 0.5),
						maximumValue: Std.int(stage.height - circle.h + (circle.h * 0.5)),
						onTrigger: value -> {
							circle.y = value;
						}
					},
					laneType: Parameter
				},
				{
					parameter: {
						name: "x axis",
						id: 2,
						type: ParameterType.PERCENT,
						minimumValue: Std.int(circle.w * 0.5),
						maximumValue: Std.int(stage.width - circle.w + (circle.w * 0.5)),
						onTrigger: value -> {
							circle.x = value;
						}
					},
					laneType: Parameter
				},
				{
					parameter: {
						name: "radius",
						id: 3,
						type: ParameterType.PERCENT,
						minimumValue: 0,
						maximumValue: 255,
						onTrigger: value -> {
							circle.w = value;
						}
					},
					laneType: Parameter
				},
				{
					parameter: {
						name: "red",
						id: 3,
						type: ParameterType.PERCENT,
						minimumValue: 0,
						maximumValue: 255,
						onTrigger: value -> {
							circle.color.r = value;
						}
					},
					laneType: Parameter
				},
				{
					parameter: {
						name: "green",
						id: 3,
						type: ParameterType.PERCENT,
						minimumValue: 0,
						maximumValue: 255,
						onTrigger: value -> {
							circle.color.g = value;
						}
					},
					laneType: Parameter
				},
				{
					parameter: {
						name: "blue",
						id: 3,
						type: ParameterType.PERCENT,
						minimumValue: 0,
						maximumValue: 255,
						onTrigger: value -> {
							circle.color.b = value;
						}
					},
					laneType: Parameter
				}],
				numRows: 16
			}

			glyphTracker.addTrack(track);
			
			keyboard.bind(KeyCode.R, "RUN", "Toggle time running", loop -> {
				trace('r');
				glyphTracker.toggleRunning();
			});

			alwaysDraw = true;
			gum.toggleUpdate(true);
		};
	}

	
	override function onUpdate(deltaMs:Int) {
		super.onUpdate(deltaMs);
		timeContext.update(deltaMs);
	}

	override function onTick(deltaMs:Int):Bool {
		glyphTracker.onTick(deltaMs);
		return super.onTick(deltaMs);
	}

	override function onKeyDown(code:KeyCode, modifier:KeyModifier) {
		glyphTracker.onKeyDown(code, modifier);
		super.onKeyDown(code, modifier);
	}

	var glyphTracker:GlyphTracker;

	var timeContext:DeltaTimeContext;

	var audioContext:NullAudioContext;

	var tracker:Tracker;
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
