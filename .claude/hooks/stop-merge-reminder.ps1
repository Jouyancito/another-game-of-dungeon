$ErrorActionPreference = 'SilentlyContinue'
$msg = git log -1 --pretty=%s 2>$null
if ($msg -match '^merge:') {
    Write-Output '{"systemMessage":"MERGE detectado en HEAD. Antes de cerrar sesion: llamar mem_session_summary con Goal/Discoveries/Accomplished/Next Steps/Files."}'
}
