function drawHorizontalLines(startInt,endInt,loopInc)

ratBrainAtlas = imread('ratBrainAtlas.jpg');
disp('Select the horizontal coordinates for where the histology begins and ends.');
imshow(ratBrainAtlas);
hold on;

[~,ys] = ginput(2);
stepPx = round((ys(end) - ys(1)) / (endInt - startInt));
lineCount = 0;
for ii=startInt:loopInc:endInt
    yCoord = ys(1) + (lineCount * stepPx * loopInc);
    p1 = [0 yCoord];
    p2 = [size(ratBrainAtlas,2) yCoord];
    plot([p1(1),p2(1)],[p1(2),p2(2)],'Color','r','LineWidth',2);
    text(p1(1),p1(2),num2str(ii),'FontSize',12);
    text(p2(1),p1(2),num2str(ii),'FontSize',12,'HorizontalAlignment','right');
    lineCount = lineCount + 1;
end
hold off;

export_fig -painters -r600 -q101 ratBrainAtlas-print.pdf