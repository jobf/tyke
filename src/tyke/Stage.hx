package tyke;

import tyke.Keyboard;
import tyke.Echo;
import tyke.Sprites;

class Stage {
	var display:Display;
	var program:Program;
	var globalFrameBuffer:FrameBuffer;
	var coreLoop:PeoteViewLoop;
	var sprites:Array<SpriteFrames> = [];
	var layers:Map<String, Layer> = [];
	public var width(get, null):Int;
	public var height(get, null):Int;

	public function new(display:Display, coreLoop:PeoteViewLoop) {
		this.display = display;
		this.coreLoop = coreLoop;
		var buffer = new Buffer<ViewElement>(1);
		program = new Program(buffer);
		program.setFragmentFloatPrecision("high");
		program.alphaEnabled = true;
		program.discardAtAlpha(null);
		display.addProgram(program);
		var view = new ViewElement(0, 0, display.width, display.height);
		buffer.addElement(view);
		globalFrameBuffer = makeFrameBuffer("frameBuffer");
	}

	public function globalFilter(formula:String, inject:String){
		program.injectIntoFragmentShader(inject, true);
		program.setColorFormula(formula);
	}

	function chainFrameBuffer(frameBuffer:FrameBuffer, name:String) {
		program.addTexture(frameBuffer.texture, name, true);
	}

	function makeFrameBuffer(name:String): FrameBuffer{
		var frameBuffer = coreLoop.getFrameBufferDisplay(display.x, display.y, display.width, display.height);
		chainFrameBuffer(frameBuffer, name);
		return frameBuffer;
	}

	public function createLayer(name:String, useGlobalFrameBuffer:Bool = true):Layer {
		var fb = useGlobalFrameBuffer ? globalFrameBuffer : makeFrameBuffer(name);
		var layer = new Layer(fb);
		layers[name] = layer;
		return layer;
	}

	function initGraphicsBuffer(name:String, buffer:IHaveGraphicsBuffer){
		var layer = createLayer(name);
		layer.registerGraphicsBuffer(buffer);
		layer.addProgramToFrameBuffer(buffer.program);
		layers[name] = layer;
	}

	public function createEchoDebugLayer():DrawShapes {
		final name = "echo";
		var frames = new DrawShapes();
		initGraphicsBuffer(name, frames);
		return frames;
	}

	public function createSpriteFramesLayer(name:String, image:Image, frameSize:Int):SpriteFrames {
		var frames = new SpriteFrames(image, frameSize);
		initGraphicsBuffer(name, frames);
		return frames;
	}

	public function createGlyphFramesLayer(name:String, font:Font<FontStyle>):GlyphFrames {
		var frames = new GlyphFrames(font);
		initGraphicsBuffer(name, frames);
		return frames;
	}

	public function updateGraphicsBuffers() {
		for (layer in layers) {
			layer.updateGraphicsBuffers();
		}
	}

	function get_width():Int {
		return display.width;
	}

	function get_height():Int {
		return display.height;
	}
}

class ViewElement implements Element {
	@posX var x:Int = 0;
	@posY var y:Int = 0;

	@sizeX var w:Int;
	@sizeY var h:Int;

	public function new(positionX:Int = 0, positionY:Int = 0, width:Int, height:Int) {
		this.x = positionX;
		this.y = positionY;
		this.w = width;
		this.h = height;
	}
}

interface IHaveGraphicsBuffer {
	public function updateGraphicsBuffers():Void;
	public var program(get, null):Program;
}

class Layer {

	var frameBuffer(default, null):FrameBuffer;
	public var display(get, null):Display;
	var buffers:Array<IHaveGraphicsBuffer>;

	public function new(frameBuffer:FrameBuffer) {
		this.frameBuffer = frameBuffer;
		buffers = [];
	}

	public function updateGraphicsBuffers() {
		for (frames in buffers) {
			frames.updateGraphicsBuffers();
		}
	}

	public function registerGraphicsBuffer(frames:IHaveGraphicsBuffer) {
		buffers.push(frames);
	}

	public function addProgramToFrameBuffer(program:Program){
		frameBuffer.display.addProgram(program);
	}

	function get_display():Display {
		return frameBuffer.display;
	}
}

typedef IsComplete = Bool;

typedef GranularAction = {
	isEnabled:Bool,
	perform:Tick->IsComplete,
}

class Tweens {
	var actions:Array<GranularAction>;

	public function new() {
		actions = [];
	}

	public function update(tick:Tick) {
		for (a in actions) {
			if (a.isEnabled) {
				a.isEnabled = !a.perform(tick);
			}
		}
	}

	public function add(action:GranularAction) {
		actions.push(action);
		
	}

	public static var linear:(time:Float, begin:Float, change:Float, duration:Float) -> Float = (time, begin, change, duration) -> return change * time / duration + begin;
}
