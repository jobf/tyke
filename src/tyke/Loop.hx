package tyke;

import tyke.jam.SoundManager;
import echo.Echo;
import echo.World;
import tyke.Layers;
import tyke.Palettes;
import tyke.Keyboard;
import tyke.Glyph;
import tyke.Stage;

@:structInit
class Text {
	public var font:Font<FontStyle>;
	public var fontStyle:FontStyle;
	public var fontProgram:FontProgram<FontStyle>;
}

class Glyphs {
	public static function initText(?display:Display, font:Font<FontStyle>):Text {
		var fontStyle = font.createFontStyle();
		fontStyle.width = font.config.width;
		fontStyle.height = font.config.height;
		var fontProgram = font.createFontProgram(fontStyle);
		if (display != null) {
			display.addProgram(fontProgram);
		}
		return {
			font: font,
			fontStyle: fontStyle,
			fontProgram: fontProgram
		}
	}
}

class GlyphLoop extends PeoteViewLoop {
	public var layers(default, null):Array<GlyphGrid>;
	public var palette(default, null):Palette;

	var data:GlyphLoopConfig;
	var assets:Assets;
	var keyboard:KeyPresses<GlyphLoop>;
	var mouse:Mouse;
	final transparent:Int = 0x00000000;

	public var text:Text;

	var onInitComplete:Void->Void = () -> return;

	public function new(data:GlyphLoopConfig, assets:Assets, ?palette:Palette) {
		super();
		this.data = data;
		this.assets = assets;
		this.palette = palette != null ? palette : new Palette(Sixteen.Versitle.toRGBA());
		layers = [];
		keyboard = new KeyPresses<GlyphLoop>([]);
		mouse = new Mouse();
	}

	override function onInit(gum:Gum) {
		super.onInit(gum);

		// todo? more flexible font handling
		assets.Preload(() -> {
			text = Glyphs.initText(display, assets.fontCache[0]);
			display.addProgram(text.fontProgram);
			onInitComplete();
		});
	}

	var alwaysDraw:Bool = false;

	override public function onTick(tick:Int) {
		var requestDrawUpdate = false;
		for (l in layers) {
			l.onTick(tick);
			if (l.hasChanged) {
				requestDrawUpdate = true;
			}
		}

		return alwaysDraw || requestDrawUpdate;
	}

	override public function onDraw(tick:Int) {
		for (l in layers) {
			if (l.hasChanged) {
				// todo ? partial updates
				l.draw();
				l.hasChanged = false;
			}
		}
		text.fontProgram.updateAllGlyphes();
	}

	override public function onKeyDown(code:KeyCode, modifier:KeyModifier) {
		keyboard.handle(code, this);
	}

	override function onMouseDown(x:Float, y:Float, button:MouseButton) {
		mouse.onDown(x, y, button);
	}

	override function onMouseUp(x:Float, y:Float, button:MouseButton) {
		mouse.onUp(x, y, button);
	}

	override function onMouseMove(x:Float, y:Float) {
		mouse.onMove(x, y);
	}
}

class PhysicalStageLoop extends PeoteViewLoop {
	public var stage(default, null):Stage;
	public var world(default, null):World;
	public var soundManager(default, null):SoundManager;

	var onInitComplete:Void->Void;

	public var assets(default, null):Assets;
	public var keyboard(default, null):KeyPresses<PhysicalStageLoop>;
	public var width(default, null):Int;
	public var height(default, null):Int;

	var widthOverride(default, null):Null<Int>;
	var heightOverride(default, null):Null<Int>;

	public function new(assets:Assets, onInitComplete:Void->Void, ?width:Int, ?height:Int) {
		super();
		if (width != null) {
			widthOverride = width;
		}
		if (height != null) {
			heightOverride = height;
		}
		this.assets = assets;
		this.onInitComplete = onInitComplete;
		keyboard = new KeyPresses<PhysicalStageLoop>([]);
	}

	override function onInit(gum:Gum) {
		super.onInit(gum);

		assets.Preload(() -> {
			initWorldAndStage();
			onInitComplete();
		});
	}

	function initWorldAndStage():Void {
		width = widthOverride == null ? display.width : widthOverride;
		height = heightOverride == null ? display.height : heightOverride;
		stage = new Stage(display, this, width, height);
		trace('initialized stage $width $height');
		world = Echo.start({
			width: width,
			height: height,
			gravity_y: 100,
			iterations: 2
		});
		trace('initialized echo $width $height');
	}

	var alwaysDraw:Bool = false;

	override function onPreloadComplete() {
		super.onPreloadComplete();
		this.soundManager = new SoundManager();
	}

	override public function onTick(tick:Int) {
		var requestDrawUpdate = false;

		return alwaysDraw || requestDrawUpdate;
	}

	override public function onUpdate(deltaMs:Int) {
		// trace('world step $deltaMs');
		world.step(deltaMs / 1000);
		if(this.soundManager != null){
			this.soundManager.update(deltaMs / 1000);
		}
	}

	override public function onDraw(deltaMs:Int) {
		// trace('draw');
		stage.updateGraphicsBuffers();
	}

	override public function onKeyDown(code:KeyCode, modifier:KeyModifier) {
		keyboard.handle(code, this);
	}
}

class CountDownInt {
	var duration:Int;
	var countDown:Int;
	var onComplete:() -> Void;
	var restartWhenComplete:Bool;

	public function new(durationTicks:Int, onComplete:Void->Void, restartWhenComplete:Bool = false) {
		this.duration = durationTicks;
		this.countDown = durationTicks;
		this.onComplete = onComplete;
		this.restartWhenComplete = restartWhenComplete;
	}

	public function update(elapsedTicks:Int) {
		countDown -= elapsedTicks;
		if (countDown <= 0) {
			onComplete();
			if (restartWhenComplete) {
				countDown = duration;
			}
		}
	}

	public function changeDuration(duration:Int) {
		this.duration = duration;
		onComplete();
		countDown = duration;
	}

	public function restart() {
		countDown = duration;
	}
}

class CountDown {
	var duration:Float;
	var countDown:Float;
	var onComplete:() -> Void;
	var restartWhenComplete:Bool;

	public function new(durationSeconds:Float, onComplete:Void->Void, restartWhenComplete:Bool = false) {
		this.duration = durationSeconds;
		this.onComplete = onComplete;
		this.restartWhenComplete = restartWhenComplete;
		this.countDown = durationSeconds;
	}

	public function update(elapsedSeconds:Float) {
		countDown -= elapsedSeconds;
		if (countDown <= 0) {
			onComplete();
			if (restartWhenComplete) {
				reset();
			}
		}
	}

	public inline function reset() {
		countDown = duration;
	}
}

class Extensions {
	public static inline function int(f:Float) {
		return Std.int(f);
	};
}
