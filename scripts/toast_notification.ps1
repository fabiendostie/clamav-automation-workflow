param(
    [string]$virusName,
    [string]$fileName
)

# Try-catch block to handle errors
try {
    # Load necessary assemblies
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

    # Define the app ID (using Windows Defender's ID since we're doing security alerts)
    $AppId = "Microsoft.Windows.SecHealthUI_cw5n1h2txyewy!SecHealthUI"

    # Create the toast notification content
    $template = @"
<toast scenario="alarm">
    <visual>
        <binding template="ToastGeneric">
            <text>SECURITY ALERT: Virus Detected!</text>
            <text>$virusName</text>
            <text>Found in: $fileName</text>
        </binding>
    </visual>
    <audio src="ms-winsoundevent:Notification.Default" loop="false"/>
</toast>
"@

    # Create the XML document
    $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
    $xml.LoadXml($template)

    # Create and show the toast notification
    $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($AppId).Show($toast)
    
    Write-Output "Toast notification sent successfully."
} catch {
    # Fallback to simple notification if toast fails
    Write-Output "Toast notification failed: $_"
    # Try alternative notification method
    [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null
    [System.Windows.Forms.MessageBox]::Show("ClamAV has detected $virusName in file: $fileName", 'VIRUS ALERT!', 'OK', [System.Windows.Forms.MessageBoxIcon]::Warning)
}