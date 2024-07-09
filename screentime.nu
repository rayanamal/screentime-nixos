#!/usr/bin/env nu
exit
# Hour range in which the device can be used. 
# You can use a list too: [7 8 9 10 18 19 20 21]
const ALLOWED_HOURS = 6..21

# Your timezone. See a list of timezones by running this script with:
# ./screentime.nu list-timezones
const TIMEZONE = "Europe/Istanbul"

# Maximum allowed offline usage time before the computer shuts down.
# Set to false to never shut down when offline.
const MAX_OFFLINE = 15min

const DIR = '/var/lib/screentime-nixos/'						
def main [] {
	mkdir $DIR
	let file = $DIR | path join 'offline-mins.nuon'
	if not ($file | path exists) {
		0 | save $file
	}
	let online = try {
			ping -c 1 8.8.8.8 | ignore
			true
		} catch { false }
	if $online {
		0 | save -f $file
		let hour = date now | format date '%H' | into int
		if $hour not-in $ALLOWED_HOURS {
			shutdown now
		}
	} else if not $online {
		let offline_mins = (open $file) + 1
		$offline_mins | save -f $file
		let offline_dur = $offline_mins | into duration -u min   
		if $offline_dur >= $MAX_OFFLINE and (sys host).uptime >= 5min {
			shutdown now
		}
	}
}

def "main list-timezones" [] {
	date list-timezone
}
