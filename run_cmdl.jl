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



include("setup.jl")


### run simulation with given setup and parameters

function run_events(model, t_stop, logfile)
	t = 1.0
	step = 1.0
	last = 0

	while t_stop <= 0 || t < t_stop
		SIRm.upto!(t) # run internal scheduler up to the next time step
		
		# we want the analysis to happen at every integral time step
		if (now = trunc(Int, t)) >= last
			# in case we skipped a step (shouldn't happen, but just in case...)
			for i in last:now
				# print all stats to file
				print_stats_stat_log(logfile, model)
			end
			# remember when we did the last data output
			last = now
		end

		t += step

#		println(t)
	end
end


### run simulation with given setup and parameters

function run_steps(model, t_stop, logfile, ord)
	for t in 1:t_stop
		update!(model, ord)
		# print all stats to file
		print_stats_stat_log(logfile, model)
	end
end


### setup, run, cleanup



## parameters

# parse command line args
using ArgParse 
# translate params to args and vice versa
using Params2Args

const arg_settings = ArgParseSettings("run simulation", autofix_names=true)

@add_arg_table! arg_settings begin
	"--rand-seed", "-r"
		help = "random seed"
		arg_type = Int
		default = 42
	"--stop-time", "-t"
		help = "at which time to stop the simulation" 
		arg_type = Float64 
		default = 0.0
	"--step-wise", "-s"
		help = "run the model step-wise instead of event-based"
		arg_type = Bool
		default = false
	"--shuffle"
		help = "if running step-wise shuffle the population"
		arg_type = Bool
		default = false
end

# new group of arguments
add_arg_group!(arg_settings, "simulation parameters")

# translate Params into args
include("params.jl")
fields_as_args!(arg_settings, Params)

# parse cmdl args
const args = parse_args(arg_settings, as_symbols=true)
# and create a Params object from them
const p = @create_from_args(args, Params)



## setup

const t_stop = args[:stop_time] 
const seed = args[:rand_seed]

const model = p.topology == 1 ?
	setup_model_grid(p.r_inf, p.r_rec, p.r_imm, p.r_mort, p.x, p.y, seed) :
	setup_model_geograph(p.r_inf, p.r_rec, p.r_imm, p.r_mort, p.N, p.near, p.nc, seed)

const logf = prepare_outfiles("log_file.txt")


## run

if args[:step_wise]
	@time run_steps(model, trunc(Int, t_stop), logf, args[:shuffle])
else
	init_events(model)
	@time run_events(model, t_stop, logf)
end



## cleanup

close(logf)

