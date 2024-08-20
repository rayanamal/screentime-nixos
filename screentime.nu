#!/usr/bin/env nu

# Hour range in which the device can be used. 
# You can use a list too: [7 8 9 10 18 19 20 21]
const ALLOWED_HOURS = 6..21

# Your timezone. See a list of timezones by running this script with:
# ./screentime.nu list-timezones
const TIMEZONE = "Europe/London"

# Maximum allowed offline usage time before the computer shuts down.
const MAX_OFFLINE = 15min

# Maximum allowed extra time outside of $ALLOWED_HOURS.
const EXTRA_MINS = 15min

# Directory in which usage data is saved
const DIR = '/var/lib/screentime-nixos/'						

def shutdown [] {
	if (sys host).uptime >= 5min {
		# print 'shutdown now' # for testing
		shutdown now
	}
}

let offline_file = $DIR | path join 'offline-mins.nuon'
let extra_file = $DIR | path join 'extra-mins.nuon'

mkdir $DIR

if not ($offline_file | path exists) {
	0 | save $offline_file
}

if not ($extra_file | path exists) {
	0 | save $extra_file
}

def main [] {
	loop {
		let online = try {
				ping -c 1 8.8.8.8 | ignore
				true
			} catch { false }
		if $online {
			0 | save -f $offline_file
			let hour = date now | format date '%H' | into int
			if $hour not-in $ALLOWED_HOURS {
				let extra_mins = (open $extra_file) + 1
				$extra_mins | save -f $extra_file
				let extra_dur = $extra_mins | into duration -u min   
				if $extra_dur >= $EXTRA_MINS {
					shutdown
				}
			} else if $hour in $ALLOWED_HOURS {
				0 | save -f $extra_file
			}
		} else if not $online {
			let offline_mins = (open $offline_file) + 1
			$offline_mins | save -f $offline_file
			let offline_dur = $offline_mins | into duration -u min   
			if $offline_dur >= $MAX_OFFLINE {
				shutdown
			}
		}
		sleep (random int 45..75 | into duration -u sec)
	}
}


def "main list-timezones" [] {
	date list-timezone
}
