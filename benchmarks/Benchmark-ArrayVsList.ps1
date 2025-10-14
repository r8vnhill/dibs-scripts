#Requires -Version 7.5
$n = 100000
$results = @()

# Arreglo con +=
$timeArray = Measure-Command {
    $a = @()
    foreach ($i in 1..$n) {
        $a += "x$i"
    }
}
$results += @{
    Method            = 'Array +='
    TotalMilliseconds = $timeArray.TotalMilliseconds
}

# List[T] con Add()
$timeList = Measure-Command {
    $l = [System.Collections.Generic.List[string]]::new()
    foreach ($i in 1..$n) {
        $l.Add("x$i")
    }
}
$results += @{
    Method            = 'List[T].Add()'
    TotalMilliseconds = $timeList.TotalMilliseconds
}

# Mostrar como tabla
Write-Output ('{0,-20} {1,10}' -f 'Método', 'Tiempo (ms)')
foreach ($r in $results) {
    Write-Output ('{0,-20} {1,10}' -f $r.Method, $r.TotalMilliseconds)
}
