# Clean Stage script in Nushell

def main [] {
    let clean_root = ($env.CLEAN_ROOT? | default "/")
    
    print "Reverting back to upstream defaults..."
    # Revert back to upstream defaults
    do -i { ^dnf5 config-manager setopt keepcache=0 }
    do -i { ^dnf5 versionlock clear }
    
    print "Masking and disabling flatpak-add-fedora-repos..."
    do -i { ^systemctl disable flatpak-add-fedora-repos.service }
    do -i { ^systemctl mask flatpak-add-fedora-repos.service }
    let flatpak_service = $"($clean_root)/usr/lib/systemd/system/flatpak-add-fedora-repos.service"
    if ($flatpak_service | path exists) {
        rm -f $flatpak_service
    }
    
    let gitkeep = $"($clean_root)/.gitkeep"
    if ($gitkeep | path exists) {
        rm -rf $gitkeep
    }
    
    # Remove files in var except cache
    let var_dir = $"($clean_root)/var"
    if ($var_dir | path exists) {
        let items = (ls $var_dir | get name)
        for item in $items {
            if ($item | path basename) != "cache" {
                rm -rf $item
            }
        }
    }
    
    # Remove files in var/cache except libdnf5 and rpm-ostree
    let cache_dir = $"($clean_root)/var/cache"
    if ($cache_dir | path exists) {
        let items = (ls $cache_dir | get name)
        for item in $items {
            let base = ($item | path basename)
            if $base != "libdnf5" and $base != "rpm-ostree" {
                rm -rf $item
            }
        }
    }
    
    # Clear tmpfs-backed directories /tmp and /boot safely
    for runtime_dir in ["tmp", "boot"] {
        let path = $"($clean_root)/($runtime_dir)"
        mkdir $path
        let entries = (glob $"($path)/*" --include-symlinks)
        for entry in $entries {
            let is_mount = (try { ^mountpoint -q $entry; true } catch { false })
            if not $is_mount {
                rm -rf $entry
            }
        }
    }
    
    # Clear /run depth-first
    let run_dir = $"($clean_root)/run"
    mkdir $run_dir
    let run_entries = (try { glob $"($run_dir)/**/*" --include-symlinks | reverse } catch { [] })
    for entry in $run_entries {
        let is_mount = (try { ^mountpoint -q $entry; true } catch { false })
        if $is_mount {
            continue
        }
        if ($entry | path type) == "dir" {
            try { rm -d $entry }
        } else {
            try { rm -f $entry }
        }
    }
}
