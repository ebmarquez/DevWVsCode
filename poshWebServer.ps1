#!/usr/bin/pwsh -Command

$health = '/health'
$port = 8080
$UrlPrefix = (hostname -i)
$listener = New-Object System.Net.HttpListener

# using the Plus will make the listening port agnostic when running in a linux container.
Write-Host ("Adding URI to the listener http://+:{1}{2}" -f $UrlPrefix, $port, $health)
$listener.Prefixes.Add(("http://+:{1}{2}" -f $UrlPrefix, $port, ($health + '/') ))
Write-Host ("Starting WebService Listener")
$listener.Start()
Write-Host ("Webserver is listening: [{0}]" -f $listener.IsListening)
while ($listener.IsListening) {
    $content = $null
    Write-Host ("Waiting for Context")
    $context = $listener.GetContext()
    Write-Host ("UserAgent: {0}" -f $context.Request.UserAgent)
    Write-Host ("RawURL: {0}" -f $context.Request.RawUrl)
    Write-Host ("UserHostName: {0}" -f $context.Request.UserHostName)
    Write-Host ("Context Method: [{0}]" -f $context.Request.HttpMethod)
    Write-Host ("RemoteEndPoint: [{0}]" -f $context.Request.RemoteEndPoint)
    Write-Host ("LocalEndPoint: [{0}]" -f $context.Request.LocalEndPoint)

    if ($context.Request.HttpMethod -eq 'GET') {
        $url = $context.Request.Url.LocalPath
        if ($url -eq $health -or $url -eq ($health + '/')) {
            $context.Response.ContentType = 'application/json'
            Write-Host 'Heath Called, response: { "Version": "1.1.1.1" }'
            $content = [Text.Encoding]::UTF8.GetBytes('{ "Version": "1.1.1.1" }')
        }
    }
    else {
        $context.Response.StatusCode = 404
        $message = "<h1>404 - Page Not Found URL:$($context.Request.HttpMethod) $($context.Request.Url) </h1>"
        $content = [System.Text.Encoding]::UTF8.GetBytes($message)
    }

    $context.Response.OutputStream.Write($content, 0, $content.Length)
    $context.Response.Close()
}