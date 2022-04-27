package tyke;

class Mouse {
	public function new() {}

	public var onDown:(x:Float, y:Float, button:MouseButton) -> Void = (x, y, button) -> {
		trace('mouse down $x $y $button');
	};

    public var onUp:(x:Float, y:Float, button:MouseButton) -> Void = (x, y, button) -> {
		trace('mouse up $x $y $button');
	};

	public var onMove:(x:Float, y:Float) -> Void = (x, y) -> {
		// trace('mouse move $x $y');
	};
}
