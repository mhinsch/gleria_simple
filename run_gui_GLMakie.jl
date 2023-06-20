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


using GLMakie

include("main_util.jl")

add_to_load_path!("./lib/")

using ParamUtils

include("params.jl")
include("setup.jl")

function disp!(wd, model)
	s = size(model.space)
	for y in 1:s[1], x in 1:s[2]
		wd[y, x] = model.space[y, x].status == colonised ? 1 : 0
	end
end

function main()
	
	# *** parameters and command line
	
	# this creates parameters with default values as defined in params.jl,
	# then overrides that with values that are provided as cmdl args
    allpars, args = load_parameters(ARGS, Params, cmdl = (
	    # additional cmdl args that are not part of params.jl
		["--rand-seed", "-r"],
		Dict(
			:help => "random seed",
			:arg_type => Int,
			:default => 42),
		["--stop-time", "-t"],
		Dict(
			:help => "at which time to stop the simulation",
			:arg_type => Float64, 
			:default => 0.0),
		["--max-step", "-m"],
		Dict(
			:help => "upper limit for simulated time per frame",
			:arg_type => Float64,
			:default => 1.0),
		["--quit-on-stop", "-q"],
		Dict(
			:help => "whether to quit when stop-time is reached",
			:action => :store_true) )
		)
		
	pars = allpars[1]
	# end of sim
	t_stop :: Float64 = args[:stop_time]
	# max step size
	max_step :: Float64 = args[:max_step]
	
	seed :: Int = args[:rand_seed]
	
    # *** set up model 
        
	logfile = prepare_outfiles("log_file.txt")
	sim = setup(pars, seed)
	model = sim.model
	init_events(sim)
	
	# *** setup gui
	
	world_disp = Observable(zeros(size(model.space)))
	disp!(world_disp[], model)
	fig = Figure()
	heatmap(fig[1, 1], world_disp, colormap = [:green, :red], overdraw=true)
	graphs1 = Observable([[0.0],[0.0]]) 
	axis, plots = series(fig[1, 2][1, 1], graphs1)
	
	display(fig)
	
	t = 1.0
	step = max_step
	last = 0

	pause = false
	quit = false
	while ! quit
		# don't do anything if we are in pause mode
		if !pause && !(t_stop > 0 && t >= t_stop)
			t1 = time()
			step_until!(sim, t) # run internal scheduler up to the next time step
			
			# we want the analysis to happen at every integral time step
			if (now = trunc(Int, t)) >= last
				# in case we skipped a step (shouldn't happen, but just in case...)
				for i in last:now
					# print all stats to file
					data = observe(Data, model, i)
					log_results(logfile, data)
					# we can just reuse the observation results
					push!(graphs1[][1], data.empty.n)
					push!(graphs1[][2], data.colonised.n)
					#add_value!(graphs[3], data.col_neighbours.mean)
				end
				# remember when we did the last data output
				last = now
			end

			# measure (real-world) time it took to simulate one step
			dt = time() - t1

			# adjust simulation step size
			if dt > 0.05
				step /= 1.1
			elseif dt < 0.01 && step < max_step # this is a simple model, so let's limit
				step *= 1.1                # max step size to about 1
			end
			
			t += step

			println(t)
		end
		
		if t_stop > 0 && t >= t_stop && args[:quit_on_stop] 
			break
		end
		
		disp!(world_disp[], model)
		notify(world_disp)
		autolimits!(axis)
		notify(graphs1)
	end
	
	# *** cleanup

	close(logfile)
end


if ! isinteractive()
    @time main()
end

