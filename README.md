Screen Time features for NixOS. 

For now, it's not a proper Nix package, just a bunch of configuration options along with a script.

## Features

- Downtime: Block your computer from opening outside of specified working hours.
- URL Blocklist: Block specified URLs in Chromium and Firefox.

## Requirements

### 1. Not knowing root password

In order for this system to work properly, you should not know what your root password is. Unfortunately on Linux, a lot of stuff depend on having root access. Fortunately, the stuff you need root access for is rarely an emergency. Trust me, you'll be just fine without sudo. Not to mention more secure too, depending on your configuration. 

In order to achieve this and still be able to be root and do system modifications when a need arises, do the following.:

1. [Timelock](https://github.com/rayanamal/timelock) your root password. Set the decryption time to an amount that'll prevent your impulsive behavior. Whenever you want to make a change in your system, you can start decrypting the password. After the decryption is complete, you can do whatever system modifications you want, and then delete the decrypted password.

    I personally note down system modifications which require root access and do all of them at once every few weeks.

    I also set the decryption time to 8 hours but as you can tell from the existence of this repo, I had a pretty severe case of internet addiction. For most people, 30 mins or 1 hour will be perfectly ok.

2. Remove your user from the sudo group.
<pre><code>users.users.&lt;name&gt;.extraGroups = [ <span style="text-decoration: line-through;">wheel</span> ]
</code></pre>

3. (*Optional*) Install [distrobox](https://distrobox.it/). Distrobox allows the creation of Linux containers as easily as "`distrobox enter debian`". This allows you to be dropped into any Linux distribution and be able to install software on it while having screen time features on the host machine. Also recommended is to install and learn [podman](https://podman.io/) too, to serve as a rootless backend for distrobox. (Using Docker as a rootless backend is very cumbersome.)

### 2. Constant connectivity

The script `screentime.nu` won't trust system clock unless you are online, to prevent system time modifications through BIOS. You can set a maximum allowed offline usage time as described below.

## Installation

1. Clone the repository **with sudo**:
```bash
sudo git clone "https://github.com/rayanamal/screentime-nixos.git"
```

2. Edit the constants at the start of the `screentime.nu` file:
	- `TIMEZONE`: Set your timezone.
	- `ALLOWED_HOURS`: Your productive hours. You'll be able to use your computer in this time range. 
	- `EXTRA_MINS`: Allowed maxiumum extra time per day. You'll be able to use your computer outside of `ALLOWED_HOURS` for the duration specified here. It's intended to be used for emergencies. 
	- `MAX_OFFLINE`: Allowed maximum offline usage time. You'll be allowed to use the computer when offline for the duration specifed here. 

You're given 5 minutes every time you boot independent of all settings.

3. Change the cloned repository's ownership.

```bash
chown -R root:root /path/to/screentime-nixos/
```

4. Add this to your `/etc/nixos/configuration.nix`:
```nix
  systemd.services.screentime = {
  	wantedBy = [ "multi-user.target" ];
  	serviceConfig = {
      Restart = "on-failure";
    };
    script = "/home/username/.screentime.nu";
    environment.PATH = lib.mkForce "/run/current-system/sw/bin";
  };
```
Edit it to put the path to cloned repository.

5. Make sure `nushell` is available to the root user. You can add it with:
```nix
 environment.systemPackages = with pkgs; [
    nushell
 ]
```

6. Add the following to your `configuration.nix`. Tailor the website list for your own browsing habits.
```nix
  programs.chromium = { 
    enable = true;
    extraOpts = {
      "URLBlocklist" = [
        "news.ycombinator.com"
        "youtube.com"
        "lobste.rs"
        "reddit.com"
        "instagram.com"
      ];
    };
  };

# Everything is blocked on Firefox, so that you don't use it
  programs.firefox = {
  	enable = true;
    policies.WebsiteFilter = {
      Block =  ["<all_urls>"];
    };
  };
```

  If you prefer Firefox as your main browser, refer to the respective documentation for configuring url blocklists: [Firefox](https://mozilla.github.io/policy-templates/#websitefilter), [Chromium](https://chromeenterprise.google/intl/en_us/policies/#URLBlocklist).

## Screen-timing your phone
If you want to use non-bypassable Screen Time measures found in this repo for your computer, it's possible you want to use them for your phone too. 
- The easiest way to do that (especially if you're in the US and don't use apps like WhatsApp) is to get a [Light Phone](https://www.thelightphone.com/). 
- If you absolutely can't do that, then the next best solution is to give someone you trust the Screen Time password on your phone. 
- If you don't have anyone you can trust (which is arguably an even bigger problem that needs fixing!), you can [timelock](https://github.com/rayanamal/timelock) your Screen Time password and ask someone to enter (but not remember) the Screen Time password, or you can use various bluetooth/USB keyboard emulator apps and tools on various platforms to enter the password yourself without seeing it.

## Notes

Screen Time controls are subjective. Everyone has different computering habits. And there's always the (mostly justified) argument that the only reason people are not able to control their screen usage is because they lack self-awareness and/or a purpose in life to be motivated for. Self awareness can be gained through Cognitive-Behavioral Therapy, meditation, or being a devout Muslim. A purpose in life can be gained through a lot of things: your loved ones, activism of all types, the desire to improve other people's lives, even work. Though most of these crumble when faced with the question "We're all gonna die anyway, why bother?". Remarkably religions involving afterlife - specifically Islam - passes this test. Even though this accurately describes the predicament of the modern individual, it's far from the whole picture.

It's known that Big Tech companies are specifically targeting and engineering for your attention, optimizing for dopamine hits to keep the ad dollars flowing. Hundreds of millions are spent per year to A/B test some UI change, will it lead to more "engagement" or not? So it's not fair at all to put the blame on the user fully either. When you unleash algorithmic feeds on a 21th century population, inevitably a sizeable fraction gets caught in the net. 

For many people, there is no need for Screen Time. They're busy enough with their daily lives. For others, a little bit of friction (think about iOS Screen Time without a password) is enough. Yet our kind, software engineers, are ironically the ones most prone to falling to bad usage habits, due to our fascination with technology, the lack of friction because of our tech-savviness, and the chronically online nature of our job. Thus the need for Screen Time controls, and the need for this project. I'm a happy user since 2 years now, and I see the positive effect on myself.

## Contributing and Feedback

Let me know how this project worked (or didn't) for you!

This project is open to contributions.

## TODOs

- We can rebuild nixos with the same delay (after change of configuration.nix) that is in the password and impulse control will work without the user ever needing to unlock root access.
