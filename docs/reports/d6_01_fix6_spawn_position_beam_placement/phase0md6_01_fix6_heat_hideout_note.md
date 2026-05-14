# Heat Hideout Note

Persistent heat policy was preserved. Mid-run camera/wrong-code/beam events record security/debug counters and alert state but do not directly increment persistent heat. Existing heat increase remains tied to mission failure paths. Hideout heat display sync was not changed in this pass and should remain a later display/data-source pass if it still reads low after GameState heat changes.

## Assertions
- ASSERT heat_hideout_gap_documented == true
- ASSERT persistent_heat_policy_preserved == true
