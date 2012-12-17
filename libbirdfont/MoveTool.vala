/*
    Copyright (C) 2012 Johan Mattsson

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

using Math;
using Cairo;

namespace Supplement {

class MoveTool : Tool {

	bool move_path = false;
	double last_x = 0;
	double last_y = 0;

	bool resize_path = false;
	Path? resized_path = null;
	double last_resize_y;
	
	ImageSurface? resize_handle;
	
	public MoveTool (string n) {
		base (n, _("Move paths"), 'm', CTRL);
		
		resize_handle = Icons.get_icon ("resize_handle.png");
	
		select_action.connect((self) => {
		});

		deselect_action.connect((self) => {
			Glyph glyph = MainWindow.get_current_glyph ();
			glyph.clear_active_paths ();
		});
				
		press_action.connect((self, b, x, y) => {
			Glyph glyph = MainWindow.get_current_glyph ();
						
			glyph.store_undo_state ();
			
			foreach (Path p in glyph.active_paths) {
				if (is_over_resize_handle (p, x, y)) {
					resize_path = true;
					resized_path = p;
					last_resize_y = y;
					return;
				}
			}
			
			if (resized_path != null) {
				if (is_over_resize_handle ((!) resized_path, x, y)) {
					resize_path = true;
					last_resize_y = y;
					return;					
				}
			}
			
			if (!glyph.is_over_selected_path (x, y)) {
				if (!glyph.select_path (x, y)) {
					glyph.clear_active_paths ();
				}
			}
			
			move_path = true;
				
			last_x = x;
			last_y = y;
		});

		release_action.connect((self, b, x, y) => {
			Glyph glyph = MainWindow.get_current_glyph ();
			
			move_path = false;
			resize_path = false;
				
			if (GridTool.is_visible ()) {
				foreach (Path p in glyph.active_paths) {
					tie_path_to_grid (p, x, y);
				}
			}
		});
		
		move_action.connect ((self, x, y)	 => {
			Glyph glyph = MainWindow.get_current_glyph ();
			double dx = last_x - x;
			double dy = last_y - y; 
			double p = PenTool.precision;
			Path rp;
			double h, ratio;
			
			if (move_path) {
				foreach (Path path in glyph.active_paths) {
					path.move (glyph.ivz () * -dx * p, glyph.ivz () * dy * p);
				}
			}
			
			if (resize_path) {
				return_if_fail (!is_null (resized_path));
				rp = (!) resized_path;
				h = rp.xmax - rp.xmin;
				
				ratio = 1;
				ratio -= 0.7 * p * (Glyph.path_coordinate_y (last_resize_y) - Glyph.path_coordinate_y (y)) / h;
				
				rp.resize (ratio);
				last_resize_y = y;
			}

			last_x = x;
			last_y = y;

			MainWindow.get_glyph_canvas ().redraw ();
		});
		
		key_press_action.connect ((self, keyval) => {
			Glyph g = MainWindow.get_current_glyph ();
			
			if (keyval == Key.DEL) {
				foreach (Path p in g.active_paths) {
					g.path_list.remove (p);
					g.update_view ();
				}
			}
		});
		
		draw_action.connect ((self, cr, glyph) => {
			Glyph g = MainWindow.get_current_glyph ();
			ImageSurface img = (!) resize_handle;
		
			foreach (Path p in g.active_paths) {
				cr.set_source_surface (img, Glyph.reverse_path_coordinate_x (p.xmax) - 10, Glyph.reverse_path_coordinate_y (p.ymax) - 10);
				cr.paint ();	
			}
			
			if (resized_path != null) {
				cr.set_source_surface (img, Glyph.reverse_path_coordinate_x (((!) resized_path).xmax) - 10, Glyph.reverse_path_coordinate_y (((!)resized_path).ymax) - 10);
				cr.paint ();
			}
		});
	}

	bool is_over_resize_handle (Path p, double x, double y) {
		double handle_x = Math.fabs (Glyph.reverse_path_coordinate_x (p.xmax)); 
		double handle_y = Math.fabs (Glyph.reverse_path_coordinate_y (p.ymax));
		return fabs (handle_x - x + 10) < 20 && fabs (handle_y - y + 10) < 20;
	}

	void tie_path_to_grid (Path p, double x, double y) {
		double sx, sy, qx, qy;	
		
		// tie to grid
		sx = p.xmax;
		sy = p.ymax;
		qx = p.xmin;
		qy = p.ymin;
		
		GridTool.tie_coordinate (ref sx, ref sy);
		GridTool.tie_coordinate (ref qx, ref qy);
		
		if (Math.fabs (qy - p.ymin) < Math.fabs (sy - p.ymax)) {
			p.move (0, qy - p.ymin);
		} else {
			p.move (0, sy - p.ymax);
		}

		if (Math.fabs (qx - p.xmin) < Math.fabs (sx - p.xmax)) {
			p.move (qx - p.xmin, 0);
		} else {
			p.move (sx - p.xmax, 0);
		}		
	}

}

}