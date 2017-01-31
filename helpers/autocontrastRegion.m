% AUTOCONTRAST  Automatically adjusts contrast of images to optimum level.
%    e.g. autocontrast('Sunset.jpg','Output.jpg')

function img=autocontrastRegion(img)

% --- added by Matt
orig_img = img;

imgX = size(img,1);
imgY = size(img,2);
imgCX = round(imgX / 2);
imgCY = round(imgX / 2);
regionX = round(imgX * .25);
regionY = round(imgY * .25);

img = img(imgCX-regionX:imgCX+regionX,imgCY-regionY:imgCY+regionY,:);
figure; imshow(img);
% --- end addition

low_limit=0.008;
up_limit=0.992;

low_limit=.001;
up_limit=.999;

[m1 n1 r1]=size(img);
img=double(img);
%--------------------calculation of vmin and vmax----------------------
for k=1:r1
    arr=sort(reshape(img(:,:,k),m1*n1,1));
    v_min(k)=arr(ceil(low_limit*m1*n1));
    v_max(k)=arr(ceil(up_limit*m1*n1));
end
%----------------------------------------------------------------------
if r1==3
    v_min=rgb2ntsc(v_min);
    v_max=rgb2ntsc(v_max);
end
%----------------------------------------------------------------------
% % img=(img-v_min(1))/(v_max(1)-v_min(1));
img=double(orig_img); % added by Matt
img=(img-v_min(1))/(v_max(1)-v_min(1));
img=uint8(img.*255);