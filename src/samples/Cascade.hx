package samples;

import tyke.Grid;
import tyke.Palettes;
import tyke.Layers;
import tyke.Loop;
import tyke.Glyph;

// todo ! drop Text and just use FontProgram

class Cascade extends GlyphLoop {
	public function new(data:GlyphLoopConfig, assets:Assets, ?palette:Palette) {
		super(data, assets, palette);
		onInitComplete = begin;
	}

	function getInitFor(char:String, fg:Int, bg:Int):(Int, Int) -> GlyphModel {
		final options:String = "ABCDEFGHIJKLMNOPQRSTUVWYZ";
		final maxIndex:Int = options.length;
		var defaultFg = fg;
		return (col, row) -> {
			var x = col * text.fontStyle.width;
			var y = row * text.fontStyle.height;
			var charCode:Int = " ".charCodeAt(0);
			if (row < 3) {
				charCode = "0".charCodeAt(0);
				fg = 7;
			} else if (row < 12) {
				fg = defaultFg;
				charCode = options.charCodeAt(randomInt(maxIndex) - 1);
			}

			return {
				char: charCode,
				glyph: text.fontProgram.createGlyph(charCode, x, y, text.fontStyle),
				paletteIndexFg: fg,
				paletteIndexBg: bg,
				bgIntensity: 1.0
			};
		}
	}

	function begin() {
		var config:GlyphLayerConfig = {
			numColumns: Math.ceil(display.width / text.fontStyle.width),
			numRows: Math.ceil(display.height / text.fontStyle.height),
			cellWidth: Math.ceil(text.fontStyle.width),
			cellHeight: Math.ceil(text.fontStyle.height),
			palette: palette,
			cellInit: getInitFor(" ", 1, 3)
		}
		cascade = new CascadeLayer(config, text.fontProgram);
		layers = [cascade];

		mouse.onDown = (x, y, button) -> {
			var pointUnderMouse:Point = cascade.screenToGrid(x, y, display.width, display.height);
			var underMouse = cascade.get(pointUnderMouse.x, pointUnderMouse.y);
			var scrunitizedChar = underMouse.char;
			var isClickable = scrunitizedChar != cascade.emptyChar && underMouse.char >= cascade.minChar;
			if (isClickable) {
				// trace('$c $r ${underMouse.char}');
				cascade.clearAllMatching(underMouse.char);
				isCascading = true;
			}
		}

		cascade.hasChanged = true;
		gum.toggleUpdate(true);
	}

	var isCascading:Bool;

	override function onTick(tick:Int):Bool {
		if (isCascading) {
			if (cascade.changed()) {
				cascade.hasChanged = true;
			} else {
				isCascading = false;
			}
		}
		return super.onTick(tick);
	}

	var cascade:CascadeLayer;
}

class Overlay extends GlyphLayer {
	var lines:Array<Array<Int>> = [];

	public function addLine(text:String) {
		lines.push([for (c in text.split("")) c.charCodeAt(0)]);
	}

	public function refreshDisplay() {
		for (lineIndex => line in lines) {
			trace([for (c in line) String.fromCharCode(c)].join(""));
			for (charIndex => char in line) {
				this.forSingleCoOrdinate(charIndex, lineIndex, (col, row, cell) -> {
					cell.char = char;
					cell.paletteIndexFg = 14;
					cell.paletteIndexBg = 15;
				});
			}
		}
		hasChanged = true;
	}
}

class CascadeLayer extends GlyphLayer {
	public final emptyChar = " ".charCodeAt(0);
	public final minChar = "A".charCodeAt(0);
	public final treasureChar = "0".charCodeAt(0);

	final threshold:Int = 12;

	override function onTick(tick:Int):Void {
		// hasChanged = true;
	}

	// var palettes = [Sixteen.VanillaMilkshake, Sixteen.Soldier, Sixteen.Versitle];
	// var paletteIndex:Int = 0;

	public function clearAllMatching(charCode:Int) {
		var numRemoved = 0;
		for (i => cell in cells) {
			if (cell.char == charCode) {
				cell.char = emptyChar;
				numRemoved++;
			}
		}
		// trace(numRemoved);
		if (numRemoved > 0) {
			hasChanged = true;
		}
	}

	final canFallTo:Array<Point> = [
		{
			x: 0,
			y: 1
		},
		{
			x: 1,
			y: 1
		},
		{
			x: -1,
			y: 1
		}
	];

	function moved(from:GlyphModel, column:Int, row:Int):Bool {
		var to = get(column, row);
		if (to.char == emptyChar) {
			to.char = from.char;
			to.paletteIndexFg = from.paletteIndexFg;
			from.char = emptyChar;
			// trace('moved');
			return true;
		}
		return false;
	}

	public function changed():Bool {
		var somethingMoved = false;
		final isReversed = true;
		forEach((c, r, each) -> {
			if (each.char == treasureChar) {
				var isGrounded = r == numRows - 1;
				if (!isGrounded) {
					// can fall so  will try various destinations
					for (o in canFallTo) {
						var column = o.x + c;
						var row = o.y + r;
						if (!isInBounds(column, row)) {
							continue;
						}
						if (moved(each, column, row)) {
							somethingMoved = true;
							break;
						}
					}
				} else {
					// is on ground so exit the treasure
					var column = c + 1;
					var row = r;
					var isExiting = column >= numColumns;
					if (isExiting) {
						// trace('score!');
						each.char = emptyChar;
						somethingMoved = true;
					} else {
						if (moved(each, column, row)) {
							// trace('exiting');
							somethingMoved = true;
						}
					}
				}
			}
		}, isReversed);

		return somethingMoved;
	}
}
