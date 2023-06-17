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




### draw GUI

# draw world to canvas
function draw_world(model, xs=0, ys=0)
	# draw sectors
	for x in 1:size(model.space)[1], y in 1:size(model.space)[2]
		s = model.space[x, y]
		if s.status == empty
			col = RL.ColorFromNormalized(RL.rayvector(s.suitability, 0.0, 0.0, 1.0))
		elseif s.status == colonised
			col = RL.GREEN
		end
		RL.DrawPixel(x+xs, y+ys, col)
	end
end

