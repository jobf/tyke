package tyke.jam;

import peote.text.Line;
import tyke.Graphics;
import echo.Body;
import echo.World;

using tyke.jam.ArrayExtensions;

class ClickHandler {
	public var group(default, null):Array<UiEntity> = [];
	public var targets(default, null):Array<Body> = [];

	public function new(cursor:Body, world:World) {
		this.cursor = cursor;
		this.world = world;
		world.add(cursor);

		world.listen(targets, cursor, {
			enter: onItemOver,
			exit: onItemLeave,
		});
	}

	// public function update(deltaMs:Float) {
	// 	// group.all((item)->item.update(deltaMs));
	// }

	public function listenForClicks(extraTargets:Array<Body>) {
		world.listen(extraTargets, cursor, {
			enter: onItemOver,
			exit: onItemLeave,
		});
	}

	public function onMouseDown() {
		for (item in itemsUnderMouse) {
			item.click();
		}
	}

	// todo check that the Body arguments are always in this order?
	function onItemOver(cursor:Body, item:Body, collisions:Array<CollisionData>) {
		// trace('mouseover');
		var entity:UiEntity = item.uiEntity;
		if (entity != null) {
			if (!itemsUnderMouse.contains(entity)) {
				// trace('mouseover remembered');
				itemsUnderMouse.push(entity);

				// entity.setColor(Global.onHoverColor);
			}
		}
	}

	// todo check that the Body arguments are always in this order?
	function onItemLeave(cursor:Body, item:Body) {
		// trace('mouseleave');
		var entity:UiEntity = item.uiEntity;

		if (entity != null && itemsUnderMouse.length > 0) {
			if (itemsUnderMouse.contains(entity)) {
				itemsUnderMouse.remove(entity);
				// entity.setColor(...);
				// trace('mouseleave discard');
			}
		}
	}

	public function registerUiEntity(entity:UiEntity) {
		targets.push(entity.body);
		group.push(entity);
		world.add(entity.body);
	}

	var cursor:Body;
	var world:World;
	var itemsUnderMouse:Array<UiEntity> = [];
}

class TextButton {
	var line:Line<FontStyle>;

	public var onClick:TextButton->Void;

	public function new(world:World, shapeRenderer:ShapeRenderer, fontProgram:FontProgram<FontStyle>, color:Color, geometry:RectangleGeometry, text:String) {
		var body = new Body({
			kinematic: true, // ! important !
			x: geometry.x,
			y: geometry.y,
			shape: {
				width: geometry.x,
				height: geometry.y,
				solid: false,
			}
		});
		var textX = body.x - geometry.width * 0.5;
		var textY = body.y - fontProgram.fontStyle.height * 0.5;
		line = fontProgram.createLine(text, textX, textY);
	}

	public function click() {
		if (onClick != null) {
			onClick(this);
		}
	}
}

typedef ButtonConfig = {text:String, action:UiEntity->Void, color:Color}

class ButtonGrid {
	public function new(clickHandler:ClickHandler, shapeRenderer:ShapeRenderer, fontProgram:FontProgram<FontStyle>, world:World, buttons:Array<ButtonConfig>,
			container:RectangleGeometry, margin:Int, rows:Int, columns:Int) {
		container.width -= Std.int(margin * 0.5);
		container.height -= Std.int(margin * 0.5);
		container.x += margin;
		container.y += margin;

		// todo - pass numRows and numCOlumns in
		var buttonWidth = Std.int(container.width / columns);
		var buttonHeight = Std.int(container.height / rows);

		var i = 0;
		for (r in 0...rows) {
			for (c in 0...columns) {
				var buttonConfig = buttons[i];
				if (buttonConfig == null) {
					// no more to display
					break;
				}

				var buttonX = Std.int(container.x + (c * buttonWidth) + buttonWidth * 0.5);
				var buttonY = Std.int(container.y + (r * buttonHeight) + buttonHeight * 0.5);

				var body = new Body({
					shape: {
						solid: false,
						width: buttonWidth,
						height: buttonHeight,
					},
					kinematic: true,
					x: buttonX,
					y: buttonY,
				});

				var bg = shapeRenderer.makeShape(buttonX, buttonY, buttonWidth, buttonHeight, RECT, buttonConfig.color);
				var button = new UiEntity(body, bg, fontProgram, buttonConfig.action, buttonConfig.text);
				clickHandler.registerUiEntity(button);
				i++;
			}
		}
	}
}

class UiEntity {
	public var body(default, null):Body;

	var background(default, null):Shape;
	var label(default, null):Line<FontStyle>;
	var onClick:UiEntity->Void;
	var fontProgram:FontProgram<FontStyle>;

	public function new(body:Body, bg:Shape, fontProgram:FontProgram<FontStyle>, onClick:UiEntity->Void, labelText:String) {
		this.body = body;
        this.body.uiEntity = this;
		this.background = bg;
		this.onClick = onClick;
		this.fontProgram = fontProgram;
		var textX = bg.w * 0.5;
		var textY = body.y - fontProgram.fontStyle.height * 0.5;
		label = this.fontProgram.createLine(labelText, textX, textY);
		var offsetX = label.x - (label.textSize * 0.5);
		this.fontProgram.lineSetPosition(label, offsetX, label.y);
		this.fontProgram.lineUpdate(label);
	}

	public function over() {}

	public function out() {}

	public function click() {
		onClick(this);
	}

	public function setColor(?bgColor:Color, ?labelColor:Color) {
		if (bgColor != null) {
			background.color = bgColor;
		}
		if (labelColor != null) {
			fontProgram.fontStyle.color = labelColor;
			// fontProgram.
		}
	}
}
