function ParseTmp2CurrHolding_hundsun(AccountInfo, id)
global fid_log

numOfAccount = length(AccountInfo);
for ai = 1:numOfAccount
    if str2double(AccountInfo{ai}.ID) == id
        break;
    end
end

[idate, itime] = GetDateTimeNum();
fprintf(fid_log, '--->>> %s_%s,\tBegin to parse stock holding file. account = %s.\n', num2str(idate), num2str(itime), AccountInfo{ai}.NAME);

path_source = [AccountInfo{ai}.ACCOUNTPATH AccountInfo{ai}.NAME '\'];
path_dest   = [AccountInfo{ai}.ACCOUNTPATH AccountInfo{ai}.NAME '\'];
sourceFile  = [path_source 'stock_holding.txt'];
destFile    = [path_dest 'current_holding.txt'];
file_split  = [path_source 'split.txt'];
unit = str2double(AccountInfo{ai}.UNIT);

%% load split files
if exist(file_split, 'file')
	split = load(file_split);
end

%% parse holding log file
fid_s = fopen(sourceFile, 'r');
if fid_s > 0
    [idate, itime] = GetDateTimeNum();
    fprintf(fid_log, '--->>> %s_%s,\tBegin to parse holding file. file = %s.\n', num2str(idate), num2str(itime), sourceFile);
    
    rawData = textscan(fid_s, '%s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s','delimiter',',');
    numOfInst = size(rawData{1,1},1) - 2;
    holding = zeros(numOfInst, 3);
    for i = 1:numOfInst
        holding(i,1) = str2double(rawData{1,2}{i+1}(2:end-1));%ticker
        holding(i,2) = str2double(rawData{1,3}{i+1}(2:end-1));%holding
        holding(i,3) = str2double(rawData{1,4}{i+1}(2:end-1));%this day buy vol
        holding(i,3) = (holding(i,2) - holding(i,3)) * unit;% available
    end

    for k = 1:size(holding,2)
        holding(isnan(holding(:,k)),:) = [];
    end
    fclose(fid_s);    
else
    [idate, itime] = GetDateTimeNum();
    fprintf(fid_log, '--->>> %s_%s,\tError when open holding file. file = %s.\n', num2str(idate), num2str(itime), sourceFile);
end

if exist(path_dest, 'dir')
else
    mkdir(path_dest);
end
if exist('holding','var')
    if ~isempty(holding)
		if exist('split', 'var')
			[co_ticker, pSplit, pHolding] = intersect(holding(:,1), split(:,1));
			if isempty(co_ticker)
			else
				holding(pHolding,2) = holding(pHolding,2) + split(pSplit,2);
			end
		end
        fid_d = fopen(destFile,'w');
        fprintf(fid_d, [repmat('%15d\t',1,size(holding,2)), '\n'], holding');
        fclose(fid_d);
    end
end

%% copy file to history direction
[idate, itime] = GetDateTimeNum();
dst_sourceFile    = [path_source 'HistoricalLog\stock_holding_' num2str(idate) '_' num2str(itime) '.txt'];
dst_destFile        = [path_dest '\HistoricalCurrentHolding\current_holding_' num2str(idate) '_' num2str(itime) '.txt'];
dst_file_split = [path_dest 'HitoricalSplit\split_' num2str(idate) '_' num2str(itime) '.txt'];
CopyFile2HistoryDir(sourceFile, dst_sourceFile);
CopyFile2HistoryDir(destFile, dst_destFile);
CopyFile2HistoryDir(file_split, dst_file_split);

[idate, itime] = GetDateTimeNum();
fprintf(fid_log, '--->>> %s_%s,\tEnd to parse stock holding file. account = %s.\n', num2str(idate), num2str(itime), AccountInfo{ai}.NAME);