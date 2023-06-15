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


function prepare()	
	# *** parameters and command line
	
	# this creates parameters with default values as defined in params.jl,
	# then overrides that with values that are provided as cmdl args
    pars, args = load_parameters(ARGS, Params, cmdl = ( 
		["--rand-seed", "-r"],
		Dict(:help => "random seed",
			:arg_type => Int,
			:default => 42), 
		["--stop-time", "-t"],
		Dict(:help => "at which time to stop the simulation",
			:arg_type => Float64, 
			:default => 0.0) )
		)
		
	t_s :: Float64 = args[:stop_time]
	seed :: Int = args[:rand_seed]
    # *** set up model 
        
	sim = setup(pars[1], seed)
	model = sim.model
	
	# *** output, graphs
	
	logfile = prepare_outfiles("log_file.txt")	
		
	# *** main loop
	
	sim, pars[1], logfile, t_s 
end

function run_steps(sim, pars, logfile, n)
	t = 1.0
	step = 1.0
	last_observe = 0

	while t < n
		step_until!(sim, t) # run internal scheduler up to the next time step
		
		# we want the analysis to happen at every integral time step
		if (now = trunc(Int, t)) >= last_observe
			# in case we skipped a step (shouldn't happen, but just in case...)
			for i in last_observe:now
				# print all stats to file
				data = observe(Data, sim.model, i)
				log_results(logfile, data)
			end
			# remember when we did the last data output
			last_observe = now
		end

		t += step

#		println(t)
	end
end

function finish(logfile)
	close(logfile)
end

#const s, p, l = prepare()

function run()
	@time s, p, l, t = prepare()
	#pp = Params()
	@time init_events(s)
	@time run_steps(s, p, l, t)
	@time finish(l)
end

run()
