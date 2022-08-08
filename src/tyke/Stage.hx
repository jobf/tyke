package tyke;

import lime.utils.Assets;
import tyke.App;
import tyke.Keyboard;
import tyke.Echo;
import tyke.Graphics;
import tyke.Glyph;

class Stage {
	var core:AppCore;

	public var program(default, null):Program;

	var globalFrameBuffer:FrameBuffer;
	var sprites:Array<SpriteRenderer> = [];
	var layers:Map<String, Layer> = [];
	var view:ViewElement;
	var buffer:Buffer<ViewElement>;

	public var width(default, null):Int;
	public var height(default, null):Int;

	public function new(core:AppCore, width:Int, height:Int) {
		this.core = core;
		this.width = width;
		this.height = height;
		buffer = new Buffer<ViewElement>(1);
		program = new Program(buffer);
		program.setFragmentFloatPrecision("high");
		program.alphaEnabled = true;
		program.discardAtAlpha(null);
		core.display.addProgram(program);
		view = new ViewElement(0, 0, this.width, this.height);
		buffer.addElement(view);
		final isGlobalFrameBufferPersistent = false;
		globalFrameBuffer = makeFrameBuffer("globalFramebuffer", isGlobalFrameBufferPersistent, this.core.config.screenWidth, this.core.config.screenHeight);
	}

	public function globalFilter(formula:String, inject:String) {
		program.injectIntoFragmentShader(inject, true);
		program.setColorFormula(formula);
	}

	function chainFrameBuffer(frameBuffer:FrameBuffer, name:String) {
		program.addTexture(frameBuffer.texture, name, true);
	}

	function makeFrameBuffer(name:String, isPersistent:Bool, width:Int, height:Int):FrameBuffer {
		var frameBuffer = core.getFrameBufferDisplay(core.display.x, core.display.y, width, height, isPersistent);
		chainFrameBuffer(frameBuffer, name);
		return frameBuffer;
	}

	public function createLayer(name:String, width:Int, height:Int, isPersistentFrameBuffer:Bool, useGlobalFrameBuffer:Bool = true):Layer {
		var shouldMakeFrameBuffer = useGlobalFrameBuffer || (width > 0 || height > 0);
		var w = width == 0 ? core.display.width : width;
		var h = height == 0 ? core.display.height : height;
		var fb = shouldMakeFrameBuffer ? globalFrameBuffer : makeFrameBuffer(name, isPersistentFrameBuffer, w, h);
		var layer = new Layer(fb);
		layers[name] = layer;
		return layer;
	}

	function initGraphicsBuffer(name:String, buffer:IHaveGraphicsBuffer, isPersistentFrameBuffer:Bool, isIndividualFrameBuffer:Bool, width:Int, height:Int) {
		var layer = createLayer(name, width, height, isPersistentFrameBuffer, !isIndividualFrameBuffer);
		layer.registerGraphicsBuffer(buffer);
		layer.addProgramToFrameBuffer(buffer.program);
		layers[name] = layer;
	}

	public function createShapeRenderLayer(name:String, isPersistentFrameBuffer:Bool = false, isIndividualFrameBuffer:Bool = false, width:Int = 0, height:Int = 0):ShapeRenderer {
		var frames = new ShapeRenderer();
		initGraphicsBuffer(name, frames, isPersistentFrameBuffer, isIndividualFrameBuffer, width, height);
		return frames;
	}

	public function createRectangleRenderLayer(name:String, isPersistentFrameBuffer:Bool = false, isIndividualFrameBuffer:Bool = false, width:Int = 0, height:Int = 0):RectangleRenderer {
		var frames = new RectangleRenderer();
		initGraphicsBuffer(name, frames, isPersistentFrameBuffer, isIndividualFrameBuffer, width, height);
		return frames;
	}

	public function createSpriteRendererLayer(name:String, image:Image, frameSizeW:Int, frameSizeH:Int, isPersistentFrameBuffer:Bool = false, isIndividualFrameBuffer:Bool = false, width:Int = 0, height:Int = 0):SpriteRenderer {
		var frames = new SpriteRenderer(image, frameSizeW, frameSizeH);
		initGraphicsBuffer(name, frames, isPersistentFrameBuffer, isIndividualFrameBuffer, width, height);
		return frames;
	}

	public function createSpriteRendererFor(assetPath:String, tileWidth:Int, tileHeight:Int, isIndividualFrameBuffer:Bool = false, width:Int = 0, height:Int = 0, nameOverride:String = ""):SpriteRenderer {
		var image = Assets.getImage(assetPath);
		var name = nameOverride.length > 0 ? nameOverride : assetPath;
		return createSpriteRendererLayer(name, image, tileWidth, tileHeight, isIndividualFrameBuffer, width, height);
	}

	public function createGlyphRendererLayer(name:String, font:Font<FontStyle>, isPersistentFrameBuffer:Bool = false, isIndividualFrameBuffer:Bool = false, width:Int = 0, height:Int = 0):GlyphRenderer {
		var frames = new GlyphRenderer(font);
		initGraphicsBuffer(name, frames, isPersistentFrameBuffer, isIndividualFrameBuffer, width, height);
		return frames;
	}

	public function updateGraphicsBuffers() {
		for (layer in layers) {
			layer.updateGraphicsBuffers();
		}
	}

	public function centerX():Float {
		return width * 0.5;
	}

	public function centerY():Float {
		return height * 0.5;
	}

	public function setZoom(z:Int) {
		core.display.set_zoom(z);
	}

	public function setScroll(x:Int, y:Int) {
		view.x = x;
		view.y = y;
		buffer.update();
		// set_x and set_ xOffset are reverse of each other?
		// display.set_x(x);
		// display.set_y(y);
		// display.set_xOffset(x);
		// display.set_yOffset(y);
	}

	public function getLayer(name:String) {
		return layers[name];
	}

	public function getTime():Float {
		return core.peoteView.get_time();
	}
}

class ViewElement implements Element {
	@posX public var x:Int = 0;
	@posY public var y:Int = 0;

	@sizeX var w:Int;
	@sizeY var h:Int;

	public function new(positionX:Int = 0, positionY:Int = 0, width:Int, height:Int) {
		this.x = positionX;
		this.y = positionY;
		this.w = width;
		this.h = height;
	}
}

typedef IsComplete = Bool;

@:structInit
class GranularAction {
	public var isEnabled:Bool;
	public var perform:Int->IsComplete;
}

class Tweens {
	var actions:Array<GranularAction>;

	public function new() {
		actions = [];
	}

	public function update(tick:Int) {
		for (a in actions) {
			if (a.isEnabled) {
				a.isEnabled = !a.perform(tick);
			}
		}
	}

	public function add(action:GranularAction) {
		actions.push(action);
	}

	public static var linear:(time:Float, begin:Float, change:Float,
		duration:Float) -> Float = (time, begin, change, duration) -> return change * time / duration + begin;
}

@:structInit
class AnimationConfig {
	public var tileIndexes:Array<Int>;
	public var speed:Int;
	public var isLooped:Bool;
}

class Animation {
	public var frameCollections(default, null):Map<Int, AnimationConfig>;
	public var frameIndex(default, null):Int;
	public var currentAnimation(default, null):Int;

	var spriteSheetColumns:Int;

	var onAdvance:Animation->Void;

	public function new(spriteSheetColumns:Int, ?frameCollections:Map<Int, AnimationConfig>, startIndex:Int = 0, ?onAdvance:Animation->Void) {
		this.spriteSheetColumns = spriteSheetColumns;
		this.frameCollections = frameCollections == null ? [] : frameCollections;
		this.spriteSheetColumns = spriteSheetColumns;
		frameIndex = startIndex;
		this.onAdvance = onAdvance;
	}

	public function defineFrames(key:Int, rowIndex:Int, columnIndex:Int, numFrames:Int, isLooped:Bool = true, speed:Int = 1) {
		var firstFrame = (rowIndex * spriteSheetColumns) + columnIndex;
		var lastFrame = firstFrame + numFrames;
		var config:AnimationConfig = {
			tileIndexes: [for (i in firstFrame...lastFrame) i],
			speed: speed,
			isLooped: isLooped
		};

		frameCollections[key] = config;
	}

	public function advance() {
		if (frameCollections.exists(currentAnimation)) {
			if (onAdvance != null) {
				onAdvance(this);
			}
			if (frameCollections[currentAnimation].isLooped) {
				if (frameIndex < frameCollections[currentAnimation].tileIndexes.length)
					frameIndex++;
				frameIndex = frameIndex % frameCollections[currentAnimation].tileIndexes.length;
			}
		}
		// if (frameIndex > frames.length - 1) {
		// 	frameIndex = 0;
		// }
	}

	public function addAnimation(name:Int, config:AnimationConfig) {
		frameCollections[name] = config;
	}

	public function setAnimation(key:Int, ?speed:Int = null) {
		currentAnimation = key;
		frameIndex = 0;
		// onAdvance(this);
	}

	public function currentTile():Int {
		return frameCollections[currentAnimation].tileIndexes[frameIndex];
	}
}

class Camera {
	public var body(default, null):Body;

	public function new(onMove:(x:Float, y:Float) -> Void) {
		body = new Body({
			shape: {
				width: 1,
				height: 1,
			},
			kinematic: true,
			mass: 1,
			x: 0,
			y: 0,
		});

		body.on_move = onMove;
	}

	var onMove:(x:Float, y:Float) -> Void;
}
