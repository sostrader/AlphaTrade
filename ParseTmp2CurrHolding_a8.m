function ParseTmp2CurrHolding_a8(AccountInfo, id)
numOfAccount = length(AccountInfo);
for ai = 1:numOfAccount
    if str2double(AccountInfo{ai}.ID) == id
        break;
    end
end

times = clock;
ndate = times(1) * 1e4 + times(2) * 1e2 + times(3);
sdate = num2str(ndate);

path_log = [AccountInfo{ai}.LOGPATH AccountInfo{ai}.NAME '\'];
path_goal = [AccountInfo{ai}.GOALPATH 'currentHolding\' AccountInfo{ai}.NAME '\'];
path_source = [path_log sdate '\'];
path_dest = [path_goal sdate '\'];
sourceFile = [path_source 'stock_holding.xlsx'];
destFile = [path_dest 'current_holding.txt'];
unit = str2double(AccountInfo{ai}.UNIT);

%% parse holding log file
[~, ~, rawData] = xlsread(sourceFile);
numOfInst = size(rawData,1) - 3;
if numOfInst > 0
    holding = zeros(numOfInst, 3);
    for im = 1:numOfInst
        holding(im,1) = str2double(rawData{im + 2, 3});%ticker
        holding(im,2) = rawData{im + 2, 5}(1) * unit;%vol
        holding(im,3) = holding(im,2) - rawData{im + 2, 10}(1) * unit;%available vol
    end
    holding(isnan(holding(:,1)),:) = [];    
end

if exist(path_dest, 'dir')
else
    mkdir(path_dest);
end
if exist('holding','var')
    if ~isempty(holding)
        fid_d = fopen(destFile,'w');
        fprintf(fid_d, [repmat('%15d\t',1,size(holding,2)), '\n'], holding');
        fclose(fid_d);
    end
end