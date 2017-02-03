function registerAndBlend(redDir,greenDir)

%% Register and Blend
% This function attempts to find slide images in two separate directories
% and blend them specifically using the red and green channels.
% It has (3) utilities:
%%
% # Standardizes file name extensions to 'jpeg'
% # Registers red and green images (i.e. aligns them)
% # Blends the red and green channel and saves multiple versions based
%   on a decorrelation stretch to intensify saturation.
%%
%% Dependencies
% <matlab:prettyDependencies('registerAndBlend.m') Show in Terminal>


prefFileExt = '.jpeg';
decorrTols = [0.0,.0002,.001];

% no hidden files
redFiles = dir2(redDir,'R*');
redFileNames = natsort({redFiles(:).name}');
greenFiles = dir2(greenDir,'R*');
greenFileNames = natsort({greenFiles(:).name}');

% just use one list, needs to be in both anyways
splits1 = cellfun(@(x) strsplit(x,'-'),redFileNames,'UniformOutput',false);
splits2 = cellfun(@(x) x{3},splits1,'UniformOutput',false);
[~,redSlides,redExts] = cellfun(@(x) fileparts(x),splits2,'UniformOutput',false);

splits1 = cellfun(@(x) strsplit(x,'-'),greenFileNames,'UniformOutput',false);
splits2 = cellfun(@(x) x{3},splits1,'UniformOutput',false);
[~,greenSlides,greenExts] = cellfun(@(x) fileparts(x),splits2,'UniformOutput',false);

% make sure file extensions match
if numel(unique([greenExts;redExts])) > 1
    % non-standard extensions
    button = questdlg(['Multiple file extensions found. Can I repair these to ',prefFileExt,'? (required to continue)'],'findEmptySevFiles','Yes','No','No');
    if strcmp(button,'Yes')
        h = waitbar(0,'Moving files...');
        useFiles = redFileNames;
        useDir = redDir;
        totalFiles = numel(redFileNames) + numel(greenFileNames);
        fileCount = 1;
        for ii = 1:2
            if ii == 2; useFiles = greenFileNames; useDir = greenDir; end;
            for iFile = 1:length(useFiles)
                waitbar(fileCount/totalFiles,h);
                [~,name,ext] = fileparts(useFiles{iFile});
                src = fullfile(useDir,[name,ext]);
                dest = fullfile(useDir,[name,prefFileExt]);
                if ~strcmp(src,dest)
                    movefile(src,dest);
                end
                fileCount = fileCount + 1;
            end
        end
        close(h);
        % call master function now that files are renamed
        registerAndBlend(redDir,greenDir);
        return; % [ ] test this!
    else
        disp('Extensions left unmatched.');
    end
end

% perform registration
% idxs of strings in unordered A&&B
matchIdx = ismember(redSlides,greenSlides);
h = waitbar(0,'');
for redIdx = 1:length(matchIdx)
    if ~matchIdx(redIdx); continue; end;
    [~,greenIdx] = ismember(redSlides(redIdx),greenSlides);
    waitbar(redIdx/length(matchIdx),h,[redSlides{redIdx},' [registering]...']);
    greenFile = fullfile(greenDir,greenFileNames{greenIdx});
    redFile = fullfile(redDir,redFileNames{redIdx});
    imGreen = imread(greenFile);
    imGreen = squeeze(imGreen(:,:,2));
    imRed = imread(redFile);
    imRed = squeeze(imRed(:,:,1));
    [optimizer,metric] = imregconfig('Multimodal');
    % registered should be green transformed [ ] test this
    disp(['Registering: ',redSlides{redIdx}]);
    [registered,~] = imregister(imGreen,imRed,'similarity',optimizer,metric);
%         figure; imshowpair(imRed,registered);
    imBlend = cat(3, imRed, registered, zeros(size(imRed)));
    saveDir = strsplit(redDir,filesep);
    saveDir = strjoin(saveDir(1:end-1),filesep);
    for iTols = 1:size(decorrTols,2)
        tolStr = strrep(num2str(decorrTols(iTols)),'.','-');
        blendDir = fullfile(saveDir,['blended_tol',tolStr]);
        % mkdir on first loop
        if redIdx == 1
            if ~exist(blendDir)
                mkdir(blendDir);
            end
        end
        waitbar(redIdx/length(matchIdx),h,[redSlides{redIdx},' [registering] --> [writing tol',tolStr,']...']);
        S = decorrstretch(imBlend,'tol',decorrTols(iTols));
        blendSavePath = fullfile(blendDir,[strjoin([splits1{1,1}{1},redSlides(redIdx),tolStr],'-'),prefFileExt]);
        imwrite(S,blendSavePath);
    end
end
close(h);
