# Author: Mason Palma
# Date: 22JUN2021
# Purpose: To provide a SimpleHTTPServer in Powershell
# Credits: Much of this code was taken from Microsoft's C# documentation then translated to powershell

$listener = [System.Net.HttpListener]::new();
$current_dir = $(Get-Location).Path;
$port = 8000;
$prefix = "http://" + $current_dir  + ":" + $port + "`/";

$listener.Prefixes.add("http://127.0.0.1:$($port)/");
$outward_ip = Get-NetIPAddress -AddressFamily IPv4

#create prefixes for each file in directory, this allows each file in directory to be gettable from uri
foreach($file in $files){$listener.Prefixes.Add("http://localhost:$($port)" + "`/" + [string]$file);}

#Start listener; console write out
$listener.Start();
write-host "Listening on port $($port)" -BackgroundColor Red -ForegroundColor DarkYellow;

try{

    while ($listener.IsListening)
    {
        
        [System.Net.HttpListenerContext]$context = $listener.GetContext();
        [System.Net.HttpListenerRequest]$request = $context.Request;
        [System.Net.HttpListenerResponse]$response = $context.Response;

        ##List Files in directory using HTML

        $files = Get-ChildItem $current_dir;

        [string]$response_text = "<!DOCTYPE html><title>$($current_dir)</title><BODY><h1>$($current_dir)</h1>
        $(foreach ($file in $files)
        {
        "<li>
            <a href=$([string]$file) download=$([string]$file)>$([string]$file)</a>
        </li>"
        })
        </BODY></HTML>";

        ##End List files in directory 

        #Verify only GET request
        if ($request.HttpMethod -eq "GET")
        {
            #Debug statements to verify resource GET
            write-host "Full URL : " $([string]$request.Url);
            write-host "Resource : " $([string]$request.RawUrl);
            
            write-host $request.LocalEndPoint
            write-host $request.RemoteEndPoint

            #Translate URI get to Dir Format
            [string]$get_resource = [string]$request.RawUrl -replace "/","";
    
            #Start valid request flag to identify resource exists
            $valid_req = $false;
            foreach ($file in $files)
            {
                if([string]$get_resource -eq [string]$file)
                {
                    $valid_req = $true;
                    #write-host $([string]$get_resource) is a valid resource. -BackgroundColor Yellow -ForegroundColor Green 
                }
            }
            #End valid request flag
    
            #If valid request, return response of data from StreamReader
            if ($valid_req -eq $true)
            {
                write-host $([string]$get_resource) is a valid resource. -BackgroundColor Yellow -ForegroundColor Red;
                
                [System.Net.HttpListenerContext]$context1 = [System.Net.HttpListenerContext]$context;
                [System.Net.HttpListenerRequest]$request1 = $context1.Request;
                [System.Net.HttpListenerResponse]$response1 = $context1.Response;
                
                $full_path = $current_dir + '\' + $get_resource

                $buffer1 = [System.Text.Encoding]::UTF8.GetBytes($([System.IO.StreamReader]::new($full_path).ReadToEnd()));

                $response1.ContentLength64 = [System.Int64]$buffer1.Length;
                [System.IO.Stream]$output1 = $response1.OutputStream;

                $output1.Write($buffer1, 0, [System.Int64]$buffer1.Length);
                $output1.Flush();
                

            }
            else
            {
                #for directory GET, List File
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($response_text);
                $response.ContentLength64 = $buffer.Length;
                [System.IO.Stream]$output = $response.OutputStream;
                $output.Write($buffer,0,$buffer.Length);
                $output.Flush();
            }
        }
    }
    
    $output.Close();
    $listener.Stop();
}

catch [System.Exception]{
    
    Write-Error ($_.Exception | Format-List -Force | Out-String) -ErrorAction Continue
    Write-Error ($_.InvocationInfo | Format-List -Force | Out-String) -ErrorAction Continue

    $output.Close();
    $listener.Stop();
}

finally {
    $output.Close();
    $listener.Stop(); 
}
