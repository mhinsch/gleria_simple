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



# This package provides some nice convenience syntax for parameters.
# Specifically we can set default values for struct elements. A constructor is
# then created that a) has all struct elements as named args and b) sets the
# value of elements to the default values if they are not specified on calling
# the constructor
using Parameters


"Simulation parameters"
@with_kw struct Params
	# element documentation is automatically translated into commandline help text

	"colonisation rate"
	r_beta :: Float64 = 25

	"number of settled worlds to start with"
	n_settled	:: Int = 1

	"world topology (1=matrix, 2=geograph)"
	topology	:: Int = 1

	"world width (only matrix)"
	x 			:: Int = 1000
	"world height (only matrix)"
	y 			:: Int = 1000
end
