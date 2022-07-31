package tyke;

@:structInit
class GlyphModel {
	public var char:Int;
	// todo - remove glyph from here (need to reimplement layers first)
	public var glyph:Glyph<FontStyle>;
	public var paletteIndexFg:Int;
	public var paletteIndexBg:Int;
	public var bgIntensity:Float;
}

@:structInit
class GlyphLoopConfig {
	public var numCellsWide:Int;
	public var numCellsHigh:Int;
}

class FontStyle {
	public var color:Color = Color.LIME;
	public var bgColor:Color = Color.BLACK;
	public var width:Float = 16;
	public var height:Float = 16;
	public var zIndex:Int = 0;
	public var tilt:Float = 0.0;
	public var weight:Float = 0.5;

	public function new() {}
}

class CellWorks {
	public static function randomise(c:Int, r:Int, cell:GlyphModel, palette:Palette, isColorRandom:Bool = true, isCharRandom:Bool = true) {
		if (isColorRandom) {
			cell.paletteIndexFg = palette.randomIndex();
		}
		if (isCharRandom) {
			cell.char = randomChar();
		}
	}

	static var cycle:Int = 0;

	public static function cyclePalette(cell:GlyphModel, palette:Palette, reduceColorsBy:Int = 0, tick:Int) {
		cell.paletteIndexFg = palette.cyclePalette(reduceColorsBy);
		cycle++;
		var wavelength = 0.01;
		var alphaGain = Math.abs(Math.sin(cycle * wavelength));
		// trace(alphaGain);
		cell.bgIntensity = Math.ceil(255 * alphaGain);
	}
}

class Palette {
	var paletteCycleIndex:Int = 0;
	final transparent:Int = 0x00000000;

	public var colors(default, null):Array<Int>;

	var defaultBgIndex(default, null):Int;

	public function new(colors:Array<Int>, defaultBgIndex:Int = -1) {
		this.defaultBgIndex = defaultBgIndex;
		this.colors = colors;
	}

	public function cyclePalette(shortenBy:Int = 0):Color {
		var last = paletteCycleIndex;
		var maxIndex = colors.length - shortenBy;
		paletteCycleIndex++;
		if (paletteCycleIndex >= maxIndex) {
			paletteCycleIndex = 0;
		}
		return last >= colors.length ? colors.length - 1 : last;
	}

	public function randomIndex():Int {
		return randomInt(colors.length - 1);
	}

	public function setColors(colors:Array<Int>) {
		this.colors = colors;
	}

	public function colorOrDefault(index:Int) {
		return index < 0 ? transparent : colors[index];
	}
}

function randomInt(max:Int) {
	return Math.ceil(max * Math.random());
}

function randomFloat(min:Float = 0, max:Float = 1):Float {
	return min + Math.random() * (max - min);
}

function randomChance(percent:Float = 50):Bool{
	return Math.random() < percent / 100;
}

function randomChar():Int {
	var random = Math.random();
	var charIndexOffset = Math.ceil(AsciiCharRange * random);
	return AsciiMinChar + charIndexOffset;
}

final AsciiMinChar:Int = 32;
final AsciiCharRange:Int = 96;
