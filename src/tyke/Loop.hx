package tyke;

import echo.Echo;
import echo.World;
import tyke.Layers;
import tyke.Palettes;
import tyke.Keyboard;
import tyke.Glyph;
import tyke.Stage;

typedef Text = {font:Font<FontStyle>, fontStyle:FontStyle, fontProgram:FontProgram<FontStyle>}

class Glyphs {
	public static function initText(?display:Display, font:Font<FontStyle>):Text {
		var fontStyle = font.createFontStyle();
		fontStyle.width = font.config.width;
		fontStyle.height = font.config.height;
		var fontProgram = font.createFontProgram(fontStyle);
		if(display != null){
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
	public var layers(default, null):Array<GlyphLayer>;
	public var palette(default, null):Palette;

	var data:GlyphLoopConfig;
	var assets:Assets;
	var keyboard:KeyPresses<GlyphLoop>;
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
		text.fontProgram.updateGlyphes();
	}

	override public function onKeyDown(code:KeyCode, modifier:KeyModifier) {
		keyboard.handle(code, this);
	}

}


class PhysicalStageLoop extends PeoteViewLoop
{
	var stage:Stage;
	var world:World;
	var onInitComplete:Void->Void = () -> throw "You must set onInitComplete function!";
	var assets:Assets;
	var keyboard:KeyPresses<PhysicalStageLoop>;

	public function new(assets:Assets) {
		super();
		this.assets = assets;
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
		stage = new Stage(display, this);
		world = Echo.start({
			width: display.width,
			height: display.height,
			gravity_y: 100,
			iterations: 2
		});
	}

	var alwaysDraw:Bool = false;

	override public function onTick(tick:Int) {
		var requestDrawUpdate = false;
		

		return alwaysDraw || requestDrawUpdate;
	}

	override public function onDraw(deltaMs:Int) {
		world.step(deltaMs / 1000);
		stage.updateGraphicsBuffers();
	}

	override public function onKeyDown(code:KeyCode, modifier:KeyModifier) {
		keyboard.handle(code, this);
	}
}