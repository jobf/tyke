package;

import samples.GlyphDemo;
import samples.Cascade;
import samples.ShapeDebug;
import tyke.Glyph;

import samples.TYKE;
class SampleApp extends App{
	var config:GlyphLoopConfig = {
		numCellsWide: 40,
		numCellsHigh: 40,
	}

	override function init(window:Window, ?config:GumConfig) {
		super.init(window, {
			framesPerSecond: 30,
			drawOnlyWhenRequested: false,
			displayWidth: 800,
			displayHeight: 600,
			displayIsScaled: true
		});
		initLoop();
	}

	function initLoop(){
		// override me	
	}
}

function assets() {
	return new Assets({
		fonts: ["assets/fonts/tiled/hack_ascii.json"],
		images: [
			"assets/images/bit-bonanza-food.png",
		]
	});
}

class GlyphDemoApp extends SampleApp {
	override function initLoop(){
		super.initLoop();
		gum.changeLoop(new GlyphDemo(config, assets()));
	}
}


class CascadeApp extends SampleApp {
	override function initLoop(){
		super.initLoop();
		gum.changeLoop(new Cascade(config, assets()));
	}
}


class TApp extends SampleApp {
	override function initLoop(){
		super.initLoop();
		gum.changeLoop(new TYKE(config, assets()));
	}
}



class ShapeDebugApp extends SampleApp {
	override function initLoop(){
		super.initLoop();
		gum.changeLoop(new ShapeLoop(assets()));
	}
}