## Onboarding GUI

import pkg/owlkettle,
       pkg/owlkettle/[playground, adw]

viewable OnboardingApp:
  description: string = "This is Equinox"
  iconName: string = "weather-clear-symbolic"
  title: string = "Equinox"
  active: bool = false
  subtitle: string = "uuuuuh"
  sensitive: bool = true
  tooltip: string = "man..."
  sizeRequest: tuple[x, y: int] = (-1, -1)

method view(app: OnboardingAppState): Widget =
  result = gui:
    Window():
      defaultSize = (400, 600)
      title = app.title
      HeaderBar {.addTitlebar.}:
        style = [HeaderBarFlat]

      Clamp:
        maximumSize = 500
        margin = 12

        Box():
          orient = OrientY
          spacing = 12

          PreferencesGroup {.expand: false.}:
            title = "Onboarding"
            #description = "Losing it"

            ActionRow:
              title = "I Consent"
              subtitle = "To the Equinox terms of service"
              Switch() {.addSuffix.}

              #proc activated(active: bool) =
              #  app.active = active
              #  echo "Consent status: ", active

          Box {.hAlign: AlignCenter, vAlign: AlignCenter.}:
            orient = OrientX
            spacing = 12

            Button:
              style = [ButtonPill, ButtonSuggested]
              text = "Launch"
              proc clicked() =
                echo "clicked"

            Button:
              style = [ButtonPill]
              icon = "applications-system-symbolic"
              #tooltip = "config"
              proc clicked() =
                echo "losing it"

proc runOnboardingApp* =
  adw.brew(gui(OnboardingApp()))
