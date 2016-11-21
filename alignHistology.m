function alignHistology(varargin)
% use:
% alignHistology('/Volumes/RecordingsLeventhal2/ChoiceTask/R0125/R0125-histology/Nissl',true);
% See Box > Protocols > Histology > Align Protocol.docx
% varargin{2} is 'break after compress'

if isempty(varargin)    
    histoDir = uigetdir(pwd,'Select histology directory');
else
    histoDir = varargin{1};
end

% compress images but skip if dir exists
compressedDir = fullfile(histoDir,'compressed');
if ~isdir(compressedDir)
    % found hidden files in this dir, using R* wildcard
    tifFiles = dir(fullfile(histoDir,'*.TIF'));
    if isempty(tifFiles)
        error('No TIF files found in directory');
    end

    % sort by date, assumming they are scanned in order
    datenums = cell2mat({tifFiles(:).datenum});
    [~,idx] = sort(datenums);
    tifFiles = {tifFiles(idx).name};

    h = waitbar(0,'Compressing Images');
    mkdir(compressedDir);
    for iTif = 1:length(tifFiles)
        waitbar(iTif/length(tifFiles),h,'Compressing Images');
        A = imread(fullfile(histoDir,tifFiles{iTif}));
        A = imresize(A,0.5);
        A = autocontrast(A);
        imwrite(A,fullfile(compressedDir,[tifFiles{iTif},'.jpeg']));
    end
    close(h);
end

if nargin == 2
    return;
end

% work with compress files
jpegFiles = dir(fullfile(compressedDir,'R*.jpeg'));
jpegFiles = natsort({jpegFiles.name});

% user selects files to use
% [] exit on cancel
imageIds = [];
while length(imageIds) < 2
    imageIds = listdlg('PromptString','Select starting file:',...
                'SelectionMode','multiple','ListSize',[200 600],...
                'ListString',jpegFiles);
end

iImage = 1;
initMag = 25;
while iImage < length(imageIds)
    if iImage == 1
        IM1 = imread(fullfile(compressedDir,jpegFiles{imageIds(iImage)}));
        h = figure;
        imshow(IM1,'InitialMagnification',initMag);
        choice = questdlg('Flip horizontal?','','No','Yes','No');
        switch choice
            case 'Yes'
                IM1 = flip(IM1,2);
                imshow(IM1,'InitialMagnification',initMag);
        end
        
        doRotate = true;
        imRot = 0;
        IMtemp = IM1;
        while doRotate
            choice = questdlg('Rotate?','','Keep','Clockwise','Counter Clockwise','Keep');
            switch choice
                case 'Keep'
                    doRotate = false;
                case 'Clockwise'
                    imRot = imRot - 10;
                    IMtemp = imrotate(IM1,imRot);
                    imshow(IMtemp,'InitialMagnification',initMag);
                case 'Counter Clockwise'
                    imRot = imRot + 10;
                    IMtemp = imrotate(IM1,imRot);
                    imshow(IMtemp,'InitialMagnification',initMag);
            end
        end
        IM1 = IMtemp;
        close(h);
        
        alignedDir = fullfile(compressedDir,'aligned');
        if ~isdir(alignedDir)
            mkdir(alignedDir);
        end
        imwrite(IM1,fullfile(alignedDir,jpegFiles{imageIds(iImage)}));
        
        h = msgbox('Select 4 or more control points. Press cmd/ctrl+W after selection of points.');
        uiwait(h);
    else
        IM1 = IM2registered;
    end
    
    IM2 = imread(fullfile(compressedDir,jpegFiles{imageIds(iImage+1)}));
    [moving_out,fixed_out] = cpselect(IM2,IM1,'Wait',true);
    if length(moving_out) >= 4
        mytform = fitgeotrans(moving_out,fixed_out,'projective');
        rIM1 = imref2d(size(IM1));
        IM2registered = imwarp(IM2,mytform,'OutputView',rIM1);
        h = figure; 
        imshowpair(IM2registered,IM1,'blend');
        choice = questdlg('How does it look?','','Keep','Redo','Skip','Keep');
        switch choice
            case 'Keep'
                imwrite(IM2registered,fullfile(alignedDir,jpegFiles{imageIds(iImage+1)}));
                iImage = iImage + 1;
            case 'Redo'
                continue;
            case 'Skip'
                iImage = iImage + 1;
        end
        close(h);
    else
        choice = questdlg('You must have 4 or more control points.','','Skip','Redo','Exit','Skip');
        switch choice
            case 'Skip'
                iImage = iImage + 1;
            case 'Redo'
                continue;
            case 'Exit'
                break;
        end
    end
end