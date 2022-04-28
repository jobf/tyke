package samples;

import tyke.Grid;
import tyke.Palettes;
import tyke.Layers;
import tyke.Loop;
import tyke.Glyph;

// todo ! drop Text and just use FontProgram
@:structInit
class ScreenGeometry{
	public var displayColumns:Int;
	public var displayRows:Int;

	public var displayPixelsWide:Int;
	public var displayPixelsHigh:Int;

	public var boundaryColumnLeft:Int;
	public var boundaryColumnRight:Int;
}

class Cascade extends GlyphLoop {
	public function new(data:GlyphLoopConfig, assets:Assets, ?palette:Palette) {
		super(data, assets, palette);
		onInitComplete = begin;
	}

	function getInitFor(char:String, fg:Int, bg:Int, geometry:ScreenGeometry):(Int, Int) -> GlyphModel {
		final options:String = "ABCDEFGHIJKLMNOPQRSTUVWYZ";
		final maxIndex:Int = options.length;

		var defaultFg = fg;
		return (col, row) -> {
			var x = col * text.fontStyle.width;
			var y = row * text.fontStyle.height;
			var charCode:Int = " ".charCodeAt(0);
			if(col < geometry.boundaryColumnLeft || col > geometry.boundaryColumnRight){
				charCode = " ".charCodeAt(0);
			}
			else if (row < 3) {
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
		final numColumns = 19;
		final numRows = 16;
		var numColumnsInDisplay = Math.ceil(display.width / text.fontStyle.width);
		var border = numColumnsInDisplay - numColumns;
		var boundaryLeft = Std.int(border * 0.5);
		var boundarRight = numColumnsInDisplay - boundaryLeft;
		geometry = {
			displayRows: Math.ceil(display.height / text.fontStyle.height),
			displayColumns: numColumnsInDisplay,
			displayPixelsWide: display.width,
			displayPixelsHigh: display.height,
			boundaryColumnRight: boundarRight,
			boundaryColumnLeft: boundaryLeft
		}
		var config:GlyphLayerConfig = {
			numColumns: geometry.displayColumns,
			numRows: geometry.displayRows,
			// numColumns: 19,
			// numRows: 16,
			cellWidth: Math.ceil(text.fontStyle.width),
			cellHeight: Math.ceil(text.fontStyle.height),
			palette: palette,
			cellInit: getInitFor(" ", 1, 3, geometry)
		}
		playWidth = config.numColumns * config.cellWidth;
		playHeight = config.numRows * config.cellHeight;
		cascade = new CascadeLayer(config, text.fontProgram, geometry);
		layers = [cascade];
		isPlayerOnLeft = true;
		mouse.onDown = (x, y, button) -> {
			if (isCascading)
				return;
			var pointUnderMouse:Point = cascade.screenToGrid(x, y, playWidth, playHeight);
			var underMouse = cascade.get(pointUnderMouse.x, pointUnderMouse.y);
			var scrunitizedChar = underMouse.char;
			var isClickable = scrunitizedChar != cascade.emptyChar && underMouse.char >= cascade.minChar;
			if (isClickable) {
				// trace('$c $r ${underMouse.char}');
				cascade.clearAllMatching(underMouse.char);
				isCascading = true;
				isPlayerOnLeft = !isPlayerOnLeft;
			}
		}

		cascade.hasChanged = true;
		gum.toggleUpdate(true);
	}

	var isCascading:Bool;

	override function onTick(tick:Int):Bool {
		if (isCascading) {
			if (cascade.changed(isPlayerOnLeft)) {
				cascade.hasChanged = true;
			} else {
				isCascading = false;
			}
		}
		return super.onTick(tick);
	}

	var geometry:ScreenGeometry;

	var cascade:CascadeLayer;

	var isPlayerOnLeft:Bool;

	var playWidth:Int;

	var playHeight:Int;
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

class CacadeArea{
	public function new(){

	}
}

class CascadeLayer extends GlyphLayer {

	public function new(config:GlyphLayerConfig, fontProgram:FontProgram<FontStyle>, geometry:ScreenGeometry){
		super(config, fontProgram);
		this.geometry = geometry;
	}

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
	
	public function isInPlayableBounds(column:Int, row:Int):Bool {
		return column >= geometry.boundaryColumnLeft && row >= 0 && column <= geometry.boundaryColumnRight && row < numRows;
	}

	public function changed(isPlayerOnLeft:Bool = true):Bool {
		var somethingMoved = false;
		final isReversed = true;
		final updatingIndidivually = true;
		final isCancelable = updatingIndidivually;
		forEachCancelable((c, r, each) -> {
			if (each.char == treasureChar) {
				var isGrounded = r == numRows - 1;
				if (!isGrounded) {
					// can fall so  will try various destinations
					for (o in canFallTo) {
						var column = o.x + c;
						var row = o.y + r;
						if (!isInPlayableBounds(column, row)) {
							continue;
						}
						if (moved(each, column, row)) {
							somethingMoved = true;
							break;
						}
					}
				} else {
					// is on ground so exit the treasure
					var groundedDirection = isPlayerOnLeft ? 1 : -1;
					var column = c + groundedDirection;
					var row = r;
					var isExiting = column >= geometry.boundaryColumnRight || column <= geometry.boundaryColumnLeft;
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
			return isCancelable && somethingMoved;
		}, isReversed);

		return somethingMoved;
	}

	var geometry:ScreenGeometry;
}
