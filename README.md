Some screen time features implemented for NixOS.

## Features

- Downtime: Block your computer from opening outside of specified working hours.
- URL Blocklist: Block specified URLs in Chromium and Firefox.

## Requirements

In order for this to work properly, you should not know what your root password is. Unfortunately on Linux, a lot of stuff depend on having root access. Fortunately, the stuff you need root access for is rarely an emergency. Trust me, you'll be just fine without sudo. Not to mention more secure too, depending on your configuration. 

In order to achieve this and still be able to practically use your machine, do the following:

1. [Timelock](https://github.com/rayanamal/timelock) your root password. Preferably set the decryption time to ~6 hours. This prevents impulsive behavior. Whenever you want to make a change in your system, you can start decrypting the password. After the decryption is complete, you can do whatever system modifications you want.

    I personally note down system modifications which require root access and do all of them at once every few weeks.

2. Remove your user from the sudo group.
<pre><code>users.users.&lt;name&gt;.extraGroups = [ <span style="text-decoration: line-through;">wheel</span> ]
</code></pre>

3. (*Optional*) Install [distrobox](https://distrobox.it/) for Linux containers as easy as "`distrobox enter ubuntu`". This allows you to be dropped into any Linux distribution and be able to install software on it while having screen time features on the host machine. Preferably also install and learn [podman](https://podman.io/) too, for a no-config rootless docker experience. What good is a dev who doesn't know containers anyway?

## Installation

1. Clone the repository **with sudo**:
```bash
sudo git clone "https://github.com/rayanamal/screentime-nixos.git"
```

2. Edit the constants at the start of the `screentime.nu` file to set your timezone, productive hours and (optional) allowed maximum offline usage.

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

# Everything is blocked on firefox, so that you don't use it  
  programs.firefox = {
  	enable = true;
    policies.WebsiteFilter = {
      Block =  ["<all_urls>"];
    };
  };
```

  If you prefer Firefox as your main browser, refer to the respective documentation for configuring url blocklists: [Firefox](https://mozilla.github.io/policy-templates/#websitefilter), [Chromium](https://chromeenterprise.google/intl/en_us/policies/#URLBlocklist).