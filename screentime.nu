#!/usr/bin/env nu

# Hour range in which the device can be used. 
# You can use lists too: [7 8 9 10 18 19 20 21]
const ALLOWED_RANGE = 6..21

# Your timezone. See a list of timezones at https://worldtimeapi.org/timezones
const TIMEZONE = "America/New_York"

# Maximum allowed offline usage time before the computer shuts down.
# Set to false to never shut down when offline.
const MAX_OFFLINE = 15min

def main [] {
	try {
		let data = http get ('https://worldtimeapi.org/api/timezone/' + $TIMEZONE)
		let time = $data | get datetime | into datetime
		let hour = $time | format date '%H' | into int
		if $hour not-in $ALLOWED_RANGE {
			shutdown now
		}
	} catch {
		if $MAX_OFFLINE != false and (sys host).uptime >= $MAX_OFFLINE {
			shutdown now
		}
	}
}