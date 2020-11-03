Param ( 
  [Parameter(Mandatory=$true)][string]$sourceFolder,
  [Parameter(Mandatory=$true)][string]$output,
  [string]$mediaType = "DISK" 
)

$mediaTypes = @{CDR=2; 
                CDRW=3; 
                DVDRAM=5; 
                DVDPLUSR=6; 
                DVDPLUSRW=7; 
                DVDPLUSR_DUALLAYER=8; 
                DVDDASHR=9; 
                DVDDASHRW=10; 
                DVDDASHR_DUALLAYER=11; 
                DISK=12; 
                DVDPLUSRW_DUALLAYER=13; 
                BDR=18; 
                BDRE=19 } 

$fullPath = $output;

# Write all params to the console.
Write-Host ([Environment]::NewLine);
Write-Host ("Parameters:");
Write-Host ("----------");
Write-Host ("Sources folder: " + $sourceFolder);
Write-Host ("Ouput: " + $output);
Write-Host ("Media type: " + $mediaType);
Write-Host ([Environment]::NewLine)

$cp = New-Object CodeDom.Compiler.CompilerParameters;           
$cp.CompilerOptions = "/unsafe";
$cp.WarningLevel = 4;
$cp.TreatWarningsAsErrors = $true;

Add-Type -CompilerParameters $cp -TypeDefinition @"
namespace Local
{
    public static class ImageStreamWriter  
    { 
        public unsafe static void Write(string Path, object Stream, int BlockSize, int TotalBlocks)  
        {  
            int bytes = 0;  
            byte[] buf = new byte[BlockSize];  
            var ptr = (System.IntPtr)(&bytes);  
            var o = System.IO.File.OpenWrite(Path);  
            var i = Stream as System.Runtime.InteropServices.ComTypes.IStream;  
  
            if (o != null) 
            { 
                while (TotalBlocks-- > 0) 
                {  
                    i.Read(buf, BlockSize, ptr); o.Write(buf, 0, bytes);  
                }  
                o.Flush(); o.Close();  
            } 
        } 
    } 
} 
"@

if (-not (Test-Path $sourceFolder))
    {
        Write-Host ($sourceFolder + " does not exist. Process aborted.");
        return;
    }

Write-Host ("Preparing folder structure...");
$fsi = New-Object -ComObject IMAPI2FS.MsftFileSystemImage;
$fsi.ChooseImageDefaultsForMediaType($mediaTypes[$mediaType]);
$fsi.VolumeName = $fileName;
$fsi.Root.AddTree($sourceFolder, $false);

Write-Host ("Writing system image...");
$image = $fsi.CreateResultImage();

Write-Host ("Saving system image to '" + $fullPath + "'...");
[Local.ImageStreamWriter]::Write($fullPath, $image.ImageStream, $image.BlockSize,$image.TotalBlocks); 
Write-Host("Done!");