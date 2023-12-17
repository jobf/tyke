package tyke;

import peote.text.Line;
import peote.text.FontProgram;

class Log {
	var x:Int;
	var y:Int;
	var maxLines:Int;
	var maxAlphaReduction:Int;
	var lines:Array<Line<FontStyle>>;
	var fontProgram:FontProgram<FontStyle>;
	var fontStyle:FontStyle;

	public function new(x:Int, y:Int, fontProgram:FontProgram<FontStyle>, fontStyle:FontStyle, maxLines:Int = 10, maxAlphaReduction:Int = 0xa0) {
		this.x = x;
		this.y = y;
		this.fontProgram = fontProgram;
		this.fontStyle = fontStyle;
		this.maxLines = maxLines;
		this.maxAlphaReduction = maxAlphaReduction;
		lines = [];
	}

	public function write(message:String):Void {
		var fg = fontStyle.color;
		var bg = fontStyle.bgColor;

		for (i => line in lines) {
			var alpha = 0xff - Math.ceil(((maxLines - i) / maxLines) * maxAlphaReduction);
			fontStyle.color = fg.changeAlpha(alpha);
			fontStyle.bgColor = bg.changeAlpha(alpha);
			fontProgram.lineSetStyle(line, fontStyle);
			fontProgram.lineSetYPosition(line, line.y - line.height);
			fontProgram.lineUpdate(line);
		}

		fontStyle.color = fg;
		fontStyle.bgColor = bg;

		lines.push(fontProgram.createLine(message, x, y, fontStyle));
		if (lines.length > maxLines) {
			var oldestLine = lines.shift();
			fontProgram.removeLine(oldestLine);
		}
	}
}

class HUD {
	var watchers:Array<Void->String>;
	var lines:Array<Line<FontStyle>>;
	var fontProgram:FontProgram<FontStyle>;
	var fontStyle:FontStyle;
	var x:Int;
	var y:Int;
	public function new(x:Int, y:Int, fontProgram:FontProgram<FontStyle>, fontStyle:FontStyle) {
		this.x = x;
		this.y = y;
		watchers = [];
		lines = [];
		this.fontProgram = fontProgram;
		this.fontStyle = fontStyle;
	}

	public function watch(getText:Void->String, x:Int, y:Int) {
		lines.push(fontProgram.createLine("?", x + this.x, y + this.y, fontStyle));
		watchers.push(getText);
	}

	public function update() {
		for (i => getText in watchers) {
			var log = getText();
			var line = lines[i];
			fontProgram.setLine(line, log, line.x, line.y, fontStyle);
			fontProgram.lineUpdate(line);
			// trace(log);
		}
	}
}
