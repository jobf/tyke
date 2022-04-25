package samples;

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
		final options:String = "ABCDEF";
		final maxIndex:Int = options.length;

		// final options:Array<String> = ["A", "B", "C", "D", "E", "F"];
		return (col, row) -> {
			var x = col * text.fontStyle.width;
			var y = row * text.fontStyle.height;
			var charCode:Int = " ".charCodeAt(0);
			if (row < 3) {
				charCode = "0".charCodeAt(0);
			} else {
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
			numColumns: data.numCellsWide,
			numRows: data.numCellsHigh,
			cellWidth: Math.ceil(text.fontStyle.width),
			cellHeight: Math.ceil(text.fontStyle.height),
			palette: palette,
			cellInit: getInitFor(" ", 1, 3)
		}
		// var infoConfig:GlyphLayerConfig = {
		// 	numColumns: data.numCellsWide,
		// 	numRows: data.numCellsHigh,
		// 	cellWidth: Math.ceil(text.fontStyle.width),
		// 	cellHeight: Math.ceil(text.fontStyle.height),
		// 	palette: palette,
		// 	cellInit: getInitFor(" ", 0, -1)
		// }

		var demo = new CascadeLayer(config, text.fontProgram);
		// var info = new Overlay(infoConfig, text.fontProgram);

		// layers = [demo, info];
		layers = [demo];

		mouse.onDown = (x, y, button) -> {
			var pX = x / display.width;
			var pY = y / display.height;
			var numVisibleColumns = display.width / text.fontStyle.width;
			var numVisibleRows = display.height / text.fontStyle.height;
			var c = Math.floor(pX * numVisibleColumns);
			var r = Math.floor(pY * numVisibleRows);
			var underMouse = demo.get(c, r);
			var scrunitizedChar = underMouse.char;
			var isClickable = scrunitizedChar != demo.emptyChar && underMouse.char >= demo.minChar;
			if (isClickable) {
				trace('$c $r ${underMouse.char}');

				demo.clearAllMatching(underMouse.char);
			}
		}
		demo.hasChanged = true;
		gum.toggleUpdate(true);
	}
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
		trace(numRemoved);
		if (numRemoved > 0) {
			hasChanged = true;
		}
	}
}
