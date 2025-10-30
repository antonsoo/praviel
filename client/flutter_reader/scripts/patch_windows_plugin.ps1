# Patch flutter_secure_storage_windows CMakeLists.txt for version 3.1.2
# This fixes the missing include directory bug

$cmakeFile = "windows\flutter\ephemeral\.plugin_symlinks\flutter_secure_storage_windows\windows\CMakeLists.txt"

if (Test-Path $cmakeFile) {
    Write-Host "Patching $cmakeFile..."

    $content = Get-Content $cmakeFile -Raw

    # Check if already patched
    if ($content -match 'target_include_directories\(\$\{PLUGIN_NAME\} PRIVATE') {
        Write-Host "Already patched!"
        exit 0
    }

    # Replace INTERFACE with PRIVATE and keep INTERFACE
    $content = $content -replace `
        'target_include_directories\(\$\{PLUGIN_NAME\} INTERFACE\s+"\$\{CMAKE_CURRENT_SOURCE_DIR\}/include"\)', `
        "target_include_directories(`${PLUGIN_NAME} PRIVATE`n  `"`${CMAKE_CURRENT_SOURCE_DIR}/include`")`ntarget_include_directories(`${PLUGIN_NAME} INTERFACE`n  `"`${CMAKE_CURRENT_SOURCE_DIR}/include`")"

    Set-Content -Path $cmakeFile -Value $content
    Write-Host "Patch applied successfully!"
} else {
    Write-Host "CMake file not found. Run 'flutter pub get' first."
    exit 1
}
