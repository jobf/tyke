package samples;

import tyke.Traxe;
import echo.data.Options.BodyOptions;
import tyke.Echo;
import tyke.Palettes.Sixteen;
import echo.Body;
import echo.World;
import echo.Echo;
import tyke.Sprites;
import tyke.Layers;
import tyke.Loop;
import tyke.Glyph;
import tyke.Stage;

// todo ?	TYKE need not extend GlyphLoop as it uses stage for layer management
//			make a StageLoop instead?
class WorldStageLoop extends GlyphLoop {
	var stage:Stage;
	var world:World;

	public function new(assets:Assets) {
		super({
			numCellsWide: 10,
			numCellsHigh: 10
		}, assets);
	}

	function initWorldAndStage() {
		stage = new Stage(display, this);
		world = Echo.start({
			width: display.width,
			height: display.height,
			gravity_y: 100,
			iterations: 2
		});
	}


	override function onDraw(deltaMs:Int) {
		world.step(deltaMs / 1000);
		stage.updateGraphicsBuffers();
	}
}

class TYKE extends WorldStageLoop {
	public function new(data:GlyphLoopConfig, assets:Assets) {
		super(assets);
		onInitComplete = () -> {
			initWorldAndStage();
			begin(data.numCellsWide, data.numCellsHigh);
		}

		keyboard.bind(KeyCode.P, "PAUSE", "TOGGLE UPDATE", loop -> {
			gum.toggleUpdate();
		});
	}

	function begin(numColumns:Int, numRows:Int) {

		final injectTimeUniform = true;
		var hues = new Filter(stage.width, stage.height, ColorFilterFormulas.Hues, injectTimeUniform);
		var bgLayer = stage.createLayer("bg");
		hues.addToDisplay(bgLayer.display);

		var totalColumns = Math.ceil(stage.width  / assets.fontCache[0].config.width);
		var totalRows = Math.ceil(stage.height  / assets.fontCache[0].config.height);
		soup = new WordSoup(totalColumns, totalRows, stage, assets.fontCache[0]);
		salad = new SimulationSalad(world, stage, assets.imageCache[0]);

		// this filter should appear as separate layer with 'frameBuffer' behind it
		// that was possible when all layers had their own texture being mixed
		// currently does not work
		var useGlobalFrameBuffer = false;
		var curtainLayer = stage.createLayer("curtain", useGlobalFrameBuffer);
		var curtainFilter = new Filter(stage.width, stage.height, ColorFilterFormulas.Gradient);
		curtainFilter.addToDisplay(curtainLayer.display);

		// set up global shader with reference to teh gloabl frame buffer texture
		stage.globalFilter("globalCompose(frameBuffer_ID)", FrameBufferFormulas.DotScreen);

		alwaysDraw = true;
		gum.toggleUpdate(true);
	}

	override function onTick(deltaMs:Int):Bool {
		soup.onTick(deltaMs);
		salad.onTick(deltaMs);
		return super.onTick(deltaMs);
	}

	override function onDraw(deltaMs:Int) {
		super.onDraw(deltaMs);
	}

	var salad:SimulationSalad;
	var soup:WordSoup;
}

class WordSoup {
	var word:String = "TYKE";
	var stage:Stage;

	public final layerName = "glyphs";

	public function new(numColumns:Int, numRows:Int, stage:Stage, font:Font<FontStyle>) {
		glyphFrames = stage.createGlyphFramesLayer(layerName, font);
		var fontProgram = glyphFrames.fontProgram;
		var config:GlyphLayerConfig = {
			numColumns: numColumns,
			numRows: numRows,
			cellWidth: Math.ceil(fontProgram.fontStyle.width),
			cellHeight: Math.ceil(fontProgram.fontStyle.height),
			palette: new Palette(Sixteen.Versitle.toRGBA()),
			cellInit: (col, row) -> {
				var charIndex = randomInt(word.length) - 1;
				// trace(rng);
				var charCode = word.charCodeAt(charIndex);
				var x = col * fontProgram.fontStyle.width;
				var y = row * fontProgram.fontStyle.height;
				return {
					char: 0,
					glyph: fontProgram.createGlyph(charCode, x, y, fontProgram.fontStyle),
					paletteIndexFg: 4,
					paletteIndexBg: -1,
					bgIntensity: 1.0,
				}
			}
		}
		var tnt = new Traxe();
		glyphs = new GlyphLayer(config, fontProgram);
	}

	var waves = 2;
	var gain = 0.02;
	var elapsedTicks:Int = 0;

	public function onTick(deltaMs:Int):Void {
		elapsedTicks++;
		glyphs.forEach((c, r, cell) -> {
			var R = 0.5 + 0.5 * Math.cos(elapsedTicks + c + 0);
			var G = 0.5 + 0.5 * Math.cos(elapsedTicks + r + 2);
			var B = 0.5 + 0.5 * Math.cos(elapsedTicks + c + 4);
			cell.glyph.color.r = Math.ceil(255 * R);
			cell.glyph.color.g = Math.ceil(255 * G);
			cell.glyph.color.b = Math.ceil(255 * B);
			cell.glyph.color.alpha = Math.ceil(127 * Math.sin(c - r * waves * elapsedTicks * gain) + 127);
			var CI = 0.5 + 0.5 * Math.sin((elapsedTicks * 0.3) + c + 4);
			var charIndex = Math.ceil(CI * (word.length)) - 1;
			cell.char = word.charCodeAt(charIndex);
			glyphFrames.fontProgram.glyphSetChar(cell.glyph, cell.char);
		});
	}

	var glyphs:GlyphLayer;
	var glyphFrames:GlyphFrames;
}

class SimulationSalad {
	var stage:Stage;
	var world:World;
	var sprites:Array<Sprite>;
	var spriteFrames:SpriteFrames;
	final frameSize:Int = 10;
	var debugLayer:DrawShapes;

	public function new(world:World, stage:Stage, spriteSheet:Image) {
		this.world = world;
		this.stage = stage;
		this.sprites = [];
		initSprites(spriteSheet);
		initEdges();
		initCollisionListeners();
	}

	public final layerName = "sprites";

	function initSprites(spriteSheet:Image) {
		spriteFrames = stage.createSpriteFramesLayer(layerName, spriteSheet, frameSize);
		debugLayer = stage.createShapeRenderLayer();
	}

	function initEdges() {
		var edgeThickness = 40;
		// top
		makeEdge(Std.int(stage.width * 0.5), 0, stage.width + (edgeThickness * 2), edgeThickness);
		// bottom
		makeEdge(Std.int(stage.width * 0.5), stage.height, stage.width + (edgeThickness * 2), edgeThickness);
		// left
		makeEdge(edgeThickness - Std.int(edgeThickness * 0.5), Std.int(stage.height * 0.5), edgeThickness, stage.height + (edgeThickness * 2));
		// right
		// makeEdge(stage.width + Std.int(edgeThickness * 0.5), Std.int(stage.height * 0.5), edgeThickness, stage.height + (edgeThickness * 2));
	}

	function makeEdge(x:Int, y:Int, w:Int, h:Int) {
		var options:BodyOptions = {
			shape: {
				type: RECT,
				width: w,
				height: h
			},
			mass: 0, // mass of 0 is unmovable
			x: x,
			y: y,
			elasticity: 2.0,
		};
		var body = world.make(options);
		final debug = false;

		if (debug) {
			var d = debugLayer.makeShape(options, RECT);
		}
	}

	function initCollisionListeners() {
		final minTileIndex = 4;
		final maxTileIndex = 34 - minTileIndex;

		world.listen({
			enter: (body1:Body, body2:Body, array) -> {
				// trace('$body1 $body2');
				if (body1.sprite != null) {
					// set random frame from sprite sheet
					body1.sprite.tile = randomInt(maxTileIndex) + minTileIndex;
					// if it's not already rotating, or if chance is true, increase rotation clockwise
					if (body1.rotational_velocity != 0 || randomChance()) {
						var minRotation = body1.mass * 10;
						body1.rotational_velocity -= randomFloat(minRotation, minRotation + 10);
					}
					// if colliding with another sprite, spritesheet frame 'rubs off'
					if (body2.sprite != null) {
						body2.sprite.tile = body1.sprite.tile;
					}
				}
			}
		});
	}

	var timer = 0;
	var colliders:Array<Body> = [];

	public function onTick(deltaMs:Int) {
		for (c in colliders) {
			if (c.x > stage.width + 100) {
				c.active = false;
				// todo recycle bodies/sprites
			}
		}
		final wait = 750 - randomInt(300);
		timer += deltaMs;
		if (timer > wait) {
			var collider = makeCollider(50, 50);
			colliders.push(collider);
			launch(world.add(collider), world, false);
			timer = 0;
		}
	}

	inline function launch(b:Body, w:World, left:Bool) {
		b.set_position(left ? 20 : w.width - 20, w.height / 2);
		var velocityX = -3000;
		var velocityY = 3000;
		b.velocity.set(velocityX, velocityY);
	}

	final spriteScale:Int = 3;

	inline function attachSprite(body:Body, options:BodyOptions, tileIndex:Int = 0):Sprite {
		var sprite:Sprite = spriteFrames.makeSprite(-100, -100, Std.int(options.shape.width * spriteScale), tileIndex);
		body.on_move = (x, y) -> {
			sprite.move(x, y);
			// sprite.x = x;
			// sprite.y = y;
		};

		body.on_rotate = rotation -> {
			sprite.rotate(rotation);
			// sprite.rotation = rotation;
		};

		body.sprite = sprite;
		final debug = false;
		if (debug) {
			sprite.attachDebug(debugLayer.makeShape(options, RECT));
		}
		return sprite;
	}

	inline function makeCollider(width:Int, height):Body {
		var options:BodyOptions = {
			elasticity: 0.5,
			mass: 10 - randomInt(5),
			x: -100,
			y: -100,
			max_velocity_x: 9000,
			max_velocity_y: 9000,
			max_rotational_velocity: 200,
			shape: {
				type: RECT,
				width: width,
				height: height
			},
		};
		var body = new Body(options);
		var sprite:Sprite = attachSprite(body, options, 4);
		sprite.c.alpha = Math.ceil(95 * (5 / body.mass)) + 160;
		sprites.push(sprite);
		return body;
	}
}
