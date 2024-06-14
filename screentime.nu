#!/usr/bin/env nu

# Hour range in which the device can be used.
const ALLOWED_RANGE = 6..21

# Your timezone. See a list of timezones at https://worldtimeapi.org/timezones
const TIMEZONE = "America/New_York"

# Allowed offline usage time before the computer shuts down.
const ALLOWED_OFFLINE = 15min 

def main [] {
	try {
		let data = http get ('https://worldtimeapi.org/api/timezone/' + $TIMEZONE)
		let time = $data | get datetime | into datetime
		let hour = $time | format date '%H' | into int
		if $hour not-in $ALLOWED_RANGE {
			shutdown now
		}
	} catch {
		if (sys host).uptime >= $ALLOWED_OFFLINE {
			shutdown now
		}
	}
}
