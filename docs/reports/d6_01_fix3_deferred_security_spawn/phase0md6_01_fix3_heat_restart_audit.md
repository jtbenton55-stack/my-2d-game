# Heat / restart audit

No code change: if testers **restart scene** or **quit without dying/failing**, **`fail_mission`** may never run → heat unchanged. Use **fail_level path** or explicit fail to verify +1.
