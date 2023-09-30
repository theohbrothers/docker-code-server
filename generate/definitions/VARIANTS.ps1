$local:VERSIONS = @( Get-Content $PSScriptRoot/versions.json -Encoding utf8 -raw | ConvertFrom-Json )

# Docker image variants' definitions
$local:VARIANTS_MATRIX = @(
    foreach ($v in $local:VERSIONS.'code-server'.versions) {
        @{
            package = 'code-server'
            package_version = $v
            distro = 'alpine'
            distro_version = if ([version]$v -ge [version]'4.17') { '3.17' } else { '3.15' }
            subvariants = @(
                @{ components = @() }
                @{ components = @( 'docker' ) }
                foreach ($v in $local:VERSIONS.go.versions) {
                    @{ components = @( 'docker', "go-$v" ) }
                }
                @{ components = @( 'docker-rootless' ) }
                foreach ($v in $local:VERSIONS.go.versions) {
                    @{ components = @( 'docker-rootless', "go-$v" ) }
                }
            )
        }
    }
)

$VARIANTS = @(
    foreach ($variant in $VARIANTS_MATRIX){
        foreach ($subVariant in $variant['subvariants']) {
            @{
                # Metadata object
                _metadata = @{
                    package = $variant['package']
                    package_version = $variant['package_version']
                    distro = $variant['distro']
                    distro_version = $variant['distro_version']
                    platforms = 'linux/amd64'
                    components = $subVariant['components']
                    job_group_key = $variant['package_version']
                }
                # Docker image tag. E.g. '2.17.0' or '2.17.0[-component..]'
                tag = @(
                        $variant['package_version']
                        $subVariant['components'] | ? { $_ }
                ) -join '-'
                tag_as_latest = if ($variant['package_version'] -eq $local:VARIANTS_MATRIX[0]['package_version'] -and $subVariant['components'].Count -eq 0) { $true } else { $false }
            }
        }
    }
)

# Docker image variants' definitions (shared)
$VARIANTS_SHARED = @{
    buildContextFiles = @{
        templates = @{
            'Dockerfile' = @{
                common = $true
                passes = @(
                    @{
                        variables = @{}
                    }
                )
            }
            'docker-entrypoint.sh' = @{
                common = $true
                passes = @(
                    @{
                        variables = @{}
                    }
                )
            }
            'settings.json' = @{
                common = $true
                passes = @(
                    @{
                        variables = @{}
                    }
                )
            }
        }
    }
}

# Global cache for remote file content
$global:CACHE = @{}
