$n = 100000

$results = @()

# Arreglo con +=
$timeArray = Measure-Command {
    $a = @()
    1..$n | ForEach-Object { $a += "x$_" }
}
$results += [pscustomobject]@{
    Method            = 'Array +='
    TotalMilliseconds = $timeArray.TotalMilliseconds
}

# List[T] con Add()
$timeList = Measure-Command {
    $l = [System.Collections.Generic.List[string]]::new()
    1..$n | ForEach-Object { $l.Add("x$_") }
}
$results += [pscustomobject]@{
    Method            = 'List[T].Add()'
    TotalMilliseconds = $timeList.TotalMilliseconds
}

# Mostrar como tabla
$results | Format-Table -AutoSize
