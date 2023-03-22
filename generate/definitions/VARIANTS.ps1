# Docker image variants' definitions
$local:VARIANTS_MATRIX = @(
    @{
        package = 'code-server'
        package_version = '4.11.0'
        distro = 'alpine'
        distro_version = '3.15'
        subvariants = @(
            @{ components = @(); tag_as_latest = $true } # Base
            @{ components = @( 'docker' ) } # Incremental
            @{ components = @( 'docker-rootless' ) } # Incremental
        )
    }
    @{
        package = 'code-server'
        package_version = '4.10.1'
        distro = 'alpine'
        distro_version = '3.15'
        subvariants = @(
            @{ components = @() } # Base
            @{ components = @( 'docker' ) } # Incremental
            @{ components = @( 'docker-rootless' ) } # Incremental
        )
    }
    @{
        package = 'code-server'
        package_version = '4.9.1'
        distro = 'alpine'
        distro_version = '3.15'
        subvariants = @(
            @{ components = @(); } # Base
            @{ components = @( 'docker' ) } # Incremental
            @{ components = @( 'docker-rootless' ) } # Incremental
        )
    }
    @{
        package = 'code-server'
        package_version = '4.8.3'
        distro = 'alpine'
        distro_version = '3.15'
        subvariants = @(
            @{ components = @() } # Base
            @{ components = @( 'docker' ) } # Incremental
            # Invoke-RestMethod https://go.dev/dl/?mode=json&include=all
            @{ components = @( 'docker', 'go-1.17.13' ) } # Incremental
            @{ components = @( 'docker', 'go-1.18.10' ) } # Incremental
            @{ components = @( 'docker', 'go-1.19.7' ) } # Incremental
            @{ components = @( 'docker', 'go-1.20.2' ) } # Incremental
            @{ components = @( 'docker-rootless' ) } # Incremental
            @{ components = @( 'docker-rootless', 'go-1.17.13' ) } # Incremental
            @{ components = @( 'docker-rootless', 'go-1.18.10' ) } # Incremental
            @{ components = @( 'docker-rootless', 'go-1.19.7' ) } # Incremental
            @{ components = @( 'docker-rootless', 'go-1.20.2' ) } # Incremental
        )
    }
    @{
        package = 'code-server'
        package_version = '4.7.1'
        distro = 'alpine'
        distro_version = '3.15'
        subvariants = @(
            @{ components = @() } # Base
            @{ components = @( 'docker' ) } # Incremental
            @{ components = @( 'docker-rootless' ) } # Incremental
        )
    }
    @{
        package = 'code-server'
        package_version = '4.6.1'
        distro = 'alpine'
        distro_version = '3.15'
        subvariants = @(
            @{ components = @() } # Base
            @{ components = @( 'docker' ) } # Incremental
            @{ components = @( 'docker-rootless' ) } # Incremental
        )
    }
    # @{
    #     package = 'code-server'
    #     package_version = '3.12.0'
    #     distro = 'alpine'
    #     distro_version = '3.14'
    #     subvariants = @(
    #         @{ components = @() } # Base
    #     )
    # }
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
                }
                # Docker image tag. E.g. 'v2.3.0-alpine-3.6'
                tag = @(
                        "v$( $variant['package_version'] )"
                        $subVariant['components'] | ? { $_ }
                        $variant['distro']
                        $variant['distro_version']
                ) -join '-'
                tag_as_latest = if ( $subVariant.Contains('tag_as_latest') ) {
                    $subVariant['tag_as_latest']
                } else {
                    $false
                }
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
