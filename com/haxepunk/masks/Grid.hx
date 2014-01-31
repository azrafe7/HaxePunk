package com.haxepunk.masks;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Graphics;
import flash.geom.Point;
import flash.geom.Rectangle;
import com.haxepunk.HXP;
import com.haxepunk.Mask;

/**
 * Uses a hash grid to determine collision, faster than
 * using hundreds of Entities for tiled levels, etc.
 */
class Grid extends Hitbox
{
	/**
	 * If x/y positions should be used instead of columns/rows (the default). Columns/rows means 
	 * screen coordinates relative to the width/height specified in the constructor. X/y means 
	 * grid coordinates, relative to the grid size.
	 */
	public var usePositions:Bool;


	/**
	 * Constructor. The actual size of the grid is determined by dividing the width/height by
	 * tileWidth/tileHeight, and stored in the properties columns/rows.
	 * @param	width			Width of the grid, in pixels.
	 * @param	height			Height of the grid, in pixels.
	 * @param	tileWidth		Width of a grid tile, in pixels.
	 * @param	tileHeight		Height of a grid tile, in pixels.
	 * @param	x				X offset of the grid.
	 * @param	y				Y offset of the grid.
	 */
	public function new(width:Int, height:Int, tileWidth:Int, tileHeight:Int, x:Int = 0, y:Int = 0)
	{
		super();

		// check for illegal grid size
		if (width == 0 || height == 0 || tileWidth == 0 || tileHeight == 0)
		{
			throw "Illegal Grid, sizes cannot be 0.";
		}

		_rect = HXP.rect;
		_point = HXP.point;
		_point2 = HXP.point2;

		// set grid properties
		columns = Std.int(width / tileWidth);
		rows = Std.int(height / tileHeight);
		
		data = new BitmapData(columns, rows, true, 0);
	
		_tile = new Rectangle(0, 0, tileWidth, tileHeight);
		_x = x;
		_y = y;
		_width = width;
		_height = height;
		usePositions = false;

		// set callback functions
		_check.set(Type.getClassName(Mask), collideMask);
		_check.set(Type.getClassName(Hitbox), collideHitbox);
		_check.set(Type.getClassName(Pixelmask), collidePixelmask);
		_check.set(Type.getClassName(Imagemask), collidePixelmask);
		_check.set(Type.getClassName(Grid), collideGrid);
	}

	/**
	 * Sets the value of the tile.
	 * @param	column		Tile column.
	 * @param	row			Tile row.
	 * @param	solid		If the tile should be solid.
	 */
	public function setTile(column:Int = 0, row:Int = 0, solid:Bool = true)
	{
		if (usePositions)
		{
			column = Std.int(column / _tile.width);
			row = Std.int(row / _tile.height);
		}
		data.setPixel32(column, row, solid ? 0xFFFFFFFF : 0);
	}

	/**
	 * Makes the tile non-solid.
	 * @param	column		Tile column.
	 * @param	row			Tile row.
	 */
	public inline function clearTile(column:Int = 0, row:Int = 0)
	{
		setTile(column, row, false);
	}

	/**
	 * Gets the value of a tile.
	 * @param	column		Tile column.
	 * @param	row			Tile row.
	 * @return	tile value.
	 */
	public function getTile(column:Int = 0, row:Int = 0):Bool
	{
		if (usePositions)
		{
			column = Std.int(column / _tile.width);
			row = Std.int(row / _tile.height);
		}
		return data.getPixel32(column, row) != 0;
	}

	/**
	 * Sets the value of a rectangle region of tiles.
	 * @param	column		First column.
	 * @param	row			First row.
	 * @param	width		Columns to fill.
	 * @param	height		Rows to fill.
	 * @param	solid		Value to fill.
	 */
	public function setRect(column:Int = 0, row:Int = 0, width:Int = 1, height:Int = 1, solid:Bool = true)
	{
		if (usePositions)
		{
			column = Std.int(column / _tile.width);
			row    = Std.int(row / _tile.height);
			width  = Std.int(width / _tile.width);
			height = Std.int(height / _tile.height);
		}

		_rect.x = column;
		_rect.y = row;
		_rect.width = width;
		_rect.height = height;
		data.fillRect(_rect, solid ? 0xFFFFFFFF : 0);
	}

	/**
	 * Makes the rectangular region of tiles non-solid.
	 * @param	column		First column.
	 * @param	row			First row.
	 * @param	width		Columns to fill.
	 * @param	height		Rows to fill.
	 */
	public inline function clearRect(column:Int = 0, row:Int = 0, width:Int = 1, height:Int = 1)
	{
		setRect(column, row, width, height, false);
	}

	/**
	* Loads the grid data from a string.
	* @param	str			The string data, which is a set of tile values (0 or 1) separated by the columnSep and rowSep strings.
	* @param	columnSep	The string that separates each tile value on a row, default is ",".
	* @param	rowSep		The string that separates each row of tiles, default is "\n".
	*/
	public function loadFromString(str:String, columnSep:String = ",", rowSep:String = "\n")
	{
		var row:Array<String> = str.split(rowSep),
			rows:Int = row.length,
			col:Array<String>, cols:Int;
		for (y in 0...rows)
		{
			if (row[y] == '') continue;
			col = row[y].split(columnSep);
			cols = col.length;
			for (x in 0...cols)
			{
				if (col[x] == '') continue;
				setTile(x, y, Std.parseInt(col[x]) > 0);
			}
		}
	}

	/**
	* Loads the grid data from an array.
	* @param	array	The array data, which is a set of tile values (0 or 1)
	*/
	public function loadFrom2DArray(array:Array<Array<Int>>)
	{
		for (y in 0...array.length)
		{
			for (x in 0...array[0].length)
			{
				setTile(x, y, array[y][x] > 0);
			}
		}
	}

	/**
	* Saves the grid data to a string.
	* @param	columnSep	The string that separates each tile value on a row, default is ",".
	* @param	rowSep		The string that separates each row of tiles, default is "\n".
	* 
	* @return The string version of the grid.
	*/
	public function saveToString(columnSep:String = ",", rowSep:String = "\n", 
		solid:String = "true", empty:String = "false"): String
	{
		var s:String = '',
			x:Int, y:Int;
		for (y in 0...rows)
		{
			for (x in 0...columns)
			{
				s += Std.string(getTile(x, y) ? solid : empty);
				if (x != columns - 1) s += columnSep;
			}
			if (y != rows - 1) s += rowSep;
		}
		return s;
	}
	
	/**
	 *  Make a copy of the grid.
	 * 
	 * @return Return a copy of the grid.
	 */
	public function clone():Grid
	{
		var cloneGrid = new Grid(_width, _height, Std.int(_tile.width), Std.int(_tile.height), _x, _y);
		for ( y in 0...rows)
		{
			for (x in 0...columns)
			{
				cloneGrid.setTile(x,y,getTile(x,y));
			}
		}
		return cloneGrid;
	}

	/**
	 * The tile width.
	 */
	public var tileWidth(get_tileWidth, never):Int;
	private inline function get_tileWidth():Int { return Std.int(_tile.width); }

	/**
	 * The tile height.
	 */
	public var tileHeight(get_tileHeight, never):Int;
	private inline function get_tileHeight():Int { return Std.int(_tile.height); }

	/**
	 * How many columns the grid has
	 */
	public var columns(default, null):Int;

	/**
	 * How many rows the grid has.
	 */
	public var rows(default, null):Int;

	/**
	 * The grid data.
	 */
	public var data(default, null):BitmapData;

	/** @private Collides against an Entity. */
	override private function collideMask(other:Mask):Bool
	{
		_rect.x = other.parent.x - other.parent.originX - parent.x + parent.originX;
		_rect.y = other.parent.y - other.parent.originY - parent.y + parent.originY;
		_point.x = Std.int((_rect.x + other.parent.width - 1) / _tile.width) + 1;
		_point.y = Std.int((_rect.y + other.parent.height -1) / _tile.height) + 1;
		_rect.x = Std.int(_rect.x / _tile.width);
		_rect.y = Std.int(_rect.y / _tile.height);
		_rect.width = _point.x - _rect.x;
		_rect.height = _point.y - _rect.y;
	#if flash
		return data.hitTest(HXP.zero, 1, _rect);
	#else
		return Mask.hitTest(data, HXP.zero, 1, _rect);
	#end
	}

	/** @private Collides against a Hitbox. */
	override private function collideHitbox(other:Hitbox):Bool
	{
		_rect.x = other.parent.x + other._x - parent.x - _x;
		_rect.y = other.parent.y + other._y - parent.y - _y;
		_point.x = Std.int((_rect.x + other._width - 1) / _tile.width) + 1;
		_point.y = Std.int((_rect.y + other._height - 1) / _tile.height) + 1;
		_rect.x = Std.int(_rect.x / _tile.width);
		_rect.y = Std.int(_rect.y / _tile.height);
		_rect.width = _point.x - _rect.x;
		_rect.height = _point.y - _rect.y;
	#if flash
		return data.hitTest(HXP.zero, 1, _rect);
	#else
		return Mask.hitTest(data, HXP.zero, 1, _rect);
	#end
	}

	/** @private Collides against a Pixelmask. */
	private function collidePixelmask(other:Pixelmask):Bool
	{
		var x1:Int = Std.int(other.parent.x + other.x - parent.x - _x),
			y1:Int = Std.int(other.parent.y + other.y - parent.y - _y),
			x2:Int = Std.int((x1 + other.width - 1) / _tile.width),
			y2:Int = Std.int((y1 + other.height - 1) / _tile.height);
		_point.x = x1;
		_point.y = y1;
		x1 = Std.int(x1 / _tile.width);
		y1 = Std.int(y1 / _tile.height);
		_tile.x = x1 * _tile.width;
		_tile.y = y1 * _tile.height;
		var xx:Int = x1;
		
		while (y1 <= y2)
		{
			while (x1 <= x2)
			{
				if (data.getPixel32(x1, y1) != 0)
				{
				#if flash
					if (other.data.hitTest(_point, other.threshold, _tile)) return true;
				#else
					if (Mask.hitTest(other.data, _point, other.threshold, _tile)) return true;
				#end
				}
				x1++;
				_tile.x += _tile.width;
			}
			x1 = xx;
			y1++;
			_tile.x = x1 * _tile.width;
			_tile.y += _tile.height;
		}
		
		return false;
	}

	/** @private Collides against a Grid. */
	private function collideGrid(other:Grid):Bool
	{
		// Find the X edges
		var ax1:Float = parent.x + _x;
		var ax2:Float = ax1 + _width;
		var bx1:Float = other.parent.x + other._x;
		var bx2:Float = bx1 + other._width;
		if (ax2 < bx1 || ax1 > bx2) return false;
		
		// Find the Y edges
		var ay1:Float = parent.y + _y;
		var ay2:Float = ay1 + _height;
		var by1:Float = other.parent.y + other._y;
		var by2:Float = by1 + other._height;
		if (ay2 < by1 || ay1 > by2) return false;
		
		// Find the overlapping area
		var ox1:Float = ax1 > bx1 ? ax1 : bx1;
		var oy1:Float = ay1 > by1 ? ay1 : by1;
		var ox2:Float = ax2 < bx2 ? ax2 : bx2;
		var oy2:Float = ay2 < by2 ? ay2 : by2;
		
		// Find the smallest tile size, and snap the top and left overlapping
		// edges to that tile size. This ensures that corner checking works
		// properly.
		var tw:Float, th:Float;
		if (_tile.width < other._tile.width)
		{
			tw = _tile.width;
			ox1 -= parent.x + _x;
			ox1 = Std.int(ox1 / tw) * tw;
			ox1 += parent.x + _x;
		}
		else
		{
			tw = other._tile.width;
			ox1 -= other.parent.x + other._x;
			ox1 = Std.int(ox1 / tw) * tw;
			ox1 += other.parent.x + other._x;
		}
		if (_tile.height < other._tile.height)
		{
			th = _tile.height;
			oy1 -= parent.y + _y;
			oy1 = Std.int(oy1 / th) * th;
			oy1 += parent.y + _y;
		}
		else
		{
			th = other._tile.height;
			oy1 -= other.parent.y + other._y;
			oy1 = Std.int(oy1 / th) * th;
			oy1 += other.parent.y + other._y;
		}
		
		// Step through the overlapping rectangle
		var y:Float = oy1;
		var x:Float = 0;
		while (y < oy2) {
			// Get the row indices for the top and bottom edges of the tile
			var ar1:Int = Std.int((y - parent.y - _y) / _tile.height);
			var br1:Int = Std.int((y - other.parent.y - other._y) / other._tile.height);
			var ar2:Int = Std.int(((y - parent.y - _y) + (th - 1)) / _tile.height);
			var br2:Int = Std.int(((y - other.parent.y - other._y) + (th - 1)) / other._tile.height);
			
			x = ox1;
			while (x < ox2) {
				// Get the column indices for the left and right edges of the tile
				var ac1:Int = Std.int((x - parent.x - _x) / _tile.width);
				var bc1:Int = Std.int((x - other.parent.x - other._x) / other._tile.width);
				var ac2:Int = Std.int(((x - parent.x - _x) + (tw - 1)) / _tile.width);
				var bc2:Int = Std.int(((x - other.parent.x - other._x) + (tw - 1)) / other._tile.width);
				
				// Check all the corners for collisions
				if ((data.getPixel32(ac1, ar1) != 0 && other.data.getPixel32(bc1, br1) != 0)
				 || (data.getPixel32(ac2, ar1) != 0 && other.data.getPixel32(bc2, br1) != 0)
				 || (data.getPixel32(ac1, ar2) != 0 && other.data.getPixel32(bc1, br2) != 0)
				 || (data.getPixel32(ac2, ar2) != 0 && other.data.getPixel32(bc2, br2) != 0))
				{
					return true;
				}
				x += tw;
			}
			y += th;
		}
		
		return false;
	}

	override public function debugDraw(graphics:Graphics, scaleX:Float, scaleY:Float):Void
	{
		HXP.point.x = (_x + parent.x - HXP.camera.x) * HXP.screen.fullScaleX;
		HXP.point.y = (_y + parent.y - HXP.camera.y) * HXP.screen.fullScaleY;

		graphics.beginFill(0x0000FF, 0.3);
		var stepX = tileWidth * HXP.screen.fullScaleX,
			stepY = tileHeight * HXP.screen.fullScaleY,
			pos = HXP.point.x + stepX;

		for (i in 1...columns)
		{
			graphics.drawRect(pos, HXP.point.y, 1, _height * HXP.screen.fullScaleX);
			pos += stepX;
		}

		pos = HXP.point.y + stepY;
		for (i in 1...rows)
		{
			graphics.drawRect(HXP.point.x, pos, _width * HXP.screen.fullScaleY, 1);
			pos += stepY;
		}

		HXP.rect.y = HXP.point.y;
		for (y in 0...rows)
		{
			HXP.rect.x = HXP.point.x;
			for (x in 0...columns)
			{
				if (data.getPixel32(x, y) != 0)
				{
					graphics.drawRect(HXP.rect.x, HXP.rect.y, stepX, stepY);
				}
				HXP.rect.x += stepX;
			}
			HXP.rect.y += stepY;
		}
		graphics.endFill();
	}

	public function squareProjection(axis:Point, point:Point):Void
	{
		if (axis.x < axis.y)
		{
			point.x = axis.x;
			point.y = axis.y;
		}
		else
		{
			point.y = axis.x;
			point.x = axis.y;
		}
	}

	// Grid information.
	private var _tile:Rectangle;
	private var _rect:Rectangle;
	private var _point:Point;
	private var _point2:Point;
}
