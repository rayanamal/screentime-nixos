#!/usr/bin/env nu

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
	let file = $DIR | path join 'last-online.nuon'
	if not ($file | path exists) {
		date now | save $file
	}
	let online = try {
			ping -c 1 8.8.8.8 | save /dev/null
			true
		} catch { false }
	if $online {
		date now | save -f $file
		let hour = date now | format date '%H' | into int
		if $hour not-in $ALLOWED_HOURS {
			shutdown now
		}
	} else if not $online {
		let last_online = open $file
		if (date now) - $last_online >= $MAX_OFFLINE and (sys).host.uptime >= 7min {
			shutdown now
		}
	}
}

def "main list-timezones" [] {
	date list-timezone
}
