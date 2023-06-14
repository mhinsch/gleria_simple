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

using Raylib
using Raylib: rayvector

# make this less annoying
const RL = Raylib

include("main_util.jl")

add_to_load_path!("./lib/")


using SimpleGraph
using ParamUtils

include("params.jl")
include("setup.jl")
include("draw_gui.jl")



function main()
	
	# *** parameters and command line
	
	# this creates parameters with default values as defined in params.jl,
	# then overrides that with values that are provided as cmdl args
    pars, args = load_parameters(ARGS, Params, 
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
		["--max-step", "-m"],
		Dict(
			:help => "upper limit for simulated time per frame",
			:arg_type => Float64,
			:default => 1.0)
		)
		
	# end of sim
	t_stop = args[:stop_time]
	# max step size
	max_step = args[:max_step]
		
	# *** set up GUI
	
    scale = args[:gui_scale]
    screenWidth = floor(Int, 1600 * scale)
    screenHeight = floor(Int, 900 * scale)

    RL.InitWindow(screenWidth, screenHeight, "gleria 1.0")
    RL.SetTargetFPS(60)
    camera = RL.RayCamera2D(
        rayvector(screenWidth/2, screenHeight/2),
        rayvector(screenWidth/2, screenHeight/2),
        #rayvector(500, 500),
        0,
        1)
        
    # *** set up model 
        
	sim = setup(pars, args[:rand_seed])
	model = sim.model
	
	# *** output, graphs
	
	logfile = prepare_outfiles("log_file.txt")	
	graphs = [
		Graph{Int}(RL.GREEN), 
		Graph{Int}(RL.RED), 
		Graph{Float64}(RL.BLUE)] 
		#Graph{Int}(RL.WHITE)] 
		
		
	# *** main loop
	
	init_events(sim)
	
	t = 1.0
	step = max_step
	last_observe = 0
	
	pause = false
	while ! RL.WindowShouldClose()
		
		# *** simulation logic and analysis/output
			
		if !pause && !(t_stop > 0 && t >= t_stop)
			t1 = time()
			step_until!(sim, t) # run internal scheduler up to the next time step
			
			# we want the analysis to happen at every integral time step
			if (now = trunc(Int, t)) >= last_observe
				# in case we skipped a step (shouldn't happen, but just in case...)
				for i in last_observe:now
					# print all stats to file
					data = observe(Data, model, i)
					log_results(logfile, data)
					# we can just reuse the observation results
					add_value!(graphs[1], data.empty.n)
					add_value!(graphs[2], data.colonised.n)
					add_value!(graphs[3], data.col_neighbours.mean)
				end
				# remember when we did the last data output
				last_observe = now
			end

			t += step

			# measure (real-world) time it took to simulate one step
			dt = time() - t1

			# adjust simulation step size
			if dt > 0.05
				step /= 1.1
			elseif dt < 0.01 && step < max_step 
				step *= 1.1                
			end

			println(t)
		end

        if RL.IsKeyPressed(Raylib.KEY_SPACE)
            pause = !pause
            sleep(0.2)
        end
        
        # *** GUI stuff
        
        RL.BeginDrawing()

        RL.ClearBackground(RL.LIGHTGRAY)
        
        RL.BeginMode2D(camera)
        
        draw_world(model, 0, 0) 

        RL.EndMode2D()

        # draw graphs
        draw_graph(floor(Int, 2*screenWidth*1/3), 0, 
                   floor(Int, screenWidth*1/3), floor(Int, screenHeight/2)-20, 
                   graphs,
                   single_scale = true, 
                   labels = ["empty", "colonized", "n neighb"],
                   fontsize = floor(Int, 15 * scale))
		
		RL.EndDrawing()
	end
	
	RL.CloseWindow()	
	
	close(logfile)
end


if ! isinteractive()
    main()
end

