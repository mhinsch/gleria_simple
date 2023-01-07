#   Copyright (C) 2020 Martin Hinsch <hinsch.martin@gmail.com>
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <https://www.gnu.org/licenses/>.



using SSDL
using SimpleGraph
using SimpleGui


### draw GUI

# draw world to canvas
function draw_world(canvas, model)
	xs = canvas.xsize - 1
	ys = canvas.ysize - 1

	# draw connections
#=	for p in model.pop
		x1 = trunc(Int, p.x * xs) + 1
		y1 = trunc(Int, p.y * ys) + 1

		for p2 in p.contacts
			x2 = trunc(Int, p2.x * xs) + 1
			y2 = trunc(Int, p2.y * ys) + 1

			line(canvas, x1, y1, x2, y2, red(255))
		end
	end
=#
	# draw sectors
	for x in 1:size(model.space)[1], y in 1:size(model.space)[2]
		s = model.space[x, y]
		if s.status == empty
			col = red(floor(Int, 255 * s.suitability))
		elseif s.status == colonised
			col = green(255)
		end
		
		circle_fill(canvas, x, y, 3, UInt32(col), true)
	end
end

# draw both panels to video memory
function draw(model, graphs, gui)
	clear!(gui.canvas)
	draw_world(gui.canvas, model)
	update!(gui.panels[1,1], gui.canvas)

	clear!(gui.canvas)
	draw_graph(gui.canvas, graphs)
	update!(gui.panels[2, 1], gui.canvas)
end

