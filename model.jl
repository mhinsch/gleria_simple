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



### include library code

using Random

using MiniEvents


### declare agent type(s)

@enum Status empty colonised

mutable struct Sector
    status :: Status
    neighbours :: Vector{Sector}
	suitability :: Float64
end

Sector(s) = Sector(empty, [], s)
Sector(state, s) = Sector(state, [], s)



### declare simulation

mutable struct Model
    beta :: Float64
    
    space :: Matrix{Sector}
end

Model(b) = Model(b, Matrix{Sector}(undef, 0, 0))



### event-based: declare simulation processes

@events sector::Sector begin
	@debug
    @rate(@sim().model.beta * sector.suitability * count(s -> s.status == colonised, sector.neighbours)) ~
        sector.status == empty => 
            begin
                sector.status = colonised
                @r sector sector.neighbours
            end
end


@simulation Gleria Sector begin
	model :: Model
end


function init_events(sim)
    for sector in sim.model.space
        spawn!(sector, sim)
    end
end

