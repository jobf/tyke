package tyke;

import tyke.Grid;
import tyke.Loop;
import tyke.Loop.Glyphs;
import tyke.Glyph;
import tyke.Palettes;

typedef LayerConfig<T> = {
	numColumns:Int,
	numRows:Int,
	cellWidth:Int,
	cellHeight:Int,
	palette:Palette,
	?cellInit:(Column, Row) -> T
}

class GridLayer<T> extends GridStructure<T> {
	public var hasChanged:Bool = false;
	public var palette(default, null):Palette;

	public function new(config:LayerConfig<T>) {
		super(config.numColumns, config.numRows, config.cellInit);
		palette = config.palette;
	}

	public function onTick(tick:Int):Void {
		// hasChanged = true;
	}
}

class GlyphLayer extends GridLayer<GlyphModel> {
	var fontProgram:FontProgram<FontStyle>;
	var fontStyle:FontStyle;

	public var offsetX:Int;
	public var offsetY:Int;
	public var cellWidth(get, null):Float;

	function get_cellWidth():Float {
		return fontStyle == null ? 20 : fontStyle.width;
	}

	public var cellHeight(get, null):Float;

	function get_cellHeight():Float {
		return fontStyle == null ? 36 : fontStyle.height;
	}

	public function new(config:GlyphLayerConfig, fontProgram:FontProgram<FontStyle>) {
		this.fontProgram = fontProgram;
		fontProgram.fontStyle.bgColor = 0x00000000;
		final space = 0x20;
		if (config.cellInit == null) {
			config.cellInit = (column, row) -> {
				var charCode = 0;
				var x = column * config.cellWidth;
				var y = row * config.cellHeight;
				return {
					char: charCode,
					glyph: fontProgram.createGlyph(space, x, y, fontProgram.fontStyle),
					paletteIndexFg: 10,
					paletteIndexBg: -1,
					bgIntensity: 1.0
				};
			}
		}
		super(config);
	}

	public function draw() {
		// trace('draw');
		for (i => cell in cells) {
			cell.glyph.color = palette.colorOrDefault(cell.paletteIndexFg);
			var bgColor = palette.colorOrDefault(cell.paletteIndexBg);
			if (cell.paletteIndexBg > 0) {
				var alpha = Math.ceil(255 * cell.bgIntensity);
				cell.glyph.bgColor = bgColor.changeAlpha(alpha);
			}
			// null cell must be 'space' to have any graphic - todo draw at beginining
			fontProgram.glyphSetChar(cell.glyph, cell.char == 0x0 ? " ".charCodeAt(0) : cell.char);
		}
	}

	public function screenToGrid(pixelX:Float, pixelY:Float, pixelW:Float, pixelH:Float):Point {
		var pX = pixelX / pixelW;
		var pY = pixelY / pixelH;
		var numVisibleColumns = pixelW / fontProgram.fontStyle.width;
		var numVisibleRows = pixelH / fontProgram.fontStyle.height;
		var c = Math.floor(pX * numVisibleColumns);
		var r = Math.floor(pY * numVisibleRows);
		return {x: c, y: r};
	}
}

typedef GlyphLayerConfig = LayerConfig<GlyphModel>
