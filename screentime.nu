#!/usr/bin/env nu

# Set your configuration here!

const USERS: list<string> = [ ]
# A list of the usernames to terminate upon exceeding time limits.
# Other users will remain unaffected.
# Examples:
# - ['alice']
# - ['bob' 'carl' 'dan']    
# Note that there's no comma between list items!

const ALLOWED_TIMES = [
    "05.00 - 22.00"
]
# Time ranges in which the device can be used. Example:
# [
#    "8.00 - 12.30"
#    "13.35 - 17.50"
# ]
# An empty list means the device is blocked at all times.

const TIMEZONE: string = ""
# Your timezone. See a list of timezones by running this script with: 
# ./screentime.nu list-timezones
# Example: "Europe/London"

const MAX_OFFLINE: duration = 3min
# Maximum allowed offline usage time per day.

const EXTRA_MINS: duration = 10min
# Maximum allowed extra time per day outside of $ALLOWED_TIMES you have defined.

# That's it! You can also change the following optional settings:

const LIMIT_RESET_HOUR: string = "5am"
# The hour at which the extra time and offline time limit counters reset every day.

const DIR: path = '/var/lib/screentime-nixos'
# The directory in which data files are saved.

# The duration after boot in which time limits are disabled.
const AFTER_BOOT: duration = 90sec

-----------------------------------------------------------

mkdir $DIR

let data_file: path = ($DIR | path join 'data.nuon')
if not ($data_file | path exists) {
	{ 
		extra: 0min, 
		offline: 0min,
		# offline_block_counter: 0,
		# Offline block counter was a strategy used to deal with intermittent network connections on Wi-Fi. 
		# At the moment there are no known users facing this issue, but I'm keeping it commented out just in case.
		last_reset: ($LIMIT_RESET_HOUR | into datetime | into int)
	} | save $data_file
}

def main []: nothing -> nothing {
	# alias notify = try { notify -a "screentime-nixos" -s "1 minute left to termination" -t "Your user session will be terminated in 60 seconds." --timeout 60sec }
	# notify

	let allowed_times = $ALLOWED_TIMES | process-allowlist
	let last_reset = (v last_reset | into datetime)
	mut next_reset = $last_reset + 1day

	loop {
		let online: bool = (
			ping -c 5 8.8.8.8
			| complete
			| $in.exit_code == 0
		)
		if $online {
			if not (is-time-allowed "now" $allowed_times) {
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
				# if (v offline_block_counter) >= 3 {
				# 	set offline_block_counter 0
					block
				# } else {
				# 	set offline_block_counter ((v offline_block_counter) + 1)
				# }
			} else if (v offline) == $MAX_OFFLINE {
				# notify
			}
		}
		sleep (1min - (4sec + 40ms)) # every interval between pings take 1.01 seconds and we ping 5 times.
		# sleep 100ms # for testing
	}
}

def "main list-timezones" []: nothing -> table<timezone: string> {
	date list-timezone
}

def "set" [field: string, value: any]: nothing -> nothing {
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

# Convert a 24-hour clock string to a duration value
def clock-to-duration []: string -> duration {
	str trim
	| str replace -a ':' '.'
	| parse-expect '(?<hours>\d{1,2}).(?<minutes>\d{2})'
	| into record
	| $"($in.hours)hr ($in.minutes)min"
	| into duration
}

# Parse a string using a regex and exit with an error message if there are no matches
def parse-expect [regex]: string -> list<any> {
	parse -r $regex
    | if ($in | is-empty) {
        print -e $'Provided input string "($in)" is in an invalid format. It should conform to the regular expression "($regex)"' 
        exit 1
    } else { }
}

# Process a list of time range strings into a table
def process-allowlist []: list<string> -> table<start: duration, end: duration> {
	each {|str|
		str trim
		| parse-expect '(?<start>\S+)\s*-\s*(?<end>\S+)'
		| update cells {
			clock-to-duration
		}
		| into record
		| if ($in.start > $in.end) {
			print -e $"Start time ($in.start) is after end time ($in.end) in the provided input string: ($str)"
			exit 1
		} else {}
	}
}

# Check whether the current hour is in the allowed times
def is-time-allowed [test_hour: string, allowlist: table<start: duration, end: duration>]: nothing -> bool {
	let hour = (
		if $test_hour == 'now' {
			date now
			| format date "%H.%M"
		} else {
			$test_hour
		}
		| clock-to-duration
	)
	$allowlist
	| any {|it|
		$hour >= $it.start and $hour <= $it.end
	}
}

# A function to test time allowlist parsing
export def test [] {
	open ./tests.nuon
	| enumerate
	| each {|e|
		let test = $e.item
		let ind = $e.index | $" ($in):" | fill -w 4
		let allowed_hours = $test.allowlist | process-allowlist
		let result = is-time-allowed $test.hour $allowed_hours
		if $result != $test.expected {
			print $"\n($ind) FAIL: expected ($test.expected) but got ($result)\n"
			print $"\nTested ($test.hour) against ($test.allowlist)"
		} else {
			print $"($ind) PASS: expected ($test.expected) and got ($result)"
		}
	}
	ignore
}