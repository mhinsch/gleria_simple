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



### include all the other pieces of code

push!(LOAD_PATH, pwd()) # let Julia find local packages

include("model.jl")
include("setup_world.jl")
include("analysis.jl")


### prepare the simulation


function setup(par, seed)
	Random.seed!(seed)

	model = Model(par.r_beta)

	model.space = setup_grid(par.x, par.y)
	for s in model.space
		s.suitability = rand()
	end

	model.space[(size(model.space).÷2)...].status = colonised

	for i in 1:(par.n_settled-1)
		rand(model.space).status = colonised
	end

	Gleria(model)
end



function prepare_outfiles(fname)
	logfile = open(fname, "w")
	print_header(logfile, Data)
	logfile
end

