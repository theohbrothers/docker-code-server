# Docker image variants' definitions
$local:VARIANTS_MATRIX = @(
    @{
        package = 'code-server'
        package_version = '4.9.1'
        distro = 'alpine'
        distro_version = '3.15'
        subvariants = @(
            @{ components = @(); tag_as_latest = $true } # Base
        )
    }
    @{
        package = 'code-server'
        package_version = '4.8.3'
        distro = 'alpine'
        distro_version = '3.15'
        subvariants = @(
            @{ components = @() } # Base
            @{ components = @( 'pwsh-7.3.1' ) } # Incremental
            @{ components = @( 'pwsh-7.2.8' ) } # Incremental
            @{ components = @( 'pwsh-7.1.7' ) } # Incremental
            @{ components = @( 'pwsh-7.0.13' ) } # Incremental
        )
    }
    @{
        package = 'code-server'
        package_version = '4.7.1'
        distro = 'alpine'
        distro_version = '3.15'
        subvariants = @(
            @{ components = @() } # Base
        )
    }
    @{
        package = 'code-server'
        package_version = '4.6.1'
        distro = 'alpine'
        distro_version = '3.15'
        subvariants = @(
            @{ components = @() } # Base
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
                    package_version_semver = "v$( $variant['package_version'] )" -replace '-r\d+', ''   # E.g. Strip out the '-r' in '2.3.0.0-r1'
                    distro = $variant['distro']
                    distro_version = $variant['distro_version']
                    base_tag = if (!$subVariant['components']) {
                        # Base
                        ''
                    }else {
                        # Incremental
                        @(
                            "v$( $variant['package_version'] )" -replace '-r\d+', ''    # E.g. Strip out the '-r' in '2.3.0.0-r1'
                            $variant['distro']
                            $variant['distro_version']
                        ) -join '-'
                    }
                    platforms = 'linux/amd64'
                    components = $subVariant['components']
                }
                # Docker image tag. E.g. 'v2.3.0.0-alpine-3.6'
                tag = @(
                        "v$( $variant['package_version'] )" -replace '-r\d+', ''    # E.g. Strip out the '-r' in '2.3.0.0-r1'
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
                includeHeader = $false
                includeFooter = $false
                passes = @(
                    @{
                        variables = @{}
                    }
                )
            }
        }
    }
}
