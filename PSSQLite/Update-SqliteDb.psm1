function Update-SqliteDbPassword {
    [CmdletBinding()]
    param(
        [Parameter( Position=0,
                    Mandatory=$true,
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false,
                    HelpMessage='SQLite Data Source required...' )]
        [Alias('Path','File','FullName','Database')]
        [validatescript({
            #This should match memory, or the parent path should exist
            $Parent = Split-Path $_ -Parent
            if(
                $_ -match ":MEMORY:|^WHAT$" -or
                ( $Parent -and (Test-Path $Parent))
            ){
                $True
            }
            else {
                Throw "Invalid datasource '$_'.`nThis must match :MEMORY:, or '$Parent' must exist"
            }
        })]
        [string[]]
        $DataSource,
		
		[Parameter( Position=1,
					Mandatory=$true,
					ValueFromPipeline=$false,
					ValueFromPipelineByPropertyName=$false,
					ValueFromRemainingArguments=$false,
                    HelpMessage='Password for SQLite Data Source' )]
		[Alias( 'Pass' )]
		[string]
		$Password,
		
		[Parameter( Position=1,
					Mandatory=$true,
					ValueFromPipeline=$false,
					ValueFromPipelineByPropertyName=$false,
					ValueFromRemainingArguments=$false,
                    HelpMessage='New password for SQLite Data Source' )]
		[Alias( 'NewPass' )]
		[string]
		$NewPassword
    ) 

    Begin
    {
        #Assembly, should already be covered by psm1
            Try
            {
                [void][System.Data.SQLite.SQLiteConnection]
            }
            Catch
            {
                if( -not ($Library = Add-Type -path $SQLiteAssembly -PassThru -ErrorAction stop) )
                {
                    Throw "This module requires the ADO.NET driver for SQLite:`n`thttp://system.data.sqlite.org/index.html/doc/trunk/www/downloads.wiki"
                }
            }
    }
    Process
    {
        foreach($DB in $DataSource)
        {
			# Resolve the path entered for the database to a proper path name.
			# This accounts for a variaty of possible ways to provide a path, but
			# in the end the connection string needs a fully qualified file path.
			if ($DB -match ":MEMORY:") 
			{
				$Database = $DB
			}
			else 
			{
				$Database = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DB)    
			}
			
			if (Test-Path $Database)
			{
				$ConnectionString = "Data Source={0};Version=3;Password='{1}';" -f $Database, $Password.Replace("'", "&#39;")
				$conn = New-Object System.Data.SQLite.SQLiteConnection -ArgumentList $ConnectionString
				
				Try {
					$conn.Open()
					$conn.ChangePassword($NewPassword.Replace("'", "&#39;"));
					$conn.Close()
				}
				Catch {
					Write-Error $_
					continue
				}
				
			}
			else {
				Write-Verbose "Database does not exist"
			}
        }
    }
}
