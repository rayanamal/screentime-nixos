#### Warning! Currently systems with Wi-Fi connectivity as opposed to Ethernet have spontaneous system shutdown issues, especially upon waking up from sleep. A fix is underway.

___
<br>
Screen Time features for NixOS. 

For now, it's not a proper Nix package, just a bunch of configuration options along with a script.

## Features

- Downtime: Block your computer from opening outside of specified working hours.
- URL Blocklist: Block specified URLs in Chromium and Firefox.

## Requirements

In order for this to work properly, you should not know what your root password is. Unfortunately on Linux, a lot of stuff depend on having root access. Fortunately, the stuff you need root access for is rarely an emergency. Trust me, you'll be just fine without sudo. Not to mention more secure too, depending on your configuration. 

In order to achieve this and still be able to practically use your machine, do the following:

1. [Timelock](https://github.com/rayanamal/timelock) your root password. Set the decryption time to an amount that'll prevent your impulsive behavior. Whenever you want to make a change in your system, you can start decrypting the password. After the decryption is complete, you can do whatever system modifications you want, and then delete the decrypted password.

    I personally note down system modifications which require root access and do all of them at once every few weeks.

    I also set the decryption time to 8 hours but as you can tell from the existence of this repo, I had a pretty severe case of having no life. Most people will probably be fine with 30 mins or 1 hour.

2. Remove your user from the sudo group.
<pre><code>users.users.&lt;name&gt;.extraGroups = [ <span style="text-decoration: line-through;">wheel</span> ]
</code></pre>

3. (*Optional*) Install [distrobox](https://distrobox.it/) for Linux containers as easy as "`distrobox enter ubuntu`". This allows you to be dropped into any Linux distribution and be able to install software on it while having screen time features on the host machine. Preferably also install and learn [podman](https://podman.io/) too, for a no-config rootless docker experience. What good is a dev who doesn't know containers anyway?

## Installation

1. Clone the repository **with sudo**:
```bash
sudo git clone "https://github.com/rayanamal/screentime-nixos.git"
```

2. Edit the constants at the start of the `screentime.nu` file to set your timezone, productive hours and allowed maximum offline usage time.

3. Add this to your `/etc/nixos/configuration.nix`:
```nix
  systemd.services.screentime = {
    startAt = "minutely";
    script = "/path/to/repository/screentime.nu";
    environment.PATH = lib.mkForce "/run/current-system/sw/bin";
  };
```
edit it to put the path to cloned repository.

4. Make sure `nushell` is available to the root user. You can add it with:
```nix
 environment.systemPackages = with pkgs; [
    nushell
 ]
```

5. Add the following to your `configuration.nix`. Tailor the website list for your browsing habits.
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

### Screen-timing your phone
If you need non-bypassable Screen Time measures in this repo for your computer, it's possible you need them for your phone too. The easiest way to do that (especially if you're in the US and don't use apps like WhatsApp) is to get a [Light Phone](https://www.thelightphone.com/). If you absolutely can't do that, then the next best solution is to give someone you trust the Screen Time password on your phone. If you don't have anyone you can trust, you can [timelock](https://github.com/rayanamal/timelock) your Screen Time password and ask someone to enter (but not to remember) it or use bluetooth/USB keyboard emulator apps and tools on various platforms to enter the password without yourself seeing it.

### Notes

Screen Time controls are subjective. Everyone has different computering habits. And there's always the (mostly justified) argument that the only reason people are not able to control their screen usage is because they lack self-awareness and/or a purpose in life to be motivated for. Self awareness can be gained through Cognitive-Behavioral Therapy, meditation, or being a devout Muslim. A purpose in life can be gained through a lot of things: your loved ones, activism of all types, the desire to improve other people's lives. Though most of these crumble when faced with the question "We're all gonna die anyway, why bother?". Remarkably religion - specifically Islam - passes this test. Even though this accurately describes the predicament of the modern individual, it's far from the whole picture.

It's known that Big Tech companies are specifically targeting and engineering for your attention, optimizing for dopamine hits to keep the ad dollars flowing. Hundreds of millions are spent per year to A/B test some UI change, will it lead to more "engagement" or not? So it's not fair at all to put the blame on the user fully either. When you unleash algorithmic feeds on a 21th century population, inevitably a sizeable fraction gets caught in the net. 

For many people, there is no need for Screen Time. They're busy enough with their daily lives. For others, a little bit of friction (think about iOS Screen Time without a password) is enough. Yet our kind, software engineers, are ironically the ones most prone to falling to bad usage habits, due to our fascination with technology, the lack of barriers because of our tech-savviness, and the chronically online nature of our job. Thus the need for Screen Time controls, and the need for this repo. I'm a happy user since 2 years now, and I see the positive effect.
