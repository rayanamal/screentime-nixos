#!/usr/bin/env nu

# Set your configuration here!

const USERS: list<string> = []
# A list of the usernames to terminate upon exceeding time limits.
# Other users will remain unaffected.
# Examples: 
# - ['alice']
# - ['bob' 'carl' 'dan']    

const ALLOWED_HOURS = 6..16
# Hour range in which the device can be used. Examples:
# - 6..21                    (A range denoted as start..end)
# - [7 8 9 10 20 21]         (You can use a list too!)

const TIMEZONE: string = "Europe/London"
# Your timezone. See a list of timezones by running this script with: 
# ./screentime.nu list-timezones
# Example: "Europe/London"

const MAX_OFFLINE: duration = 15min
# Maximum allowed offline usage time per day.

const EXTRA_MINS: duration = 30min
# Maximum allowed extra time per day outside of $ALLOWED_HOURS you have defined.

# That's it! You can also change the following optional settings:

const LIMIT_RESET_HOUR: string = "6am"
# The hour at which the extra time and offline time limit counters reset every day.

const DIR: path = '/var/lib/screentime-nixos'
# const DIR: path = 'test/' # for testing
# The directory in which data files are saved.

# The duration after boot in which time limits are disabled.
const AFTER_BOOT: duration = 3min

-----------------------------------------------------------

mkdir $DIR

let data_file: path = ($DIR | path join 'data.nuon')
if not ($data_file | path exists) {
	{ 
		extra: 0min, 
		offline: 0min,
		offline_block_counter: 0,
		last_reset: ($LIMIT_RESET_HOUR | into datetime | into int)
	} | save $data_file
}

def main [] nothing -> nothing {
	# alias notify = try { notify -a "screentime-nixos" -s "1 minute left to termination" -t "Your user session will be terminated in 60 seconds." --timeout 60sec }
	# notify

	let last_reset = (v last_reset | into datetime)
	mut next_reset = $last_reset + 1day

	loop {
		let online: bool = (
			ping -c 3 8.8.8.8
			| complete
			| $in.exit_code == 0
		)
		if $online {
			let hour: int = (date now | format date '%H' | into int)
			if $hour not-in $ALLOWED_HOURS {
				set extra ((v extra) + 1min)	
				if (v extra) == 1min or (v extra) > $EXTRA_MINS {
					block
				} else if (v extra) == $EXTRA_MINS {
					# notify
				}
			}
			if (date now) > $next_reset {
				set last_reset ($next_reset | into int)
				$next_reset = $next_reset + 1day
				set extra 0min
				set offline 0min
			}
		} else if not $online {
			set offline ((v offline) + 1min)
			if (v offline) > $MAX_OFFLINE {
				if (v offline_block_counter) == 3 {
					set offline_block_counter 0
					block
				} else {
					set offline_block_counter ((v offline_block_counter) + 1)
				}
			} else if (v offline) == $MAX_OFFLINE {
				# notify
			}
		}
		sleep (1min - (2sec + 40ms))
		# sleep 100ms # for testing
	}
}

def "main list-timezones" []: nothing -> table<timezone: string> {
	date list-timezone
}

def "set" [field: string, value: any] nothing -> nothing {
	open $data_file | update $field $value | save -f $data_file
}

def v [field: string]: nothing -> any {
	open $data_file | get $field
}

def block []: nothing -> nothing {
	# print "User is blocked." ; exit # for testing
	if (sys host).uptime >= $AFTER_BOOT {
		$USERS  | each {
			let user: string = $in
			print $"User \"($user)\" is terminated."
			try { loginctl kill-user $user }
			try { systemctl suspend }
		}
	}
}
