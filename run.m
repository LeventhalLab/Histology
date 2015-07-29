controlPoints = 4;

% % disp('Select histology directory...');
% % histoDir = uigetdir();
tifFiles = dir(fullfile(histoDir,'*.TIF'));

% sort by date
datenums = cell2mat({tifFiles(:).datenum});
[~,idx] = sort(datenums);
tifFiles = {tifFiles(idx).name};

% compress images
compressedDir = fullfile(histoDir,'compressed');
if ~isdir(compressedDir)
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

jpegFiles = dir(fullfile(compressedDir,'*.jpeg'));
jpegFiles = {jpegFiles.name};
imageIds = listdlg('PromptString','Select starting file:',...
                'SelectionMode','multiple','ListSize',[200 600],...
                'ListString',jpegFiles);

transformPoints = zeros(length(jpegFiles),controlPoints,2);
for ii=1:length(imageIds)-1
    IM1 = imread(fullfile(compressedDir,jpegFiles{imageIds(ii)}));
    IM2 = imread(fullfile(compressedDir,jpegFiles{imageIds(ii+1)}));
    [moving_out,fixed_out] = cpselect(IM1,IM2,'Wait',true);
    mytform = fitgeotrans(moving_out,fixed_out,'projective');
    rIM2 = imref2d(size(IM2));
    IM1registered = imwarp(IM1,mytform,'OutputView',rIM2);
    figure, imshowpair(IM1registered,IM2,'blend')
    
%     registered = imwarp(IM2, mytform);
%     figure;imshow(registered);
    
    pause(2);
end
% select start image
% use line to mark horizontal surgery plane
% mark points forwards, then backwards
% can I automatically flip the image based on points? I think...
% save in compressed > orientated

% how does this handle canvas size? Will it come into photoshop okay? Do I
% need to increase canvas size so it rotates correctly?