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



### import analysis library

using MiniObserve


### setup some handy shortcuts

const MV = MeanVarAcc{Float64}		# mean, variance
const MM = MaxMinAcc{Float64}	# min, max
const I = Iterators


### declare analysis
# this generates a type Data to hold the results
# and overloads the functions observe, print_header and 
# log_results for that type

@observe Data model t_now begin
	@record "time" t_now

	@for a in model.space begin
		@stat("colonised", CountAcc) <| (a.status == colonised)
		@stat("empty", 	CountAcc) <| (a.status == empty)
	end

	@for a in I.filter(ag->ag.status==empty, model.space) begin
		@stat("col_neighbours", MV) <| Float64(count(n->n.status==colonised, a.neighbours))
	end

	# counting could also have been done like this:
	# @record "n_susceptible"	count(ag -> ag.status == susceptible, model.pop)
end

