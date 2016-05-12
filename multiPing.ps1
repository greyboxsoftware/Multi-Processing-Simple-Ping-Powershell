#Prompting the user to enter a text file path where a list of computers are located
$computerFile = Read-Host "Enter the path to a text file where the list of comptuers is located. i.e. c:\temp\computer.txt"

#Grabbing a list of computer names from a text file
$computerName = Get-Content $computerFile

#Setting up a max thread count
$threadCount = 2

#ForEach loop that will loop through a list of computers 
ForEach ($computer in $computerName) {

#This script block stores a list of commands that you want to perform. This is not just limited to a simple ping that I am demonstrating. 
$scriptBlock = {

        #parameter that you are receiving from outside the scriptblock will be stored here 
        param ($computerToPing)
        #Error handling Try/Catch Statement 
        Try {
        #Testing the connection to a computer or website quitely so it only stores a True or False statement
        $testComputerPing = Test-Connection -ComputerName $computerToPing -Count 1 -Quiet

        #condition if statment that will perform a action if the condition is true 
        if ($testComputerPing -eq 'True') {
            Write-Host "$computerToPing ping status is true" -ForegroundColor Green -BackgroundColor Black
        
        }
        #if the condition isnt true it will let you know that it failed
        else {Write-Host "$computerToPing ping timed out" -ForegroundColor Red -BackgroundColor Black}
        } 
        #by some happenstance that there is a unknown error in this simple script, it will be caught here and gracefully fail
        Catch { Write-Host "$computerToPing failed with error $_.ExceptionMessage" }
}

       #Starting a background job to run the commands in the scriptblock that you identified earlier and we are out-null this command to free up space in the console
       Start-Job -ScriptBlock $scriptBlock -ArgumentList $computer | Out-Null

       #while loop that will throttle the background jobs to not exceed the amount that you specified in $threadCount
       while($(Get-Job -State 'Running').Count -ge $threadCount)
       {
            Get-Job | Wait-Job | Out-Null
       }
       #Auto removes jobs that are marked complete
       Get-Job -State Completed | % {
            Receive-Job $_ -AutoRemoveJob -Wait
       }
}
#While loop that will wait until the remaining jobs are finished
While ($(Get-Job -State Running).Count -gt 0) {
   Get-Job | Wait-Job -Any | Out-Null
}
#once all the jobs are complete then all remaining jobs will be removed. 
Get-Job -State Completed | % {
   Receive-Job $_ -AutoRemoveJob -Wait
}