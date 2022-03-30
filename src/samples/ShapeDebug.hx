package samples;

import echo.data.Options.BodyOptions;
import samples.TYKE;
import tyke.Glyph;
import echo.Body;
import echo.data.Types;
import tyke.Echo;
import echo.World;
import tyke.Stage;

//	todo ? implement and extend StageLoop instead?
class ShapeLoop extends WorldStageLoop {
	var shapes:ShapeShaker;

	public function new(assets:Assets) {
		super(assets);
		onInitComplete = () -> {
			initWorldAndStage();
			begin();
		}

		// keyboard.bind(KeyCode.P, "PAUSE", "TOGGLE UPDATE", loop -> {
		// 	gum.toggleUpdate();
		// });
	}

	function begin() {
		shapes = new ShapeShaker(world, stage);
		world.listen();
		alwaysDraw = true;
		gum.toggleUpdate(true);
	}

	override function onTick(deltaMs:Int):Bool {
		shapes.onTick(deltaMs);
		var requestDraw = super.onTick(deltaMs);
		return requestDraw;
	}

	override function onDraw(deltaMs:Int) {
		super.onDraw(deltaMs);
	}

	override function onMouseMove(x:Float, y:Float) {
		super.onMouseMove(x, y);
		if (shapes != null) {
			shapes.onMouseMove(x, y);
		}
	}
}

class ShapeShaker {
	var stage:Stage;
	var world:World;
	var shapesLayer:DrawShapes;

	public function new(world:World, stage:Stage) {
		this.world = world;
		this.stage = stage;
		shapesLayer = this.stage.createShapeRenderLayer();

		mouseBody = new HardLight({
			x: stage.width * 0.5,
			y: stage.height * 0.5,
			kinematic: true,
			rotational_velocity: 10,
			shape: {
				type: POLYGON,
				sides: 3,
				radius: 100,
				width: 200,
				height: 200,
				solid: true
			}
		}, this.world, shapesLayer, 0x44ff44aa);
		// var p:Polygon = cast mouseBody.body.shape;
		// var a = p.vertices[0].distance(p.vertices[1]);

		var blockBody = new HardLight({
			mass: 0,
			elasticity: 0.3,
			x: stage.width * 0.5,
			y: stage.height * 0.5,
			shape: {
				type: RECT,
				width: stage.width * 0.3,
				height: stage.height * 0.03,
			}
		}, this.world, shapesLayer, 0xffff4455);

		world.listen({
			// separate: separate,
			enter: (body1, body2, array) -> {
				// if(body1.element != null){}
				if (body1.utility != null) {
					body1.utility.collide();
				}
				if (body2.utility != null) {
					body2.utility.collide();
				}
			},
			// stay: stay,
			// exit: exit,
			// condition: condition,
			// percent_correction: percent_correction,
			// correction_threshold: correction_threshold
		});
	}

	var elapsedTicks:Int = 0;
	var body_count = 16;
	var timer = 0;

	var polygonSides:Array<Int> = [3, 3, 3, 3, 5, 7, 11];

	public function onTick(deltaMs:Int):Void {
		elapsedTicks++;
		timer += deltaMs;
		if (timer > 360) {
			var size = randomFloat(68, 102);
			var isSolid = randomChance();
			if (world.count < body_count) {
				var shapeType:ShapeType = randomChance() ? RECT : randomChance() ? POLYGON : CIRCLE;
				var color = isSolid ? 0xffffff99 : 0x4444ff99;
				if (shapeType == POLYGON && !isSolid) {
					color = 0xff33ff99;
				}
				var numSides = 1;
				if (shapeType != CIRCLE) {
					if (shapeType == POLYGON) {
						var i = randomInt(polygonSides.length - 1);
						numSides = polygonSides[i];
					} else {
						// RECT
						numSides = 4;
					}
				}
				var light = new HardLight({
					x: randomFloat(0, world.width),
					y: 100,
					velocity_y: 20,
					mass: 4,
					elasticity: 0.3,
					rotational_velocity: randomFloat(-30, 30),
					shape: {
						type: shapeType,
						radius: size * 0.5,
						width: size,
						height: size,
						solid: isSolid,
						sides: numSides, // todo better shader drawing of shapes -- Random.range_int(3, 8)
					}
				}, world, shapesLayer, color);
			}

			timer = 0;
		}
		world.for_each((member) -> {
			if (isOutOfBounds(member)) {
				member.velocity.set(0, 0);
				member.set_position(randomFloat(0, world.width), 0);
			}
		});
	}

	public function onMouseMove(x:Float, y:Float) {
		mouseBody.body.set_position(x, y);
	}

	function isOutOfBounds(b:Body) {
		var bounds = b.bounds();
		var check = bounds.min_y > world.height || bounds.max_x < 0 || bounds.min_x > world.width;
		bounds.put();
		return check;
	}

	var mouseBody:HardLight;
}

class HardLight {
	public var graphic(default, null):Shape;
	public var body(default, null):Body;

	public function new(config:BodyOptions, world:World, shapes:DrawShapes, color:Color = Color.LIME) {
		body = world.make(config);

		var geo:Geometry = switch (body.shape.type) {
			case CIRCLE: CIRCLE;
			case POLYGON: POLYGON(config.shape.sides);
			case _: RECT;
		};
		graphic = shapes.makeShape(config, geo, color);
		body.on_move = (x, y) -> {
			graphic.setPosition(x, y);
		};
		body.on_rotate = (r) -> {
			graphic.rotation = r;
		};

		body.utility = new Utility(() -> {
			this.collide();
		});
	}

	var debounceDelay = 50;

	public function collide() {
		var timeNow = Date.now().getTime(); // todo ? use peote time
		if ((timeNow - lastCollideTime) > debounceDelay) {
			lastCollideTime = timeNow;
			lit = !lit;
			graphic.color.a = lit ? 0xaa : 0x99;
		}
	}

	var lastCollideTime:Float;

	var lit:Bool;
}

typedef Range = {
	min:Int,
	max:Int
}

class Emitter {
	var isEmitting:Bool;
	var rateLimit:Float;
	var timer:Float;
	var onEmit:Float->Void;

	public function new(onEmit:Float->Void, isEmitting:Bool = true, rateLimit:Float = 0) {
		this.onEmit = onEmit;
		this.isEmitting = isEmitting;
		this.rateLimit = rateLimit;
		this.timer = 0;
	}

	public function update(deltaMs:Float):Void {
		if (isEmitting) {
			timer += deltaMs;
			if (timer > rateLimit) {
				onEmit(deltaMs);
				timer = 0;
			}
		}
	}
}
