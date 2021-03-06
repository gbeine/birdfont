/*
    Copyright (C) 2012, 2014 Johan Mattsson

    This library is free software; you can redistribute it and/or modify 
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation; either version 3 of the 
    License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful, but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
    Lesser General Public License for more details.
*/

using Cairo;

namespace BirdFont {

public enum MenuDirection {
	DROP_DOWN,
	POP_UP;
}

public class DropMenu : GLib.Object {

	public delegate void Selected (MenuAction self);
	public signal void selected (DropMenu self);
	
	double x = -1;
	double y = -1;
	
	double menu_x = -1;
	
	bool menu_visible = false;

	Gee.ArrayList <MenuAction> actions = new Gee.ArrayList <MenuAction> ();

	const int item_height = 25;
	
	MenuDirection direction = MenuDirection.DROP_DOWN;
	
	ImageSurface? icon = null;
	
	public signal void signal_delete_item  (int item_index);
	
	public DropMenu (string icon_file = "") {
		if (icon_file != "") {
			icon = Icons.get_icon (@"$icon_file.png");
		}
	}
	
	public MenuAction get_action_index (int index) {
		if (!(0 <= index < actions.size)) {
			warning (@"No action for index $index.");
			return new MenuAction ("None");
		}
		return actions.get (index);
	}
	
	public void recreate_index () {
		int i = -1;
		foreach (MenuAction a in actions) {
			a.index = i;
			i++;
		}
	}
	
	public MenuAction get_action_no2 () {
		if (actions.size < 2) {
			warning ("No such action");
			return new MenuAction ("None");
		}
		
		return actions.get (1);
	}
	
	public void deselect_all () {
		foreach (MenuAction m in actions) {
			m.set_selected (false);
		}
	}
	
	public void set_direction (MenuDirection d) {
		direction = d;
	}
	
	public void close () {
		menu_visible = false;
	}
	
	public MenuAction add_item (string label) {
		MenuAction m = new MenuAction (label);
		add_menu_item (m);
		return m;
	}
	
	public void add_menu_item (MenuAction m) {
		m.parent = this;
		actions.add (m);
	}
		
	public bool is_over_icon (double px, double py) {
		if (x == -1 || y == -1) {
			return false;
		}
		
		return x - 5 < px < x + 12 + 5 && y - 5 < py < y + 12 + 5;
	}

	public bool menu_item_action (double px, double py) {
		MenuAction? action;
		MenuAction a;
		MenuAction ma;
		int index;
		
		if (menu_visible) {
			action = get_menu_action_at (px, py);
			
			if (action != null) {
				a = (!) action;

				// action for the delete button
				if (a.has_delete_button && menu_x + 88 - 7 < px < menu_x + 88 + 13) { 
					index = 0;
					ma = actions.get (0);
					while (true) {
						if (a == ma) {
							actions.remove_at (index);
							signal_delete_item (index);
							break;
						}
						
						if (ma == actions.get (actions.size - 1)) {
							break;
						} else {
							ma = actions.get (index + 1);
							index++;
						}
					}
					return false;
				} else {
					a.action (a);
					selected (this);
					menu_visible = false;
				}
				
				return true;
			}
		}
		
		return false;
	}
	
	public bool menu_icon_action (double px, double py) {		
		menu_visible = is_over_icon (px, py);
		return menu_visible;
	}
	
	MenuAction? get_menu_action_at (double px, double py) {
		double n = 0;
		double ix, iy;
		
		foreach (MenuAction item in actions) {
			ix = menu_x - 6;
			
			if (direction == MenuDirection.DROP_DOWN) {
				iy = y + 12 + n * item_height;
			} else {
				iy = y - 24 - n * item_height;
			}
	
			if (ix <= px <= ix + 100 && iy <= py <= iy + item_height) {
				return item;
			}
			
			n++;			
		}

		return null;
	}
	
	public void set_position (double px, double py) {
		x = px;
		y = py;
		
		if (x - 100 + 19 < 0) {
			menu_x = 10;
		} else {
			menu_x = x - 100 + 19;
		}
	}
	
	public void draw_menu (Context cr) {
		double ix, iy;
		int n;
		Pattern gradient;
		
		if (likely (!menu_visible)) {
			return;
		}
		
		cr.save ();
		cr.set_source_rgba (177/255.0, 177/255.0, 177/255.0, 1);
		cr.set_line_width (0);
		
		gradient = new Pattern.linear (menu_x, y - 3 * item_height, menu_x, y);
		gradient.add_color_stop_rgb (0, 177/255.0, 177/255.0, 177/255.0);
		gradient.add_color_stop_rgb (1, 234/255.0, 234/255.0, 234/255.0);
		
		cr.set_source (gradient);
		cr.rectangle (menu_x, y - actions.size * item_height, 94, actions.size * item_height);
		
		cr.fill_preserve ();
		cr.stroke ();
		cr.restore ();
		
		cr.save ();
		
		n = 0;
		foreach (MenuAction item in actions) {
			iy = y - 8 - n * item_height;
			ix = menu_x + 2;
			
			item.draw (ix, iy, cr);
			n++;
		}
		
		cr.restore ();
	}
	
	public void draw_icon (Context cr) {
		double alpha = 1;
		ImageSurface i = (!) icon;
		
		if (!menu_visible) {
			alpha = 0;
		}
		
		cr.save ();
		
		cr.set_source_rgba (234/255.0, 234/255.0, 234/255.0, alpha);
		
		cr.rectangle (x, y, 12, 12);
		cr.fill_preserve ();
		cr.stroke ();
		
		if (likely (icon != null && i.status () == Cairo.Status.SUCCESS)) {
			cr.set_source_surface (i, x, y + (12 - i.get_height ()) / 2.0);
			cr.paint ();
		} else {
			warning ("Failed to load icon.");
		}
		
		cr.restore ();
	}
}

}
