package tyke;

import peote.text.Line;
import ob.traxe.Track;
import ob.traxe.LaneConfiguration;
import tyke.Echo.Shape;
import tyke.Echo.DrawShapes;
import tyke.Sprites;
import tyke.Layers;
import tyke.Palettes;
import tyke.Glyph;
import ob.traxe.Audio;
import ob.traxe.Navigator;
import ob.traxe.Tracker;


class NullAudioContext implements IAudioContext {
	public function new() {
		it = null;
	}

	public var it(default, null):Dynamic;
}

class GlyphTracker {
	public final layerName = "glyphs";

	var laneColumnsMap:Array<Array<Int>> = [];

	public function new(glyphRender:GlyphFrames, cursorRender:DrawShapes, headsRender:DrawShapes, numColumns:Int, numRows:Int, tracker:Tracker) {
		this.glyphRender = glyphRender;
		this.cursorRender = cursorRender;
		this.headsRender = headsRender;
		this.tracker = tracker;

		var config:GlyphLayerConfig = {
			numColumns: numColumns,
			numRows: numRows,
			cellWidth: Math.ceil(glyphRender.fontProgram.fontStyle.width),
			cellHeight: Math.ceil(glyphRender.fontProgram.fontStyle.height),
			palette: new Palette(Sixteen.Versitle.toRGBA()),
		}

		glyphs = new GlyphLayer(config, glyphRender.fontProgram);
		statusLine = glyphRender.fontProgram.createLine('help is coming...', 0, 600 - glyphRender.fontProgram.fontStyle.height);

		tracker.onFocusChanged = focusCursor;
		tracker.onValueChanged = updateText;
		tracker.onTrackRowChanged = updateHeads;
		tracker.onTrackAdded = initTrack;

		var cursorColor = Color.MAGENTA;
		cursorColor.alpha = 160;
		cursor = cursorRender.makeShape(0, 0, glyphRender.fontProgram.fontStyle.width, glyphRender.fontProgram.fontStyle.height, RECT, cursorColor);
	}

	function initTrack(track:Track) {
		var x = 0;
		var laneColumnIndex = 0;
		var laneColumnIndexes = [];

		for (lane in track.lanes) {
			laneColumnIndexes.push(laneColumnIndex);
			laneColumnIndex += lane.numColumns;
			// trace(lane.numRows);
			for (rowIndex in 0...lane.numRows) {
				var chars = lane.formatRow(rowIndex);

				for (c in 0...lane.numColumns) {
					// trace('grid cell ${x + c} $rowIndex');
					var cell = glyphs.get(x + c, rowIndex);
					cell.char = chars[c].char.charCodeAt(0);
					// glyphs. todo ? set following via GlyphLayer?
					glyphRender.fontProgram.glyphSetChar(cell.glyph, cell.char);
					glyphRender.fontProgram.updateGlyph(cell.glyph);
				}
			}
			var playheadColor = 0x8cc060a0;
			var playHeadWidth = lane.numColumns * glyphRender.fontProgram.fontStyle.width;
			var xOffset = (playHeadWidth * 0.5);
			var playheadX = (playHeadWidth * lane.index) + xOffset;
			var playheadY = glyphRender.fontProgram.fontStyle.height * 0.5;
			var playhead = headsRender.makeShape(playheadX, playheadY, playHeadWidth, glyphRender.fontProgram.fontStyle.height, RECT, playheadColor);
			playHeads.push(playhead);
			x += lane.numColumns;
		}
		laneColumnsMap.push(laneColumnIndexes);

		cursorRender.updateGraphicsBuffers();

		focusCursor({
			trackIndex: 0,
			laneIndex: 0,
			columnIndex: 0,
			rowIndex: 0
		});
	}

	inline function getFocusSingle(cursor:NavigatorCursor):GlyphModel {
		var columnIndex = laneColumnsMap[cursor.trackIndex][cursor.laneIndex] + cursor.columnIndex;
		return glyphs.get(columnIndex, cursor.rowIndex);
	}

	inline function getFocusRow(trackIndex:Int, laneIndex:Int, rowIndex:Int, rowWidth:Int):Array<GlyphModel> {
		var columnIndex = laneColumnsMap[trackIndex][laneIndex];
		return [for (i in 0...rowWidth) glyphs.get(columnIndex + i, rowIndex)];
	}

	function focusCursor(cursor:NavigatorCursor) {
		var g = getFocusSingle(cursor);

		this.cursor.x = g.glyph.x + Std.int(this.cursor.w * 0.5);
		this.cursor.y = g.glyph.y + Std.int(this.cursor.h * 0.5);
		cursorRender.updateGraphicsBuffers();
		updateStatusLine(cursor);
		// trace('cursor pos ${this.cursor.x} ${this.cursor.y}');
	}
	
	function updateStatusLine(cursor:NavigatorCursor) {
		var text = '${tracker.information()}';
		var padChars = StringTools.rpad(text, " ", statusLine.length);
		glyphRender.fontProgram.lineSetChars(statusLine, padChars);
	}

	function updateText(cursor:NavigatorCursor, update:LaneUpdate) {
		if (update.entireLane) {
			if (update.changeRowcountBy != 0) {
				alterTrackViewLengths(update.changeRowcountBy, cursor.trackIndex);
			}
			updateLaneText(cursor.trackIndex);
		} else {
			updateRowText(cursor.trackIndex, cursor.rowIndex);
		}
	}

	var playHeads:Array<Shape> = [];

	function updateHeads(track:Int) {
		var y = tracker.tracks[track].playIndex * (glyphRender.fontProgram.fontStyle.height + (glyphRender.fontProgram.fontStyle.height * 0.5));
		trace('update heads y: $y');
		
		for(s in playHeads){
			// todo ! individual lanes as well as tracks
			s.y = y;
		}
	}

	var waves = 2;
	var gain = 0.02;
	var elapsedTicks:Int = 0;

	public function onTick(deltaMs:Int):Void {
		// todo - track down the bug in stage 'layers' not calling updateGraphicsBuffers 
		headsRender.updateGraphicsBuffers();
		elapsedTicks++;
		glyphs.onTick(deltaMs);
		glyphs.draw();
	}

	var glyphs:GlyphLayer;
	var glyphRender:GlyphFrames;

	public function onKeyDown(code:KeyCode, modifier:KeyModifier) {
		tracker.handleKeyDown({keyCode: code, modifier: modifier});
	}

	var cursorRender:DrawShapes;
	var headsRender:DrawShapes;

	var cursor:Shape;

	function updateRowText(trackIndex:Int, rowIndex:Int) {
		var lane = tracker.laneUnderCursor();
		var glyphs = getFocusRow(trackIndex, lane.index, rowIndex, lane.numColumns);
		var data = lane.formatRow(rowIndex);
		for (i => cell in data) {
			glyphs[i].char = cell.char.charCodeAt(0);
		}
	}

	function updateLaneText(trackIndex:Int) {
		var lane = tracker.laneUnderCursor();
		for (rowIndex in 0...lane.numRows) {
			if (rowIndex > lane.rows.length - 1) {
				// stop updating lines because they are actually empty
				break;
			}
			var data = lane.formatRow(rowIndex);
			updateGlyphs(data, trackIndex, lane.index, rowIndex);
		}
	}

	inline function updateGlyphs(data:Array<{char:String, column:ColumnType}>, trackIndex:Int, laneIndex:Int, rowIndex:Int) {
		var glyphs = getFocusRow(trackIndex, laneIndex, rowIndex, data.length);
		for (i => cell in data) {
			glyphs[i].char = cell.char.charCodeAt(0);
		}
	}

	function alterTrackViewLengths(changeRowCountBy:Int, trackIndex:Int) {
		for (lane in tracker.tracks[trackIndex].lanes) {
			for (rowIndex in 0...lane.numRows) {
				var data = lane.formatRow(rowIndex);
				updateGlyphs(data, trackIndex, lane.index, rowIndex);
			}
		}
		// if (changeRowCountBy > 0) {
		// }
		// else{

		// }
	}

	public function addTrack(track:TrackDefinition) {
		tracker.addTrack(track);
	}

	public function toggleRunning() {
		tracker.toggleIsStarted();
	}

	var tracker:Tracker;

	var statusLine:Line<FontStyle>;
}

typedef TrackGlyphs = {
	rows:Array<Array<GlyphModel>>
}
