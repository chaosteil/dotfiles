# Enable host units from /usr/lib/systemd/system with tmpfiles links, as
# "systemctl enable" does. Entries: { unit; wantedBy ? null; alias ? [ ]; }.
lib: units:
lib.mkMerge (
  map (
    {
      unit,
      wantedBy ? null,
      alias ? [ ],
    }:
    let
      source = "/usr/lib/systemd/system/${unit}";
    in
    lib.optionalAttrs (wantedBy != null) {
      "/etc/systemd/system/${wantedBy}.wants/${unit}".L.argument = source;
    }
    // lib.listToAttrs (
      map (name: lib.nameValuePair "/etc/systemd/system/${name}" { L.argument = source; }) alias
    )
  ) units
)
