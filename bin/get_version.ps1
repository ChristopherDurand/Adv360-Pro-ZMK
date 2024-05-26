# Get the date, first 4 chars of branch name, and short commit hash
$date = Get-Date -Format "yyyyMMdd"
$branch = if ($args.Count -ge 1) { $args[0].Substring(0, 4) } else { (git rev-parse --abbrev-ref HEAD).Substring(0, 4) }
$commit = if ($args.Count -ge 2) { $args[1] } else { git rev-parse --short HEAD }

function uppercase_char {
    param (
        [string]$char
    )

    return $char.ToUpper()
}

# Function to transform characters to ZMK key behaviours
function transform_char {
    param (
        [string]$char
    )

    if ($char -match "[A-Za-z]") {
        return "<&kp $(uppercase_char $char)>, "
    } elseif ($char -match "[0-9]") {
        return "<&kp N${char}>, "
    } elseif ($char -eq ".") {
        return "<&kp DOT>, "
    }
}

# Iterate over the date and format characters
$formatted_date = ""
for ($i = 0; $i -lt $date.Length; $i++) {
    $formatted_date += transform_char $date[$i]
}

# Insert separator between date and branch
$formatted_date += "<&kp MINUS>, "

# Iterate over the branch and format characters
$formatted_branch = ""
for ($i = 0; $i -lt $branch.Length; $i++) {
    $formatted_branch += transform_char $branch[$i]
}

# Insert separator between branch and commit hash
$formatted_branch += "<&kp MINUS>, "

# Iterate over the commit hash and format characters
$formatted_commit = ""
for ($i = 0; $i -lt $commit.Length; $i++) {
    $formatted_commit += transform_char $commit[$i]
}

# Combine the formatted string, add trailing carriage return
$formatted_result = "$formatted_date$formatted_branch$formatted_commit"
$formatted_result += "<&kp RET>"

Write-Output $formatted_result

# Create new macro to define version, overwrite previous one
$macro_content = @"
#define VERSION_MACRO
macro_ver: macro_ver {
    compatible = "zmk,behavior-macro";
    label = "macro_ver";
    #binding-cells = <0>;
    bindings = $formatted_result;
};
"@

$macro_content | Set-Content -Path "config/version.dtsi"
