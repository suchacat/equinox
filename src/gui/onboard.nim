## Onboarding GUI
import std/[logging]
import pkg/owlkettle, pkg/owlkettle/[playground, adw]

viewable OnboardingApp:
  description:
    string = "This is Equinox"
  iconName:
    string = "weather-clear-symbolic"
  title:
    string = "Equinox"
  active:
    bool = false
  subtitle:
    string = "uuuuuh"
  sensitive:
    bool = true
  tooltip:
    string = "man..."
  sizeRequest:
    tuple[x, y: int] = (-1, -1)

  consentedTOS:
    bool
  consentedPrivacy:
    bool

method view(app: OnboardingAppState): Widget =
  result = gui:
    Window:
      defaultSize = (400, 600)
      title = app.title
      HeaderBar {.addTitlebar.}:
        style = [HeaderBarFlat]

      Clamp:
        maximumSize = 500
        margin = 12

        Box:
          orient = OrientY
          spacing = 12

          PreferencesGroup {.expand: false.}:
            title = "Onboarding"
            #description = "Losing it"

            ActionRow:
              title = "I Consent"
              subtitle = "To the Equinox Terms of Service"
              Switch() {.addSuffix.}:
                proc changed(active: bool) =
                  app.consentedTOS = active
                  if app.consentedTOS:
                    debug "gui: user has consented to TOS"
                  else:
                    debug "gui: user no longer consents to TOS"

            ActionRow:
              title = "I Consent"
              subtitle = "To the Equinox Privacy Policy"
              Switch() {.addSuffix.}:
                proc changed(active: bool) =
                  app.consentedPrivacy = active
                  if app.consentedPrivacy:
                    debug "gui: user has consented to privacy policy"
                  else:
                    debug "gui: user no longer consents to privacy policy"

          Box {.hAlign: AlignCenter, vAlign: AlignCenter.}:
            orient = OrientX
            spacing = 12

            Button:
              style = [ButtonPill, ButtonSuggested]
              text = "Start Setup"
              proc clicked() =
                let consent = app.consentedPrivacy and app.consentedTOS
                if not consent:
                  discard

            #[ Button:
              style = [ButtonPill]
              icon = "applications-system-symbolic"
              #tooltip = "config"
              proc clicked() =
                echo "losing it" ]#

proc runOnboardingApp*() =
  adw.brew(gui(OnboardingApp()))
