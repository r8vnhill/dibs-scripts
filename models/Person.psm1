class Person {
    [string] $FirstName
    [string] $LastName

    Person([string] $first, [string] $last) {
        $this.FirstName = $first
        $this.LastName = $last
    }

    [string] ToString() {
        return '{0} {1}' -f $this.FirstName, $this.LastName
    }
}
