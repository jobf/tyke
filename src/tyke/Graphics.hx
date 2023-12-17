package tyke;

import tyke.Loop;

interface IHaveGraphicsBuffer {
	public function updateGraphicsBuffers():Void;
	public var program(get, null):Program;
}

enum Geometry {
	RECT;
	CIRCLE;
	POLYGON(numSides:Int);
}

@:structInit
class RectangleGeometry{
	public var x:Int;
	public var y:Int;
	public var width:Int;
	public var height:Int;

	public function trace() {
		trace('x $x y $y w $width height $height');
	}
}

class Layer {
	public var frameBuffer(default, null):FrameBuffer;
	public var display(get, null):Display;

	var buffers:Array<IHaveGraphicsBuffer>;

	public function new(frameBuffer:FrameBuffer) {
		this.frameBuffer = frameBuffer;
		buffers = [];
	}

	public function updateGraphicsBuffers() {
		for (frames in buffers) {
			// trace('update gfx buffer');
			frames.updateGraphicsBuffers();
		}
		// trace('\n');
	}

	public function registerGraphicsBuffer(frames:IHaveGraphicsBuffer) {
		buffers.push(frames);
	}

	public function addProgramToFrameBuffer(program:Program) {
		frameBuffer.display.addProgram(program);
	}

	function get_display():Display {
		return frameBuffer.display;
	}
}

class GlyphRenderer implements IHaveGraphicsBuffer {
	var text:Text;

	public var program(get, null):Program;

	function get_program():Program {
		return text.fontProgram;
	}

	public var fontProgram(get, null):FontProgram<FontStyle>;

	function get_fontProgram():FontProgram<FontStyle> {
		return text.fontProgram;
	}

	public function new(font:Font<FontStyle>) {
		text = Glyphs.initText(font);
	}

	/* redraw all sprites, e.g. call this in draw loop */
	public function updateGraphicsBuffers() {
		text.fontProgram.updateAllGlyphes();
	}
}

class Shape implements Element {
	@pivotX @formula("w * 0.5 + px_offset") public var px_offset:Float;
	@pivotY @formula("h * 0.5 + py_offset") public var py_offset:Float;
	@rotation public var rotation:Float;
	@sizeX @varying public var w:Int;
	@sizeY @varying public var h:Int;
	@color public var color:Color = 0xaabb00ff;
	// @color public var c:Color = 0xaabb00ff;
	@posX @set("Position") public var x:Float;
	@posY @set("Position") public var y:Float;
	@custom @varying public var sides:Float = 3.0;
	@custom @varying public var shape:Float = 0.0;

	var OPTIONS = {blend: true};

	public static var InjectFragment = "
    #define PI 3.14159265359
    #define TWO_PI 6.28318530718
    
    // from the book of shaders https://thebookofshaders.com/07/
	// only triangle is correct at the moment
	// todo ! calculate r for n sided polygons
	// or use vertices data from echo shape
    vec4 polygon(vec4 c, float sides){
        // Remap the coord for
        vec2 coord = vTexCoord;
        coord.y = (1.0 - coord.y);

        // Remap the space to -1. to 1.
        vec2 st = coord * 2.0-1.0;

        // Angle and radius from the current pixel
        float r = TWO_PI/sides;
        float a = atan(st.x,st.y) + PI;

        // Shaping function that modulate the distance
        float d = cos(floor(.5+a/r)*r-a)*length(st);
        float A = 1.0-smoothstep(.5,.51,d) == 1.0 ? c.a : 0.0;
        return vec4(c.rgb, A);
    }

    // // https://github.com/ayamflow/glsl-2d-primitives/blob/master/polygon.glsl
    // vec4 polygon(vec4 c, float sides){
    //     vec2 st = vTexCoord * 2.0 - 1.0;
    //     st.y  = (1.0 - st.y);
    //     float angle = atan(st.x,st.y) + PI;
    //     float slice = TWO_PI / sides;
    //     // float radius = 0.4;
    //     float radius = 0.5;//1.0;//0.7;//sides / 10.0;
    //     // float x = vSize.x; 
    //     // float radius = 1.0 / cos(x) * (180.0 / sides);
    //     float s = step(radius, cos(floor(0.5 + angle / slice ) * slice - angle) * length(st));
    //     float A = 1.0 - s == 1.0 ? c.a : 0.0;
    //     return vec4(c.rgb, A);
    // }

    float circle(vec2 st, float radius)
    {
        vec2 dist = st-vec2(0.5);
        return 1.-smoothstep(radius-(radius*0.01),
                             radius+(radius*0.01),
                             dot(dist,dist)*4.0
                            );
    }

    vec4 compose(vec4 c, float shapeType, float numSides){
        // return vec4(0.8,0.8,0.8,1.0);
        if(shapeType <= 0.0 ){
            return c;
        }
        // circle
        if(shapeType == 1.0){
            float a = circle(vTexCoord, 1.0) == 1.0 ? c.a : 0.0;
			return vec4(c.rgb, a);
        }
        // polygon
        return polygon(c, numSides);
    }
    ";

	public static var ColorFormula = "compose(color, shape, sides)";

	public function new(positionX:Int = 0, positionY:Int = 0, width:Int, height:Int, shapeType:Int, numSides:Float = 3.0, color:Int = 0xffffffFF) {
		this.x = positionX;
		this.y = positionY;
		this.w = width;
		this.h = height;
		this.shape = shapeType;
		this.color = color;
		this.sides = numSides;
		// todo visible should honour alpha not be on or off
		// this.visible = true;
	}

	public var visible(get, set):Bool;

	function get_visible():Bool {
		return color.alpha == 0;
	}

	function set_visible(isVisible:Bool):Bool {
		color.alpha = isVisible ? 0xff : 0x00;
		return isVisible;
	}
}




class ShapeRenderer implements IHaveGraphicsBuffer {
	var buffer:Buffer<Shape>;
	var shapesInBuffer:Array<Shape>;

	var _program:Program;
	// var shapeInBuffer
	public var program(get, null):Program;

	public function get_program():Program {
		return _program;
	}

	public function new(bufferSize:Int = 256) {
		buffer = new Buffer<Shape>(bufferSize, bufferSize, true);
		shapesInBuffer = [];
		_program = new Program(buffer);
		_program.setFragmentFloatPrecision("high");
		_program.discardAtAlpha(null);
		final injectTimeUniform = false;
		_program.injectIntoFragmentShader(Shape.InjectFragment, injectTimeUniform);
		_program.setColorFormula(Shape.ColorFormula);
	}

	public function makeShape(x:Int, y:Int, width:Int, height:Int, shape:Geometry, color:Color = Color.LIME):Shape {
		var shapeType:Int = switch (shape) {
			case CIRCLE: 1;
			case RECT: 0;
			case _: 2; // polygon
		}
		var numSides = switch (shape) {
			case CIRCLE: 1;
			case POLYGON(sides): sides;
			case _: 4;
		}

		var shape = new Shape(Std.int(x), Std.int(y), width, height, shapeType, numSides, color);

		buffer.addElement(shape);
		shapesInBuffer.push(shape);
		
		return shape;
	}

	public function updateGraphicsBuffers() {
		// trace('shape renderer update');
		buffer.update();
	}

	public function setVisibility(isVisible:Bool) {
		for(shape in shapesInBuffer){
			shape.visible = isVisible;
		}
	}
}

class Rectangle implements Element {
	// @pivotX @formula("w * 0.5 + px_offset") public var px_offset:Float;
	// @pivotY @formula("h * 0.5 + py_offset") public var py_offset:Float;
	@pivotX public var px_offset:Float = 0.0;
	@pivotY public var py_offset:Float = 0.0;
	@rotation public var rotation:Float = 0.0;
	@sizeX @varying public var w:Float;
	@sizeY @varying public var h:Float;
	@color public var color:Color = 0xaabb00ff;
	// @color public var c:Color = 0xaabb00ff;
	@posX @set("Position") public var x:Float;
	@posY @set("Position") public var y:Float;
	@custom @varying public var sides:Float = 3.0;
	@custom @varying public var shape:Float = 0.0;

	var OPTIONS = {blend: true};

	public static var InjectFragment = "
   
    ";

	public static var ColorFormula = "";

	public function new(positionX:Float = 0, positionY:Float = 0, width:Float, height:Float, rotation:Float = 3.0, color:Int = 0xffffffFF) {
		this.x = positionX;
		this.y = positionY;
		this.w = width;
		this.h = height;
		this.color = color;
		this.rotation = rotation;
	}

	public var visible(get, set):Bool;

	function get_visible():Bool {
		return color.alpha == 0;
	}

	function set_visible(isVisible:Bool):Bool {
		color.alpha = isVisible ? 0xff : 0x00;
		return isVisible;
	}
}


class RectangleRenderer implements IHaveGraphicsBuffer {
	public var buffer(default, null):Buffer<Rectangle>;
	var _program:Program;

	public var program(get, null):Program;

	public function get_program():Program {
		return _program;
	}

	public function new(bufferSize:Int = 256) {
		buffer = new Buffer<Rectangle>(bufferSize, bufferSize, true);
		_program = new Program(buffer);
		// _program.setFragmentFloatPrecision("high");
		_program.discardAtAlpha(null);
		// final injectTimeUniform = false;
		// _program.injectIntoFragmentShader(Rectangle.InjectFragment, injectTimeUniform);
		// _program.setColorFormula(Rectangle.ColorFormula);
	}

	public function makeRectangle(x:Float, y:Float, width:Float, height:Float, angle:Float, color:Color = Color.LIME):Rectangle {
		var element = new Rectangle(x, y, width, height, angle, color);
		buffer.addElement(element);
		return element;
	}

	public function updateGraphicsBuffers() {
		// trace('echo');
		buffer.update();
	}
}


class Sprite implements Element {
	// @posX public var x:Int;
	// @posY public var y:Int;
	@pivotX @formula("w * 0.5 + px_offset") public var px_offset:Float;
	@pivotY @formula("h * 0.5 + py_offset") public var py_offset:Float;
	@rotation public var rotation:Float;

	/** element width (can be negative when x is flipped, e.g. 400 would be -400)**/
	@sizeX public var w:Int;

	/** element height (can be negative when y is flipped, e.g. 400 would be -400)**/
	@sizeY public var h:Int;

	/** actual width (does not change when x is flipped )**/
	public var width(default, null):Int;

	/** actual height (does not change when y is flipped )**/
	public var height(default, null):Int;

	// Texture properties
	// @texSlot public var slot:Int = 1;
	// @texUnit() public var unit:Int = 1;
	@texSlot("base") public var slot:Int = 0;
	@color public var c:Color = 0xaabb00ff;
	@texTile() public var tile:Int = 0;

	// at what peote.time it have to shake
	@custom public var shakeAtTime:Float = -100.0;
	@custom public var shakeFrequencyY:Float = 6.0;
	@custom public var shakeFrequencyX:Float = 6.0;
	@custom public var shakeDistanceY:Float = 3.0;
	@custom public var shakeDistanceX:Float = 3.0;
	@custom public var shakeDurationX:Float = 1.2;
	@custom public var shakeDurationY:Float = 0.9;

	// params for shake: number of shakes, size in pixel, durationtime in seconds
	@posX @set("Position") @formula("x + shake(shakeAtTime, shakeFrequencyX, shakeDistanceX, shakeDurationX)") public var x:Float;
	@posY @set("Position") @formula("y + shake(shakeAtTime, shakeFrequencyY, shakeDistanceY, shakeDurationY)") public var y:Float;

	// params for blinking alpha
	@custom("alpha") @varying @constEnd(1.0) @anim("A", "pingpong") public var alpha:Float;
	// @custom("alpha") @varying @constStart(0.0) @constEnd(1.0) @anim("A", "pingpong") public var alpha:Float;

	var OPTIONS = {blend: true};

	public static var InjectVertex = "
	#define TWO_PI 6.28318530718
	float shake( float atTime, float freq, float size, float duration )
	{
		float t = max(0.0, uTime - atTime);				
		t = (clamp(t, 0.0, duration) / duration);			
		// return 1.0 - size + size * sin(freq * TWO_PI * t) * (t+0.5)*t*t*(t-1.0)*(t-1.0)*15.5;
		return size * sin(freq * TWO_PI * t) * (t+0.5)*t*t*(t-1.0)*(t-1.0)*15.5;
	}
	";

	public static var InjectFragment = "";

	public function new(positionX:Int = 0, positionY:Int = 0, width:Int, height:Int, tile:Int = 0, tint:Int = 0xffffffFF, isVisible:Bool = true) {
		this.x = positionX;
		this.y = positionY;
		this.w = width;
		this.h = height;
		this.width = this.w;
		this.height = this.h;
		this.c = tint;
		this.tile = tile;
		this.visible = isVisible;
	}

	public function shake(atTime:Float) {
		shakeAtTime = atTime;
		// buffer.updateElement(this);
	}

	public function setFlashing(isFlashing:Bool){
		// todo - adhere to previously set alpha
		if(isFlashing){
			alphaStart = 0.0;
		}
		else{
			alphaStart = 1.0;
		}
	}

	public var isFlippedX(default, null):Bool;

	public function flipX(isFlipped:Bool) {
		isFlippedX = isFlipped;
		var flipBy = isFlippedX ? -1 : 1;
		// var adjustPosBy = isFlippedX ? width * 0.5 : 0;
		w = width * flipBy;
		// x += adjustPosBy;
	}	public var visible(get, set):Bool;

	function get_visible():Bool {
		return c.alpha == 0;
	}

	function set_visible(isVisible:Bool):Bool {
		c.alpha = isVisible ? 0xff : 0x00;
		return isVisible;
	}
	var debugElement:Shape;
	public function attachDebug(debug:Shape){
		this.debugElement = debug;
	}

	public function move(x:Float, y:Float){
		this.x = x;
		this.y = y;
		if(debugElement != null){
			debugElement.x = x;
			debugElement.y = y;
		}
	}

	public function rotate(r:Float){
		this.rotation = r;
		if(debugElement != null){
			debugElement.rotation = r;
		}
	}
}

/* Handle Sprites from spritesheet Image */
class SpriteRenderer implements IHaveGraphicsBuffer {
	var spriteSheet:Texture;
	var buffer:Buffer<Sprite>;
	var _program:Program;

	public var program(get, null):Program;

	function get_program():Program {
		return _program;
	}

	public function new(image:Image, frameSize:Int, bufferSize:Int = 256) {
		spriteSheet = new Texture(image.width, image.height);
		spriteSheet.tilesX = Std.int(image.width / frameSize);
		spriteSheet.tilesY = Std.int(image.height / frameSize);
		spriteSheet.setImage(image, 0);
		buffer = new Buffer<Sprite>(bufferSize, bufferSize, true);
		_program = new Program(buffer);
		_program.setFragmentFloatPrecision("high");
		_program.discardAtAlpha(null);
		_program.injectIntoVertexShader(Sprite.InjectVertex, true);
		_program.injectIntoFragmentShader(Sprite.InjectFragment, false);
		_program.addTexture(spriteSheet, "base");
		_program.setColorFormula( 'vec4(base.r, base.g, base.b, base.a * alpha)' );
	}

	public function makeSprite(x:Int, y:Int, spriteSize:Int, tileIndex:Int, framesIndex:Int = 0, isVisible:Bool = true):Sprite {
		var sprite = new Sprite(x, y, spriteSize, spriteSize, tileIndex, isVisible);
		sprite.alphaStart = 1.0;
		sprite.timeAStart = 0.5;
		sprite.timeADuration = 0.25; 
		buffer.addElement(sprite);
		return sprite;
	}

	/* redraw all sprites, e.g. call this in draw loop */
	public function updateGraphicsBuffers() {
		buffer.update();
	}
}

class FilterElement implements Element {
	@posX public var x:Int = 0;
	@posY public var y:Int = 0;

	@sizeX public var w:Int = 100;
	@sizeY public var h:Int = 100;
	@texSlot("base") public var slot:Int = 0;
	@color public var c:Color = 0xff0000ff;

	public function new(positionX:Int = 0, positionY:Int = 0, width:Int = 100, height:Int = 100, color:Color) {
		this.x = positionX;
		this.y = positionY;
		this.w = width;
		this.h = height;
		this.c = color;
	}
}

class Filter {
	var buffer:Buffer<FilterElement>;
	var program:Program;

	public function new(width:Int, height:Int, colorFormula:String, injectTimeUniform:Bool = false) {
		final bufferSize = 1;
		buffer = new Buffer<FilterElement>(bufferSize, bufferSize, true);
		program = new Program(buffer);
		// program.setFragmentFloatPrecision("high");
		program.discardAtAlpha(null);
		var color = 0x113366.RGBA(0xcc);
		var element = new FilterElement(0, 0, width, height, 0x000000ff);
		buffer.addElement(element);
		program.injectIntoFragmentShader(colorFormula, injectTimeUniform);
		program.setColorFormula('compose()');
	}

	/* register for drawing on a Display */
	public function addToDisplay(display:Display) {
		display.addProgram(program);
	}
}