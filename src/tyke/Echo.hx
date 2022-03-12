package tyke;

import tyke.Stage;

enum Geometry {
	RECT;
	CIRCLE;
	POLYGON(numSides:Int);
}

class Utility {
	public function new(onCollide:Void->Void) {
		this.onCollide = onCollide;
	}

	var onCollide:Void->Void;

	public function collide() {
		onCollide();
	}
}

class DrawShapes implements IHaveGraphicsBuffer {
	// var display:Display;
	var buffer:Buffer<Shape>;
	var _program:Program;

	public var program(get, null):Program;

	public function get_program():Program {
		return _program;
	}

	public function new(bufferSize:Int = 256) {
		// this.display = display;
		buffer = new Buffer<Shape>(bufferSize, bufferSize, true);
		_program = new Program(buffer);
		_program.setFragmentFloatPrecision("high");
		_program.discardAtAlpha(null);
		final injectTimeUniform = false;
		_program.injectIntoFragmentShader(Shape.InjectFragment, injectTimeUniform);
		_program.setColorFormula(Shape.ColorFormula);
	}

	public function makeShape(x, y, w, h, shape:Geometry, color:Color = Color.LIME):Shape {
		var width = Std.int(w);
		var height = Std.int(h);

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
		return shape;
	}

	public function updateGraphicsBuffers() {
		// trace('echo');
		buffer.update();
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

	var OPTIONS = {alpha: true};

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
