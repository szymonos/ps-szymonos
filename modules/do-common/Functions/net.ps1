function Convert-CidrToRange {
    param (
        [Parameter(Mandatory)]
        [string]$cidrNotation
    )

    $addr, $maskLength = $cidrNotation -split '/'
    [int]$maskLen = 0
    if (-not [int32]::TryParse($maskLength, [ref] $maskLen)) {
        throw "Cannot parse CIDR mask length string: '$maskLen'"
    }
    if (0 -gt $maskLen -or $maskLen -gt 32) {
        throw 'CIDR mask length must be between 0 and 32'
    }
    $ipAddr = [Net.IPAddress]::Parse($addr)
    if ($ipAddr -eq $null) {
        throw "Cannot parse IP address: $addr"
    }
    if ($ipAddr.AddressFamily -ne [Net.Sockets.AddressFamily]::InterNetwork) {
        throw 'Can only process CIDR for IPv4'
    }

    $shiftCnt = 32 - $maskLen
    $mask = -bnot ((1 -shl $shiftCnt) - 1)
    $ipNum = [Net.IPAddress]::NetworkToHostOrder([BitConverter]::ToInt32($ipAddr.GetAddressBytes(), 0))
    $ipStart = ($ipNum -band $mask)
    $ipEnd = ($ipNum -bor (-bnot $mask))

    # return as tuple of strings:
    return [PSCustomObject]@{
        CidrRange  = $cidrNotation
        FirstIP    = [BitConverter]::GetBytes([Net.IPAddress]::HostToNetworkOrder($ipStart)) -join '.'
        LastIP     = [BitConverter]::GetBytes([Net.IPAddress]::HostToNetworkOrder($ipEnd)) -join '.'
        TotalHosts = $ipEnd - $ipStart + 1
    }
}
