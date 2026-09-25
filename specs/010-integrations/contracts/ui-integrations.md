# UI Contract: Integrations page (ref `10-settings-integrations.png`)

- Title "Integrations" · subtitle "Apps your agents can reach into."
- Top row: search field ("Search integrations", `#2A2A2A`, rounded 14) + white pill "Add custom connector".
- `CONNECTED` card rows: icon 40 pt · name 20 pt semibold · status dot + text (green `#34C759` "Connected" /
  orange `#F5A623` "Reconnect required") · description 16 pt gray, 2 lines max · actions:
  - healthy: dark pill "Disconnect"
  - broken: primary pill "Reconnect" + round white ✕
- `AVAILABLE INTEGRATIONS` card rows: same without status; primary pill "Connect".
- Sign-in sheet: icon + "Finish signing in to {Name}" + steps + spinner "Waiting for {Name}…" + "Cancel".
- Custom connector sheet: Name, "Web address" or "Command on this Mac" segmented, field, Add (primary) / Cancel.
- Apps chip (sidebar): up to 3 connected icons (18 pt) + "Apps" + "+".
