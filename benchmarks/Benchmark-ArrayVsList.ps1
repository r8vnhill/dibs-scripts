#Requires -Version 7.5
$n = 100000
$results = [System.Collections.Generic.List[PSCustomObject]]::new()

# Arreglo con +=
$timeArray = Measure-Command {
    $a = @()
    foreach ($i in 1..$n) {
        $a += "x$i"
    }
}
$results.Add([PSCustomObject]@{
        Method            = 'Array +='
        TotalMilliseconds = $timeArray.TotalMilliseconds
    })

# List[T] con Add()
$timeList = Measure-Command {
    $l = [System.Collections.Generic.List[string]]::new()
    foreach ($i in 1..$n) {
        $l.Add("x$i")
    }
}
$results.Add([PSCustomObject]@{
        Method            = 'List[T].Add()'
        TotalMilliseconds = $timeList.TotalMilliseconds
    })

$results
