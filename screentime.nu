#!/usr/bin/env nu

# Hour range in which the device can be used. 
# You can use lists too: [7 8 9 10 18 19 20 21]
const ALLOWED_HOURS = 6..21

# Your timezone. See a list of timezones by running this script with:
# ./screentime.nu list-timezones
const TIMEZONE = "America/New_York"

# Maximum allowed offline usage time before the computer shuts down.
# Set to false to never shut down when offline.
const MAX_OFFLINE = 15min

def main [] {
	try {
		ping -c 1 8.8.8.8 | ignore
		let time = date now | date to-timezone $TIMEZONE
		let hour = $time | format date '%H' | into int
		if $hour not-in $ALLOWED_HOURS {
			shutdown now
		}
	} catch {
		if $MAX_OFFLINE != false and (sys host).uptime >= $MAX_OFFLINE {
			shutdown now
		}
	}
}

def "main list-timezones" [] {
	date list-timezone
}