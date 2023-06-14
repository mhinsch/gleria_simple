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



include("main_util.jl")

add_to_load_path!("./lib/")


using ParamUtils

include("params.jl")
include("setup.jl")


function main()
	
	# *** parameters and command line
	
	# this creates parameters with default values as defined in params.jl,
	# then overrides that with values that are provided as cmdl args
    pars, args = load_parameters(ARGS, Params, 
		["--rand-seed", "-r"],
		Dict(
			:help => "random seed",
			:arg_type => Int,
			:default => 42),
		["--stop-time", "-t"],
		Dict(
			:help => "at which time to stop the simulation",
			:arg_type => Float64, 
			:default => 0.0)
		)
		
	# end of sim
	t_stop = args[:stop_time]
		
    # *** set up model 
        
	sim = setup(pars, args[:rand_seed])
	model = sim.model
	
	# *** output, graphs
	
	logfile = prepare_outfiles("log_file.txt")	
		
	# *** main loop
	
	init_events(sim)
	
	t = 1.0
	step = 1.0
	last_observe = 0

	while t_stop <= 0 || t < t_stop
		step_until!(sim, t) # run internal scheduler up to the next time step
		
		# we want the analysis to happen at every integral time step
		if (now = trunc(Int, t)) >= last_observe
			# in case we skipped a step (shouldn't happen, but just in case...)
			for i in last_observe:now
				# print all stats to file
				data = observe(Data, model, i)
				log_results(logfile, data)
			end
			# remember when we did the last data output
			last_observe = now
		end

		t += step

#		println(t)
	end
	
	close(logfile)
end



if ! isinteractive()
	@time main()
end



