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


using SimpleDirectMediaLayer.LibSDL2

include("main_util.jl")

add_to_load_path!("./lib/")

using SimpleGui
using ParamUtils

include("params.jl")
include("setup.jl")
include("draw_gui_SDL.jl")

function main()
	
	# *** parameters and command line
	
	# this creates parameters with default values as defined in params.jl,
	# then overrides that with values that are provided as cmdl args
    allpars, args = load_parameters(ARGS, Params, cmdl = (
	    # additional cmdl args that are not part of params.jl
        ["--gui-scale"], 
	    Dict(
		    :help => "set gui scale", 
		    :default => 1.0, 
		    :arg_type => Float64),
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
		["--quit-on-stop", "-q"],
		Dict(
			:help => "whether to quit when stop-time is reached",
			:action => :store_true),
		["--max-step", "-m"],
		Dict(
			:help => "upper limit for simulated time per frame",
			:arg_type => Float64,
			:default => 1.0) )
		)
		
	pars = allpars[1]
	# end of sim
	t_stop :: Float64 = args[:stop_time]
	# max step size
	max_step :: Float64 = args[:max_step]
	
	seed :: Int = args[:rand_seed]
	
	# *** setup gui
	
	gui = setup_Gui("gleria 1.0", 1500, 1500, 2, 1)
	graphs = [Graph{Int}(green(255)), Graph{Int}(red(255)), Graph{Float64}(blue(255)), Graph{Int}(WHITE)] 
    # *** set up model 
        
	logfile = prepare_outfiles("log_file.txt")
	sim = setup(pars, seed)
	model = sim.model
	init_events(sim)
	
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
					add_value!(graphs[1], data.empty.n)
					add_value!(graphs[2], data.colonised.n)
					add_value!(graphs[3], data.col_neighbours.mean)
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
		
		event_ref = Ref{SDL_Event}()
        while Bool(SDL_PollEvent(event_ref))
            evt = event_ref[]
            evt_ty = evt.type
			if evt_ty == SDL_QUIT
                quit = true
                break
            elseif evt_ty == SDL_KEYDOWN
                scan_code = evt.key.keysym.scancode
                if scan_code == SDL_SCANCODE_ESCAPE || scan_code == SDL_SCANCODE_Q
					quit = true
					break
                elseif scan_code == SDL_SCANCODE_P || scan_code == SDL_SCANCODE_SPACE
					pause = !pause
                    break
                else
                    break
                end
            end
		end

		# draw gui to video memory
		draw(model, graphs, gui)
		# copy to screen
		render!(gui)
	end
	
	# *** cleanup

	close(logfile)
	SDL_Quit()
end


if ! isinteractive()
    @time main()
end

