# Image Info Generation in Nushell
# Generates /usr/share/ublue-os/image-info.json and customizes /usr/lib/os-release.

def main [] {
    let image_name = ($env.IMAGE_NAME? | default "bluefin")
    let image_vendor = ($env.IMAGE_VENDOR? | default "rjallais")
    let ublue_image_tag = ($env.UBLUE_IMAGE_TAG? | default "stable")
    let base_image_name = ($env.BASE_IMAGE_NAME? | default "bluefin")
    let fedora_major_version = ($env.FEDORA_MAJOR_VERSION? | default "40")
    let version = ($env.VERSION? | default "")
    
    let pretty_name = ($env.IMAGE_PRETTY_NAME? | default "My Custom OS")
    let image_like = ($env.IMAGE_LIKE? | default "fedora")
    let home_url = ($env.HOME_URL? | default $"https://github.com/($image_vendor)/($image_name)")
    let documentation_url = ($env.DOCUMENTATION_URL? | default $"https://github.com/($image_vendor)/($image_name)/blob/main/README.md")
    let support_url = ($env.SUPPORT_URL? | default $"https://github.com/($image_vendor)/($image_name)/issues")
    let bug_report_url = ($env.BUG_REPORT_URL? | default $"https://github.com/($image_vendor)/($image_name)/issues/new")
    
    let image_flavor = if ($image_name | str contains "nvidia") { "nvidia" } else { "main" }
    let image_ref = $"ostree-image-signed:docker://ghcr.io/($image_vendor)/($image_name)"
    
    # Write image-info.json
    let image_info_path = "/usr/share/ublue-os/image-info.json"
    mkdir "/usr/share/ublue-os"
    
    let info = {
        "image-name": $image_name,
        "image-flavor": $image_flavor,
        "image-vendor": $image_vendor,
        "image-ref": $image_ref,
        "image-tag": $ublue_image_tag,
        "base-image-name": $base_image_name,
        "fedora-version": $fedora_major_version
    }
    
    $info | to json | save -f $image_info_path
    print $"Wrote ($image_info_path)"
    print $"  image-name: ($image_name)"
    print $"  image-flavor: ($image_flavor)"
    print $"  image-vendor: ($image_vendor)"
    
    # Customize /usr/lib/os-release
    let os_release_path = "/usr/lib/os-release"
    if ($os_release_path | path exists) {
        let os_release_content = (open $os_release_path | into string)
        if not ($os_release_content | str contains "VARIANT_ID=") {
            let os_version = if ($version | is-empty) { $ublue_image_tag } else { $version }
            
            let append_content = $"
# ($image_name) image identity
VARIANT_ID=\"($image_flavor)\"
PRETTY_NAME=\"($pretty_name)\"
NAME=\"($image_name)\"
IMAGE_ID=\"($image_name)\"
IMAGE_VERSION=\"($os_version)\"
ID_LIKE=\"($image_like)\"
HOME_URL=\"($home_url)\"
DOCUMENTATION_URL=\"($documentation_url)\"
SUPPORT_URL=\"($support_url)\"
BUG_REPORT_URL=\"($bug_report_url)\"
"
            # Append to file
            $append_content | save --append $os_release_path
            print $"Customized ($os_release_path)"
        }
    }
}
