// Managed by host-setup (install/firefox/). Tells Firefox to read a system-wide
// AutoConfig file from the application directory. Goes in
// /usr/lib/firefox/defaults/pref/. Pairs with ../../firefox.cfg.
//
// obscure_value=0 means firefox.cfg is plain text (no byte-shift obfuscation);
// sandbox_enabled=false lets the .cfg use the full config API on modern Firefox.
pref("general.config.filename", "firefox.cfg");
pref("general.config.obscure_value", 0);
pref("general.config.sandbox_enabled", false);
