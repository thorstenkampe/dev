Describe 'Test script' {
    It 'option help' {
        $result   = ./script.ps1 -h
        $result   = $result.Split([Environment]::NewLine)[0]
        $expected = 'script.ps1 [-Help] [<CommonParameters>]'

        Assert-True -Actual $?
        Assert-Equal -Actual $result -Expected $expected
    }

    It 'unknown option' {
        $exception = "A parameter cannot be found that matches parameter name 'x'."
        {./script.ps1 -x}  | Should -Throw -ExpectedMessage $exception
    }
}
