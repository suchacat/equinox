import pkg/owlkettle,
       pkg/owlkettle/adw,
       ../core/meta

template openAboutMenu*(app) =
  discard app.open:
    gui:
      AboutWindow:
        applicationName = "Equinox"
        developerName = "The EquinoxHQ Team"
        version = meta.Version
        supportUrl = "https://discord.gg/Z5m3n9fjcU"
        issueUrl = "https://github.com/equinoxhq/equinox/issues"
        website = "https://equinoxhq.github.io"
        copyright =
          """
Copyright (C) 2025 xTrayambak and the EquinoxHQ Team
The Roblox logo and branding are registered trademarks of Roblox Corporation.
        """
        license = meta.License
        licenseType = LicenseMIT_X11
        applicationIcon = "equinox"
        developers = @["Trayambak (xTrayambak)"]
        designers = @["Adrien (AshtakaOOf)"]
        artists = @[]
        documenters = @[]
        credits =
          @{
            "APK Fetching": @["Kirby (k1yrix)"],
            "Waydroid project developers (a special thanks!)":
              @["aleasto et. al"],
          }

