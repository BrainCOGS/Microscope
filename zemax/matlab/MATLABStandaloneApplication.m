function [ r ] = MATLABStandaloneApplication( args )

if ~exist('args', 'var')
    args = [];
end

% Initialize the OpticStudio connection
TheApplication = InitConnection();
if isempty(TheApplication)
    % failed to initialize a connection
    r = [];
else
    try
        r = BeginApplication(TheApplication, args);
        CleanupConnection(TheApplication);
    catch err
        CleanupConnection(TheApplication);
        rethrow(err);
    end
end
end


function [r] = BeginApplication(TheApplication, args)

import ZOSAPI.*;

    % Open file
    testFile = System.String.Concat('C:\Users\Manuel\Desktop\excitation_twinkle.zos');

    peaks = [];
    dz = 0.1;     % steps of 100 nm in z
    dangle = 0.5; % steps of 0.5 degree in galvo

    angles = -10:dangle:10;
    zs = (-20:dz:20)*1e-3;

    psf_all = zeros(length(angles), 32, 32, length(zs));

    angle_idx = 1;
    for angle = angles
        z_idx     = 1;
        for z = zs
            TheSystem = TheApplication.PrimarySystem;
            TheSystem.LoadFile(testFile,false);
            TheSystem.LDE.GetSurfaceAt(3).GetCellAt(14).DoubleValue =  angle;
            TheSystem.LDE.GetSurfaceAt(5).GetCellAt(14).DoubleValue = -angle;
            
            TheSystem.LDE.GetSurfaceAt(38).Thickness = 0.007 + z;
    
            testFile2 = System.String.Concat('C:\Users\Manuel\Desktop\tmp.zos');
            TheSystem.SaveAs(testFile2);
            try
                newWin = TheSystem.Analyses.New_HuygensPsf;
                newWin.ApplyAndWaitForCompletion();
                newWin_Results = newWin.GetResults();
                dataGrid = newWin_Results.DataGrids(1);
                PSFslice = dataGrid.Values.double;
                psf_all(angle_idx,:,:,z_idx) = PSFslice;
            end
            TheSystem.Disconnect();
            disp([round(100*angle_idx/length(angles)), z_idx]); % Progress

            z_idx = z_idx + 1;
        end
        angle_idx = angle_idx + 1;
    end
    
    export = struct;
    export.results          = psf_all;
    export.resolutionDx     = dataGrid.Dx;
    export.resolutionDy     = dataGrid.Dy;
    export.resolutionDz     = dz;
    export.resolutionDangle = dangle;

    save("./zemax_results.mat", 'export')
    r = [];
end

function app = InitConnection()

import System.Reflection.*;

% Find the installed version of OpticStudio.
zemaxData = winqueryreg('HKEY_CURRENT_USER', 'Software\Zemax', 'ZemaxRoot');
NetHelper = strcat(zemaxData, '\ZOS-API\Libraries\ZOSAPI_NetHelper.dll');
% Note -- uncomment the following line to use a custom NetHelper path
% NetHelper = 'C:\Users\Manuel\Documents\Zemax\ZOS-API\Libraries\ZOSAPI_NetHelper.dll';
% This is the path to OpticStudio
NET.addAssembly(NetHelper);

success = ZOSAPI_NetHelper.ZOSAPI_Initializer.Initialize();
% Note -- uncomment the following line to use a custom initialization path
% success = ZOSAPI_NetHelper.ZOSAPI_Initializer.Initialize('C:\Program Files\OpticStudio\');
if success == 1
    LogMessage(strcat('Found OpticStudio at: ', char(ZOSAPI_NetHelper.ZOSAPI_Initializer.GetZemaxDirectory())));
else
    app = [];
    return;
end

% Now load the ZOS-API assemblies
NET.addAssembly(AssemblyName('ZOSAPI_Interfaces'));
NET.addAssembly(AssemblyName('ZOSAPI'));

% Create the initial connection class
TheConnection = ZOSAPI.ZOSAPI_Connection();

% Attempt to create a Standalone connection

% NOTE - if this fails with a message like 'Unable to load one or more of
% the requested types', it is usually caused by try to connect to a 32-bit
% version of OpticStudio from a 64-bit version of MATLAB (or vice-versa).
% This is an issue with how MATLAB interfaces with .NET, and the only
% current workaround is to use 32- or 64-bit versions of both applications.
app = TheConnection.CreateNewApplication();
if isempty(app)
   HandleError('An unknown connection error occurred!');
end
if ~app.IsValidLicenseForAPI
    HandleError('License check failed!');
    app = [];
end

end

function LogMessage(msg)
disp(msg);
end

function HandleError(error)
ME = MException('zosapi:HandleError', error);
throw(ME);
end

function  CleanupConnection(TheApplication)
% Note - this will close down the connection.

% If you want to keep the application open, you should skip this step
% and store the instance somewhere instead.
TheApplication.CloseApplication();
end


