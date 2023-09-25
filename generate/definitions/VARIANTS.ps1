$local:VERSIONS = @( Get-Content $PSScriptRoot/versions.json -Encoding utf8 -raw | ConvertFrom-Json )

# Docker image variants' definitions
$local:VARIANTS_MATRIX = @(
    foreach ($v in $local:VERSIONS.'code-server'.versions) {
        @{
            package = 'code-server'
            package_version = $v
            distro = 'alpine'
            distro_version = '3.15'
            subvariants = @(
                if ($v -eq '4.8.3') {
                    @{ components = @() } # Base
                    @{ components = @( 'docker' ) } # Incremental
                    # Invoke-RestMethod https://go.dev/dl/?mode=json&include=all
                    @{ components = @( 'docker', 'go-1.20.8' ) } # Incremental
                    @{ components = @( 'docker-rootless' ) } # Incremental
                    @{ components = @( 'docker-rootless', 'go-1.20.8' ) } # Incremental
                }else {
                    @{ components = @() } # Base
                    @{ components = @( 'docker' ) } # Incremental
                    @{ components = @( 'docker-rootless' ) } # Incremental
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
                    base_tag = if ($subVariant['components'].Count -eq 0) {
                        '' # Base image has no base
                    }elseif ($subVariant['components'].Count -eq 1) {
                        # 1st incremental should point to base
                        @(
                            "v$( $variant['package_version'] )"
                            $variant['distro']
                            $variant['distro_version']
                        ) -join '-'
                    }else {
                        # 2nd or greater incremental should point to prior incremental
                        @(
                            "v$( $variant['package_version'] )"
                            $subVariant['components'][0..($subVariant['components'].Count - 2)]
                            $variant['distro']
                            $variant['distro_version']
                        ) -join '-'
                    }
                    platforms = 'linux/amd64'
                    components = $subVariant['components']
                    job_group_key = $variant['package_version']
                }
                # Docker image tag. E.g. 'v2.3.0-alpine-3.6'
                tag = @(
                        "v$( $variant['package_version'] )"
                        $subVariant['components'] | ? { $_ }
                        $variant['distro']
                        $variant['distro_version']
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
