function ConvertFrom-SecureToPlain {
    
    param( [Parameter(Mandatory=$true)][System.Security.SecureString] $SecurePassword)
    
    # Create a "password pointer"
    $PasswordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
    
    # Get the plain text version of the password
    $PlainTextPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto($PasswordPointer)
    
    # Free the pointer
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($PasswordPointer)
    
    # Return the plain text password
    $PlainTextPassword
    
}
