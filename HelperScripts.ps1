function Round([Decimal]$a, [int]$b){
    return [math]::round($a, $b)
}

# Run a process, and throwing if return code is not 0
function Run{
    param(
        [String]$FilePath,
        [String]$Arguments,
        [Bool]$ContinueOnError = $False,
        [Bool]$Echo = $True
    )

    if ($Echo)
    {
        "$FilePath $Arguments"
    }

    $elapsed = Measure-Command { $process = Start-Process -FilePath $FilePath -ArgumentList $Arguments -Wait -PassThru -NoNewWindow }

    "Finished in $(Round $elapsed.TotalSeconds 2) seconds"

    if ($ContinueOnError)
    {
        "Exited with status code $($process.ExitCode)"
        return
    }

    if ($process.ExitCode -ne 0)
    {
        throw "Exited with status code $($process.ExitCode)"
    }
}

function Download-If-Not-Exist{
    param(
        [String]$filePath,
        [String]$url
    )

    if (-Not (Test-Path $filePath)) {
        Run "curl" "-L -s -o $filePath $url"
    }
}