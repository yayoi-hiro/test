$rules = @{
    result = @(
        @{0="SUCCESS";1="ERROR"}
    )

    user = @(
        @{1="LOGIN";2="LOGOUT"}
        @{1="NORMAL";2="ADMIN"}
    )
}

#log.txt
#2026-03-13 result 0
#2026-03-13 user 1 2

Get-Content log.txt | ForEach-Object {

    $line = $_
    $parts = $line.Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)

    if ($parts.Length -ge 3)
    {
        $key = $parts[1]

        if ($rules.ContainsKey($key))
        {
            $maps = $rules[$key]
            $names = @()

            for ($i=0; $i -lt $maps.Count; $i++)
            {
                $index = $i + 2

                if ($index -lt $parts.Length)
                {
                    $code = [int]$parts[$index]
                    $map  = $maps[$i]

                    if ($map.ContainsKey($code))
                    {
                        $names += $map[$code]
                    }
                }
            }

            if ($names.Count -gt 0)
            {
                "$line (" + ($names -join ", ") + ")"
                return
            }
        }
    }

    $line
}